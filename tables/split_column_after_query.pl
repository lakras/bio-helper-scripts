#!/usr/bin/env perl

# Splits column into two columns following appearance of query in each column value. If
# a cell does not contain the query, duplicates the column value.

# Usage:
# perl split_column_after_query.pl [table] "[column name]" "[query]"

# Prints to console. To print to file, use
# perl split_column_after_query.pl [table] "[column name]" "[query]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_split = $ARGV[1];
my $query = $ARGV[2];


my $NEWLINE = "\n";
my $DELIMITER = "\t";

# if 1, input column title is actually column number
my $INPUT_COLUMN_NUMBER_NOT_TITLE = 0;


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in and processes input table
my $column_to_split = -1;
my $first_line = 1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		
		if($INPUT_COLUMN_NUMBER_NOT_TITLE)
		{
			$column_to_split = $title_of_column_to_split;
		}
		elsif($first_line) # column titles
		{
			# identifies columns to include
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $title_of_column_to_split)
				{
					$column_to_split = $column;
				}
				$column++;
			}
			
			# verifies that we have found all columns to include
			if($column_to_split == -1)
			{
				print STDERR "Error: expected column title ".$title_of_column_to_split
					." not found in table ".$table."\nExiting.\n";
				die;
			}
			
			$first_line = 0; # next line is not column titles
		}
		
		# prints all column values
		my $column = 0;
		my $printing_first_column = 1;
		foreach my $value(@items_in_line)
		{
			# splits column value if we are in the column to split
			if($column == $column_to_split)
			{
				if($value =~ /^([^$query]*)$query(.*)$/)
				{
					$value = $1.$DELIMITER.$2;
				}
				else
				{
					$value = $value.$DELIMITER.$value;
				}
			}
		
			# prints delimiter
			if(!$printing_first_column)
			{
				print $DELIMITER;
			}
			$printing_first_column = 0;
			
			# prints value
			if(defined $value)
			{
				print $value;
			}
			$column++;
		}
		print $NEWLINE;
	}
}
close TABLE;


# December 6, 2022
