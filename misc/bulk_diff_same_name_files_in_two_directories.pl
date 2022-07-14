#!/usr/bin/env perl

# Compares all files with the same name in the two input directories. Prints any
# differences between same-name files. The two directories must contain files with the
# same names.

# Usage:
# perl bulk_diff_same_name_files_in_two_directories.pl [first directory] [second directory]


use strict;
use warnings;


my $directory_1 = $ARGV[0];
my $directory_2 = $ARGV[1];


# adds final slash to directories if it isn't there
if($directory_1 !~ /\/$/)
{
	$directory_1 .= "/";
}
if($directory_2 !~ /\/$/)
{
	$directory_2 .= "/";
}


# retrieves all filepaths in first directory
my %filename_appears_in_directory_1 = (); # key: file name -> value: 1 if file appears in directory 1
opendir DIRECTORY_1, $directory_1;
while(my $file = readdir(DIRECTORY_1))
{
	# saves filename
	$filename_appears_in_directory_1{$file} = 1;
}
close DIRECTORY_1;


# retrieves all filepaths in second directory
my %filename_appears_in_directory_2 = (); # key: file name -> value: 1 if file appears in directory 2
opendir DIRECTORY_2, $directory_2;
while(my $file = readdir(DIRECTORY_2))
{
	# saves filename
	$filename_appears_in_directory_2{$file} = 1;
}
close DIRECTORY_2;


# compares each pair of same-name files, one from each directory
foreach my $file_name(sort keys %filename_appears_in_directory_1)
{
	if($filename_appears_in_directory_2{$file_name}) # file name appears in both directories
	{
		# generates file paths for each directory
		my $filepath_1 = $directory_1.$file_name;
		my $filepath_2 = $directory_2.$file_name;
		
		# compares the two files
		`diff $filepath_1 $filepath_2`;
	}
}


# July 14, 2022
