#!/usr/bin/env perl

# Sorts the dates in the specified columns. For each row, of the dates in the specified
# columns, the earliest date will go in the first specified column, the second-earliest
# in the second specified column, etc. Empty values go last. Dates provided must be
# in YYYY-MM-DD format.

# Usage:
# perl sort_date_columns_with_paired_label_columns.pl [table] [title of column with dates]
# [title of label column that should travel with paired dates] [title of another column with dates]
# [title of label column that should travel with those paired dates] [etc.]

# Prints to console. To print to file, use
# perl sort_date_columns_with_paired_label_columns.pl [table] [title of column with dates]
# [title of label column that should travel with paired dates] [title of another column with dates]
# [title of label column that should travel with those paired dates] [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];

my @titles_of_columns_with_dates = @ARGV[map 2*$_+1, 0..$#ARGV/2-1]; # odd
my @titles_of_columns_with_labels = @ARGV[map 2*$_, 1..$#ARGV/2]; # even
# column retrieval based on https://www.perlmonks.org/?node_id=38046

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
if(!scalar @titles_of_columns_with_dates)
{
	print STDERR "Error: no column titles provided. Exiting.\n";
	die;
}
if(scalar @titles_of_columns_with_dates < 2)
{
	print STDERR "Error: only one date column provided. Nothing for me to do.\n";
	die;
}
if(scalar @titles_of_columns_with_labels != scalar @titles_of_columns_with_dates)
{
	print STDERR "Error: number of columns with date labels does not match number of "
		."columns with dates. Exiting.\n";
	die;
}


# converts arrays of column titles to hashes
my %title_is_of_column_with_date = (); # key: column title -> value: 1 if column has dates
my %title_is_of_column_with_labels = (); # key: column title -> value: 1 if column has dates
my %column_title_to_column = (); # key: included column title -> value: column
my %date_column_title_to_label_column_title = (); # key: title of column with dates -> value: title of column with labels for those dates
foreach my $column_title_index(0..$#titles_of_columns_with_dates)
{
	my $date_column_title = $titles_of_columns_with_dates[$column_title_index];
	my $label_column_title = $titles_of_columns_with_labels[$column_title_index];
	
	$date_column_title_to_label_column_title{$date_column_title} = $label_column_title;
	$title_is_of_column_with_date{$date_column_title} = 1;
	$title_is_of_column_with_labels{$label_column_title} = 1;
	$column_title_to_column{$date_column_title} = -1;
	$column_title_to_column{$label_column_title} = -1;	
}


# reads in and processes input table
my $first_line = 1;
my %column_is_column_with_dates = (); # key: column (0-indexed) -> value: 1 if column has dates
my %column_is_column_with_labels = (); # key: column (0-indexed) -> value: 1 if column has labels
my %date_column_to_label_column = (); # key: column with dates -> value: column with labels for those dates
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
			# identifies columns with dates
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $title_is_of_column_with_date{$column_title})
				{
					$column_is_column_with_dates{$column} = 1;
					$column_title_to_column{$column_title} = $column;
				}
				elsif(defined $column_title and $title_is_of_column_with_labels{$column_title})
				{
					$column_is_column_with_labels{$column} = 1;
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
			
			# matches date columns to corresponding label columns
			foreach my $date_column_title(keys %date_column_title_to_label_column_title)
			{
				my $label_column_title = $date_column_title_to_label_column_title{$date_column_title};
				my $date_column = $column_title_to_column{$date_column_title};
				my $label_column = $column_title_to_column{$label_column_title};
				$date_column_to_label_column{$date_column} = $label_column;
			}
			
			# print header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# retrieves non-empty date column values
			my @date_values = ();
			my @label_values = ();
			my @label_values_corresponding_to_empty_dates = ();
			foreach my $column_with_dates(keys %column_is_column_with_dates)
			{
				my $column_with_corresponding_labels = $date_column_to_label_column{$column_with_dates};
				
				if(value_present($items_in_line[$column_with_dates]))
				{
					push(@date_values, $items_in_line[$column_with_dates]);
					push(@label_values, $items_in_line[$column_with_corresponding_labels]);
				}
				elsif(value_present($items_in_line[$column_with_corresponding_labels]))
				{
					push(@label_values_corresponding_to_empty_dates, $items_in_line[$column_with_corresponding_labels]);
				}
			}
	
			# calculates distance from base date for each date
			my $base_date = "2021-01-01";
			my @sorted_date_indices = sort {date_difference($date_values[$a], $base_date) <=> date_difference($date_values[$b], $base_date)} (0..$#date_values);
			my @sorted_date_values = ();
			my @sorted_date_labels = ();
			foreach my $date_index(@sorted_date_indices)
			{
				my $date = $date_values[$date_index];
 				my $date_label = $label_values[$date_index];
 				
 				push(@sorted_date_values, $date);
 				push(@sorted_date_labels, $date_label);
			}
			
			# replaces date column values with sorted dates and takes their labels with them
			my $sorted_date_index = 0;
			foreach my $date_column_title(@titles_of_columns_with_dates)
			{
				# retrieves column to edit
				my $date_column = $column_title_to_column{$date_column_title};
				my $label_column = $date_column_to_label_column{$date_column};
				
				# retrieves date value that should go in that column
				my $date_value = "";
				my $label_value = "";
				if($sorted_date_index < scalar @sorted_date_values)
				{
					$date_value = $sorted_date_values[$sorted_date_index];
					$label_value = $sorted_date_labels[$sorted_date_index] if defined $sorted_date_labels[$sorted_date_index];
				}
				else
				{
					$label_value = $label_values_corresponding_to_empty_dates[$sorted_date_index - scalar @sorted_date_values]
						if defined $label_values_corresponding_to_empty_dates[$sorted_date_index - scalar @sorted_date_values];
				}
				
				# edits column values
				$items_in_line[$date_column] = $date_value;
				$items_in_line[$label_column] = $label_value;
				
				$sorted_date_index++;
			}
		
			# prints all values, including the already replaced values in columns with dates
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter
				if($column > 0)
				{
					print $DELIMITER;
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


# collection date - vaccine dose date >= 14
# input format example: 2021-07-24
sub date_difference
{
	my $date_1 = $_[0];
	my $date_2 = $_[1];
	
	my %NON_LEAP_DAYS_IN_MONTHS = (1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31,
		6 => 30, 7 => 31, 8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31);
	my $DAYS_IN_2020 = 366;
	
	if(!$date_1 or $date_1 eq "NA" or $date_1 eq "N/A"
		or !$date_2 or $date_2 eq "NA" or $date_2 eq "N/A")
	{
		return "";
	}
	
	# parses date 1
	my $year_1 = 0;
	my $month_1 = 0;
	my $day_1 = 0;
	if($date_1 =~ /^(\d{4})-(\d+)-(\d+)$/)
	{
		# retrieves date
		$year_1 = int($1);
		$month_1 = int($2);
		$day_1 = int($3);
	}
	else
	{
		print STDERR "Error: could not parse date: ".$date_1.". Exiting.\n";
		die;
	}
	if(!$NON_LEAP_DAYS_IN_MONTHS{$month_1})
	{
		print STDERR "Error: month not recognized: ".$month_1." Exiting.\n";
		die;
	}
	if($year_1 != 2020 and $year_1 != 2021)
	{
		print STDERR "Error: year not 2020 or 2021: ".$year_1.". Exiting.\n";
		die;
	}
	
	# parses date 2
	my $year_2 = 0;
	my $month_2 = 0;
	my $day_2 = 0;
	if($date_2 =~ /^(\d{4})-(\d+)-(\d+)$/)
	{
		# retrieves date
		$year_2 = int($1);
		$month_2 = int($2);
		$day_2 = int($3);
	}
	else
	{
		print STDERR "Error: could not parse date: ".$date_2.". Exiting.\n";
		die;
	}
	if(!$NON_LEAP_DAYS_IN_MONTHS{$month_2})
	{
		print STDERR "Error: month not recognized: ".$month_2." Exiting.\n";
		die;
	}
	if($year_2 != 2020 and $year_2 != 2021)
	{
		print STDERR "Error: year not 2020 or 2021: ".$year_2.". Exiting.\n";
		die;
	}
	
	# converts months to days
	$month_1--;
	while($month_1)
	{
		if($year_1 == 2020 and $month_1 == 2)
		{
			$day_1 ++;
		}
		$day_1 += $NON_LEAP_DAYS_IN_MONTHS{$month_1};
		$month_1--;
	}
	$month_2--;
	while($month_2)
	{
		if($year_2 == 2020 and $month_2 == 2)
		{
			$day_2 ++;
		}
		$day_2 += $NON_LEAP_DAYS_IN_MONTHS{$month_2};
		$month_2--;
	}
	
	# converts 2021 to +366 days (for full 2020 passed)
	if($year_1 == 2021)
	{
		$day_1 += $DAYS_IN_2020;
	}
	if($year_2 == 2021)
	{
		$day_2 += $DAYS_IN_2020;
	}
	
	# calculates difference between dates
	return $day_1 - $day_2;
}

# returns 1 if input is non-empty, 0 if not
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


# August 26, 2021
