#!/usr/bin/env perl

# Generates "average" sequence of aligned sequence from most common base at each position.
# If first sequence in alignment is reference, reference is not included in calculation of
# average sequence.

# Usage:
# perl get_average_sequence_of_aligned_sequences.pl [alignment fasta file path]
# [1 if alignment includes reference as first sequence, 0 if alignment does not include a reference]

# Prints to console. To print to file, use
# perl get_average_sequence_of_aligned_sequences.pl [alignment fasta file path]
# [1 if alignment includes reference as first sequence, 0 if alignment does not include a reference]
# > [output fasta file path]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment; reference sequence must appear first
my $first_sequence_is_reference = $ARGV[1]; # if 0, includes first sequence in alignment; if 1, ignores it


my $NEWLINE = "\n";


# verifies that fasta alignment file exists and is non-empty
if(!$alignment_file)
{
	print STDERR "Error: no input fasta alignment file provided. Exiting.\n";
	die;
}
if(!-e $alignment_file)
{
	print STDERR "Error: input fasta alignment file does not exist:\n\t".$alignment_file."\nExiting.\n";
	die;
}
if(-z $alignment_file)
{
	print STDERR "Error: input fasta alignment file is empty:\n\t".$alignment_file."\nExiting.\n";
	die;
}


# reads in fasta sequences
my $first_sequence = 1; # 1 if we are currently reading in the first sequence in the alignment
my $current_sequence = "";
my %position_to_base_to_count = (); # key: position -> base -> value: number of sequences base appears at position
open FASTA_FILE, "<$alignment_file" || die "Could not open $alignment_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		# (unless it is the reference sequence)
		if($current_sequence and !($first_sequence and $first_sequence_is_reference))
		{
			my $position = 0;
			for my $base(split(//, $current_sequence))
			{
				$position_to_base_to_count{$position}{$base}++;
				$position++;
			}
		}
		
		# prepare to read in new sequence
		$current_sequence = "";
		$first_sequence = 0;
	}
	else # not header line
	{
		$current_sequence .= uc($_);
	}
}
close FASTA_FILE;
# process final sequence if it has been read in
# (unless it is the reference sequence)
if($current_sequence and !($first_sequence and $first_sequence_is_reference))
{
	my $position = 0;
	for my $base(split(//, $current_sequence))
	{
		$position_to_base_to_count{$position}{$base}++;
		$position++;
	}
}


# prints average sequence
print ">average_sequence".$NEWLINE;
foreach my $position(sort {$a <=> $b} keys %position_to_base_to_count)
{
	# determines most common base
	my $most_common_base = "";
	foreach my $base(sort {$position_to_base_to_count{$position}{$b} <=> $position_to_base_to_count{$position}{$a}}
		keys %{$position_to_base_to_count{$position}})
	{
		if(!$most_common_base)
		{
			$most_common_base = $base;
		}
	}
	
	# prints most common base at this position
	print $most_common_base;
}
print $NEWLINE;


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

# returns 1 if base is not gap, 0 if base is a gap (or whitespace or empty)
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


# December 15, 2022
