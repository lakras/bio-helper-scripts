#!/usr/bin/env perl

# Retrieves query sequences by name from fasta file, taking query sequence names from a list in a file, one sequence name per line.

# Usage:
# perl retrieve_sequences_by_names_listed_in_file.pl [fasta file path] [file with list of query sequence names]

# Prints to console. To print to file, use
# perl retrieve_sequences_by_names_listed_in_file.pl [fasta file path] [file with list of query sequence names] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $sequence_names_file = $ARGV[1];


# verifies that query sequence names file exists and is non-empty have been provided
if(!$sequence_names_file)
{
	print STDERR "Error: no query sequence names file provided. Exiting.\n";
	die;
}
if(!-e $sequence_names_file)
{
	print STDERR "Error: query sequence names file does not exist:\n\t".$sequence_names_file."\nExiting.\n";
	die;
}
if(-z $sequence_names_file)
{
	print STDERR "Error: query sequence names file is empty:\n\t".$sequence_names_file."\nExiting.\n";
	die;
}

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


# reads in list of files to extract
# builds hash of query sequence names for fast checking
my %sequence_name_included = (); # key: sequence name -> value: 1 if sequence is a query sequence
open QUERY_NAMES_LIST, "<$sequence_names_file" || die "Could not open $sequence_names_file to read; terminating =(\n";
while(<QUERY_NAMES_LIST>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/) # non-empty line
	{
		$sequence_name_included{$_} = 1;
	}
}
close QUERY_NAMES_LIST;


# counts number unique sequence names we are trying to retrieve
my $number_unique_query_sequences = keys %sequence_name_included;


# reads in fasta file and retrieves sequences matching query sequence names
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $printing_this_sequence = 0; # 1 if we are printing the sequence we are currently reading
my %sequence_name_found = (); # key: sequence name -> value: 1 if sequence has been found and printed
my $number_unique_query_sequences_found = 0; # the number of unique query sequence names we have found in the fasta file
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# exits if we have found all sequences
		if($number_unique_query_sequences_found >= $number_unique_query_sequences)
		{
			close FASTA_FILE;
			last;
		}
	
		# checks if this sequence name is one of our query sequences
		my $sequence_name = $1;
		$printing_this_sequence = 0;
		if($sequence_name_included{$sequence_name})
		{
			# records that we are printing lines belonging to this sequence
			$printing_this_sequence = 1;
			
			# marks this sequence as found
			$sequence_name_found{$sequence_name} = 1;
			
			# updates count of number unique query sequence names found
			$number_unique_query_sequences_found = keys %sequence_name_found;
		}
	}
	
	# prints this line (header or sequence) if we are printing this sequence
	if($printing_this_sequence)
	{
		print $_."\n";
	}
}
close FASTA_FILE;


# verifies that all query sequences have been found and printed
foreach my $sequence_name(@sequence_names)
{
	if(!$sequence_name_found{$sequence_name})
	{
		print STDERR "Error: sequence name ".$sequence_name." not found\n";
	}
}


# July 12, 2021
# August 6, 2021
