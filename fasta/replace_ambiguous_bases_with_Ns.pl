#!/usr/bin/env perl

# Replaces ambiguous bases (anything except A, T, C, G, or -) in each sequence with Ns.

# Usage:
# perl replace_ambiguous_bases_with_Ns.pl [fasta file path]

# Prints to console. To print to file, use
# perl replace_ambiguous_bases_with_Ns.pl [fasta file path] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # fasta file


my $NEWLINE = "\n";


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
my %sequence_name_to_sequence = (); # key: sequence name -> value: sequence read in
my @sequences_in_order_read_in = (); # sequence names in order they appear in the fasta file
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
			push(@sequences_in_order_read_in, $current_sequence_name);
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
	$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
	push(@sequences_in_order_read_in, $current_sequence_name);
}
close FASTA_FILE;


# prints each sequence with ambiguous bases changed to Ns
foreach my $sequence_name(@sequences_in_order_read_in)
{
	print ">".$sequence_name.$NEWLINE;
	my $sequence = $sequence_name_to_sequence{$sequence_name};
	for my $base(split(//, $sequence))
	{
		if(is_ambiguous_base($base))
		{
			print "N";
		}
		else
		{
			print $base;
		}
	}
	print $NEWLINE;
}


# returns 0 if base is A, T, C, G, or -, 1 if not
sub is_ambiguous_base
{
	my $base = $_[0];
	
	if($base eq "-")
	{
		return 0;
	}
	
	if($base eq "A" or $base eq "a")
	{
		return 0;
	}
	if($base eq "T" or $base eq "t")
	{
		return 0;
	}
	if($base eq "C" or $base eq "c")
	{
		return 0;
	}
	if($base eq "G" or $base eq "g")
	{
		return 0;
	}
	
	return 1;
}


# January 28, 2025
