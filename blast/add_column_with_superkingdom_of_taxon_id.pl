#!/usr/bin/env perl

# Reads in column containing taxon id and adds column containing the superkingdom of
# that taxon id.

# Usage:
# perl add_column_with_superkingdom_of_taxon_id.pl [table]
# [title of column containing taxon ids] [nodes.dmp file from NCBI]

# Prints to console. To print to file, use
# perl add_column_with_superkingdom_of_taxon_id.pl [table]
# [title of column containing taxon ids] [nodes.dmp file from NCBI] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $taxon_id_column_title = $ARGV[1];
my $nodes_file = $ARGV[2]; # nodes.dmp file from NCBI: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz


my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $TAXONDUMP_DELIMITER = "\t[|]\t"; # nodes.dmp and names.dmp

my $SUPERKINGDOM_COLUMN_TITLE = "superkingdom"; # column to add

# superkingdoms
my %TAXON_ID_TO_SUPERKINGDOM = (
	2157 => "Archaea",
	2 => "Bacteria",
	2759 => "Eukaryota",
	10239 => "Viruses");
my $ROOT_TAXON_ID = 1;

# nodes.dmp and names.dmp
my $TAXONID_COLUMN = 0;	# both
my $PARENTID_COLUMN = 1;	# nodes.dmp
my $RANK_COLUMN = 2;		# nodes.dmp
my $NAMES_COLUMN = 1;		# names.dmp
my $NAME_TYPE_COLUMN = 3;	# names.dmp


# verifies that all input files exist and are non-empty
if(!$nodes_file or !-e $nodes_file or -z $nodes_file)
{
	print STDERR "Error: nodes.dmp file not provided, does not exist, or empty:\n\t"
		.$nodes_file."\nExiting.\n";
	die;
}
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: input table not provided, does not exist, or is empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in nodes file
my %taxonid_to_parent = (); # key: taxon id -> value: taxon id of parent taxon
my %taxonid_to_rank = (); # key: taxon id -> value: rank of taxon
open NODES_FILE, "<$nodes_file" || die "Could not open $nodes_file to read\n";
while(<NODES_FILE>)
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items = split($TAXONDUMP_DELIMITER, $_);
		my $taxonid = $items[$TAXONID_COLUMN];
		my $parent_taxonid = $items[$PARENTID_COLUMN];
		my $rank = $items[$RANK_COLUMN];
		
		$taxonid_to_parent{$taxonid} = $parent_taxonid;
		$taxonid_to_rank{$taxonid} = $rank;
	}
}
close NODES_FILE;


# reads in taxon id column of table and adds superkingdom column
my $first_line = 1;
my $taxon_id_column = -1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		if($first_line) # column titles
		{
			# identifies column to merge by and columns to save
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $taxon_id_column_title)
				{
					if($taxon_id_column != -1)
					{
						print STDERR "Warning: column title ".$taxon_id_column_title
							." appears more than once in input table:\n\t".$table."\n";
					}
					$taxon_id_column = $column;
				}
				$column++;
			}
			
			# verifies that we have found column to merge by
			if($taxon_id_column == -1)
			{
				print STDERR "Warning: column title ".$taxon_id_column_title
					." not found in input table:\n\t".$table."\nExiting.\n";
				die;
			}
			$first_line = 0; # next line is not column titles
			
			# prints line as is
			print $line;
			
			# prints titles of new superkingdom column
			print $DELIMITER.$SUPERKINGDOM_COLUMN_TITLE.$NEWLINE;
		}
		else # column values (not column titles)
		{
			# retrieves taxon id
			my $taxon_id = $items_in_line[$taxon_id_column];
			
			# retrieves superkingdom
			my $superkingdom = $NO_DATA;
			my $ancestor_taxon_id = $taxon_id;
			while($superkingdom eq $NO_DATA
				and $taxonid_to_parent{$ancestor_taxon_id}
				and $ancestor_taxon_id ne $taxonid_to_parent{$ancestor_taxon_id}
				and $ancestor_taxon_id ne $ROOT_TAXON_ID)
			{
				if($TAXON_ID_TO_SUPERKINGDOM{$ancestor_taxon_id})
				{
					$superkingdom = $TAXON_ID_TO_SUPERKINGDOM{$ancestor_taxon_id};
				}
				$ancestor_taxon_id = $taxonid_to_parent{$ancestor_taxon_id}
			}
			
			# prints line as is
			print $line;
			
			# prints superkingdom column value
			print $DELIMITER.$superkingdom.$NEWLINE;
		}
	}
}
close TABLE;


# April 4, 2023
