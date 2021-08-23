#!/usr/bin/env perl

# Merges (takes union of) multiple tables by the values in the specified columns.

# Input table has one row per table with tab-separated columns:
# - input table path
# - title column to merge by in 
# - optional: Remaining tab-separated columns list titles of columns to include in output.
#   If no column titles are provided, all columns are printed in the output.

# Usage:
# perl merge_tables_by_column_value.pl [file describing input]

# Prints to console. To print to file, use
# perl merge_tables_by_column_value.pl [file describing input] > [merged output table path]


use strict;
use warnings;


my $input_descriptions = $ARGV[0];


my $INPUT_DESCRIPTIONS_TABLE_PATH_COLUMN = 0;
my $INPUT_DESCRIPTIONS_COLUMN_TO_MERGE_BY_COLUMN = 1;


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";


my $APPEND_FILENAME_TO_COLUMN_TITLES = 1;


# verifies that input description table exists and is non-empty
if(!$input_descriptions)
{
	print STDERR "Error: input description table not provided. Exiting.\n";
	die;
}
if(!-e $input_descriptions)
{
	print STDERR "Error: input description table does not exist:\n\t".$input_descriptions."\nExiting.\n";
	die;
}
if(-z $input_descriptions)
{
	print STDERR "Error: input description table is empty:\n\t".$input_descriptions."\nExiting.\n";
	die;
}


# reads in input descriptions
my %table_path_to_column_title_to_merge_by = (); # key: table path -> value: title of column to merge by
my %table_path_to_include_all_columns = (); # key: table path -> value: 1 if we should include all columns from this table, 0 if not
my %table_path_to_column_title_to_included = (); # key: table path -> key: column title -> value: 1 if column will be included in output, 0 if not
open INPUT_DESCRIPTIONS, "<$input_descriptions" || die "Could not open $input_descriptions to read; terminating =(\n";
while(<INPUT_DESCRIPTIONS>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $_);
		
		# retrieves values
		my $table_path = $items_in_line[$INPUT_DESCRIPTIONS_TABLE_PATH_COLUMN];
		my $column_title_to_merge_by = $items_in_line[$INPUT_DESCRIPTIONS_COLUMN_TO_MERGE_BY_COLUMN];
		my @column_titles_to_include = ();
		foreach my $column_title(@items_in_line[$INPUT_DESCRIPTIONS_COLUMN_TO_MERGE_BY_COLUMN+1..$#items_in_line])
		{
			# saves only column titles containing at least one non-whitespace character
			if($column_title =~ /\S/)
			{
				push(@column_titles_to_include, $column_title);
			}
		}
		
		# verifies that input values make sense
		if(!$table_path or !-e $table_path or -z $table_path)
		{
			print STDERR "Error: input table path does not exist or is empty:\n\t"
				.$table_path."\nExiting.\n";
			die;
		}
		if(!$column_title_to_merge_by)
		{
			print STDERR "Error: column title to merge by not provided in input for table:\n\t"
				.$table_path."\nExiting.\n";
			die;
		}
		
		# verifies that we haven't already seen this table path
		if($table_path_to_column_title_to_merge_by{$table_path})
		{
			print STDERR "Error: table path listed more than once in input:\n\t"
				.$table_path."\nExiting.\n";
			die;
		}
		
		# saves values
		$table_path_to_column_title_to_merge_by{$table_path} = $column_title_to_merge_by;
		if(scalar @column_titles_to_include) # provided column titles to include
		{
			$table_path_to_include_all_columns{$table_path} = 0;
			foreach my $column_title(@column_titles_to_include)
			{
				$table_path_to_column_title_to_included{$table_path}{$column_title} = 1;
			}
		}
		else # no column titles to include--include them all
		{
			$table_path_to_include_all_columns{$table_path} = 1;
		}
	}
}
close INPUT_DESCRIPTIONS;


# reads in input tables
my %table_path_to_column_titles_to_print = (); # key: table path -> value: column titles to print
my %table_path_to_empty_line_to_print = (); # key: table path -> value: what should be printed if there is nothing to print
my %value_to_merge_by_to_table_path_to_values_to_print = (); # key: value to merge by -> key: table path -> value: column values to print
my $merged_column_title_of_value_to_merge_on = "";
foreach my $table_path(keys %table_path_to_column_title_to_merge_by)
{
	my $first_line = 1;
	my $column_to_merge_by = -1;
	my %column_included = (); # key: column number (0-indexed) -> value: 1 if column will be included in output, 0 if not
	open TABLE, "<$table_path" || die "Could not open $table_path to read; terminating =(\n";
	while(<TABLE>) # for each row in the file
	{
		chomp;
		if($_ =~ /\S/) # if row not empty
		{
			my @items_in_line = split($DELIMITER, $_);
			if($first_line) # column titles
			{
				# identifies column to merge by and columns to include in output
				my $column = 0;
				foreach my $column_title(@items_in_line)
				{
					if($column_title)
					{
						if($column_title eq $table_path_to_column_title_to_merge_by{$table_path})
						{
							if($column_to_merge_by != -1)
							{
								print STDERR "Error: title of column to merge by "
									.$table_path_to_column_title_to_merge_by{$table_path}
									." appears more than once in table:"
									."\n\t".$table_path."\nExiting.\n";
								die;
							}
							$column_to_merge_by = $column;
							
							if($merged_column_title_of_value_to_merge_on)
							{
								$merged_column_title_of_value_to_merge_on .= "/";
							}
							$merged_column_title_of_value_to_merge_on .= $column_title;
						}
						if($table_path_to_include_all_columns{$table_path}
							or $table_path_to_column_title_to_included{$table_path}{$column_title})
						{
							$column_included{$column} = 1;
						}
					}
					$column++;
				}
				
				# verifies that we have found column to merge by
				if($column_to_merge_by == -1)
				{
					print STDERR "Error: could not find column to merge by "
						.$table_path_to_column_title_to_merge_by{$table_path}." in table:"
						."\n\t".$table_path."\nExiting.\n";
					die;
				}
			}
			
			# retrieves value to merge by and chunk of line to print
			my $value_to_merge_by = $items_in_line[$column_to_merge_by];
			my $to_print = "";
			foreach my $included_column(sort keys %column_included)
			{
				$to_print .= $DELIMITER;
				if($APPEND_FILENAME_TO_COLUMN_TITLES and $first_line)
				{
					$to_print .= filename($table_path)." ";
				}
				$to_print .= $items_in_line[$included_column];
			}
			
			# saves column titles to print if this line is column titles
			if($first_line)
			{
				$table_path_to_column_titles_to_print{$table_path} = $to_print;
			}
			
			# generates empty line to print if a value to merge on does not appear in this table
			if($first_line)
			{
				foreach my $included_column(sort keys %column_included)
				{
					$table_path_to_empty_line_to_print{$table_path} .= $DELIMITER;
				}
			}
			
			# saves values to print if this line is values (rather than column titles)
			else
			{
				if($value_to_merge_by_to_table_path_to_values_to_print{$value_to_merge_by}{$table_path})
				{
					if($value_to_merge_by_to_table_path_to_values_to_print{$value_to_merge_by}{$table_path} ne $to_print)
					{
						print STDERR "Error: value to merge by ".$value_to_merge_by
							." appears more than once in table:"."\n\t".$table_path
							."\nValues are different. Exiting.\n";
					}
					else
					{
						print STDERR "Warning: value to merge by ".$value_to_merge_by
							." appears more than once in table:"."\n\t".$table_path."\n";
					}
				}
				$value_to_merge_by_to_table_path_to_values_to_print{$value_to_merge_by}{$table_path} = $to_print;
			}
			$first_line = 0; # next line is not column titles
		}
	}
	close TABLE;
}

# prints column titles
print $merged_column_title_of_value_to_merge_on;
foreach my $table_path(keys %table_path_to_column_title_to_merge_by)
{
	print $table_path_to_column_titles_to_print{$table_path};
}
print $NEWLINE;

# prints merged output table values
foreach my $value_to_merge_by(keys %value_to_merge_by_to_table_path_to_values_to_print)
{
	print $value_to_merge_by;
	foreach my $table_path(keys %table_path_to_column_title_to_merge_by)
	{
		if($value_to_merge_by_to_table_path_to_values_to_print{$value_to_merge_by}{$table_path})
		{
			print $value_to_merge_by_to_table_path_to_values_to_print{$value_to_merge_by}{$table_path};
		}
		else
		{
			print $table_path_to_empty_line_to_print{$table_path};
		}
	}
	print $NEWLINE;
}


# example input:  /Users/lakras/my_file.txt
# example output: my_file.txt
sub filename
{
	my $filepath = $_[0];
	
	if($filepath =~ /^.*\/([^\/]+)$/)
	{
		return $1;
	}
	return "";
}

# August 19, 2021
