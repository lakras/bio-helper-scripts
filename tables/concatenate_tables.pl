#!/usr/bin/env perl

# Concatenates tables with potentially different columns, adding empty space for missing
# column values.

# Usage:
# perl concatenate_tables.pl [table1] [table2] [table3] etc.

# Prints to console. To print to file, use
# perl concatenate_tables.pl [table1] [table2] [table3] etc. > [concatenated output table path]


use strict;
use warnings;


my @input_tables = @ARGV;


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";


# verifies that input tables exist and are non-empty
if(!scalar @input_tables)
{
	print STDERR "Error: no input tables provided. Exiting.\n";
	die;
}
if(scalar @input_tables == 1)
{
	print STDERR "Error: only one input table provided. Nothing for me to do. Exiting.\n";
	die;
}
foreach my $input_table(@input_tables)
{
	if(!$input_table)
	{
		print STDERR "Error: input table not provided. Exiting.\n";
		die;
	}
	if(!-e $input_table)
	{
		print STDERR "Error: input table does not exist:\n\t".$input_table."\nExiting.\n";
		die;
	}
	if(-z $input_table)
	{
		print STDERR "Error: input table is empty:\n\t".$input_table."\nExiting.\n";
		die;
	}
}


# reads in all column titles
my $column_title_count = 0; # number column titles we have encountered
my %column_titles = (); # key: column title -> value: column title count after this column was encountered
foreach my $input_table(@input_tables)
{
	my $first_line = 1;
	open INPUT_TABLE, "<$input_table" || die "Could not open $input_table to read; terminating =(\n";
	while(<INPUT_TABLE>) # for each row in the file
	{
		chomp;
		if($first_line and $_ =~ /\S/) # if row not empty
		{
			my @items_in_line = split($DELIMITER, $_);
			
			# identifies column to merge by and columns to include in output
			foreach my $column_title(@items_in_line)
			{
				if(!$column_titles{$column_title})
				{
					$column_title_count++;
					$column_titles{$column_title} = $column_title_count;
				}
			}
			
			$first_line = 0;
		}
	}
	close INPUT_TABLE;
}


# prints column titles
my $first_column_title_printed = 1;
foreach my $column_title(sort {$column_titles{$a} <=> $column_titles{$b}} keys %column_titles) # sorts column titles by the order of their appearance
{
	# prints delimiter (tab)
	if(!$first_column_title_printed)
	{
		print $DELIMITER;
	}
	$first_column_title_printed = 0;
	
	# prints column title
	print $column_title;
}
print $NEWLINE;


# reads in tables again and prints concatenated table, adding blank values for columns
# that are not present
foreach my $input_table(@input_tables)
{
	# sets all column indices to -1
	my %column_title_to_index = ();
	foreach my $column_title(keys %column_titles)
	{
		$column_title_to_index{$column_title} = -1;
	}

	# reads in and prints table
	my $first_line = 1;
	open INPUT_TABLE, "<$input_table" || die "Could not open $input_table to read; terminating =(\n";
	while(<INPUT_TABLE>) # for each row in the file
	{
		chomp;
		if($_ =~ /\S/) # if row not empty
		{
			my @items_in_line = split($DELIMITER, $_);
			if($first_line) # column titles
			{
				# identifies columns with column titles we are printing
				my $column = 0;
				foreach my $column_title(@items_in_line)
				{
					if($column_titles{$column_title})
					{
						if($column_title_to_index{$column_title} != -1)
						{
							print STDERR "Error: column title ".$column_title
								." appears more than once in table:\n\t"
								.$input_table."\nExiting.\n";
							die;
						}
						$column_title_to_index{$column_title} = $column;
					}
					else
					{
						print STDERR "Error: column title ".$column_title
							." detected in second but not first file readthrough of table:\n\t"
							.$input_table."\nExiting.\n";
						die;
					}
					$column++;
				}
				
				$first_line = 0;
			}
			else # column values (not titles)
			{
				# prints concatenated table with blank values for columns that are not present
				my $first_column_printed = 1;
				foreach my $column_title(sort {$column_titles{$a} <=> $column_titles{$b}} keys %column_titles) # sorts column titles by the order of their appearance
				{
					# prints delimiter (tab)
					if(!$first_column_printed)
					{
						print $DELIMITER;
					}
					$first_column_printed = 0;
	
					# prints blank column if this column is not present
					if($column_title_to_index{$column_title} == -1)
					{
						print $NO_DATA;
					}
					
					# otherwise prints column value
					else
					{
						my $column = $column_title_to_index{$column_title};
						print $items_in_line[$column];
					}
				}
				print $NEWLINE;
			}
		}
	}
	close INPUT_TABLE;
}


# August 22, 2021
