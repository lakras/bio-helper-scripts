#!/usr/bin/env perl

# Duplicates selected columns.

# Usage:
# perl duplicate_columns.pl [tab-separated table] "[column title]" "[another column title]"
# [etc.]

# Prints to console. To print to file, use
# perl duplicate_columns.pl [tab-separated table] "[column title]" "[another column title]"
# [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_to_duplicate = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";


my $PRINT_DUPLICATE_VALUES = 0;
my $SORT_VALUES = 1;
my $CONCATENATED_VALUE_SEPARATOR = ", ";
my $CONCATENATED_COLUMN_TITLE_SEPARATOR = "_";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that titles of column to duplicate are provided and make sense
if(!scalar @titles_of_columns_to_duplicate)
{
	print STDERR "Error: title of columns to duplicate not provided. Exiting.\n";
	die;
}


# reads in and processes input table
my %column_to_duplicate = (); # key: column (0-indexed) -> value: 1 if column will be duplicated
my %column_title_to_column = ();
foreach my $column_title(@titles_of_columns_to_duplicate)
{
	$column_title_to_column{$column_title} = -1;
}

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
				if(defined $column_title_to_column{$column_title})
				{
					if($column_title_to_column{$column_title} == -1)
					{
						$column_title_to_column{$column_title} = $column;
						$column_to_duplicate{$column} = 1;
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
			
			# prints existing column titles
			print $line;
			
			# generates and prints duplicated column titles
			# in order of their column titles provided in input
			foreach my $column_title(@titles_of_columns_to_duplicate)
			{
				print $DELIMITER.$column_title."_copy";
			}
			print $NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# prints existing values
			print $line;
			
			# retrieves and prints duplicated values
			# in order of their column titles provided in input
			foreach my $column_title(@titles_of_columns_to_duplicate)
			{
				my $column = $column_title_to_column{$column_title};
				my $value = $items_in_line[$column];
				
				print $DELIMITER;
				if(defined $value and length $value)
				{
					print $value;
				}
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# August 27, 2021
