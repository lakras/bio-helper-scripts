#!/usr/bin/env perl

# Given a list of accession numbers, one per line, downloads and prints fasta sequences
# corresponding to each accession number.

# Based on option 2 in https://edwards.flinders.edu.au/ncbi-sequence-or-fasta-batch-download-using-entrez/


# Usage:
# perl download_fasta_sequences_from_accession_numbers.pl
# [path of file with list of accession numbers, one per line]
# [database (nucleotide by default)]

# Prints to console. To print to file, use
# perl download_fasta_sequences_from_accession_numbers.pl
# [path of file with list of accession numbers, one per line]
# [database (nucleotide by default)] > [output fasta file path]

use strict;
use warnings;


my $accession_numbers_file = $ARGV[0]; # list of accession numbers, one per line
my $database = $ARGV[1]; # nucleotide by default
if(!$database)
{
	$database = "nucleotide";
}


my $NEWLINE = "\n";
my $ACCESSION_NUMBER_COMMAND_DELIMITER = " ";


# reads in accession numbers and retrieves corresponding fasta sequences
my $accession_numbers_command_list = "";
open ACCESSION_NUMBERS, "<$accession_numbers_file" || die "Could not open $accession_numbers_file to read\n";
while(<ACCESSION_NUMBERS>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my $accession_number = $_;
		
		# builds and runs command to download fasta file
		# example URL: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&rettype=fasta&retmode=text&id=D90600.1
		my $command = "curl https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db="
			.$database."\\&rettype=fasta\\&retmode=text\\&id=".$accession_number; # ." > ".$output_fasta;
		my $fasta_sequence = `$command`;
		
		if($fasta_sequence =~ /^>/)
		{
			print $fasta_sequence;
		}
		else
		{
			print STDERR "Error: skipping output that is not a fasta sequence (accession"
				." number ".$accession_number."): \n".$fasta_sequence;
		}
	}
}
close ACCESSION_NUMBERS;


# December 27, 2022
