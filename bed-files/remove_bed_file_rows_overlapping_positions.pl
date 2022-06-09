#!/usr/bin/env perl

# Removes rows in bed file that overlap with parameter positions.

# Usage:
# perl remove_bed_file_rows_overlapping_positions.pl [bed file path]
# [position (0-indexed); any rows overlapping this position will be removed]
# [another position] [another position] [etc.]

# Prints to console. To print to file, use
# perl remove_bed_file_rows_overlapping_positions.pl [bed file path]
# [position (0-indexed); any rows overlapping this position will be removed]
# [another position] [another position] [etc.] > [output bed file path]


use strict;
use warnings;


my $bed_file = $ARGV[0]; # tab-separated table with columns: sequence name, first position (0-indexed), non-inclusive end position (0-indexed)
my @positions_to_remove_overlaps_with = @ARGV[1..$#ARGV]; # 1-indexed


# in bed file:
my $START_POSITION_COLUMN = 1;
my $END_POSITION_COLUMN = 2;

my $DELIMITER = "\t";
my $NEWLINE = "\n";


# verifies that input bed file exists and is non-empty
if(!$bed_file)
{
	print STDERR "Error: no input bed file provided. Exiting.\n";
	die;
}
if(!-e $bed_file)
{
	print STDERR "Error: input bed file does not exist:\n\t".$bed_file."\nExiting.\n";
	die;
}
if(-z $bed_file)
{
	print STDERR "Error: input bed file is empty:\n\t".$bed_file."\nExiting.\n";
	die;
}

# verifies that we have positions to remove overlaps with
if(!scalar @positions_to_remove_overlaps_with)
{
	print STDERR "Error: no positions to remove provided. Exiting.\n";
	die;
}


# reads in positions described in bed file
# prints rows that do not overlap with any positions to remove overlaps with
open BED_FILE, "<$bed_file" || die "Could not open $bed_file to read; terminating =(\n";
while(<BED_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		# retrieves start and end
		my @values = split($DELIMITER, $line);
		my $start = $values[$START_POSITION_COLUMN]; # first position (0-indexed)
		my $end = $values[$END_POSITION_COLUMN]; # non-inclusive end position (0-indexed)
		
		# determines whether or not this row should be printer
		my $overlap_found = 0;
		foreach my $position(@positions_to_remove_overlaps_with) # 0-indexed
		{
			if($position >= $start and $position < $end)
			{
				$overlap_found = 1;
			}
		}
		
		# prints row if it should be printed
		if(!$overlap_found)
		{
			print $line;
			print $NEWLINE;
		}
	}
}
close BED_FILE;


# June 9, 2022
