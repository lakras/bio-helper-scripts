#!/usr/bin/env perl

# Selects a certain number of sequences at random from input fasta file.

# Usage:
# perl select_random_sequences.pl [fasta sequence file]
# [number sequences to select at random]

# Prints to console. To print to file, use
# perl select_random_sequences.pl [fasta sequence file]
# [number sequences to select at random] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # sequences to choose from; sequence names must be unique
my $number_sequences_to_select = $ARGV[1];


my $NEWLINE = "\n";


# verifies that inputs make sense
if($number_sequences_to_select < 1)
{
	print STDERR "Error: number sequences to select is less than 1. Exiting.\n";
	die;
}
if($number_sequences_to_select !~ /^\d+$/)
{
	print STDERR "Error: number sequences to select is not a positive integer. Exiting.\n";
	die;
}
if(!$fasta_file or !-e $fasta_file)
{
	print STDERR "Error: input fasta file does not exist. Exiting.\n";
	die;
}


# counts total number of sequences in the input fasta file
open FASTA, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $total_number_sequences = 0;
while(<FASTA>) # for each row in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # sequence name
	{
		$total_number_sequences++;
	}
}
close FASTA;


# calculates proportion of sequences to select
if($number_sequences_to_select >= $total_number_sequences)
{
	print STDERR "Error: number sequences to select is not less than total number of "
		."sequences. Exiting.\n";
	die;
}
my $proportion_sequences_to_select = $number_sequences_to_select / $total_number_sequences;


# selects and prints sequences
my $current_sequence_included = 0;
my $number_sequences_selected = 0;
my %sequence_printed = ();
while($number_sequences_selected < $number_sequences_to_select)
{
	open FASTA, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
	while(<FASTA>) # for each row in the file
	{
		chomp;
		if($_ =~ /^>(.*)$/) # sequence name
		{
			my $sequence_name = $1;
			my $random_value = rand(1);
			if($random_value < $proportion_sequences_to_select
				and $number_sequences_selected < $number_sequences_to_select
				and !$sequence_printed{$sequence_name})
			{
				$current_sequence_included = 1;
				$sequence_printed{$sequence_name} = 1;
				$number_sequences_selected++;
			}
			else
			{
				$current_sequence_included = 0;
			}
		}
	
		if($current_sequence_included)
		{
			print $_;
			print $NEWLINE;
		}
	}
	close FASTA;
}


# September 2, 2020
# January 17, 2022
