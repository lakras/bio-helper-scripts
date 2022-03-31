#!/usr/bin/env perl

# Replaces whole column (including title unless hardcoded option selected) with empty
# values.

# Usage:
# perl replace_whole_column_with_empty_values.pl [table] "[column title]"
# "[another column title]" [etc.]

# Prints to console. To print to file, use
# perl replace_whole_column_with_empty_values.pl [table] "[column title]"
# "[another column title]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_to_wipe = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";

my $WIPE_COLUMN_TITLES = 1; # if 1, also wipes out column titles; if 0, wipes out values but not column titles


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that we have been provided column titles
if(!scalar @titles_of_columns_to_wipe)
{
	print STDERR "Error: no column titles provided. Exiting.\n";
	die;
}


# converts array of column titles to a hash
my %title_is_of_column_to_wipe = (); # key: column title -> value: 1 if column has dates
my %column_title_to_column = (); # key: included column title -> value: column
foreach my $column_title(@titles_of_columns_to_wipe)
{
	$title_is_of_column_to_wipe{$column_title} = 1;
	$column_title_to_column{$column_title} = -1;
}


# reads in and processes input table
my $first_line = 1;
my %column_is_column_to_wipe = (); # key: column (0-indexed) -> value: 1 if we are removing this column
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
			# identifies columns to include
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $title_is_of_column_to_wipe{$column_title})
				{
					$column_is_column_to_wipe{$column} = 1;
					$column_title_to_column{$column_title} = $column;
				}
				$column++;
			}
			
			# verifies that we have found all columns to include
			foreach my $column_title(keys %column_title_to_column)
			{
				if($column_title_to_column{$column_title} == -1)
				{
					print STDERR "Error: expected column title ".$column_title
						." not found in table ".$table."\nExiting.\n";
					die;
				}
			}
		}
		
		# prints all values, replacing values in columns to wipe
		my $column = 0;
		foreach my $value(@items_in_line)
		{
			# prints delimiter
			if($column > 0)
			{
				print $DELIMITER;
			}
		
			# replaces values if this is a column to search
			if((!$column_is_column_to_wipe{$column} # we aren't wiping this column
				or !$WIPE_COLUMN_TITLES and $first_line) # this is the header line and we aren't wiping the header line
				and defined $value and length $value)
			{
				# prints value
				print $value;
			}
			$column++;
		}
		print $NEWLINE;
		$first_line = 0; # next line is not column titles
	}
}
close TABLE;


# August 24, 2021
# March 31, 2022
