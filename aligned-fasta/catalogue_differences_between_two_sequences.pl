#!/usr/bin/env perl

# Catalogues differences between two aligned sequences.

# Usage:
# perl catalogue_differences_between_two_sequences.pl [alignment fasta file path]

# Prints to console. To print to file, use
# perl catalogue_differences_between_two_sequences.pl [alignment fasta file path]
# > [output file path]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment; reference sequence must appear first


my $NEWLINE = "\n";


# verifies that fasta alignment file exists and is non-empty
if(!$alignment_file)
{
	print STDERR "Error: no input fasta alignment file provided. Exiting.\n";
	die;
}
if(!-e $alignment_file)
{
	print STDERR "Error: input fasta alignment file does not exist:\n\t".$alignment_file."\nExiting.\n";
	die;
}
if(-z $alignment_file)
{
	print STDERR "Error: input fasta alignment file is empty:\n\t".$alignment_file."\nExiting.\n";
	die;
}


# reads in the two aligned fasta sequences
my $sequence_1 = "";
my $sequence_2 = "";
my $reading_sequence_number = 0;
open FASTA_FILE, "<$alignment_file" || die "Could not open $alignment_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		$reading_sequence_number++;
	}
	else
	{
		if($reading_sequence_number == 2)
		{
			$sequence_1 .= $_;
		}
		elsif($reading_sequence_number == 3)
		{
			$sequence_2 .= $_;
		}
		else
		{
			print STDERR "Warning: more than two aligned sequences provided; ignoring"
				." additional sequences.\n";
		}
	}
}
close FASTA_FILE;


# retrieves bases
my @sequence_1_bases = split('', $sequence_1);
my @sequence_2_bases = split('', $sequence_2);


# verifies that they are the same length
if(scalar @sequence_1_bases != scalar @sequence_2_bases)
{
	print STDERR "Error: aligned sequences are not the same character length. Exiting.\n";
	die;
}

for (my $index = 0; $index < scalar @sequence_1_bases; $index++)
{
	if(uc $sequence_1_bases[$index] ne uc $sequence_2_bases[$index])
	{
		print $sequence_1_bases[$index];
		print $index + 1;
		print $sequence_2_bases[$index];
		print $NEWLINE;
	}
}

# November 7, 2024
