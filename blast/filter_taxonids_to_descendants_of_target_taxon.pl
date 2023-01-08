#!/usr/bin/env perl

# Given a list of txaon ids, one per line, filters down to only descendants of parameter
# taxon id (for example, 10239 for Viruses).


# Usage:
# perl filter_taxonids_to_descendants_of_target_taxon.pl
# [path of file with list of taxon ids, one per line] [nodes.dmp file from NCBI]
# [taxon id to filter to]

# Prints to console. To print to file, use
# perl filter_taxonids_to_descendants_of_target_taxon.pl
# [path of file with list of taxon ids, one per line] [nodes.dmp file from NCBI]
# [taxon id to filter to] > [output list of taxon ids]


use strict;
use warnings;


my $taxon_ids_file = $ARGV[0]; # list of taxon ids, one per line
my $nodes_file = $ARGV[1]; # nodes.dmp file from NCBI: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
my $taxon_id_to_filter_to = $ARGV[2]; # filters down to only descendants of this taxon id (inclusive)


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $TAXONDUMP_DELIMITER = "\t[|]\t"; # nodes.dmp and names.dmp

my $ROOT_TAXON_ID = 1;

# nodes.dmp
my $TAXONID_COLUMN = 0;
my $PARENTID_COLUMN = 1;


# verifies that all input files exist and are non-empty
if(!$nodes_file or !-e $nodes_file or -z $nodes_file)
{
	print STDERR "Error: nodes.dmp file not provided, does not exist, or empty:\n\t"
		.$nodes_file."\nExiting.\n";
	die;
}
if(!$taxon_ids_file or !-e $taxon_ids_file or -z $taxon_ids_file)
{
	print STDERR "Error: taxon ids file not provided, does not exist, or empty:\n\t"
		.$taxon_ids_file."\nExiting.\n";
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

# reads in taxon ids and prints those descended from Viruses (10239)
open TAXON_IDS, "<$taxon_ids_file" || die "Could not open $taxon_ids_file to read\n";
while(<TAXON_IDS>)
{
	chomp;
	if($_ =~ /\S/)
	{
		# determines whether or not taxon id is a descendant of taxon id to filter to
		my $taxon_id = $_;
		my $taxon_id_ancestor = $taxon_id;
		my $determined_to_pass_filter = 0;
		while($taxon_id_ancestor != $ROOT_TAXON_ID and !$determined_to_pass_filter)
		{
			if($taxon_id_ancestor == $taxon_id_to_filter_to)
			{
				$determined_to_pass_filter = 1;
			}
			$taxon_id_ancestor = $taxonid_to_parent{$taxon_id_ancestor};
		}
		
		# prints taxon id if it passes filter
		if($determined_to_pass_filter)
		{
			print $taxon_id.$NEWLINE;
		}
	}
}
close TAXON_IDS;


# January 3, 2022
