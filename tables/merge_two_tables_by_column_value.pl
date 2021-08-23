#!/usr/bin/env perl

# Merges (takes union of) two tables by the values in the specified columns.

# Usage:
# perl merge_two_tables_by_column_value.pl [table1 file path] [table1 column number (0-indexed)] [table2 file path] [table2 column number (0-indexed)]

# Prints to console. To print to file, use
# perl merge_two_tables_by_column_value.pl [table1 file path] [table1 column number (0-indexed)] [table2 file path] [table2 column number (0-indexed)] > [output table path]


use strict;
use warnings;


my $table_1 = $ARGV[0]; # file path of tab-separated table
my $table_1_column_to_merge_by = $ARGV[1]; # table 1 column number to merge by (0-indexed)
my $table_2 = $ARGV[2]; # file path of tab-separated table
my $table_2_column_to_merge_by = $ARGV[3]; # table 2 column number to merge by (0-indexed)


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";


# verifies that input tables exist and are non-empty
if(!$table_1 or !$table_2)
{
	print STDERR "Error: two input tables not provided. Exiting.\n";
	die;
}
if(!-e $table_1)
{
	print STDERR "Error: input table file does not exist:\n\t".$table_1."\nExiting.\n";
	die;
}
if(!-e $table_2)
{
	print STDERR "Error: input table file does not exist:\n\t".$table_2."\nExiting.\n";
	die;
}
if(-z $table_1)
{
	print STDERR "Error: input table file is empty:\n\t".$table_1."\nExiting.\n";
	die;
}
if(-z $table_2)
{
	print STDERR "Error: input table file is empty:\n\t".$table_2."\nExiting.\n";
	die;
}

# verifies that column numbers are non-negative value
if($table_1_column_to_merge_by < 0 or $table_2_column_to_merge_by < 0)
{
	print STDERR "Error: negative column number. Exiting.\n";
	die;
}


# reads in table 1
my $table_1_column_to_merge_by_title = "";
my $table_1_column_titles = "";
my %column_to_merge_by_values = (); # key: value in column to merge by in either table -> value: 1
my $table_1_number_columns = 0; # number columns in table 1
my %column_to_merge_by_value_to_table_1_line = (); # key: value in column to merge by in table 1 -> value: corresponding line in table 1
my $first_line = 1;
open TABLE_1, "<$table_1" || die "Could not open $table_1 to read; terminating =(\n";
while(<TABLE_1>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my $line = $_;
		if($line =~ /^(.*[^\t])\t+$/) # strips any trailing tabs
		{
			$line = $1;
		}
		my @items_in_line = split($DELIMITER, $line);
		
		if($first_line) # column titles
		{
			$table_1_number_columns = scalar @items_in_line;
			if($table_1_column_to_merge_by >= $table_1_number_columns)
			{
				print STDERR "Error: table 1 does not contain enough columns to retrieve column "
					.$table_1_column_to_merge_by.":\n\t".$table_1."\nExiting.\n";
				die;
			}
			$table_1_column_titles = $line;
			$table_1_column_to_merge_by_title = $items_in_line[$table_1_column_to_merge_by];
			
			$first_line = 0; # next line is not column titles
		}
		else # column values
		{
			my $column_to_merge_by_value = $items_in_line[$table_1_column_to_merge_by];
			if($column_to_merge_by_value_to_table_1_line{$column_to_merge_by_value})
			{
				print STDERR "Warning: value ".$column_to_merge_by_value." appears more than "
					."once in table 1. Printing final value encountered.\n";
			}
			$column_to_merge_by_value_to_table_1_line{$column_to_merge_by_value} = $line;
			$column_to_merge_by_values{$column_to_merge_by_value} = 1;
		}
	}
}
close TABLE_1;


# reads in table 2
my $table_2_column_to_merge_by_title = "";
my $table_2_column_titles = "";
my $table_2_number_columns = 0; # number columns in table 2
my %column_to_merge_by_value_to_table_2_line = (); # key: value in column to merge by in table 1 -> value: corresponding line in table 2
$first_line = 1;
open TABLE_2, "<$table_2" || die "Could not open $table_2 to read; terminating =(\n";
while(<TABLE_2>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my $line = $_;
		if($line =~ /^(.*[^\t])\t+$/) # strips any trailing tabs
		{
			$line = $1;
		}
		my @items_in_line = split($DELIMITER, $line);
		
		if($first_line) # column titles
		{
			$table_2_number_columns = scalar @items_in_line;
			if($table_2_column_to_merge_by >= $table_2_number_columns)
			{
				print STDERR "Error: table 2 does not contain enough columns to retrieve column "
					.$table_2_column_to_merge_by.":\n\t".$table_2."\nExiting.\n";
				die;
			}
			$table_2_column_titles = $line;
			$table_2_column_to_merge_by_title = $items_in_line[$table_2_column_to_merge_by];
			
			$first_line = 0; # next line is not column titles
		}
		else # column values
		{
			my $column_to_merge_by_value = $items_in_line[$table_2_column_to_merge_by];
			if($column_to_merge_by_value_to_table_2_line{$column_to_merge_by_value})
			{
				print STDERR "Warning: value ".$column_to_merge_by_value." appears more than "
					."once in table 2. Printing final value encountered.\n";
			}
			$column_to_merge_by_value_to_table_2_line{$column_to_merge_by_value} = $line;
			$column_to_merge_by_values{$column_to_merge_by_value} = 1;
		}
	}
}
close TABLE_2;


# prints column titles
print $table_1_column_to_merge_by_title."/".$table_2_column_to_merge_by_title.$DELIMITER; # new column with column to merge by
print $table_1_column_titles.$DELIMITER; # all table1 values
print $table_2_column_titles.$NEWLINE;   # all table2 values

# prints merged table with columns from both tables
my $no_data_to_print = $NO_DATA.$DELIMITER;
foreach my $column_to_merge_by_value(sort keys %column_to_merge_by_values)
{
	# prints value merged by
	print $column_to_merge_by_value;
	print $DELIMITER;

	# prints table 1 values
	my $number_columns_printed = 0;
	if($column_to_merge_by_value_to_table_1_line{$column_to_merge_by_value})
	{
		print $column_to_merge_by_value_to_table_1_line{$column_to_merge_by_value};
		print $DELIMITER;
		
		# prepares to print any additional spacing needed
		my @items_in_line = split($DELIMITER, $column_to_merge_by_value_to_table_1_line{$column_to_merge_by_value});
		$number_columns_printed = scalar @items_in_line;
	}
	
	# prints any additional spacing needed
	if($number_columns_printed < $table_1_number_columns)
	{
		print $no_data_to_print x ($table_1_number_columns - $number_columns_printed);
	}
	elsif($number_columns_printed > $table_1_number_columns)
	{
		print STDERR "Error: too many columns printed from table 1 for value "
			.$column_to_merge_by_value."; ".$number_columns_printed." > ".$table_1_number_columns."\n";
	}
	
	# prints table 2 values
	$number_columns_printed = 0;
	if($column_to_merge_by_value_to_table_2_line{$column_to_merge_by_value})
	{
		print $column_to_merge_by_value_to_table_2_line{$column_to_merge_by_value};
		
		# prepares to print any additional spacing needed
		my @items_in_line = split($DELIMITER, $column_to_merge_by_value_to_table_2_line{$column_to_merge_by_value});
		$number_columns_printed = scalar @items_in_line;
	}
	
	# prints any additional spacing needed
	if($number_columns_printed < $table_2_number_columns)
	{
		print $no_data_to_print x ($table_2_number_columns - $number_columns_printed);
	}
	elsif($number_columns_printed > $table_2_number_columns)
	{
		print STDERR "Error: too many columns printed from table 2 for value "
			.$column_to_merge_by_value."; ".$number_columns_printed." > ".$table_2_number_columns."\n";
	}
	
	print $NEWLINE;
}


# August 4, 2021
