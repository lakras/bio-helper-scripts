#!/usr/bin/env perl

# Prints either all lines before or all lines after sequence name appears in blast output
# file.

# Usage:
# perl slice_blast_output_file_before_or_after_sequence_name_query.pl [blast output]
# [sequence name to slice before or after]
# [1 to print all lines BEFORE sequence name, 0 to print all lines AFTER sequence name]
# [1 to print lines including sequence name, 0 not to]

# Prints to console. To print to file, use
# perl slice_blast_output_file_before_or_after_sequence_name_query.pl [blast output]
# [sequence name to slice before or after]
# [1 to print all lines BEFORE sequence name, 0 to print all lines AFTER sequence name]
# [1 to print lines including sequence name, 0 not to]
# > [output subset of blast output table]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $sequence_name_of_interest = $ARGV[1];
my $print_before = $ARGV[2]; # 1 to print all lines BEFORE sequence name, 0 to print all lines AFTER sequence name
my $print_sequence_of_interest_lines = $ARGV[3]; # 1 to print lines containing sequence name of interest, 0 to not print lines containing sequence name of interest


my $NEWLINE = "\n";
my $DELIMITER = "\t";

# blast file
my $SEQUENCE_NAME_COLUMN = 0; 	# qseqid

# if 0, matches only identical sequence names
# if 1, matches sequence names that include name of sequence of interest
my $MATCH_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST = 0;


# verifies that blast output file exists and is non-empty
if(!$blast_output or !-e $blast_output or -z $blast_output)
{
	print STDERR "Error: blast output file not provided, does not exist, or empty:\n\t"
		.$blast_output."\nExiting.\n";
	die;
}


open BLAST_FILE, "<$blast_output" || die "Could not open $blast_output to read\n";
my $print_output = 0; # 0: don't print this line, 1: print this line, 2: this line contains sequence name of interest
if($print_before)
{
	$print_output = 1;
}
while(<BLAST_FILE>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$SEQUENCE_NAME_COLUMN];
		
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
close BLAST_FILE;


# September 21, 2020
# January 20, 2022
