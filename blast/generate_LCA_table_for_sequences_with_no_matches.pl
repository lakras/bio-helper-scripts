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
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search]
# [fasta file that was input to blast search]

# Prints to console. To print to file, use
# perl generate_LCA_table_for_sequences_with_no_matches.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search]
# [fasta file that was input to blast search]  > [output table]


use strict;
use warnings;


my $LCA_matches = $ARGV[0]; # output of retrieve_top_blast_hits_LCA_for_each_sequence.pl
my $fasta_file = $ARGV[1]; # fasta file that was input to blast search (to retrieve sequence lengths and names of unclassified sequences)

my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";

# blast LCA table columns:
my $sequence_name_column = 0;
my $LCA_taxon_id_column = 1;
my $LCA_taxon_rank_column = 2;
my $LCA_taxon_species_column = 3;
my $LCA_taxon_genus_column = 4;
my $LCA_taxon_family_column = 5;
my $LCA_taxon_superkingdom_column = 6;
my $evalue_of_top_hits_column = 7;
my $lowest_pident_of_top_hits_column = 8;
my $mean_pident_of_top_hits_column = 9;
my $highest_pident_of_top_hits_column = 10;
my $lowest_qcovs_of_top_hits_column = 11;
my $mean_qcovs_of_top_hits_column = 12;
my $highest_qcovs_of_top_hits_column = 13;
my $number_top_hits_column = 14;


# verifies that input files exist and are non-empty
if(!$fasta_file or !-e $fasta_file or -z $fasta_file)
{
	print STDERR "Error: fasta file not provided, does not exist, or empty:\n\t"
		.$fasta_file."\nExiting.\n";
	die;
}
if(!$LCA_matches or !-e $LCA_matches or -z $LCA_matches)
{
	print STDERR "Error: LCA matches file not provided, does not exist, or empty:\n\t"
		.$LCA_matches."\nExiting.\n";
	die;
}


# reads in sequence names from LCA table
my $first_row = 1;
my %sequence_names_with_matches = (); # key: sequence name appearing in LCA table -> value: 1
open LCA_MATCHES, "<$LCA_matches" || die "Could not open $LCA_matches to read\n";
while(<LCA_MATCHES>)
{
	chomp;
	my $line = $_;
	if($line =~ /\S/)
	{
		if($first_row)
		{
			# ignore header line
			$first_row = 0;
		}
		else
		{
			# reads in relevant lines in row
			my @items = split($DELIMITER, $line);
			my $sequence_name = $items[$sequence_name_column];
			
			# saves sequence name
			$sequence_names_with_matches{$sequence_name} = 1;
		}
	}
}
close LCA_MATCHES;


# reads in sequence names from fasta file
my %sequence_names_without_matches = (); # key: sequence name not appearing in LCA table -> value: 1
open FASTA_FILE, "<$unmapped_sequences_fasta" || die "Could not open $unmapped_sequences_fasta to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		my $sequence_name = $1;
		
		if(!$sequence_names_with_matches{$sequence_name})
		{
			$sequence_names_without_matches{$sequence_name} = 1;
		}
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
foreach my $sequence_name(sort keys %sequence_names_without_matches)
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

