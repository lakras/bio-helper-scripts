#!/usr/bin/env perl

# Converts lists of variable values, such as those output by Terra, to a table. Lists of
# values must appear with variable on one line followed by values in the following line,
# comma-separated and surrounded by brackets. Lines not matching this format are ignored.
# Variable names must be unique (cannot repeat). List items must be in order for all
# variables. Expects all variables to have identical numbers of values: ignores variables
# with less than the largest number of values.

# Example input:
# variable1
# ["value1", "value2", "value3"]
# variable2
# null
# variable3
# [ 1, 2, 3 ]

# Example output:
# variable1	variable3
# "value1"	1
# "value2"	2
# "value3"	3


# Usage:
# perl convert_variable_value_lists_to_table.pl [file containing input lists]
# [optional list item separator, ", " by default] [optional list start, "[" by default]
# [optional list end, "]" by default]

# Prints to console. To print to file, use
# perl convert_variable_value_lists_to_table.pl [file containing input lists]
# [optional list item separator, ", " by default] [optional list start, "[" by default]
# [optional list end, "]" by default] > [output table path]


use strict;
use warnings;


my $input_lists_file = $ARGV[0]; # file containing input lists; see format above
my $list_item_separator = $ARGV[1]; # optional list item separator, ", " by default
my $list_start = $ARGV[2]; # optional list start, "[" by default
my $list_end = $ARGV[3]; # optional list end, "]" by default


# for input:
my $DEFAULT_LIST_ITEM_SEPARATOR = ", ";
my $DEFAULT_LIST_START = "\\[";
my $DEFAULT_LIST_END = "\\]";

# for output:
my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in replacement map file


# verifies that input file exists and is not empty
if(!$input_lists_file or !-e $input_lists_file or -z $input_lists_file)
{
	print STDERR "Error: input lists file not provided, does not exist, or empty:\n\t"
		.$input_lists_file."\nExiting.\n";
	die;
}

# sets optional values to defaults if not provided
if(!$list_item_separator)
{
	$list_item_separator = $DEFAULT_LIST_ITEM_SEPARATOR;
}
if(!$list_start)
{
	$list_start = $DEFAULT_LIST_START;
}
if(!$list_end)
{
	$list_end = $DEFAULT_LIST_END;
}


# reads in input variable names and values
my %variable_name_to_list_of_values = (); # key: variable name -> value: list of variable values, in order read in
my $previous_line = "";
open INPUT_LISTS_FILE, "<$input_lists_file" || die "Could not open $input_lists_file to read; terminating =(\n";
while(<INPUT_LISTS_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/)
	{
		if($line =~ /^\s*$list_start\s*(.*)\s*$list_end\s*$/) # if this is a list
		{
			# retrieves list of variable values
			my $list = $1;
			my @items_in_list = split($list_item_separator, $list);
			
			# retrieves variable name
			my $variable_name = $previous_line;
			
			# saves variable name and values
			$variable_name_to_list_of_values{$variable_name} = \@items_in_list;
		}
		
		# saves line in case it is a variable name
		$previous_line = $line;
	}
}
close INPUT_LISTS_FILE;


# retrieves largest number values for any variable
my $max_number_values = 0;
foreach my $variable_name(sort keys %variable_name_to_list_of_values)
{
	my @list_of_values = @{$variable_name_to_list_of_values{$variable_name}};
	my $list_of_values_length = scalar @list_of_values;
	if($list_of_values_length > $max_number_values)
	{
		$max_number_values = $list_of_values_length;
	}
}


# prints header line
my $first_column = 1;
foreach my $variable_name(sort keys %variable_name_to_list_of_values)
{
	# determines if variable is included
	my @list_of_values = @{$variable_name_to_list_of_values{$variable_name}};
	if(scalar @list_of_values == $max_number_values) # included (number values matches maximum)
	{
		# print delimiter
		if(!$first_column)
		{
			print $DELIMITER;
		}
		$first_column = 0;
	
		# print column title
		print $variable_name;
	}
}
print $NEWLINE;


# prints values
for my $row_number(0..$max_number_values-1)
{
	$first_column = 1;
	foreach my $variable_name(sort keys %variable_name_to_list_of_values)
	{
		# determines if variable is included
		my @list_of_values = @{$variable_name_to_list_of_values{$variable_name}};
		if(scalar @list_of_values == $max_number_values) # included (number values matches maximum)
		{
			# print delimiter
			if(!$first_column)
			{
				print $DELIMITER;
			}
			$first_column = 0;
	
			# print column value
			if(scalar @list_of_values > $row_number)
			{
				print $list_of_values[$row_number];
			}
		}
	}
	print $NEWLINE;
}


# May 15, 2022
