#!/usr/bin/env perl

# In rows where a column has a present, non-zero value, replaces value in another column
# with parameter replacement value.

# Usage:
# perl replace_column_values_where_other_column_present_and_nonzero.pl [table]
# "[title of column to check]" "[title of column to fill in]" "[replacement value]"

# Prints to console. To print to file, use
# perl replace_column_values_where_other_column_present_and_nonzero.pl [table]
# "[title of column to check]" "[title of column to fill in]" "[replacement value]"
# > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_check = $ARGV[1];
my $title_of_column_to_fill_in = $ARGV[2];
my $replacement_value = $ARGV[3];


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
my $column_to_check = -1;
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
				if(defined $column_title and $column_title eq $title_of_column_to_check)
				{
					if($column_to_check != -1)
					{
						print STDERR "Error: title of column with check "
							.$title_of_column_to_check." appears more than once in table:"
							."\n\t".$table."\nExiting.\n";
						die;
					}
					$column_to_check = $column;
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
			if($column_to_check == -1)
			{
				print STDERR "Error: could not find title of column with check "
					.$title_of_column_to_check." in table:\n\t".$table."\nExiting.\n";
				die;
			}
			
			# prints header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			my $value_to_check = $items_in_line[$column_to_check];
			
			# prints all values, replacing in column to fill in as appropriate
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter
				if($column > 0)
				{
					print $DELIMITER;
				}
		
				# prints value
				if($column == $column_to_fill_in
					and defined $value_to_check
					and (length $value_to_check or $value_to_check))
				{
					print $replacement_value;
				}
				else
				{
					if(defined $value and (length $value or $value))
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
