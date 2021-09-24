#!/usr/bin/env perl

# Deletes columns with specified column titles.

# Usage:
# perl delete_columns.pl [table] "[title of column to delete]"
# "[title of another column to delete]" "[title of another column to delete]" [etc.]

# Prints to console. To print to file, use
# perl delete_columns.pl [table] "[title of column to delete]"
# "[title of another column to delete]" "[title of another column to delete]" [etc.]
# > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_to_delete = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# builds hash of column titles to delete for easy lookup
my %column_title_is_to_be_deleted = (); # key: column title -> value: 1 if column should be deleted
foreach my $column_title(@titles_of_columns_to_delete)
{
	$column_title_is_to_be_deleted{$column_title} = 1;
}


# reads in and processes input table
my $first_line = 1;
my %column_to_delete = (); # key: column (0-indexed) -> value: 1 if it should be deleted
my %column_title_found = (); # key: column title -> value: 1 if column title has been found
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
			# identifies columns to delete
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title_is_to_be_deleted{$column_title})
				{
					$column_to_delete{$column} = 1;
					$column_title_found{$column_title} = 1;
				}
				$column++;
			}
			
			# verifies that we have found columns to delete
			foreach my $column_title(@titles_of_columns_to_delete)
			{
				if(!$column_title_found{$column_title})
				{
					print STDERR "Warning: input column ".$column_title." not found.\n";
				}
			}
			
			$first_line = 0; # next line is not column titles
		}
		
		# prints all values not in columns to delete
		my $column = 0;
		my $printing_first_column = 1;
		foreach my $value(@items_in_line)
		{
			if(!$column_to_delete{$column})
			{
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
			}
			$column++;
		}
		print $NEWLINE;
	}
}
close TABLE;


# August 24, 2021
# September 23, 2021
