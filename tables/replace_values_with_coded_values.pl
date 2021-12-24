#!/usr/bin/env perl

# Replaces non-empty values with coded values, e.g., Value 1 (for the most common value),
# Value 2 (for the second-most common value), Value 3, etc.

# Usage:
# perl replace_values_with_coded_values.pl [table] "[title of column to search]"
# "[optional code prefix]"

# Prints to console. To print to file, use
# perl replace_values_with_coded_values.pl [table] "[title of column to search]"
# "[optional code prefix]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_search = $ARGV[1];
my $code_prefix = $ARGV[2]; # optional


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# sets code prefix to default if not provided
if(!$code_prefix)
{
	$code_prefix = "Value";
}


# reads in all values in input table
my %value_to_count = (); # key: non-empty value in column of interest -> value: number of times value appears
my $first_line = 1;
my $column_to_search = -1;
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
			# identifies columns to include
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
			
			# verifies that we have found all column
			if($column_to_search == -1)
			{
				print STDERR "Error: expected column title ".$title_of_column_to_search
					." not found. Exiting.\n";
				die;
			}
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			my $value = $items_in_line[$column_to_search];
			if(defined $value and length $value)
			{
				$value_to_count{$value}++;
			}
		}
	}
}
close TABLE;


# codes values
my $value_count = 1;
my %value_to_coded_value = (); # key: value -> value: coded value
foreach my $value(sort {$value_to_count{$b} <=> $value_to_count{$a}} keys %value_to_count)
{
	my $coded_value = $code_prefix." ".$value_count;
	$value_to_coded_value{$value} = $coded_value;
	$value_count++;
}


# reads in input table and replaces values with coded values
$first_line = 1;
$column_to_search = -1;
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
			# identifies columns to include
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
			
			# verifies that we have found all column
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
			# prints all values, replacing values in columns to search
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
					if(defined $value and length $value)
					{
						$value = $value_to_coded_value{$value};
					}
				}
		
				# prints value
				if(defined $value and length $value)
				{
					print $value;
				}
				$column++;
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# August 24, 2021
# December 22, 2021
# December 23, 2021
