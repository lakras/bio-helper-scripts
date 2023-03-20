#!/usr/bin/env perl

# Searches provided sequences for provided query sequences.

# Outputs table with columns:
# - name of sequence containing at least one query sequence
# - number of query sequences matched

# Usage:
# perl search_for_query_sequences.pl [fasta file path containing sequences to search]
# [fasta file path containing queries]

# Prints to console. To print to file, use
# perl search_for_query_sequences.pl [fasta file path containing sequences to search]
# [fasta file path containing queries] > [output table file path]


use strict;
use warnings;


my $sequences_to_search_fasta = $ARGV[0];
my $query_sequences_fasta = $ARGV[1];


my $DELIMITER = "\t";
my $NEWLINE = "\n";


# verifies that fasta files exist and are non-empty
if(!$sequences_to_search_fasta or !$query_sequences_fasta)
{
	print STDERR "Error: input fasta file not provided. Exiting.\n";
	die;
}
if(!-e $sequences_to_search_fasta or !-e $query_sequences_fasta)
{
	print STDERR "Error: input fasta file does not exist. Exiting.\n";
	die;
}
if(-z $sequences_to_search_fasta or -z $query_sequences_fasta)
{
	print STDERR "Error: input fasta file is empty. Exiting.\n";
	die;
}


# reads in query sequences fasta file
open QUERIES, "<$query_sequences_fasta"
	|| die "Could not open $query_sequences_fasta to read; terminating =(\n";
my %query_name_to_sequence = (); # key: query sequence name -> value: query sequence
my %query_sequences = (); # key: query sequence -> value: 1
my $current_sequence = ""; # sequence currently being read in
my $current_sequence_name = ""; # name of sequence currently being read in
while(<QUERIES>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# processes previous sequence
		if($current_sequence)
		{
# 			$query_name_to_sequence{$current_sequence_name} = $current_sequence;
			$query_sequences{$current_sequence} = 1;
		}
	
		# processes new sequence
		my $current_sequence_name = $1;
		my $current_sequence = "";
	}
	else
	{
		$current_sequence .= uc($_);
	}
}
close QUERIES;

# processes final sequence
if($current_sequence)
{
# 	$query_name_to_sequence{$current_sequence_name} = $current_sequence;
	$query_sequences{$current_sequence} = 1;
}


# reads in and searches through sequences to search
open SEQUENCES, "<$sequences_to_search_fasta"
	|| die "Could not open $sequences_to_search_fasta to read; terminating =(\n";
$current_sequence = ""; # sequence currently being read in
$current_sequence_name = ""; # name of sequence currently being read in
while(<SEQUENCES>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# processes previous sequence
		if($current_sequence)
		{
			my $number_queries_matched = 0; # number queries matched by current sequence
			foreach my $query_sequence(keys %query_sequences)
			{
				if($current_sequence =~ /$query_sequence/)
				{
					$number_queries_matched++;
				}
			}
			print $current_sequence_name.$DELIMITER.$number_queries_matched.$NEWLINE;
		}
	
		# processes new sequence
		my $current_sequence_name = $1;
		my $current_sequence = "";
	}
	else
	{
		$current_sequence .= uc($_);
	}
}
close SEQUENCES;

# processes final sequence
if($current_sequence)
{
	my $number_queries_matched = 0; # number queries matched by current sequence
	foreach my $query_sequence(keys %query_sequences)
	{
		if($current_sequence =~ /$query_sequence/)
		{
			$number_queries_matched++;
		}
	}
	print $current_sequence_name.$DELIMITER.$number_queries_matched.$NEWLINE;
}


# March 20, 2023

