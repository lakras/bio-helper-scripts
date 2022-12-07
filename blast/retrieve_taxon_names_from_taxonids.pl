#!/usr/bin/env perl

# Retrieves each match's taxon name from its taxon id and adds it to blast or diamond
# output as a new column.

# Usage:
# perl retrieve_taxon_names_from_taxonids.pl [blast or diamond output]
# [names.dmp file from NCBI]


# Prints to console. To print to file, use
# perl retrieve_taxon_names_from_taxonids.pl [blast or diamond output]
# [names.dmp file from NCBI] > [blast or diamond output with taxon name column added]


use strict;
use warnings;


my $blast_or_diamond_output = $ARGV[0]; # potential blast output format: qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue
my $names_file = $ARGV[1]; # names.dmp file from NCBI: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
my $taxonid_column = $ARGV[2]; # column number of taxon id column (3 by default)

my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $TAXONDUMP_DELIMITER = "\t[|]\t"; # nodes.dmp and names.dmp
my $TAXONID_SEPARATOR = ";"; # in blast file

# names.dmp
my $TAXONID_COLUMN = 0;
my $NAMES_COLUMN = 1;
my $NAME_TYPE_COLUMN = 3;



# verifies that input files exist and are not empty
if(!$blast_or_diamond_output or !-e $blast_or_diamond_output or -z $blast_or_diamond_output)
{
	print STDERR "Error: blast or diamond output not provided, does not exist, or empty:\n\t"
		.$blast_or_diamond_output."\nExiting.\n";
	die;
}
if(!$names_file or !-e $names_file or -z $names_file)
{
	print STDERR "Error: names.dmp file not provided, does not exist, or empty:\n\t"
		.$names_file."\nExiting.\n";
	die;
}


# sets taxonid column to default if not provided
if(!defined $taxonid_column)
{
	$taxonid_column = 3;
}


# retrieves taxon id to taxon name mapping
my %taxonid_to_taxon_name = (); # key: taxon id -> value: taxon name
open NAMES_FILE, "<$names_file" || die "Could not open $names_file to read\n";
while(<NAMES_FILE>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($TAXONDUMP_DELIMITER, $_);
		my $taxonid = $items[$TAXONID_COLUMN];
		my $taxon_name = $items[$NAMES_COLUMN];
		
		$taxonid_to_taxon_name{$taxonid} = $taxon_name;
	}
}
close NAMES_FILE;


# reads in blast or diamond output and adds names column right after taxon id column
open BLAST_OR_DIAMOND_OUTPUT, "<$blast_or_diamond_output"
	|| die "Could not open $blast_or_diamond_output to read\n";
my %matched_accession_numbers = (); # key: matched accession number -> value: 1
my %matched_accession_number_to_name = (); # key: matched accession number -> value: sequence name
while(<BLAST_OR_DIAMOND_OUTPUT>)
{
	chomp;
	if($_ =~ /\S/)
	{
		# retrieves values
		my @items = split($DELIMITER, $_);
		my $taxonids = $items[$taxonid_column];
		my $taxon_names = $NO_DATA;
		
		foreach my $taxonid(split($TAXONID_SEPARATOR, $taxonids))
		{
			if(defined $taxonid_to_taxon_name{$taxonid})
			{
				if($taxon_names eq $NO_DATA)
				{
					$taxon_names = "";
				}
				if($taxon_names)
				{
					$taxon_names .= $TAXONID_SEPARATOR;
				}
				$taxon_names .= $taxonid_to_taxon_name{$taxonid};
			}
			else
			{
				print STDERR "Error: name not read in for taxon id ".$taxonid."\n";
			}
		}
		
		# prints line with taxon name added right after taxon id
		my $column = 0;
		foreach my $value(@items)
		{
			if($column > 0)
			{
				print $DELIMITER;
			}
			if($column == $taxonid_column)
			{
				print $taxonids.$DELIMITER.$taxon_names;
			}
			else
			{
				print $value;
			}
			$column++;
		}
	}
	print $NEWLINE;
}
close BLAST_OR_DIAMOND_OUTPUT;


# December 6, 2022
