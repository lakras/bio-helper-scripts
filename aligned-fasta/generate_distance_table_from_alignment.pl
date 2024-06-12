#!/usr/bin/env perl

# Generates 2d table of distances between all sequences in alignment.

# Usage:
# perl generate_distance_table_from_alignment.pl [alignment fasta file path]
# [1 to ignore first sequence in alignment, 0 to include it] [1 to generate R-friendly table]

# Prints to console. To print to file, use
# perl generate_distance_table_from_alignment.pl [alignment fasta file path]
# [1 to ignore first sequence in alignment, 0 to include it] [1 to generate R-friendly table]
# > [output table path]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment; reference sequence must appear first
my $ignore_reference = $ARGV[1]; # if 0, includes first sequence in alignment; if 1, ignores it
my $generate_R_friendly_table = $ARGV[2];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


my $PRINT_EACH_DISTANCE_TWICE = 0; # if 0, fills triangle rather than square


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


# prints header line
if(!$generate_R_friendly_table)
{
	# prints all sequence names
	foreach my $sequence_names_index(0..$#sequence_names)
	{
		# prints sequence name
		my $sequence_name = $sequence_names[$sequence_names_index];
		print $DELIMITER;
		print $sequence_name;
	}
	print $NEWLINE;
}
else
{
	print "sequence_1";
	print $DELIMITER;
	print "sequence_2";
	print $DELIMITER;
	print "distance";
	print $NEWLINE;
}


# compares all pairs of sequences and prints distances
my %sequence_sequence_distance = (); # key: sequence name 1 -> key: sequence name 2 -> value: distance
foreach my $sequence_names_index_1(0..$#sequence_names)
{
	my $sequence_name_1 = $sequence_names[$sequence_names_index_1];
	my $sequence_1 = $sequence_name_to_sequence{$sequence_name_1};
	
	if(!$generate_R_friendly_table)
	{
		# prints sequence name
		print $sequence_name_1;

		# prints pairs we have already printed
		foreach my $sequence_names_index_2(0..$sequence_names_index_1-1)
		{
			print $DELIMITER;
			if($PRINT_EACH_DISTANCE_TWICE)
			{
				my $sequence_name_2 = $sequence_names[$sequence_names_index_2];
				print prepare_integer_for_printing($sequence_sequence_distance{$sequence_name_1}{$sequence_name_2});
			}
		}
		
		# prints comparison of same sequence
		print $DELIMITER;
		if($PRINT_EACH_DISTANCE_TWICE)
		{
			print prepare_integer_for_printing(0);
		}
	}
	
	# makes and prints new comparisons
	foreach my $sequence_names_index_2($sequence_names_index_1+1 .. $#sequence_names)
	{
		my $sequence_name_2 = $sequence_names[$sequence_names_index_2];
		my $sequence_2 = $sequence_name_to_sequence{$sequence_name_2};
		
		# compares sequence 1 and 2
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
		
		# saves distance
		$sequence_sequence_distance{$sequence_name_1}{$sequence_name_2} = $distance;
		$sequence_sequence_distance{$sequence_name_2}{$sequence_name_1} = $distance;
		
		# prints distance if non-R-friendly table
		if(!$generate_R_friendly_table)
		{
			print $DELIMITER;
			print prepare_integer_for_printing($distance);
		}
	}
	print $NEWLINE;
}

# prints distances if R friendly table
if($generate_R_friendly_table)
{
	if($PRINT_EACH_DISTANCE_TWICE)
	{
		foreach my $sequence_name_1(@sequence_names)
		{
			foreach my $sequence_name_2(@sequence_names)
			{
				print $sequence_name_1;
				print $DELIMITER;
				print $sequence_name_2;
				print $DELIMITER;
				print $sequence_sequence_distance{$sequence_name_1}{$sequence_name_2};
				print $NEWLINE;
			}
		}
	}
	else
	{
		foreach my $sequence_names_index_1(0..$#sequence_names)
		{
			my $sequence_name_1 = $sequence_names[$sequence_names_index_1];
			foreach my $sequence_names_index_2(0..$sequence_names_index_1-1)
			{
				my $sequence_name_2 = $sequence_names[$sequence_names_index_2];
				
				print $sequence_name_1;
				print $DELIMITER;
				print $sequence_name_2;
				print $DELIMITER;
				print $sequence_sequence_distance{$sequence_name_1}{$sequence_name_2};
				print $NEWLINE;
			}
		}
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
