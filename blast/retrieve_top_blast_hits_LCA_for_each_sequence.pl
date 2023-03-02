#!/usr/bin/env perl

# For each sequence, extracts all top hits with same e-values (assumes they are in order
# in blast output). Prints lowest common ancestor (LCA) of top hits for each sequence.

# Input nodes.dmp file must be from same date as database used for input blast search
# results.

# Output table has columns (tab-separated):
# - sequence name
# - LCA taxon id
# - LCA taxon rank
# - LCA taxon species
# - LCA taxon genus
# - LCA taxon family
# - evalue of top hits
# - lowest pident of top hits
# - mean pident of top hits
# - highest pident of top hits
# - lowest qcovs of top hits
# - mean qcovs of top hits
# - highest qcovs of top hits
# - number top hits
# - accession numbers matched in top hits, in comma-separated list

# Usage:
# perl retrieve_top_blast_hits_LCA_for_each_sequence.pl [blast output]
# [nodes.dmp file from NCBI]
# [number by which to multiply sequence's top evalue, to use as threshold for inclusion in LCA]
# [1 to print all matched accession numbers in a final column]
# [1 to treat blast output as modified DIAMOND output]

# Prints to console. To print to file, use
# perl retrieve_top_blast_hits_LCA_for_each_sequence.pl [blast output]
# [nodes.dmp file from NCBI] 
# [number by which to multiply sequence's top evalue, to use as threshold for inclusion in LCA]
# [1 to print all matched accession numbers in a final column]
# [1 to treat blast output as modified DIAMOND output] > [output table]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $nodes_file = $ARGV[1]; # nodes.dmp file from NCBI: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
my $top_evalue_multiplier_for_inclusion_threshold = $ARGV[2]; # LCA is performed on all hits with e-value less than or equal to this value * top e-value; set to 1 by default, to include only top e-value
my $print_matched_taxon_ids = $ARGV[3]; # if 1, prints all accession numbers matched by top hits in a final column
my $is_diamond_output = $ARGV[4]; # if 1, treats input file with blast output as modified DIAMOND output; format: qseqid stitle (part 1: accession number) stitle (part 2: sequence name) taxonid qlen slen length pident qcovhsp evalue


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $TAXONDUMP_DELIMITER = "\t[|]\t"; # nodes.dmp and names.dmp
my $TAXONID_SEPARATOR = ";"; # in blast file


# default value of top_evalue_multiplier_for_inclusion_threshold
my $DEFAULT_TOP_EVALUE_MULTIPLIER = 1;

# blast file
my $SEQUENCE_NAME_COLUMN_BLAST = 0; 	# qseqid
my $MATCHED_ACCESSION_NUMBER_COLUMN_BLAST = 1; # sacc
my $MATCHED_TAXONID_COLUMN_BLAST = 3;	# staxids (Subject Taxonomy ID(s), separated by a ';')
my $PERCENT_ID_COLUMN_BLAST = 9; 		# pident
my $QUERY_COVERAGE_COLUMN_BLAST = 10;	# qcovs
my $EVALUE_COLUMN_BLAST = 11;			# evalue

# modified DIAMOND output file columns
# format: qseqid stitle (part 1: accession number) stitle (part 2: sequence name) taxonid qlen slen length pident qcovhsp evalue
# Note: sstitle column must first be separated out into two columns, accession number and
# sequence name, and taxon id column must be added
# perl split_column_after_query.pl [DIAMOND output file] 1 " " > [DIAMOND output file with accession number and sequence name in separate columns]
# perl retrieve_taxonids_from_accession_numbers_of_blast_matches_bulk.pl [DIAMOND output file with accession number and sequence name in separate columns] 3 1 prot.accession2taxid.FULL.* > [DIAMOND output file with accession number and sequence name in separate columns, and with taxon id column added]
my $SEQUENCE_NAME_COLUMN_DIAMOND = 0; 			# qseqid
my $MATCHED_ACCESSION_NUMBER_COLUMN_DIAMOND = 1; # sacc
my $MATCHED_TAXONID_COLUMN_DIAMOND = 3;			# staxids (Subject Taxonomy ID(s), separated by a ';')
my $PERCENT_ID_COLUMN_DIAMOND = 7; 				# pident
my $QUERY_COVERAGE_COLUMN_DIAMOND = 8;			# qcovs
my $EVALUE_COLUMN_DIAMOND = 9;					# evalue

# nodes.dmp and names.dmp
my $TAXONID_COLUMN = 0;	# both
my $PARENTID_COLUMN = 1;	# nodes.dmp
my $RANK_COLUMN = 2;		# nodes.dmp
my $NAMES_COLUMN = 1;		# names.dmp
my $NAME_TYPE_COLUMN = 3;	# names.dmp

my $SPECIES = "species";
my $GENUS = "genus";
my $FAMILY = "family";
my $ROOT_TAXON_ID = 1;

# 1 to print top blast hits to STDERR (for testing)
my $PRINT_TOP_BLAST_HITS_TO_STDERR = 0;
my $LOUD = 0;


# sets e-value multiplier for inclusion threshold
if(!$top_evalue_multiplier_for_inclusion_threshold)
{
	$top_evalue_multiplier_for_inclusion_threshold = $DEFAULT_TOP_EVALUE_MULTIPLIER;
}


# determines whether columns should be blast format or modified diamond format
my $sequence_name_column = $SEQUENCE_NAME_COLUMN_BLAST; 	# qseqid
my $matched_accession_number_column = $MATCHED_ACCESSION_NUMBER_COLUMN_BLAST; # sacc
my $matched_taxonid_column = $MATCHED_TAXONID_COLUMN_BLAST;	# staxids (Subject Taxonomy ID(s), separated by a ';')
my $percent_id_column = $PERCENT_ID_COLUMN_BLAST; 			# pident
my $query_coverage_column = $QUERY_COVERAGE_COLUMN_BLAST;	# qcovs
my $evalue_column = $EVALUE_COLUMN_BLAST;					# evalue
if($is_diamond_output)
{
	$sequence_name_column = $SEQUENCE_NAME_COLUMN_DIAMOND; 	# qseqid
	$matched_accession_number_column = $MATCHED_ACCESSION_NUMBER_COLUMN_DIAMOND; # sacc
	$matched_taxonid_column = $MATCHED_TAXONID_COLUMN_DIAMOND;	# staxids (Subject Taxonomy ID(s), separated by a ';')
	$percent_id_column = $PERCENT_ID_COLUMN_DIAMOND; 			# pident
	$query_coverage_column = $QUERY_COVERAGE_COLUMN_DIAMOND;	# qcovs
	$evalue_column = $EVALUE_COLUMN_DIAMOND;					# evalue
}


# verifies that all input files exist and are non-empty
if(!$nodes_file or !-e $nodes_file or -z $nodes_file)
{
	print STDERR "Error: nodes.dmp file not provided, does not exist, or empty:\n\t"
		.$nodes_file."\nExiting.\n";
	die;
}
if(!$blast_output or !-e $blast_output or -z $blast_output)
{
	print STDERR "Error: blast output not provided, does not exist, or empty:\n\t"
		.$blast_output."\nExiting.\n";
	die;
}


# reads in nodes file
print STDERR "reading in nodes file....\n" if $LOUD;
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


# reads in blast output and extracts top blast hits for each sequence
print STDERR "processing blast output....\n" if $LOUD;
open BLAST_OUTPUT, "<$blast_output" || die "Could not open $blast_output to read\n";

my $previous_sequence_name = "";
my $is_top_evalue = 1;
my $sequence_top_evalue = -1;
my %taxon_id_is_in_current_LCA_taxon_path = (); # key: taxon id -> value: 1 if taxon is in taxon path of current LCA

my %sequence_name_to_top_hits_LCA_taxon_id = (); # key: sequence name -> value: current taxon id of LCA of top hits' taxa
my %sequence_name_to_min_top_hit_pident = (); # key: sequence name -> value: lowest pident of top hits
my %sequence_name_to_max_top_hit_pident = (); # key: sequence name -> value: highest pident of top hits
my %sequence_name_to_min_top_hit_qcovs = (); # key: sequence name -> value: lowest qcovs of top hits
my %sequence_name_to_max_top_hit_qcovs = (); # key: sequence name -> value: highest qcovs of top hits
my %sequence_name_to_number_top_hits = (); # key: sequence name -> value: number top hits
my %sequence_name_to_sum_top_hits_pident = (); # key: sequence name -> value: sum of top hits pident
my %sequence_name_to_sum_top_hits_qcovs = (); # key: sequence name -> value: sum of top hits qcovs
my %sequence_name_to_top_hits_evalue = (); # key: sequence name -> value: e-value of top hits
my %sequence_name_to_accession_number_matched = (); # key: sequence name -> key: accession number -> value: 1

my %printed_error_for_taxon_id = (); # key: taxon id -> value: 1 if we've already printed an error for this taxon id
while(<BLAST_OUTPUT>)
{
	chomp;
	my $line = $_;
	if($line =~ /\S/)
	{
# 		print STDERR $_."\n";
		
		my @items = split($DELIMITER, $line);
		my $sequence_name = $items[$sequence_name_column];
		my $matched_accession_number = $items[$matched_accession_number_column];
		my $matched_taxon_id_as_provided = $items[$matched_taxonid_column];
		my $percent_id = $items[$percent_id_column];
		my $query_coverage = $items[$query_coverage_column];
		my $evalue = $items[$evalue_column];
		
		# saves matched taxon id(s)
		$sequence_name_to_accession_number_matched{$sequence_name}{$matched_accession_number} = 1;
		
		# if multiple matched taxon ids listed, handles each taxon id separately
		my @matched_taxon_ids = split($TAXONID_SEPARATOR, $matched_taxon_id_as_provided);
		
		# collects matched taxon ids and removes NA matched taxon ids
		my %matched_taxon_ids_set = ();
		foreach my $matched_taxon_id(@matched_taxon_ids)
		{
			if($matched_taxon_id ne $NO_DATA)
			{
				$matched_taxon_ids_set{$matched_taxon_id} = 1;
			}
		}
		@matched_taxon_ids = keys %matched_taxon_ids_set;
		
		# processes matched taxon ids
		foreach my $matched_taxon_id(@matched_taxon_ids)
		{
			# new sequence, so the first match has lowest e-value
			if($sequence_name ne $previous_sequence_name)
			{
				if($PRINT_TOP_BLAST_HITS_TO_STDERR)
				{
					print STDERR $_;
					print STDERR $NEWLINE;
				}
				$is_top_evalue = 1;
				$sequence_top_evalue = $evalue;
				%taxon_id_is_in_current_LCA_taxon_path = ();
			}
		
			# not first match for this sequence, but the e-value is the same as the e-value
			# of the first match for this sequence
			elsif($is_top_evalue and $evalue <= $sequence_top_evalue
				* $top_evalue_multiplier_for_inclusion_threshold)
			{
				if($PRINT_TOP_BLAST_HITS_TO_STDERR)
				{
					print STDERR $_;
					print STDERR $NEWLINE;
				}
			}
		
			# not same e-value as first match for this sequence
			else
			{
				$is_top_evalue = 0;
			}
			
			# verifies that we can trace full ancestry of this taxon id
			my $can_trace_taxon_id_ancestry = 1;
			if($is_top_evalue)
			{
				my $matched_taxon_id_ancestor = $matched_taxon_id;
				while($can_trace_taxon_id_ancestry
					and $matched_taxon_id_ancestor ne $ROOT_TAXON_ID)
				{
					if(defined $taxonid_to_parent{$matched_taxon_id_ancestor})
					{
						$matched_taxon_id_ancestor = $taxonid_to_parent{$matched_taxon_id_ancestor};
					}
					else
					{
						$can_trace_taxon_id_ancestry = 0;
					}
				}
			}
			if(!$can_trace_taxon_id_ancestry and !$printed_error_for_taxon_id{$matched_taxon_id})
			{
				print STDERR "Error: could not trace ancestry of taxon id "
					.$matched_taxon_id." in taxon path of matched taxon id in hit:\n"
						.$line."\n";
				$printed_error_for_taxon_id{$matched_taxon_id} = 1;
			}
		
			# processes this hit if it is a top hit for this sequence and we can track its
			# ancestry
			if($is_top_evalue and $can_trace_taxon_id_ancestry)
			{
				# updates percent identity, percent coverage, and e-value stats
				if($sequence_name ne $previous_sequence_name
					or $percent_id < $sequence_name_to_min_top_hit_pident{$sequence_name})
				{
					$sequence_name_to_min_top_hit_pident{$sequence_name} = $percent_id;
				}
				if($sequence_name ne $previous_sequence_name
					or $percent_id > $sequence_name_to_max_top_hit_pident{$sequence_name})
				{
					$sequence_name_to_max_top_hit_pident{$sequence_name} = $percent_id;
				}
				if($sequence_name ne $previous_sequence_name
					or $query_coverage < $sequence_name_to_min_top_hit_qcovs{$sequence_name})
				{
					$sequence_name_to_min_top_hit_qcovs{$sequence_name} = $query_coverage;
				}
				if($sequence_name ne $previous_sequence_name
					or $query_coverage > $sequence_name_to_max_top_hit_qcovs{$sequence_name})
				{
					$sequence_name_to_max_top_hit_qcovs{$sequence_name} = $query_coverage;
				}
				$sequence_name_to_number_top_hits{$sequence_name}++;
				$sequence_name_to_sum_top_hits_pident{$sequence_name} += $percent_id;
				$sequence_name_to_sum_top_hits_qcovs{$sequence_name} += $query_coverage;
				$sequence_name_to_top_hits_evalue{$sequence_name} = $evalue;
			
				# updates LCA taxon id
				my $taxon_id_updated = 0;
				if($sequence_name ne $previous_sequence_name)
				{
					# if this is the first top hit we've seen for this sequence, this hit's
					# taxon id is the LCA taxon id so far
					$sequence_name_to_top_hits_LCA_taxon_id{$sequence_name} = $matched_taxon_id;
					$taxon_id_updated = 1;
				}
				else
				{
					# slowly move up new taxon id's path
					# at each step, check if ancestor taxon id is in current LCA's path
					# once the answer is yes, that is our new LCA
					my $LCA_found = 0;
					my $matched_taxon_id_ancestor = $matched_taxon_id;
					while(!$LCA_found)
					{
						# if taxon id is root (1), then the LCA is root (1)
						if($matched_taxon_id_ancestor == $ROOT_TAXON_ID)
						{
							$LCA_found = 1;
							$sequence_name_to_top_hits_LCA_taxon_id{$sequence_name} = $ROOT_TAXON_ID;
						}
						
						# verifies that if taxon id is not root, then it has a non-root parent
						elsif($matched_taxon_id_ancestor == $taxonid_to_parent{$matched_taxon_id_ancestor})
						{
							print STDERR "Error: taxon id is not root but has itself as parent: "
								.$matched_taxon_id_ancestor.". Exiting.\n";
							die;
						}
					
						# check if taxon id is in path of current LCA
						# if so, new LCA is taxon id
						elsif($taxon_id_is_in_current_LCA_taxon_path{$matched_taxon_id_ancestor})
						{
							$LCA_found = 1;
							if($sequence_name_to_top_hits_LCA_taxon_id{$sequence_name} ne $matched_taxon_id_ancestor)
							{
								$sequence_name_to_top_hits_LCA_taxon_id{$sequence_name} = $matched_taxon_id_ancestor;
								$taxon_id_updated = 1;
							}
						}
						
						# we have not found the LCA but we are done looking at taxon id
						# in the next loop we will look at its parent
						elsif(defined $taxonid_to_parent{$matched_taxon_id_ancestor})
						{
							$matched_taxon_id_ancestor = $taxonid_to_parent{$matched_taxon_id_ancestor};
						}
						
						# throws error if taxon id does not have a parent
						else
						{
							print STDERR "Error: could not find parent of taxon id "
								.$matched_taxon_id_ancestor
								." in taxon path of matched taxon id in hit:\n".$line
								."\nAssigning LCA taxon for sequence to 1 (root).\n";
							$LCA_found = 1;
							$sequence_name_to_top_hits_LCA_taxon_id{$sequence_name} = $ROOT_TAXON_ID;
						}
					}
				}
		
				# updates taxon path of LCA taxon if we updated the LCA taxon
				if($taxon_id_updated)
				{
					%taxon_id_is_in_current_LCA_taxon_path = ();
					my $taxon_id = $sequence_name_to_top_hits_LCA_taxon_id{$sequence_name};
					$taxon_id_is_in_current_LCA_taxon_path{$taxon_id} = 1;
					while(defined $taxonid_to_parent{$taxon_id}
						and $taxonid_to_parent{$taxon_id} != $taxon_id)
					{
						$taxon_id_is_in_current_LCA_taxon_path{$taxon_id} = 1;
						$taxon_id = $taxonid_to_parent{$taxon_id};
					}
				}
				
				# prepares for next sequence
				$previous_sequence_name = $sequence_name;
			}
		}
	}
}
close BLAST_OUTPUT;


# prints output table column titles
print "sequence_name".$DELIMITER;
print "LCA_taxon_id".$DELIMITER;
print "LCA_taxon_rank".$DELIMITER;
print "LCA_taxon_species".$DELIMITER;
print "LCA_taxon_genus".$DELIMITER;
print "LCA_taxon_family".$DELIMITER;
print "evalue_of_top_hits".$DELIMITER;
print "lowest_pident_of_top_hits".$DELIMITER;
print "mean_pident_of_top_hits".$DELIMITER;
print "highest_pident_of_top_hits".$DELIMITER;
print "lowest_qcovs_of_top_hits".$DELIMITER;
print "mean_qcovs_of_top_hits".$DELIMITER;
print "highest_qcovs_of_top_hits".$DELIMITER;
print "number_top_hits";
if($print_matched_taxon_ids)
{
	print $DELIMITER."matched_accession_numbers";
}
print $NEWLINE;


# prints output table
foreach my $sequence_name(sort keys %sequence_name_to_top_hits_LCA_taxon_id)
{
	# retrieves species, genus, and family of LCA match for this sequence
	my $LCA_match_taxon_id = $sequence_name_to_top_hits_LCA_taxon_id{$sequence_name};
	my $LCA_taxon_species = $NO_DATA;
	my $LCA_taxon_genus = $NO_DATA;
	my $LCA_taxon_family = $NO_DATA;
	
	my $matched_taxon_id_ancestor = $LCA_match_taxon_id;
	do
	{
		if(defined $taxonid_to_rank{$matched_taxon_id_ancestor})
		{
			if($taxonid_to_rank{$matched_taxon_id_ancestor} eq $SPECIES)
			{
				$LCA_taxon_species = $matched_taxon_id_ancestor;
			}
			elsif($taxonid_to_rank{$matched_taxon_id_ancestor} eq $GENUS)
			{
				$LCA_taxon_genus = $matched_taxon_id_ancestor;
			}
			elsif($taxonid_to_rank{$matched_taxon_id_ancestor} eq $FAMILY)
			{
				$LCA_taxon_family = $matched_taxon_id_ancestor;
			}
		}
		if(defined $taxonid_to_parent{$matched_taxon_id_ancestor})
		{
			$matched_taxon_id_ancestor = $taxonid_to_parent{$matched_taxon_id_ancestor};
		}
	}
	while(defined $taxonid_to_parent{$matched_taxon_id_ancestor}
		and $taxonid_to_parent{$matched_taxon_id_ancestor} != $matched_taxon_id_ancestor);

	# prints output line for LCA match for this sequence
	print $sequence_name.$DELIMITER;
	print $LCA_match_taxon_id.$DELIMITER;
	if($taxonid_to_rank{$sequence_name_to_top_hits_LCA_taxon_id{$sequence_name}})
	{
		print $taxonid_to_rank{$sequence_name_to_top_hits_LCA_taxon_id{$sequence_name}};
	}
	print $DELIMITER;
	print $LCA_taxon_species.$DELIMITER;
	print $LCA_taxon_genus.$DELIMITER;
	print $LCA_taxon_family.$DELIMITER;
	print $sequence_name_to_top_hits_evalue{$sequence_name}.$DELIMITER;
	print $sequence_name_to_min_top_hit_pident{$sequence_name}.$DELIMITER;
	print $sequence_name_to_sum_top_hits_pident{$sequence_name} / $sequence_name_to_number_top_hits{$sequence_name}.$DELIMITER;
	print $sequence_name_to_max_top_hit_pident{$sequence_name}.$DELIMITER;
	print $sequence_name_to_min_top_hit_qcovs{$sequence_name}.$DELIMITER;
	print $sequence_name_to_sum_top_hits_qcovs{$sequence_name} / $sequence_name_to_number_top_hits{$sequence_name}.$DELIMITER;
	print $sequence_name_to_max_top_hit_qcovs{$sequence_name}.$DELIMITER;
	print $sequence_name_to_number_top_hits{$sequence_name};
	if($print_matched_taxon_ids)
	{
		print $DELIMITER;
		print join(",", sort keys %{$sequence_name_to_accession_number_matched{$sequence_name}});
	}
	print $NEWLINE;
}


# November 4, 2022
# December 6, 2022

