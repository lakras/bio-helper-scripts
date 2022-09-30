#!/usr/bin/env perl

# Summarizes frequency of all column values and combinations of column values in columns
# of interest in table.

# Usage:
# perl summarize_column_value_combination_frequencies.pl [table to summarize]
# "[title of column of interest]" "[optional title of another column of interest]"
# "[optional title of another column of interest]" [etc.]

# Prints to console. To print to file, use
# perl summarize_column_value_combination_frequencies.pl [table to summarize]
# "[title of column of interest]" "[optional title of another column of interest]"
# "[optional title of another column of interest]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @column_titles = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";

my $OUTPUT_COUNT_COLUMN_TITLE = "count";
my $ALL_VALUES_COLUMN_VALUE = "any";


# verifies that input files exist and are not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that input table columns provided
if(scalar @column_titles < 1)
{
	print STDERR "Error: no column titles provided. Exiting.\n";
	die;
}


# prepares to read in column titles
my $first_line = 1;
my %column_title_found = (); # key: column title -> value: 1 if column title has been found
my %column_title_to_column = (); # key: title of column of interest -> value: column (0-indexed)
my %column_title_of_interest = (); # key: title of column of interest -> value: 1
foreach my $column_title(@column_titles)
{
	$column_title_of_interest{$column_title} = 1;
}


# reads in table
my %column_value_combination_to_count = (); # key: values in columns of interest, tab-separated -> value: number of rows that combination appears in
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
				if(defined $column_title and $column_title_of_interest{$column_title})
				{
					$column_title_found{$column_title} = 1;
					$column_title_to_column{$column_title} = $column;
				}
				$column++;
			}
			
			# verifies that we have found all columns of interest
			foreach my $column_title(@column_titles)
			{
				if(!$column_title_found{$column_title})
				{
					print STDERR "Warning: input column of interest ".$column_title." not "
						."found. Exiting.\n";
					die;
				}
			}
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# generates all combinations of values of columns of interest for this row
			my @column_value_strings = (); # rows of output table for this row
			my $padding_tabs = "";
			foreach my $column_title(@column_titles) # for each column of interest
			{
				# retrieves column value
				my $column = $column_title_to_column{$column_title};
				my $column_value = $items_in_line[$column];
				if(!defined $column_value)
				{
					$column_value = "";
				}
				
				# for each existing column value string: adds a tab to the end, makes a
				# duplicate with the new column value added
				my @updated_column_value_strings = ();
				foreach my $column_value_string(@column_value_strings)
				{
					push(@updated_column_value_strings, $column_value_string.$DELIMITER.$ALL_VALUES_COLUMN_VALUE);
					push(@updated_column_value_strings, $column_value_string.$DELIMITER.$column_value);
				}
				
				# adds new value to output table for just this column, not in combination
				# with other columns
				push(@updated_column_value_strings, $padding_tabs.$column_value);
				
				# wraps up this iteration
				@column_value_strings = @updated_column_value_strings;
				$padding_tabs .= $ALL_VALUES_COLUMN_VALUE.$DELIMITER;
			}
			
			# increments count for each column of interest value combination from this row
			foreach my $column_value_string(@column_value_strings)
			{
				$column_value_combination_to_count{$column_value_string}++;
			}
		}
	}
}
close TABLE;


# prints titles of columns of interest and new count column
foreach my $column_title(@column_titles)
{
	print $column_title.$DELIMITER;
}
print $OUTPUT_COUNT_COLUMN_TITLE.$NEWLINE;

# prints table-wide counts for all column value combinations
foreach my $column_value_combination(keys %column_value_combination_to_count)
{
	print $column_value_combination.$DELIMITER;
	print $column_value_combination_to_count{$column_value_combination};
	print $NEWLINE;
}


# September 28, 2022
