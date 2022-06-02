#!/usr/bin/env perl

# Replaces all occurrences of values in file paths to mapped replacement values. Values
# to replace should not overlap or be substrings of each other. Files already at
# replacement paths will be overwritten. Paths of files to rename can be provided directly
# as arguments or as one file with a list of filepaths, one per line.

# Usage:
# perl bulk_rename.pl
# [tab-separated file mapping current values (first column) to new values (second column)]
# [filepaths of at least two files to rename OR path of file containing filepaths of files
# to rename, one per line]


use strict;
use warnings;


my $rename_map_file = $ARGV[0];
my $list_of_files_to_rename;
my @files_to_rename;
if(scalar @ARGV > 2)
{
	@files_to_rename = @ARGV[1..$#ARGV];
}
else
{
	$list_of_files_to_rename = $ARGV[1];
}


my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in replacement map file

# replacement map columns:
my $CURRENT_VALUE_COLUMN = 0;
my $NEW_VALUE_COLUMN = 1;

my $OVERWRITE = 1; # set to 0 to prevent overwriting (stop script rather than overwrite)


# verifies that input files exist and are not empty
if(!$rename_map_file or !-e $rename_map_file or -z $rename_map_file)
{
	print STDERR "Error: rename map file not provided, does not exist, or empty:\n\t"
		.$rename_map_file."\nExiting.\n";
	die;
}
if((!$list_of_files_to_rename or !-e $list_of_files_to_rename or -z $list_of_files_to_rename)
	and !scalar @files_to_rename)
{
	print STDERR "Error: list of files to rename not provided, does not exist, or empty. "
		."Exiting.\n";
	die;
}


# read in map of new and old values
my %current_value_to_new_value = (); # key: old value -> value: new value
open REPLACEMENT_MAP, "<$rename_map_file" || die "Could not open $rename_map_file to read; terminating =(\n";
while(<REPLACEMENT_MAP>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		# reads in mapped values
		my @items_in_row = split($DELIMITER, $_);
		
		my $current_value = $items_in_row[$CURRENT_VALUE_COLUMN];
		my $new_value = $items_in_row[$NEW_VALUE_COLUMN];
		
		# verifies that we haven't seen the current value before
		if($current_value_to_new_value{$current_value}
			and $current_value_to_new_value{$current_value} ne $new_value)
		{
			print STDERR "Warning: current value ".$current_value." mapped to multiple "
				."new values.\n";
		}
		
		# saves current-new value pair
		if($new_value ne $current_value)
		{
			$current_value_to_new_value{$current_value} = $new_value;
		}
	}
}
close REPLACEMENT_MAP;


# if needed reads in and saves list of files to rename
if($list_of_files_to_rename and !scalar @files_to_rename)
{
	open FILES_TO_RENAME, "<$list_of_files_to_rename" || die "Could not open $list_of_files_to_rename to read; terminating =(\n";
	while(<FILES_TO_RENAME>) # for each line in the file
	{
		chomp;
		if($_ =~ /\S/)
		{
			my $filepath = $_;
			push(@files_to_rename, $filepath);
		}
	}
	close FILES_TO_RENAME;
}
if(!scalar @files_to_rename)
{
	print STDERR "Error: list of files to rename not provided, does not exist, or empty. "
		."Exiting.\n";
	die;
}


# renames files to rename
foreach my $filepath(@files_to_rename)
{
	# determines replacement filepath
	my $new_filepath = $filepath;
	foreach my $current_value(reverse sort keys %current_value_to_new_value)
	{
		my $new_value = $current_value_to_new_value{$current_value};
		$new_filepath =~ s/$current_value/$new_value/g;
	}
	
	# verifies that new path exists
	if(!$new_filepath)
	{
		print STDERR "Error: filepath to move file to is empty. Not moving file:\n"
			.$filepath."\n";
	}
	else
	{
		# verifies that either there is no file in new path or that we are allowing
		# overwriting
		if(-e $new_filepath)
		{
			print STDERR "Warning: new filepath already occupied. Overwriting:\n\t"
				.$new_filepath."\n";
			die_if_overwrite_not_allowed();
		}
		
		# moves file to new path
		`mv $filepath $new_filepath`;
	}
}


# June 1, 2022
