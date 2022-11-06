#!/usr/bin/env perl

# Adds a column indicating whether or not there is a difference between two columns.

# Usage:
# perl add_column_comparing_two_columns.pl [tab-separated table]
# "[title of first column to compare]" "[title of second column to compare]"
# [1 to print the actual values when different]
# "[optional new column title]" "[optional new column value if values are identical]"
# "[optional new column value if values are different]"
# "[optional new column value if one value missing]"
# "[optional new column value if both values missing]"

# Prints to console. To print to file, use
# perl add_column_comparing_two_columns.pl [tab-separated table]
# "[title of first column to compare]" "[title of second column to compare]"
# [1 to print the actual values when different]
# "[optional new column title]" "[optional new column value if values are identical]"
# "[optional new column value if values are different]"
# "[optional new column value if one value missing]"
# "[optional new column value if both values missing]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $column_title_1 = $ARGV[1];
my $column_title_2 = $ARGV[2];
my $print_values_if_different = $ARGV[3];
my $output_column_title = $ARGV[4]; # optional
my $output_value_same = $ARGV[5]; # optional
my $output_value_different = $ARGV[6]; # optional
my $output_value_one_missing = $ARGV[7]; # optional
my $output_value_both_missing = $ARGV[8]; # optional


my $NEWLINE = "\n";
my $DELIMITER = "\t";

# output defaults
my $DEFAULT_OUTPUT_VALUE_SAME = "same";
my $DEFAULT_OUTPUT_VALUE_DIFFERENT = "different";
my $DEFAULT_OUTPUT_VALUE_ONE_MISSING = "";
my $DEFAULT_OUTPUT_VALUE_BOTH_MISSING = "";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# sets empty values to defaults
if(!$output_column_title)
{
	$output_column_title = "compare ".$column_title_1." ".$column_title_2;
}
if(!$output_value_same)
{
	$output_value_same = $DEFAULT_OUTPUT_VALUE_SAME;
}
if(!$output_value_different)
{
	$output_value_different = $DEFAULT_OUTPUT_VALUE_DIFFERENT;
}
if(!$output_value_one_missing)
{
	$output_value_one_missing = $DEFAULT_OUTPUT_VALUE_ONE_MISSING;
}
if(!$output_value_both_missing)
{
	$output_value_both_missing = $DEFAULT_OUTPUT_VALUE_BOTH_MISSING;
}


# reads in table and generates new column title
my $first_line = 1;
my $column_1 = -1;
my $column_2 = -1;
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
			# identifies columns of interest
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if($column_title eq $column_title_1)
				{
					$column_1 = $column;
				}
				elsif($column_title eq $column_title_2)
				{
					$column_2 = $column;
				}
				$column++;
			}
			
			# verifies that we have found all columns of interest
			if($column_1 == -1 or $column_2 == -1)
			{
				print STDERR "Error: input columns ".$column_title_1." and ".$column_title_2
					." not both found. Exiting.\n";
				die;
			}
			$first_line = 0; # next line is not column titles
			
			# prints column titles line as is with new column
			print $line.$DELIMITER;
			print $output_column_title.$NEWLINE;
		}
		else # column values (not column titles)
		{
			# retrieves values of columns of interest and compares them
			my $column_1_value = $items_in_line[$column_1];
			my $column_2_value = $items_in_line[$column_2];
			
			my $comparison_value = "";
			if(!$column_1_value and !$column_2_value)
			{
				$comparison_value = $output_value_both_missing;
			}
			elsif(!$column_1_value or !$column_2_value)
			{
				$comparison_value = $output_value_one_missing;
			}
			elsif($column_1_value eq $column_2_value)
			{
				$comparison_value = $output_value_same;
			}
			else
			{
				$comparison_value = $output_value_different;
				if($print_values_if_different)
				{
					$comparison_value .= ": ".$column_1_value."; ".$column_2_value;
				}
			}
			
			# prints line as is with new column
			print $line.$DELIMITER;
			print $comparison_value.$NEWLINE;
		}
	}
}
close TABLE;


# returns 1 if string is empty; returns 0 if string is not empty
sub is_empty
{
	my $value = $_[0];
	if(defined $value and length $value)
	{
		return 0;
	}
	return 1;
}





# October 11, 2022
