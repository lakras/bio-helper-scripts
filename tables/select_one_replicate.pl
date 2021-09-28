#!/usr/bin/env perl

# Given a table with multiple replicates from the same source, selects one replicate per
# source, using selected column to select replicate. In the event of a tie, selects first
# appearing replicate.

# Usage:
# perl select_one_replicate.pl [tab-separated table]
# "[title of column containing source of each replicate (same value for every replicate from the same source)]"
# "[title of column to use to select replicate]"
# [0 to select replicate with smallest numerical value, 1 to select replicate with largest numerical value]

# Prints to console. To print to file, use
# perl select_one_replicate.pl [tab-separated table]
# "[title of column containing source of each replicate (same value for every replicate from the same source)]"
# "[title of column to use to select replicate]"
# [0 to select replicate with smallest numerical value, 1 to select replicate with largest numerical value]
# > [annotated output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $source_column_title = $ARGV[1];
my $comparison_column_title = $ARGV[2];
my $option = $ARGV[3]; # 0 to select replicate with smallest numerical value, 1 to select replicate with largest numerical value


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
if($option != 0 and $option != 1)
{
	print STDERR "Error: option not 0 or 1. Exiting.\n";
	die;
}


# reads in input table, recording smallest or largest numerical value for each replicate
my $first_line = 1;
my $source_column = -1;
my $comparison_column = -1;
my %source_to_winning_comparison_value = (); # key: source name -> value: winning value attached to replicate to print for this source
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
			# identifies column to compare by and column containing source id
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if($column_title eq $source_column_title)
				{
					$source_column = $column;
				}
				elsif($column_title eq $comparison_column_title)
				{
					$comparison_column = $column;
				}
				$column++;
			}
		
			# verifies that all columns have been found
			if($source_column == -1 or $comparison_column == -1)
			{
				print STDERR "Error: expected column titles not found. Exiting.\n";
				die;
			}
		
			# next line is not column titles
			$first_line = 0;
		}
		else # column values
		{
			# retrieves name of source and value to compare replicates by
			my $source = $items_in_line[$source_column];
			my $comparison_value = $items_in_line[$comparison_column];
			
			# saves comparison value if it wins
			if(!defined $source_to_winning_comparison_value{$source}
				or $option == 0 and $comparison_value < $source_to_winning_comparison_value{$source}
				or $option == 1 and $comparison_value > $source_to_winning_comparison_value{$source})
			{
				$source_to_winning_comparison_value{$source} = $comparison_value;
			}
		}
	}
}
close TABLE;


# reads in input table again, printing row for only one selected replicate from each source
$first_line = 1;
my %source_printed = (); # key: source name -> value: 1 if a row has been printed for this source
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
			# prints column titles as they are
			print $line.$NEWLINE;
		
			# next line is not column titles
			$first_line = 0;
		}
		else # column values
		{
			# retrieves name of source and value to compare replicates by
			my $source = $items_in_line[$source_column];
			my $comparison_value = $items_in_line[$comparison_column];
			
			# prints this row if it contains the winning comparison value for this source
			# and a replicate from this source has not been printed in a previous row
			if($comparison_value == $source_to_winning_comparison_value{$source}
				and !$source_printed{$source})
			{
				print $line.$NEWLINE;
				$source_printed{$source} = 1;
			}
		}
	}
}
close TABLE;


# September 28, 2021
