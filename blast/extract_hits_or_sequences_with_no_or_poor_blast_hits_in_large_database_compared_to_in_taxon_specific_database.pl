#!/usr/bin/env perl

# Retrieves blast hits or fasta sequences of sequences that produced a blast hit from the
# taxon of interest in a blast search within a database consisting only of sequences from
# the taxon of interest and produced either no hits at all in blast search within large
# database blast search or only hits that were comparable to or worse than hits from
# the blast search in the taxon-specific database.

# Usage:
# perl extract_hits_or_sequences_with_no_or_poor_blast_hits_in_large_database_compared_to_in_taxon_specific_database.pl
# [blast output table from taxon-specific database blast search]
# [blast output table from large database blast search]
# [fasta file that was input to blast for large database blast search]
# [nodes.dmp file from NCBI] [taxon id of taxon of interest]
# [1 to print fasta sequences, 0 to print subset of blast output]

# Prints to console. To print to file, use
# perl extract_hits_or_sequences_with_no_or_poor_blast_hits_in_large_database_compared_to_in_taxon_specific_database.pl
# [blast output table from taxon-specific database blast search]
# [blast output table from large database blast search]
# [fasta file that was input to blast for large database blast search]
# [nodes.dmp file from NCBI] [taxon id of taxon of interest]
# [1 to print fasta sequences, 0 to print subset of blast output] > [output file path]


use strict;
use warnings;


# blast output format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $taxon_database_blast_output = $ARGV[0]; # taxon-specific database blast search results
my $large_database_blast_output = $ARGV[1]; # large database blast search results
my $large_database_search_input_fasta = $ARGV[2]; # fasta sequence entered as input to large database blast search
my $nodes_file = $ARGV[3]; # nodes.dmp file from NCBI: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
my $taxon_of_interest = $ARGV[4]; # taxon id of taxon of interest, as defined in NCBI taxonomy browser https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi
my $print_fasta_sequences = $ARGV[5]; # if 1, prints fasta file for sequences from taxon of interest; if 0, prints blast hits from both databases for taxon of interest


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $TAXONDUMP_DELIMITER = "\t[|]\t"; # nodes.dmp and names.dmp
my $TAXONID_SEPARATOR = ";"; # in blast file

# blast file
my $SEQUENCE_NAME_COLUMN = 0; 	# qseqid
my $MATCHED_TAXONID_COLUMN = 3;	# staxids (Subject Taxonomy ID(s), separated by a ';')
my $SUPERKINGDOM_COLUMN = 5;	# sskingdoms (Subject Super Kingdom(s), separated by a ';' (in alphabetical order))
my $PERCENT_ID_COLUMN = 9; 		# pident
my $QUERY_COVERAGE_COLUMN = 10;	# qcovs
my $EVALUE_COLUMN = 11;			# evalue

# nodes.dmp
my $TAXONID_COLUMN = 0;
my $PARENTID_COLUMN = 1;
my $RANK_COLUMN = 2;

# maximum number of blast hits to print from each sequence from each database blast search
my $MAX_NUMBER_HITS_TO_PRINT_PER_SEQUENCE = 0;

# a hit is categorized as "good" in the taxon-specific database blast search if it has at least
# multipler * percent identity and percent query coverage of top hit for that sequence
# from the large database blast search 
my $PERCENT_ID_MULTIPLER = 0.90;
my $QUERY_COVERAGE_MULTIPLER = 0.95;


# verifies that all input files exist and are non-empty
if(!$nodes_file or !-e $nodes_file or -z $nodes_file)
{
	print STDERR "Error: nodes.dmp file not provided, does not exist, or empty:\n\t"
		.$nodes_file."\nExiting.\n";
	die;
}
if(!$taxon_database_blast_output or !-e $taxon_database_blast_output
	or -z $taxon_database_blast_output)
{
	print STDERR "Error: taxon-specific database blast output file not provided, does not exist, "
		."or empty:\n\t".$taxon_database_blast_output."\nExiting.\n";
	die;
}
if(!$large_database_blast_output or !-e $large_database_blast_output
	or -z $large_database_blast_output)
{
	print STDERR "Error: large database blast output file not provided, does not exist, "
		."or empty:\n\t".$large_database_blast_output."\nExiting.\n";
	die;
}
if(!$large_database_search_input_fasta or !-e $large_database_search_input_fasta
	or -z $large_database_search_input_fasta)
{
	print STDERR "Error: fasta file not provided, does not exist, or empty:\n\t"
		.$large_database_search_input_fasta."\nExiting.\n";
	die;
}


# reads in nodes file
my %taxonid_to_parent = (); # key: taxon id -> value: taxon id of parent taxon
open NODES_FILE, "<$nodes_file" || die "Could not open $nodes_file to read\n";
while(<NODES_FILE>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($TAXONDUMP_DELIMITER, $_);
		my $taxonid = $items[$TAXONID_COLUMN];
		my $parent_taxonid = $items[$PARENTID_COLUMN];
		
		$taxonid_to_parent{$taxonid} = $parent_taxonid;
	}
}
close NODES_FILE;


# hash tables used in the next few steps
my %all_large_db_search_sequence_names = (); # key: sequence name -> value: 1
my %has_hits_in_large_db_search = (); # key: sequence name -> value: 1 if sequence has any hits in large database seaerch
my %has_taxon_of_interest_hit_in_large_db = (); # key: sequence name -> value: 1 if sequence has taxon of interest hit in large database search
my %large_db_highest_percent_id = (); # key: sequence name -> value: highest %id for that sequence in large database search
my %large_db_highest_percent_qcovs = (); # key: sequence name -> value: highest % query coverage for that sequence in large database search

my %large_db_top_hit_percent_id = (); # key: sequence name -> value: top hit %id for that sequence in large database search
my %large_db_top_hit_percent_qcovs = (); # key: sequence name -> value: top hit % query coverage for that sequence in large database search


# retrieve names of sequences that were input to large database search
open FASTA, "<$large_database_search_input_fasta" || die "Could not open $large_database_search_input_fasta to read; terminating =(\n";
while(<FASTA>) # for each row in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # sequence name
	{
		my $sequence_name = $1;
		$large_db_highest_percent_id{$sequence_name} = 0;
		$large_db_highest_percent_qcovs{$sequence_name} = 0;
		
		$large_db_top_hit_percent_id{$sequence_name} = 0;
		$large_db_top_hit_percent_qcovs{$sequence_name} = 0;
		
		$all_large_db_search_sequence_names{$sequence_name} = 1;
	}
}
close FASTA;


# scans through results of large database search
# identifies sequences that produced no hits
# identifies sequences that produced no hits within taxon of interest
# for sequences with no hits within taxon of interest, determines highest %id and highest % query coverage
open LARGE_DB_BLAST_OUTPUT, "<$large_database_blast_output" || die "Could not open $large_database_blast_output to read\n";
while(<LARGE_DB_BLAST_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($DELIMITER, $_);
		my $sequence_name = $items[$SEQUENCE_NAME_COLUMN];
		my $percent_id = $items[$PERCENT_ID_COLUMN];
		my $query_coverage = $items[$QUERY_COVERAGE_COLUMN];
		my $evalue = $items[$EVALUE_COLUMN];
		my @matched_taxon_ids = split($TAXONID_SEPARATOR, $items[$MATCHED_TAXONID_COLUMN]);
		
		# records hit for this sequence
		$has_hits_in_large_db_search{$sequence_name} = 1;
		if($percent_id > $large_db_highest_percent_id{$sequence_name})
		{
			$large_db_highest_percent_id{$sequence_name} = $percent_id;
		}
		if($query_coverage > $large_db_highest_percent_qcovs{$sequence_name})
		{
			$large_db_highest_percent_qcovs{$sequence_name} = $query_coverage;
		}
		
		if(!$large_db_top_hit_percent_id{$sequence_name})
		{
			$large_db_top_hit_percent_id{$sequence_name} = $percent_id;
		}
		if(!$large_db_top_hit_percent_qcovs{$sequence_name})
		{
			$large_db_top_hit_percent_qcovs{$sequence_name} = $query_coverage;
		}
		
		# traverses full taxon path to check for matched taxon id
		foreach my $matched_taxon_id(@matched_taxon_ids)
		{
			my $matched_taxon_id_ancestor = $matched_taxon_id;
			while(!$has_taxon_of_interest_hit_in_large_db{$sequence_name}
				and $matched_taxon_id_ancestor != 1
				and (!defined $taxonid_to_parent{$matched_taxon_id_ancestor}
					or $matched_taxon_id_ancestor != $taxonid_to_parent{$matched_taxon_id_ancestor}))
			{
				if($matched_taxon_id_ancestor == $taxon_of_interest)
				{
					$has_taxon_of_interest_hit_in_large_db{$sequence_name} = 1;
				}
				if(defined $taxonid_to_parent{$matched_taxon_id_ancestor})
				{
					$matched_taxon_id_ancestor = $taxonid_to_parent{$matched_taxon_id_ancestor};
				}
				else
				{
					print STDERR "Warning: ancestor of taxon id "
						.$matched_taxon_id_ancestor." not found in nodes.dmp file.\n";
					$matched_taxon_id_ancestor = 1;
				}
			}
		}
	}
}
close LARGE_DB_BLAST_OUTPUT;


# scans through taxon-specific database search results
# identifies sequences that have taxon-specific database hit with %id >= 70% of the highest for that
# contig or with % query coverage >= 90% of the highest for that contig in large database search
my %has_good_taxon_database_hit = (); # key: sequence name -> value: 1 if sequence has taxon-specific database hit with %id >= 70% or % query coverage >= 90% of the highest for that contig in large database search
open TAXON_ONLY_BLAST_OUTPUT, "<$taxon_database_blast_output" || die "Could not open $taxon_database_blast_output to read\n";
while(<TAXON_ONLY_BLAST_OUTPUT>)
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
		
		if($has_hits_in_large_db_search{$sequence_name} and !$has_taxon_of_interest_hit_in_large_db{$sequence_name} # haven't previously categorized this sequence
			and !$has_good_taxon_database_hit{$sequence_name}) # haven't already identified this sequence as having good picobirnavirus hit
		{
			if($percent_id >= $PERCENT_ID_MULTIPLER * $large_db_top_hit_percent_id{$sequence_name}
				and $query_coverage >= $QUERY_COVERAGE_MULTIPLER * $large_db_top_hit_percent_qcovs{$sequence_name})
			{
				$has_good_taxon_database_hit{$sequence_name} = 1;
			}
		}
	}
}
close TAXON_ONLY_BLAST_OUTPUT;


# pulls out fasta sequences of interest
if($print_fasta_sequences)
{
	open FASTA, "<$large_database_search_input_fasta" || die "Could not open $large_database_search_input_fasta to read; terminating =(\n";
	my $current_sequence_included = 0;
	while(<FASTA>) # for each line in the file
	{
		chomp;
		if($_ =~ /^>(.*)$/) # sequence name
		{
			my $sequence_name = $1;
			$current_sequence_included = 0;
		
			if((!$has_hits_in_large_db_search{$sequence_name}
					or !$has_taxon_of_interest_hit_in_large_db{$sequence_name})
				and $has_good_taxon_database_hit{$sequence_name})
			{
				$current_sequence_included = 1;
			}
		}
	
		if($current_sequence_included)
		{
			print $_;
			print $NEWLINE;
		}
	}
	close FASTA;
}

# pulls out taxon-specific database blast results for sequences of interest
if(!$print_fasta_sequences)
{
	my %number_hits_printed = (); # key: sequence name -> value: number blast hits printed
	open TAXON_ONLY_BLAST_OUTPUT, "<$taxon_database_blast_output" || die "Could not open $taxon_database_blast_output to read\n";
	while(<TAXON_ONLY_BLAST_OUTPUT>)
	{
		chomp;
		if($_ =~ /\S/)
		{
			my @items = split($DELIMITER, $_);
			my $sequence_name = $items[$SEQUENCE_NAME_COLUMN];
		
			if($all_large_db_search_sequence_names{$sequence_name}
				and (!$has_hits_in_large_db_search{$sequence_name}
					or !$has_taxon_of_interest_hit_in_large_db{$sequence_name})
				and $has_good_taxon_database_hit{$sequence_name})
			{
				if($MAX_NUMBER_HITS_TO_PRINT_PER_SEQUENCE == 0
					or $number_hits_printed{$sequence_name} < $MAX_NUMBER_HITS_TO_PRINT_PER_SEQUENCE)
				{
					print $_.$DELIMITER.$taxon_of_interest."_database".$NEWLINE;
					$number_hits_printed{$sequence_name}++;
				}
			}
		}
	}
	close TAXON_ONLY_BLAST_OUTPUT;

	# pulls out large database blast results for sequences of interest
	%number_hits_printed = (); # key: sequence name -> value: number blast hits printed
	open LARGE_DB_BLAST_OUTPUT, "<$large_database_blast_output" || die "Could not open $large_database_blast_output to read\n";
	while(<LARGE_DB_BLAST_OUTPUT>)
	{
		chomp;
		if($_ =~ /\S/)
		{
			my @items = split($DELIMITER, $_);
			my $sequence_name = $items[$SEQUENCE_NAME_COLUMN];
		
			if((!$has_hits_in_large_db_search{$sequence_name}
					or !$has_taxon_of_interest_hit_in_large_db{$sequence_name})
				and $has_good_taxon_database_hit{$sequence_name})
			{
				if($MAX_NUMBER_HITS_TO_PRINT_PER_SEQUENCE == 0
					or $number_hits_printed{$sequence_name} < $MAX_NUMBER_HITS_TO_PRINT_PER_SEQUENCE)
				{
					print $_.$DELIMITER."large_database".$NEWLINE;
					$number_hits_printed{$sequence_name}++;
				}
			}
		}
	}
	close LARGE_DB_BLAST_OUTPUT;
}


# October 1, 2020
# January 21, 2022
