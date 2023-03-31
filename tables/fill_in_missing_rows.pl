#!/usr/bin/env perl

# Catalogues all values in parameter columns. In any combination of values is missing,
# adds it as a row with NAs in all other columns.

# Usage:
# perl fill_in_missing_rows.pl [table] "[title of column of interest 1]"
# "[title of column of interest 2]" etc.

# Prints to console. To print to file, use
# perl fill_in_missing_rows.pl [table] "[title of column of interest 1]"
# "[title of column of interest 2]" etc. > [output table path]


use strict;
use warnings;


my $table = $ARGV[0]; # table
my @column_titles_of_interest = @ARGV[1..$#ARGV]; # titles of columns of interest


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";


# verifies that input files exist and are not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table to add columns to not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}
if(scalar(@column_titles_of_interest) < 1)
{
	print STDERR "Error: titles of columns of interest not provided. Exiting.\n";
	die;
}


# creates hashes from titles of columns of interest
my %column_title_is_of_interest = (); # key: title of column of interest -> value: 1
for my $column_title(@column_titles_of_interest)
{
	$column_title_is_of_interest{$column_title} = 1;
}
my %column_title_of_interest_to_index_in_input_list = ();
for(my $index = 0; $index < scalar(@column_titles_of_interest); $index++)
{
	$column_title_of_interest_to_index_in_input_list{$column_titles_of_interest[$index]} = $index;
}

# reads in table
my $first_line = 1;
my @column_to_column_title = ();
my %column_title_to_column = (); # key: column title -> value: column number
my %column_to_column_values = (); # key: column number -> key: column value -> value: 1
my %column_value_combination_present = (); # key: combination of column values present in at least one row that are present in table, tab-separated -> value: 1
my $number_columns = -1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		$number_columns = scalar(@items_in_line);
		if($first_line) # column titles
		{
			# identifies column to merge by and columns to save
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title_is_of_interest{$column_title})
				{
					$column_title_to_column{$column_title} = $column;
				}
				$column++;
			}
			$first_line = 0; # next line is not column titles
			@column_to_column_title = @items_in_line;
		}
		else # column values (not column titles)
		{
			# retrieves values in columns of interest
			my $column_value_combination = "";
			for my $column_title(@column_titles_of_interest)
			{
				my $column_number = $column_title_to_column{$column_title};
				my $column_value = $items_in_line[$column_number];
				$column_to_column_values{$column_number}{$column_value} = 1;
				
				if($column_value_combination)
				{
					$column_value_combination .= $DELIMITER;
				}
				$column_value_combination .= $column_value;
			}
			$column_value_combination_present{$column_value_combination} = 1;
		}
		
		# prints line as is
		print $line;
		print $NEWLINE;
	}
}
close TABLE;


# generates hash from column titles and column numbers


# generates all combinations of column values in columns of interest
my %column_value_combinations = (); # key: combination of column values present in at least one row, whether or not they are present in table, tab-separated -> value: 1
my $first_column_of_interest = 1;
for my $column_title(@column_titles_of_interest)
{
	my $column_number = $column_title_to_column{$column_title};
	my %column_value_combinations_updated = ();
	foreach my $column_value(keys %{$column_to_column_values{$column_number}})
	{
		if($first_column_of_interest)
		{
			$column_value_combinations_updated{$column_value} = 1;
		}
		else
		{
			foreach my $column_value_combination(keys %column_value_combinations)
			{
				if($column_value_combination)
				{
					$column_value_combination .= $DELIMITER;
				}
				$column_value_combination .= $column_value;
				$column_value_combinations_updated{$column_value_combination} = 1;
			}
		}
	}
	%column_value_combinations = %column_value_combinations_updated;
	$first_column_of_interest = 0;
}

# verifies that all combinations of values in columns of interest have been added
# adds them if not
foreach my $column_value_combination(keys %column_value_combinations)
{
# 	print STDERR $column_value_combination."\n";
	if(!$column_value_combination_present{$column_value_combination})
	{
		my @column_values_of_interest = split($DELIMITER, $column_value_combination);
		for(my $column = 0; $column < $number_columns; $column++)
		{
			if($column > 0)
			{
				print $DELIMITER;
			}
		
			my $column_title = $column_to_column_title[$column];
			
			# if column is of interest, print value of interest
			if($column_title_is_of_interest{$column_title})
			{
				my $index = $column_title_of_interest_to_index_in_input_list{$column_title};
				print $column_values_of_interest[$index];
			}
			
			# prints NA if column is not of interest
			else
			{
				print $NO_DATA;
			}
		}
		print $NEWLINE;
	}
}


# March 31, 2023
