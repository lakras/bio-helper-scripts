#!/usr/bin/env perl

# Prints position of sequence in fasta file.

# Usage:
# perl retrieve_sequence_position_in_fasta_file.pl [fasta sequence file]
# "[sequence name]"


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $sequence_name_of_interest = $ARGV[1];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# counts total number of sequences and number of sequences up to and including
# sequence of interest
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read\n";
my $sequence_count = 0;
my $sequence_count_when_sequence_of_interest_seen = 0;
while(<FASTA_FILE>)
{
	chomp;
	if($_ =~ /^>(.*)$/)
	{
		my $sequence_name = $1;
		if($sequence_name eq $sequence_name_of_interest)
		{
			$sequence_count_when_sequence_of_interest_seen = $sequence_count;
		}
		$sequence_count++;
	}
}
close FASTA_FILE;


# prints position of sequence in fasta file
my $percentage = 100 * $sequence_count_when_sequence_of_interest_seen / $sequence_count;
print "sequence ".$sequence_count_when_sequence_of_interest_seen." of ".$sequence_count." (".round($percentage)."%)\n";


# rounds input value to one decimal place
sub round
{
	my $value = $_[0];
	return sprintf("%.1f", $value);
}


# September 21, 2020
# January 17, 2022
