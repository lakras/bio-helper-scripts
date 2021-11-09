#!/usr/bin/env perl

# Adds column with specified title and specified value for all values.

# Usage:
# perl add_one_value_column.pl [table to add column to] "[title of column to add]"
# "[value of column to add]"

# Prints to console. To print to file, use
# perl add_one_value_column.pl [table to add column to] "[title of column to add]"
# "[value of column to add]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_add = $ARGV[1];
my $value_of_column_to_add = $ARGV[2];

my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input table exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table to add column to not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in and adds column to table to add columns to
my $first_line = 1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		if($first_line) # column titles
		{
			# prints line as is
			print $line;
			
			# prints title of new column
			print $DELIMITER;
			print $title_of_column_to_add;
			print $NEWLINE;
			
			$first_line = 0;
		}
		else # column values (not column titles)
		{
			# prints line as is
			print $line;
			
			# prints value of new column
			print $DELIMITER;
			print $value_of_column_to_add;
			print $NEWLINE;
		}
	}
}
close TABLE;


# September 26, 2021
# November 8, 2021
