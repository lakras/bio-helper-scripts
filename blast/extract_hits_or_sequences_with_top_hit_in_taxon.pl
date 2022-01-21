#!/usr/bin/env perl

# Retrieves blast hits or fasta sequences of sequences with top hit or any hit at all in
# taxon of interest or its children.

# Usage:
# perl extract_hits_or_sequences_with_top_hit_in_taxon.pl [blast output table]
# [fasta file that was input to blast] [nodes.dmp file from NCBI]
# [taxon id of taxon of interest]
# [1 to print fasta sequences, 0 to print subset of blast output]

# Prints to console. To print to file, use
# perl extract_hits_or_sequences_with_top_hit_in_taxon.pl [blast output table]
# [fasta file that was input to blast] [nodes.dmp file from NCBI]
# [taxon id of taxon of interest]
# [1 to print fasta sequences, 0 to print subset of blast output] > [output file path]


use strict;
use warnings;


my $blast_output = $ARGV[0]; # format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $fasta_file = $ARGV[1]; # contains all sequences included in blast output
my $nodes_file = $ARGV[2]; # nodes.dmp file from NCBI: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
my $taxon_of_interest = $ARGV[3]; # taxon id of taxon of interest, as defined in NCBI taxonomy browser https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi
my $print_fasta_sequences = $ARGV[4]; # if 1, prints fasta file for sequences with top hits in taxon of interest; if 0, prints blast hits for sequences with top hits in taxon of interest


my $ONLY_INCLUDE_SEQUENCES_WITH_TOP_HITS_IN_TAXON = 1; # if 1, only includes sequences with a top hit in taxon of interest; if 0, includes sequences with any hit in taxon of interest
my $DEFINE_TOP_HITS_BY_EVALUE = 1; # if 1, defines a top hit using the e-value; if 0, defines a top hit using the percent id and percent query coverage
my $MINIMUM_EVALUE_MULTIPLIER = 10; # sequences are included if a hit within this multiplier of the minimum e-value for a sequence comes from the taxon of interest or its children
my $MAXIMUM_PERCENT_ID_MULTIPLIER = 0.60; # sequences are included if a hit within this multiplier of the maximum percent identity for a sequence comes from the taxon of interest or its children
my $MAXIMUM_PERCENT_QUERY_COVERAGE_MULTIPLIER = 0.90; # sequences are included if a hit within this multiplier of the maximum percent query coverage for a sequence comes from the taxon of interest or its children

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

# nodes.dmp and names.dmp
my $TAXONID_COLUMN = 0;	# both
my $PARENTID_COLUMN = 1;	# nodes.dmp
my $RANK_COLUMN = 2;		# nodes.dmp
my $NAMES_COLUMN = 1;		# names.dmp
my $NAME_TYPE_COLUMN = 3;	# names.dmp


# verifies that all input files exist and are non-empty
if(!$nodes_file or !-e $nodes_file or -z $nodes_file)
{
	print STDERR "Error: nodes.dmp file not provided, does not exist, or empty:\n\t"
		.$nodes_file."\nExiting.\n";
	die;
}
if(!$blast_output or !-e $blast_output or -z $blast_output)
{
	print STDERR "Error: blast output file not provided, does not exist, or empty:\n\t"
		.$blast_output."\nExiting.\n";
	die;
}
if($print_fasta_sequences and (!$fasta_file or !-e $fasta_file or -z $fasta_file))
{
	print STDERR "Error: fasta file not provided, does not exist, or empty:\n\t"
		.$fasta_file."\nExiting.\n";
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


# reads in blast output: retrieves lowest e-value score for each sequence
my %sequence_seen = (); # key: sequence name -> value: 1 if sequence has been seen
my %minimum_evalue = (); # key: sequence name -> value: lowest e-value seen for that sequence
my %max_percent_id = (); # key: sequence name -> value: highest % id for that sequence
my %max_query_coverage = (); # key: sequence name -> value: highest % query coverage for that sequence
if($ONLY_INCLUDE_SEQUENCES_WITH_TOP_HITS_IN_TAXON)
{
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
			
			if(!$sequence_seen{$sequence_name})
			{
				$sequence_seen{$sequence_name} = 1;
				$minimum_evalue{$sequence_name} = $evalue;
				$max_percent_id{$sequence_name} = $percent_id;
				$max_query_coverage{$sequence_name} = $query_coverage;
			}
			else
			{
				if($evalue < $minimum_evalue{$sequence_name})
				{
					$minimum_evalue{$sequence_name} = $evalue;
				}
				if($percent_id > $max_percent_id{$sequence_name})
				{
					$max_percent_id{$sequence_name} = $percent_id;
				}
				if($query_coverage > $max_query_coverage{$sequence_name})
				{
					$max_query_coverage{$sequence_name} = $query_coverage;
				}
			}
		}
	}
	close BLAST_OUTPUT;
}


# reads in blast output: retrieves list of sequences with hits in taxon of interest or descendants
open BLAST_OUTPUT, "<$blast_output" || die "Could not open $blast_output to read\n";
my %sequence_has_blast_hit = (); # key: sequence name -> value: 1 if sequence has been seen
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
		my @matched_taxon_ids = split($TAXONID_SEPARATOR, $items[$MATCHED_TAXONID_COLUMN]);
		
		# traverses full taxon path to check for matched taxon id
		my $matched_taxon_id_is_in_expected_taxon = 0;
		foreach my $matched_taxon_id(@matched_taxon_ids)
		{
			my $matched_taxon_id_ancestor = $matched_taxon_id;
			while(!$matched_taxon_id_is_in_expected_taxon
				and $matched_taxon_id_ancestor != 1
				and (!defined $taxonid_to_parent{$matched_taxon_id_ancestor}
					or $matched_taxon_id_ancestor != $taxonid_to_parent{$matched_taxon_id_ancestor}))
			{
				if($matched_taxon_id_ancestor == $taxon_of_interest)
				{
					$matched_taxon_id_is_in_expected_taxon = 1;
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
		
		# determines whether or not this sequence should be included
		if($matched_taxon_id_is_in_expected_taxon)
		{
			if($ONLY_INCLUDE_SEQUENCES_WITH_TOP_HITS_IN_TAXON) # include only sequences with a top blast hit within taxon of interest
			{
				if($DEFINE_TOP_HITS_BY_EVALUE) # top hits defined by e-value
				{
					if($minimum_evalue{$sequence_name} * $MINIMUM_EVALUE_MULTIPLIER >= $evalue)
					{
						$sequence_has_blast_hit{$sequence_name} = 1;
					}
				}
				else # top hits defined by percent identity and percent query coverage
				{
					if($percent_id >= $MAXIMUM_PERCENT_ID_MULTIPLIER * $max_percent_id{$sequence_name}
						or $query_coverage >= $MAXIMUM_PERCENT_QUERY_COVERAGE_MULTIPLIER * $max_query_coverage{$sequence_name})
					{
						$sequence_has_blast_hit{$sequence_name} = 1;
					}
				}
			}
			else # include all sequences with any blast hit within taxon of interest
			{
				$sequence_has_blast_hit{$sequence_name} = 1;
			}
		}
	}
}
close BLAST_OUTPUT;


# prints hits for sequences that have top hit in taxon of interest
if(!$print_fasta_sequences)
{
	open BLAST_OUTPUT, "<$blast_output" || die "Could not open $blast_output to read\n";
	while(<BLAST_OUTPUT>)
	{
		chomp;
		if($_ =~ /\S/)
		{
			my @items = split($DELIMITER, $_);
			my $sequence_name = $items[$SEQUENCE_NAME_COLUMN];
		
			if($sequence_has_blast_hit{$sequence_name})
			{
				print "$_".$NEWLINE;
			}
		}
	}
	close BLAST_OUTPUT;
}


# reads in fasa file; prints sequences that appeared in the blast output
my %sequence_printed = ();
if($print_fasta_sequences)
{
	open FASTA, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
	my $current_sequence_included = 0;
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
}


# verifies that all expected sequences from blast output have been found in the fasta fiel
foreach my $sequence_name(keys %sequence_has_blast_hit)
{
	if($sequence_has_blast_hit{$sequence_name} and !$sequence_printed{$sequence_name})
	{
		print STDERR "Error: sequence ".$sequence_name." seen in blast output but not fasta.\n";
	}
}


# August 25, 2020
# January 20, 2022
