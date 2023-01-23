#!/usr/bin/env perl

# Adds column listing the date that is the latest or earliest of the specified columns but
# earlier than the cut-off date from the cut-off date column. Dates must be in YYYY-MM-DD
# format.

# Usage:
# perl add_column_with_earliest_or_latest_date_before_cutoff.pl [table]
# [0 to select earliest date, 1 to select latest date]
# "[title of column with cut-off date]" "[title of column with dates to select from]"
# "[title of another column with dates to select from]"
# "[title of another column with dates to select from]" [etc.]

# Prints to console. To print to file, use
# perl add_column_with_earliest_or_latest_date_before_cutoff.pl [table]
# [0 to select earliest date, 1 to select latest date]
# "[title of column with cut-off date]" "[title of column with dates to select from]"
# "[title of another column with dates to select from]"
# "[title of another column with dates to select from]" [etc.] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $selecting_latest_date = $ARGV[1];
my $title_of_cutoff_date_column = $ARGV[2];
my @titles_of_columns_with_dates = @ARGV[3..$#ARGV];


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


# names new date column
my $new_date_column_title = "";
if($selecting_latest_date)
{
	$new_date_column_title .= "latest";
}
else
{
	$new_date_column_title .= "earliest";
}
$new_date_column_title .= "_of_".join("_", @titles_of_columns_with_dates);


# converts array of column titles to a hash
my %title_is_of_column_with_date = (); # key: column title -> value: 1 if column has dates
my %column_title_to_column = (); # key: included column title -> value: column
foreach my $column_title(@titles_of_columns_with_dates)
{
	$title_is_of_column_with_date{$column_title} = 1;
	$column_title_to_column{$column_title} = -1;
}
$column_title_to_column{$title_of_cutoff_date_column} = -1;


# reads in and processes input table
my $first_line = 1;
my %column_is_column_with_dates = (); # key: column (0-indexed) -> value: 1 if column has dates
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
				if(defined $column_title and $column_title eq $title_of_cutoff_date_column)
				{
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
			
			# print header line with new column title
			print $line.$DELIMITER.$new_date_column_title.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# retrieves non-empty date column values
			my @date_values = ();
			foreach my $column_with_dates(keys %column_is_column_with_dates)
			{
				if(value_present($items_in_line[$column_with_dates]))
				{
					# splits date into multiple dates if there are multiple dates
					if($items_in_line[$column_with_dates] =~ /, /)
					{
						my @date_sub_values = split(", ", $items_in_line[$column_with_dates]);
						foreach my $date_sub_value( @date_sub_values)
						{
							if(value_present($date_sub_value))
							{
								push(@date_values, $date_sub_value);
							}
						}
					}
					else
					{
						push(@date_values, $items_in_line[$column_with_dates]);
					}
				}
			}
			
			# retrieves cut-off date
			my $cutoff_date = $items_in_line[$column_title_to_column{$title_of_cutoff_date_column}];
			
			# removes any date values on or after cutoff date
			my @updated_date_values = ();
			foreach my $date(@date_values)
			{
				if(date_difference($date, $cutoff_date) > 0)
				{
					push(@updated_date_values, @date_values);
				}
			}
			@date_values = @updated_date_values;
		
			# retrieves latest or earliest date
			my $result_date_value = "";
			if($selecting_latest_date)
			{
				$result_date_value = get_latest_date(@date_values);
			}
			else
			{
				$result_date_value = get_earliest_date(@date_values);
			}
			
			# print line with new column
			print $line.$DELIMITER.$result_date_value.$NEWLINE;
		}
	}
}
close TABLE;


# returns 1 if input year is a leap year, 0 if not
# input example: 2001
sub is_leap_year
{
	my $year = $_[0];
	if($year % 4 == 0)
	{
		return 1;
	}
	return 0;
}

# returns date 2 - date 1, in days
# for a use case like checking collection date - vaccine dose date >= 14
# input format example: 2021-07-24
sub date_difference
{
	my $date_1 = $_[0];
	my $date_2 = $_[1];
	
	my %days_in_months = (1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31,
		6 => 30, 7 => 31, 8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31);
	my $days_in_year = 365;
	
	# verifies that we have two non-empty dates to compare
	if(!defined $date_1 or !length $date_1 or !$date_1
		or $date_1 eq "NA" or $date_1 eq "N/A" or $date_1 eq "NaN"
		or $date_1 !~ /\S/)
	{
		return "";
	}
	if(!defined $date_2 or !length $date_2 or !$date_2
		or $date_2 eq "NA" or $date_2 eq "N/A" or $date_2 eq "NaN"
		or $date_2 !~ /\S/)
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
		print STDERR "Error: could not parse date: ".$date_1.".\n";
		return "";
	}
	if(!$days_in_months{$month_1})
	{
		print STDERR "Error: month not recognized: ".$month_1.".\n";
		return "";
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
		print STDERR "Error: could not parse date: ".$date_2.".\n";
		return "";
	}
	if(!$days_in_months{$month_2})
	{
		print STDERR "Error: month not recognized: ".$month_2.".\n";
		return "";
	}
	
	# converts months to days
	$month_1--;
	while($month_1)
	{
		if(is_leap_year($year_1) and $month_1 == 2)
		{
			$day_1 ++;
		}
		$day_1 += $days_in_months{$month_1};
		$month_1--;
	}
	$month_2--;
	while($month_2)
	{
		if(is_leap_year($year_2) and $month_2 == 2)
		{
			$day_2 ++;
		}
		$day_2 += $days_in_months{$month_2};
		$month_2--;
	}
	
	# retrieves smallest of the two years
	my $smallest_year = $year_2;
	if($year_1 < $year_2)
	{
		$smallest_year = $year_1;
	}
	
	# converts years to days since smallest year
	$year_1--;
	while($year_1 >= $smallest_year)
	{
		if(is_leap_year($year_1))
		{
			$day_1 += 1;
		}
		$day_1 += $days_in_year;
		$year_1--;
	}
	$year_2--;
	while($year_2 >= $smallest_year)
	{
		if(is_leap_year($year_2))
		{
			$day_2 += 1;
		}
		$day_2 += $days_in_year;
		$year_2--;
	}
	
	# calculates and returns difference between dates
	my $difference = $day_2 - $day_1;
	return $difference;
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

# given a list of dates, returns the earliest one
# input format example: 2021-07-24
sub get_earliest_date
{
	my @input_dates = @_;
	
	# removes empty dates
	my @dates = ();
	foreach my $input_date(@input_dates)
	{
		if(defined $input_date and length $input_date)
		{
			push(@dates, $input_date);
		}
	}
	
	# verifies that we are comparing at least two dates
	if(scalar @dates == 0) # no dates
	{
		return "";
	}
	if(scalar @dates == 1) # only one date
	{
		return $dates[0];
	}
	
	# finds earliest date
	my $base_date = "2021-01-01";
	my $earliest_date = $dates[0];
	my $earliest_date_distance_from_base_date = date_difference($earliest_date, $base_date);
	foreach my $date(@dates)
	{
		my $distance_from_base_date = date_difference($date, $base_date);
		if($distance_from_base_date > $earliest_date_distance_from_base_date)
		{
			$earliest_date = $date;
			$earliest_date_distance_from_base_date = $distance_from_base_date;
		}
	}
	return $earliest_date;
}

# given a list of dates, returns the latest one
# input format example: 2021-07-24
sub get_latest_date
{
	my @dates = @_;
	if(scalar @dates == 0)
	{
		return "";
	}
	if(scalar @dates == 1)
	{
		return $dates[0];
	}
	
	my $base_date = "2021-01-01";
	my $latest_date = $dates[0];
	my $latest_date_distance_from_base_date = date_difference($latest_date, $base_date);
	foreach my $date(@dates)
	{
		my $distance_from_base_date = date_difference($date, $base_date);
		if($distance_from_base_date < $latest_date_distance_from_base_date)
		{
			$latest_date = $date;
			$latest_date_distance_from_base_date = $distance_from_base_date;
		}
	}
	return $latest_date;
}


# August 26, 2021
# September 23, 2021
# January 23, 2023
