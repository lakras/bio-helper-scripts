#!/usr/bin/env perl

# Selects a certain number of lines at random from input table or list.

# Usage:
# perl select_random_lines.pl [table or list] [number rows or lines to select at random]

# Prints to console. To print to file, use
# perl select_random_lines.pl [table or list] [number rows or lines to select at random]
# > [output table or list]


use strict;
use warnings;


my $input_list = $ARGV[0]; # sequences to choose from; sequence names must be unique
my $number_lines_to_select = $ARGV[1];


my $NEWLINE = "\n";


# verifies that inputs make sense
if($number_lines_to_select < 1)
{
	print STDERR "Error: number lines to select is less than 1. Exiting.\n";
	die;
}
if($number_lines_to_select !~ /^\d+$/)
{
	print STDERR "Error: number lines to select is not a positive integer. Exiting.\n";
	die;
}
if(!$input_list or !-e $input_list)
{
	print STDERR "Error: input table or list does not exist. Exiting.\n";
	die;
}


# counts total number of lines in the input table or list
open INPUT_LIST, "<$input_list" || die "Could not open $input_list to read; terminating =(\n";
my $total_number_lines = 0;
while(<INPUT_LIST>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # non-empty line
	{
		$total_number_lines++;
	}
}
close INPUT_LIST;


# calculates proportion of lines to select
if($number_lines_to_select >= $total_number_lines)
{
	print STDERR "Error: number lines to select is not less than total number of "
		."lines. Exiting.\n";
	die;
}
my $proportion_lines_to_select = $number_lines_to_select / $total_number_lines;


# selects and prints lines
my $number_lines_selected = 0;
my %line_printed = ();
while($number_lines_selected < $number_lines_to_select)
{
	open INPUT_LIST, "<$input_list" || die "Could not open $input_list to read; terminating =(\n";
	while(<INPUT_LIST>) # for each row in the file
	{
		chomp;
		if($_ =~ /\S/) # non-empty line
		{
			my $line = $_;
			my $random_value = rand(1);
			if($random_value < $proportion_lines_to_select
				and $number_lines_selected < $number_lines_to_select
				and !$line_printed{$line})
			{
				print $line.$NEWLINE;
				$line_printed{$line} = 1;
				$number_lines_selected++;
			}
		}
	}
	close INPUT_LIST;
}


# September 2, 2020
# January 17, 2022
# October 24, 2023
