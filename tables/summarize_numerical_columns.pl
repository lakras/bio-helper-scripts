#!/usr/bin/env perl

# Summarizes selected numerical columns. Adds new columns with: mean, standard deviation,
# median, min, max, range, and all values sorted in a comma-separated list.

# Usage:
# perl summarize_numerical_columns.pl [tab-separated table] "[column title]"
# "[another column title]" [etc.]

# Prints to console. To print to file, use
# perl summarize_numerical_columns.pl [tab-separated table] "[column title]"
# "[another column title]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_to_summarize = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";


my $CONCATENATED_COLUMN_TITLE_SEPARATOR = "_";
my $COLUMN_VALUES_SEPARATOR = ", ";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that titles of column to summarize are provided and make sense
if(!scalar @titles_of_columns_to_summarize)
{
	print STDERR "Error: title of columns to summarize not provided. Exiting.\n";
	die;
}


# reads in and processes input table
my %column_to_summarize = (); # key: column (0-indexed) -> value: 1 if column will be summarized
my %column_title_to_column = ();
foreach my $column_title(@titles_of_columns_to_summarize)
{
	$column_title_to_column{$column_title} = -1;
}

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
						$column_to_summarize{$column} = 1;
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
			
			# generates concatenated column title
			my $concatenated_column_title = join($CONCATENATED_COLUMN_TITLE_SEPARATOR, @titles_of_columns_to_summarize);
			
			# prints existing column titles
			print $line.$DELIMITER;
			
			# prints new column titles
			print "mean_".$concatenated_column_title.$DELIMITER; # mean
			print "std_dev_".$concatenated_column_title.$DELIMITER; # standard deviation,
			print "median_".$concatenated_column_title.$DELIMITER; # median
			print "min_".$concatenated_column_title.$DELIMITER; # min
			print "max_".$concatenated_column_title.$DELIMITER; # max
			print "range_".$concatenated_column_title.$DELIMITER; # range
			print "all_values_sorted_".$concatenated_column_title.$NEWLINE; # all values sorted in a comma-separated list
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# retrieves column values to summarize
			my @column_values = ();
			foreach my $column_title(@titles_of_columns_to_summarize)
			{
				my $column = $column_title_to_column{$column_title};
				my $value = $items_in_line[$column];
			
				push(@column_values, $value);
			}
			
			# calculates summary values
			my $mean = mean(@column_values);
			my $std_dev = std_dev(@column_values);
			my $median = median(@column_values);
			my $min = min(@column_values);
			my $max = max(@column_values);
			my $range = $min."-".$max;
			my $all_values_sorted = join($COLUMN_VALUES_SEPARATOR, sort(@column_values));
			
			# prints existing column values
			print $line.$DELIMITER;
			
			# prints new column values
			print $mean.$DELIMITER; # mean
			print $std_dev.$DELIMITER; # standard deviation,
			print $median.$DELIMITER; # median
			print $min.$DELIMITER; # min
			print $max.$DELIMITER; # max
			print $range.$DELIMITER; # range
			print $all_values_sorted.$NEWLINE; # all values sorted in a comma-separated list
		}
	}
}
close TABLE;


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
