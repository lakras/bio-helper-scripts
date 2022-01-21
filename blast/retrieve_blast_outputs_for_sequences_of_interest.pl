#!/usr/bin/env perl

# Retrieves blast hits for sequences of interest from blast output file.

# Usage:
# perl retrieve_blast_outputs_for_sequences_of_interest.pl [blast output file]
# [sequence name to retrieve blast hits for]
# [another sequence name to retrieve blast hits for] [etc.]

# Prints to console. To print to file, use
# perl retrieve_blast_outputs_for_sequences_of_interest.pl [blast output file]
# [sequence name to retrieve blast hits for]
# [another sequence name to retrieve blast hits for] [etc.] > [subset blast output path]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my @sequences_of_interest = @ARGV[1..$#ARGV]; # list of sequence names to retrieve blast hits for


my $NEWLINE = "\n";
my $DELIMITER = "\t";

# blast file
my $SEQUENCE_NAME_COLUMN = 0; 	# qseqid

# if 0, includes only identical sequence names
# if 1, includes sequence names that include name of sequence of interest
my $INCLUDE_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST = 0;


# verifies that blast output file exists and is non-empty
if(!$blast_output or !-e $blast_output or -z $blast_output)
{
	print STDERR "Error: blast output file not provided, does not exist, or empty:\n\t"
		.$blast_output."\nExiting.\n";
	die;
}

# verifies that sequences of interest were provided
if(!scalar @sequences_of_interest)
{
	print STDERR "Error: no sequences of interest provided.\nExiting.\n";
	die;
}


# reads in blast output and extracts sequences of interest
open BLAST_OUTPUT, "<$blast_output" || die "Could not open $blast_output to read\n";
while(<BLAST_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$SEQUENCE_NAME_COLUMN];
		
		my $line_is_for_sequence_of_interest = 0;
		foreach my $sequence_name_of_interest(@sequences_of_interest)
		{
			if($INCLUDE_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST and $sequence_name =~ /$sequence_name_of_interest/
				or !$INCLUDE_ANY_SEQUENCE_CONTAINING_NAME_OF_INTEREST and $sequence_name eq $sequence_name_of_interest)
			{
				$line_is_for_sequence_of_interest = 1;
			}
		}
		
		if($line_is_for_sequence_of_interest)
		{
			print $_;
			print $NEWLINE;
		}
	}
}
close BLAST_OUTPUT;


# August 30, 2020
# January 20, 2022
