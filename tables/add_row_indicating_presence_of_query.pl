#!/usr/bin/env perl

# Adds row with values indicating presence of query in column.

# Usage:
# perl add_row_indicating_presence_of_query.pl [table] [query]

# Prints to console. To print to file, use
# perl add_row_indicating_presence_of_query.pl [table] [query] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $query = $ARGV[1];

my $NEWLINE = "\n";
my $DELIMITER = "\t";

my $IGNORE_FIRST_LINE = 1;


# verifies that input files exist and are not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in table
my $first_line = 1;
my %column_number_to_query_present = (); # key: column number -> value: 1 if query is present
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		if(!$IGNORE_FIRST_LINE or !$first_line)
		{
			# checks if query is present in line
			my @items_in_line = split($DELIMITER, $line, -1);
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				if($value eq $query)
				{
					$column_number_to_query_present{$column} = 1;
				}
				$column++;
			}
		}
		
		# prints line as is
		print $line.$NEWLINE;
		$first_line = 0;
	}
}
close TABLE;


# prints row with presence or absence of query in each column
foreach my $column_number(sort keys %column_number_to_query_present)
{
	if($column_number_to_query_present{$column_number})
	{
		print $query.$DELIMITER;
	}
	print $NEWLINE;
}


# February 27, 2022
# March 4, 2022
