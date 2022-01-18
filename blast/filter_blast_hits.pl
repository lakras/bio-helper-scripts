#!/usr/bin/env perl

# Filters blast hits: prints blast hits with at least minimum percent identity and at
# least minimum percent query coverage. Can also further filter with optional maximum
# percent identity, maximum percent query coverage provided, or minimum length of matched
# sequence.

# Usage:
# perl filter_blast_hits.pl [blast output] [minimum percent identity]
# [minimum percent query coverage] [optional maximum percent identity]
# [optional maximum percent query coverage] [optional minimum length of matched sequence]

# Prints to console. To print to file, use
# perl filter_blast_hits.pl [blast output] [minimum percent identity]
# [minimum percent query coverage] [optional maximum percent identity]
# [optional maximum percent query coverage] [optional minimum length of matched sequence]
# > [output subset of blast output table]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $min_pident = $ARGV[1]; # minimum percent identity
my $min_qcovs = $ARGV[2]; # minimum percent query coverage
my $max_pident = $ARGV[3]; # optional maximum percent identity
my $max_qcovs = $ARGV[4]; # optional maximum percent query coverage
my $min_match_length = $ARGV[5]; # optional minimum length of matched sequence


my $OR = 0; # if 1, includes blast hits with at least minimum percent identity OR at least minimum percent query coverage


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
my $MATCH_LENGTH_COLUMN = 8;	# length


# verifies that input file exists and is not empty
if(!$blast_output or !-e $blast_output or -z $blast_output)
{
	print STDERR "Error: blast output not provided, does not exist, or empty:\n\t"
		.$blast_output."\nExiting.\n";
	die;
}

# initializes uninitialized values
if(!$min_pident)
{
	$min_pident = 0;
}
if(!$min_qcovs)
{
	$min_qcovs = 0;
}
if(!$max_pident)
{
	$max_pident = 100;
}
if(!$max_qcovs)
{
	$max_qcovs = 100;
}
if(!$min_match_length)
{
	$min_match_length = 0;
}


# reads in blast output and extracts sequences passing thresholds
open BLAST_OUTPUT, "<$blast_output" || die "Could not open $blast_output to read\n";
while(<BLAST_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$SEQUENCE_NAME_COLUMN];
		my $percent_id = $items[$PERCENT_ID_COLUMN];
		my $query_coverage = $items[$QUERY_COVERAGE_COLUMN];
		my $evalue = $items[$EVALUE_COLUMN];
		my $match_length = $items[$MATCH_LENGTH_COLUMN];
	
		if(!$OR and ($percent_id >= $min_pident and $query_coverage >= $min_qcovs
				and $match_length >= $min_match_length)
			or $OR and ($percent_id >= $min_pident or $query_coverage >= $min_qcovs)
				and $match_length >= $min_match_length)
		{
			print $_;
			print $NEWLINE;
		}
	}
}
close BLAST_OUTPUT;


# August 30, 2020
# January 18, 2022
