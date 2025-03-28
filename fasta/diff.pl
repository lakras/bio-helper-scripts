#!/usr/bin/env perl

# Compares sequences with the same name in the two fasta files. Prints any sequences that
# are different in the two fasta files.

# Usage:
# perl diff.pl [fasta file path] [another fasta file path]

# Prints to console. To print to file, use
# perl diff.pl [fasta file path] [another fasta file path]
# > [output file path]


use strict;
use warnings;


my $fasta_file_1 = $ARGV[0]; # fasta file
my $fasta_file_2 = $ARGV[1]; # fasta file


my $NEWLINE = "\n";


# verifies that fasta files exist and are non-empty
if(!$fasta_file_1 or !-e $fasta_file_1 or -z $fasta_file_1
	or !$fasta_file_2 or !-e $fasta_file_2 or -z $fasta_file_2)
{
	print STDERR "Error: one or both input fasta files not provided, does not exist, or"
		." is empty. Exiting.\n";
	die;
}


# reads in fasta files
my $current_sequence = "";
my $current_sequence_name = "";
my %sequence_name_to_sequence_1 = (); # key: sequence name -> value: sequence read in
open FASTA_FILE_1, "<$fasta_file_1" || die "Could not open $fasta_file_1 to read; terminating =(\n";
while(<FASTA_FILE_1>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			$sequence_name_to_sequence_1{$current_sequence_name} = $current_sequence;
		}
		
		# save new sequence name and prepare to read in new sequence
		$current_sequence_name = $1;
		$current_sequence = "";
	}
	else # not header line
	{
		$current_sequence .= uc($_);
	}
}
if($current_sequence)
{
	$sequence_name_to_sequence_1{$current_sequence_name} = $current_sequence;
}
close FASTA_FILE_1;

$current_sequence = "";
$current_sequence_name = "";
my %sequence_name_to_sequence_2 = (); # key: sequence name -> value: sequence read in
open FASTA_FILE_2, "<$fasta_file_2" || die "Could not open $fasta_file_2 to read; terminating =(\n";
while(<FASTA_FILE_2>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			$sequence_name_to_sequence_2{$current_sequence_name} = $current_sequence;
		}
		
		# save new sequence name and prepare to read in new sequence
		$current_sequence_name = $1;
		$current_sequence = "";
	}
	else # not header line
	{
		$current_sequence .= uc($_);
	}
}
if($current_sequence)
{
	$sequence_name_to_sequence_2{$current_sequence_name} = $current_sequence;
}
close FASTA_FILE_2;


# accounts for all sequence names
my %all_sequence_names = (); # key: sequence name -> value: 1
foreach my $sequence_name(keys %sequence_name_to_sequence_1)
{
	$all_sequence_names{$sequence_name} = 1;
}
foreach my $sequence_name(keys %sequence_name_to_sequence_2)
{
	$all_sequence_names{$sequence_name} = 1;
}


# compares sequences from the two fasta files
foreach my $sequence_name(keys %all_sequence_names)
{
	my $sequence_1 = $sequence_name_to_sequence_1{$sequence_name};
	my $sequence_2 = $sequence_name_to_sequence_2{$sequence_name};
	
	if($sequence_1 ne $sequence_2)
	{
		print $sequence_name.$NEWLINE;
		print $fasta_file_1.$NEWLINE;
		print $sequence_1.$NEWLINE;
		print $fasta_file_2.$NEWLINE;
		print $sequence_2.$NEWLINE;
		print $NEWLINE;
	}
}


# March 28, 2025
