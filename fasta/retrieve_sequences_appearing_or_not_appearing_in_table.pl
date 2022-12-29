#!/usr/bin/env perl

# Retrieves sequences whose names do or do not appear in input table.

# Usage:
# perl retrieve_sequences_appearing_or_not_appearing_in_table.pl [fasta file]
# [input table] [column number of sequence names (0-indexed)]
# [1 to retrieve sequences that DO appear in input table, 0 to retrieve sequences that DON'T]

# Prints to console. To print to file, use
# perl retrieve_sequences_appearing_or_not_appearing_in_table.pl [fasta file]
# [input table] [column number of sequence names (0-indexed)]
# [1 to retrieve sequences that DO appear in input table, 0 to retrieve sequences that DON'T]
# > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $input_table = $ARGV[1];
my $sequence_names_column = $ARGV[2];
my $retrieve_sequences_appearing_in_table = $ARGV[3]; # 1 to retrieve sequences that DO appear in input table, 0 to retrieve sequences that DON'T


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";


# verifies that input files exist and are not empty
if(!$fasta_file or !-e $fasta_file or -z $fasta_file)
{
	print STDERR "Error: fasta file not provided, does not exist, or empty:\n\t"
		.$fasta_file."\nExiting.\n";
	die;
}

if(!$input_table or !-e $input_table or -z $input_table)
{
	print STDERR "Error: input table not provided, does not exist, or empty:\n\t"
		.$input_table."\nExiting.\n";
	die;
}


# retrieves list of sequences appearing in input table
my %sequence_appears_in_input_table = (); # key: sequence name -> value: 1 if sequence name appears in input table
open INPUT_TABLE, "<$input_table" || die "Could not open $input_table to read\n";
while(<INPUT_TABLE>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$sequence_names_column];
		if($sequence_name)
		{
			$sequence_appears_in_input_table{$sequence_name} = 1;
		}
	}
}
close INPUT_TABLE;


# prints fasta sequences of only those sequences that either DO or DON'T appear in input table
open FASTA, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $current_sequence_included = 0;
while(<FASTA>) # for each row in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # sequence name
	{
		my $sequence_name = $1;
		$current_sequence_included = 0;
		if($retrieve_sequences_appearing_in_table and $sequence_appears_in_input_table{$sequence_name})
		{
			$current_sequence_included = 1;
		}
		if(!$retrieve_sequences_appearing_in_table and !$sequence_appears_in_input_table{$sequence_name})
		{
			$current_sequence_included = 1;
		}
	}
	
	if($current_sequence_included)
	{
		print $_;
		print $NEWLINE;
	}
}
close FASTA;


# September 1, 2020
# January 20, 2022
# December 29, 2022
