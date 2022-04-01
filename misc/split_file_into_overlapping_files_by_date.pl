#!/usr/bin/env perl

# Splits file with multiple lines up into overlapping smaller files, each containing dates
# within twice the parameter number of days. Each line will appear in two files.

# Usage:
# perl split_file_into_overlapping_files_by_date.pl [file path]
# [half the date range in each output file] [column containing dates, 0-indexed]

# New files are created at filepath of old file with "_1.txt", "_2.txt", etc. appended to
# the end. Files already at those paths will be overwritten.


use strict;
use warnings;


my $file = $ARGV[0];
my $half_date_distance_in_each_file = $ARGV[1]; # inclusive, in days
my $date_column = $ARGV[2]; # column containing date, 0-indexed


my $NEWLINE = "\n";
my $DELIMITER = "\t";

my $OVERWRITE = 1; # set to 0 to prevent overwriting (stop script rather than overwrite)


# verifies that input file exists and is not empty
if(!$file)
{
	print STDERR "Error: no input file provided. Exiting.\n";
	die;
}
if(!-e $file)
{
	print STDERR "Error: input file does not exist:\n\t".$file."\nExiting.\n";
	die;
}
if(-z $file)
{
	print STDERR "Error: input file is empty:\n\t".$file."\nExiting.\n";
	die;
}

# sanity check date distance
if($half_date_distance_in_each_file < 2)
{
	print STDERR "Date distance < 2. Exiting.\n";
	die;
}

# sanity check date column
if($date_column < 0)
{
	print STDERR "Date column < 0. Exiting.\n";
	die;
}


# sort input file by date
my $sorted_file = $file."_sorted.txt";
my $date_column_1_indexed = $date_column + 1;
verify_output_file_ok_to_write($sorted_file);
`sort -k $date_column_1_indexed $file > $sorted_file`;
$file = $sorted_file;


# prepares to read in input file and generate first output file
my $start_date = ""; # first date in output file
my $file_number = 1; # file number of current output file (appears at the end of the output file path)
my $output_file = $file."_".$file_number.".txt"; # current output file we are printing to
verify_output_file_ok_to_write($output_file);


# splits file into smaller files
open OUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";
open FILE, "<$file" || die "Could not open $file to read; terminating =(\n";
my $distance_from_start_date = 0;
while(<FILE>) # for each line in the file
{
	chomp;
	
	# retrieves date from file
	my @items_in_line = split($DELIMITER, $_, -1);
	my $date = date_to_YYYY_MM_DD($items_in_line[$date_column]);
	if(!$start_date)
	{
		$start_date = $date;
	}
	$distance_from_start_date = date_difference($start_date, $date);
	
	# opens new output file if necessary
	if($distance_from_start_date >= $half_date_distance_in_each_file)
	{
		close OUT_FILE;
		$file_number++;
		$start_date = "";
		$output_file = $file."_".$file_number.".txt";
		verify_output_file_ok_to_write($output_file);
		open OUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";
	}

	# prints this line
	print OUT_FILE $_."\n";
}
close FILE;
close OUT_FILE;


# merges last two files if last file is too small
if($distance_from_start_date < $half_date_distance_in_each_file)
{
	my $last_file = $file."_".$file_number.".txt";
	my $second_to_last_file = $file."_".($file_number-1).".txt";
	my $temp_file = $last_file."_temp.txt";
	verify_output_file_ok_to_write($temp_file);
	`cat $second_to_last_file $last_file > $temp_file`;
	`rm $last_file`;
	`rm $second_to_last_file`;
	`mv $temp_file $second_to_last_file`;
	$file_number--;
}


# combines adjacent files
# 1 2 3 4 5 6
# 12 23 34 45 56
for my $half_sized_file_number_1(1..$file_number-1)
{
	my $half_sized_file_number_2 = $half_sized_file_number_1 + 1;
	
	my $half_sized_file_1 = $file."_".$half_sized_file_number_1.".txt";
	my $half_sized_file_2 = $file."_".$half_sized_file_number_2.".txt";
	
	my $combined_files = $file."_".$half_sized_file_number_1."_".$half_sized_file_number_2.".txt";
	verify_output_file_ok_to_write($combined_files);
	`cat $half_sized_file_1 $half_sized_file_2 > $combined_files`;
}


# deletes half-sized files
for my $half_sized_file_number(1..$file_number)
{
	my $half_sized_file = $file."_".$half_sized_file_number.".txt";
	`rm $half_sized_file`;
}


# if overwriting not allowed (if $OVERWRITE is set to 0), prints an error and exits
sub verify_output_file_ok_to_write
{
	my $output_file = $_[0];
	
	if(-e $output_file)
	{
		print STDERR "Warning: output file already exists. Overwriting:\n\t".$output_file."\n";
		if(!$OVERWRITE)
		{
			print STDERR "Error: exiting to avoid overwriting. Set \$OVERWRITE to 1 to allow "
				."overwriting.\n";
			die;
		}
	}
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
	
	# removes timestamp from date
	# 7/17/21 12:21
	if($date =~ /^(.*)\s+\d+:\d+$/)
	{
		$date = $1;
	}
	
	# if date is already in output format, returns it as is
	if($date =~ /^\d{4}-\d+-\d+$/)
	{
		return $date;
	}
	
	# retrieves day, month, and year from input
	my $year = -1;
	my $month = -1;
	my $day = -1;
	
	if($date =~ /^(\d\d\d\d)[\/-]([a-zA-Z]+)[\/-](\d+)$/) # YYYY/MMM/DD or YYYY-MMM-DD format, with Month written out (e.g., Dec)
	{
		# retrieves date
		$year = $1;
		$month = month_text_to_month_number($2);
		$day = $3;
	}
	elsif($date =~ /^(\d+)[\/-]([a-zA-Z]+)[\/-](\d\d\d\d)$/) # DD/MMM/YYYY or DD-MMM-YYYY format, with Month written out (e.g., Dec)
	{
		# retrieves date
		$year = $3;
		$month = month_text_to_month_number($2);
		$day = $1;
	}
	elsif($date =~ /^(\d+)[\/-]([a-zA-Z]+)[\/-](\d+)$/) # DD/MMM/YY or DD-MMM-YY format, with Month written out (e.g., Dec)
	{
		# retrieves date
		$year = $3;
		$month = month_text_to_month_number($2);
		$day = $1;
	}
	elsif($date =~ /^(\d+)[\/-](\d+)[\/-](\d+)$/) #  M/D/YY or M-D-YY format
	{
		# retrieves date
		$year = $3;
		$month = $1;
		$day = $2;
	}
	else # format not recognized
	{
		print STDERR "Error: date ".$date." not in recognized format.\n";
		return $date;
	}
	
	# prepares output
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
		."YYYY-MM-DD format. Please fix code.\n";
	die;
}


# March 4, 2020
# July 12, 2021
# April 1, 2022
