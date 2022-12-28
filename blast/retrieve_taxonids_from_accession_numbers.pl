#!/usr/bin/env perl

# Given a list of accession numbers, one per line, retrieves corresponding taxon ids.
# Outputs tab-separating map with sequence name and taxon id.

# Install Entrez before running. Use either of these two commands:
# sh -c "$(curl -fsSL ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"
# sh -c "$(wget -q ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh -O -)"
# More info: https://www.ncbi.nlm.nih.gov/books/NBK179288/


# Usage:
# perl retrieve_taxonids_from_accession_numbers.pl
# [path of file with list of accession numbers, one per line] [database (nuccore by default)]

# Prints to console. To print to file, use
# perl retrieve_taxonids_from_accession_numbers.pl
# [path of file with list of accession numbers, one per line]
# [database (nuccore by default)] > [output mapping table path]


use strict;
use warnings;


my $accession_numbers_file = $ARGV[0]; # list of accession numbers, one per line
my $database = $ARGV[1]; # nuccore (default) or protein or other
if(!$database)
{
	$database = "nuccore";
}


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";


my $sacc_to_taxon_id_string = `cat $accession_numbers_file | epost -db $database | esummary | xtract -pattern DocumentSummary -element Caption,TaxId`;
print $sacc_to_taxon_id_string;


# December 1, 2022
# December 27, 2022
