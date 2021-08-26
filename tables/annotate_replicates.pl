#!/usr/bin/env perl

# Assigns a source number to all replicates from the same source. Adds source number
# as a column to table to annotate.

# Usage:
# perl annotate_replicates.pl [tab-separated replicate ids, one line per source]
# [table to annotate] [title of column containing replicate ids in table to annotate]
# [optional source column title for output]

# Prints to console. To print to file, use
# perl annotate_replicates.pl [tab-separated replicate ids, one line per source]
# [table to annotate] [title of column containing replicate ids in table to annotate]
# [optional source column title for output] > [annotated output table path]


use strict;
use warnings;


my $replicate_ids_file = $ARGV[0];
my $table_to_annotate = $ARGV[1];
my $replicate_ids_column_title = $ARGV[2];
my $source_column_title = $ARGV[3];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "";


# verifies that input tables exist and are non-empty
verify_input_file($replicate_ids_file, "replicate names file");
verify_input_file($table_to_annotate, "table to annotate");

# verifies that other inputs make sense
if(!defined $replicate_ids_column_title or !length $replicate_ids_column_title)
{
	print STDERR "Error: title of column containing replicate names not provided. Exiting.\n";
	die;
}


# reads in table to annotate to retrieve included replicate names
my $first_line = 1;
my $replicate_ids_column = -1;
my %replicate_id_included = (); # key: replicate id -> value: 1 if replicate id found in table to annotate
open TABLE_TO_ANNOTATE, "<$table_to_annotate" || die "Could not open $table_to_annotate to read; terminating =(\n";
while(<TABLE_TO_ANNOTATE>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $_, -1);
		
		if($first_line) # column titles
		{
			# identifies columns of interest
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if($column_title eq $replicate_ids_column_title)
				{
					$replicate_ids_column = $column;
				}
				$column++;
			}
			
			# verifies that all columns have been found
			if($replicate_ids_column == -1)
			{
				print STDERR "Error: expected replicate id column title "
					.$replicate_ids_column_title." not found in table to annotate. Exiting.\n";
				die;
			}
			
			$first_line = 0; # next line is not column titles
		}
		else # column values
		{
			# retrieves replicate id
			my $replicate_id = $items_in_line[$replicate_ids_column];
			
			# marks replicate id as found in table to annotate
			$replicate_id_included{$replicate_id} = 1;
		}
	}
}
close TABLE_TO_ANNOTATE;


# reads in replicates from same sources
my %replicate_id_to_source_number = (); # key: replicate id -> value: unique source number
my $source_number = 0;
open REPLICATE_IDS, "<$replicate_ids_file" || die "Could not open $replicate_ids_file to read; terminating =(\n";
while(<REPLICATE_IDS>) # for each row in the file
{
	chomp;
	if($_ =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $_, -1);
		
		# retrieves included replicate ids for replicates from same source
		my %replicate_ids_from_this_source_hash = (); # key: replicate id -> value: 1
		foreach my $replicate_id(@items_in_line)
		{
			if(defined $replicate_id and $replicate_id_included{$replicate_id})
			{
				if($replicate_ids_from_this_source_hash{$replicate_id})
				{
					print STDERR "Warning: replicate id appears more than once "
						."in a source's row in table of sources with multiple replicates: "
						.$replicate_id.".\n";
				}
				$replicate_ids_from_this_source_hash{$replicate_id} = 1;
			}
		}
		
		# saves source number for all replicates from this source
		if(scalar keys %replicate_ids_from_this_source_hash > 1)
		{
			$source_number++;
			foreach my $replicate_id(keys %replicate_ids_from_this_source_hash)
			{
				if($replicate_id_to_source_number{$replicate_id})
				{
					print STDERR "Warning: replicate id ".$replicate_id." listed as belonging "
						."to more than one source. Listing both sources.\n";
					$replicate_id_to_source_number{$replicate_id} .= ", ".$source_number;
				}
				else
				{
					$replicate_id_to_source_number{$replicate_id} = $source_number;
				}
			}
		}
	}
}
close REPLICATE_IDS;


# reads in table to annotate and annotates with source number
# (replicates that are the only replicate for a source get their own source numbers)
$first_line = 1;
open TABLE_TO_ANNOTATE, "<$table_to_annotate" || die "Could not open $table_to_annotate to read; terminating =(\n";
while(<TABLE_TO_ANNOTATE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		if($first_line) # column titles
		{
			# prints header line with source number column title
			if(defined $source_column_title and length $source_column_title)
			{
				print $source_column_title;
			}
			else
			{
				print "source_number";
			}
			print $DELIMITER.$line.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values
		{
			# retrieves replicate id
			my @items_in_line = split($DELIMITER, $line, -1);
			my $replicate_id = $items_in_line[$replicate_ids_column];
			
			# retrieves or generates source number corresponding to this replicate
			my $replicate_source_number = -1;
			if($replicate_id_to_source_number{$replicate_id})
			{
				$replicate_source_number = $replicate_id_to_source_number{$replicate_id};
			}
			else
			{
				$source_number++;
				$replicate_source_number = $source_number;
			}
			
			# prints line with source number
			print $replicate_source_number.$DELIMITER.$line.$NEWLINE;
		}
	}
}
close TABLE_TO_ANNOTATE;


sub verify_input_file
{
	my $file_path = $_[0];
	my $descriptive_name_to_print = $_[1];
	
	if(!$file_path)
	{
		print STDERR "Error: ".$descriptive_name_to_print." not provided. Exiting.\n";
		die;
	}
	if(!-e $file_path)
	{
		print STDERR "Error: ".$descriptive_name_to_print." does not exist:\n\t"
			.$file_path."\nExiting.\n";
		die;
	}
	if(-z $file_path)
	{
		print STDERR "Error: ".$descriptive_name_to_print." is empty:\n\t"
			.$file_path."\nExiting.\n";
		die;
	}
}


# August 23, 2021
