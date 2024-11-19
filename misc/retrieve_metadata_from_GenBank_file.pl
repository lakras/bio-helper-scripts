#!/usr/bin/env perl

# Retrieves metadata from GenBank .gb file and outputs as a table, one row per sequence.

# Usage:
# perl retrieve_metadata_from_GenBank_file.pl [GenBank .gb file]

# Prints to console. To print to file, use
# perl retrieve_metadata_from_GenBank_file.pl [GenBank .gb file] > [output table path]


use strict;
use warnings;


my $genbank_gb_file = $ARGV[0];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$genbank_gb_file or !-e $genbank_gb_file or -z $genbank_gb_file)
{
	print STDERR "Error: GenBank .gb file not provided, does not exist, or empty:\n\t"
		.$genbank_gb_file."\nExiting.\n";
	die;
}


# prints header line
print "accession".$DELIMITER;
print "name".$DELIMITER;
print "length".$DELIMITER;
print "organism".$DELIMITER;
print "mol_type".$DELIMITER;
print "strain".$DELIMITER;
print "isolation_source".$DELIMITER;
print "host".$DELIMITER;
print "geo_loc_name".$DELIMITER;
print "collection_date".$DELIMITER;
print "note".$DELIMITER;
print "authors".$DELIMITER;
print "title".$NEWLINE;


# reads in GenBank file and prints data of interest
my $accession = "";
my $name = "";
my $length = "";
my $organism = "";
my $mol_type = "";
my $strain = "";
my $isolation_source = "";
my $host = "";
my $geo_loc_name = "";
my $collection_date = "";
my $note = "";
my $note_continuing = 0;
my $authors = "";
my $authors_continuing = 0;
my $title = "";
my $title_continuing = 0;
open GENBANK_FILE, "<$genbank_gb_file" || die "Could not open $genbank_gb_file to read; terminating =(\n";
while(<GENBANK_FILE>) # for each row in the file
{
	chomp;
	my $line = $_;
	
	# start of new entry
	if($line =~ /LOCUS       /)
	{
		# print previous entry
		if($accession)
		{
			print $accession.$DELIMITER;
			print $name.$DELIMITER;
			print $length.$DELIMITER;
			print $organism.$DELIMITER;
			print $mol_type.$DELIMITER;
			print $strain.$DELIMITER;
			print $isolation_source.$DELIMITER;
			print $host.$DELIMITER;
			print $geo_loc_name.$DELIMITER;
			print $collection_date.$DELIMITER;
			print $note.$DELIMITER;
			print $authors.$DELIMITER;
			print $title.$NEWLINE;
		}
		
		# clear for new entry
		$accession = "";
		$name = "";
		$length = "";
		$organism = "";
		$mol_type = "";
		$strain = "";
		$isolation_source = "";
		$host = "";
		$geo_loc_name = "";
		$collection_date = "";
		$note = "";
		$authors = "";
		$title = "";
	}
	
	# length
	if($line =~ /LOCUS.+ (\d+ bp)/)
	{
		$length = $1;
	}
	
	# accession (version)
	if($line =~ /VERSION     (.*)$/)
	{
		$accession = $1;
	}
	
	# accession (version)
	if($line =~ /DEFINITION  (.*)$/)
	{
		$name = $1;
	}
	
	# organism
	if($line =~ /                     \/organism="(.*)"/)
	{
		$organism = $1;
	}
	
	# mol_type
	if($line =~ /                     \/mol_type="(.*)"/)
	{
		$mol_type = $1;
	}
	
	# strain
	if($line =~ /                     \/strain="(.*)"/)
	{
		$strain = $1;
	}
	
	# isolation_source
	if($line =~ /                     \/isolation_source="(.*)"/)
	{
		$isolation_source = $1;
	}
	
	# host
	if($line =~ /                     \/host="(.*)"/)
	{
		$host = $1;
	}
	
	# geo_loc_name
	if($line =~ /                     \/geo_loc_name="(.*)"/)
	{
		$geo_loc_name = $1;
	}
	
	# collection_date
	if($line =~ /                     \/collection_date="(.*)"/)
	{
		$collection_date = $1;
	}
	
	# note
	if($line =~ /                     \/note="(.*?)"?$/)
	{
		$note = $1;
		$note_continuing = 1;
	}
	elsif($note_continuing)
	{
		if($line =~ /                     ([^"\/].*?)"?$/)
		{
			$note .= " ".$1;
		}
		else
		{
			$note_continuing = 0;
		}
	}
	
	# authors
	if($line =~ /  AUTHORS   (.*)/)
	{
		if($authors)
		{
			$authors .= "; ";
		}
		$authors .= $1;
		$authors_continuing = 1;
	}
	elsif($authors_continuing)
	{
		if($line =~ /            (.*)/)
		{
			$authors .= " ".$1;
		}
		else
		{
			$authors_continuing = 0;
		}
	}
	
	# title
	if($line =~ /  TITLE     (.*)/)
	{
		if($1 ne "Direct Submission")
		{
			if($title)
			{
				$title .= "; ";
			}
			$title .= $1;
			$title_continuing = 1;
		}
	}
	elsif($title_continuing)
	{
		if($line =~ /            (.*)/)
		{
			$title .= " ".$1;
		}
		else
		{
			$title_continuing = 0;
		}
	}
	
	# title
	
}
close GENBANK_FILE;

# print last entry
if($accession)
{
	print $accession.$DELIMITER;
	print $name.$DELIMITER;
	print $length.$DELIMITER;
	print $organism.$DELIMITER;
	print $mol_type.$DELIMITER;
	print $strain.$DELIMITER;
	print $isolation_source.$DELIMITER;
	print $host.$DELIMITER;
	print $geo_loc_name.$DELIMITER;
	print $collection_date.$DELIMITER;
	print $note.$DELIMITER;
	print $authors.$DELIMITER;
	print $title.$NEWLINE;
}


# November 18, 2024
