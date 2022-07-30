#!/usr/bin/env perl

# Modifies start and end positions in bed file from 0-indexed or 1-indexed to 0-indexed
# or 1-indexed and from inclusive end or non-iclusive end to inclusive end or non-iclusive end.

# Usage:
# perl modify_start_end_position_indexing_and_inclusivity.pl [bed file path]
# [1 if input is 1-indexed, 0 if input is 0-indexed]
# [1 if input has inclusive end, 0 if input has non-inclusive end]
# [1 if output should be 1-indexed, 0 if output should be 0-indexed]
# [1 if output should have inclusive end, 0 if output should have non-inclusive end]

# Prints to console. To print to file, use
# perl modify_start_end_position_indexing_and_inclusivity.pl [bed file path]
# [1 if input is 1-indexed, 0 if input is 0-indexed]
# [1 if input has inclusive end, 0 if input has non-inclusive end]
# [1 if output should be 1-indexed, 0 if output should be 0-indexed]
# [1 if output should have inclusive end, 0 if output should have non-inclusive end]
# > [output bed file path]


use strict;
use warnings;


my $bed_file = $ARGV[0]; # tab-separated table with columns: sequence name, first position, end position, optional other columns
my $input_1_indexed = $ARGV[1]; # 1 if input is 1-indexed, 0 if input is 0-indexed
my $input_inclusive_end = $ARGV[2]; # 1 if input has inclusive end, 0 if input has non-inclusive end
my $output_1_indexed = $ARGV[3]; # 1 if output should be 1-indexed, 0 if output should be 0-indexed
my $output_inclusive_end = $ARGV[4]; # 1 if output should have inclusive end, 0 if output should have non-inclusive end


# in input bed file:
my $SEQUENCE_NAME_COLUMN = 0;
my $START_POSITION_COLUMN = 1;
my $END_POSITION_COLUMN = 2;
my $FIRST_COLUMN_OF_REST_OF_LINE = 3;

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
	print STDERR "Error: input file does not exist:\n\t".$bed_file."\nExiting.\n";
	die;
}
if(-z $bed_file)
{
	print STDERR "Error: input file is empty:\n\t".$bed_file."\nExiting.\n";
	die;
}


# reads in primer positions described in bed file; outputs modified positions
open BED_FILE, "<$bed_file" || die "Could not open $bed_file to read; terminating =(\n";
while(<BED_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		# retrieves sequence name and start and end
		my @values = split($DELIMITER, $line);
		my $sequence_name = $values[$SEQUENCE_NAME_COLUMN];
		my $start = $values[$START_POSITION_COLUMN];
		my $end = $values[$END_POSITION_COLUMN];
		my $rest_of_line = join($DELIMITER, @values[$FIRST_COLUMN_OF_REST_OF_LINE...$#values]);
		
		# modifies indexing
		if($input_1_indexed and !$output_1_indexed)
		{
			# input is 1-indexed, output should be 0-indexed
			# subtract 1 from start and end positions
			$start = $start - 1;
			$end = $end - 1;
		}
		elsif(!$input_1_indexed and $output_1_indexed)
		{
			# input is 0-indexed, output should be 1-indexed
			# add 1 to start and end positions
			$start = $start + 1;
			$end = $end + 1;
		}
		
		# modifies inclusive or non-inclusive end
		if($input_inclusive_end and !$output_inclusive_end)
		{
			# input has inclusive end, output has non-inclusive end
			# add 1 to end position
			$end = $end + 1;
		}
		if(!$input_inclusive_end and $output_inclusive_end)
		{
			# input has non-inclusive end, output has inclusive end
			# subtract 1 from end position
			$end = $end - 1;
		}
		
		# prints line
		print STDERR $sequence_name.$DELIMITER;
		print STDERR $start.$DELIMITER;
		print STDERR $end.$DELIMITER;
		print STDERR $rest_of_line.$NEWLINE;
	}
}
close BED_FILE;


# July 30, 2022
