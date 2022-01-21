#!/usr/bin/env perl

# Merges fasta files, removing redundant sequences (so there is only one of each sequence,
# regardless of name). Can also be used to remove redundant sequences from a single fasta
# file.

# Usage:
# perl merge_fastas_and_remove_redundant_sequences.pl [fasta file path]
# [another fasta file path] [another fasta file path] [etc.]

# Prints to console. To print to file, use
# perl merge_fastas_and_remove_redundant_sequences.pl [fasta file path]
# [another fasta file path] [another fasta file path] [etc.] > [output fasta file path]


use strict;
use warnings;


my @fastas_to_merge = @ARGV[0..$#ARGV]; # fasta files to merge


my $NEWLINE = "\n";
my $SEQUENCE_NAME_SEPARATOR = "__";


# verifies that fasta files were provided
if(!scalar @fastas_to_merge)
{
	print STDERR "Error: no fasta files provided.\nExiting.\n";
	die;
}


my %sequence_to_name = (); # key: sequence -> value: name of sequence (concatenated with "_" if multiple)
foreach my $fasta(@fastas_to_merge)
{
	# sequence and name of sequence currently being read in
	my $sequence = "";
	my $sequence_name = "";
	
	# reads in fasta file
	open FASTA, "<$fasta" || die "Could not open $fasta to read; terminating =(\n";
	while(<FASTA>) # for each row in the file
	{
		chomp;
		if($_ =~ /^>(.*)$/) # sequence name
		{
			# processes previous sequence
			if($sequence_to_name{$sequence})
			{
				$sequence_to_name{$sequence} .= $SEQUENCE_NAME_SEPARATOR.$sequence_name;
			}
			else
			{
				$sequence_to_name{$sequence} = $sequence_name;
			}
			
			# new current sequence
			$sequence_name = $1;
			$sequence = "";
		}
		elsif($_ =~ /\S/) # if row not empty
		{
			$sequence .= $_;
		}
	}
	close FASTA;
	
	# processes last sequence if there is anything left
	if($sequence)
	{
		if($sequence_to_name{$sequence})
		{
			$sequence_to_name{$sequence} .= $SEQUENCE_NAME_SEPARATOR.$sequence_name;
		}
		else
		{
			$sequence_to_name{$sequence} = $sequence_name;
		}
	}
}


# outputs merged fasta file
# allows for empty sequences but not empty sequence names
foreach my $sequence(keys %sequence_to_name)
{
	my $sequence_name = $sequence_to_name{$sequence};
	if($sequence_name)
	{
		print ">".$sequence_to_name{$sequence}.$NEWLINE;
		print $sequence.$NEWLINE;
	}
}


# July 1, 2020
# January 20, 2022
