#!/usr/bin/env perl


# Splits fasta file with multiple sequences up into a number of smaller files, each with
# about the same number of sequences.

# Usage:
# perl split_fasta_into_n_files.pl [fasta file path] [number output files to generate]

# New files are created at filepath of old file with "_1_of_[n].fasta", "_2_of_[n].fasta",
# etc. appended to the end. Files already at those paths will be overwritten.


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $number_files = $ARGV[1];


# verifies that input fasta file exists and is not empty
if(!$fasta_file)
{
	print STDERR "Error: no input fasta file provided. Exiting.\n";
	die;
}
if(!-e $fasta_file)
{
	print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
	die;
}
if(-z $fasta_file)
{
	print STDERR "Error: input fasta file is empty:\n\t".$fasta_file."\nExiting.\n";
	die;
}

# sanity check input number of files
if(!$number_files or $number_files < 2)
{
	print STDERR "Fewer than 2 output files requested. My services are not needed here.\n";
	die;
}


# reads in input fasta file and counts total number of sequences
my $number_sequences = 0;
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	if($_ =~ /^>/) # header line
	{
		$number_sequences++;
	}
}
close FASTA_FILE;
if($number_sequences < 2)
{
	print STDERR "Fewer than 2 sequences in input file. My services are not needed here.\n";
	die;
}


# calculates number of sequences to print in each file
my $number_sequences_per_file = $number_sequences / $number_files;


# splits sequences in fasta file into a number of smaller files
my $current_output_file_number = 0; # the number added to the end of the filepath of the current output file
my $sequences_in_current_output_file = 0; # number of sequences we have printed to the current output file
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /^>/) # header line
	{
		if(!$current_output_file_number or $sequences_in_current_output_file >= $number_sequences_per_file)
		{
			$current_output_file_number++;
			$sequences_in_current_output_file = 0;
			
			# closes current output file
			close OUT_FILE;
			
			# opens the next output file
			my $current_output_file = $fasta_file."_".$current_output_file_number."_of_".$number_files.".fasta";
			if(-e $current_output_file)
			{
				print STDERR "Warning: output file already exists. Overwriting:\n\t".$current_output_file."\n";
			}
			open OUT_FILE, ">$current_output_file" || die "Could not open $current_output_file to write; terminating =(\n";
		}
		$sequences_in_current_output_file++;
	}
	print OUT_FILE $line;
	print OUT_FILE "\n";
}
close FASTA_FILE;
close OUT_FILE;


# May 27, 2020
# July 12, 2021
