#!/usr/bin/env perl

# Fills in empty values in column of interest with an increasing numerical index value,
# so that every empty cell contains a unique numerical value.

# Usage:
# perl fill_in_empty_column_values_with_increasing_numerical_index.pl [table]
# "[title of column to fill in]"

# Prints to console. To print to file, use
# perl fill_in_empty_column_values_with_increasing_numerical_index.pl [table]
# "[title of column to fill in]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_fill_in = $ARGV[1];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in and processes input table
my $count = 1;
my $first_line = 1;
my $column_to_fill_in = -1;
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
			# identifies column to fill in
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $title_of_column_to_fill_in)
				{
					if($column_to_fill_in != -1)
					{
						print STDERR "Error: title of column to fill in "
							.$title_of_column_to_fill_in." appears more than once in table:"
							."\n\t".$table."\nExiting.\n";
						die;
					}
					$column_to_fill_in = $column;
				}
				$column++;
			}
			
			# verifies that we have found column to fill in
			if($column_to_fill_in == -1)
			{
				print STDERR "Error: could not find title of column to fill in "
					.$title_of_column_to_fill_in." in table:\n\t".$table."\nExiting.\n";
				die;
			}
			
			# prints header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# prints all values, filling in empty values in column to fill in
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter
				if($column > 0)
				{
					print $DELIMITER;
				}
		
				# prints value
				if($column == $column_to_fill_in)
				{
					if(defined $value and length $value)
					{
						print $value;
					}
					else
					{
						print $count;
						$count++;
					}
				}
				else
				{
					if(defined $value and length $value)
					{
						print $value;
					}
				}
				$column++;
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# August 24, 2021
# January 23, 2023
