#!/usr/bin/env perl

# Filters table by column values. Only includes rows equal to, greater than, or less than
# column value of interest in column to filter by.

# Usage:
# perl filter_table_rows_by_numerical_column_value.pl [tab-separated table]
# [0 to match cells equal to query, 1: less than, 2: less than or equal to, 3: greater than, 4: greater than or equal to]
# "[title of column to filter by]" "[column value to select]"

# Prints to console. To print to file, use
# perl filter_table_rows_by_numerical_column_value.pl [tab-separated table]
# [0 to match cells equal to query, 1: less than, 2: less than or equal to, 3: greater than, 4: greater than or equal to]
# "[title of column to filter by]" "[column value to select]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $option = $ARGV[1]; # 0 to match cells equal to query, 1: less than, 2: less than or equal to, 3: greater than, 4: greater than or equal to
my $title_of_column_to_filter_by = $ARGV[2]; # no spaces
my $query = $ARGV[3];


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
			if(!$column_value)
			{
				$column_value = 0;
			}
			
			# prints this line if the value of interest is in the column to filter by
			if($option == 0 and $column_value == $query     # 0 to match cells equal to query,
				or $option == 1 and $column_value < $query  # 1 to match cells less than query
				or $option == 2 and $column_value <= $query # 2 to match cells less than or equal to query
				or $option == 3 and $column_value > $query  # 3 to match cells greater than query
				or $option == 4 and $column_value >= $query)# 4 to match cells greater than or equal to query
			{
				print $line.$NEWLINE;
			}
		}
	}
}
close TABLE;

# August 12, 2021
# August 25, 2021
# September 26, 2021
