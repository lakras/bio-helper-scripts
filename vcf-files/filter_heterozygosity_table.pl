#!/usr/bin/env perl

# Filters input heterozygosity table.

# Input heterozygosity table is in same format as that used in polyphonia
# (see https://github.com/broadinstitute/polyphonia#--het)
# or output by vcf-files/vcf_file_to_heterozygosity_table.pl
# (https://github.com/lakras/bio-helper-scripts/blob/main/vcf-files/vcf_file_to_heterozygosity_table.pl):
# - name of reference genome (e.g., NC_045512.2)
# - position of locus relative to reference genome, 1-indexed (e.g., 28928)
# - major allele at that position (e.g., C)
# - major allele readcount (e.g., 1026)
# - major allele frequency (e.g., 0.934426)
# - minor allele at that position (e.g., T)
# - minor allele readcount (e.g., 72)
# - minor allele frequency (e.g., 0.065574)

# Usage:
# perl filter_heterozygosity_table.pl [heterozygosity table]
# [minimum minor allele readcount] [minimum minor allele frequency] [minimum read depth]

# Prints to console. To print to file, use
# perl filter_heterozygosity_table.pl [heterozygosity table]
# [minimum minor allele readcount] [minimum minor allele frequency] [minimum read depth]
# > [output filtered heterozygosity table path]


use strict;
use warnings;


my $heterozygosity_table = $ARGV[0];
my $minimum_minor_allele_readcount = $ARGV[1]; # suggested: 10
my $minimum_minor_allele_frequency = $ARGV[2]; # suggested: 0.03 = 3%
my $minimum_read_depth = $ARGV[3]; # suggested: 100


# intermediate file heterozygosity table columns:
my $HETEROZYGOSITY_TABLE_REFERENCE_COLUMN = 0;
my $HETEROZYGOSITY_TABLE_POSITION_COLUMN = 1; # (0-indexed)
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_COLUMN = 2;
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_READCOUNT_COLUMN = 3;
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_FREQUENCY_COLUMN = 4;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_COLUMN = 5;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_READCOUNT_COLUMN = 6;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_FREQUENCY_COLUMN = 7;

my $DELIMITER = "\t";
my $NEWLINE = "\n";
my $NO_DATA = "NA";


# filters heterozygosity table
open HETEROZYGOSITY_TABLE, "<$heterozygosity_table" || die "Could not open $heterozygosity_table to read; terminating =(\n";
while(<HETEROZYGOSITY_TABLE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		# parses this line
		my @items = split($DELIMITER, $line);
		my $reference = $items[$HETEROZYGOSITY_TABLE_REFERENCE_COLUMN];
		my $position = $items[$HETEROZYGOSITY_TABLE_POSITION_COLUMN];
		my $minor_allele = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_COLUMN];
		my $minor_allele_readcount = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_READCOUNT_COLUMN];
		my $minor_allele_frequency = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_FREQUENCY_COLUMN];
		my $consensus_allele = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_COLUMN];
		my $consensus_allele_readcount = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_READCOUNT_COLUMN];
		my $consensus_allele_frequency = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_FREQUENCY_COLUMN];
		
		# print line if passes filter
		if($minor_allele_readcount >= $minimum_minor_allele_readcount
			and $minor_allele_frequency >= $minimum_minor_allele_frequency
			and $minor_allele_readcount + $consensus_allele_readcount >= $minimum_read_depth)
		{
			print $line.$NEWLINE;
		}
	}
}
close HETEROZYGOSITY_TABLE;


# April 1, 2022
