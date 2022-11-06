#!/usr/bin/env perl

# Replaces all occurrences of values in selected column to mapped replacement values.

# Usage:
# perl bulk_replace_in_one_column.pl [tab-separated file mapping current values (first
# column) to new values (second column)] [path of table in which to replace values]
# [title of column to replace values in]

# Prints to console. To print to file, use
# perl bulk_replace_in_one_column.pl [tab-separated file mapping current values (first
# column) to new values (second column)] [path of table in which to replace values]
# [title of column to replace values in] > [output table path]


use strict;
use warnings;


my $replacement_map_file = $ARGV[0];
my $table = $ARGV[1];
my $title_of_column_to_search = $ARGV[2];


my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in replacement map file


# replacement map columns:
my $CURRENT_VALUE_COLUMN = 0;
my $NEW_VALUE_COLUMN = 1;


# verifies that input files exists and are not empty
if(!$replacement_map_file or !-e $replacement_map_file or -z $replacement_map_file)
{
	print STDERR "Error: replacement map file not provided, does not exist, or empty:\n\t"
		.$replacement_map_file."\nExiting.\n";
	die;
}
# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# read in map of new and old values
my %current_value_to_new_value = (); # key: old value -> value: new value
open REPLACEMENT_MAP, "<$replacement_map_file" || die "Could not open $replacement_map_file to read; terminating =(\n";
while(<REPLACEMENT_MAP>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		# reads in mapped values
		my @items_in_row = split($DELIMITER, $_);
		
		my $current_value = $items_in_row[$CURRENT_VALUE_COLUMN];
		my $new_value = $items_in_row[$NEW_VALUE_COLUMN];
		
		# verifies that we haven't seen the current value before
		if($current_value_to_new_value{$current_value}
			and $current_value_to_new_value{$current_value} ne $new_value)
		{
			print STDERR "Warning: current value ".$current_value." mapped to multiple "
				."new values.\n";
		}
		
		# saves current-new value pair
		if($new_value ne $current_value)
		{
			$current_value_to_new_value{$current_value} = $new_value;
		}
	}
}
close REPLACEMENT_MAP;


# reads in input table and replaces values
my $first_line = 1;
my $column_to_search = -1;
my %values_not_mapped = (); # key: value not mapped to a replacement value -> value: 1
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
			# identifies column to search
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $title_of_column_to_search)
				{
					if($column_to_search != -1)
					{
						print STDERR "Error: column to search ".$title_of_column_to_search
							." encountered more than once. Exiting.\n";
						die;
					}
					$column_to_search = $column;
				}
				$column++;
			}
			
			# verifies that we have found column
			if($column_to_search == -1)
			{
				print STDERR "Error: expected column title ".$title_of_column_to_search
					." not found. Exiting.\n";
				die;
			}
			
			# print header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# prints all values, replacing values in column to search
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter
				if($column > 0)
				{
					print $DELIMITER;
				}
				
				# replaces values if this is a column to search
				if($column == $column_to_search)
				{
					if(defined $current_value_to_new_value{$value})
					{
						$value = $current_value_to_new_value{$value};
					}
					elsif($value)
					{
						$values_not_mapped{$value} = 1;
					}
				}
		
				# prints value
				print $value;
				$column++;
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# prints list of values not mapped
if(scalar keys %values_not_mapped)
{
	print STDERR "Warning: the following values were not mapped to replacement values:\n";
	foreach my $value(keys %values_not_mapped)
	{
		print STDERR "\t".$value."\n";
	}
}


# July 22, 2021
# December 23, 2021
