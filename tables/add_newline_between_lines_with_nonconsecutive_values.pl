#!/usr/bin/env perl

# Adds newline between lines containing non-consecutive values in first column.

# Usage:
# perl add_newline_between_lines_with_nonconsecutive_values.pl [table]
# [column with integer values]

# Prints to console. To print to file, use
# perl add_newline_between_lines_with_nonconsecutive_values.pl [table]
# [column with integer values] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $column = $ARGV[1]; # column containing integer values, 0-indexed

my $NEWLINE = "\n";
my $DELIMITER = "\t";


my $previous_value = -1;
my $first_line = 1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		# prints extra newline if first column value is not the previous one +1
		my @items_in_line = split($DELIMITER, $line, -1);
		my $value = "";
		if(scalar @items_in_line > $column)
		{
			$value = $items_in_line[$column];
			if(!$first_line and $value != $previous_value + 1)
			{
				print $NEWLINE;
			}
		}
		
		$first_line = 0;
		$previous_value = $value;
	}
	
	# prints this line
	print $line.$NEWLINE;
}
close TABLE;


# February 21, 2022