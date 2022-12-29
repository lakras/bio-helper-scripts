#!/usr/bin/env perl

# Retrieves each match's taxon id from Entrez using match accession number column and adds
# taxon ids to blast or diamond output as a new column.

# Install Entrez before running. Use either of these two commands:
# sh -c "$(curl -fsSL ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"
# sh -c "$(wget -q ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh -O -)"
# More info: https://www.ncbi.nlm.nih.gov/books/NBK179288/


# Usage:
# perl retrieve_taxonids_from_accession_numbers_of_blast_matches.pl [blast or diamond output]
# [1 if blast or diamond output is from a nucleotide search; 0 if it is from a protein search]
# [column number of new taxon id column to add to output file (0-indexed)]
# [column number (0-indexed) of column containing match accession numbers (stitle)]
# [optional column number (0-indexed) of column containing match names (stitle)]

# Prints to console. To print to file, use
# perl retrieve_taxonids_from_accession_numbers_of_blast_matches.pl [blast or diamond output]
# [1 if blast or diamond output is from a nucleotide search; 0 if it is from a protein search]
# [column number of new taxon id column to add to output file (0-indexed)]
# [column number (0-indexed) of column containing match accession numbers (stitle)]
# [optional column number (0-indexed) of column containing match names (stitle)]
# > [blast or diamond output with taxon id column added]


use strict;
use warnings;


my $blast_or_diamond_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $nucleotide = $ARGV[1]; # 1 if blast or diamond output is from a nucleotide search; 0 if it is from a protein search
my $output_taxonid_column = $ARGV[2]; # column number of new taxon id column to add to output file (0-indexed)
my $sacc_column = $ARGV[3]; # column number (0-indexed) of column containing match accession numbers (stitle)
my $stitle_column = $ARGV[4]; # optional column number (0-indexed) of column containing match names (stitle)


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";

my $TEMP_FILE_EXTENSION = "_temp.txt";
my $PRINT_TO_TEMP_FILE = 1; # if 0, prints temp file contents to echo to avoid printing temp file (has high likelihood of error for too-long argument)


# verifies that input file exists and is not empty
if(!$blast_or_diamond_output or !-e $blast_or_diamond_output or -z $blast_or_diamond_output)
{
	print STDERR "Error: blast or diamond output not provided, does not exist, or empty:\n\t"
		.$blast_or_diamond_output."\nExiting.\n";
	die;
}


# reads in blast or diamond output and extracts matched sequence accession numbers (sacc column)
# if available, also extracts matched sequence names (stitle column)
open BLAST_OR_DIAMOND_OUTPUT, "<$blast_or_diamond_output"
	|| die "Could not open $blast_or_diamond_output to read\n";
my %matched_accession_numbers = (); # key: matched accession number -> value: 1
my %matched_accession_number_to_name = (); # key: matched accession number -> value: sequence name
while(<BLAST_OR_DIAMOND_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sacc = $items[$sacc_column];
		$matched_accession_numbers{$sacc} = 1;
		
		if(defined $stitle_column)
		{
			my $stitle = $items[$stitle_column];
			$matched_accession_number_to_name{$sacc} = $stitle;
		}
	}
}
close BLAST_OR_DIAMOND_OUTPUT;


# collects accession numbers and retrieves taxon ids for them
my $database = "protein";
if($nucleotide)
{
	$database = "nuccore";
}

my $sacc_to_taxon_id_string = "";
if($PRINT_TO_TEMP_FILE) # prints list of accession numbers to look up to a temp file
{
	# collects accession numbers and prints to temp file
	my $temp_file = $blast_or_diamond_output.$TEMP_FILE_EXTENSION;
	open TEMP_FILE, ">$temp_file" || die "Could not open $temp_file to write\n";
	foreach my $sacc(keys %matched_accession_numbers)
	{
		print TEMP_FILE $sacc;
		print TEMP_FILE $NEWLINE;
	}
	close TEMP_FILE;

	# retrieves taxon id for each accession number from Entrez, where possible
	$sacc_to_taxon_id_string = `cat $temp_file | epost -db $database | esummary | xtract -pattern DocumentSummary -element Caption,TaxId`;
	
	# deletes temp file
	`rm $temp_file`;
}
else # uses echo to avoid printing to a temp file (has high likelihood of error for too-long argument)
{
	# collects accession numbers
	my $matched_accession_numbers_string = "";
	foreach my $sacc(keys %matched_accession_numbers)
	{
		$matched_accession_numbers_string .= $sacc.$NEWLINE;
	}

	# retrieves taxon id for each accession number from Entrez, where possible
	$sacc_to_taxon_id_string = `echo "$matched_accession_numbers_string" | epost -db $database | esummary | xtract -pattern DocumentSummary -element Caption,TaxId`;
}



# reads in taxon id to accession number mapping
my %sacc_to_taxon_id = (); # key: match accession number -> value: match taxon id
foreach my $line(split($NEWLINE, $sacc_to_taxon_id_string))
{
	my @items = split($DELIMITER, $line);
	my $sacc = $items[0];
	my $taxonid = $items[1];
	
	$sacc_to_taxon_id{$sacc} = $taxonid;
}


# for accession numbers without a taxon id, attempts to retrieve taxon id from taxon name
if(defined $stitle_column)
{
	# retrieves names of matched taxon whose taxon id could not be retrieved from accession numbers
	my %matched_taxon_names = (); # key: name of matched taxon whose taxon id could not be retrieved from accession number -> value: 1
	my %matched_accession_number_to_taxon_name = (); # key: matched accession number whose taxon id could not be retrieved -> value: its taxon name
	foreach my $sacc(keys %matched_accession_numbers)
	{
		if(!defined $sacc_to_taxon_id{$sacc}
			and defined $matched_accession_number_to_name{$sacc})
		{
			# retrieves taxon name from sequence name
			if($matched_accession_number_to_name{$sacc} =~ /\[([^\[\]]+)\]$/)
			{
				my $taxon_name = $1;
				
				# removes parentheses
				$taxon_name =~ s/\(/ /g;
				$taxon_name =~ s/\)/ /g;
				
				$matched_taxon_names{$taxon_name} = 1;
				$matched_accession_number_to_taxon_name{$sacc} = $taxon_name;
			}
		}
	}
	
	# retrieves taxon ids from taxon name
	my %matched_taxon_name_to_taxon_id = (); # key: taxon name -> value: taxon id
	foreach my $matched_taxon_name(keys %matched_taxon_names)
	{
		my $taxon_id = `esearch -db taxonomy -query "$matched_taxon_name" | esummary | xtract -pattern DocumentSummary -element TaxId`;
		chomp $taxon_id;
		$matched_taxon_name_to_taxon_id{$matched_taxon_name} = $taxon_id;
	}
	
	# maps retrieved taxon ids to accession numbers
	foreach my $sacc(keys %matched_accession_numbers)
	{
		if(!defined $sacc_to_taxon_id{$sacc}
			and defined $matched_accession_number_to_name{$sacc}
			and defined $matched_accession_number_to_taxon_name{$sacc})
		{
			# retrieves taxon name from sequence name
			my $matched_taxon_name = $matched_accession_number_to_taxon_name{$sacc};
			if(defined $matched_taxon_name_to_taxon_id{$matched_taxon_name})
			{
				my $matched_taxonid = $matched_taxon_name_to_taxon_id{$matched_taxon_name};
				$sacc_to_taxon_id{$sacc} = $matched_taxonid;
			}
		}
	}
}


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
