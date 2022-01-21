#!/usr/bin/env perl

# Retrieves sequences that do not have blast results.

# Usage:
# perl extract_sequences_with_no_blast_hits.pl [blast output file]
# [fasta file that was input to blast]

# Prints to console. To print to file, use
# perl extract_sequences_with_no_blast_hits.pl [blast output file]
# [fasta file that was input to blast] > [output fasta file path]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # blast output format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $fasta_file = $ARGV[1]; # contains all sequences included in broad-database blast output--should be the fasta file used as input to broad-database blast


my $NEWLINE = "\n";
my $DELIMITER = "\t";

# blast file
my $SEQUENCE_NAME_COLUMN = 0; 	# qseqid
my $MATCHED_TAXONID_COLUMN = 3;# staxids (Subject Taxonomy ID(s), separated by a ';')
my $SUPERKINGDOM_COLUMN = 5;	# sskingdoms (Subject Super Kingdom(s), separated by a ';' (in alphabetical order))
my $PERCENT_ID_COLUMN = 9; 	# pident
my $QUERY_COVERAGE_COLUMN = 10;# qcovs
my $EVALUE_COLUMN = 11;		# evalue


# retrieves list of all sequences that were input to blast (all sequences to examine here)
my %sequence_has_no_or_poor_blast_hits = (); # key: sequence name -> value: 1 if sequence has no blast hit or only "bad" blast hits
open FASTA, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA>) # for each row in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # sequence name
	{
		my $sequence_name = $1;
		$sequence_has_no_or_poor_blast_hits{$sequence_name} = 1;
	}
}
close FASTA;


# reads in blast output: removes sequences with any matches
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
		my $matched_taxon_id = $items[$MATCHED_TAXONID_COLUMN];
		
		# marks sequence to not be output
		$sequence_has_no_or_poor_blast_hits{$sequence_name} = 0;
	}
}
close BLAST_OUTPUT;


# reads in fasa file; prints sequences with no hits
open FASTA, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $current_sequence_included = 0;
my %sequence_printed = ();
while(<FASTA>) # for each row in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # sequence name
	{
		my $sequence_name = $1;
		if($sequence_has_no_or_poor_blast_hits{$sequence_name})
		{
			$current_sequence_included = 1;
			$sequence_printed{$sequence_name} = 1;
		}
		else
		{
			$current_sequence_included = 0;
		}
	}
	
	if($current_sequence_included)
	{
		print $_;
		print $NEWLINE;
	}
}
close FASTA;


# verifies that all expected sequences from blast output have been found in the fasta file
foreach my $sequence_name(keys %sequence_has_no_or_poor_blast_hits)
{
	if($sequence_has_no_or_poor_blast_hits{$sequence_name}
		and !$sequence_printed{$sequence_name})
	{
		print STDERR "Error: sequence ".$sequence_name." seen in blast output but "
			."not in fasta.\n";
	}
}


# September 1, 2020
# January 20, 2022
