#!/usr/bin/env perl

# Prints ranges of positions with read depths at or above minimum read depth.

# Usage:
# perl retrieve_position_ranges_with_threshold_read_depth.pl [minimum read depth]
# [read depth table] [optional 1 to print output as one line]

# Prints to console. To print to file, use
# perl retrieve_position_ranges_with_threshold_read_depth.pl [minimum read depth]
# [read depth table] [optional 1 to print output as one line] > [output path]


use strict;
use warnings;


my $minimum_read_depth = $ARGV[0];
my $read_depth_table = $ARGV[1]; # read depth table produced by samtools with tab separated columns: name of reference, position relative to reference (1-indexed), read depth
my $print_as_one_line = $ARGV[2]; # if 1, prints all position ranges in one line with no other columns


# columns in read-depth tables produced by samtools:
my $READ_DEPTH_REFERENCE_COLUMN = 0; # reference must be same across all input files
my $READ_DEPTH_POSITION_COLUMN = 1; # 1-indexed
my $READ_DEPTH_COLUMN = 2;


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";


my $PRINT_DISTANCE_BETWEEN_RANGES = 0; # if 1, prints number of bases between ranges
my $PRINT_RANGE_LENGTHS = 0; # if 1, prints lengths of ranges
my $PRINT_RANGE_START_END_AS_SEPARATE_COLUMNS = 0; # if 1, prints start and end of range as two separate columns
my $RANGE_START_END_SEPARATOR = " - "; # printed between the start and end of a range

my $PRINT_AS_ONE_LINE_RANGE_START_END_SEPARATOR = " "; # printed between the start and end of a range when all position ranges printed on one line
my $PRINT_AS_ONE_LINE_RANGES_SEPARATOR = " "; # printed between position ranges when all position ranges printed on one line


# verifies that input file exists and is non-empty
if(!$read_depth_table or !-e $read_depth_table or -z $read_depth_table)
{
	print STDERR "Error: read depth table not provided, does not exist, or is empty:\n\t"
		.$read_depth_table."\nExiting.\n";
	die;
}


# reads in read depth table
my %reference_to_position_to_read_depth = (); # key: reference -> key: position -> value: read depth
open READ_DEPTH_TABLE, "<$read_depth_table" || die "Could not open $read_depth_table to read; terminating =(\n";
while(<READ_DEPTH_TABLE>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		# reads in mapped values
		my @items_in_row = split($DELIMITER, $_);

		my $position = $items_in_row[$READ_DEPTH_POSITION_COLUMN];
		my $read_depth = $items_in_row[$READ_DEPTH_COLUMN];
		my $reference = $items_in_row[$READ_DEPTH_REFERENCE_COLUMN];
		
		# saves read depth
		$reference_to_position_to_read_depth{$reference}{$position} = $read_depth;
	}
}
close READ_DEPTH_TABLE;


# prints header line
if($PRINT_DISTANCE_BETWEEN_RANGES)
{
	print "distance_from_previous_range".$DELIMITER;
}
print "reference".$DELIMITER;
if($PRINT_RANGE_START_END_AS_SEPARATE_COLUMNS)
{
	print "position_range_passing_threshold_start";
	print $DELIMITER;
	print "position_range_passing_threshold_end";
}
else
{
	print "position_range_passing_threshold";
}
if($PRINT_RANGE_LENGTHS)
{
	print $DELIMITER."position_range_length";
}
print $NEWLINE;


# calculates and prints ranges of positions with read depths at or above minimum
foreach my $reference(sort keys %reference_to_position_to_read_depth)
{
	my $currently_in_range_passing_threshold = 0;
	my $current_range_start = -1;
	my $previous_position = -1;
	my $previous_position_passing_threshold = -1;
	foreach my $position(sort {$a <=> $b} keys %{$reference_to_position_to_read_depth{$reference}})
	{
		# read depth at position passes threshold
		if($reference_to_position_to_read_depth{$reference}{$position} >= $minimum_read_depth)
		{
			# check for state change
			if(!$currently_in_range_passing_threshold)
			{
				# prints distance from previous range
				if(!$print_as_one_line and $PRINT_DISTANCE_BETWEEN_RANGES)
				{
					if($previous_position_passing_threshold != -1)
					{
						my $distance_from_previous_range = $position - $previous_position_passing_threshold - 1;
						print $distance_from_previous_range.$DELIMITER;
					}
					else
					{
						print $NO_DATA.$DELIMITER;
					}
				}
				
				# open new range
				$currently_in_range_passing_threshold = 1;
				$current_range_start = $position;
				if(!$print_as_one_line)
				{
					print $reference.$DELIMITER.$position;
					if($PRINT_RANGE_START_END_AS_SEPARATE_COLUMNS)
					{
						print $DELIMITER;
					}
					else
					{
						print $RANGE_START_END_SEPARATOR;
					}
				}
				else
				{
					# print as one line
					print $position.$PRINT_AS_ONE_LINE_RANGE_START_END_SEPARATOR;
				}
			}
			$previous_position_passing_threshold = $position;
		}
		else # read depth at position does not pass threshold
		{
			# check for state change
			if($currently_in_range_passing_threshold)
			{
				# print close of range
				print $previous_position;
				
				# print length of range
				if(!$print_as_one_line)
				{
					my $range_length = $previous_position - $current_range_start + 1;
					if($PRINT_RANGE_LENGTHS)
					{
						print $DELIMITER.$range_length;
					}
					print $NEWLINE;
				}
				else
				{
					# print as one line
					print $PRINT_AS_ONE_LINE_RANGES_SEPARATOR;
				}
				
				# close range
				$currently_in_range_passing_threshold = 0;
				$current_range_start = -1;
			}
		}
		$previous_position = $position;
	}
	
	# closes range if it hasn't been closed
	if($currently_in_range_passing_threshold and $previous_position != -1)
	{
		# print close of range
		print $previous_position;
		
		# print length of range
		my $range_length = $previous_position - $current_range_start + 1;
		if($PRINT_RANGE_LENGTHS)
		{
			print $DELIMITER.$range_length;
		}
		print $NEWLINE;
		
		# close range
		$currently_in_range_passing_threshold = 0;
		$current_range_start = -1;
	}
}


# November 8, 2021
