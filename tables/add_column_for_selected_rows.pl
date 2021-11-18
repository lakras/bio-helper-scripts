#!/usr/bin/env perl

# Creates new column with values in selected rows.

# Usage:
# perl add_column_for_selected_rows.pl [table to add new column to]
# "[title of column in table to identify rows by]"
# [file with list of rows to select, one per line] "[optional title of new column to add]"
# "[optional value to add to selected rows in new column]"
# "[optional value to add to all other rows in new column]"

# Prints to console. To print to file, use
# perl add_column_for_selected_rows.pl [table to add new column to]
# "[title of column in table to identify rows by]"
# [file with list of rows to select, one per line] "[optional title of new column to add]"
# "[optional value to add to selected rows in new column]"
# "[optional value to add to all other rows in new column]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0]; # table to add column to
my $table_title_of_column_to_merge_by = $ARGV[1]; # title of column to select rows by
my $list_of_rows_to_add_to = $ARGV[2]; # file with list of rows to select, identified by values in column to select rows by, one per line
my $title_of_new_column = $ARGV[3]; # optional title of new column to add
my $new_column_value_for_selected_rows = $ARGV[4]; # optional value to add to selected rows in new column
my $new_column_value_for_other_rows = $ARGV[5]; # optional value to add to all other rows in new column


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input files exist and are not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table to add columns to not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}
if(!$list_of_rows_to_add_to or !-e $list_of_rows_to_add_to or -z $list_of_rows_to_add_to)
{
	print STDERR "Error: list of rows to add to not provided, does not exist, or empty:\n\t"
		.$list_of_rows_to_add_to."\nExiting.\n";
	die;
}

# verifies that input table columns make sense
if(!defined $table_title_of_column_to_merge_by)
{
	print STDERR "Error: column title to merge by not provided. Exiting.\n";
	die;
}


# sets optional values if not selected
if(!defined $title_of_new_column)
{
	$title_of_new_column = $list_of_rows_to_add_to;
}
if(!defined $new_column_value_for_selected_rows)
{
	$new_column_value_for_selected_rows = "TRUE";
}
if(!defined $new_column_value_for_other_rows)
{
	$new_column_value_for_other_rows = "FALSE";
}


# reads in list of rows to add to
my %row_to_add_to = (); # key: value in column to merge by of row to add to -> value: 1
open LIST_OF_ROWS_TO_ADD_TO, "<$list_of_rows_to_add_to" || die "Could not open $list_of_rows_to_add_to to read; terminating =(\n";
while(<LIST_OF_ROWS_TO_ADD_TO>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		$row_to_add_to{$line} = 1;
	}
}
close LIST_OF_ROWS_TO_ADD_TO;


# reads in and adds column to table to add columns to
my $first_line = 1;
my $table_column_to_merge_by = -1;
my %row_found = (); # key: value in column to merge by of row to add to -> value: 1 if row found in table
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
			# identifies column to merge by and columns to save
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $table_title_of_column_to_merge_by)
				{
					if($table_column_to_merge_by != -1)
					{
						print STDERR "Warning: column title ".$table_title_of_column_to_merge_by
							." of column to merge by appears more than once in input "
							."table:\n\t".$table."\n";
					}
					$table_column_to_merge_by = $column;
				}
				$column++;
			}
			
			# verifies that we have found column to merge by
			if($table_column_to_merge_by == -1)
			{
				print STDERR "Warning: column title ".$table_title_of_column_to_merge_by
					." of column to merge by not found in input table:\n\t".$table
					."\nExiting.\n";
				die;
			}
			$first_line = 0; # next line is not column titles
			
			# prints line as is
			print $line;
			
			# prints titles of new column
			print $DELIMITER;
			print $title_of_new_column;
			print $NEWLINE;
		}
		else # column values (not column titles)
		{
			# retrieves value to merge by
			my $value_to_merge_by = $items_in_line[$table_column_to_merge_by];
			
			# prints line as is
			print $line;
			
			# prints new column value
			print $DELIMITER;
			if(defined $value_to_merge_by and $row_to_add_to{$value_to_merge_by})
			{
				print $new_column_value_for_selected_rows;
				$row_found{$value_to_merge_by} = 1;
			}
			else
			{
				print $new_column_value_for_other_rows;
			}
			
			print $NEWLINE;
		}
	}
}
close TABLE;


# verifies that we have found all rows
foreach my $row_value(keys %row_to_add_to)
{
	if(!$row_found{$row_value})
	{
		print STDERR "Warning: expected value ".$row_value." not found in table.\n";
	}
}


# September 26, 2021
# November 18, 2021
