#!/usr/bin/env perl

# Collapse duplicate sequences into one representative sequence per group of identical
# sequences. Optionally requires sequence name to be identical after first word.

# Usage:
# perl collapse_duplicates.pl [alignment fasta file path]
# [1 to require identical sequence name after the first word]

# Prints to console. To print to file, use
# perl collapse_duplicates.pl [alignment fasta file path]
# [1 to require identical sequence name after the first word] > [output fasta]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment
my $include_names_in_comparison = $ARGV[1]; # if 1, requires identical sequence name after the first word; if 0, collapses all identical sequences


my $NEWLINE = "\n";


# reads in alignment
my %sequence_name_to_sequence = (); # key: name of sequence in this alignment file -> value: sequence
my %sequence_to_sequence_names = (); # key: sequence -> key: sequence name -> value: 1
my $current_sequence_name = ""; # name of sequence currently being read in
my $current_sequence = ""; # sequence currently being read in
open FASTA_FILE, "<$alignment_file" || die "Could not open $alignment_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# saves sequence that was just read in
		if($current_sequence_name and $current_sequence)
		{
			$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
			$sequence_to_sequence_names{$current_sequence}{$current_sequence_name} = 1;
		}
	
		# sets up new current sequence
		$current_sequence_name = $1;
		$current_sequence = "";
	}
	else # sequence (not header line)
	{
		# adds to sequence
		$current_sequence .= uc($_);
	}
}
close FASTA_FILE;
if($current_sequence_name and $current_sequence)
{
	$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
	$sequence_to_sequence_names{$current_sequence}{$current_sequence_name} = 1;
}


# collapse all identical sequences with same name after first word
if($include_names_in_comparison)
{
	foreach my $sequence(keys %sequence_to_sequence_names)
	{
		my @sequence_names = sort keys %{$sequence_to_sequence_names{$sequence}};
		
		# pull out sequence names after first word
		my %sequence_name_after_first_word_to_count = (); # key: sequence name after first word -> value: number sequences
		my %sequence_name_after_first_word_to_full_sequence_name = (); # key: sequence name after first word -> key: full sequence name -> value: 1
		foreach my $sequence_name(@sequence_names)
		{
			my @words = split(/\s+/, $sequence_name);
			shift @words;
			my $sequence_name_after_first_word = join(" ", @words);
			$sequence_name_after_first_word_to_count{$sequence_name_after_first_word}++;
			$sequence_name_after_first_word_to_full_sequence_name{$sequence_name_after_first_word}{$sequence_name} = 1;
		}
		
		# print sequences
		foreach my $sequence_name_after_first_word(sort keys %sequence_name_after_first_word_to_count)
		{
			# only one sequence with this name after the first word--print as is
			if($sequence_name_after_first_word_to_count{$sequence_name_after_first_word} == 1)
			{
				my @matched_sequence_names = keys %{$sequence_name_after_first_word_to_full_sequence_name{$sequence_name_after_first_word}};
				my $sequence_name = $matched_sequence_names[0];
				print ">".$sequence_name.$NEWLINE;
				print $sequence.$NEWLINE;
			}
			
			# multiple sequences with this name after the first word
			else
			{
				my $merged_sequence_name = $sequence_name_after_first_word." ("
					.$sequence_name_after_first_word_to_count{$sequence_name_after_first_word}
					." genomes)";
				print ">".$merged_sequence_name.$NEWLINE;
				print $sequence.$NEWLINE;
			}
		}
	}
}


# collapse all identical sequences
else
{
	foreach my $sequence(keys %sequence_to_sequence_names)
	{
		my @sequence_names = sort keys %{$sequence_to_sequence_names{$sequence}};
		
		# concatenate the sequence names
		my $joined_names = join(" ", @sequence_names);
		
		# print sequence with new name
		print ">".$joined_names.$NEWLINE;
		print $sequence.$NEWLINE;
	}
}


# February 13, 2025
