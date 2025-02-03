#!/usr/bin/env perl

# Retrieves sequence names from fasta file.

# Usage:
# perl retrieve_sequence_names.pl [fasta file path]

# Prints to console. To print to file, use
# perl retrieve_sequence_names.pl [fasta file path] > [output file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];


my $NEWLINE = "\n";


# verifies that fasta file exists and is non-empty
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


# reads in fasta file and retrieves sequence names
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		print $1.$NEWLINE;
	}
}
close FASTA_FILE;


# February 3, 2025
