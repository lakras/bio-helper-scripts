#!/usr/bin/env perl

# Counts number bases (including Ns and other ambiguous non-gap letters) in fasta file(s).

# Usage:
# perl calculate_genome_size.pl [fasta file path] [another fasta file path] [etc.]

# Prints to console. To print to file, use
# perl summarize_fasta_sequences.pl [fasta file path] [another fasta file path] [etc.]
# > [output file path]


use strict;
use warnings;


my @fasta_files = @ARGV; # sequence names may not appear more than once across all files


# for printing
my $NEWLINE = "\n";


# verifies that fasta file exists and is non-empty
if(!scalar @fasta_files)
{
	print STDERR "Error: no input fasta files provided. Exiting.\n";
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


# reads in fasta file and counts characters appearing in each sequence
my $genome_size = 0;
foreach my $fasta_file(@fasta_files)
{
	open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
	while(<FASTA_FILE>) # for each line in the file
	{
		chomp;
		if($_ !~ /^>(.*)/) # sequence (not header line)
		{
			foreach my $character(split //, $_)
			{
				if($character =~ /[A-Za-z]/)
				{
					$genome_size++;
				}
			}
		}
	}
	close FASTA_FILE;
}


# prints result
print $genome_size;


# March 23, 2023
