#!/usr/bin/env perl

# Maps accession numbers to taxon ids directly from NCBI accession number to taxon id
# mapping file, without using Entrez. Useful for mapping thousands or millions of
# accession numbers, since this method does not have rate limits.

# Retrieves each match's taxon id from from match accession number column and adds
# taxon ids to blast or diamond output as a new column. Reads in mapping tables in
# parallel to save time.

# Appropriate mapping tables must be downloaded and unzipped from
# ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/
# (see README file)

# For example:
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.1.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.2.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.3.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.4.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.5.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.6.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.7.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.8.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.9.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.10.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.11.gz
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.12.gz
# gunzip prot.accession2taxid.FULL.1.gz
# gunzip prot.accession2taxid.FULL.2.gz
# gunzip prot.accession2taxid.FULL.3.gz
# gunzip prot.accession2taxid.FULL.4.gz
# gunzip prot.accession2taxid.FULL.5.gz
# gunzip prot.accession2taxid.FULL.6.gz
# gunzip prot.accession2taxid.FULL.7.gz
# gunzip prot.accession2taxid.FULL.8.gz
# gunzip prot.accession2taxid.FULL.9.gz
# gunzip prot.accession2taxid.FULL.10.gz
# gunzip prot.accession2taxid.FULL.11.gz
# gunzip prot.accession2taxid.FULL.12.gz
# (unzipped mapping tables add up to around 82 GB, almost 5 billion lines)


# Usage:
# perl retrieve_taxonids_from_accession_numbers_of_blast_matches_bulk.pl [blast or diamond output]
# [column number of new taxon id column to add to output file (0-indexed)]
# [column number (0-indexed) of column containing match accession numbers (stitle)]
# [unzipped mapping table] [another unzipped mapping table] [etc.]

# Prints to console. To print to file, use
# perl retrieve_taxonids_from_accession_numbers_of_blast_matches_bulk.pl [blast or diamond output]
# [column number of new taxon id column to add to output file (0-indexed)]
# [column number (0-indexed) of column containing match accession numbers (stitle)]
# [unzipped mapping table] [another unzipped mapping table] [etc.]
# > [blast or diamond output with taxon id column added]


use strict;
use warnings;
use Parallel::ForkManager; # download here: https://metacpan.org/pod/Parallel::ForkManager


my $blast_or_diamond_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $output_taxonid_column = $ARGV[1]; # column number of new taxon id column to add to output file (0-indexed)
my $sacc_column = $ARGV[2]; # column number (0-indexed) of column containing match accession numbers (stitle)
my @mapping_tables = @ARGV[3..$#ARGV]; # mapping tables with accession number in first column, taxonid in second column; ex. prot.accession2taxid.FULL for all protein accession numbers, downloaded and unzipped from ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/ (see README)


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$blast_or_diamond_output or !-e $blast_or_diamond_output or -z $blast_or_diamond_output)
{
	print STDERR "Error: blast or diamond output not provided, does not exist, or empty:\n\t"
		.$blast_or_diamond_output."\nExiting.\n";
	die;
}

# verifies that mapping tables have been entered, exist, and are not empty
if(!scalar @mapping_tables)
{
	print STDERR "Error: accession number to taxon id mapping table not provided. "
		."Exiting.\n";
	die;
}
foreach my $mapping_table(@mapping_tables)
{
	if(!$mapping_table or !-e $mapping_table or -z $mapping_table)
	{
		print STDERR "Error: accession number to taxon id mapping table does not exist "
			."or is empty:\n\t".$mapping_table."\nExiting.\n";
		die;
	}
}



# reads in blast or diamond output and extracts matched sequence accession numbers (sacc column)
open BLAST_OR_DIAMOND_OUTPUT, "<$blast_or_diamond_output"
	|| die "Could not open $blast_or_diamond_output to read\n";
my %matched_accession_numbers = (); # key: matched accession number -> value: 1
while(<BLAST_OR_DIAMOND_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sacc = $items[$sacc_column];
		$matched_accession_numbers{$sacc} = 1;
	}
}
close BLAST_OR_DIAMOND_OUTPUT;


# reads through mapping file and finds accession numbers of interest
my $cores_to_use = scalar @mapping_tables;
my %mapping_table_to_accession_number_to_taxon_id = (); # key: mapping table -> key: accession number of interest from this mapping table -> value: taxon id
my $pm = Parallel::ForkManager -> new($cores_to_use);
$pm -> run_on_finish(
	sub
	{
		my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;
		my $q = $data_structure_reference -> {mapping_table};
		$mapping_table_to_accession_number_to_taxon_id{$q} = $data_structure_reference -> {accession_number_to_taxon_id};
	}
);


# reads in taxon ids of accession numbers of interest from each mapping file in parallel
foreach my $mapping_table(@mapping_tables)
{
	my $pid = $pm -> start and next;
	
	# retrieves filename and total length of this mapping table
	# for printing our progress as we read it in
	my $mapping_table_filename = $mapping_table;
	if($mapping_table_filename =~ /\/([^\/]+)$/)
	{
		$mapping_table_filename = $1;
	}
	my $total_lines = `wc -l $mapping_table`;
	my $total_hundred_million_lines = int($total_lines/100000000)+1;
	
	# reads in taxon ids of accession numbers of interest from this mapping file
	open MAPPING, "<$mapping_table" || die "Could not open $mapping_table to read\n";
	my %accession_number_to_taxon_id = (); # key: accession number of interest from this mapping table -> value: taxon id
	my $number_read_in = 0;
	my $number_hundred_thousands_read_in = 0;
	while(<MAPPING>)
	{
		my @items = split($DELIMITER, $_);
		my $accession_number = $items[0];
		my $taxon_id = $items[1];
	
		if($matched_accession_numbers{$accession_number})
		{
			$accession_number_to_taxon_id{$accession_number} = $taxon_id;
		}
	
		# prints number lines read in every 100,000,000 lines
		$number_read_in++;
		if($number_read_in == 100000000)
		{
			$number_read_in = 0;
			$number_hundred_thousands_read_in++;
			print STDERR $number_hundred_thousands_read_in." of ".$total_hundred_million_lines." total hundred million lines "
				."read in of ".$mapping_table_filename."....\n";
		}
	}
	close MAPPING;
	print STDERR .$mapping_table_filename." read in.\n";
	
	$pm -> finish(0, {accession_number_to_taxon_id => \%accession_number_to_taxon_id, mapping_table => $mapping_table});
}
$pm -> wait_all_children;


# consolidates all accession number to taxonid id mappings of interest read in from mapping tables
my %accession_number_to_taxon_id = (); # key: accession number of interest -> value: taxon id
foreach my $mapping_table(@mapping_tables)
{
	foreach my $accession_number(keys %{$mapping_table_to_accession_number_to_taxon_id{$mapping_table}})
	{
		my $taxon_id = $mapping_table_to_accession_number_to_taxon_id{$mapping_table}{$accession_number};
		$accession_number_to_taxon_id{$accession_number} = $taxon_id;
	}
}


# prints list of accession numbers without a taxon id
my $accession_numbers_without_taxon_id = "";
foreach my $sacc(keys %matched_accession_numbers)
{
	if(!defined $accession_number_to_taxon_id{$sacc})
	{
		$accession_numbers_without_taxon_id .= $sacc."\n";
	}
}
if($accession_numbers_without_taxon_id)
{
	print STDERR "Error: could not retrieve taxon ids for the following accession "
		."numbers:\n".$accession_numbers_without_taxon_id;
}


# reads in blast or diamond output and prints with new taxonid column
open BLAST_OR_DIAMOND_OUTPUT, "<$blast_or_diamond_output"
	|| die "Could not open $blast_or_diamond_output to read\n";
while(<BLAST_OR_DIAMOND_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		
		# retrieves match accession number
		my $sacc = $items[$sacc_column];
		
		# retrieves taxon id
		my $taxonid = $NO_DATA;
		if(defined $accession_number_to_taxon_id{$sacc})
		{
			$taxonid = $accession_number_to_taxon_id{$sacc};
		}
		
		# prints row
		my $column = 0;
		foreach my $item(@items)
		{
			# prints tab if needed
			if($column > 0)
			{
				print $DELIMITER;
			}
		
			# prints new column if needed
			if($column == $output_taxonid_column)
			{
				print $taxonid.$DELIMITER;
			}
		
			# prints existing column
			print $item;
			
			$column++;
		}
		if($column == $output_taxonid_column) # new column is added after all other columns
		{
			print $DELIMITER.$taxonid;
		}
	}
	print $NEWLINE;
}
close BLAST_OR_DIAMOND_OUTPUT;


# December 1, 2022
# January 3, 2022
# January 4, 2022
