#!/usr/bin/env perl

# Takes in one bed file and at least one other bed file to compare it to. Outputs
# proportion of the sequence in the regions described in the first bed file that is
# captured in the regions described in each additional bed file. Outputs each bed file
# path and the proportion it covers of the first bed file.

# Assumes all rows come from only one reference sequence.

# I do this in a really dumb way but hey it's not too slow and it works!


# Usage:
# perl calculate_proportions_bed_file_covered_by_other_bed_files.pl [bed file path]
# [other bed file path] [another bed file path] [and another] [etc.]

# Prints to console. To print to file, use
# perl calculate_proportions_bed_file_covered_by_other_bed_files.pl [bed file path]
# [other bed file path] [another bed file path] [and another] [etc.] > [output file path]


use strict;
use warnings;


my $bed_file = $ARGV[0]; # tab-separated table with columns: sequence name, first position (0-indexed), non-inclusive end position (0-indexed)
my @other_bed_files = @ARGV[1..$#ARGV];


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

# verifies that we have other bed files
if(!scalar @other_bed_files)
{
	print STDERR "Error: no additional bed files provided. Exiting.\n";
	die;
}


# reads in bed file and marks covered positions
my %position_covered_by_first_bed_file = (); # key: position (0-indexed) -> value: 1 if covered by one of the amplicons
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
		
		# markes positions covered by amplicon
		for(my $position = $start; $position < $end; $position++)
		{
			$position_covered_by_first_bed_file{$position} = 1;
		}
	}
}
close BED_FILE;


# reads in each additional bed file, marks covered positions, and calculates proportion
# of positions in first bed file that are covered by this bed file
foreach my $other_bed_file(@other_bed_files)
{
	# reads in bed file and marks covered positions
	my %position_covered_by_other_bed_file = (); # key: position (0-indexed) -> value: 1 if covered by one of the amplicons
	open BED_FILE, "<$other_bed_file" || die "Could not open $other_bed_file to read; terminating =(\n";
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
		
			# markes positions covered by amplicon
			for(my $position = $start; $position < $end; $position++)
			{
				$position_covered_by_other_bed_file{$position} = 1;
			}
		}
	}
	close BED_FILE;
	
	# for each position covered by first bed file, checks if it is covered by this other 
	# bed file
	my $total_number_positions_covered_by_first_bed_file = 0;
	my $number_positions_covered_by_both_bed_files = 0;
	foreach my $position(keys %position_covered_by_first_bed_file)
	{
		$total_number_positions_covered_by_first_bed_file++;
		if($position_covered_by_other_bed_file{$position})
		{
			$number_positions_covered_by_both_bed_files++;
		}
	}
	
	# calculates proportion positions covered
	my $proportion_positions_covered = $number_positions_covered_by_both_bed_files / $total_number_positions_covered_by_first_bed_file;
	my $fraction_positions_covered = $number_positions_covered_by_both_bed_files."/".$total_number_positions_covered_by_first_bed_file;
	my $percent_positions_covered = sprintf("%.1f", 100 * $proportion_positions_covered)."%";
	
	# retrieves filename of other bed file
	my $other_bed_file_filename = $other_bed_file;
	if($other_bed_file_filename =~ /\/([^\/]*)$/)
	{
		$other_bed_file_filename = $1;
	}
	
	# prints proportion positions covered
	print $other_bed_file_filename;
	print $DELIMITER;
	print $percent_positions_covered;
	print $DELIMITER;
	print $proportion_positions_covered;
	print $DELIMITER;
	print $fraction_positions_covered;
	print $NEWLINE;
}


# June 9, 2022
