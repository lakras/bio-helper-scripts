#!/usr/bin/env perl

# Merges (takes union of) all columns in rows with shared value in column to merge by.
# If titles of columns not to merge by are provided, leaves one row per input row with
# all other columns identical. If no columns not to merge by provided, fully merges any
# rows sharing a value in column to merge by (one row per value).

# Usage:
# perl merge_rows_by_column_value.pl [table to merge] [title of column to merge by]
# [optional title of column not to merge] [optional title of another column not to merge] [etc.]

# Prints to console. To print to file, use
# perl merge_rows_by_column_value.pl [table to merge] [title of column to merge by]
# [optional title of column not to merge] [optional title of another column not to merge]
# [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $title_of_column_to_merge_by = $ARGV[1];
my @titles_of_columns_not_to_merge = @ARGV[2..$#ARGV];


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

# verifies that title of column to merge on is provided
if(!defined $title_of_column_to_merge_by or !length $title_of_column_to_merge_by)
{
	print STDERR "Error: title of column to merge on not provided. Exiting.\n";
	die;
}


# reads in and processes input table
my $first_line = 1;
my $column_to_merge_by = -1;
my %dont_merge_column = (); # key: column number (0-indexed) -> value: 1 if we should not merge this column
my $line_number = 0;
my %value_to_merge_by_to_input_lines = (); # key: value to merge by -> key: input line -> value: line number
my %value_to_merge_by_to_first_line_number = (); # key: value to merge by -> key: number of first line it appears in
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
			# identifies column to merge by and columns not to merge
			my %dont_merge_column_title_found = (); # key: column title of column not to merge -> value: 1 if found in input table
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title)
				{
					if($column_title eq $title_of_column_to_merge_by)
					{
						if($column_to_merge_by != -1)
						{
							print STDERR "Error: title of column to merge by "
								.$title_of_column_to_merge_by." appears more than once in table:"
								."\n\t".$table."\nExiting.\n";
							die;
						}
						$column_to_merge_by = $column;
					}
					else
					{
						foreach my $title_of_column_not_to_merge(@titles_of_columns_not_to_merge)
						{
							if($column_title eq $title_of_column_not_to_merge)
							{
								$dont_merge_column{$column} = 1;
								$dont_merge_column_title_found{$column_title} = 1;
							}
						}
					}
				}
				$column++;
			}
			
			# verifies that we have found column to merge by
			if($column_to_merge_by == -1)
			{
				print STDERR "Error: could not find title of column to merge by "
					.$title_of_column_to_merge_by." in table:\n\t".$table."\nExiting.\n";
				die;
			}
			
			# verifies that we have found all columns not to merge
			foreach my $title_of_column_not_to_merge(@titles_of_columns_not_to_merge)
			{
				if(!$dont_merge_column_title_found{$title_of_column_not_to_merge})
				{
					print STDERR "Error: could not find title of column to not merge "
						.$title_of_column_not_to_merge." in table:\n\t"
						.$table."\nExiting.\n";
					die;
				}
			}
			
			# prints column titles
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# retrieves value to merge by
			my $value_to_merge_by = $items_in_line[$column_to_merge_by];
			
			# saves input line
			if(!$value_to_merge_by_to_input_lines{$value_to_merge_by}{$line})
			{
				$line_number++;
				$value_to_merge_by_to_input_lines{$value_to_merge_by}{$line} = $line_number;
				if(!$value_to_merge_by_to_first_line_number{$value_to_merge_by})
				{
					$value_to_merge_by_to_first_line_number{$value_to_merge_by} = $line_number;
				}
			}
		}
	}
}
close TABLE;

# merges and prints rows by value to merge by in order of appearance
for my $value_to_merge_by( # sort by order of appearance
	sort {$value_to_merge_by_to_first_line_number{$a} <=> $value_to_merge_by_to_first_line_number{$b}}
	keys %value_to_merge_by_to_input_lines)
{
	my @merged_values = ();
	
	# traverses all input lines with this value to merge by
	# merges columns that aren't marked not to be merged
	for my $input_line( # sort by order of appearance
		sort {$value_to_merge_by_to_input_lines{$value_to_merge_by}{$a} <=> $value_to_merge_by_to_input_lines{$value_to_merge_by}{$b}}
		keys %{$value_to_merge_by_to_input_lines{$value_to_merge_by}})
	{
		my @items_in_line = split($DELIMITER, $input_line, -1);
		my $column = 0;
		foreach my $value(@items_in_line)
		{
			if(value_present($value) and !$dont_merge_column{$column})
			{
				if(!value_present($merged_values[$column]) or $merged_values[$column] ne $value)
				{
					if(length $merged_values[$column])
					{
						$merged_values[$column] .= ", ";
					}
					$merged_values[$column] .= $value;
				}
			}
			$column++;
		}
	}
	
	# if there aren't any columns not to merge by, prints merged line
	if(!scalar @titles_of_columns_not_to_merge)
	{
		print join($DELIMITER, @merged_values).$NEWLINE;
	}
	
	# if there are columns not to merge by, prints row for each input row in order it originally appeared in
	else
	{
		for my $input_line( # sort by order of appearance
			sort {$value_to_merge_by_to_input_lines{$value_to_merge_by}{$a} <=> $value_to_merge_by_to_input_lines{$value_to_merge_by}{$b}}
			keys %{$value_to_merge_by_to_input_lines{$value_to_merge_by}})
		{
			my @items_in_line = split($DELIMITER, $input_line, -1);
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter (tab) if needed
				if($column > 0)
				{
					print $DELIMITER;
				}
				
				# prints merged or original value
				if($dont_merge_column{$column})
				{
					# print original, unmerged value
					if(defined $value)
					{
						print $value;
					}
				}
				else
				{
					# print merged value
					if(defined $merged_values[$column])
					{
						print $merged_values[$column];
					}
				}
				$column++;
			}
			print $NEWLINE;
		}
	}
}


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


# August 23, 2021
