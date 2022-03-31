#!/usr/bin/env perl

# Moves files in input list to provided directory.

# Usage:
# perl bulk_move_files_in_list.pl
# [file containing list of paths of files to move, one per line]
# [directory to move files to]


use strict;
use warnings;


my $list_of_files_to_move = $ARGV[0]; # file containing list of paths of files to move, one per line
my $directory_to_move_files_to = $ARGV[1]; # directory to move files to


# verifies that list of input files exists and is non-empty
if(!$list_of_files_to_move)
{
	print STDERR "Error: no input file list provided. Exiting.\n";
	die;
}
if(!-e $list_of_files_to_move)
{
	print STDERR "Error: input file list does not exist:\n\t"
		.$list_of_files_to_move."\nExiting.\n";
	die;
}
if(-z $list_of_files_to_move)
{
	print STDERR "Error: input file list is empty:\n\t"
		.$list_of_files_to_move."\nExiting.\n";
	die;
}

# verifies that directory exists
if(!$directory_to_move_files_to)
{
	print STDERR "Error: no directory provided. Exiting.\n";
	die;
}
if(!-d $directory_to_move_files_to)
{
	print STDERR "Error: directory does not exist or is not a directory:\n\t"
		.$directory_to_move_files_to."\nExiting.\n";
	die;
}


open FILES_TO_MOVE, "<$list_of_files_to_move" || die "Could not open $list_of_files_to_move to read; terminating =(\n";
while(<FILES_TO_MOVE>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		my $file_path = $_;
		if(-e $file_path) # if file exists
		{
			# move file
			`mv $file_path $directory_to_move_files_to`;
		}
	}
}
close FILES_TO_MOVE;


# March 31, 2022
