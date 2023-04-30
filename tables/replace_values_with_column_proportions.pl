#!/usr/bin/env perl

# Calculates sum of each column containing numerical values. Replaces values in column
# with the proportion of its sum.

# Usage:
# perl replace_values_with_column_proportions.pl [tab-separated table]

# Prints to console. To print to file, use
# perl replace_values_with_column_proportions.pl [tab-separated table] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# reads in table and calculates sum of each column
my %column_is_not_numerical = (); # key: column number (0-indexed) -> value: 1 if column does not contain only numerical values
my %column_sum = (); # key: column number (0-indexed) -> value: sum of values in column
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
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				# checks if value is numerical
				if($value =~ /^[\d.-]+$/)
				{
					# column is numerical
					# adds value to column sum
					if(!$column_sum{$column})
					{
						$column_sum{$column} = 0;
					}
					$column_sum{$column} = $column_sum{$column} + $value;
				}
				else
				{
					# column is not numerical
					$column_is_not_numerical{$column} = 1;
				}
				$column++;
			}
		}
	}
}
close TABLE;

# reads in table and replaces each numerical column value with proportion
$first_line = 1;
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
			$first_line = 0; # next line is not column titles
			
			# prints column titles line as is
			print $line.$NEWLINE;
		}
		else # column values (not column titles)
		{
			my $column = 0;
			foreach my $value(@items_in_line)
			{
				if($column > 0)
				{
					print $DELIMITER;
				}
				if($column_is_not_numerical{$column})
				{
					# column is not numerical--print value as is
					print $value;
				}
				else # column is numerical
				{
					# column is numerical--print proportion
					if($column_sum{$column})
					{
						my $proportion = $value / $column_sum{$column};
						print $proportion;
					}
					else
					{
						print "0";
					}
				}
				$column++;
			}
			print $NEWLINE;
		}
	}
}
close TABLE;


# April 29, 2023
