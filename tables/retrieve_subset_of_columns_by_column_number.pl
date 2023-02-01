#!/usr/bin/env perl

# Subsets table to only columns of interest.

# Usage:
# perl retrieve_subset_of_columns_by_column_number.pl [table]
# [column number of first column to include in output]
# [column number of second column to include] [etc.]

# Prints to console. To print to file, use
# perl retrieve_subset_of_columns_by_column_number.pl [table]
# [column number of first column to include in output]
# [column number of second column to include] [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @column_numbers_of_columns_to_include = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that we have been provided columns to include
if(!scalar @column_numbers_of_columns_to_include)
{
	print STDERR "Error: no columns to include provided. Exiting.\n";
	die;
}


# converts array of column numbers to include to a hash
my %include_column = (); # key: column title -> value: 1 if column should be included in output
foreach my $column_number(@column_numbers_of_columns_to_include)
{
	$include_column{$column_number} = 1;
}


# reads in and processes input table
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		
		# prints all values in columns to include
		my $column = 0;
		my $printing_first_column = 1;
		foreach my $value(@items_in_line)
		{
			if($include_column{$column})
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
# January 31, 2023
