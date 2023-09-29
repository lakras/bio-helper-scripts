#!/usr/bin/env perl

# Given a table with a column of taxon ids, filters down to only descendants of parameter
# taxon id (for example, 10239 for Viruses).


# Usage:
# perl filter_taxonids_in_table_column_to_descendants_of_target_taxon.pl
# [path of table with taxon id] [number (0-indexed) of column with taxon ids]
# [nodes.dmp file from NCBI] [taxon id to filter to]

# Prints to console. To print to file, use
# perl filter_taxonids_in_table_column_to_descendants_of_target_taxon.pl
# [path of table with taxon id] [number (0-indexed) of column with taxon ids]
# [nodes.dmp file from NCBI] [taxon id to filter to] > [output table]


use strict;
use warnings;


my $table = $ARGV[0]; # table with taxon id
my $taxon_id_column = $ARGV[1]; # column with taxon ids (0-indexed)
my $nodes_file = $ARGV[2]; # nodes.dmp file from NCBI: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
my $taxon_id_to_filter_to = $ARGV[3]; # filters down to only descendants of this taxon id (inclusive)


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
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: taxon ids file not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
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

# reads in taxon ids and prints those descended from Viruses (10239) or other parent
open TABLE, "<$table" || die "Could not open $table to read\n";
while(<TABLE>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items_in_line = split($DELIMITER, $_, -1);
		my $taxon_id = $items_in_line[$taxon_id_column];
	
		# determines whether or not taxon id is a descendant of taxon id to filter to
		my $taxon_id_ancestor = $taxon_id;
		my $determined_to_pass_filter = 0;
		while($taxon_id_ancestor != $ROOT_TAXON_ID and !$determined_to_pass_filter)
		{
			if($taxon_id_ancestor == $taxon_id_to_filter_to)
			{
				$determined_to_pass_filter = 1;
			}
			if($taxonid_to_parent{$taxon_id_ancestor})
			{
				$taxon_id_ancestor = $taxonid_to_parent{$taxon_id_ancestor};
			}
			else
			{
				$taxon_id_ancestor = $ROOT_TAXON_ID;
			}
		}
		
		# prints line if taxon id passes filter
		if($determined_to_pass_filter)
		{
			print $_.$NEWLINE;
		}
	}
}
close TABLE;


# January 3, 2022
# June 9, 2023
