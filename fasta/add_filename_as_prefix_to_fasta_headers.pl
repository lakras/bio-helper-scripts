#!/usr/bin/env perl

# Adds file name as prefix to each header line in fasta file(s).

# Usage:
# perl add_filename_as_prefix_to_fasta_headers.pl [fasta file path]
# [another fasta file path] [etc.]

# Prints to console. To print to file, use
# perl add_filename_as_prefix_to_fasta_headers.pl [fasta file path]
# [another fasta file path] [etc.] > [output fasta file path]


use strict;
use warnings;


my @fasta_files = @ARGV[0..$#ARGV]; # list of fasta files


my $REMOVE_ALL_EXTENSIONS = 1; # if 1, removes all extensions (.something) from file name
my $NEWLINE = "\n";


# verifies that fasta files exist and are non-empty
if(!scalar @fasta_files)
{
	print STDERR "Error: no input fasta file provided. Exiting.\n";
	die;
}
foreach my $fasta_file(@fasta_files)
{
	if(!-e $fasta_file)
	{
		print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
		die;
	}
	if(-z $fasta_file)
	{
		print STDERR "Warning: input fasta file is empty:\n\t".$fasta_file."\n";
	}
}


# reads in fasta file; adds file name as prefix to each header
foreach my $fasta_file(@fasta_files)
{
	# retrieves file name to use as prefix for this fasta file's sequences
	my $prefix = $fasta_file;
	
	# removes directory (file path preceding file name)
	if($prefix =~ /.*\/(.+)/)
	{
		$prefix = $1;
	}
	
	# removes extension(s) at end of file name
	if($REMOVE_ALL_EXTENSIONS)
	{
		# removes all extensions from end of file name
		while($prefix =~ /(.*)[.]\w+/) 
		{
			$prefix = $1;
		}
	}
	else
	{
		# removes last extension from end of file name
		if($prefix =~ /(.*)[.]\w+/) 
		{
			$prefix = $1;
		}
	}

	# prints fasta file with file name as prefix to each header
	open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
	while(<FASTA_FILE>) # for each line in the file
	{
		chomp;
		if($_ =~ /^>(.*)/) # header line
		{
			$_ = ">".$prefix."__".$1;
		}
		print $_;
		print $NEWLINE;
	}
	close FASTA_FILE;
}


# June 7, 2020
# July 14, 2021
# January 17, 2022
