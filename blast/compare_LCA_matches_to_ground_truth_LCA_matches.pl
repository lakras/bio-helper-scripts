#!/usr/bin/env perl

# Compares LCA match taxon from two blast outputs for each match. Uses output of
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

# Output table has one row for each ground truth row, with columns:
# - sequence name
# - test LCA match taxon
# - test LCA match taxon rank
# - test LCA match taxon species
# - test LCA match taxon genus
# - test LCA match taxon family
# - test lowest_pident_of_top_hits
# - test mean_pident_of_top_hits
# - test highest_pident_of_top_hits
# - test lowest_qcovs_of_top_hits
# - test mean_qcovs_of_top_hits
# - test highest_qcovs_of_top_hits
# - test number top hits
# - ground truth LCA match taxon
# - ground truth LCA match taxon rank
# - ground truth LCA match taxon species
# - ground truth LCA match taxon genus
# - ground truth LCA match taxon family
# - ground truth lowest_pident_of_top_hits
# - ground truth mean_pident_of_top_hits
# - ground truth highest_pident_of_top_hits
# - ground truth lowest_qcovs_of_top_hits
# - ground truth mean_qcovs_of_top_hits
# - ground truth highest_qcovs_of_top_hits
# - ground truth number top hits
# - 1 if test and ground truth taxa are identical
# - 1 if test and ground truth taxa are identical at the species level
# - 1 if test and ground truth taxa are identical at the genus level
# - 1 if test and ground truth taxa are identical at the family level
# - 1 if test LCA match taxon is in ground truth LCA match taxon, 0 if not
# - 1 if ground truth LCA match taxon is in test LCA match taxon, 0 if not


# Usage:
# perl compare_LCA_matches_to_ground_truth_LCA_matches.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search, to be treated as ground truth]
# [output of another retrieve_top_blast_hits_LCA_for_each_sequence.pl for another blast search, to compare to ground truth]
# [nodes.dmp file from NCBI]

# Prints to console. To print to file, use
# perl compare_LCA_matches_to_ground_truth_LCA_matches.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search, to be treated as ground truth]
# [output of another retrieve_top_blast_hits_LCA_for_each_sequence.pl for another blast search, to compare to ground truth]
# [nodes.dmp file from NCBI] > [output table]


use strict;
use warnings;


my $ground_truth_LCA_matches = $ARGV[0];
my $LCA_matches_to_test = $ARGV[1];
my $nodes_file = $ARGV[2]; # nodes.dmp file from NCBI: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $TAXONDUMP_DELIMITER = "\t[|]\t"; # nodes.dmp and names.dmp

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

# nodes.dmp and names.dmp
my $TAXONID_COLUMN = 0;	# both
my $PARENTID_COLUMN = 1;	# nodes.dmp
my $RANK_COLUMN = 2;		# nodes.dmp
my $NAMES_COLUMN = 1;		# names.dmp
my $NAME_TYPE_COLUMN = 3;	# names.dmp

# output table
my $YES = "1";
my $NO = "0";

# if 1, prints available information for sequences in the test file even if those
# sequences do not appear in the ground truth file (but prints an error)
# if 0, only prints sequences that appear in both files
my $PRINT_TEST_SEQUENCES_WITHOUT_GROUND_TRUTH = 0;


# verifies that all input files exist and are non-empty
if(!$nodes_file or !-e $nodes_file or -z $nodes_file)
{
	print STDERR "Error: nodes.dmp file not provided, does not exist, or empty:\n\t"
		.$nodes_file."\nExiting.\n";
	die;
}
if(!$ground_truth_LCA_matches or !-e $ground_truth_LCA_matches or -z $ground_truth_LCA_matches)
{
	print STDERR "Error: ground truth LCA matches file not provided, does not exist, or empty:\n\t"
		.$ground_truth_LCA_matches."\nExiting.\n";
	die;
}
if(!$LCA_matches_to_test or !-e $LCA_matches_to_test or -z $LCA_matches_to_test)
{
	print STDERR "Error: LCA matches to test file not provided, does not exist, or empty:\n\t"
		.$LCA_matches_to_test."\nExiting.\n";
	die;
}


# reads in nodes file
my %taxonid_to_parent = (); # key: taxon id -> value: taxon id of parent taxon
my %taxonid_to_rank = (); # key: taxon id -> value: rank of taxon
open NODES_FILE, "<$nodes_file" || die "Could not open $nodes_file to read\n";
while(<NODES_FILE>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($TAXONDUMP_DELIMITER, $_);
		my $taxonid = $items[$TAXONID_COLUMN];
		my $parent_taxonid = $items[$PARENTID_COLUMN];
		my $rank = $items[$RANK_COLUMN];
		
		$taxonid_to_parent{$taxonid} = $parent_taxonid;
		$taxonid_to_rank{$taxonid} = $rank;
	}
}
close NODES_FILE;


# reads in ground truth file
my %sequence_name_to_true_LCA_taxon_id = ();
my %sequence_name_to_true_LCA_taxon_rank = ();
my %sequence_name_to_true_LCA_taxon_species = ();
my %sequence_name_to_true_LCA_taxon_genus = ();
my %sequence_name_to_true_LCA_taxon_family = ();
my %sequence_name_to_true_lowest_pident_of_top_hits = ();
my %sequence_name_to_true_mean_pident_of_top_hits = ();
my %sequence_name_to_true_highest_pident_of_top_hits = ();
my %sequence_name_to_true_lowest_qcovs_of_top_hits = ();
my %sequence_name_to_true_mean_qcovs_of_top_hits = ();
my %sequence_name_to_true_highest_qcovs_of_top_hits = ();
my %sequence_name_to_true_number_top_hits = ();
my $first_row = 1;
open GROUND_TRUTH, "<$ground_truth_LCA_matches" || die "Could not open $ground_truth_LCA_matches to read\n";
while(<GROUND_TRUTH>)
{
	chomp;
	if($_ =~ /\S/ and !$first_row)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$sequence_name_column];
		
		$sequence_name_to_true_LCA_taxon_id{$sequence_name} = $items[$LCA_taxon_id_column];
		$sequence_name_to_true_LCA_taxon_rank{$sequence_name} = $items[$LCA_taxon_rank_column];
		$sequence_name_to_true_LCA_taxon_species{$sequence_name} = $items[$LCA_taxon_species_column];
		$sequence_name_to_true_LCA_taxon_genus{$sequence_name} = $items[$LCA_taxon_genus_column];
		$sequence_name_to_true_LCA_taxon_family{$sequence_name} = $items[$LCA_taxon_family_column];
		$sequence_name_to_true_lowest_pident_of_top_hits{$sequence_name} = $items[$lowest_pident_of_top_hits_column];
		$sequence_name_to_true_mean_pident_of_top_hits{$sequence_name} = $items[$mean_pident_of_top_hits_column];
		$sequence_name_to_true_highest_pident_of_top_hits{$sequence_name} = $items[$highest_pident_of_top_hits_column];
		$sequence_name_to_true_lowest_qcovs_of_top_hits{$sequence_name} = $items[$lowest_qcovs_of_top_hits_column];
		$sequence_name_to_true_mean_qcovs_of_top_hits{$sequence_name} = $items[$mean_qcovs_of_top_hits_column];
		$sequence_name_to_true_highest_qcovs_of_top_hits{$sequence_name} = $items[$highest_qcovs_of_top_hits_column];
		$sequence_name_to_true_number_top_hits{$sequence_name} = $items[$number_top_hits_column];
	}
	$first_row = 0;
}
close GROUND_TRUTH;


# prints output table column titles
print "sequence_name".$DELIMITER;

print "test_LCA_match_taxon".$DELIMITER;
print "test_LCA_match_taxon_rank".$DELIMITER;
print "test_LCA_match_taxon_species".$DELIMITER;
print "test_LCA_match_taxon_genus".$DELIMITER;
print "test_LCA_match_taxon_family".$DELIMITER;
print "test_lowest_pident_of_top_hits".$DELIMITER;
print "test_mean_pident_of_top_hits".$DELIMITER;
print "test_highest_pident_of_top_hits".$DELIMITER;
print "test_lowest_qcovs_of_top_hits".$DELIMITER;
print "test_mean_qcovs_of_top_hits".$DELIMITER;
print "test_highest_qcovs_of_top_hits".$DELIMITER;
print "test_number_top_hits".$DELIMITER;

print "ground_truth_LCA_match_taxon".$DELIMITER;
print "ground_truth_LCA_match_taxon_rank".$DELIMITER;
print "ground_truth_LCA_match_taxon_species".$DELIMITER;
print "ground_truth_LCA_match_taxon_genus".$DELIMITER;
print "ground_truth_LCA_match_taxon_family".$DELIMITER;
print "ground_truth_lowest_pident_of_top_hits".$DELIMITER;
print "ground_truth_mean_pident_of_top_hits".$DELIMITER;
print "ground_truth_highest_pident_of_top_hits".$DELIMITER;
print "ground_truth_lowest_qcovs_of_top_hits".$DELIMITER;
print "ground_truth_mean_qcovs_of_top_hits".$DELIMITER;
print "ground_truth_highest_qcovs_of_top_hits".$DELIMITER;
print "ground_truth_number_top_hits".$DELIMITER;

print "test_and_ground_truth_taxa_identical".$DELIMITER;
print "test_and_ground_truth_taxa_identical_at_species_level".$DELIMITER;
print "test_and_ground_truth_taxa_identical_at_genus_level".$DELIMITER;
print "test_and_ground_truth_taxa_identical_at_family_level".$DELIMITER;
print "test_LCA_match_taxon_in_ground_truth_LCA_match_taxon".$DELIMITER;
print "ground_truth_LCA_match_taxon_in_test_LCA_match_taxon".$NEWLINE;


# reads in test file and prints output
$first_row = 1;
my %ground_truth_sequence_has_test_match = (); # key: sequence name appearing in ground truth file -> value: 1 if sequence name also appears in test file
open TEST, "<$LCA_matches_to_test" || die "Could not open $LCA_matches_to_test to read\n";
while(<TEST>)
{
	chomp;
	if($_ =~ /\S/ and !$first_row)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$sequence_name_column];
		$ground_truth_sequence_has_test_match{$sequence_name} = 1;
	
		if($sequence_name_to_true_number_top_hits{$sequence_name}
			or $PRINT_TEST_SEQUENCES_WITHOUT_GROUND_TRUTH)
		{
			# print sequence name
			print $sequence_name.$DELIMITER;
		
			# print details of LCA match to compare to ground truth
			print $items[$LCA_taxon_id_column].$DELIMITER;
			print $items[$LCA_taxon_rank_column].$DELIMITER;
			print $items[$LCA_taxon_species_column].$DELIMITER;
			print $items[$LCA_taxon_genus_column].$DELIMITER;
			print $items[$LCA_taxon_family_column].$DELIMITER;
			print $items[$lowest_pident_of_top_hits_column].$DELIMITER;
			print $items[$mean_pident_of_top_hits_column].$DELIMITER;
			print $items[$highest_pident_of_top_hits_column].$DELIMITER;
			print $items[$lowest_qcovs_of_top_hits_column].$DELIMITER;
			print $items[$mean_qcovs_of_top_hits_column].$DELIMITER;
			print $items[$highest_qcovs_of_top_hits_column].$DELIMITER;
			print $items[$number_top_hits_column].$DELIMITER;
		}
		
		# print details of ground truth LCA match
		if($sequence_name_to_true_number_top_hits{$sequence_name})
		{
			print $sequence_name_to_true_LCA_taxon_id{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_LCA_taxon_rank{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_LCA_taxon_species{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_LCA_taxon_genus{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_LCA_taxon_family{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_lowest_pident_of_top_hits{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_mean_pident_of_top_hits{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_highest_pident_of_top_hits{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_lowest_qcovs_of_top_hits{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_mean_qcovs_of_top_hits{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_highest_qcovs_of_top_hits{$sequence_name}.$DELIMITER;
			print $sequence_name_to_true_number_top_hits{$sequence_name}.$DELIMITER;
			
			# print columns comparing LCA match to ground truth
			# 1 if test and ground truth taxa are identical
			if($items[$LCA_taxon_id_column] ne $NO_DATA
				and $sequence_name_to_true_LCA_taxon_id{$sequence_name} ne $NO_DATA
				and $items[$LCA_taxon_id_column]
					== $sequence_name_to_true_LCA_taxon_id{$sequence_name})
			{
				print $YES.$DELIMITER;
			}
			else
			{
				print $NO.$DELIMITER;
			}
			
			# 1 if test and ground truth taxa are identical at the species level
			if($items[$LCA_taxon_species_column] ne $NO_DATA
				and $sequence_name_to_true_LCA_taxon_species{$sequence_name} ne $NO_DATA
				and $items[$LCA_taxon_species_column]
					== $sequence_name_to_true_LCA_taxon_species{$sequence_name})
			{
				print $YES.$DELIMITER;
			}
			else
			{
				print $NO.$DELIMITER;
			}
			
			# 1 if test and ground truth taxa are identical at the genus level
			if($items[$LCA_taxon_genus_column] ne $NO_DATA
				and $sequence_name_to_true_LCA_taxon_genus{$sequence_name} ne $NO_DATA
				and $items[$LCA_taxon_genus_column]
					== $sequence_name_to_true_LCA_taxon_genus{$sequence_name})
			{
				print $YES.$DELIMITER;
			}
			else
			{
				print $NO.$DELIMITER;
			}
			
			# 1 if test and ground truth taxa are identical at the family level
			if($items[$LCA_taxon_family_column] ne $NO_DATA
				and $sequence_name_to_true_LCA_taxon_family{$sequence_name} ne $NO_DATA
				and $items[$LCA_taxon_family_column]
					== $sequence_name_to_true_LCA_taxon_family{$sequence_name})
			{
				print $YES.$DELIMITER;
			}
			else
			{
				print $NO.$DELIMITER;
			}
			
			# retrieves taxon paths of test and ground truth LCA matches
			
			
			
			my $test_taxon_id = $items[$LCA_taxon_id_column];
			my %taxon_id_is_in_test_LCA_taxon_path = ();
			$taxon_id_is_in_test_LCA_taxon_path{$test_taxon_id} = 1;
			$taxon_id_is_in_test_LCA_taxon_path{1} = 1;
			
			my $ground_truth_taxon_id = $sequence_name_to_true_LCA_taxon_id{$sequence_name};
			my %taxon_id_is_in_ground_truth_LCA_taxon_path = ();
			$taxon_id_is_in_ground_truth_LCA_taxon_path{$ground_truth_taxon_id} = 1;
			$taxon_id_is_in_ground_truth_LCA_taxon_path{1} = 1;
			
			while($taxonid_to_parent{$ground_truth_taxon_id}
				and $taxonid_to_parent{$ground_truth_taxon_id} != $ground_truth_taxon_id)
			{
				$taxon_id_is_in_ground_truth_LCA_taxon_path{$ground_truth_taxon_id} = 1;
				$ground_truth_taxon_id = $taxonid_to_parent{$ground_truth_taxon_id};
			}
			
			while($taxonid_to_parent{$test_taxon_id}
				and $taxonid_to_parent{$test_taxon_id} != $test_taxon_id)
			{
				$taxon_id_is_in_test_LCA_taxon_path{$test_taxon_id} = 1;
				$test_taxon_id = $taxonid_to_parent{$test_taxon_id};
			}
			
			# print 1 if test LCA match taxon is in ground truth LCA match taxon, 0 if not
			if($taxon_id_is_in_ground_truth_LCA_taxon_path{$items[$LCA_taxon_id_column]})
			{
				print $YES;
			}
			else
			{
				print $NO;
			}
			print $DELIMITER;
			
			# print 1 if ground truth LCA match taxon is in test LCA match taxon, 0 if not
			if($sequence_name_to_true_LCA_taxon_id{$sequence_name})
			{
				print $YES;
			}
			else
			{
				print $NO;
			}
			print $NEWLINE;
		}
		elsif($PRINT_TEST_SEQUENCES_WITHOUT_GROUND_TRUTH)
		{
			print STDERR "Error: sequence name ".$sequence_name." does not appear in "
				."ground truth LCA matches file.\n";
				
			# print empty output columns for missing columns
			my $number_empty_columns_to_print = 18;
			for(my $column = 0; $column < $number_empty_columns_to_print; $column++)
			{
				print $DELIMITER;
			}
			print $NEWLINE;
		}
	}
	$first_row = 0;
}
close TEST;


# prints ground truth sequences not appearing in test sequence
foreach my $sequence_name(keys %sequence_name_to_true_number_top_hits)
{
	if(!$ground_truth_sequence_has_test_match{$sequence_name})
	{
		print $sequence_name.$DELIMITER;
		
		# prints 12 empty columns for test LCA info columns
		my $number_empty_columns_to_print = 12;
		for(my $column = 0; $column < $number_empty_columns_to_print; $column++)
		{
			print $DELIMITER;
		}
		
		# prints ground truth info
		print $sequence_name_to_true_LCA_taxon_id{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_LCA_taxon_rank{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_LCA_taxon_species{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_LCA_taxon_genus{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_LCA_taxon_family{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_lowest_pident_of_top_hits{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_mean_pident_of_top_hits{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_highest_pident_of_top_hits{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_lowest_qcovs_of_top_hits{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_mean_qcovs_of_top_hits{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_highest_qcovs_of_top_hits{$sequence_name}.$DELIMITER;
		print $sequence_name_to_true_number_top_hits{$sequence_name}.$NEWLINE;
	}
}


# November 4, 2022
