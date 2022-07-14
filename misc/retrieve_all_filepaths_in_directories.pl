#!/usr/bin/env perl

# Retrieves filepaths of all files in provided directories.

# Usage:
# perl retrieve_all_filepaths_in_directories.pl [directory path] [another directory path]
# [another directory path] [etc.]

# Prints to console. To print to file, use
# perl retrieve_all_filepaths_in_directories.pl [directory path] [another directory path]
# [another directory path] [etc.] > [output file path]


use strict;
use warnings;


my @directories = @ARGV; # directories to retrieve all filepaths from


my $NEWLINE = "\n";


foreach my $directory(@directories)
{
	# adds final slash to directory if it isn't there
	if($directory !~ /\/$/)
	{
		$directory .= "/";
	}

	# retrieves and prints paths of all files in directory
	opendir DIRECTORY, $directory;
	while(my $file = readdir(DIRECTORY))
	{
		# puts together file path of file
		my $filepath = $directory.$file;
		
		# verifies that this is a file
		if($file and !-d $file)
		{
			# prints file path of file
			print $filepath.$NEWLINE;
		}
	}
	close DIRECTORY;
}


# July 14, 2022
