#!/usr/bin/env perl

# Retrieves sequences that have blast results.

# Usage:
# perl extract_sequences_with_blast_hits.pl [blast output file]
# [fasta file that was input to blast] 
# [minimum percent identity for a blast hit to be counted]
# [minimum query coverage for a blast hit to be counted]

# Prints to console. To print to file, use
# perl extract_sequences_with_blast_hits.pl [blast output file]
# [fasta file that was input to blast]
# [minimum percent identity for a blast hit to be counted]
# [minimum query coverage for a blast hit to be counted] > [output fasta file path]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # blast output format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $fasta_file = $ARGV[1]; # contains all sequences included in broad-database blast output--should be the fasta file used as input to broad-database blast
my $minimum_pident = $ARGV[2]; # minimum percent identity to count a blast hit
my $minimum_qcovs = $ARGV[3]; # minimum query coverage to count a blast hit


my $NEWLINE = "\n";
my $DELIMITER = "\t";

# blast file
my $SEQUENCE_NAME_COLUMN = 0; 	# qseqid
my $MATCHED_TAXONID_COLUMN = 3;	# staxids (Subject Taxonomy ID(s), separated by a ';')
my $SUPERKINGDOM_COLUMN = 5;	# sskingdoms (Subject Super Kingdom(s), separated by a ';' (in alphabetical order))
my $PERCENT_ID_COLUMN = 9; 		# pident
my $QUERY_COVERAGE_COLUMN = 10;	# qcovs
my $EVALUE_COLUMN = 11;			# evalue


# verifies that input files exist and are not empty
if(!$fasta_file or !-e $fasta_file or -z $fasta_file)
{
	print STDERR "Error: fasta file not provided, does not exist, or empty:\n\t"
		.$fasta_file."\nExiting.\n";
	die;
}

if(!$blast_output or !-e $blast_output or -z $blast_output)
{
	print STDERR "Error: blast output file not provided, does not exist, or empty:\n\t"
		.$blast_output."\nExiting.\n";
	die;
}

# sets thresholds to default values if not provided
if(!$minimum_pident)
{
	$minimum_pident = 0;
}
if(!$minimum_qcovs)
{
	$minimum_qcovs = 0;
}


# reads in blast output: removes sequences with any matches
my %sequence_has_blast_hit = (); # key: sequence name -> value: 1 if sequence has blast hits passing thresholds
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
		
		# marks sequence to be output
		if($percent_id >= $minimum_pident and $query_coverage >= $minimum_qcovs)
		{
			$sequence_has_blast_hit{$sequence_name} = 1;
		}
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
		if($sequence_has_blast_hit{$sequence_name})
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
foreach my $sequence_name(keys %sequence_has_blast_hit)
{
	if($sequence_has_blast_hit{$sequence_name}
		and !$sequence_printed{$sequence_name})
	{
		print STDERR "Error: sequence ".$sequence_name." seen in blast output but "
			."not in fasta.\n";
	}
}


# September 1, 2020
# January 20, 2022
