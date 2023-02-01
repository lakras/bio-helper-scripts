#!/usr/bin/env perl

# Splits table into multiple tables, one for each column value in specified column.

# Usage:
# perl split_table_by_column_value.pl [input table file path]
# "[title of column to split by]"

# New files are created at filepath of old file with "_[column value 1].txt", 
# "_[column value 1].txt", etc. appended to the end. Files already at those paths
# will be overwritten.


use strict;
use warnings;


my $table = $ARGV[0];
my $column_title_to_split_on = $ARGV[1];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in and splits up input table
my $first_line = 1;
my $column_to_split_on = -1;
my $header_line = "";
my %column_value_to_output_file = (); # key: column value -> value: output file to print to
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
			# identifies column to split on
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title
					and $column_title eq $column_title_to_split_on)
				{
					$column_to_split_on = $column;
				}
				$column++;
			}
			
			# verifies that we have found column to split on
			if($column_to_split_on == -1)
			{
				print STDERR "Error: expected title of column to split on "
					.$column_to_split_on." not found in table ".$table."\nExiting.\n";
				die;
			}
			
			# saves header line
			$header_line = $line;
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			my $column_value_to_split_on = $items_in_line[$column_to_split_on];
			
			# opens new output table if this column title hasn't been encountered before
			if(!defined $column_value_to_output_file{$column_value_to_split_on})
			{
				my $column_value_printable = $column_value_to_split_on;
				$column_value_printable =~ tr/ /_/;
				my $output_file = $table."_".$column_value_printable.".txt";
				open OUT_FILE, ">$output_file"
					|| die "Could not open $output_file to write; terminating =(\n";
				print OUT_FILE $header_line;
				print OUT_FILE $NEWLINE;
				close OUT_FILE;
				$column_value_to_output_file{$column_value_to_split_on} = $output_file;
			}
			
			# prints table row to column value's table
			my $output_file = $column_value_to_output_file{$column_value_to_split_on};
			open OUT_FILE, ">>$output_file"
					|| die "Could not open $output_file to write; terminating =(\n";
			print OUT_FILE $line;
			print OUT_FILE $NEWLINE;
			close OUT_FILE;
		}
	}
}
close TABLE;


# January 31, 2023
