#!/usr/bin/env perl

# Counts number unambiguous bases (A, T, C, G) in each sequence. Outputs tab-separated
# table of sequence names and number unambiguous bases, one sequence per line.

# Usage:
# perl count_unambiguous_bases_in_each_sequence.pl [fasta file path]

# Prints to console. To print to file, use
# perl count_unambiguous_bases_in_each_sequence.pl [fasta file path]
# > [output table file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # fasta file


my $NEWLINE = "\n";
my $DELIMITER = "\t";


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


# counts number unambiguous bases in each sequence
foreach my $sequence_name(@sequences_in_order_read_in)
{
	# counts number unambiguous bases
	my $sequence = $sequence_name_to_sequence{$sequence_name};
	my $number_unambiguous_bases = 0;
	for my $base(split(//, $sequence))
	{
		if(is_unambiguous_base($base))
		{
			$number_unambiguous_bases++;
		}
	}
	
	# prints number unambiguous bases
	print $sequence_name.$DELIMITER.$number_unambiguous_bases.$NEWLINE;
}


# returns 1 if base is A, T, C, or G, 0 if not
sub is_unambiguous_base
{
	my $base = $_[0];
	
	if($base eq "-")
	{
		print STDERR "Error: sequence contains gaps and is therefore an alignment. "
			."Exiting.\n";
		die;
	}
	
	if($base eq "A" or $base eq "a")
	{
		return 1;
	}
	if($base eq "T" or $base eq "t")
	{
		return 1;
	}
	if($base eq "C" or $base eq "c")
	{
		return 1;
	}
	if($base eq "G" or $base eq "g")
	{
		return 1;
	}
	
	return 0;
}


# May 8, 2024
