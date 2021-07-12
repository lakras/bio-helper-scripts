#!/usr/bin/env perl

# Retrieves query sequences by name from fasta file.
# Usage:
# perl retrieve_sequences_by_name.pl [fasta file path] [query sequence name 1] [query sequence name 2] [etc.]

# Prints to console. To print to file, use
# perl retrieve_sequences_by_name.pl [fasta file path] [query sequence name 1] [query sequence name 2] [etc.] > [output file path]

use strict;
use warnings;

my $fasta_file = $ARGV[0];
my @sequence_names = @ARGV[1..$#ARGV];

# verifies that query sequence names have been provided
if(!scalar @sequence_names)
{
	print STDERR "Error: no query sequence names provided. Exiting.\n";
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

# builds hash of query sequence names for fast checking
my %sequence_name_included = (); # key: sequence name -> value: 1 if sequence is a query sequence
foreach my $sequence_name(@sequence_names)
{
	$sequence_name_included{$sequence_name} = 1;
}

# reads in fasta file and retrieves sequences matching query sequence names
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $printing_this_sequence = 0;
my %sequence_name_found = (); # key: sequence name -> value: 1 if sequence has been found and printed
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# checks if this sequence name is one of our query sequences
		my $sequence_name = $1;
		$printing_this_sequence = 0;
		if($sequence_name_included{$sequence_name})
		{
			$printing_this_sequence = 1;
			$sequence_name_found{$sequence_name} = 1;
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
