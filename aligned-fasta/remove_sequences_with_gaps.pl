#!/usr/bin/env perl

# Removes sequences with -s.

# Usage:
# perl remove_sequences_with_gaps.pl [fasta file path]

# Prints to console. To print to file, use
# perl remove_sequences_with_gaps.pl [fasta file path] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # fasta file


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

# reads in fasta file
my $current_sequence = "";
my $current_sequence_name = "";
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			if(!sequence_contains_gaps($current_sequence))
			{
				print ">".$current_sequence_name."\n";
				print $current_sequence."\n";
			}
		}
		
		# save new sequence name and prepare to read in new sequence
		$current_sequence_name = $1;
		$current_sequence = "";
	}
	else # not header line
	{
		$current_sequence .= uc($_);
	}
}
if($current_sequence)
{
	if(!sequence_contains_gaps($current_sequence))
	{
		print ">".$current_sequence_name."\n";
		print $current_sequence."\n";
	}
}
close FASTA_FILE;


# returns 1 if sequence contains a - or any bases other than A, T, C, and G
sub sequence_contains_gaps
{
	my $sequence = $_[0];
	
	if($sequence =~ /-/)
	{
		return 1; # sequence contains a -
	}
	return 0; # sequence does not contain -s
}


# October 23, 2024
# February 5, 2025
