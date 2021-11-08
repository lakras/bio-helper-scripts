#!/usr/bin/env perl

# Summarizes read depths across read depth tables. Outputs table with reference name;
# position; and mean, standard deviation, median, min, max, and range of read depths at
# each position, and number of read depth values at each position that are 0.

# Read depth tables must be in format produced by samtools depth (tab-separated reference
# name, position, read depth; no header line).

# Usage:
# perl summarize_read_depths_across_files.pl [read depth table] [another read depth table]
# [another read depth table] [etc.]

# Prints to console. To print to file, use
# perl summarize_read_depths_across_files.pl [read depth table] [another read depth table]
# [another read depth table] [etc.] > [output table path]


use strict;
use warnings;


my @read_depth_tables = @ARGV[0..$#ARGV]; # all files must be relative to same reference


# columns in read-depth tables produced by samtools:
my $READ_DEPTH_REFERENCE_COLUMN = 0; # reference must be same across all input files
my $READ_DEPTH_POSITION_COLUMN = 1; # 1-indexed
my $READ_DEPTH_COLUMN = 2;


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";

my $SAME_REFERENCES_AND_POSITIONS_IN_ALL_FILES = 1; # if 1, assumes all files use the same reference and should include all positions; fills in any missing read depths in a file as 0s


# verifies that input files exist
if(!scalar @read_depth_tables)
{
	print STDERR "Error: no read depth tables provided. Exiting.\n";
	die;
}
foreach my $read_depth_table(@read_depth_tables)
{
	if(!$read_depth_table or !-e $read_depth_table)
	{
		print STDERR "Error: read depth table does not exist, or empty:\n\t"
			.$read_depth_table."\nExiting.\n";
		die;
	}
}


# reads in read depth tables
my %reference_to_position_to_read_depths = (); # key: reference -> key: position -> value: list of read depths at position, one value per input file
foreach my $read_depth_table(@read_depth_tables)
{
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
			push(@{$reference_to_position_to_read_depths{$reference}{$position}}, $read_depth);
		}
	}
	close READ_DEPTH_TABLE;
}


if($SAME_REFERENCES_AND_POSITIONS_IN_ALL_FILES)
{
	# counts the number of values at each position
	my $maximum_number_read_depths_at_a_position = 0;
	foreach my $reference(keys %reference_to_position_to_read_depths)
	{
		foreach my $position(keys %{$reference_to_position_to_read_depths{$reference}})
		{
			my $number_read_depths_at_position = scalar @{$reference_to_position_to_read_depths{$reference}{$position}};
			if($number_read_depths_at_position > $maximum_number_read_depths_at_a_position)
			{
				$maximum_number_read_depths_at_a_position = $number_read_depths_at_position;
			}
		}
	}


	# verifies that each position has the same number of values; adds 0s if not
	foreach my $reference(keys %reference_to_position_to_read_depths)
	{
		foreach my $position(keys %{$reference_to_position_to_read_depths{$reference}})
		{
			my $number_read_depths_at_position = scalar @{$reference_to_position_to_read_depths{$reference}{$position}};
			while($number_read_depths_at_position < $maximum_number_read_depths_at_a_position)
			{
				push(@{$reference_to_position_to_read_depths{$reference}{$position}}, 0);
				$number_read_depths_at_position = scalar @{$reference_to_position_to_read_depths{$reference}{$position}};
			}
		}
	}
}


# prints header line
print "reference".$DELIMITER;
print "position".$DELIMITER;
print "read_depth_mean".$DELIMITER; # mean
print "read_depth_std_dev".$DELIMITER; # standard deviation,
print "read_depth_median".$DELIMITER; # median
print "read_depth_min".$DELIMITER; # min
print "read_depth_max".$DELIMITER; # max
print "read_depth_range".$DELIMITER; # range
print "number_zero_values".$NEWLINE;


# calculates and prints summary of read depths at each position
foreach my $reference(sort keys %reference_to_position_to_read_depths)
{
	foreach my $position(sort {$a <=> $b} keys %{$reference_to_position_to_read_depths{$reference}})
	{
		# retrieves read depths at this position
		my @read_depths_at_position = @{$reference_to_position_to_read_depths{$reference}{$position}};
	
		# calculates summary values
		my $mean = mean(@read_depths_at_position);
		my $std_dev = std_dev(@read_depths_at_position);
		my $median = median(@read_depths_at_position);
		my $min = min(@read_depths_at_position);
		my $max = max(@read_depths_at_position);
		my $range = $min."-".$max;
		my $number_zero_values = number_zero_values(@read_depths_at_position);
	
		# prints position
	 	print $reference.$DELIMITER;
		print $position.$DELIMITER;
	
		# prints read depth summary column values
		print $mean.$DELIMITER; # mean
		print $std_dev.$DELIMITER; # standard deviation,
		print $median.$DELIMITER; # median
		print $min.$DELIMITER; # min
		print $max.$DELIMITER; # max
		print $range.$DELIMITER; # range
		print $number_zero_values.$NEWLINE; # range
	}
}


# returns number of values equal to 0
sub number_zero_values
{
	my @values = @_;
	
	my $number_zeros = 0;
	foreach my $value(@values)
	{
		if(!$value)
		{
			$number_zeros++;
		}
	}
	return $number_zeros;
}

# returns minimum value in input array
sub min
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# retrieves minimum value
	my $min_value = $values[0];
	foreach my $value(@values)
	{
		if($value < $min_value)
		{
			$min_value = $value;
		}
	}
	return $min_value;
}

# returns maximum value in input array
sub max
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# retrieves maximum value
	my $max_value = $values[0];
	foreach my $value(@values)
	{
		if($value > $max_value)
		{
			$max_value = $value;
		}
	}
	return $max_value;
}

# returns mean of input array
sub mean
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# sums all values
	my $sum = 0;
	foreach my $value(@values)
	{
		$sum += $value;
	}
	return $sum/scalar @values;
}

# returns standard deviation of input array
sub std_dev
{
	my @values = @_;
	
	# returns if we don't have enough input values
	if(scalar @values < 2)
	{
		return $NO_DATA;
	}
	
	# calculates mean
	my $mean = mean(@values);
	
	# calculates sum of squared differences from the mean
	my $sum_of_squared_differences = 0;
	foreach my $value(@values)
	{
		my $difference = $mean - $value;
		$sum_of_squared_differences += $difference * $difference;
	}
	
	# calculates and returns standard deviation
	return sqrt($sum_of_squared_differences / (scalar @values - 1))
}

# returns median of input array
sub median
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# sorts values
	@values = sort @values;
	
	# returns center
	if(scalar @values % 2 == 0) # even number of values
	{
		return ($values[scalar @values/2] + $values[scalar @values/2-1])/2;
	}
	else # odd number of values
	{
		return $values[scalar @values/2];
	}
}

# August 26, 2021
# September 26, 2021
# November 8, 2021
