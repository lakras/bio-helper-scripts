#!/usr/bin/env perl

# Matches each sample name to a file path containing that sample name. Outputs sample
# names with file paths, tab-separated, one sample per line.

# Usage:
# perl match_file_paths_to_sample_names.pl
# [file containing list of sample names, one per line]
# [file containing list of file paths, one per line]

# Prints to console. To print to file, use
# perl match_file_paths_to_sample_names.pl
# [file containing list of sample names, one per line]
# [file containing list of file paths, one per line] > [output table path]


use strict;
use warnings;


my $sample_names_file = $ARGV[0]; # file containing list of sample names, one per line
my $file_paths_file = $ARGV[1]; # file containing list of file paths, one per line


my $DELIMITER = "\t";
my $NEWLINE = "\n";

my $SEARCH_FOR_MATCH_QUICKLY = 1; # if 0, uses pattern matching at O(n^2); if 1, trims extension off filename until match is found
my $VERIFY_MATCHES_FOUND = 0;
my $ONLY_PRINT_SAMPLE_NAMES_WITH_MATCHING_FILE_PATHS = 0;


# verifies that input files exist and are non-empty
if(!$sample_names_file or !-e $sample_names_file or -z $sample_names_file)
{
	print STDERR "Error: sample names list file is not a non-empty file:\n\t"
		.$sample_names_file."\nExiting.\n";
	die;
}
if(!$file_paths_file or !-e $file_paths_file or -z $file_paths_file)
{
	print STDERR "Error: file paths list file is not a non-empty file:\n\t"
		.$file_paths_file."\nExiting.\n";
	die;
}


# reads in sample names
my %all_samples = (); # key: sample name -> value: 1
open SAMPLE_NAMES_LIST, "<$sample_names_file" || die "Could not open $sample_names_file to read; terminating =(\n";
while(<SAMPLE_NAMES_LIST>) # for each line in the file
{
	chomp;
	my $sample_name = $_;
	if($sample_name =~ /\S/) # non-empty string
	{
		$all_samples{$sample_name} = 1;
	}
}
close SAMPLE_NAMES_LIST;


# reads in file paths
my %sample_name_to_file_path = (); # key: sample name -> value: matched file path
my @file_paths_without_sample_names = ();
open FILE_PATHS_LIST, "<$file_paths_file" || die "Could not open $file_paths_file to read; terminating =(\n";
while(<FILE_PATHS_LIST>) # for each line in the file
{
	chomp;
	my $file_path = $_;
	if($file_path =~ /\S/) # non-empty string
	{
		# retrieves file name from file path
		my $file_name = $file_path;
		if($file_name =~ /^.*\/(.+)$/)
		{
			$file_name = $1;
		}
		
		my $sample_name = "";
		if($SEARCH_FOR_MATCH_QUICKLY) # fastest option
		{
			# removes extensions until file name matches a sample name or is empty
			my $potential_sample_name = $file_name;
			while($potential_sample_name and !$sample_name)
			{
				if($all_samples{$potential_sample_name})
				{
					# sample name matched
					$sample_name = $potential_sample_name;
				}
				else
				{
					# trims off extension
					if($potential_sample_name =~ /(.*)[.].+/)
					{
						$potential_sample_name = $1;
					}
					else
					{
						$potential_sample_name = "";
					}
				}
			}
		}
		else # slowest but most thorough option
		{
			# retrieve sample name from file name
			my $sample_name = "";
			foreach my $potential_sample_name(sort {length $a <=> length $b} keys %all_samples)
			{
				if($file_path =~ /$potential_sample_name/)
				{
					$sample_name = $potential_sample_name;
					last;
				}
			}
		}
		
		# verifies that we haven't already matched a file path to this sample name
		if($sample_name_to_file_path{$sample_name})
		{
			print STDERR "Warning: multiple file paths mapped to sample name "
				.$sample_name.":\n\t".$sample_name_to_file_path{$sample_name}
				."\n\t".$file_path."\n";
		}
		
		# saves matched sample name
		if($sample_name)
		{
			$sample_name_to_file_path{$sample_name} .= $file_path;
		}
		else
		{
			push(@file_paths_without_sample_names, $file_path);
		}
	}
}
close FILE_PATHS_LIST;


if($VERIFY_MATCHES_FOUND)
{
	# verifies that we found a file path for each sample
	my @sample_names_without_file_paths = ();
	foreach my $sample_name(keys %all_samples)
	{
		if(!$sample_name_to_file_path{$sample_name})
		{
			push(@sample_names_without_file_paths, $sample_name);
		}
	}
	if(scalar @sample_names_without_file_paths)
	{
		print STDERR "Warning: sample names without matching file paths:\n";
		foreach my $sample_name(sort @sample_names_without_file_paths)
		{
			print STDERR "\t".$sample_name."\n";
		}
	}


	# verifies that we found a sample name for each file path
	if(scalar @file_paths_without_sample_names)
	{
		print STDERR "Warning: file paths without matching sample names:\n";
		foreach my $file_path(sort @file_paths_without_sample_names)
		{
			print STDERR "\t".$file_path."\n";
		}
	}
}


# prints output
foreach my $sample_name(keys %all_samples)
{
	if(!$ONLY_PRINT_SAMPLE_NAMES_WITH_MATCHING_FILE_PATHS
		or $sample_name_to_file_path{$sample_name})
	{
		print $sample_name;
		print $DELIMITER;
		if($sample_name_to_file_path{$sample_name})
		{
			print $sample_name_to_file_path{$sample_name};
		}
		print $NEWLINE;
	}
}


# March 24, 2022
