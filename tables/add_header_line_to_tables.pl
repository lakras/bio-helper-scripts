#!/usr/bin/env perl

# Adds header line to all input files. Saves output tables in new files at same path with
# _with_header_line.txt extension. Four spaces in the input header line are replaced with
# tabs.

# Usage:
# perl add_header_line_to_tables.pl "[header line]" [table] [optional additional table]
# [etc.]


use strict;
use warnings;


my $header_line = $ARGV[0];
my @tables = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that inputs are provided
if(!$header_line)
{
	print STDERR "Error: header line not provided. Exiting.\n";
	die;
}
if(scalar @tables < 1)
{
	print STDERR "Error: input tables not provided. Exiting.\n";
	die;
}


# replaces \ts with tabs in the header line
$header_line =~ s/\G[ ]{2}/\t/g;

# reads in and prints each table
foreach my $table(@tables)
{
	my $output_table = $table."_with_header_line.txt";
	open OUTPUT_TABLE, ">$output_table" || die "Could not open output table to write; terminating =(\n";
	print OUTPUT_TABLE $header_line.$NEWLINE;
	
	open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
	while(<TABLE>) # for each row in the file
	{
		print OUTPUT_TABLE $_;
	}
	close TABLE;
	close OUTPUT_TABLE;
}


# November 13, 2022
