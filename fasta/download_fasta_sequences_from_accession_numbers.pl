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
my $MAXIMUM_NUMBER_ACCESSION_NUMBERS_IN_ONE_URL = 400;


# reads in accession numbers and retrieves corresponding fasta sequences
my @accession_numbers_lists = ();
my $current_accession_numbers_command_list = "";
my $current_number_accession_numbers = 0;
open ACCESSION_NUMBERS, "<$accession_numbers_file" || die "Could not open $accession_numbers_file to read\n";
while(<ACCESSION_NUMBERS>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my $accession_number = $_;
		if($current_accession_numbers_command_list)
		{
			$current_accession_numbers_command_list .= ",";
		}
		$current_accession_numbers_command_list .= $accession_number;
		$current_number_accession_numbers++;
		
		if($current_number_accession_numbers >= $MAXIMUM_NUMBER_ACCESSION_NUMBERS_IN_ONE_URL)
		{
			push(@accession_numbers_lists, $current_accession_numbers_command_list);
			$current_number_accession_numbers = 0;
			$current_accession_numbers_command_list = "";
		}
	}
}
close ACCESSION_NUMBERS;
push(@accession_numbers_lists, $current_accession_numbers_command_list);


# builds and runs command to download fasta file
# example URL: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&rettype=fasta&retmode=text&id=D90600.1
foreach my $accession_numbers_list(@accession_numbers_lists)
{
	my $command = "curl https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db="
		.$database."\\&rettype=fasta\\&retmode=text\\&id=".$accession_numbers_list; # ." > ".$output_fasta;
# 	print $command."\n";
	my $fasta_sequences = `$command`;

	if($fasta_sequences =~ /^>/)
	{
		print $fasta_sequences;
	}
	else
	{
		print STDERR "Error: skipping output that is not a fasta sequence:\n"
			.$fasta_sequences."\n"."from accesion number(s)\n".$accession_numbers_list."\n";
	}
}


# December 27, 2022
# December 29, 2022
