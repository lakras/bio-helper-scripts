#!/usr/bin/env perl

# Counts number unambiguous differences between each pair of sequences listed in input file.

# Usage:
# perl compare_pairs_of_sequences_from_list.pl
# [pairs of sequence names, space-separated, one per line] [alignment fasta file path]

# Prints to console. To print to file, use
# perl compare_pairs_of_sequences_from_list.pl
# [pairs of sequence names, space-separated, one per line] [alignment fasta file path]
# > [output table path]


use strict;
use warnings;


my $sequence_pairs = $ARGV[0]; # pairs of sequence names, space-separated, one per line
my $alignment_file = $ARGV[1]; # fasta alignment; reference sequence must appear first


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $SAMPLE_PAIR_DELIMITER = " ";


# reads in fasta sequences
my $current_sequence = "";
my $current_sequence_name = "";
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
			$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
		}
		
		# save new sequence name and prepare to read in new sequence
		$current_sequence_name = $1;
		if($current_sequence_name =~ /(.*)\|.*/)
		{
			$current_sequence_name = $1;
		}
		$current_sequence = "";
	}
	else # not header line
	{
		$current_sequence .= uc($_);
	}
}
close FASTA_FILE;
if($current_sequence)
{
	$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
}


# reads in pairs of sequence names, adds genetic distance as a column value, and prints line
open SEQUENCE_PAIRS, "<$sequence_pairs" || die "Could not open $sequence_pairs to read\n";
while(<SEQUENCE_PAIRS>)
{
	chomp;
	my $line = $_;
	if($line =~ /\S/)
	{
		if($line =~ /(.*)$DELIMITER(.*)/)
		{
			# retrieves sequence names
			my $sequence_name_1 = $1;
			my $sequence_name_2 = $2;
			
			# retrieves sequences
			my $sequence_1 = "";
			if($sequence_name_to_sequence{$sequence_name_1})
			{
				$sequence_1 = $sequence_name_to_sequence{$sequence_name_1};
			}
			else
			{
				print STDERR "Error: sequence not found: ".$sequence_name_1."\n";
			}
			
			my $sequence_2 = "";
			if($sequence_name_to_sequence{$sequence_name_2})
			{
				$sequence_2 = $sequence_name_to_sequence{$sequence_name_2};
			}
			else
			{
				print STDERR "Error: sequence not found: ".$sequence_name_2."\n";
			}
			
			# compares sequences
			if($sequence_1 and $sequence_2)
			{
				my $distance = 0;
				for(my $base_index = 0; $base_index < maximum(length($sequence_1), length($sequence_2)); $base_index++)
				{
					my $sequence_1_base = substr($sequence_1, $base_index, 1);
					my $sequence_2_base = substr($sequence_2, $base_index, 1);
			
					if(is_unambiguous_base($sequence_1_base) and is_unambiguous_base($sequence_2_base)
						and $sequence_1_base ne $sequence_2_base)
					{
						$distance++;
					}
				}
				
				# prints sequence names and distance
				print $sequence_name_1.$DELIMITER;
				print $sequence_name_2.$DELIMITER;
				print $distance.$NEWLINE;
			}
		}
		else
		{
			print STDERR "Line format not recognized:\n".$line."\n";
		}
	}
}
close SEQUENCE_PAIRS;


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
