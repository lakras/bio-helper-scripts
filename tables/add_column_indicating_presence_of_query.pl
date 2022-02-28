#!/usr/bin/env perl

# Adds column with values indicating presence of query in row.

# Usage:
# perl add_column_indicating_presence_of_query.pl [table] [query]

# Prints to console. To print to file, use
# perl add_column_indicating_presence_of_query.pl [table] [query] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $query = $ARGV[1];

my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input files exist and are not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in table
my $first_line = 1;
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
			# prints column titles as they are
			print $line.$DELIMITER;
			
			# prints new column title
			print $query.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# scans line for presence of query
			my $query_found = 0;
			foreach my $value(@items_in_line)
			{
				if($value eq $query)
				{
					$query_found = 1;
				}
			}
		
			# prints line as it is
			print $line.$DELIMITER;
			
			# prints value if query found
			if($query_found)
			{
				print $query;
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# February 27, 2022
