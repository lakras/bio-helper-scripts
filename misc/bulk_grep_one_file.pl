#!/usr/bin/env perl

# Searches input file for queries. Prints lines containing queries.

# Usage:
# perl bulk_grep_one_file.pl [file to grep] "[query 1]" "[query 2]" "[query 3]" [etc.]

# Prints to console. To print to file, use
# perl bulk_grep_one_file.pl [file to grep] "[query 1]" "[query 2]" "[query 3]" [etc.]
# > [output file path]


use strict;
use warnings;


my $file_to_grep = $ARGV[0];
my @queries = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";


# verifies that input files exist and are not empty
if(!$file_to_grep or !-e $file_to_grep or -z $file_to_grep)
{
	print STDERR "Error: file to grep not provided, does not exist, or is empty:\n\t"
		.$file_to_grep."\nExiting.\n";
	die;
}

# search each line for each query
open FILE_TO_GREP, "<$file_to_grep" || die "Could not open $file_to_grep to read; terminating =(\n";
while(<FILE_TO_GREP>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/)
	{
		my $line_included = 0;
		foreach my $query(@queries)
		{
			if($line =~ /$query/)
			{
				$line_included = 1;
			}
		}
		
		if($line_included)
		{
			print $line;
			print $NEWLINE;
		}
	}
}
close FILE_TO_GREP;


# November 3, 2021
