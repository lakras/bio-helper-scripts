#!/usr/bin/env perl

# Prints all sequences from fasta file that contain at least one provided query in the
# sequence name. Case sensitive.

# Usage:
# perl retrieve_sequences_containing_queries.pl [fasta file path] "[query 1]"
# "[query 2]" "[query 3]" [etc.]

# Prints to console. To print to file, use
# perl retrieve_sequences_containing_queries.pl [fasta file path] "[query 1]"
# "[query 2]" "[query 3]" [etc.] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my @queries = @ARGV[1..$#ARGV];


# verifies that query sequence names have been provided
if(!scalar @queries)
{
	print STDERR "Error: no queries provided. Exiting.\n";
	die;
}

# verifies that fasta file exists and is non-empty
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


# reads in fasta file and retrieves sequences matching query sequence names
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $printing_this_sequence = 0; # 1 if we are printing the sequence we are currently reading
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# checks if this sequence name contains at least one of our queries
		my $sequence_name = $1;
		$printing_this_sequence = 0;
		foreach my $query(@queries)
		{
			if($sequence_name =~ /$query/)
			{
				# records that we are printing lines belonging to this sequence
				$printing_this_sequence = 1;
			}
		}
	}
	
	# prints this line (header or sequence) if we are printing this sequence
	if($printing_this_sequence)
	{
		print $_."\n";
	}
}
close FASTA_FILE;


# November 3, 2021
