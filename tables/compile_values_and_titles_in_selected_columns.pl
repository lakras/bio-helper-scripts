#!/usr/bin/env perl

# Generates a new column with the values in selected columns and their column titles,
# where values are present.

# Usage:
# perl compile_values_and_titles_in_selected_columns.pl [tab-separated table]
# [column title] [another column title] [etc.]

# Prints to console. To print to file, use
# perl compile_values_and_titles_in_selected_columns.pl [tab-separated table]
# [column title] [another column title] [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_to_concatenate = @ARGV[1..$#ARGV];


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

# verifies that titles of column to concatenate are provided and make sense
if(!scalar @titles_of_columns_to_concatenate)
{
	print STDERR "Error: title of columns to concatenate not provided. Exiting.\n";
	die;
}


# reads in and processes input table
my %column_to_concatenate = (); # key: column (0-indexed) -> value: 1 if column will be concatenated
my %column_title_to_column = ();
foreach my $column_title(@titles_of_columns_to_concatenate)
{
	$column_title_to_column{$column_title} = -1;
}

my $first_line = 1;
my @column_to_column_title = (); # key: column (0-indexed) -> value: column title
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
			@column_to_column_title = @items_in_line;
		
			# identifies columns to merge
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title_to_column{$column_title})
				{
					if($column_title_to_column{$column_title} == -1)
					{
						$column_title_to_column{$column_title} = $column;
						$column_to_concatenate{$column} = 1;
					}
					else
					{
						print STDERR "Warning: column ".$column_title." encountered more "
							."than once in table ".$table."\n";
					}
				}
				$column++;
			}
		
			# verifies that all columns have been found
			foreach my $column_title(keys %column_title_to_column)
			{
				if($column_title_to_column{$column_title} == -1)
				{
					print STDERR "Error: expected column title ".$column_title
						." not found in table ".$table
						."\nExiting.\n";
					die;
				}
				$column++;
			}
			
			# generates concatenated column title
			my $concatenated_column_title = "compiled_".join("_", @titles_of_columns_to_concatenate);
			
			# prints existing column titles
			print $line.$DELIMITER;
			
			# prints concatenated column title
			print $concatenated_column_title.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# retrieves column values and titles to concatenate
			my %column_value_to_titles = (); # key: column value -> value: comma-separated list of selected column titles containing this value
			my @values_in_order = ();
			foreach my $column_title(@titles_of_columns_to_concatenate)
			{
				my $column = $column_title_to_column{$column_title};
				my $value = $items_in_line[$column];
			
				if(defined $value and length $value)
				{
					# saves column value in order it appeared, if we haven't seen it before
					if(!$column_value_to_titles{$value})
					{
						push(@values_in_order, $value)
					}
				
					# saves column title
					if($column_value_to_titles{$value})
					{
						$column_value_to_titles{$value} .= ", ";
					}
					$column_value_to_titles{$value} .= $column_title;
				}
			}
			
			# puts together concatenated values and column titles to print
			my $concatenated_values = "";
			foreach my $value(@values_in_order)
			{
				if($concatenated_values)
				{
					$concatenated_values .= "; ";
				}
				$concatenated_values .= $value." (".$column_value_to_titles{$value}.")";
			}
			
			# prints existing column titles
			print $line.$DELIMITER;
			
			# prints concatenated column title
			print $concatenated_values.$NEWLINE;
		}
	}
}
close TABLE;


# August 26, 2021
