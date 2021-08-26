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
		my @items_in_line = split($DELIMITER, $line, -1);
		
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
					."once in table 1. Merging rows.\n";
			}
			$column_to_merge_by_value_to_table_1_line{$column_to_merge_by_value}
				= merge_values_to_print($column_to_merge_by_value_to_table_1_line{$column_to_merge_by_value}, $line);
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
		my @items_in_line = split($DELIMITER, $line, -1);
		
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
					."once in table 2. Merging rows.\n";
			}
			$column_to_merge_by_value_to_table_2_line{$column_to_merge_by_value}
				= merge_values_to_print($column_to_merge_by_value_to_table_2_line{$column_to_merge_by_value}, $line);
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

# merges two rows into one row
# for each column, adds both values if they are different, present value if one is absent,
# or nothing if neither has a value
sub merge_values_to_print
{
	my $to_print_1 = $_[0];
	my $to_print_2 = $_[1];
	
	# if both empty, returns
	if(!defined $to_print_1 and !defined $to_print_2)
	{
		return "";
	}
	
	# defines empty strings
	if(!defined $to_print_1)
	{
		$to_print_1 = "";
	}
	if(!defined $to_print_2)
	{
		$to_print_2 = "";
	}
	
	# splits values to print into their component parts
	my @to_print_1_items = split($DELIMITER, $to_print_1, -1);
	my @to_print_2_items = split($DELIMITER, $to_print_2, -1);
	
# 	if(scalar @to_print_1_items != scalar @to_print_2_items)
# 	{
# 		print STDERR "Error: output row chunks with duplicate values to merge by contain "
# 			."unequal numbers of columns (".(scalar @to_print_1_items)." and "
# 			.(scalar @to_print_2_items)."). Cannot merge properly:\n"
# 			.$to_print_1."\n".$to_print_2."\n";
# 	}
	
	# merges values
	my @to_print = ();
	for my $index(0..max($#to_print_1_items, $#to_print_2_items))
	{
    	my $to_print_1_item = $to_print_1_items[$index];
    	my $to_print_2_item = $to_print_2_items[$index];
    	
    	# adds merged value
    	if(!length($to_print_1_item) and !length($to_print_2_item)) # both items absent
    	{
    		push(@to_print, "");
    	}
    	elsif(length($to_print_1_item) and !length($to_print_2_item)) # item 1 is present, item 2 is empty string
    	{
    		push(@to_print, $to_print_1_item);
    	}
    	elsif(length($to_print_2_item) and !length($to_print_1_item)) # item 2 is present, item 1 is empty string
    	{
    		push(@to_print, $to_print_2_item);
    	}
    	elsif(length($to_print_1_item) and length($to_print_2_item) and $to_print_1_item eq $to_print_2_item) # both items present and same value in both items
    	{
    		push(@to_print, $to_print_1_item);
    	}
    	elsif(length($to_print_1_item) and length($to_print_2_item) and $to_print_1_item ne $to_print_2_item) # both items present and different
    	{
    		push(@to_print, $to_print_1_item.", ".$to_print_2_item);
    	}
    	else # something else?
    	{
    		print STDERR "Error: unexpected possibility reached. Please check and fix code.\n";
    		push(@to_print, $to_print_1_item.", ".$to_print_2_item);
    	}
	}
	return join($DELIMITER, @to_print);
}

# returns the maximum of two values
sub max
{
	my $value_1 = $_[0];
	my $value_2 = $_[1];
	
	if($value_1 >= $value_2)
	{
		return $value_1;
	}
	if($value_2 > $value_1)
	{
		return $value_2;
	}
	print STDERR "Error: unexpected possibility reached. Please check and fix code.\n";
	return $value_2;
}


# August 4, 2021
