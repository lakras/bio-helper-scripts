#!/usr/bin/env perl

# Splits file with multiple lines up into a number of overlapping smaller files. Each line
# will appear in two files. Either all output files will have about the same number of
# lines, or there will be two "jagged" half-sized output files if it is a priority for all
# output files to only have lines that are consecutive in the input.

# Example of a 15-line input with 3 slices and 3*2 = 6 approximately equal-sized output
# files (equal_sized_outputs == 1):
# line 1	output file 1	output file 4
# line 2	output file 1	output file 4
# line 3	output file 1	output file 4
# line 4	output file 1	output file 5
# line 5	output file 1	output file 5
# line 6	output file 2	output file 5
# line 7	output file 2	output file 5
# line 8	output file 2	output file 5
# line 9	output file 2	output file 6
# line 10	output file 2	output file 6
# line 11	output file 3	output file 6
# line 12	output file 3	output file 6
# line 13	output file 3	output file 6
# line 14	output file 3	output file 4
# line 15	output file 3	output file 4

# Outputs:
# _1_of_6.txt: lines 1-5
# _2_of_6.txt: lines 6-10
# _3_of_6.txt: lines 11-15
# _4_of_6.txt: lines 1-3, lines 14-15
# _5_of_6.txt: lines 4-8
# _6_of_6.txt: lines 9-13

# Example of a 15-line input with 3 slices and 2*3+1 output files with lines that are
# also consecutive in the input (equal_sized_outputs == 0):
# line 1	output file 1	output file 4
# line 2	output file 1	output file 4
# line 3	output file 1	output file 5
# line 4	output file 1	output file 5
# line 5	output file 1	output file 5
# line 6	output file 2	output file 5
# line 7	output file 2	output file 5
# line 8	output file 2	output file 6
# line 9	output file 2	output file 6
# line 10	output file 2	output file 6
# line 11	output file 3	output file 6
# line 12	output file 3	output file 6
# line 13	output file 3	output file 7
# line 14	output file 3	output file 7
# line 15	output file 3	output file 7

# Outputs:
# _1_of_7.txt: lines 1-5
# _2_of_7.txt: lines 6-10
# _3_of_7.txt: lines 11-15
# _4_of_7.txt: lines 1-3
# _5_of_7.txt: lines 4-8
# _6_of_7.txt: lines 9-13
# _7_of_7.txt: lines 14-15

# Usage:
# perl split_file_into_2n_overlapping_files.pl [file path] [number equal slices (n)]
# [1 to generate N=2*n approximately equal sized files, 0 to generate N=2*n+1 output files with lines that are also consecutive in the input]

# New files are created at filepath of old file with "_1_of_[N].txt", "_2_of_[N].txt",
# etc. appended to the end. Files already at those paths will be overwritten.


use strict;
use warnings;


my $file = $ARGV[0];
my $number_slices = $ARGV[1];
my $equal_sized_outputs = $ARGV[2]; # 1 to generate 2*n approximately equal sized files, 0 to generate 2*n+1 output files with lines that are also consecutive in the input


my $OVERWRITE = 1; # set to 0 to prevent overwriting (stop script rather than overwrite)


# verifies that input file exists and is not empty
if(!$file)
{
	print STDERR "Error: no input file provided. Exiting.\n";
	die;
}
if(!-e $file)
{
	print STDERR "Error: input file does not exist:\n\t".$file."\nExiting.\n";
	die;
}
if(-z $file)
{
	print STDERR "Error: input file is empty:\n\t".$file."\nExiting.\n";
	die;
}

# sanity check number files
if(!$number_slices or $number_slices < 2)
{
	print STDERR "Fewer than 2 output files requested. My services are not needed here.\n";
	die;
}


# count lines in file
my $number_lines = 0; # number lines read in from input file
open FILE, "<$file" || die "Could not open $file to read; terminating =(\n";
while(<FILE>) # for each line in the file
{
	chomp;
	$number_lines++;
}
close FILE;


# calculates number lines per file
my $number_lines_per_file = $number_lines/$number_slices;
if($number_lines_per_file * $number_slices < $number_lines)
{
	$number_lines_per_file++;
}


# calculates how many output files will be generated
my $total_number_files;
if($equal_sized_outputs)
{
	$total_number_files = $number_slices * 2;
}
else
{
	$total_number_files = $number_slices * 2 + 1;
}


# prepares to read in input file and generate first output file
my $number_lines_read_in = 0; # number lines read in from input file
my $file_number = 1; # file number of current output file (appears at the end of the output file path)
my $output_file = $file."_".$file_number."_of_".$total_number_files.".txt"; # current output file we are printing to
verify_output_file_ok_to_write($output_file);


# splits file into smaller files
open OUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";
open FILE, "<$file" || die "Could not open $file to read; terminating =(\n";
while(<FILE>) # for each line in the file
{
	chomp;
	
	# opens new output file if necessary
	if($number_lines_read_in >= $number_lines_per_file)
	{
		close OUT_FILE;
		$file_number++;
		$number_lines_read_in = 0;
		$output_file = $file."_".$file_number."_of_".$total_number_files.".txt";
		verify_output_file_ok_to_write($output_file);
		open OUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";
	}
	
	# prints this line
	print OUT_FILE $_."\n";
	$number_lines_read_in++;
}
close FILE;
close OUT_FILE;


# prepares to generate next output file
$file_number++;
$number_lines_read_in = 0; # number lines read in from input file
$output_file = $file."_".$file_number."_of_".$total_number_files.".txt"; # current output file we are printing to
verify_output_file_ok_to_write($output_file);


# splits file into smaller files again, shifted to overlap with the first set of output files
my $printing_jagged_first_file = 1; # printing in half-sized, "jagged" first file
my $jagged_first_file_file_number = $file_number;
open OUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";
open FILE, "<$file" || die "Could not open $file to read; terminating =(\n";
while(<FILE>) # for each line in the file
{
	chomp;
	
	# opens new output file if necessary
	if($number_lines_read_in >= $number_lines_per_file
		or $printing_jagged_first_file and $number_lines_read_in >= $number_lines_per_file/2)
	{
		close OUT_FILE;
		$printing_jagged_first_file = 0;
		$file_number++;
		$number_lines_read_in = 0;
		
		# if this is the last file and we are printing all approximately equal-sized output files,
		# open jagged first file back up
		if($equal_sized_outputs and $file_number > $total_number_files)
		{
			$output_file = $file."_".$jagged_first_file_file_number."_of_".$total_number_files.".txt";
			open OUT_FILE, ">>$output_file" || die "Could not open $output_file to append; terminating =(\n";
		}
		else
		{
			$output_file = $file."_".$file_number."_of_".$total_number_files.".txt";
			verify_output_file_ok_to_write($output_file);
			open OUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";
		}
	}
	
	# prints this line
	print OUT_FILE $_."\n";
	$number_lines_read_in++;
}
close FILE;
close OUT_FILE;


# if overwriting not allowed (if $OVERWRITE is set to 0), prints an error and exits
sub verify_output_file_ok_to_write
{
	my $output_file = $_[0];
	
	if(-e $output_file)
	{
		print STDERR "Warning: output file already exists. Overwriting:\n\t".$output_file."\n";
		if(!$OVERWRITE)
		{
			print STDERR "Error: exiting to avoid overwriting. Set \$OVERWRITE to 1 to allow "
				."overwriting.\n";
			die;
		}
	}
}


# March 4, 2020
# July 12, 2021
# April 1, 2022
