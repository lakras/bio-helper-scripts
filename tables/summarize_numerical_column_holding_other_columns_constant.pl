#!/usr/bin/env perl

# Summarizes values in selected numerical column while holding other columns constant.
# Outputs table with constant columns and new columns with statistics summarizing selected
# numerical column: mean, standard deviation, median, number values, min, max, range, and
# all values sorted in a comma-separated list.

# Usage:
# perl summarize_numerical_column_holding_other_columns_constant.pl [tab-separated table]
# "[title of numerical column to summarize]" "[title of column to hold constant]"
# "[title of another column to hold constant]" [etc.]

# Prints to console. To print to file, use
# perl summarize_numerical_column_holding_other_columns_constant.pl [tab-separated table]
# "[title of numerical column to summarize]" "[title of column to hold constant]"
# "[title of another column to hold constant]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_summarize = $ARGV[1];
my @titles_of_columns_to_hold_constant = @ARGV[2..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";


my $CONCATENATED_COLUMN_TITLE_SEPARATOR = "_";
my $COLUMN_VALUES_SEPARATOR = ", ";


my $INCLUDE_ORIGINAL_COLUMN_TITLE_IN_SUMMARY_COLUMN_TITLES = 0;


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

if(!$title_of_column_to_summarize)
{
	print STDERR "Error: title of column to summarize not provided. Exiting.\n";
	die;
}

# verifies that titles of column to hold constant are provided
if(!scalar @titles_of_columns_to_hold_constant)
{
	print STDERR "Error: titles of columns to hold constant not provided. Exiting.\n";
	die;
}


# reads in and processes input table
my $column_to_summarize = -1;
my %column_title_to_column = (); # key: title of column of interest -> value: column number (0-indexed)
foreach my $column_title(@titles_of_columns_to_hold_constant, $title_of_column_to_summarize)
{
	$column_title_to_column{$column_title} = -1;
}
my %constant_column_values_to_values_to_summarize = (); # key: concatenated values of columns held constant -> value: list of values in column to summarize

my $first_line = 1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		if($first_line) # column titles
		{
			# identifies columns to merge
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title_to_column{$column_title})
				{
					if($column_title_to_column{$column_title} == -1)
					{
						$column_title_to_column{$column_title} = $column;
						if($column_title eq $title_of_column_to_summarize)
						{
							$column_to_summarize = $column;
						}
					}
					else
					{
						print STDERR "Warning: column ".$column_title." encountered more "
							."than once in table ".$table."\n";
					}
				}
				$column++;
			}
		
			# verifies that all columns have been found
			foreach my $column_title(keys %column_title_to_column)
			{
				if($column_title_to_column{$column_title} == -1)
				{
					print STDERR "Error: expected column title ".$column_title
						." not found in table ".$table
						."\nExiting.\n";
					die;
				}
				$column++;
			}
			
			# prints titles of columns to hold constant
			foreach my $column_title(@titles_of_columns_to_hold_constant)
			{
				print $column_title.$DELIMITER;
			}
			
			# prints summary statistic column titles
			my $column_title_piece = "";
			if($INCLUDE_ORIGINAL_COLUMN_TITLE_IN_SUMMARY_COLUMN_TITLES)
			{
				$column_title_piece = "_".$title_of_column_to_summarize;
			}
			
			print "mean".$column_title_piece.$DELIMITER; # mean
			print "std_dev".$column_title_piece.$DELIMITER; # standard deviation,
			print "median".$column_title_piece.$DELIMITER; # median
			print "number_values".$column_title_piece.$DELIMITER; # number values
			print "min".$column_title_piece.$DELIMITER; # min
			print "max".$column_title_piece.$DELIMITER; # max
			print "range".$column_title_piece.$DELIMITER; # range
			print "all_values_sorted".$column_title_piece.$NEWLINE; # all values sorted in a comma-separated list
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# retrieve values of columns held constant
			my $constant_columns_to_print = "";
			foreach my $column_title(@titles_of_columns_to_hold_constant)
			{
				$constant_columns_to_print .= $items_in_line[$column_title_to_column{$column_title}];
				$constant_columns_to_print .= $DELIMITER;
			}
			
			# save value of column to summarize
			my $value_to_summarize = $items_in_line[$column_to_summarize];
			push(@{$constant_column_values_to_values_to_summarize{$constant_columns_to_print}}, $value_to_summarize);
		}
	}
}
close TABLE;


# prints output
foreach my $constant_columns_to_print(keys %constant_column_values_to_values_to_summarize)
{
	# retrieves column values to summarize
	my @column_values = @{$constant_column_values_to_values_to_summarize{$constant_columns_to_print}};

	# calculates summary values
	my $mean = mean(@column_values);
	my $std_dev = std_dev(@column_values);
	my $median = median(@column_values);
	my $number_values = scalar @column_values;
	my $min = min(@column_values);
	my $max = max(@column_values);
	my $range = $min."-".$max;
	my $all_values_sorted = join($COLUMN_VALUES_SEPARATOR, sort(@column_values));

	# prints existing column values
	print $constant_columns_to_print;

	# prints new column values
	print $mean.$DELIMITER; # mean
	print $std_dev.$DELIMITER; # standard deviation
	print $median.$DELIMITER; # median
	print $number_values.$DELIMITER; # number values
	print $min.$DELIMITER; # min
	print $max.$DELIMITER; # max
	print $range.$DELIMITER; # range
	print $all_values_sorted.$NEWLINE; # all values sorted in a comma-separated list
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
# November 4, 2021
