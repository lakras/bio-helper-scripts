#!/usr/bin/env perl

# Combines input files. Prints each line only once (no duplicate lines). Prints lines in
# order in which they first appear in all the input files.

# Usage:
# perl combine_files_and_delete_duplicate_lines.pl [input file] [another input file]
# [another input file] [etc.]

# Prints to console. To print to file, use
# perl combine_files_and_delete_duplicate_lines.pl [input file] [another input file]
# [another input file] [etc.] > [output table path]


use strict;
use warnings;


my @files_to_combine = @ARGV;


my $NEWLINE = "\n";


# verifies that input files exist
if(!scalar @files_to_combine)
{
	print STDERR "Error: no input files provided. Exiting.\n";
	die;
}

# reads in input files
my %line_to_first_appearance_line_number = (); # key: line read in -> value: line number of first appearance of this line across all files
my $overall_line_number = 1; # line number across all files
foreach my $file(@files_to_combine)
{
	open FILE, "<$file" || die "Could not open $file to read; terminating =(\n";
	while(<FILE>) # for each line in the file
	{
		chomp;
		my $line = $_;
		if($line =~ /\S/) # non-empty line
		{
			if(!$line_to_first_appearance_line_number{$line})
			{
				$line_to_first_appearance_line_number{$line} = $overall_line_number;
			}
		}
		$overall_line_number++;
	}
	close FILE;
}


# prints output lines in order in which they first appear in the files
foreach my $line(
	sort {$line_to_first_appearance_line_number{$a} <=> $line_to_first_appearance_line_number{$b}}
	keys %line_to_first_appearance_line_number)
{
	print $line.$NEWLINE;
}


# April 1, 2022