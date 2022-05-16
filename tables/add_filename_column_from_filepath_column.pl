#!/usr/bin/env perl

# Retrieves filepaths from specified column (or first column by default). Adds new column
# with filenames retrieved from these filepaths.

# Usage:
# perl add_filename_column_from_filepath_column.pl [table to add new column to]
# [optional title of column containing filepaths (if not provided, uses first column)]
# [optional 1 to remove all file extensions in output filenames (such that filename contains no .s)]

# Prints to console. To print to file, use
# perl add_filename_column_from_filepath_column.pl [table to add new column to]
# [optional title of column containing filepaths (if not provided, uses first column)] 
# [optional 1 to remove all file extensions in output filenames (such that filename contains no .s)]
# > [output table path]


use strict;
use warnings;


my $table = $ARGV[0]; # table to add new column to
my $filepaths_column_title = $ARGV[1]; # optional title of column containing filepaths (if not provided, uses first column)
my $remove_all_file_extensions = $ARGV[2]; # if set to 1, removes all file extensions in output filenames (such that filename contains no .s)

my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in replacement map file


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: input table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in input table
my $first_line = 1;
my $filepaths_column = 0;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		if($first_line) # column titles
		{
			if($filepaths_column_title)
			{
				# identifies column with filepaths
				my $column = 0;
				foreach my $column_title(@items_in_line)
				{
					if(defined $column_title and $column_title eq $filepaths_column_title)
					{
						$filepaths_column = $column;
					}
					$column++;
				}
			}
			
			# print filenames column title
			if($filepaths_column_title)
			{
				print $filepaths_column_title."_";
			}
			print "filenames".$DELIMITER;
			
			# print the rest of the header line as is
			print $line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# retrieve file name from file path
			my $filename = $items_in_line[$filepaths_column];
			if($filename =~ /^"(.*)"$/) # remove quotes around filepath
			{
				$filename = $1;
			}
			if($filename =~ /^.*\/(.*)$/) # remove directory path
			{
				$filename = $1;
			}
			if($filename =~ /^(.*)[.].*$/) # remove file extension
			{
				$filename = $1;
			}
			if($remove_all_file_extensions)
			{
				while($filename =~ /^(.*)[.].*$/) # remove file extension
				{
					$filename = $1;
				}
			}
			
			# print filenames column
			print $filename.$DELIMITER;
			
			# print the rest of the line as is
			print $line.$NEWLINE;
		}
	}
}
close TABLE;


# May 15, 2022
