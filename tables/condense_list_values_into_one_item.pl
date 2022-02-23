#!/usr/bin/env perl

# For any values in specified columns that are comma-separated lists, replaces
# comma-separated list with the first, smallest, or largest value in the list.

# Usage:
# perl condense_list_values_into_one_item.pl [table]
# [0 to use the first value, 1 to use the smallest value, 2 to use the greatest value]
# "[title of column to replace lists in]" "[title of another column to replace lists in]"
# "[title of another column to replace lists in]" [etc.]

# Prints to console. To print to file, use
# perl condense_list_values_into_one_item.pl [table]
# [0 to use the first value, 1 to use the smallest value, 2 to use the greatest value]
# "[title of column to replace lists in]" "[title of another column to replace lists in]"
# "[title of another column to replace lists in]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $option = $ARGV[1]; # 0 to use the first value, 1 to use the smallest value, 2 to use the greatest value
my @titles_of_columns_to_search = @ARGV[2..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that we have been provided column titles
if(!scalar @titles_of_columns_to_search)
{
	print STDERR "Error: no column titles provided. Exiting.\n";
	die;
}

# verifies that option makes sense
if($option < 0 or $option > 2)
{
	print STDERR "Error: option ".$option." not recognized. Selecting first value by default.\n";
	$option = 1;
}


# converts array of column titles to a hash
my %title_is_of_column_to_search = (); # key: column title -> value: 1 if column has dates
my %column_title_to_column = (); # key: included column title -> value: column
foreach my $column_title(@titles_of_columns_to_search)
{
	$title_is_of_column_to_search{$column_title} = 1;
	$column_title_to_column{$column_title} = -1;
}


# reads in and processes input table
my $first_line = 1;
my %column_is_column_to_search = (); # key: column (0-indexed) -> value: 1 if column has dates
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
				if(defined $column_title and $title_is_of_column_to_search{$column_title})
				{
					$column_is_column_to_search{$column} = 1;
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
			
			# print header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# prints all values, replacing values in columns to search
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter
				if($column > 0)
				{
					print $DELIMITER;
				}
				
				# replaces values that are lists if this is a column to search
				if($column_is_column_to_search{$column})
				{
					# if value is a comma-separated list, retrieves the first value in the list
					my @values = split(", ", $value, -1);
					if($option == 0) # first value
					{
						$value = $values[0];
					}
					elsif($option == 1) # smallest value
					{
						@values = sort {$a <=> $b} @values;
						$value = $values[0];
					}
					elsif($option == 2) # greatest value
					{
						@values = sort {$b <=> $a} @values;
						$value = $values[0];
					}
					else
					{
						print STDERR "Error: option ".$option." not recognized. "
							."Selecting first value by default.\n";
						$value = $values[0];
					}
				}
		
				# prints value
				if(defined $value and length $value)
				{
					print $value;
				}
				$column++;
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# August 24, 2021
# February 9, 2022
