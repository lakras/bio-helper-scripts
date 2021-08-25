#!/usr/bin/env perl

# Converts dates in specified columns to YYYY-MM-DD format. Multiple dates may be
# separated by a ", ". Column titles must not have spaces.

# Usage:
# perl dates_in_columns_to_YYYY_MM_DD.pl [table] [title of column with dates]
# [title of another column with dates] [title of another column with dates] [etc.]

# Prints to console. To print to file, use
# perl dates_in_columns_to_YYYY_MM_DD.pl [table] [title of column with dates]
# [title of another column with dates] [title of another column with dates] [etc.] > [output table path]


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
						push(@YYYY_MM_DD_dates, date_to_YYYY_MM_DD($sub_value))
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
	print STDERR "Error: date ".$date." not in recognized format while converting format "
		."in column(s) ".join(", ", @titles_of_columns_with_dates)." in table:\n\t".$table
		."\nPlease fix input or code. Exiting.\n";
	die;
}


# August 24, 2021
