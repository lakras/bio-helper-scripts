#!/usr/bin/env perl

# Removes query sequences by position from fasta file.

# Usage:
# perl remove_sequences_by_position_in_fasta_file.pl [fasta file path]
# [position of sequence to remove (1-indexed)] [position of another sequence to remove]
# [etc.]

# Prints to console. To print to file, use
# perl remove_sequences_by_position_in_fasta_file.pl [fasta file path]
# [position of sequence to remove (1-indexed)] [position of another sequence to remove]
# [etc.] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my @positions = @ARGV[1..$#ARGV];


# verifies that query sequence positions have been provided
if(!scalar @positions)
{
	print STDERR "Error: no query sequence positions provided. Exiting.\n";
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
my %sequence_position_excluded = (); # key: sequence position in fasta file -> value: 1 if sequence is to be excluded in output
foreach my $position(@positions)
{
	$sequence_position_excluded{$position} = 1;
}


# reads in fasta file and retrieves sequences matching query sequence names
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $printing_this_sequence = 0; # 1 if we are printing the sequence we are currently reading
my %position_found = (); # key: sequence position in fasta file -> value: 1 if sequence has been found and printed
my $sequence_position = 0;
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# checks if this sequence position is one of our query sequences
		$sequence_position++;
		$printing_this_sequence = 1;
		if($sequence_position_excluded{$sequence_position})
		{
			# records that we are printing lines belonging to this sequence
			$printing_this_sequence = 0;
			
			# marks this sequence as found
			$position_found{$sequence_position} = 1;
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
foreach my $position(@positions)
{
	if(!$position_found{$position})
	{
		print STDERR "Error: sequence position ".$position." not found\n";
	}
}


# July 12, 2021
# March 24, 2022
# March 30, 2022
