#!/usr/bin/env perl

# Merges selected columns. Reports any conflicts.

# Usage:
# perl merge_columns.pl [table to merge] "[title of column to merge]"
# "[title of another column to merge]" "[title of another column to merge]" [etc.]

# Prints to console. To print to file, use
# perl merge_columns.pl [table to merge] "[title of column to merge]"
# "[title of another column to merge]" "[title of another column to merge]" [etc.]
# > [output table path]


use strict;
use warnings;
use Scalar::Util qw(looks_like_number);


my $table = $ARGV[0];
my @titles_of_columns_to_merge = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";


my $NUMERIC_VALUE_ALLOWED_DIFFERENCE = 1;
my $PRINT_MERGED_COLUMNS = 1;


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
				if(!$column_to_merge{$column} or $PRINT_MERGED_COLUMNS)
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
				if(value_present($value_to_merge))
				{
					if($value_to_merge_to_source{$value_to_merge})
					{
						$value_to_merge_to_source{$value_to_merge} .= ", ";
					}
					$value_to_merge_to_source{$value_to_merge} .= $column_title;
				}
			}
			
			# if values are numerical and all within a buffer of each other
			my $all_numeric = 1;
			foreach my $value(keys %value_to_merge_to_source)
			{
				if(!looks_like_number($value))
				{
					$all_numeric = 0;
				}
			}
			
			my $values_all_close_enough = 1;
			if($all_numeric)
			{
				foreach my $value_1(keys %value_to_merge_to_source)
				{
					foreach my $value_2(keys %value_to_merge_to_source)
					{
						if($value_2 - $value_1 > $NUMERIC_VALUE_ALLOWED_DIFFERENCE
							or $value_2 - $value_1 < -1 * $NUMERIC_VALUE_ALLOWED_DIFFERENCE)
						{
							$values_all_close_enough = 0;
						}
					}
				}
			}
			
			# prints a warning if values disagree
			if(scalar keys %value_to_merge_to_source > 1
				or $all_numeric and !$values_all_close_enough)
			{
				print STDERR "Warning: merge conflict:";
				foreach my $value(keys %value_to_merge_to_source)
				{
					print STDERR "\n\t".$value."\t".$value_to_merge_to_source{$value}
				}
				print STDERR "\n";
			}
			
			# determines merged value
			my $merged_value = "";
			if($all_numeric and $values_all_close_enough
				and scalar keys %value_to_merge_to_source > 1)
			{
				# if all values numerical and close enough, just takes the first one
				$merged_value = (keys %value_to_merge_to_source)[0];
			}
			else
			{
				# lists all values
				foreach my $value(sort keys %value_to_merge_to_source)
				{
					if($merged_value)
					{
						$merged_value .= ", ";
					}
					$merged_value .= $value;
				}
			}
			
			# prints columns except merged columns
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				if(!$column_to_merge{$column} or $PRINT_MERGED_COLUMNS)
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


sub value_present
{
	my $value = $_[0];
	
	# checks in various ways if value is empty
	if(!defined $value)
	{
		return 0;
	}
	if(!length $value)
	{
		return 0;
	}
	if($value !~ /\S/)
	{
		return 0;
	}
	
	# value not empty!
	return 1;
}


# August 24, 2021
