#!/usr/bin/env perl

# Summarizes files. Generates table with filepath, filename, filename with extensions
# trimmed off, and number lines, words, and characters in the file.

# Usage:
# perl summarize_files.pl [file with list of files to summarize, one per line]

# Prints to console. To print to file, use
# perl summarize_files.pl [file with list of files to summarize, one per line]
# > [output file path]


my $files_to_summarize = $ARGV[0]; # file containing list of files to summarize, one per line


my $DELIMITER = "\t";
my $NEWLINE = "\n";


# prints header line
print "filepath".$DELIMITER;
print "filename".$DELIMITER;
print "filename_without_extensions".$DELIMITER;
print "number_lines".$DELIMITER;
print "number_words".$DELIMITER;
print "number_characters".$NEWLINE;


# summarizes input files
open FILES_TO_SUMMARIZE, "<$files_to_summarize" || die "Could not open $files_to_summarize to read; terminating =(\n";
while(<FILES_TO_SUMMARIZE>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		my $file_path = $_;
		
		# retrieves file name from file path
		my $file_name = $file_path;
		if($file_name  =~ /\/([^\/]+)$/)
		{
			$file_name = $1;
		}
		
		# removes extensions from file name
		my $file_name_without_extensions = $file_name;
		while($file_name_without_extensions =~ /(.*)[.].*/)
		{
			$file_name_without_extensions = $1;
		}
		
		# retrieves wordcount stats
		my $number_lines = `wc -l $file_path`;
		my $number_words = `wc -w $file_path`;
		my $number_characters = `wc -c $file_path`;
		
		# cleans up wordcount stats
		if($number_lines =~ /^\s+(\d+)\s/)
		{
			$number_lines = $1;
		}
		if($number_words =~ /^\s+(\d+)\s/)
		{
			$number_words = $1;
		}
		if($number_characters =~ /^\s+(\d+)\s/)
		{
			$number_characters = $1;
		}
		
		# prints summary of this file
		print $file_path.$DELIMITER;
		print $file_name.$DELIMITER;
		print $file_name_without_extensions.$DELIMITER;
		print $number_lines.$DELIMITER;
		print $number_words.$DELIMITER;
		print $number_characters.$NEWLINE;
	}	
}
close FILES_TO_SUMMARIZE;


# April 1, 2022
