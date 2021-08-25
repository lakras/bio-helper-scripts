#!/usr/bin/env perl

# Merges selected columns. Reports any conflicts. Input column titles cannot have whitespace.

# Usage:
# perl merge_columns.pl [table to merge] [title of column to merge]
# [title of another column to merge] [title of another column to merge] [etc.]

# Prints to console. To print to file, use
# perl merge_columns.pl [table to merge] [title of column to merge]
# [title of another column to merge] [title of another column to merge] [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_to_merge = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that titles of column to merge on are provided and makes sense
if(scalar @titles_of_columns_to_merge < 2)
{
	print STDERR "Error: fewer than two columns to merge provided. Nothing for me to "
		."do. Exiting.\n";
	die;
}


# reads in and processes input table
my %column_to_merge = (); # key: column (0-indexed) -> value: 1 if column will be merged
my %column_title_to_column = ();
foreach my $column_title(@titles_of_columns_to_merge)
{
	$column_title_to_column{$column_title} = -1;
}
my $first_line = 1;
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
			# identifies columns to merge
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title_to_column{$column_title})
				{
					if($column_title_to_column{$column_title} == -1)
					{
						$column_title_to_column{$column_title} = $column;
						$column_to_merge{$column} = 1;
					}
					else
					{
						print STDERR "Warning: column ".$column_title." encountered more "
							."than once in table ".$table."\n";
					}
				}
				$column++;
			}
		
			# verifies that all columns have been found
			foreach my $column_title(keys %column_title_to_column)
			{
				if($column_title_to_column{$column_title} == -1)
				{
					print STDERR "Error: expected column title ".$column_title
						." not found in table ".$table
						."\nExiting.\n";
					die;
				}
				$column++;
			}
			
			# generates merged column title
			my $merged_column_title = join("/", @titles_of_columns_to_merge);
			
			# prints column titles except merged columns
			$column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(!$column_to_merge{$column})
				{
					print $column_title.$DELIMITER;
				}
				$column++;
			}
			
			# prints merged column
			print $merged_column_title.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# retrieves values to merge
			my %value_to_merge_to_source = (); # key: value to merge -> value: column that is source
			foreach my $column_title(sort keys %column_title_to_column)
			{
				my $value_to_merge = $items_in_line[$column_title_to_column{$column_title}];
				if(defined $value_to_merge and length $value_to_merge)
				{
					if($value_to_merge_to_source{$value_to_merge})
					{
						$value_to_merge_to_source{$value_to_merge} = ", ".$column_title
					}
					else
					{
						$value_to_merge_to_source{$value_to_merge} = $column_title;
					}
				}
			}
			
			# prints a warning if values disagree
			if(scalar keys %value_to_merge_to_source > 1)
			{
				print STDERR "Warning: merge conflict:";
				foreach my $value(keys %value_to_merge_to_source)
				{
					print "\n\t".$value."\t".$value_to_merge_to_source{$value}
				}
				print "\n";
			}
			
			# determines merged value
			my $merged_value = "";
			foreach my $value(keys %value_to_merge_to_source)
			{
				if(defined $merged_value and length $merged_value)
				{
					$merged_value = ", ".$value;
				}
				else
				{
					$merged_value = $value;
				}
			}
			
			# prints columns except merged columns
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				if(!$column_to_merge{$column})
				{
					print $value.$DELIMITER;
				}
				$column++;
			}
			
			# prints merged column
			print $merged_value.$NEWLINE;
		}
	}
}
close TABLE;


# August 24, 2021
