#!/usr/bin/env perl

# Generates an LCA matches table (matching output of
# retrieve_top_blast_hits_LCA_for_each_sequence.pl) for sequences with no blast hits.

# Output table has columns (tab-separated):
# - sequence name
# - LCA taxon id
# - LCA taxon rank
# - LCA taxon species
# - LCA taxon genus
# - LCA taxon family
# - LCA taxon superkingdom
# - evalue of top hits
# - lowest pident of top hits
# - mean pident of top hits
# - highest pident of top hits
# - lowest qcovs of top hits
# - mean qcovs of top hits
# - highest qcovs of top hits
# - number top hits

# Usage:
# perl generate_LCA_table_for_sequences_with_no_matches.pl
# [fasta file of unmapped sequences]

# Prints to console. To print to file, use
# perl generate_LCA_table_for_sequences_with_no_matches.pl
# [fasta file of unmapped sequences] > [output table]


use strict;
use warnings;


my $unmapped_sequences_fasta = $ARGV[0]; # fasta file of unmapped sequences


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is non-empty
if(!$unmapped_sequences_fasta or !-e $unmapped_sequences_fasta or -z $unmapped_sequences_fasta)
{
	print STDERR "Error: unmapped sequences fasta file not provided, does not exist, or empty:\n\t"
		.$unmapped_sequences_fasta."\nExiting.\n";
	die;
}


# reads in sequence names from fasta file
my %sequence_names = (); # key: sequence name -> value: 1
open FASTA_FILE, "<$unmapped_sequences_fasta" || die "Could not open $unmapped_sequences_fasta to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		$sequence_names{$1} = 1;
	}
}
close FASTA_FILE;


# prints output table column titles
print "sequence_name".$DELIMITER;
print "LCA_taxon_id".$DELIMITER;
print "LCA_taxon_rank".$DELIMITER;
print "LCA_taxon_species".$DELIMITER;
print "LCA_taxon_genus".$DELIMITER;
print "LCA_taxon_family".$DELIMITER;
print "LCA_taxon_superkingdom".$DELIMITER;
print "evalue_of_top_hits".$DELIMITER;
print "lowest_pident_of_top_hits".$DELIMITER;
print "mean_pident_of_top_hits".$DELIMITER;
print "highest_pident_of_top_hits".$DELIMITER;
print "lowest_qcovs_of_top_hits".$DELIMITER;
print "mean_qcovs_of_top_hits".$DELIMITER;
print "highest_qcovs_of_top_hits".$DELIMITER;
print "number_top_hits";
print $NEWLINE;


# prints output table
foreach my $sequence_name(sort keys %sequence_names)
{
	# prints output line for LCA match for this sequence
	print $sequence_name.$DELIMITER;
	print "0".$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print $NO_DATA.$DELIMITER;
	print "0";
	print $NEWLINE;
}


# November 4, 2022
# December 6, 2022
# March 18, 2024

