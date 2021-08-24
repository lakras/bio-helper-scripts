#!/usr/bin/env perl

# Adds column listing difference in dates between columns specified in parameter column
# titles. Dates must be in YYYY-MM-DD format. Column titles must not have spaces.
# Not guaranteed to work for dates outside of 2021 (sorry!).

# Usage:
# perl add_difference_in_dates_column.pl [table] [title of column with dates]
# [title of another column with dates] [optional title of new column]

# Prints to console. To print to file, use
# perl add_difference_in_dates_column.pl [table] [title of column with dates]
# [title of another column with dates] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $dates_1_column_title = $ARGV[1];
my $dates_2_column_title = $ARGV[2];
my $date_difference_column_title = $ARGV[3];

my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# verifies that input date table columns make sense
if(!defined $dates_1_column_title or !defined $dates_2_column_title)
{
	print STDERR "Error: date column titles not both provided. Exiting.\n";
	die;
}
if($dates_1_column_title eq $dates_2_column_title)
{
	print STDERR "Error: date column titles are identical. Exiting.\n";
	die;
}


# names new date difference column
if(!defined $date_difference_column_title)
{
	$date_difference_column_title = "days_from_".$dates_1_column_title."_to_".$dates_2_column_title;
}

# reads in and processes input table
my $first_line = 1;
my $date_1_column = -1;
my $date_2_column = -1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line);
		if($first_line) # column titles
		{
			# identifies columns to include
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $dates_1_column_title)
				{
					if($date_1_column != -1)
					{
						print STDERR "Warning: date column title ".$dates_1_column_title
							." appears more than once in input table:\n\t".$table."\n";
					}
					$date_1_column = $column;
				}
				if(defined $column_title and $column_title eq $dates_2_column_title)
				{
					if($date_2_column != -1)
					{
						print STDERR "Warning: date column title ".$dates_2_column_title
							." appears more than once in input table:\n\t".$table."\n";
					}
					$date_2_column = $column;
				}
				$column++;
			}
			
			# verifies that we have found all columns to include
			if($date_1_column == -1 or $date_2_column == -1)
			{
				print STDERR "Error: expected column titles not found in table "
					.$table."\nExiting.\n";
				die;
			}
			
			# print header line with new column title
			print $line.$DELIMITER.$date_difference_column_title.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# retrieves dates
			my $date_1 = $items_in_line[$date_1_column];
			my $date_2 = $items_in_line[$date_2_column];
		
			# calculates difference between dates
			my $date_difference = date_difference($date_1, $date_2);
			if(!defined $date_difference)
			{
				$date_difference = "";
			}
			
			# print line with new column
			print $line.$DELIMITER.$date_difference.$NEWLINE;
		}
	}
}
close TABLE;


# example input:  07/24/2021
# example output: 2021-07-24
sub date_to_YYYY_MM_DD
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
	print STDERR "Error: date not in recognized format: ".$date
		.". Please fix input or code. Exiting.\n";
	die;
}

# returns date 2 - date 1, in days
# for a use case like checking collection date - vaccine dose date >= 14
# input format example: 2021-07-24
sub date_difference
{
	my $date_1 = $_[0];
	my $date_2 = $_[1];
	
	my %NON_LEAP_DAYS_IN_MONTHS = (1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31,
		6 => 30, 7 => 31, 8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31);
	my $DAYS_IN_2020 = 366;
	
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
	
	# calculates and returns difference between dates
	my $difference = $day_2 - $day_1;
	return $difference;
}


# August 24, 2021
