#!/usr/bin/env perl

# Reheaders each sequence in fasta file according to reheadering map. Reheadering map
# must be tab-separated: old name, new name, one pair per line.

# Usage:
# perl reheader_fasta_sequences.pl [fasta file path] [reheadering map]

# Prints to console. To print to file, use
# perl reheader_fasta_sequences.pl [fasta file path] [reheadering map]
# > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $reheadering_map = $ARGV[1];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input files exist and are non-empty
if(!-e $fasta_file)
{
	print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
	die;
}
if(-z $fasta_file)
{
	print STDERR "Warning: input fasta file is empty:\n\t".$fasta_file."\n";
}
if(!-e $reheadering_map)
{
	print STDERR "Error: input reheadering map does not exist:\n\t".$reheadering_map
		."\nExiting.\n";
	die;
}
if(-z $reheadering_map)
{
	print STDERR "Warning: input reheadering map is empty:\n\t".$reheadering_map."\n";
}


# reads in reheadering map
my %old_name_to_new_name = (); # key: old name -> value: new name
open REHEADERING_MAP, "<$reheadering_map" || die "Could not open $reheadering_map to read; terminating =(\n";
while(<REHEADERING_MAP>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		my $old_name = $items_in_line[0];
		my $new_name = $items_in_line[1];
		
		$old_name_to_new_name{$old_name} = $new_name;
	}
}
close REHEADERING_MAP;


# reads in fasta file; renames each header
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# switches out sequence name
		my $name = $1;
		if($old_name_to_new_name{$name})
		{
			$name = $old_name_to_new_name{$name};
		}
		
		# prints sequence name
		print ">".$name.$NEWLINE;
	}
	else # sequence
	{
		print $_.$NEWLINE;
	}
}
close FASTA_FILE;


# February 8, 2025
