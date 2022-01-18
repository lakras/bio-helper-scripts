#!/usr/bin/env perl

# Counts the number of sequences with hits in the blast output.

# Usage:
# perl count_sequences_in_blast_output.pl [blast output table]
# [optional minimum percent id] [optional minimum query coverage]
# [1 to print sequence names, 0 to print number sequences only]

# Prints to console. To print to file, use
# perl count_sequences_in_blast_output.pl [blast output table]
# [optional minimum percent id] [optional minimum query coverage]
# [1 to print sequence names, 0 to print number sequences only] > [output file path]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # blast output format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $min_percent_id = $ARGV[1];
my $min_qcov = $ARGV[2];
my $print_sequence_names = $ARGV[3];

my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";

# blast file
my $SEQUENCE_NAME_COLUMN = 0; 	# qseqid
my $MATCHED_TAXONID_COLUMN = 3;	# staxids (Subject Taxonomy ID(s), separated by a ';')
my $SUPERKINGDOM_COLUMN = 5;	# sskingdoms (Subject Super Kingdom(s), separated by a ';' (in alphabetical order))
my $PERCENT_ID_COLUMN = 9; 		# pident
my $QUERY_COVERAGE_COLUMN = 10;	# qcovs
my $EVALUE_COLUMN = 11;			# evalue


# initializes uninitialized values
if(!$min_percent_id)
{
	$min_percent_id = 0;
}
if(!$min_qcov)
{
	$min_qcov = 0;
}

# verifies that input file exists and is not empty
if(!$blast_output or !-e $blast_output or -z $blast_output)
{
	print STDERR "Error: blast output not provided, does not exist, or empty:\n\t"
		.$blast_output."\nExiting.\n";
	die;
}


# retrieves all sequence names with hits passing thresholds
my %sequence_names = (); # key: sequence name -> value: 1
my %sequence_names_decent_hits = (); # key: sequence name -> value: 1
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
		
		$sequence_names{$sequence_name} = 1;
		
		if((!$min_percent_id or $percent_id > $min_percent_id)
			and (!$min_qcov or $query_coverage > $min_qcov))
		{
			$sequence_names_decent_hits{$sequence_name} = 1;
		}
	}
}
close BLAST_OUTPUT;


# counts number sequences
my $number_sequences = keys %sequence_names;
print $number_sequences." sequences\n";

# counts sequences passing thresholds
if($min_percent_id or $min_qcov)
{
	my $count = 0;
	foreach my $sequence_name(keys %sequence_names_decent_hits)
	{
		$count++;
	}
	print $count." sequences with pident >= ".$min_percent_id." and qcovs >= ".$min_qcov."\n";
}

# prints names of sequences passing thresholds
if($print_sequence_names)
{
	print "\n";
	foreach my $sequence_name(keys %sequence_names_decent_hits)
	{
		print $sequence_name."\n";
	}
}


# October 1, 2020
# January 17, 2022
