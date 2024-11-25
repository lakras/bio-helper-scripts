#!/usr/bin/env perl

# Selects outgroup (non-human host, for example) closest to example ingroup sequence
# (human host, for example).

# Input is an aligned fasta while where the first sequence is an example ingroup sequence
# and the rest of the sequences are potential outgroup sequences to select from.

# Prints sequence name of selected outgroup and its distance to example ingroup sequence.

# Usage:
# perl select_closest_outgroup.pl [aligned fasta file path]

# Prints to console. To print to file, use
# perl select_closest_outgroup.pl [aligned fasta file path] > [output text file]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # aligned fasta file where the first sequence is an example ingroup
# sequence and the rest of the sequences are potential outgroup sequences to select from


my $NEWLINE = "\n";
my $DELIMITER = "\t";


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
my $ingroup_sequence = "";
my %potential_outgroup_name_to_sequence = (); # key: potential outgroup sequence name -> value: sequence read in
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			# if it is the first sequence, sequence just read in is the example ingroup sequence
			if(!$ingroup_sequence)
			{
				$ingroup_sequence = $current_sequence;
			}
			
			# otherwise, this is a potential outgroup sequence
			else
			{
				$potential_outgroup_name_to_sequence{$current_sequence_name} = $current_sequence;
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
	# if it is the first sequence, sequence just read in is the example ingroup sequence
	if(!$ingroup_sequence)
	{
		$ingroup_sequence = $current_sequence;
	}
	
	# otherwise, this is a potential outgroup sequence
	else
	{
		$potential_outgroup_name_to_sequence{$current_sequence_name} = $current_sequence;
	}
}
close FASTA_FILE;


# verifies that we have read in an example ingroup sequence and at least one potential
# outgroup sequence
if(!$ingroup_sequence)
{
	print STDERR "Error: example ingroup sequence not read in (no sequences in input "
		."aligned fasta file). Exiting.\n";
	die;
}

my $number_potential_outgroup_sequences = scalar keys %potential_outgroup_name_to_sequence;
if(!$number_potential_outgroup_sequences)
{
	print STDERR "Error: no potential outgroup sequences read in (only one sequence in "
		."input aligned fasta file). Exiting.\n";
	die;
}

# otherwise, distance from example ingroup sequence to each potential outgroup sequence
my $closest_potential_outgroup = ""; # potential_outgroup_name closest to this sequence
my $closest_potential_outgroup_distance = -1; # number unambiguous bases different between this sequence and closest potential_outgroup_name

my @ingroup_sequence_aligned_bases = split(//, $ingroup_sequence);
foreach my $potential_outgroup_name(sort keys %potential_outgroup_name_to_sequence) # for each potential_outgroup_name sequence
{
	# counts number unambiguous differences between this sequence and this potential_outgroup_name
	my @potential_outgroup_aligned_bases = split(//, $potential_outgroup_name_to_sequence{$potential_outgroup_name});
	my $max_position = 0;
	if(scalar @potential_outgroup_aligned_bases < scalar @ingroup_sequence_aligned_bases)
	{
		$max_position = scalar @potential_outgroup_aligned_bases - 1;
	}
	else
	{
		$max_position = scalar @ingroup_sequence_aligned_bases - 1;
	}
	
	my $number_differences = 0;
	foreach my $position(0..$max_position)
	{
		my $potential_outgroup_name_base = uc($potential_outgroup_aligned_bases[$position]);
		my $sequence_base = uc($ingroup_sequence_aligned_bases[$position]);
		
		if(is_unambiguous_base($potential_outgroup_name_base) and is_unambiguous_base($sequence_base)
			and $potential_outgroup_name_base ne $sequence_base)
		{
			$number_differences++;
		}
	}
	
	# determines if this is the new closest potential_outgroup_name
	if($closest_potential_outgroup_distance == -1
		or $number_differences < $closest_potential_outgroup_distance)
	{
		$closest_potential_outgroup = $potential_outgroup_name;
		$closest_potential_outgroup_distance = $number_differences;
	}
}


# print the potential outgroup sequence with the shortest distance to the example ingroup sequence
print $closest_potential_outgroup;
print " (".$closest_potential_outgroup_distance." mutations away from example ingroup sequence)\n";


# returns 1 if base is A, T, C, or G, 0 if not
sub is_unambiguous_base
{
	my $base = $_[0];
	
	if($base eq "A" or $base eq "a")
	{
		return 1;
	}
	if($base eq "T" or $base eq "t")
	{
		return 1;
	}
	if($base eq "C" or $base eq "c")
	{
		return 1;
	}
	if($base eq "G" or $base eq "g")
	{
		return 1;
	}
	
	return 0;
}


# November 25, 2024
