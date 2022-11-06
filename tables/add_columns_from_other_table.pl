#!/usr/bin/env perl

# Adds columns from another table, matching rows in the two tables by selected columns
# to merge by.

# Usage:
# perl add_columns_from_other_table.pl [table to add columns to]
# "[title of column in first table to identify rows by]" [table to add columns from]
# "[title of column in second table to identify rows by]" "[title of column to add]"
# "[title of another column to add]" [etc.]

# Prints to console. To print to file, use
# perl add_columns_from_other_table.pl [table to add columns to]
# "[title of column in first table to identify rows by]" [table to add columns from]
# "[title of column in second table to identify rows by]" "[title of column to add]"
# "[title of another column to add]" [etc.] > [output table path]


use strict;
use warnings;


my $table_1 = $ARGV[0];
my $table_1_title_of_column_to_merge_by = $ARGV[1];
my $table_2 = $ARGV[2];
my $table_2_title_of_column_to_merge_by = $ARGV[3];
my @table_2_titles_of_columns_to_add = @ARGV[4..$#ARGV];

my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input files exist and are not empty
if(!$table_1 or !-e $table_1 or -z $table_1)
{
	print STDERR "Error: table to add columns to not provided, does not exist, or empty:\n\t"
		.$table_1."\nExiting.\n";
	die;
}
if(!$table_2 or !-e $table_2 or -z $table_2)
{
	print STDERR "Error: table to add columns from not provided, does not exist, or empty:\n\t"
		.$table_2."\nExiting.\n";
	die;
}

# verifies that input table columns make sense
if(!defined $table_1_title_of_column_to_merge_by or !defined $table_2_title_of_column_to_merge_by)
{
	print STDERR "Error: column titles to merge by not provided. Exiting.\n";
	die;
}
if(scalar @table_2_titles_of_columns_to_add < 1)
{
	print STDERR "Error: no columns to add provided. Exiting.\n";
	die;
}


# builds hash of column titles to add for easy lookup
my %column_title_is_to_be_added = (); # key: column title -> value: 1 if column should be added to other table
foreach my $column_title(@table_2_titles_of_columns_to_add)
{
	$column_title_is_to_be_added{$column_title} = 1;
}


# reads in new column values from table with columns to add
my $first_line = 1;
my $table_2_column_to_merge_by = -1;
my %column_to_add = (); # key: column (0-indexed) -> value: 1 if it should be added to other table
my %column_title_found = (); # key: column title -> value: 1 if column title has been found
my %column_title_to_column = (); # key: title of column to add -> value: column (0-indexed)
my %value_to_merge_by_to_new_column_values = (); # key: value in column to merge by -> value: tab-separated, ready to print values in columns to add to other table
open TABLE_2, "<$table_2" || die "Could not open $table_2 to read; terminating =(\n";
while(<TABLE_2>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		if($first_line) # column titles
		{
			# identifies column to merge by and columns to save
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $table_2_title_of_column_to_merge_by)
				{
					if($table_2_column_to_merge_by != -1)
					{
						print STDERR "Warning: column title ".$table_2_title_of_column_to_merge_by
							." of column to merge by appears more than once in input "
							."table:\n\t".$table_2."\n";
					}
					$table_2_column_to_merge_by = $column;
				}
				if(defined $column_title and $column_title_is_to_be_added{$column_title})
				{
					$column_to_add{$column} = 1;
					$column_title_found{$column_title} = 1;
					$column_title_to_column{$column_title} = $column;
				}
				$column++;
			}
			
			# verifies that we have found all columns
			if($table_2_column_to_merge_by == -1)
			{
				print STDERR "Warning: column title ".$table_2_title_of_column_to_merge_by
					." of column to merge by not found in input table:\n\t".$table_2
					."\nExiting.\n";
				die;
			}
			foreach my $column_title(@table_2_titles_of_columns_to_add)
			{
				if(!$column_title_found{$column_title})
				{
					print STDERR "Warning: input column to add ".$column_title." not "
						."found. Exiting.\n";
					die;
				}
			}
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# retrieves value to merge by
			my $value_to_merge_by = $items_in_line[$table_2_column_to_merge_by];
			
			# retrieves values in columns to add to other table
			my @values_to_save = ();
			foreach my $title_of_columns_to_add(@table_2_titles_of_columns_to_add)
			{
				my $column = $column_title_to_column{$title_of_columns_to_add};
				my $value_to_save = $items_in_line[$column];
				if(!defined $value_to_save)
				{
					$value_to_save = "";
				}
				push(@values_to_save, $value_to_save);
			}
			my $values_to_save_string = join($DELIMITER, @values_to_save);
			
			# saves values in columns to add to other table
			if($value_to_merge_by_to_new_column_values{$value_to_merge_by}
				and $value_to_merge_by_to_new_column_values{$value_to_merge_by} ne $values_to_save_string)
			{
				print STDERR "Warning: value to merge by ".$value_to_merge_by." appears "
					."more than once with different values in columns to add in table "
					."with columns to add:\n\t".$table_2."\n";
			}
			$value_to_merge_by_to_new_column_values{$value_to_merge_by} = $values_to_save_string;
		}
	}
}
close TABLE_2;


# generates empty string to add where no columns added
my @empty_values = ();
foreach my $title_of_columns_to_add(@table_2_titles_of_columns_to_add)
{
	push(@empty_values, "");
}
my $no_columns_added_string = join($DELIMITER, @empty_values);


# reads in and adds columns to table to add columns to
$first_line = 1;
my $table_1_column_to_merge_by = -1;
open TABLE_1, "<$table_1" || die "Could not open $table_1 to read; terminating =(\n";
while(<TABLE_1>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		if($first_line) # column titles
		{
			# identifies column to merge by and columns to save
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $table_1_title_of_column_to_merge_by)
				{
					if($table_1_column_to_merge_by != -1)
					{
						print STDERR "Warning: column title ".$table_1_title_of_column_to_merge_by
							." of column to merge by appears more than once in input "
							."table:\n\t".$table_1."\n";
					}
					$table_1_column_to_merge_by = $column;
				}
				$column++;
			}
			
			# verifies that we have found column to merge by
			if($table_1_column_to_merge_by == -1)
			{
				print STDERR "Warning: column title ".$table_1_title_of_column_to_merge_by
					." of column to merge by not found in input table:\n\t".$table_1
					."\nExiting.\n";
				die;
			}
			$first_line = 0; # next line is not column titles
			
			# prints line as is
			print $line;
			
			# prints titles of new columns
			print $DELIMITER;
			print join($DELIMITER, @table_2_titles_of_columns_to_add);
			print $NEWLINE;
		}
		else # column values (not column titles)
		{
			# retrieves value to merge by
			my $value_to_merge_by = $items_in_line[$table_1_column_to_merge_by];
			
			# prints line as is
			print $line;
			
			if(defined $value_to_merge_by)
			{
				# prints new column values
				if(defined $value_to_merge_by_to_new_column_values{$value_to_merge_by})
				{
					print $DELIMITER;
					print $value_to_merge_by_to_new_column_values{$value_to_merge_by};
				}
				else
				{
	# 				print STDERR "Warning: value to merge by ".$value_to_merge_by." not found "
	# 					."in table with columns to add:\n\t".$table_2."\n";
					print $DELIMITER;
					print $no_columns_added_string;
				}
			}
			else
			{
				print STDERR "Error: value to merge by not defined in line:\n$line\n";
				print $DELIMITER;
				print $no_columns_added_string;
			}
			print $NEWLINE;
		}
	}
}
close TABLE_1;


# September 26, 2021
