#!/usr/bin/env perl

# Prints either all sequences before or all sequence after sequence name appears in fasta
# sequence file.

# Usage:
# perl slice_blast_output_file_before_or_after_sequence_name_query.pl [fasta file]
# [sequence name to slice before or after]
# [1 to print all sequences BEFORE sequence name, 0 to print all sequences AFTER sequence name]
# [1 to print sequences including sequence name, 0 not to]

# Prints to console. To print to file, use
# perl slice_blast_output_file_before_or_after_sequence_name_query.pl [fasta file]
# [sequence name to slice before or after]
# [1 to print all sequences BEFORE sequence name, 0 to print all sequences AFTER sequence name]
# [1 to print sequences including sequence name, 0 not to]
# > [output fasta file]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $sequence_name_of_interest = $ARGV[1];
my $print_before = $ARGV[2]; # 1 to print all lines BEFORE sequence name, 0 to print all lines AFTER sequence name
my $print_sequence_of_interest_lines = $ARGV[3]; # 1 to print lines containing sequence name of interest, 0 to not print lines containing sequence name of interest


my $NEWLINE = "\n";
my $DELIMITER = "\t";

# if 0, matches only identical sequence names
# if 1, matches sequence names that include name of sequence of interest
my $MATCH_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST = 0;


open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read\n";
my $sequence_name = "";
my $print_output = 0; # 0: don't print this sequence, 1: print this sequence, 2: this sequence has a name matching sequence name of interest
if($print_before)
{
	$print_output = 1;
}
while(<FASTA_FILE>)
{
	chomp;
	if($_ =~ /^>(.*)$/)
	{
		$sequence_name = $1;
	
		# if we are printing everything BEFORE sequence name appears
		if($print_before)
		{
			if($MATCH_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST and $sequence_name =~ /$sequence_name_of_interest/
				or !$MATCH_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST and $sequence_name eq $sequence_name_of_interest)
			{
				$print_output = 2; # this line contains sequence name of interest
			}
			elsif($print_output == 2)
			{
				$print_output = 0; # do not print this or future lines
			}
		}
	
		# if we are printing everything AFTER sequence name appears
		else
		{
			if($MATCH_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST and $sequence_name =~ /$sequence_name_of_interest/
				or !$MATCH_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST and $sequence_name eq $sequence_name_of_interest)
			{
				$print_output = 2; # this line contains sequence name of interest
			}
			elsif($print_output == 2)
			{
				$print_output = 1; # print this and all future lines
			}
		}
	}
	if($print_output == 1 or $print_output == 2 and $print_sequence_of_interest_lines)
	{
		print $_;
		print $NEWLINE;
	}
}
close FASTA_FILE;


# October 7, 2020
# January 20, 2022
