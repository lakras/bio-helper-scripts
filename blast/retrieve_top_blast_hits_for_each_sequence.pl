#!/usr/bin/env perl

# Retrieves top hits for each sequence (assumes they are in order in blast output).
# Prints all top hits with same e-values.

# Usage:
# perl retrieve_top_blast_hits_for_each_sequence.pl [blast output]
# [number by which to multiply sequence's top evalue, to use as threshold for inclusion in top hits]
# [1 to treat blast output as modified DIAMOND output]

# Prints to console. To print to file, use
# perl retrieve_top_blast_hits_for_each_sequence.pl [blast output]
# [number by which to multiply sequence's top evalue, to use as threshold for inclusion in top hits]
# [1 to treat blast output as modified DIAMOND output]
# > [output subset of blast output table]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $top_evalue_multiplier_for_inclusion_threshold = $ARGV[1]; # LCA is performed on all hits with e-value less than or equal to this value * top e-value; set to 1 by default, to include only top e-value
my $is_diamond_output = $ARGV[2]; # if 1, treats input file with blast output as modified DIAMOND output; format: qseqid stitle (part 1: accession number) stitle (part 2: sequence name) qlen slen length pident qcovhsp evalue


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $TAXONID_SEPARATOR = ";"; # in blast file


# default value of top_evalue_multiplier_for_inclusion_threshold
my $DEFAULT_TOP_EVALUE_MULTIPLIER = 1;

# blast file columns
# format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $SEQUENCE_NAME_COLUMN_BLAST = 0; 	# qseqid
my $PERCENT_ID_COLUMN_BLAST = 9; 		# pident
my $QUERY_COVERAGE_COLUMN_BLAST = 10;	# qcovs
my $EVALUE_COLUMN_BLAST = 11;			# evalue

# modified DIAMOND output file columns
# format: qseqid stitle (part 1: accession number) stitle (part 2: sequence name) qlen slen length pident qcovhsp evalue
# Note: sstitle column must first be separated out into two columns, accession number and sequence name
# perl split_column_after_query.pl [DIAMOND output file] 1 " " > [DIAMOND output file with accession number and sequence name in separate columns]
my $SEQUENCE_NAME_COLUMN_DIAMOND = 0; 	# qseqid
my $PERCENT_ID_COLUMN_DIAMOND = 6; 		# pident
my $QUERY_COVERAGE_COLUMN_DIAMOND = 7;	# qcovs
my $EVALUE_COLUMN_DIAMOND = 8;			# evalue


# sets e-value multiplier for inclusion threshold
if(!$top_evalue_multiplier_for_inclusion_threshold)
{
	$top_evalue_multiplier_for_inclusion_threshold = $DEFAULT_TOP_EVALUE_MULTIPLIER;
}


# determines whether columns should be blast format or modified diamond format
my $sequence_name_column = $SEQUENCE_NAME_COLUMN_BLAST; 	# qseqid
my $percent_id_column = $PERCENT_ID_COLUMN_BLAST; 			# pident
my $query_coverage_column = $QUERY_COVERAGE_COLUMN_BLAST;	# qcovs
my $evalue_column = $EVALUE_COLUMN_BLAST;					# evalue
if($is_diamond_output)
{
	$sequence_name_column = $SEQUENCE_NAME_COLUMN_DIAMOND; 		# qseqid
	$percent_id_column = $PERCENT_ID_COLUMN_DIAMOND; 			# pident
	$query_coverage_column = $QUERY_COVERAGE_COLUMN_DIAMOND;	# qcovs
	$evalue_column = $EVALUE_COLUMN_DIAMOND;					# evalue
}

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
my $sequence_top_evalue = -1;
while(<BLAST_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$sequence_name_column];
# 		my $percent_id = $items[$percent_id_column];
# 		my $query_coverage = $items[$query_coverage_column];
		my $evalue = $items[$evalue_column];
		
		# new sequence, so at least the first match has lowest e-value
		if($sequence_name ne $previous_sequence_name)
		{
			print $_;
			print $NEWLINE;
			
			$is_top_evalue = 1;
			$sequence_top_evalue = $evalue;
		}
		
		# not first match for this sequence, but the e-value is within range of the e-value
		# of the first match for this sequence
		elsif($is_top_evalue and $evalue <= $sequence_top_evalue
				* $top_evalue_multiplier_for_inclusion_threshold)
		{
			print $_;
			print $NEWLINE;
		}
		
		# e-value not within range of first match for this sequence
		else
		{
			$is_top_evalue = 0;
		}
		
		# prepares for next sequence
		$previous_sequence_name = $sequence_name;
	}
}
close BLAST_OUTPUT;


# August 30, 2020
# January 18, 2022
# March 17, 2023
