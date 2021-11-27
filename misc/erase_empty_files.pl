#!/usr/bin/env perl

# Erases empty files.

# Usage:
# perl erase_empty_files.pl [file to check and potentially erase]
# [another file to check and potentially erase]
# [a third file to check and potentially erase] etc.


my @files_to_examine = @ARGV; # files to check and potentially erase


# checks that files to examine have been provided
if(!scalar @files_to_examine)
{
	print STDERR "Error: no files to examine provided. Exiting.\n";
	die;
}


# examines files and erases empty ones
foreach my $file(@files_to_examine)
{
	if(!-e $file)
	{
		# file does not exist
		print STDERR "Warning: file to examine does not exist:\n\t".$file."\n";
	}
	elsif(-z $file)
	{
		# file is empty
		`rm $file`;
	}
}


# November 27, 2021
