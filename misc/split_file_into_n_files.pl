#!/usr/bin/env perl

# Splits file with multiple lines up into a number of smaller files, each with about the
# same number of lines.

# Usage:
# perl split_file_into_n_files.pl [file path] [number output files to generate]

# New files are created at filepath of old file with "_1_of_[n].txt", "_2_of_[n].txt",
# etc. appended to the end. Files already at those paths will be overwritten.


use strict;
use warnings;


my $file = $ARGV[0];
my $number_files = $ARGV[1];


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
if(!$number_files or $number_files < 2)
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
my $number_lines_per_file = $number_lines/$number_files;
if($number_lines_per_file * $number_files < $number_lines)
{
	$number_lines_per_file++;
}


# prepares to read in input file and generate first output file
my $number_lines_read_in = 0; # number lines read in from input file
my $file_number = 1; # file number of current output file (appears at the end of the output file path)
my $output_file = $file."_".$file_number."_of_".$number_files.".txt"; # current output file we are printing to
if(-e $output_file)
{
	print STDERR "Warning: output file already exists. Overwriting:\n\t".$output_file."\n";
}


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
		$output_file = $file."_".$file_number."_of_".$number_files.".txt";
		if(-e $output_file)
		{
			print STDERR "Warning: output file already exists. Overwriting:\n\t".$output_file."\n";
		}
		open OUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";
	}
	
	# prints this line
	print OUT_FILE $_."\n";
	$number_lines_read_in++;
}
close FILE;
close OUT_FILE;


# March 4, 2020
# July 12, 2021
