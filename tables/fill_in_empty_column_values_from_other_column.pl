#!/usr/bin/env perl

# Fills in empty values in column of interest with values from other column. No spaces
# allowed in parameter column titles.

# Usage:
# perl fill_in_empty_column_values_from_other_column.pl [table] [title of column to fill in]
# [title of column with potential replacement values]

# Prints to console. To print to file, use
# perl fill_in_empty_column_values_from_other_column.pl [table] [title of column to fill in]
# [title of column with potential replacement values] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_fill_in = $ARGV[1];
my $title_of_column_with_replacement_values = $ARGV[2];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in and processes input table
my $first_line = 1;
my $column_to_fill_in = -1;
my $column_with_replacement_values = -1;
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
			# identifies parameter columns
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $title_of_column_to_fill_in)
				{
					if($column_to_fill_in != -1)
					{
						print STDERR "Error: title of column to fill in "
							.$title_of_column_to_fill_in." appears more than once in table:"
							."\n\t".$table."\nExiting.\n";
						die;
					}
					$column_to_fill_in = $column;
				}
				if(defined $column_title and $column_title eq $title_of_column_with_replacement_values)
				{
					if($column_with_replacement_values != -1)
					{
						print STDERR "Error: title of column with replacement values "
							.$title_of_column_with_replacement_values." appears more than once in table:"
							."\n\t".$table."\nExiting.\n";
						die;
					}
					$column_with_replacement_values = $column;
				}
				$column++;
			}
			
			# verifies that we have found both columns
			if($column_to_fill_in == -1)
			{
				print STDERR "Error: could not find title of column to fill in "
					.$title_of_column_to_fill_in." in table:\n\t".$table."\nExiting.\n";
				die;
			}
			if($column_with_replacement_values == -1)
			{
				print STDERR "Error: could not find title of column with replacement values "
					.$title_of_column_with_replacement_values." in table:\n\t".$table."\nExiting.\n";
				die;
			}
			
			# prints header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			my $replacement_value = $items_in_line[$column_with_replacement_values];
			if(!defined $replacement_value)
			{
				$replacement_value = "";
			}
		
			# prints all values, filling in empty values in column to fill in
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter
				if($column > 0)
				{
					print $DELIMITER;
				}
		
				# prints value
				if($column == $column_to_fill_in)
				{
					if(defined $value and length $value)
					{
						print $value;
					}
					else
					{
						print $replacement_value;
					}
				}
				else
				{
					if(defined $value and length $value)
					{
						print $value;
					}
				}
				$column++;
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# August 24, 2021
