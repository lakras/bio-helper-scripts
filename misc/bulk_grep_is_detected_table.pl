#!/usr/bin/env perl

# Searches all input files for queries listed in query list file. Outputs a table with
# detection of all queries in all files, tab-separated, one row per query, one column per file.

# Usage:
# perl bulk_grep_is_detected_table.pl [file listing queries, one per line] [file to grep]
# [another file to grep] [etc.]

# Prints to console. To print to file, use
# perl bulk_grep_is_detected_table.pl [file listing queries, one per line] [file to grep]
# [another file to grep] [etc.] > [output file path]


use strict;
use warnings;


my $query_list_file = $ARGV[0];
my @files_to_grep = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


my $PRINT_FULL_FILEPATH = 0; # if 1, prints full file path; if 0, prints filename only


# verifies that input files exist and is not empty
if(!$query_list_file or !-e $query_list_file or -z $query_list_file)
{
	print STDERR "Error: query list file not provided, does not exist, or empty:\n\t"
		.$query_list_file."\nExiting.\n";
	die;
}
foreach my $file_to_grep(@files_to_grep)
{
	if(!$file_to_grep or !-e $file_to_grep or -z $file_to_grep)
	{
		print STDERR "Error: file to grep not provided, does not exist, or empty:\n\t"
			.$file_to_grep."\nExiting.\n";
		die;
	}
}


# prints header line
print "query";
foreach my $file_to_grep(@files_to_grep)
{
	print $DELIMITER;
	if($PRINT_FULL_FILEPATH)
	{
		print $file_to_grep;
	}
	else
	{
		print filename($file_to_grep);
	}
}
print $NEWLINE;


# read in query list and grep each query
open QUERY_LIST, "<$query_list_file" || die "Could not open $query_list_file to read; terminating =(\n";
while(<QUERY_LIST>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		# prints query
		print $_;
		
		# prints detection in each file
		foreach my $file_to_grep(@files_to_grep)
		{
			print $DELIMITER;
			if(`grep "$_" $file_to_grep`)
			{
				print "detected";
			}
		}
		print $NEWLINE;
	}
}
close QUERY_LIST;


# example input:  /Users/lakras/my_file.txt
# example output: my_file.txt
sub filename
{
	my $filepath = $_[0];
	
	if($filepath =~ /^.*\/([^\/]+)$/)
	{
		return $1;
	}
	return "";
}


# August 17, 2021
# August 31, 2021
