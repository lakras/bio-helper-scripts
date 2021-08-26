#!/usr/bin/env perl

# Summarizes all values appearing in columns to summarize (sample ids and dates, for
# example) for each shared value (patient id, for example). Adds summary in new column.

# Usage:
# perl add_shared_values_summary_column.pl [tab-separated table]
# [title of column containing values shared by rows]
# [title of column to include in summary of shared values]
# [title of another column to include in summary of shared values] [etc.]

# Prints to console. To print to file, use
# perl add_shared_values_summary_column.pl [tab-separated table]
# [title of column containing values shared by rows]
# [title of column to include in summary of shared values]
# [title of another column to include in summary of shared values] [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_with_shared_values = $ARGV[1];
my @titles_of_columns_to_include_in_summary = @ARGV[2..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that titles of column to merge on are provided and make sense
if(!defined $title_of_column_with_shared_values or !length $title_of_column_with_shared_values)
{
	print STDERR "Error: title of column with shared values not provided. Exiting.\n";
	die;
}
if(!scalar @titles_of_columns_to_include_in_summary)
{
	print STDERR "Error: title of columns to summarize not provided. Exiting.\n";
	die;
}


# reads in and processes input table
my %column_to_summarize = (); # key: column (0-indexed) -> value: 1 if column will be summarized
my %summary_column_title_to_column = ();
foreach my $column_title(@titles_of_columns_to_include_in_summary)
{
	$summary_column_title_to_column{$column_title} = -1;
}
my $column_with_shared_values = -1;

my %shared_value_to_summary = (); # key: value in column with shared values -> value: summary to print in new column

my $first_line = 1;
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
			# identifies columns to merge
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $summary_column_title_to_column{$column_title})
				{
					if($summary_column_title_to_column{$column_title} == -1)
					{
						$summary_column_title_to_column{$column_title} = $column;
						$column_to_summarize{$column} = 1;
					}
					else
					{
						print STDERR "Warning: column ".$column_title." encountered more "
							."than once in table ".$table."\n";
					}
				}
				elsif($column_title eq $title_of_column_with_shared_values)
				{
					$column_with_shared_values = $column;
				}
				$column++;
			}
		
			# verifies that all columns have been found
			foreach my $column_title(keys %summary_column_title_to_column)
			{
				if($summary_column_title_to_column{$column_title} == -1)
				{
					print STDERR "Error: expected column title ".$column_title
						." not found in table ".$table
						."\nExiting.\n";
					die;
				}
				elsif($column_with_shared_values == -1)
				{
					print STDERR "Error: expected column title "
						.$title_of_column_with_shared_values." not found in table "
						.$table."\nExiting.\n";
					die;
				}
				$column++;
			}
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# retrieves shared value to generate summary for
			my $shared_value = $items_in_line[$column_with_shared_values];
			
			# retrieves summary values without duplicates
			my %summary_values = (); # key: value in a summary column -> value: 1 (to eliminate duplicates)
			foreach my $summary_value_column(values %summary_column_title_to_column)
			{
				if(defined $items_in_line[$summary_value_column] and length $items_in_line[$summary_value_column])
				{
					$summary_values{$items_in_line[$summary_value_column]} = 1;
				}
			}
			
			# generates this row's addition to shared value's summary
			my $summary_contribution = join(" ", sort keys %summary_values);
			
			# adds this rows addition to shared value's summary
			if($shared_value_to_summary{$shared_value})
			{
				$shared_value_to_summary{$shared_value} .= ", ";
			}
			$shared_value_to_summary{$shared_value} .= $summary_contribution;
		}
	}
}
close TABLE;


# prints table with added summary column
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
			# generates summary column title
			my $summary_column_title = join("/", @titles_of_columns_to_include_in_summary)
				."_by_".$title_of_column_with_shared_values;
			
			# prints existing column titles
			print $line.$DELIMITER;
			
			# prints summary column
			print $summary_column_title.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# retrieves shared value we generated summary for
			my $shared_value = $items_in_line[$column_with_shared_values];
			
			# prints existing column values
			print $line.$DELIMITER;
			
			# prints summary column
			if(defined $shared_value_to_summary{$shared_value} and length $shared_value_to_summary{$shared_value})
			{
				print $shared_value_to_summary{$shared_value};
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# August 26, 2021
