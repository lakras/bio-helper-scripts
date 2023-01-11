#!/usr/bin/env perl

# Removes any sequence whose full name has already appeared in the fasta file.

# Usage:
# perl remove_duplicate_name_sequences.pl [fasta file path]

# Prints to console. To print to file, use
# perl remove_duplicate_name_sequences.pl [fasta file path] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];


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


# reads in fasta file and prints sequences whose names haven't already been seen
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $printing_this_sequence = 1; # 1 if we are printing the sequence we are currently reading
my %sequence_name_seen = (); # key: full sequence name -> value: 1 if it has been seen in this fasta file
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# checks if this sequence name has already been seen
		my $sequence_name = $1;
		$printing_this_sequence = 1;
		if($sequence_name_seen{$sequence_name})
		{
			# records that we are printing lines belonging to this sequence
			$printing_this_sequence = 0;
		}
		$sequence_name_seen{$sequence_name} = 1;
	}
	
	# prints this line (header or sequence) if we are printing this sequence
	if($printing_this_sequence)
	{
		print $_."\n";
	}
}
close FASTA_FILE;


# January 10, 2023
