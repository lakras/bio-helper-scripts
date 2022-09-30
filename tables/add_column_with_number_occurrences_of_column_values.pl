#!/usr/bin/env perl

# Adds column indicating number occurrences of that row's value(s) in the entirety of the
# parameter column(s).

# Usage:
# perl add_column_with_number_occurrences_of_column_values.pl [tab-separated table]
# "[column title]" "[optional additional column title]"
# "[optional additional column title]" [etc.]

# Prints to console. To print to file, use
# perl add_column_with_number_occurrences_of_column_values.pl [tab-separated table]
# "[column title]" "[optional additional column title]"
# "[optional additional column title]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @column_titles = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";

# for generating output column title
my $OUTPUT_COUNT_COLUMN_TITLE_ADDITION = "count";
my $OUTPUT_COUNT_COLUMN_TITLE_DELIMITER = "_";


# verifies that input file exists and is not empty
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


# generates output column title
my $output_column_title = join($OUTPUT_COUNT_COLUMN_TITLE_DELIMITER, @column_titles,
	$OUTPUT_COUNT_COLUMN_TITLE_ADDITION);


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
			# retrieves values of columns of interest for this row and adds to their value
			# combination's count
			my $column_values_string = "";
			foreach my $column_title(@column_titles) # for each column of interest
			{
				# retrieves column value
				my $column = $column_title_to_column{$column_title};
				my $column_value = $items_in_line[$column];
				if(!defined $column_value)
				{
					$column_value = "";
				}
				
				if($column_values_string)
				{
					$column_values_string .= $DELIMITER;
				}
				$column_values_string .= $column_value;
			}
			
			# increments count for each column of interest value combination from this row
			$column_value_combination_to_count{$column_values_string}++;
		}
	}
}
close TABLE;


# reads in table a second time, printing previously generated counts in new column
$first_line = 1;
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
			# prints column titles
			print $line.$DELIMITER;
			print $output_column_title.$NEWLINE;
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# retrieves values of columns of interest for this row and adds to their value
			# combination's count
			my $column_values_string = "";
			foreach my $column_title(@column_titles) # for each column of interest
			{
				# retrieves column value
				my $column = $column_title_to_column{$column_title};
				my $column_value = $items_in_line[$column];
				if(!defined $column_value)
				{
					$column_value = "";
				}
				
				if($column_values_string)
				{
					$column_values_string .= $DELIMITER;
				}
				$column_values_string .= $column_value;
			}
			
			# prints column values
			print $line.$DELIMITER;
			print $column_value_combination_to_count{$column_values_string}.$NEWLINE;
		}
	}
}
close TABLE;


# December 9, 2021
# September 30, 2022
