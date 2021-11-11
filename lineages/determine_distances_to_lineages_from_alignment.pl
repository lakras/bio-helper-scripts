#!/usr/bin/env perl

# Generates 2d table of distances between all sequences in alignment to lineage sequences.

# Usage:
# perl determine_distances_to_lineages_from_alignment.pl [alignment fasta file path]
# "[name of lineage sequence]" "[name of another lineage sequence]" [etc.]

# Prints to console. To print to file, use
# perl determine_distances_to_lineages_from_alignment.pl [alignment fasta file path]
# "[name of lineage sequence]" "[name of another lineage sequence]" [etc.]
# > [output fasta file path]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment; reference sequence must appear first
my @lineage_sequence_names = @ARGV[1..$#ARGV]; # all lineage sequence names must appear in alignment file


my $NEWLINE = "\n";
my $DELIMITER = "\t";


my $PRINT_DISTANCES_BETWEEN_LINEAGES = 1; # if 1, prints distances between lineages as well


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

# verifies that we have at least one lineage sequence name
if(scalar @lineage_sequence_names < 1)
{
	print STDERR "Error: No lineage sequence names provided. Exiting.\n";
	die;
}


# generates hash from lineage sequence names for easy lookup
my %is_lineage_sequence_name = (); # key: sequence name -> value: 1 if sequence is lineage sequence
foreach my $lineage_sequence_name(@lineage_sequence_names)
{
	$is_lineage_sequence_name{$lineage_sequence_name} = 1;
}


# reads in fasta sequences
my $reference_sequence_read_in = 0;
my $current_sequence = "";
my $current_sequence_name = "";
my @sequence_names = (); # list of sequence names in order they were read in
my %sequence_name_to_sequence = (); # key: sequence name -> value: sequence
open FASTA_FILE, "<$alignment_file" || die "Could not open $alignment_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			if(!$ignore_reference or $reference_sequence_read_in)
			{
				$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
				push(@sequence_names, $current_sequence_name);
			}
			$reference_sequence_read_in = 1;
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
close FASTA_FILE;
if($current_sequence and (!$ignore_reference or $reference_sequence_read_in))
{
	$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
	push(@sequence_names, $current_sequence_name);
}


# verifies that all lineage sequence names have been found in alignment file
foreach my $lineage_sequence_name(@lineage_sequence_names)
{
	if(!$sequence_name_to_sequence{$lineage_sequence_name})
	{
		print STDERR "Error: no sequence provided for lineage ".$lineage_sequence_name
			.". Exiting.\n";
		die;
	}
}


# prints all lineage sequence names
foreach my $lineage_sequence_name(@lineage_sequence_names)
{
	# prints sequence name
	print $DELIMITER;
	print $lineage_sequence_name;
}
print $NEWLINE;


# compares all sequences to lineage sequences and prints distances
foreach my $sequence_name(@sequence_names)
{
	if($PRINT_DISTANCES_BETWEEN_LINEAGES or !$is_lineage_sequence_name{$sequence_name})
	{
		my $sequence = $sequence_name_to_sequence{$sequence_name};
	
		# prints sequence name
		print $sequence_name;
		
		# prints comparisons
		foreach my $lineage_sequence_name(@lineage_sequence_names)
		{
			my $lineage_sequence = $sequence_name_to_sequence{$lineage_sequence_name};
		
			# compares sequence to lineage sequence
			my $distance = 0;
			for(my $base_index = 0; $base_index < maximum(length($sequence), length($lineage_sequence)); $base_index++)
			{
				my $sequence_base = substr($sequence, $base_index, 1);
				my $lineage_sequence_base = substr($lineage_sequence, $base_index, 1);
	
				if(is_unambiguous_base($sequence_base) and is_unambiguous_base($lineage_sequence_base)
					and $sequence_base ne $lineage_sequence_base)
				{
					$distance++;
				}
			}
		
			# prints distance
			print $DELIMITER;
			print prepare_integer_for_printing($distance);
		}
		print $NEWLINE;
	}
}


# returns maximum of 2 values
sub maximum
{
	my $value_1 = $_[0];
	my $value_2 = $_[1];
	
	if($value_1 > $value_2)
	{
		return $value_1;
	}
	return $value_2;
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

# returns "0" if 0, input integer otherwise
sub prepare_integer_for_printing
{
	my $integer = $_[0];
	if($integer)
	{
		return $integer;
	}
	return "0";
}


# November 11, 2021
