#!/usr/bin/env perl

# Removes non-unique values in comma-separated lists in specified columns.

# Usage:
# perl remove_nonunique_values_in_list_in_column.pl [table] "[column title]"
# "[another column title]" "[another column title]" [etc.]

# Prints to console. To print to file, use
# perl remove_nonunique_values_in_list_in_column.pl [table] "[column title]"
# "[another column title]" "[another column title]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_to_modify = @ARGV[1..$#ARGV];


my $LIST_SEPARATOR = ", "; # separating items in lists in specified columns
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
if(!scalar @titles_of_columns_to_modify)
{
	print STDERR "Error: no column titles provided. Exiting.\n";
	die;
}


# converts array of column titles to a hash
my %title_is_of_column_to_search = (); # key: column title -> value: 1 if column has dates
my %column_title_to_column = (); # key: included column title -> value: column
foreach my $column_title(@titles_of_columns_to_modify)
{
	$title_is_of_column_to_search{$column_title} = 1;
	$column_title_to_column{$column_title} = -1;
}


# reads in and processes input table
my $first_line = 1;
my %column_is_column_to_modify = (); # key: column (0-indexed) -> value: 1 if column has dates
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
					$column_is_column_to_modify{$column} = 1;
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
			# prints all values, replacing values in columns to modify
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter
				if($column > 0)
				{
					print $DELIMITER;
				}
				
				# removes non-unique values from list if this is a column to modify
				if(defined $value and length $value and $column_is_column_to_modify{$column})
				{
					my @list_values = split($LIST_SEPARATOR, $value);
					my %unique_values = ();
					foreach my $list_value(@list_values)
					{
						$unique_values{$list_value} = 1;
					}
					$value = join($LIST_SEPARATOR, sort keys %unique_values);
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
# January 17, 2022
