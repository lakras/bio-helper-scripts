#!/usr/bin/env perl

# Prints minimum date, maximum date, and difference in dates (in days) in specified
# column in each input files. Dates must be in YYYY-MM-DD format.

# Usage:
# perl calculate_date_range_in_column.pl [column number of column with dates (0-indexed)]
# [table] [another table] [another table] [etc.]

# Prints to console. To print to file, use
# perl calculate_date_range_in_column.pl [column number of column with dates (0-indexed)]
# [table] [another table] [another table] [etc.] > [output file path]


use strict;
use warnings;


my $date_column = $ARGV[0];
my @tables = @ARGV[1..$#ARGV];

my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if($date_column < 0)
{
	print STDERR "Error: date column <0. Exiting.\n";
	die;
}

# verifies that input date table columns provided
if(!scalar @tables)
{
	print STDERR "Error: no tables provided. Exiting.\n";
	die;
}

# reads in and processes input table
foreach my $table(@tables)
{
	# retrieves all dates in column
	my @dates_in_table = ();
	open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
	while(<TABLE>) # for each row in the file
	{
		chomp;
		my $line = $_;
		if($line =~ /\S/) # if row not empty
		{
			my @items_in_line = split($DELIMITER, $line, -1);
			
			# retrieves date
			my $date = date_to_YYYY_MM_DD_if_can_be_parsed($items_in_line[$date_column]);
			if($date)
			{
				push(@dates_in_table, $date);
			}
		}
	}
	close TABLE;
	
	if(scalar @dates_in_table)
	{
		# determines minimum and maximum date
		my $earliest_date = get_earliest_date(@dates_in_table);
		my $latest_date = get_latest_date(@dates_in_table);
	
		# calculates difference between minimum and maximum date
		my $date_difference = date_difference($earliest_date, $latest_date);
		
		# prints summary
		print $table.$NEWLINE;
		print $DELIMITER."earliest date: ".$earliest_date.$NEWLINE;
		print $DELIMITER."latest date: ".$latest_date.$NEWLINE;
		print $DELIMITER."date difference: ".$date_difference.$NEWLINE;
	}
	else
	{
		# prints summary
		print $table.$NEWLINE;
		print $DELIMITER."no dates".$NEWLINE;
	}
}


# example input:  07/24/2021
# example output: 2021-07-24
# returns 0 if date could not be parsed
sub date_to_YYYY_MM_DD_if_can_be_parsed
{
	my $date = $_[0];
	
	# if date does not exist, returns as is
	if(!defined $date or !length $date or !$date
		or $date eq "NA" or $date eq "N/A" or $date eq "NaN"
		or $date !~ /\S/)
	{
		return "";
	}
	
	# if date is already in output format, returns it as is
	if($date =~ /^\d{4}-\d+-\d+$/)
	{
		return $date;
	}
	
	# translates date to output format
	if($date =~ /^(\d+)\/(\d+)\/(\d+)$/)
	{
		# retrieves date
		my $year = $3;
		my $month = $1;
		my $day = $2;
		
		# pads month and/or day with 0s if necessary
		if(length($month) < 2)
		{
			$month = "0".$month;
		}
		if(length($day) < 2)
		{
			$day = "0".$day;
		}
		
		# pads year with 20 if necessary
		if(length($year) == 2)
		{
			$year = "20".$year;
		}
		elsif(length($year) != 4)
		{
			print STDERR "Error: year ".$year." in date ".$date." not 4 or 2 digits. Exiting.\n";
		}
		
		# puts date back together
		my $output = $year."-".$month."-".$day;
		
		# verifies that output is in correct format
		if($output =~ /^\d{4}-\d{2}-\d{2}$/)
		{
			return $output;
		}
		print STDERR "Error: result ".$output." of reformatting date ".$date." not in "
			."YYYY-MM-DD format. Please fix code. Exiting.\n";
		die;
	}
	return "";
}

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


# August 24, 2021
# September 23, 2021
# April 1, 2022
