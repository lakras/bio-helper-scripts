#!/usr/bin/env perl

# Removes sequences that are only -s or Ns or are length 0.

# Usage:
# perl remove_empty_sequences.pl [fasta file path]

# Prints to console. To print to file, use
# perl remove_empty_sequences.pl [fasta file path] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # fasta file


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

# reads in fasta file
my $current_sequence = "";
my $current_sequence_name = "";
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			if(!is_empty_sequence($current_sequence))
			{
				print ">".$current_sequence_name."\n";
				print $current_sequence."\n";
			}
		}
		
		# save new sequence name and prepare to read in new sequence
		$current_sequence_name = $1;
		$current_sequence = "";
	}
	else # not header line
	{
		$current_sequence .= uc($_);
	}
}
if($current_sequence)
{
	if(!is_empty_sequence($current_sequence))
	{
		print ">".$current_sequence_name."\n";
		print $current_sequence."\n";
	}
}
close FASTA_FILE;


# returns 1 if sequence is entirely Ns or -s, 0 if not
sub is_empty_sequence
{
	my $sequence = $_[0];
	
	if(length($sequence) == 0)
	{
		return 1; # empty sequence
	}
	if($sequence =~ /[^-Nn]/)
	{
		return 0; # not an empty sequence
	}
	return 1; # empty sequence
}


# October 14, 2024
