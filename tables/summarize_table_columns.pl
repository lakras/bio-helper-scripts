#!/usr/bin/env perl

# Summarizes values in table columns. Similar to str in R.

# Usage:
# perl summarize_table_columns.pl [tab-separated table]

# Prints to console. To print to file, use
# perl summarize_table_columns.pl [tab-separated table] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];


my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in replacement map file
my @NO_DATA = ("NA", "N/A", "Undetermined", "-");


my $MINIMUM_NUMBER_OF_VALUES_TO_NOT_SUMMARIZE_NUMERICAL_COLUMN = 5;
my $MAXIMUM_NUMBER_OF_COLUMN_VALUES_TO_PRINT = 20;


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}

# read in input table
my $first_line = 1;
my @column_titles = (); # key: column number -> value: column title
my %column_to_values_counts = (); # key: column number -> key: column value -> value: count
my $number_rows = 0;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my $line = $_;
		my @items_in_line = split($DELIMITER, $line, -1);
	
		if($first_line) # column titles
		{
			# saves column titles
			@column_titles = @items_in_line;
		
			# next line is not column titles
			$first_line = 0;
		}
		else # column values
		{
			# saves all column values
			my $column = 0;
			foreach my $column_value(@items_in_line)
			{
				$column_to_values_counts{$column}{$column_value}++;
				$column++;
			}
			$number_rows++;
		}
	}
}
close TABLE;

# prints number of rows and number of columns
my $number_columns = scalar @column_titles;

print "\n";
print $number_columns." columns\n";
print $number_rows." rows\n";
print "\n";

# converts no data values array to hash
my %is_no_data = (); # key: value that means "no data" -> value: 1
foreach my $no_data_value(@NO_DATA)
{
	$is_no_data{$no_data_value} = 1;
}

# determines which columns are numerical with many values(and we shouldn't print all values)
my %column_is_numerical_with_many_values = (); # key: column number -> value: 1 if numerical values should not be catalogued
my %column_is_dates = (); # key: column number -> value: 1 if contains dates
my %column_is_has_too_many_values = (); # key: column number -> value: 1 if too many values should not be catalogued
my $column = 0;
foreach my $column_title(@column_titles)
{
	# counts number of numerical values and date and other
	my $numerical_values = 0;
	my $date_values = 0;
	my $other_values = 0;
	for my $column_value(keys %{$column_to_values_counts{$column}})
	{
		if($column_value and !$is_no_data{$column_value})
		{
			if(is_date($column_value))
			{
				$date_values++;
			}
			elsif(is_number($column_value))
			{
				$numerical_values++;
			}
			else
			{
				$other_values++;
			}
		}
	}
	
	# marks column as numerical if it has enough numerical values
	if($numerical_values >= $MINIMUM_NUMBER_OF_VALUES_TO_NOT_SUMMARIZE_NUMERICAL_COLUMN
		and $other_values == 0)
	{
		$column_is_numerical_with_many_values{$column} = 1;
	}
	
	# marks column as containing dates
	if($date_values > 0)
	{
		$column_is_dates{$column} = 1;
	}
	
	# marks column as having too many values
	if($numerical_values + $date_values + $other_values > $MAXIMUM_NUMBER_OF_COLUMN_VALUES_TO_PRINT)
	{
		$column_is_has_too_many_values{$column} = 1;
	}
	$column++;
}

# prints information on each column
$column = 0;
foreach my $column_title(@column_titles)
{
	# prints column number and title
	print "column ".$column.", ".$column_title.":\n";
	
	if($column_is_dates{$column}) # dates
	{
		# prints date values
		print "\t"."date values"."\n";
	}
	elsif($column_is_numerical_with_many_values{$column}) # numerical column
	{
		# for a numerical column, prints range and no-data counts
		# calculates range
		my $minimum_value = $NO_DATA[0];
		my $maximum_value = $NO_DATA[0];
		
		for my $column_value(sort {$column_to_values_counts{$column}{$b} <=> $column_to_values_counts{$column}{$a}}
			keys %{$column_to_values_counts{$column}})
		{
			if($column_value and !$is_no_data{$column_value} and is_number($column_value))
			{
				if($is_no_data{$minimum_value} or $column_value < $minimum_value)
				{
					$minimum_value = $column_value;
				}
				if($is_no_data{$maximum_value} or $column_value > $maximum_value)
				{
					$maximum_value = $column_value;
				}
			}
		}
		
		# prints range
		print "\t"."minimum value:"."\t".$minimum_value."\n";
		print "\t"."maximum value:"."\t".$maximum_value."\n";
	}
	elsif($column_is_has_too_many_values{$column}) # too many values
	{
		# prints too many values to print
		print "\t"."too many values to print"."\n";
	}
	else # non-numerical column with not too many values
	{
		# prints all column values and their counts
		for my $column_value(sort {$column_to_values_counts{$column}{$b} <=> $column_to_values_counts{$column}{$a}}
			keys %{$column_to_values_counts{$column}})
		{
			if($column_value and !$is_no_data{$column_value})
			{
				my $column_value_count = $column_to_values_counts{$column}{$column_value};
				print "\t".$column_value_count."\t".$column_value."\n";
			}
		}
	}
	
	# prints no data value counts
	foreach my $no_data_value(@NO_DATA)
	{
		if($column_to_values_counts{$column}{$no_data_value})
		{
			print "\t".$column_to_values_counts{$column}{$no_data_value}."\t".$no_data_value."\n";
		}
	}
	
	# prints empty value count
	if($column_to_values_counts{$column}{""})
	{
		print "\t".$column_to_values_counts{$column}{""}."\t"."empty or 0"."\n";
	}
		
	$column++;
}

sub is_number
{
	my $value = $_[0];
	if(is_date($value))
	{
		return 0;
	}
	if($value =~ /^[-]?[\d]+$/ or $value =~ /^[-]?[\d]+[.][\d]+$/)
	{
		return 1;
	}
	return 0;
}

sub is_date
{
	my $value = $_[0];
	if($value =~ /^\d+\/\d+\/\d+$/)
	{
		return 1;
	}
	if($value =~ /^\d+[-]\d+[-]\d+$/)
	{
		return 1;
	}
	return 0;
}

# August 14, 2021
