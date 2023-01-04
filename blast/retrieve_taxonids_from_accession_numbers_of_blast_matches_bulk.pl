#!/usr/bin/env perl

# Retrieves each match's taxon id from from match accession number column and adds
# taxon ids to blast or diamond output as a new column.

# Appropriate mapping table must be downloaded and unzipped from
# ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/
# (see README file)

# For example:
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.gz
# gunzip prot.accession2taxid.FULL.gz
# (unzipped mapping table is 82 GB)


# Usage:
# perl retrieve_taxonids_from_accession_numbers_of_blast_matches_bulk.pl [blast or diamond output]
# [mapping table] [column number of new taxon id column to add to output file (0-indexed)]
# [column number (0-indexed) of column containing match accession numbers (stitle)]

# Prints to console. To print to file, use
# perl retrieve_taxonids_from_accession_numbers_of_blast_matches_bulk.pl [blast or diamond output]
# [mapping table] [column number of new taxon id column to add to output file (0-indexed)]
# [column number (0-indexed) of column containing match accession numbers (stitle)]
# > [blast or diamond output with taxon id column added]


use strict;
use warnings;


my $blast_or_diamond_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $mapping_file = $ARGV[1]; # accession number in first column, taxonid in second column; ex. prot.accession2taxid.FULL for all protein accession numbers, downloaded and unzipped from ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/ (see README)
my $output_taxonid_column = $ARGV[2]; # column number of new taxon id column to add to output file (0-indexed)
my $sacc_column = $ARGV[3]; # column number (0-indexed) of column containing match accession numbers (stitle)


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

# verifies that mapping file exists and is not empty
if(!$mapping_file or !-e $mapping_file or -z $mapping_file)
{
	print STDERR "Error: accession number to taxon id mapping file not provided, does not exist, or empty:\n\t"
		.$mapping_file."\nExiting.\n";
	die;
}


# reads in blast or diamond output and extracts matched sequence accession numbers (sacc column)
# if available, also extracts matched sequence names (stitle column)
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
open MAPPING, "<$mapping_file" || die "Could not open $mapping_file to read\n";
my %sacc_to_taxon_id = (); # key: match accession number -> value: match taxon id
while(<MAPPING>)
{
	my @items = split($DELIMITER, $_);
	my $accession_number = $items[0];
	my $taxon_id = $items[1];
	
	if($matched_accession_numbers{$accession_number})
	{
		$sacc_to_taxon_id{$accession_number} = $taxon_id;
	}
}
close MAPPING;


# prints list of accession numbers without a taxon id
my $accession_numbers_without_taxon_id = "";
foreach my $sacc(keys %matched_accession_numbers)
{
	if(!defined $sacc_to_taxon_id{$sacc})
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
		if(defined $sacc_to_taxon_id{$sacc})
		{
			$taxonid = $sacc_to_taxon_id{$sacc};
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
