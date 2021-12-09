#!/usr/bin/env perl

# Counts number occurrences of each value in selected column of table.

# Usage:
# perl count_occurrences_of_column_values.pl [tab-separated table] "[column title]"

# Prints to console. To print to file, use
# perl count_occurrences_of_column_values.pl [tab-separated table] "[column title]"
# > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $column_title = $ARGV[1];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# read in input table
my $first_line = 1;
my $column_of_interest = -1;
my %column_value_to_count = (); # key: column value -> value: number occurrences
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my $line = $_;
		my @items_in_line = split($DELIMITER, $line, -1);
	
		if($first_line) # column titles
		{
			# saves index of column of interest
			my $column = 0;
			foreach my $this_column_title(@items_in_line)
			{
				if($this_column_title eq $column_title)
				{
					if($column_of_interest != -1)
					{
						print STDERR "Error: title of column of interest ".$column_title
							." appears more than once. Exiting.\n";
						die;
					}
					$column_of_interest = $column;
				}
				$column++;
			}
			
			# verifies that we have found column of interest
			if($column_of_interest == -1)
			{
				print STDERR "Error: title of column of interest ".$column_title
					." not found. Exiting.\n";
				die;
			}
		
			# next line is not column titles
			$first_line = 0;
		}
		else # column values
		{
			my $column_value = $items_in_line[$column_of_interest];
			$column_value_to_count{$column_value}++;
		}
	}
}
close TABLE;


# prints output column titles
print $column_title.$DELIMITER;
print "count".$NEWLINE;


# prints number occurrences of each value
foreach my $column_value(sort {$column_value_to_count{$a} <=> $column_value_to_count{$b}}
	keys %column_value_to_count)
{
	print $column_value.$DELIMITER;
	print $column_value_to_count{$column_value}.$NEWLINE;
}


# December 9, 2021
