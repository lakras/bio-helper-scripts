#!/usr/bin/env perl

# Subsets table to only rows of interest (those containing one of the specified values in
# the specified column).

# Usage:
# perl retrieve_subset_of_rows.pl [file path of table] "[title of column to filter by]"
# [file path of list of values to filter that column to]

# Prints to console. To print to file, use
# perl retrieve_subset_of_rows.pl [file path of table] "[title of column to filter by]"
# [file path of list of values to filter that column to] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_filter_by = $ARGV[1];
my $values_of_rows_to_include = $ARGV[2];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in values to filter column to
my %include_value = (); # key: possible value in column to filter by -> value: 1 if it is to be included
open VALUES_TO_INCLUDE, "<$values_of_rows_to_include" || die "Could not open $values_of_rows_to_include to read; terminating =(\n";
while(<VALUES_TO_INCLUDE>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		$include_value{$_} = 1;
	}
}
close VALUES_TO_INCLUDE;


# reads in and processes input table
my $first_line = 1;
my $column_to_filter_by = -1;
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
			# identifies column to filter by
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title
					and $column_title eq $title_of_column_to_filter_by)
				{
					$column_to_filter_by = $column;
				}
				$column++;
			}
			
			# verifies that we have found column to filter by
			if($column_to_filter_by == -1)
			{
				print STDERR "Error: expected title of column to filter by "
					.$title_of_column_to_filter_by." not found in table ".$table
					."\nExiting.\n";
				die;
			}
			
			# prints column titles
			print $line;
			print $NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else
		{
			# determines whether or not to print this row, and prints if so
			my $value_in_column_to_filter_by = $items_in_line[$column_to_filter_by];
			if($include_value{$value_in_column_to_filter_by})
			{
				print $line;
				print $NEWLINE;
			}
		}
	}
}
close TABLE;


# February 1, 2023
