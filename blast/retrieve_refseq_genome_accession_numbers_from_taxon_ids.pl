#!/usr/bin/env perl

# Given a list of taxon ids, one per line, retrieves accession numbers of refseq genomes.
# Outputs list of refseq genome accession numbers, one per line.

# Install Entrez before running. Use either of these two commands:
# sh -c "$(curl -fsSL ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"
# sh -c "$(wget -q ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh -O -)"
# More info: https://www.ncbi.nlm.nih.gov/books/NBK179288/


# Usage:
# perl retrieve_refseq_genome_accession_numbers_from_taxon_ids.pl
# [path of file with list of accession numbers, one per line]

# Prints to console. To print to file, use
# perl retrieve_refseq_genome_accession_numbers_from_taxon_ids.pl
# [path of file with list of accession numbers, one per line] > [output list file path]


use strict;
use warnings;


my $taxon_ids_file = $ARGV[0]; # list of taxon ids, one per line


my $MAXIMUM_NUMBER_TAXONIDS_IN_ONE_QUERY = 20;


# retrieves taxonids from input file and generates query lists with at most 400 queries per list
my @taxon_ids_queries = ();
my $current_taxonid_query = "";
my $current_number_taxonids = 0;
open TAXONIDS, "<$taxon_ids_file" || die "Could not open $taxon_ids_file to read\n";
while(<TAXONIDS>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my $taxon_id = $_;
		my $taxon_id_query_string = "txid".$taxon_id."[Organism:exp]";
		
		if($current_taxonid_query)
		{
			$current_taxonid_query .= " OR ";
		}
		$current_taxonid_query .= $taxon_id_query_string;
		
		$current_number_taxonids++;
		if($current_number_taxonids >= $MAXIMUM_NUMBER_TAXONIDS_IN_ONE_QUERY)
		{
			push(@taxon_ids_queries, $current_taxonid_query);
			$current_number_taxonids = 0;
			$current_taxonid_query = "";
		}
	}
}
close TAXONIDS;
push(@taxon_ids_queries, $current_taxonid_query);


# builds and runs query to retrieve refseq accession numbers
# example query:
# esearch -db nuccore -query "(txid11520[Organism:exp] OR txid11620[Organism:exp]) AND refseq[filter]"|efetch -format acc
foreach my $query_string(@taxon_ids_queries)
{
	my $command = "esearch -db nuccore -query \"(".$query_string.") AND refseq[filter]\"|efetch -format acc";
# 	print $command."\n";
	print `$command`;
}


# January 2, 2022
