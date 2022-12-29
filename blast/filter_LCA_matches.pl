#!/usr/bin/env perl

# Filters LCA matches by rank (at least species, genus, or family), mean percent identity,
# and/or mean percent query coverage. Uses output of
# retrieve_top_blast_hits_LCA_for_each_sequence.pl as input.

# Input table is output of retrieve_top_blast_hits_LCA_for_each_sequence.pl, with
# column titles (tab-separated):
# - sequence_name
# - LCA_taxon_id
# - LCA_taxon_rank
# - LCA_taxon_species
# - LCA_taxon_genus
# - LCA_taxon_family
# - evalue_of_top_hits
# - lowest_pident_of_top_hits
# - mean_pident_of_top_hits
# - highest_pident_of_top_hits
# - lowest_qcovs_of_top_hits
# - mean_qcovs_of_top_hits
# - highest_qcovs_of_top_hits
# - number_top_hits


# Usage:
# perl filter_LCA_matches.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search]
# [1 to requires output matches to be classified to at least species level]
# [1 to requires output matches to be classified to at least genus level]
# [1 to requires output matches to be classified to at least family level]
# [minimum mean percent identity] [maximum mean percent identity] 
# [minimum mean percent query coverage] [maximum mean percent query coverage] 


# Prints to console. To print to file, use
# perl filter_LCA_matches.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search]
# [1 to requires output matches to be classified to at least species level]
# [1 to requires output matches to be classified to at least genus level]
# [1 to requires output matches to be classified to at least family level]
# [minimum mean percent identity] [maximum mean percent identity] 
# [minimum mean percent query coverage] [maximum mean percent query coverage] 
#  > [output filtered LCA matches table]


use strict;
use warnings;


my $LCA_matches = $ARGV[0]; # output of retrieve_top_blast_hits_LCA_for_each_sequence.pl
my $classified_to_at_least_species = $ARGV[1]; # if 1, requires output matches to be classified to at least species level
my $classified_to_at_least_genus = $ARGV[2]; # if 1, requires output matches to be classified to at least genus level
my $classified_to_at_least_family = $ARGV[3]; # if 1, requires output matches to be classified to at least family level
my $min_mean_percent_identity = $ARGV[4]; # requires output matches to have at least this mean % identity
my $max_mean_percent_identity = $ARGV[5]; # requires output matches to have at most this mean % identity
my $min_mean_query_coverage = $ARGV[6]; # requires output matches to have at least this mean % query coverage
my $max_mean_query_coverage = $ARGV[7]; # requires output matches to have at most this mean % query coverage


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";

# blast LCA table
my $sequence_name_column = 0;
my $LCA_taxon_id_column = 1;
my $LCA_taxon_rank_column = 2;
my $LCA_taxon_species_column = 3;
my $LCA_taxon_genus_column = 4;
my $LCA_taxon_family_column = 5;
my $evalue_of_top_hits_column = 6;
my $lowest_pident_of_top_hits_column = 7;
my $mean_pident_of_top_hits_column = 8;
my $highest_pident_of_top_hits_column = 9;
my $lowest_qcovs_of_top_hits_column = 10;
my $mean_qcovs_of_top_hits_column = 11;
my $highest_qcovs_of_top_hits_column = 12;
my $number_top_hits_column = 13;


# verifies that all input files exist and are non-empty
if(!$LCA_matches or !-e $LCA_matches or -z $LCA_matches)
{
	print STDERR "Error: LCA matches file not provided, does not exist, or empty:\n\t"
		.$LCA_matches."\nExiting.\n";
	die;
}


# reads in and filters LCA matches
my $first_row = 1;
open LCA_MATCHES, "<$LCA_matches" || die "Could not open $LCA_matches to read\n";
while(<LCA_MATCHES>)
{
	chomp;
	my $line = $_;
	if($line =~ /\S/)
	{
		if($first_row)
		{
			# prints header line as is
			print $line.$NEWLINE;
			$first_row = 0;
		}
		else
		{
			# reads in relevant lines in row
			my @items = split($DELIMITER, $line);
			my $species = $items[$LCA_taxon_species_column];
			my $genus = $items[$LCA_taxon_genus_column];
			my $family = $items[$LCA_taxon_family_column];
			my $mean_percent_identity = $items[$mean_pident_of_top_hits_column];
			my $mean_query_coverage = $items[$mean_qcovs_of_top_hits_column];
		
			# determines whether or not this row should be printed
			my $row_passes_thresholds = 1;
			if($classified_to_at_least_species
				and (!$species or $species eq $NO_DATA))
			{
				$row_passes_thresholds = 0;
			}
			if($classified_to_at_least_genus
				and (!$genus or $genus eq $NO_DATA))
			{
				$row_passes_thresholds = 0;
			}
			if($classified_to_at_least_family
				and (!$family or $family eq $NO_DATA))
			{
				$row_passes_thresholds = 0;
			}
			if($mean_percent_identity < $min_mean_percent_identity)
			{
				$row_passes_thresholds = 0;
			}
			if($mean_percent_identity > $max_mean_percent_identity)
			{
				$row_passes_thresholds = 0;
			}
			if($mean_query_coverage < $min_mean_query_coverage)
			{
				$row_passes_thresholds = 0;
			}
			if($mean_query_coverage > $max_mean_query_coverage)
			{
				$row_passes_thresholds = 0;
			}
			
			# prints line if it passes thresholds
			if($row_passes_thresholds)
			{
				print $line.$NEWLINE;
			}
		}
	}
}
close LCA_MATCHES;


# December 28, 2022
