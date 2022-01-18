#!/usr/bin/env perl

# Retrieves top hits for each sequence (assumes they are in order in blast output).
# Prints all top hits with same e-values.

# Usage:
# perl retrieve_top_blast_hits_for_each_sequence.pl [blast output]

# Prints to console. To print to file, use
# perl retrieve_top_blast_hits_for_each_sequence.pl [blast output]
# > [output subset of blast output table]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $TAXONID_SEPARATOR = ";"; # in blast file


# blast file
my $SEQUENCE_NAME_COLUMN = 0; 	# qseqid
my $MATCHED_TAXONID_COLUMN = 3;	# staxids (Subject Taxonomy ID(s), separated by a ';')
my $SUPERKINGDOM_COLUMN = 5;	# sskingdoms (Subject Super Kingdom(s), separated by a ';' (in alphabetical order))
my $PERCENT_ID_COLUMN = 9; 		# pident
my $QUERY_COVERAGE_COLUMN = 10;	# qcovs
my $EVALUE_COLUMN = 11;			# evalue


# verifies that input file exists and is not empty
if(!$blast_output or !-e $blast_output or -z $blast_output)
{
	print STDERR "Error: blast output not provided, does not exist, or empty:\n\t"
		.$blast_output."\nExiting.\n";
	die;
}


# reads in blast output and extracts top blast hits for each sequence
open BLAST_OUTPUT, "<$blast_output" || die "Could not open $blast_output to read\n";
my $previous_sequence_name = "";
my $is_top_evalue = 1;
my $previous_evalue = -1;
while(<BLAST_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$SEQUENCE_NAME_COLUMN];
# 		my $percent_id = $items[$PERCENT_ID_COLUMN];
# 		my $query_coverage = $items[$QUERY_COVERAGE_COLUMN];
		my $evalue = $items[$EVALUE_COLUMN];
		
		if($sequence_name ne $previous_sequence_name)
		{
			print $_;
			print $NEWLINE;
			
			$is_top_evalue = 1;
		}
		elsif($is_top_evalue and $evalue == $previous_evalue)
		{
			print $_;
			print $NEWLINE;
		}
		else
		{
			$is_top_evalue = 0;
		}
		
		$previous_sequence_name = $sequence_name;
		$previous_evalue = $evalue;
	}
}
close BLAST_OUTPUT;


# August 30, 2020
# January 18, 2022
