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


# generates accession number to taxon id mapping
# (D90600.1 becomes D90600; rows printed out of order)
my $sacc_to_taxon_id_string = `cat $accession_numbers_file | epost -db $database | esummary | xtract -pattern DocumentSummary -element Caption,TaxId`;

# reads in accession number to taxon id mapping
my %accession_number_without_version_to_taxon_id = (); # key: accession number -> value: taxon id
foreach my $line(split($NEWLINE, $sacc_to_taxon_id_string))
{
	if($line =~ /\S/)
	{
		my @items = split($DELIMITER, $line);
		my $accession_number = $items[0];
		my $taxonid = $items[1];
		
		$accession_number_without_version_to_taxon_id{$accession_number} = $taxonid;
	}
}

# retrieves original accession numbers in their original order
open ACCESSION_NUMBERS, "<$accession_numbers_file" || die "Could not open $accession_numbers_file to read\n";
while(<ACCESSION_NUMBERS>)
{
	chomp;
	if($_ =~ /\S/)
	{
		# retrieves accession number without version
		my $accession_number = $_;
		my $accession_number_without_version = $accession_number;
		if($accession_number_without_version =~ /^(.*)[.]\d+/)
		{
			$accession_number_without_version = $1;
		}
		
		# retrieves taxon id
		my $taxonid = $accession_number_without_version_to_taxon_id{$accession_number_without_version};
		
		# prints accession number and txaon id
		print $accession_number.$DELIMITER;
		print $taxonid.$NEWLINE;
	}
}
close ACCESSION_NUMBERS;


# December 1, 2022
# December 27, 2022
