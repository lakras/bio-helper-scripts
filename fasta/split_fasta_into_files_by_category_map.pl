#!/usr/bin/env perl

# Splits fasta file into multiple files using map of sequence name to category.

# Usage:
# perl split_fasta_into_files_by_category_map.pl [fasta file path]
# [tab-separated map of sequence names to category, one sequence name per line]
# [directory to print output fasta files to]

# Provided directory must be empty. New files are created in the provided directory,
# named "[category].fasta". Spaces, commas, periods, and /s in category name will be
# replaced with underscores in filenames.


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $category_map = $ARGV[1];
my $directory = $ARGV[2];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# adds "/" to the end of the directory
if($directory !~ /\/$/)
{
	$directory = $directory."/";
}


# verifies that input fasta file exists and is not empty
if(!$fasta_file)
{
	print STDERR "Error: no input fasta file provided. Exiting.\n";
	die;
}
if(!-e $fasta_file)
{
	print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
	die;
}
if(-z $fasta_file)
{
	print STDERR "Error: input fasta file is empty:\n\t".$fasta_file."\nExiting.\n";
	die;
}

# verifies that mapping file exists and is not empty
if(!$category_map)
{
	print STDERR "Error: no category map file provided. Exiting.\n";
	die;
}
if(!-e $category_map)
{
	print STDERR "Error: input category map does not exist:\n\t".$category_map
		."\nExiting.\n";
	die;
}
if(-z $category_map)
{
	print STDERR "Error: input category map is empty:\n\t".$category_map
		."\nExiting.\n";
	die;
}

# verify that provided directory exists and is empty
if(!-d $directory)
{
	print STDERR "Error: provided directory does not exist:\n\t".$directory
		."\nExiting.\n";
	die;
}
if(!is_folder_empty($directory))
{
	print STDERR "Error: provided directory is not empty:\n\t".$directory
		."\nExiting.\n";
	die;
}


# reads in category mapping
my %sequence_name_to_category = (); # key: sequence name -> value: category
open CATEGORY_MAP, "<$category_map"
	|| die "Could not open $category_map to read; terminating =(\n";
while(<CATEGORY_MAP>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		# parses this line
		my @items = split($DELIMITER, $line);
		my $sequence_name = $items[0];
		my $category = $items[1];

		# saves category mapping
		$sequence_name_to_category{$sequence_name} = $category;
	}
}
close CATEGORY_MAP;


# reads in fasta file and splits up into files
my $print_current_sequence = 0;
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /^>(.*)$/) # header line
	{
		# closes current output file
		close OUT_FILE;
	
		# retrieves category
		my $sequence_name = $1;
		my $category = $sequence_name_to_category{$sequence_name};
		if(!$category and $sequence_name =~ /(.*)\|.+/)
		{
			$sequence_name = $1;
			$category = $sequence_name_to_category{$sequence_name};
		}
		
		# determines filepath of new output file
		if($category)
		{
			$category =~ tr/ /_/;
			$category =~ tr/\//_/;
			$category =~ tr/,/_/;
			$category =~ tr/[.]/_/;
			my $output_filepath = $directory.$category.".fasta";
		
			# opens new output file
			open OUT_FILE, ">>$output_filepath"
				|| die "Could not open $output_filepath to write; terminating =(\n";
			$print_current_sequence = 1;
		}
		else
		{
			$print_current_sequence = 0;
		}
	}
	
	# prints header or sequence line to current output file
	if($print_current_sequence)
	{
		print OUT_FILE $line;
		print OUT_FILE $NEWLINE;
	}
}
close FASTA_FILE;
close OUT_FILE;


# check if directory is empty, from https://stackoverflow.com/questions/4493482/detect-empty-directory-with-perl
sub is_folder_empty
{
    my $dirname = shift;
    opendir(my $dh, $dirname) or die "Not a directory";
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
}


# June 16, 2023
