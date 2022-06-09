#!/usr/bin/env perl

# Takes in a bed file of amplicons and outputs a bed file of positions not covered by
# those amplicons. Assumes all amplicons come from only one reference sequence.

# I do this in a really dumb way but hey it's not too slow and it works!


# Usage:
# perl determine_regions_not_covered_by_amplicons.pl [amplicons bed file path]

# Prints to console. To print to file, use
# perl determine_regions_not_covered_by_amplicons.pl [amplicons bed file path]
# > [output bed file path]


use strict;
use warnings;


my $amplicons_bed_file = $ARGV[0]; # tab-separated table with columns: sequence name, first position (0-indexed), non-inclusive end position (0-indexed)


# in bed file:
my $SEQUENCE_NAME_COLUMN = 0;
my $START_POSITION_COLUMN = 1;
my $END_POSITION_COLUMN = 2;

my $DELIMITER = "\t";
my $NEWLINE = "\n";


# verifies that input bed file exists and is non-empty
if(!$amplicons_bed_file)
{
	print STDERR "Error: no input bed file provided. Exiting.\n";
	die;
}
if(!-e $amplicons_bed_file)
{
	print STDERR "Error: input bed file does not exist:\n\t".$amplicons_bed_file."\nExiting.\n";
	die;
}
if(-z $amplicons_bed_file)
{
	print STDERR "Error: input bed file is empty:\n\t".$amplicons_bed_file."\nExiting.\n";
	die;
}


# reads in amplicons bed file and marks covered positions
my $greatest_position = 0;
my $sequence_name = "";
my @position_covered_by_amplicons = (); # key: position (0-indexed) -> value: 1 if covered by one of the amplicons
open BED_FILE, "<$amplicons_bed_file" || die "Could not open $amplicons_bed_file to read; terminating =(\n";
while(<BED_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		# retrieves start and end
		my @values = split($DELIMITER, $line);
		$sequence_name = $values[$SEQUENCE_NAME_COLUMN];
		my $start = $values[$START_POSITION_COLUMN]; # first position (0-indexed)
		my $end = $values[$END_POSITION_COLUMN]; # non-inclusive end position (0-indexed)
		
		# markes positions covered by amplicon
		for(my $position = $start; $position < $end; $position++)
		{
			$position_covered_by_amplicons[$position] = 1;
		}
		
		# updates greatest position in bed file
		if($end - 1 > $greatest_position)
		{
			$greatest_position = $end - 1;
		}
	}
}
close BED_FILE;


# iterates over positions and prints ranges of positions not covered
my $current_range_covered = 1;
for(my $position = 0; $position <= $greatest_position; $position++)
{
	if($position_covered_by_amplicons[$position]) # position covered
	{
		if(!$current_range_covered) # previous position was not covered
		{
			# close out this not-covered range
			print $position;
			print $NEWLINE;
			
			$current_range_covered = 1;
		}
	}
	else # position not covered
	{
		if($current_range_covered) # previous position was covered
		{
			# open new not-covered range
			print $sequence_name;
			print $DELIMITER;
			print $position;
			print $DELIMITER;
			
			$current_range_covered = 0;
		}
	}
}


# June 9, 2022
