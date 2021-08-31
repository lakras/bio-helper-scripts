#!/usr/bin/env perl

# Searches all input files for queries listed in query list file. Outputs query and each
# file it was found in, tab-separated, one line per query-file pair where query is detected.
# If query is not detected in any file, prints query followed by "not detected".

# Usage:
# perl bulk_grep_is_detected.pl [file listing queries, one per line] [file to grep]
# [another file to grep] [etc.]

# Prints to console. To print to file, use
# perl bulk_grep_is_detected.pl [file listing queries, one per line] [file to grep]
# [another file to grep] [etc.] > [output file path]


use strict;
use warnings;


my $query_list_file = $ARGV[0];
my @files_to_grep = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


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

# read in query list and grep each query
open QUERY_LIST, "<$query_list_file" || die "Could not open $query_list_file to read; terminating =(\n";
while(<QUERY_LIST>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		my $detected_in_at_least_one_file = 0;
		foreach my $file_to_grep(@files_to_grep)
		{
			print $_.$DELIMITER.$file_to_grep.$NEWLINE;
			if(`grep "$_" $file_to_grep`)
			{
				
				$detected_in_at_least_one_file = 1;
			}
		}
		
		# not detected in any file
		if(!$detected_in_at_least_one_file)
		{
			print $_.$DELIMITER."not detected".$NEWLINE;
		}
	}
}
close QUERY_LIST;


# August 17, 2021
# August 31, 2021