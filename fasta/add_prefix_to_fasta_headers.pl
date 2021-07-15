#!/usr/bin/env perl

# Adds prefix to each header line in fasta file(s).

# Usage:
# perl add_prefix_to_fasta_headers.pl [fasta file path]

# Prints to console. To print to file, use
# perl add_prefix_to_fasta_headers.pl [fasta file path] > [output fasta file path]


use strict;
use warnings;


my $prefix = $ARGV[0];
my @fasta_files = @ARGV[1..$#ARGV]; # list of fasta files


my $NEWLINE = "\n";


# verifies that prefix is non-empty
if(!$prefix)
{
	print STDERR "Error: no prefix provided. Exiting.\n";
	die;
}

# verifies that fasta files exist and are non-empty
if(!scalar @fasta_files)
{
	print STDERR "Error: no input fasta file provided. Exiting.\n";
	die;
}
foreach my $fasta_file(@fasta_files)
{
	if(!-e $fasta_file)
	{
		print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
		die;
	}
	if(-z $fasta_file)
	{
		print STDERR "Warning: input fasta file is empty:\n\t".$fasta_file."\n";
	}
}


foreach my $fasta_file(@fasta_files)
{
	open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
	while(<FASTA_FILE>) # for each line in the file
	{
		chomp;
		if($_ =~ /^>(.*)/) # header line
		{
			$_ = ">".$prefix."_".$1;
		}
		print $_;
		print $NEWLINE;
	}
	close FASTA_FILE;
}


# June 7, 2020
# July 14, 2021
