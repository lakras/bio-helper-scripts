#!/usr/bin/env perl

# Verifies that the same column values always appear with row identifier values. Column
# titles must be consistent across tables, including title of row identifier column.

# Usage:
# perl verify_column_values_are_consistent_across_tables.pl [row identifier column title]
# [table1] [table2] [table 3] [etc.]

# Prints to console.


my $row_identifier_column_title = $ARGV[0]; # title of column to identify rows by
my @tables = @ARGV[1..$#ARGV]; # must each have a header line


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";


# reads in and processes input tables
my %a_column_value_has_been_recorded_for_row_identifier = (); # key: row identifier -> key: column title -> value: 1 if a value has been read in for row identifier in this column
my %this_column_value_is_valid_for_row_identifier = (); # key: row identifier -> key: column title -> key: value that has been recorded for the row identifier in this column -> value: 1
foreach my $table(@tables)
{
	my @column_to_column_title = (); # key: column (0-indexed) -> value: column title
	my %column_title_to_column = (); # key: column title -> value: column (0-indexed)
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
				# maps column titles to columns
				@column_to_column_title = @items_in_line;
				my $column = 0;
				foreach my $column_title(@column_to_column_title)
				{
					if(defined $column_title_to_column{$column_title})
					{
						print STDERR "Warning: column ".$column_title." encountered more "
							."than once in table ".$table."\n";
					}
					else
					{
						$column_title_to_column{$column_title} = $column;
					}
					$column++;
				}
		
				# verifies that all row identifier column has been found
				if(!defined $column_title_to_column{$row_identifier_column_title} == -1)
				{
					print STDERR "Error: expected row identifier column title "
						.$row_identifier_column_title." not found in table ".$table
						."\nExiting.\n";
					die;
				}
				$column++;
			
				$first_line = 0; # next line is not column titles
			}
			else # column values (not titles)
			{
				my $row_identifier = $items_in_line[$column_title_to_column{$row_identifier_column_title}];
				my $column = 0;
				foreach my $column_value(@items_in_line)
				{
					my $column_title = $column_to_column_title[$column];
					
					if($a_column_value_has_been_recorded_for_row_identifier{$row_identifier}{$column_title})
					{
						if(!$this_column_value_is_valid_for_row_identifier{$row_identifier}{$column_title}{$column_value})
						{
							print STDERR "Error: ".$column_title." column value differs "
								."between tables for row identifier ".$row_identifier.".\n";
						}
					}
					$a_column_value_has_been_recorded_for_row_identifier{$row_identifier}{$column_title} = 1;
					$this_column_value_is_valid_for_row_identifier{$row_identifier}{$column_title}{$column_value} = 1;
					
					$column++;
				}
			}
		}
	}
	close TABLE;
}


# December 21, 2021
