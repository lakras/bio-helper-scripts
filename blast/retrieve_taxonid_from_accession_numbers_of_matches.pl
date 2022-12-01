#!/usr/bin/env perl

# Retrieves each match's taxon id from Entrez using match accession number column and adds
# taxon ids to blast or diamond output as a new column.

# Install Entrez before running. Use either of these two commands:
# sh -c "$(curl -fsSL ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"
# sh -c "$(wget -q ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh -O -)"
# More info: https://www.ncbi.nlm.nih.gov/books/NBK179288/


# Usage:
# perl retrieve_taxonid_from_accession_numbers_of_matches.pl [blast or diamond output]
# [1 if blast or diamond output is from a nucleotide search; 0 if it is from a protein search]
# [column number of new taxon id column to add to output file (0-indexed)]

# Prints to console. To print to file, use
# perl retrieve_taxonid_from_accession_numbers_of_matches.pl [blast or diamond output]
# [1 if blast or diamond output is from a nucleotide search; 0 if it is from a protein search]
# [column number of new taxon id column to add to output file (0-indexed)]
# > [blast or diamond output with taxon id column added]


use strict;
use warnings;


my $blast_or_diamond_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $nucleotide = $ARGV[1]; # 1 if blast or diamond output is from a nucleotide search; 0 if it is from a protein search
my $output_taxonid_column = $ARGV[2]; # column number of new taxon id column to add to output file (0-indexed)

my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";

# blast or diamond file
my $SACC_COLUMN = 1; # column number of column containing match accession numbers (0-indexed)


# verifies that input file exists and is not empty
if(!$blast_or_diamond_output or !-e $blast_or_diamond_output or -z $blast_or_diamond_output)
{
	print STDERR "Error: blast or diamond output not provided, does not exist, or empty:\n\t"
		.$blast_or_diamond_output."\nExiting.\n";
	die;
}


# reads in blast or diamond output and extracts matched sequence accession numbers
open BLAST_OR_DIAMOND_OUTPUT, "<$blast_or_diamond_output"
	|| die "Could not open $blast_or_diamond_output to read\n";
my %matched_accession_numbers = (); # key: matched accession number -> value: 1
while(<BLAST_OR_DIAMOND_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sacc = $items[$SACC_COLUMN];
		$matched_accession_numbers{$sacc} = 1;
	}
}
close BLAST_OR_DIAMOND_OUTPUT;

my $matched_accession_numbers_string = "";
foreach my $sacc(keys %matched_accession_numbers)
{
	$matched_accession_numbers_string .= $sacc.$NEWLINE;
}


# retrieves taxon id for each accession number from Entrez, where possible
my $database = "protein";
if($nucleotide)
{
	$database = "nuccore";
}
my $sacc_to_taxon_id_string = `echo "$matched_accession_numbers_string" | epost -db $database | esummary | xtract -pattern DocumentSummary -element Caption,TaxId`;


# reads in taxon id to accession number mapping
my %sacc_to_taxon_id = (); # key: match accession number -> value: match taxon id
foreach my $line(split($NEWLINE, $sacc_to_taxon_id_string))
{
	my @items = split($DELIMITER, $line);
	my $sacc = $items[0];
	my $taxonid = $items[1];
	
	$sacc_to_taxon_id{$sacc} = $taxonid;
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

# foreach my $sacc(keys %matched_accession_numbers)
# {
# 	print $sacc."\t".$sacc_to_taxon_id{$sacc}."\n";
# }


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
		my $sacc = $items[$SACC_COLUMN];
		
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
