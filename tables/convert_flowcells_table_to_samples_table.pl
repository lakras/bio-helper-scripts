#!/usr/bin/env perl

# Converts table where some values are lists of values, such as a flowcell table on Terra,
# to a table with one value per cell, such as a sample table on Terra. Input flowcell
# table is expanded to have one row per sample listed in the sample name column. Lists of
# values must be comma-separated and surrounded by brackets. Values that are not lists of
# values of the same length as that flowcell's sample name list are reproduced identically
# for each sample row produced for that flowcell. Column titles must be unique (cannot
# repeat). For each flowcell, lists must be in the same order as that flowcell's sample
# name list.

# Example input:
# flowcell	sample	column1	column2	column3
# "flowcell1"	["sample1", "sample2", "sample3", "sample4"], ["value1", "value2", "value3", "value4"]	null	[ 1, 2]

# Example output:
# flowcell	sample	column1	column2	column3
# "flowcell1"	"sample1"	"value1"	null	[ 1, 2]
# "flowcell1"	"sample2"	"value2"	null	[ 1, 2]
# "flowcell1"	"sample3"	"value3"	null	[ 1, 2]
# "flowcell1"	"sample4"	"value4"	null	[ 1, 2]


# Usage:
# perl convert_flowcells_table_to_samples_table.pl [flowcells table]
# "[sample lists column title]"

# Prints to console. To print to file, use
# perl convert_flowcells_table_to_samples_table.pl [flowcells table]
# "[sample lists column title]" > [output samples table path]


use strict;
use warnings;


my $flowcells_table_file = $ARGV[0]; # file containing flowcells table; see format above
my $sample_lists_column_title = $ARGV[1]; # title of column containing a list of samples, or a list with one value per sample


# if 0, does not print lists that have a different number of values than there are samples (the number of values in the sample list column)
# if 1, if any list in a cell does not have the same number of values as there are samples, prints the list as is again and again in this column, the same for each row
my $PRINT_ALL_LISTS = 0;

# for input:
my $LIST_ITEM_SEPARATOR = ',\s*';
my $LIST_START = "\\[";
my $LIST_END = "\\]";

# for input and output:
my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in replacement map file


# verifies that input file exists and is not empty
if(!$flowcells_table_file or !-e $flowcells_table_file or -z $flowcells_table_file)
{
	print STDERR "Error: input lists file not provided, does not exist, or empty:\n\t"
		.$flowcells_table_file."\nExiting.\n";
	die;
}


# reads in flowcells table and expands into samples table
my $first_line = 1;
my $sample_lists_column = -1;
open FLOWCELLS_TABLE, "<$flowcells_table_file" || die "Could not open $flowcells_table_file to read; terminating =(\n";
while(<FLOWCELLS_TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		if($first_line) # column titles
		{
			# identifies column to search
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $sample_lists_column_title)
				{
					if($sample_lists_column != -1)
					{
						print STDERR "Error: sample names lists column "
							.$sample_lists_column_title
							." encountered more than once. Exiting.\n";
						die;
					}
					$sample_lists_column = $column;
				}
				$column++;
			}
			
			# verifies that we have found sample names lists column
			if($sample_lists_column == -1)
			{
				print STDERR "Error: expected column title "
					.$sample_lists_column_title ." not found. Exiting.\n";
				die;
			}
			
			# print header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# counts sample names list for this flowcell
			my $sample_names_list_string = $items_in_line[$sample_lists_column];
			my @samples = retrieve_list_from_list_string($sample_names_list_string);
			my $number_samples = scalar @samples;
			
			# row to print for each sample
			my @output_rows = (); # key: row number -> value: row to print
			
			# expands all other columns wherever there are as many list values as sample names
			foreach my $value(@items_in_line)
			{
				# if this is a list with as many values as sample names list, expands it,
				# one value corresponding to each sample name
				# otherwise prints full original value in each row, even if it is a list
				my @list_values = ();
				if(number_values_in_list_string($value) == $number_samples)
				{
					@list_values = retrieve_list_from_list_string($value);
				}
				
				for(my $row_number = 0; $row_number < $number_samples; $row_number++)
				{
					# initializes row and adds delimiter as needed
					if(!$output_rows[$row_number])
					{
						$output_rows[$row_number] = "";
					}
					else
					{
						$output_rows[$row_number] = $output_rows[$row_number].$DELIMITER;
					}
					
					# adds cell value
					if(number_values_in_list_string($value) == $number_samples)
					{
						# one value corresponding to each sample name
						$output_rows[$row_number] = $output_rows[$row_number].$list_values[$row_number];
					}
					else
					{
						# value is the same for each sample row
						if($PRINT_ALL_LISTS or !string_is_list($value))
						{
							$output_rows[$row_number] = $output_rows[$row_number].$value;
						}
					}
				}
			}
			
			# prints output rows
			foreach my $output_row(@output_rows)
			{
				print $output_row.$NEWLINE;
			}
		}
	}
}
close FLOWCELLS_TABLE;


sub number_values_in_list_string
{
	my $list_string = $_[0];
	my @list_values = retrieve_list_from_list_string($list_string);
	return scalar @list_values;
}

sub retrieve_list_from_list_string
{
	my $list_string = $_[0];
	
	if($list_string =~ /^\s*$LIST_START\s*(.*)\s*$LIST_END\s*$/) # if this is a list
	{
		# retrieves list of variable values
		my $list = $1;
		my @items_in_list = split($LIST_ITEM_SEPARATOR, $list);
		return @items_in_list;
	}
	return;
}

sub string_is_list
{
	my $list_string = $_[0];
	
	if($list_string =~ /^\s*$LIST_START\s*(.*)\s*$LIST_END\s*$/) # if this is a list
	{
		# retrieves list of variable values
		return 1;
	}
	return 0;
}


# September 22, 2022
