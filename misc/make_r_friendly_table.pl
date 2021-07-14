#!/usr/bin/env perl

# Converts table into R-friendly format.

# Example input with $first_data_column 1
# (Extra tabs added for readability--actual input file is tab-separated):
#		1: root;	10: root;cellular organisms;
# 1A	67			1
# 1B	80			0

# Output example
# (Extra tabs added for readability)
# id	column_title					value
# 1A	1: root;						67
# 1A	10: root;cellular organisms;	1
# 1B	1: root;						80
# 1B	10: root;cellular organisms;	0

# Example input with $first_data_column 2
# (Extra tabs added for readability--actual input file is tab-separated):
#		days	1: root;	10: root;cellular organisms;
# 1A	5		67			1
# 1B	3		80			0

# Output example
# (Extra tabs added for readability)
# id	days	column_title					value
# 1A	5		1: root;						67
# 1A	5		10: root;cellular organisms;	1
# 1B	3		1: root;						80
# 1B	3		10: root;cellular organisms;	0

# Usage:
# perl make_r_friendly_table.pl [table file path] [first data column]

# Prints to console. To print to file, use
# perl make_r_friendly_table.pl [table file path] [first data column] > [output file path]


use strict;
use warnings;


my $in_table = $ARGV[0]; # file path of tab-separated table
my $first_data_column = $ARGV[1]; # first column (0-indexed) in input table that contains data values


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input table exists and is non-empty
if(!$in_table)
{
	print STDERR "Error: no input table file provided. Exiting.\n";
	die;
}
if(!-e $in_table)
{
	print STDERR "Error: input table file does not exist:\n\t".$in_table."\nExiting.\n";
	die;
}
if(-z $in_table)
{
	print STDERR "Error: input table file is empty:\n\t".$in_table."\nExiting.\n";
	die;
}

# verifies that first data column is a non-negative value
if($first_data_column < 0)
{
	print STDERR "Error: negative first data column ".$first_data_column." provided. "
		."Exiting.\n";
	die;
}


# reads in input table and converts to R-friendly format
open IN_TABLE, "<$in_table" || die "Could not open $in_table to read; terminating =(\n";
my $first_line = 1;
my @column_titles = ();
while(<IN_TABLE>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $_);
		if($first_line) # first row contains column titles
		{
			# records column titles
			foreach my $item(@items_in_line)
			{
				push @column_titles, $item;
			}
			
			# adds "id" as default first column title
			if(!$column_titles[0])
			{
				$column_titles[0] = "id";
			}
			
			# prints header line of output
			# prints everything preceding first data column
			for(my $non_data_column = 0; $non_data_column < $first_data_column; $non_data_column++)
			{
				print $column_titles[$non_data_column].$DELIMITER;
			}
			
			# prints column titles corresponding to value column entries
			print "column_title".$DELIMITER;
			print "value".$NEWLINE;
			
			# next line will not values rather than column titles column titles
			$first_line = 0;
		}
		else # this line contains values (rather than column titles)
		{
			for(my $data_column = $first_data_column; $data_column <= $#items_in_line; $data_column++)
			{
				# prints output line
				# prints everything preceding first data column
				for(my $non_data_column = 0; $non_data_column < $first_data_column; $non_data_column++)
				{
					print $items_in_line[$non_data_column].$DELIMITER;
				}
				
				# prints value column
				print $column_titles[$data_column].$DELIMITER;
				print $items_in_line[$data_column].$NEWLINE;
			}
		}
	}
}
close IN_TABLE;


# March 18, 2015
# July 14, 2021
