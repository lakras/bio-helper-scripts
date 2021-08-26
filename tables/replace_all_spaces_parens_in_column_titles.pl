#!/usr/bin/env perl

# Replaces all spaces and parentheses in header line with provided replacement value, or
# underscore by default.

# Usage:
# perl replace_all_spaces_parens_in_column_titles.pl [table]
# [optional value to replace spaces with in header line]

# Prints to console. To print to file, use
# perl replace_all_spaces_parens_in_column_titles.pl [table]
# [optional value to replace spaces with in header line] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $replacement_value = $ARGV[1]; # optional value to replace all spaces with in header line


my $DEFAULT_REPLACEMENT_VALUE = "_";
my $NEWLINE = "\n";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# sets replacement value
if(!defined $replacement_value or !length $replacement_value)
{
	$replacement_value = $DEFAULT_REPLACEMENT_VALUE;
}


# reads in input table
# prints same input table with spaces replaced in header line
my $first_line = 1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		if($first_line) # column titles
		{
			# replaces all spaces with underscores
			$line =~ s/ /$replacement_value/g;
			
			# replaces all parentheses with underscores
			$line =~ s/\(/$replacement_value/g;
			$line =~ s/\)/$replacement_value/g;
			
			$first_line = 0; # next line is not column titles
		}
		
		# prints line
		print $line.$NEWLINE;
	}
}
close TABLE;


# August 23, 2021
