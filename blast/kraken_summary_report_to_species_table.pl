#!/usr/bin/env perl

# Converts Kraken summary report to table of species found in sample.

# Kraken summary report has columns (as described in
# https://ccb.jhu.edu/software/kraken/MANUAL.html#output-format):
# - score (?)
# - total reads in the taxon, including children
# - reads assigned to this taxon specifically
# - rank (S for species)
# - taxon id
# - taxon name

# Output table has columns:
# - species taxon id
# - species name
# - total reads assigned to taxon, including children


# Usage:
# perl kraken_summary_report_to_species_table.pl [kraken summary report]

# Prints to console. To print to file, use
# perl kraken_summary_report_to_species_table.pl [kraken summary report]
# > [output table file path]


use strict;
use warnings;


my $kraken_summary_report = $ARGV[0];


my $READS_IN_TAXON_COLUMN = 1;
my $RANK_COLUMN = 3;
my $TAXON_ID_COLUMN = 4;
my $TAXON_NAME_COLUMN = 5;

my $SPECIES_RANK = "S";

my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that kraken summary report exists and is non-empty
if(!$kraken_summary_report or !-e $kraken_summary_report or -z $kraken_summary_report)
{
	print STDERR "Error: input kraken summary report file not provided, does not exist, "
		."or is empty:\n\t".$kraken_summary_report."\nExiting.\n";
	die;
}


# prints header line
print "species_taxon_id".$DELIMITER;
print "species_name".$DELIMITER;
print "number_reads".$NEWLINE;


# reads in kraken summary report
open KRAKEN_SUMMARY_REPORT, "<$kraken_summary_report"
	|| die "Could not open $kraken_summary_report to read; terminating =(\n";
while(<KRAKEN_SUMMARY_REPORT>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		my @items = split($DELIMITER, $line);
		my $reads_in_taxon = $items[$READS_IN_TAXON_COLUMN];
		my $rank = $items[$RANK_COLUMN];
		my $taxon_id = $items[$TAXON_ID_COLUMN];
		my $taxon_name = $items[$TAXON_NAME_COLUMN];
		
		if($rank eq $SPECIES_RANK)
		{
			if($taxon_name =~ /^\s*(\S.*\S)\s*$/)
			{
				$taxon_name = $1;
			}
		
			print $taxon_id.$DELIMITER;
			print $taxon_name.$DELIMITER;
			print $reads_in_taxon.$NEWLINE;
		}
	}
}
close KRAKEN_SUMMARY_REPORT;


# June 9, 2023

