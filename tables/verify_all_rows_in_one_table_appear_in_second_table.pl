#!/usr/bin/env perl

# Verifies that all rows/lines in table 1 also appear in table 2 (that table 2 is a
# superset of table 1). Prints all rows from table 1 that are missing from table 2. If
# column numbers is specified, only compares values from that column.

# Usage:
# perl verify_all_lines_in_one_table_appear_in_second_table.pl [subset table]
# [superset table] [column number to compare--set to -1 to compare full row]

# Prints to console. To print to file, use
# perl verify_all_rows_in_one_table_appear_in_second_table.pl [subset table]
# [superset table] [column number to compare--set to -1 to compare full row]
# > [output list of missing rows]


use strict;
use warnings;


my $table_1 = $ARGV[0]; # subset table
my $table_2 = $ARGV[1]; # superset table
my $column_number_to_compare = $ARGV[2]; # set to -1 to compare full row


my $DELIMITER = "\t";
my $NEWLINE = "\n";


# verifies that input files exist and are not empty
if(!$table_1 or !-e $table_1 or -z $table_1)
{
	print STDERR "Error: subset table not provided, does not exist, or empty:\n\t"
		.$table_1."\nExiting.\n";
	die;
}
if(!$table_2 or !-e $table_2 or -z $table_2)
{
	print STDERR "Error: superset table not provided, does not exist, or empty:\n\t"
		.$table_2."\nExiting.\n";
	die;
}


# reads in superset table
my %line_appears_in_table_2 = (); # key: column value for line, or full line if no column specified -> value: 1 if line appears in table 2 (superset table)
open SUPERSET_TABLE, "<$table_2" || die "Could not open $table_2 to read; terminating =(\n";
while(<SUPERSET_TABLE>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		# retrieves value to compare--column or full line
		my $line = $_;
		my @items_in_line = split($DELIMITER, $line, -1);
		my $value_to_compare = $line;
		if($column_number_to_compare != -1)
		{
			$value_to_compare = $items_in_line[$column_number_to_compare];
		}
		
		# saves value to compare
		$line_appears_in_table_2{$value_to_compare} = 1;
	}
}
close SUPERSET_TABLE;


# reads in subset table
open SUBSET_TABLE, "<$table_1" || die "Could not open $table_1 to read; terminating =(\n";
while(<SUBSET_TABLE>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		# retrieves value to compare--column or full line
		my $line = $_;
		my @items_in_line = split($DELIMITER, $line, -1);
		my $value_to_compare = $line;
		if($column_number_to_compare != -1)
		{
			$value_to_compare = $items_in_line[$column_number_to_compare];
		}
		
		# saves value to compare
		if(!$line_appears_in_table_2{$value_to_compare})
		{
			print $line.$NEWLINE;
		}
	}
}
close SUBSET_TABLE;


# March 7, 2023
