#!/usr/bin/env perl

# Filters fasta file by sequence length.

# Usage:
# perl filter_sequences_by_length.pl [fasta file path] [minimum length]
# [1 to filter by number of unambiguous bases, 0 to filter on number of bases (including Ns)]

# Prints to console. To print to file, use
# perl filter_sequences_by_length.pl [fasta file path] [minimum length]
# [1 to filter by number of unambiguous bases, 0 to filter on number of bases (including Ns)]
#  > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $minimum_length = $ARGV[1];
my $filter_by_unambiguous_sequence_length = $ARGV[2]; # 1 to filter by number of unambiguous bases, 0 to filter on number of bases (including Ns)


my $NEWLINE = "\n";


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


# reads in fasta file and retrieves sequences with length passing threshold
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $sequence_name = "";
my $sequence = "";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# processes previous sequence
		if($sequence_name and $sequence
			and sequence_length($sequence) >= $minimum_length)
		{
			print ">".$sequence_name.$NEWLINE;
			print $sequence.$NEWLINE;
		}
	
		# stars processing this sequence
		$sequence_name = $1;
		$sequence = "";
	}
	else
	{
		$sequence .= $_;
	}
}
close FASTA_FILE;

# processes final sequence
if($sequence_name and $sequence
	and sequence_length($sequence) >= $minimum_length)
{
	print ">".$sequence_name.$NEWLINE;
	print $sequence.$NEWLINE;
}


# prints number of times each character appearing in sequence
sub sequence_length
{
	my $sequence = $_[0];
	
	# capitalize sequence
	$sequence = uc($sequence);
	
	# counts number bases or unambiguous bases in this sequence
	my $sequence_length = 0;
	foreach my $base(split //, $sequence)
	{
		if($filter_by_unambiguous_sequence_length and is_unambiguous_base($base))
		{
			$sequence_length++;
		}
		elsif(!$filter_by_unambiguous_sequence_length and is_base($base))
		{
			$sequence_length++;
		}
	}
	return $sequence_length;
}

# returns 1 if base is A, T, C, G; returns 0 if not
# input base must be capitalized
sub is_unambiguous_base
{
	my $base = $_[0]; # must be capitalized
	if($base eq "A" or $base eq "T" or $base eq "C" or $base eq "G")
	{
		return 1;
	}
	return 0;
}

# returns 1 if base is not gap, 0 if base is a gap
sub is_base
{
	my $base = $_[0];
	
	# empty value
	if(!$base)
	{
		return 0;
	}
	
	# only whitespace
	if($base !~ /\S/)
	{
		return 0;
	}
	
	# gap
	if($base eq "-")
	{
		return 0;
	}
	
	# base
	return 1;
}


# December 3, 2021
