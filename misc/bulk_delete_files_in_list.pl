#!/usr/bin/env perl

# Deletes files in input list.

# Usage:
# perl bulk_delete_files_in_list.pl
# [file containing list of paths of files to delete, one per line]


use strict;
use warnings;


my $list_of_files_to_delete = $ARGV[0]; # file containing list of paths of files to delete, one per line


# verifies that list of input files exists and is non-empty
if(!$list_of_files_to_delete)
{
	print STDERR "Error: no input file list provided. Exiting.\n";
	die;
}
if(!-e $list_of_files_to_delete)
{
	print STDERR "Error: input file list does not exist:\n\t"
		.$list_of_files_to_delete."\nExiting.\n";
	die;
}
if(-z $list_of_files_to_delete)
{
	print STDERR "Error: input file list is empty:\n\t"
		.$list_of_files_to_delete."\nExiting.\n";
	die;
}


open FILES_TO_DELETE, "<$list_of_files_to_delete" || die "Could not open $list_of_files_to_delete to read; terminating =(\n";
while(<FILES_TO_DELETE>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		my $file_path = $_;
		if(-e $file_path) # if file exists
		{
			# delete file
			`rm $file_path`;
		}
	}
}
close FILES_TO_DELETE;


# March 31, 2022
