#!/usr/bin/env perl

# Combines each selected pair of columns into one column with all values. Does not merge
# values.

# Example input:
# columnA	columnB	columnC	columnD	columnE	columnF	columnG
# A1		B1		C1		D1		E1		F1		G1
# A2		B2		C2		D2		E2		F2		G2
# A3		B3		C3		D3		E3		F3		G3
# A4		B4		C4		D4		E4		F4		G4
# A5		B5		C5		D5		E5		F5		G5


# Example input titles 1, specifying that we should combine columnB and columnC:
# columnB	columnD

# Example output 1 (extra whitespace added in this comment to make output easier to read):
# columnA	columnB_columnD	columnC	columnE	columnF	columnG
# A1		B1				C1		E1		F1		G1
# A1		D1				C1		E1		F1		G1
# A2		B2				C2		E2		F2		G2
# A2		D2				C2		E2		F2		G2
# A3		B3				C3		E3		F3		G3
# A3		D3				C3		E3		F3		G3
# A4		B4				C4		E4		F4		G4
# A4		D4				C4		E4		F4		G4
# A5		B5				C5		E5		F5		G5
# A5		D5				C5		E5		F5		G5

# Notice that all values from columnB and columnD now appear in columnB_columnD. There
# are twice as many rows in the output as there were in the input. Values in all other
# columns appear twice, once for columnB and once for columnD.


# Example input titles 2, specifying that we should combine columnB and columnE, columnC
# and columnF, and columnD and columnG. These three column pairs will not be combined
# independently: the values in columnB, columnC, and columnD will be tied together, while
# the values in columnE, columnF, and columnG will be tied together.
# columnB	columnE
# columnC	columnF
# columnD	columnG

# Example output 2 (extra whitespace added in this comment to make output easier to read):
# columnA	columnB_columnE	columnC_columnF	columnD_columnG
# A1		B1				C1				D1
# A1		E1				F1				G1
# A2		B2				C2				D2
# A2		E2				F2				G2
# A3		B3				C3				D3
# A3		E3				F3				G3
# A4		B4				C4				D4
# A4		E4				F4				G4
# A5		B5				C5				D5
# A5		E5				F5				G5

# Notice that all values from columnB and columnE now appear in columnB_columnE. As in the
# previous example, values in columnA appear twice, once for each of columnB and columnE.
# Values from columnC and columnD, however, only accompany values from column B, while
# values from columnF and columnG only accompany values from column E.


# Example input titles 3 (extra whitespace added in this comment to make output easier to read):
# columnA	columnB	columnE
# 			columnC	columnF
# 			columnD	columnG

# Example output 3 (extra whitespace added in this comment to make output easier to read):
# columnA_columnB_columnE	columnC_columnF	columnD_columnG
# A1										
# B1						C1				D1
# E1						F1				G1
# A2										
# B2						C2				D2
# E2						F2				G2
# A3										
# B3						C3				D3
# E3						F3				G3
# A4										
# B4						C4				D4
# E4						F4				G4
# A5										
# B5						C5				D5
# E5						F5				G5

# Notice that in this example, columnA, columnB, and columnE are combined into one column,
# columnA_columnB_columnE. However, while the values of columnB are tied to the values of
# columnC and columnF, and the values of columnE are tied to the values of columnF and
# columnG, the values of columnA appear alone.


# Usage:
# perl combine_columns.pl [input table] [list of tab-separated groups of titles of columns
# to combine, one group per line]

# Prints to console. To print to file, use
# perl combine_columns.pl [input table] [list of tab-separated groups of titles of columns
# to combine, one group per line] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $file_with_titles_of_columns_to_combine = $ARGV[1];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";

my $DUMMY_COLUMN_TITLE = "__EMPTY"; # no input column titles should match this value


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# determines maximum number column titles we have in each line
my $maximum_number_column_titles_in_line = 0;
open COLUMN_TITLES_TABLE, "<$file_with_titles_of_columns_to_combine"
	|| die "Could not open $file_with_titles_of_columns_to_combine to read; terminating =(\n";
while(<COLUMN_TITLES_TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		my $number_items_in_line = 0;
		foreach my $column_title(@items_in_line)
		{
			if($column_title)
			{
				$number_items_in_line++;
			}
		}
		
		if($number_items_in_line > $maximum_number_column_titles_in_line)
		{
			$maximum_number_column_titles_in_line = $number_items_in_line;
		}
	}
}
close COLUMN_TITLES_TABLE;


# assigned relationships between columns
my %column_title_to_titles_of_columns_to_combine = ();
my %column_title_is_column_to_combine = (); # key: column title -> value: 1 if column will be combined with another column
my %column_title_to_column_group = (); # key: column title -> value: column it appears in in column titles table, to process what columns should accompany each other (1-indexed)

# for reading in and processing input table
my %column_title_to_column = (); # key: column title -> value: column number (0-indexed)
my @column_to_column_title = (); # key: column number (0-indexed) -> value: column title

my @empty_column_titles = (); # dummy column titles to add to input
my $empty_column_count = 0;

# reads in and processes table with titles of columns to combine
open COLUMN_TITLES_TABLE, "<$file_with_titles_of_columns_to_combine"
	|| die "Could not open $file_with_titles_of_columns_to_combine to read; terminating =(\n";
while(<COLUMN_TITLES_TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @titles_of_columns_to_combine = split($DELIMITER, $line, -1);
		my $column_titles_table_column = 0;
		
		# fills in empty column titles
		for my $index(0 .. $#titles_of_columns_to_combine)
		{
			my $column_title = $titles_of_columns_to_combine[$index];
			if(!$column_title)
			{
				my $dummy_column_title = $DUMMY_COLUMN_TITLE.$empty_column_count;
				$empty_column_count++;
				push(@empty_column_titles, $dummy_column_title);
				$titles_of_columns_to_combine[$index] = $dummy_column_title;
			}
		}
		
		# groups column titles from this line with other column titles in both dimensions
		foreach my $column_title(@titles_of_columns_to_combine)
		{
			# records that this is this title of a column to combine with other columns
			$column_title_is_column_to_combine{$column_title} = 1;
			
			# records that we do not yet know the column number of this column title
			$column_title_to_column{$column_title} = -1;
			
			# records that this column should be combined with all other columns listed in this line
			@{$column_title_to_titles_of_columns_to_combine{$column_title}} = @titles_of_columns_to_combine;#@nonempty_titles_of_columns_to_combine;
			
			# prepares to record that this column should accompany other columns appearing
			# in this column of the table with titles
			$column_title_to_column_group{$column_title} = $column_titles_table_column+1;
			$column_titles_table_column++;
		}
	}
}
close COLUMN_TITLES_TABLE;


# reads in and processes input table
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
			# verifies that no column titles match dummy variable
			foreach my $column_title(@items_in_line)
			{
				if($column_title =~ /$DUMMY_COLUMN_TITLE/)
				{
					print STDERR "Error: input column title ".$column_title." contains "
						."dummy value used internally to name empty columns: "
						.$DUMMY_COLUMN_TITLE.". Please rename column title. Exiting.\n";
					die;
				}
			}
		
			# identifies columns to combine
			@column_to_column_title = (@items_in_line, @empty_column_titles);
			my $column = 0;
			foreach my $column_title(@column_to_column_title)
			{
				if(defined $column_title_to_column{$column_title})
				{
					if($column_title_to_column{$column_title} == -1)
					{
						$column_title_to_column{$column_title} = $column;
					}
					else
					{
						print STDERR "Error: column ".$column_title." encountered more "
							."than once in input table:\n\t".$table."\nExiting.\n";
						die;
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
						." not found in input table\n\t".$table."\nExiting.\n";
					die;
				}
				$column++;
			}
			
			# prints column titles
			my %combined_column_already_printed = (); # key: column title -> value: 1 if combined column including this column has already been printed
			foreach my $column_title(@items_in_line)
			{
				if($column_title_is_column_to_combine{$column_title})
				{
					# this is a column to combine with other columns
					if(!$combined_column_already_printed{$column_title})
					{
						my @titles_of_columns_to_combine = @{$column_title_to_titles_of_columns_to_combine{$column_title}};
						
						# records that we have printed combined column title
						foreach my $column_title_from_combined_columns(@titles_of_columns_to_combine)
						{
							$combined_column_already_printed{$column_title_from_combined_columns} = 1;
						}
						
						# removes dummy columns
						@titles_of_columns_to_combine = grep {!/$DUMMY_COLUMN_TITLE/} @titles_of_columns_to_combine;
					
						# generates and prints combined column title
						my $combined_column_title = join("_", @titles_of_columns_to_combine);
						print $combined_column_title.$DELIMITER;
					}
				}
				else # not a column to combine with other columns
				{
					print $column_title.$DELIMITER;
				}
			}
			print $NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not titles)
		{
			# generates rows to print based on this row
			my @rows_to_print = (""); # list of rows to print built out of this row
			my @rows_index_to_column_group = (); # key: index of row in @rows_to_print -> value: column that added columns are in in the columns titles table (1-indexed)
			my %column_group_printed = (); # key: column that added columns are in in the columns titles table (1-indexed) -> value: 1 if any column from that group has already been printed, 0 if not
			my %combined_column_already_printed = (); # key: column title -> value: 1 if combined column including this column has already been printed
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				my $column_title = $column_to_column_title[$column];
				if($column_title_is_column_to_combine{$column_title})
				{
					# this is a column to combine with other columns
					if(!$combined_column_already_printed{$column_title})
					{
						# retrieves and adds values from all columns to combine with this column
						my @titles_of_columns_to_combine = @{$column_title_to_titles_of_columns_to_combine{$column_title}};
						my @updated_rows_to_print = ();
						my @updated_rows_index_to_column_group = ();
						my $column_group = $column_title_to_column_group{$column_title};
						foreach my $column_title_from_combined_columns(@titles_of_columns_to_combine)
						{
							# retrieves value from column to combine with this column
							my $value_to_add = $items_in_line[$column_title_to_column{$column_title_from_combined_columns}];
							if(!defined $value_to_add)
							{
								$value_to_add = "";
							}
							
							# makes new version of row to print with that column's value
							my $row_index = 0;
							foreach my $row_to_print(@rows_to_print)
							{
								if(!$rows_index_to_column_group[$row_index]
									or $rows_index_to_column_group[$row_index] == $column_title_to_column_group{$column_title_from_combined_columns})
								{
									# copies row with new value added on
									my $updated_row = $row_to_print;
									if($updated_row)
									{
										$updated_row .= $DELIMITER;
									}
									$updated_row .= $value_to_add;
									push(@updated_rows_to_print, $updated_row);
									push(@updated_rows_index_to_column_group, $column_title_to_column_group{$column_title_from_combined_columns});
									$column_group_printed{$column_title_to_column_group{$column_title_from_combined_columns}} = 1;
								}
								$row_index++;
							}
						
							# records that we have added this column to this combined column
							$combined_column_already_printed{$column_title_from_combined_columns} = 1;
						}
						
						# updated rows list is now n times as long, where n is the number of columns that were combined
						@rows_to_print = @updated_rows_to_print;
						@rows_index_to_column_group = @updated_rows_index_to_column_group;
					}
				}
				else # not a column to combine with other columns
				{
					# adds column value to all rows
					for my $row_index(0 .. $#rows_to_print)
					{
						if($rows_to_print[$row_index])
						{
							$rows_to_print[$row_index] .= $DELIMITER;
						}
						$rows_to_print[$row_index] .= $value;
					}
				}
				$column++;
			}
			
			# prints rows generated from this row
			foreach my $row_to_print(@rows_to_print)
			{
				print $row_to_print;
				print $NEWLINE;
			}
		}
	}
}
close TABLE;


# November 4, 2021
