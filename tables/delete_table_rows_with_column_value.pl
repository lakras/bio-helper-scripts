#!/usr/bin/env perl

# Deletes rows in table by column values. Only includes rows without column value
# containing text to filter out in column to filter by. Case-sensitive.

# Usage:
# perl delete_table_rows_with_column_value.pl [tab-separated table] "[query to select rows to delete]"
# [0 to match cells containing query, 1: beginning with, 2: ending with, 3: equal to]
# "[title of column to filter by]"

# Prints to console. To print to file, use
# perl delete_table_rows_with_column_value.pl [tab-separated table] "[query to select rows to delete]"
# [0 to match cells containing query, 1: beginning with, 2: ending with, 3: equal to]
# "[title of column to filter by]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $column_value_to_select = $ARGV[1];
my $option = $ARGV[2]; # 0 to match cells containing query, 1: beginning with, 2: ending with, 3: equal to
my $title_of_column_to_filter_by = $ARGV[3];


my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in replacement map file


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}
if(!$title_of_column_to_filter_by)
{
	print STDERR "Error: title of column to filter not provided. Exiting.\n";
	die;
}

# verifies option
if($option != 0 and $option != 1 and $option != 2 and $option != 3)
{
	print STDERR "Error: option provided ".$option." is not recognized. Exiting.\n";
	die;
}

# read in input table
my $first_line = 1;
my $column_to_filter_by = -1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my $line = $_;
		my @items_in_line = split($DELIMITER, $line, -1);
	
		if($first_line) # column titles
		{
			# identifies column to filter by
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if($column_title eq $title_of_column_to_filter_by)
				{
					$column_to_filter_by = $column;
				}
				$column++;
			}
		
			# verifies that all columns have been found
			if($column_to_filter_by == -1)
			{
				print STDERR "Error: expected column title not found. Exiting.\n";
				die;
			}
			
			# prints column titles
			print $line.$NEWLINE;
		
			# next line is not column titles
			$first_line = 0;
		}
		else # column values
		{
			# retrieves value in column of interest
			my $column_value = $items_in_line[$column_to_filter_by];
			
			# does not print this line if the value of interest is in the column to filter by
			if(!$column_value and !$column_value_to_select # both 0s
				or !length($column_value) and !length($column_value_to_select) # both empty strings
				or $option == 3 and defined $column_value and defined $column_value_to_select and $column_value =~ /^$column_value_to_select$/ # equal to
				or $option == 2 and defined $column_value and defined $column_value_to_select and $column_value =~ /$column_value_to_select$/ # ending with
				or $option == 1 and defined $column_value and defined $column_value_to_select and $column_value =~ /^$column_value_to_select/ # beginning with
				or $option == 0 and defined $column_value and defined $column_value_to_select and $column_value =~ /$column_value_to_select/) # containing
			{
				# not printing
			}
			else
			{
				print $line.$NEWLINE;
			}
		}
	}
}
close TABLE;

# August 12, 2021
# August 23, 2021
