#!/usr/bin/env perl

# Changes capitalization of values in specified columns: all capitalized, all lowercase,
# or first letter capitalized.

# Usage:
# perl change_capitalization_in_columns.pl [table]
# [uc to make all values uppercase, lc to make all values lowercase, first to capitalize first letter]
# "[title of column to capitalize]" "[title of another column to capitalize]"
# "[title of another column to capitalize]" [etc.]

# Prints to console. To print to file, use
# perl change_capitalization_in_columns.pl [table]
# [uc to make all values uppercase, lc to make all values lowercase, first to capitalize first letter]
# "[title of column to capitalize]" "[title of another column to capitalize]"
# "[title of another column to capitalize]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $capitalization_option = $ARGV[1];
my @titles_of_columns_to_capitalize = @ARGV[2..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that we have been provided column titles
if(!scalar @titles_of_columns_to_capitalize)
{
	print STDERR "Error: no column titles provided. Exiting.\n";
	die;
}


# converts array of column titles to a hash
my %title_is_of_column_to_capitalize = (); # key: column title -> value: 1 if column has dates
my %column_title_to_column = (); # key: included column title -> value: column
foreach my $column_title(@titles_of_columns_to_capitalize)
{
	$title_is_of_column_to_capitalize{$column_title} = 1;
	$column_title_to_column{$column_title} = -1;
}


# reads in and processes input table
my $first_line = 1;
my %column_is_column_to_capitalize = (); # key: column (0-indexed) -> value: 1 if column has dates
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
				if(defined $column_title and $title_is_of_column_to_capitalize{$column_title})
				{
					$column_is_column_to_capitalize{$column} = 1;
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
				
				# capitalizes values if this is a column to capitalize
				if($column_is_column_to_capitalize{$column})
				{
					if(defined $value and length $value)
					{
						if($capitalization_option eq "uc") # uc to make all values uppercase
						{
							$value = uc $value;
						}
						elsif($capitalization_option eq "lc") # lc to make all values lowercase
						{
							$value = lc $value;
						}
						elsif($capitalization_option eq "first") # first to capitalize first letter
						{
							my @words = split(" ", $value, -1);
							my $index = 0;
							foreach my $word(@words)
							{
								$words[$index] = lc $words[$index];
								$words[$index] = ucfirst $words[$index];
								$index++;
							}
							$value = join(" ", @words);
						}
						else
						{
							print STDERR "Error: capitalization option ".$capitalization_option
								." not recognized. Exiting.\n";
							die;
						}
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
