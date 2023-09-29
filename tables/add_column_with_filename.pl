#!/usr/bin/env perl

# Adds column with table filename in all values.

# Usage:
# perl add_column_with_filename.pl [table to add column to]

# Prints to console. To print to file, use
# perl add_column_with_filename.pl [table to add column to] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];


my $REMOVE_ALL_FILE_EXTENSIONS = 1;

my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input table exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table to add column to not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# retrieve table file name from table file path
my $table_filename = $table;
if($table_filename =~ /^.*\/(.*)$/) # remove directory path
{
	$table_filename = $1;
}
if($table_filename =~ /^(.*)[.].*$/) # remove file extension
{
	$table_filename = $1;
}
if($REMOVE_ALL_FILE_EXTENSIONS)
{
	while($table_filename =~ /^(.*)[.].*$/) # remove file extension
	{
		$table_filename = $1;
	}
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
			print "filename";
			print $NEWLINE;
			
			$first_line = 0;
		}
		else # column values (not column titles)
		{
			# prints line as is
			print $line;
			
			# prints value of new column
			print $DELIMITER;
			print $table_filename;
			print $NEWLINE;
		}
	}
}
close TABLE;


# September 26, 2021
# November 8, 2021
# June 9, 2023
