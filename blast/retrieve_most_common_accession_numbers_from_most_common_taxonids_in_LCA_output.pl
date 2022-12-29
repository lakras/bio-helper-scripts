#!/usr/bin/env perl

# Retrieve most frequent NN accession numbers matched from most frequent NN matched
# species, genera, or families.

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
# perl retrieve_most_common_accession_numbers_from_most_common_taxonids_in_LCA_output.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search]
# [species, genus, or family] [number most frequent matched species, genera, or families to examine]
# [number accession numbers most frequent matched by descendants of most frequent species, genera, or families]

# Prints to console. To print to file, use
# perl retrieve_most_common_accession_numbers_from_most_common_taxonids_in_LCA_output.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search]
# [species, genus, or family] [number most frequent matched species, genera, or families to examine]
# [number accession numbers most frequent matched by descendants of most frequent species, genera, or families]
# > [output list of accession numbers, one per line]

use strict;
use warnings;


my $LCA_matches = $ARGV[0]; # output of retrieve_top_blast_hits_LCA_for_each_sequence.pl
my $minimum_rank_of_taxa_to_examine = $ARGV[1]; # species, genus, or family
my $number_most_frequent_matched_taxa = $ARGV[2];
my $number_most_frequent_matched_accession_numbers = $ARGV[3];


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $MATCHED_ACCESSION_NUMBERS_DELIMITER = ",";
my $OUTPUT_ACCESSION_NUMBER_DELIMITER = $NEWLINE; # " ";

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
my $matched_accession_numbers_column = 14;

# in input parameter minimum_rank_of_taxa_to_examine
my $SPECIES = "species";
my $GENUS = "genus";
my $FAMILY = "family";


# verifies that inputs exist and are non-empty
if(!$LCA_matches or !-e $LCA_matches or -z $LCA_matches)
{
	print STDERR "Error: LCA matches file not provided, does not exist, or empty:\n\t"
		.$LCA_matches."\nExiting.\n";
	die;
}
if(!$minimum_rank_of_taxa_to_examine)
{
	print STDERR "Error: No minimum rank to examine provided. Must be species, genus, or "
		."family.\nExiting.\n";
	die;
}
if($minimum_rank_of_taxa_to_examine ne $SPECIES
	and $minimum_rank_of_taxa_to_examine ne $GENUS
	and $minimum_rank_of_taxa_to_examine ne $FAMILY)
{
	print STDERR "Error: Non-valid minimum rank to examine provided. Must be species, ".
		"genus, or family.\nExiting.\n";
	die;
}


# reads in species, genera, or families of matched taxon ids and their accession numbers
my %taxon_id_to_number_matches = (); # key: species-, genus-, or family-level ancestor of each taxon id matched -> number sequences matched
my %taxon_id_to_matched_accession_numbers = (); # key: species-, genus-, or family-level ancestor of each taxon id matched -> accession numbers matched by taxon or its descendants
my $first_row = 1;
open LCA_MATCHES, "<$LCA_matches" || die "Could not open $LCA_matches to read\n";
while(<LCA_MATCHES>)
{
	chomp;
	if($_ =~ /\S/ and !$first_row)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$sequence_name_column];
		my $species = $items[$LCA_taxon_species_column];;
		my $genus = $items[$LCA_taxon_genus_column];
		my $family = $items[$LCA_taxon_family_column];
		my $matched_accession_numbers = $items[$matched_accession_numbers_column];
		
		# determines ancestor taxon id
		my $ancestor_taxon_id = "";
		if($minimum_rank_of_taxa_to_examine eq $SPECIES
			and $species and $species ne $NO_DATA)
		{
			$ancestor_taxon_id = $species;
		}
		if($minimum_rank_of_taxa_to_examine eq $GENUS
			and $genus and $genus ne $NO_DATA)
		{
			$ancestor_taxon_id = $genus;
		}
		if($minimum_rank_of_taxa_to_examine eq $FAMILY
			and $family and $family ne $NO_DATA)
		{
			$ancestor_taxon_id = $family;
		}
		
		# increments number matches for this ancestor taxon id
		$taxon_id_to_number_matches{$ancestor_taxon_id} = $taxon_id_to_number_matches{$ancestor_taxon_id} + 1;
		
		# saves matched accession numbers
		if($taxon_id_to_matched_accession_numbers{$ancestor_taxon_id})
		{
			$taxon_id_to_matched_accession_numbers{$ancestor_taxon_id} = $taxon_id_to_matched_accession_numbers{$ancestor_taxon_id}.$MATCHED_ACCESSION_NUMBERS_DELIMITER;
		}
		$taxon_id_to_matched_accession_numbers{$ancestor_taxon_id} = $taxon_id_to_matched_accession_numbers{$ancestor_taxon_id}.$matched_accession_numbers;
	}
	$first_row = 0;
}
close LCA_MATCHES;


# retrieves accession numbers matched by most frequently matched ancestor taxon ids
my %accession_number_to_number_matches = (); # key: accession number matched by descendant of a top species, genus, or family -> number times it is matched
my $number_matched_taxon_ids_examined = 0;
foreach my $matched_taxon_id(
	sort {$taxon_id_to_number_matches{$b} <=> $taxon_id_to_number_matches{$a}}
	keys %taxon_id_to_number_matches)
{
	if($number_matched_taxon_ids_examined < $number_most_frequent_matched_taxa)
	{
		# retrieves accession numbers matched by this ancestor taxon id
		foreach my $matched_accession_number(split($MATCHED_ACCESSION_NUMBERS_DELIMITER, $taxon_id_to_matched_accession_numbers{$matched_taxon_id}))
		{
			if($matched_accession_number and $matched_accession_number ne $NO_DATA)
			{
				$accession_number_to_number_matches{$matched_accession_number} = $accession_number_to_number_matches{$matched_accession_number} + 1;
			}
		}
	}
	$number_matched_taxon_ids_examined++;
}


# retrieves top accession numbers
my $number_accession_numbers_examined = 0;
foreach my $matched_accession_number(
	sort {$accession_number_to_number_matches{$b} <=> $accession_number_to_number_matches{$a}}
	keys %accession_number_to_number_matches)
{
	if($number_accession_numbers_examined < $number_most_frequent_matched_accession_numbers)
	{
		# prints accession number
		print $matched_accession_number.$OUTPUT_ACCESSION_NUMBER_DELIMITER;
	}
	$number_accession_numbers_examined++;
}


# December 27, 2022
