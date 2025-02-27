#!/usr/bin/env perl

# Converts dates in specified columns to YYYY-MM-DD format. Multiple dates may be
# separated by a ", ". Column titles must not have spaces.

# Usage:
# perl dates_in_columns_to_YYYY_MM_DD.pl [table] "[title of column with dates]"
# "[title of another column with dates]" "[title of another column with dates]" [etc.]

# Prints to console. To print to file, use
# perl dates_in_columns_to_YYYY_MM_DD.pl [table] "[title of column with dates]"
# "[title of another column with dates]" "[title of another column with dates]" [etc.]
# > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my @titles_of_columns_with_dates = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $DATE_LIST_DELIMITER = ", ";


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


# converts array of column titles to a hash
my %title_is_of_column_with_dates = (); # key: column title -> value: 1 if column has dates
my %column_title_to_column = (); # key: included column title -> value: column
foreach my $column_title(@titles_of_columns_with_dates)
{
	$title_is_of_column_with_dates{$column_title} = 1;
	$column_title_to_column{$column_title} = -1;
}


# reads in and processes input table
my $first_line = 1;
my %column_has_dates = (); # key: column (0-indexed) -> value: 1 if column has dates
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
			# identifies columns to include
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $title_is_of_column_with_dates{$column_title})
				{
					$column_has_dates{$column} = 1;
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
			
			# print header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# prints all values, converting dates to YYYY-MM-DD format
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# prints delimiter
				if($column > 0)
				{
					print $DELIMITER;
				}
				
				# if this is a column with dates, converts to YYYY-MM-DD format
				if($column_has_dates{$column})
				{
					my @YYYY_MM_DD_dates = ();
					foreach my $sub_value(split($DATE_LIST_DELIMITER, $value))
					{
						my $processed_date = date_to_YYYY_MM_DD($sub_value);
						if(defined $processed_date and length $processed_date
							and $processed_date =~ /\S/)
						{
							push(@YYYY_MM_DD_dates, $processed_date);
						}
					}
					$value = join($DATE_LIST_DELIMITER, @YYYY_MM_DD_dates);
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
	if($date =~ /^[\dX]{4}-[\dX]{2}-[\dX]{2}$/)
	{
		return $date;
	}
	
	# retrieves day, month, and year from input
	my $year = -1;
	my $month = -1;
	my $day = -1;
	
	if($date =~ /^([\dX]{4})[\/-]([a-zA-Z]+)[\/-]([\dX]+)$/) # YYYY/MMM/DD or YYYY-MMM-DD format, with Month written out (e.g., Dec)
	{
		# retrieves date
		$year = $1;
		$month = month_text_to_month_number($2);
		$day = $3;
	}
	elsif($date =~ /^([\dX]+)[\/-]([a-zA-Z]+)[\/-]([\dX]{4})$/) # DD/MMM/YYYY or DD-MMM-YYYY format, with Month written out (e.g., Dec)
	{
		# retrieves date
		$year = $3;
		$month = month_text_to_month_number($2);
		$day = $1;
	}
	elsif($date =~ /^([\dX]+)[\/-]([a-zA-Z]+)[\/-]([\dX]+)$/) # DD/MMM/YY or DD-MMM-YY format, with Month written out (e.g., Dec)
	{
		# retrieves date
		$year = $3;
		$month = month_text_to_month_number($2);
		$day = $1;
	}
	elsif($date =~ /^([a-zA-Z]+)-([\dX]+)$/) # MMM-YY format, with Month written out (e.g., Dec)
	{
		# retrieves date
		$year = $2;
		$month = month_text_to_month_number($1);
		$day = "XX";
	}
	elsif($date =~ /^([\dX]+)[\/-]([\dX]+)[\/-]([\dX]+)$/) #  M/D/YY or M-D-YY format
	{
		# retrieves date
		$year = $3;
		$month = $1;
		$day = $2;
	}
	elsif($date =~ /^([\dX]+)-([\dX]+)$/) #  YYYY-MM format
	{
		# retrieves date
		$year = $1;
		$month = $2;
		$day = "XX";
	}
	elsif($date =~ /^([\dX]+)$/) #  YYYY format
	{
		# retrieves date
		$year = $1;
		$month = "XX";
		$day = "XX";
	}
	else # format not recognized
	{
		print STDERR "Error: date ".$date." not in recognized format while converting format "
			."in column(s) ".join(", ", @titles_of_columns_with_dates)." in table:\n\t"
			.$table."\n";
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
	if($output =~ /^[\dX]{4}-[\dX]{2}-[\dX]{2}$/)
	{
		return $output;
	}
	print STDERR "Error: result ".$output." of reformatting date ".$date." not in "
		."YYYY-MM-DD format. Please fix code.\n";
	die;
}

# example input: Dec
# example input: December
# example output: 12
sub month_text_to_month_number
{
	my $month_text = $_[0];
	if($month_text =~ /Jan/)
	{
		return 1;
	}
	if($month_text =~ /Feb/)
	{
		return 2;
	}
	if($month_text =~ /Mar/)
	{
		return 3;
	}
	if($month_text =~ /Apr/)
	{
		return 4;
	}
	if($month_text =~ /May/)
	{
		return 5;
	}
	if($month_text =~ /Jun/)
	{
		return 6;
	}
	if($month_text =~ /Jul/)
	{
		return 7;
	}
	if($month_text =~ /Aug/)
	{
		return 8;
	}
	if($month_text =~ /Sep/)
	{
		return 9;
	}
	if($month_text =~ /Oct/)
	{
		return 10;
	}
	if($month_text =~ /Nov/)
	{
		return 11;
	}
	if($month_text =~ /Dec/)
	{
		return 12;
	}
	print STDERR "Error: month ".$month_text." not recognized.\n";
	return $month_text;
}


# August 24, 2021
# January 30, 2022
