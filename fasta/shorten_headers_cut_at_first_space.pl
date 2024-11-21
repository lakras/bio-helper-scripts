#!/usr/bin/env perl

# Shortens headers of fasta file by cutting them off including and after the first space.

# Usage:
# perl shorten_headers_cut_at_first_space.pl [fasta file path]

# Prints to console. To print to file, use
# perl shorten_headers_cut_at_first_space.pl [fasta file path] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];


my $NEWLINE = "\n";


# verifies that fasta file exists and is non-empty
if(!$fasta_file or !-e $fasta_file or -z $fasta_file)
{
	print STDERR "Error: input fasta file not provided, does not exist, or is empty:\n"
		.$fasta_file."\nExiting.\n";
	die;
}


# reads in fasta file and prints sequences with adjusted headers
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(\S+) ?.*/) # header line
	{
		$_ = ">".$1;
	}
	print $_;
	print $NEWLINE;
}
close FASTA_FILE;


# November 21, 2024
