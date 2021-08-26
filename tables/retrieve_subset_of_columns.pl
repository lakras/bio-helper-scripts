#!/usr/bin/env perl

# Subsets table to only columns of interest.

# Usage:
# perl retrieve_subset_of_columns.pl [table] [title of first column to include in output]
# [title of second column to include] [title of third column to include] [etc.]

# Prints to console. To print to file, use
# perl retrieve_subset_of_columns.pl [table] [title of first column to include in output]
# [title of second column to include] [title of third column to include] [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_to_include = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that we have been provided columns to include
if(!scalar @titles_of_columns_to_include)
{
	print STDERR "Error: no columns to include provided. Exiting.\n";
	die;
}


# converts array of column titles to include to a hash
my %include_column_title = (); # key: column title -> value: 1 if column should be included in output
my %column_title_to_column = (); # key: included column title -> value: column
foreach my $column_title(@titles_of_columns_to_include)
{
	$include_column_title{$column_title} = 1;
	$column_title_to_column{$column_title} = -1;
}

# reads in and processes input table
my $first_line = 1;
my %include_column = (); # key: column (0-indexed) -> value: 1 if column should be included in output
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
				if(defined $column_title and $include_column_title{$column_title})
				{
					$include_column{$column} = 1;
					$column_title_to_column{$column_title} = $column;
				}
				$column++;
			}
			
			# verifies that we have found all columns to include
			foreach my $column_title(keys %column_title_to_column)
			{
				if($column_title_to_column{$column_title} == -1)
				{
					print STDERR "Error: expected column title ".$column_title
						." not found in table ".$table."\nExiting.\n";
					die;
				}
			}
			
			$first_line = 0; # next line is not column titles
		}
		
		# prints all values in columns to include
		my $column = 0;
		my $printing_first_column = 1;
		foreach my $value(@items_in_line)
		{
			if($include_column{$column})
			{
				# prints delimiter
				if(!$printing_first_column)
				{
					print $DELIMITER;
				}
				$printing_first_column = 0;
				
				# prints value
				if(defined $value)
				{
					print $value;
				}
			}
			$column++;
		}
		print $NEWLINE;
	}
}
close TABLE;


# August 24, 2021
