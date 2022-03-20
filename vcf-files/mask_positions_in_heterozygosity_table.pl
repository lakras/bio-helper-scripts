#!/usr/bin/env perl

# Masks (removes lines corresponding to) alleles at indicated positions.

# Positions must be relative to reference used in heterozygosity table.

# Input heterozygosity tables are in same format as that used in polyphonia
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
# perl mask_positions_in_heterozygosity_table.pl [heterozygosity table]
# [first position in region to mask] [last position in region to mask]
# [first position in another region to mask] [last position in another region to mask]
# [etc.]

# Prints to console. To print to file, use
# perl mask_positions_in_heterozygosity_table.pl [heterozygosity table]
# [first position in region to mask] [last position in region to mask]
# [first position in another region to mask] [last position in another region to mask]
# [etc.] > [output heterozygosity table file path]



use strict;
use warnings;


my $heterozygosity_table = $ARGV[0]; # positions must be relative to same reference used in supplied positions to mask
my @starts_and_ends_of_regions_to_mask = @ARGV[1..$#ARGV]; # first position in region to mask (1-indexed, relative to reference), last position in region to mask (1-indexed, relative to reference), first position in another region to mask, last position in another region to mask, etc.


my $DELIMITER = "\t";
my $NEWLINE = "\n";
my $NO_DATA = "";


# heterozygosity table columns:
my $HETEROZYGOSITY_TABLE_POSITION_COLUMN = 1; # (0-indexed)


# verifies that heterozygosity table exists and is non-empty
if(!$heterozygosity_table)
{
	print STDERR "Error: no input heterozygosity table provided. Exiting.\n";
	die;
}
if(!-e $heterozygosity_table)
{
	print STDERR "Error: input heterozygosity table does not exist:\n\t"
		.$heterozygosity_table."\nExiting.\n";
	die;
}
if(-z $heterozygosity_table)
{
	print STDERR "Error: input heterozygosity table is empty:\n\t"
		.$heterozygosity_table."\nExiting.\n";
	die;
}


# pulls out starts and ends of regions to mask
my @starts_of_regions_to_mask = ();
my @ends_of_regions_to_mask = ();
my $index = 0;
foreach my $position(@starts_and_ends_of_regions_to_mask)
{
	if($index % 2 == 0)
	{
		push(@starts_of_regions_to_mask, $position);
	}
	else
	{
		push(@ends_of_regions_to_mask, $position);
	}
	$index++;
}


# verifies that regions to mask are provided and make sense
if(scalar @starts_of_regions_to_mask ne scalar @ends_of_regions_to_mask)
{
	print STDERR "Error: different numbers of start and end positions of regions to "
		."mask. Exiting.\n";
	die;
}
foreach my $region_index(0..$#starts_of_regions_to_mask)
{
	my $start_of_region_to_mask = $starts_of_regions_to_mask[$region_index];
	my $end_of_region_to_mask = $ends_of_regions_to_mask[$region_index];
	
	if($start_of_region_to_mask < 1 or $start_of_region_to_mask < 1)
	{
		print STDERR "Error: position to mask < 1: ".$start_of_region_to_mask."-"
			.$end_of_region_to_mask.". Exiting.\n";
		die;
	}
	
	if($end_of_region_to_mask < $start_of_region_to_mask)
	{
		print STDERR "Error: end earlier than start of region to mask: "
			.$start_of_region_to_mask."-".$end_of_region_to_mask.". Exiting.\n";
		die;
	}
}


# creates easy look-up of whether or not position should be mask
my %mask_position = (); # key: position -> value: 1 if position should be masked
foreach my $region_index(0..$#starts_of_regions_to_mask)
{
	my $start_of_region_to_mask = $starts_of_regions_to_mask[$region_index];
	my $end_of_region_to_mask = $ends_of_regions_to_mask[$region_index];
	
	foreach my $position($start_of_region_to_mask..$end_of_region_to_mask)
	{
		$mask_position{$position} = 1;
	}
}


# reads in heterozygosity table; prints version with position masked out
open HETEROZYGOSITY_TABLE, "<$heterozygosity_table" || die "Could not open $heterozygosity_table to read; terminating =(\n";
while(<HETEROZYGOSITY_TABLE>) # for each line in the file
{
	# reads in this line and determines if it should be printed
	chomp;
	my $line = $_;
	my $print_line = 1;
	if($line =~ /\S/) # non-empty line
	{
		# parses this line
		my @items = split($DELIMITER, $line);
		my $position = $items[$HETEROZYGOSITY_TABLE_POSITION_COLUMN];
		if($mask_position{$position})
		{
			$print_line = 0;
		}
	}
	
	# prints line if it should be printed
	if($print_line)
	{
		print $line;
		print $NEWLINE;
	}
}
close HETEROZYGOSITY_TABLE;


# July 14, 2021
# November 10, 2021
# March 2, 2022
# March 20, 2022
