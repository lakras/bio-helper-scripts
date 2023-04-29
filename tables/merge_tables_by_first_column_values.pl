#!/usr/bin/env perl

# Merges (takes union of) multiple tables by the values in the first column.

# Usage:
# perl merge_tables_by_first_column_values.pl [table] [another table] [another table]
# [etc.]

# Prints to console. To print to file, use
# perl merge_tables_by_first_column_values.pl [table] [another table] [another table]
# [etc.] > [merged output table path]


use strict;
use warnings;


my @input_tables = @ARGV;


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";


# reads in all values in first column of each table
my %first_column_values = (); # key: value in any table's first column -> value: 1
foreach my $input_table(@input_tables)
{
	my $first_line = 1;
	open TABLE, "<".$input_table || die "Could not open ".$input_table." to read; terminating =(\n";
	while(<TABLE>) # for each row in the file
	{
		chomp;
		if($_ =~ /\S/) # if row not empty
		{
			my @items_in_line = split($DELIMITER, $_, -1);
			if($first_line) # column titles
			{
				$first_line = 0;
			}
			else
			{
				my $first_column_value = $items_in_line[0];
				$first_column_values{$first_column_value} = 1;
			}
		}
	}
	close TABLE;
}

# reads in each table and builds row for each first column value
my $header_line = ""; # header line to print to output
my %first_column_value_to_row = (); # key: first column value -> value: row to print
my $first_table = 1;
foreach my $input_table(@input_tables)
{
	# reads in table and adds its columns
	my $first_line = 1;
	my $number_columns_in_table = 0;
	my %first_column_value_found_in_table = (); # key: first column value -> value: 1 if found in table
	open TABLE, "<".$input_table || die "Could not open ".$input_table." to read; terminating =(\n";
	while(<TABLE>) # for each row in the file
	{
		chomp;
		if($_ =~ /\S/) # if row not empty
		{
			my @items_in_line = split($DELIMITER, $_, -1);
			if($first_line) # column titles
			{
				# removes first column title from header row
				my $header_row_without_first_column = $_;
				if(!$first_table)
				{
					if($_ =~ /^.+$DELIMITER(.*)$/)
					{
						$header_row_without_first_column = $1;
					}
					else
					{
						print STDERR "Error: header row does not contain delimiter.\n";
					}
				}
				
				# saves column titles
				if($header_line)
				{
					$header_line .= $DELIMITER;
				}
				$header_line .= $header_row_without_first_column;
				
				$number_columns_in_table = scalar @items_in_line;
				$first_line = 0;
			}
			else
			{
				my $first_column_value = $items_in_line[0];
				$first_column_value_found_in_table{$first_column_value} = 1;
				
				# removes first column value from row
				my $row_without_first_column = "";
				if($_ =~ /^$first_column_value$DELIMITER(.*)$/)
				{
					$row_without_first_column = $1;
				}
				else
				{
					print STDERR "Error: first column value not found in its row. "
						."Something is wrong with the code.\n";
				}
				
				# saves this row
				if($first_column_value_to_row{$first_column_value})
				{
					$first_column_value_to_row{$first_column_value} .= $DELIMITER;
				}
				$first_column_value_to_row{$first_column_value} .= $row_without_first_column;
			}
		}
	}
	close TABLE;
	$first_table = 0;
	
	# adds empty columns for values not found
	foreach my $first_column_value(keys %first_column_values)
	{
		if(!$first_column_value_found_in_table{$first_column_value}) # if this first column value did not appear in this table
		{
			if($first_column_value_to_row{$first_column_value})
			{
				$first_column_value_to_row{$first_column_value} .= $DELIMITER;
			}
			for(my $count = 0; $count < $number_columns_in_table; $count++)
			{
				$first_column_value_to_row{$first_column_value} .= $DELIMITER;
			}
		}
	}
}

# prints output table
print $header_line;
print $NEWLINE;
foreach my $first_column_value(keys %first_column_values)
{
	print $first_column_value;
	print $DELIMITER;
	print $first_column_value_to_row{$first_column_value};
	print $NEWLINE;
}


# April 29, 2023
