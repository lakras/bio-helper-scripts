#!/usr/bin/env perl

# Deletes column with input column title.

# Usage:
# perl delete_column.pl [table] "[title of column to delete]"

# Prints to console. To print to file, use
# perl delete_column.pl [table] "[title of column to delete]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_delete = $ARGV[1];


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
my $column_to_delete = -1;
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
			# identifies column to delete
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $title_of_column_to_delete)
				{
					if($column_to_delete != -1)
					{
						print STDERR "Error: title of column to delete "
							.$title_of_column_to_delete." appears more than once in table:"
							."\n\t".$table."\nExiting.\n";
						die;
					}
					$column_to_delete = $column;
				}
				$column++;
			}
			
			# verifies that we have found column to delete
			if($column_to_delete == -1)
			{
				print STDERR "Error: could not find title of column to delete "
					.$title_of_column_to_delete." in table:\n\t".$table."\nExiting.\n";
				die;
			}
			
			$first_line = 0; # next line is not column titles
		}
		
		# prints all values not in column to delete
		my $column = 0;
		my $printing_first_column = 1;
		foreach my $value(@items_in_line)
		{
			if($column != $column_to_delete)
			{
				# prints delimiter
				if(!$printing_first_column)
				{
					print $DELIMITER;
				}
				$printing_first_column = 0;
				
				# prints value
				if(defined $value)
				{
					print $value;
				}
			}
			$column++;
		}
		print $NEWLINE;
	}
}
close TABLE;


# August 24, 2021
