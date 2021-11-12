#!/usr/bin/env perl

# Merges aligned sequences with same name up to a ": ", such as those output by LASTZ.

# Usage:
# perl collapse_aligned_sequences_by_name.pl [alignment fasta file path]

# Prints to console. To print to file, use
# perl collapse_aligned_sequences_by_name.pl [alignment fasta file path]
# > [output fasta file path]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment; reference sequence must appear first


my $NEWLINE = "\n";
my $NAME_SEPARATOR = ": "; # merges sequences with same name up to this string


# verifies that fasta alignment file exists and is non-empty
if(!$alignment_file)
{
	print STDERR "Error: no input fasta alignment file provided. Exiting.\n";
	die;
}
if(!-e $alignment_file)
{
	print STDERR "Error: input fasta alignment file does not exist:\n\t".$alignment_file."\nExiting.\n";
	die;
}
if(-z $alignment_file)
{
	print STDERR "Error: input fasta alignment file is empty:\n\t".$alignment_file."\nExiting.\n";
	die;
}


# reads in fasta sequences
# groups sequences by name
my %sequence_name_to_sequences = (); # key: sequence name before ": " -> value: list of sequences matching this sequence name
my $current_sequence = "";
my $current_sequence_name = "";
open FASTA_FILE, "<$alignment_file" || die "Could not open $alignment_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			push(@{$sequence_name_to_sequences{$current_sequence_name}}, $current_sequence);
		}
		
		# save new sequence name and prepare to read in new sequence
		$current_sequence_name = $1;
		if($current_sequence_name =~ /^(.*)$NAME_SEPARATOR/)
		{
			$current_sequence_name = $1;
		}
		$current_sequence = "";
	}
	else # not header line
	{
		$current_sequence .= uc($_);
	}
}
close FASTA_FILE;
push(@{$sequence_name_to_sequences{$current_sequence_name}}, $current_sequence);


# merge sequences with same name
foreach my $sequence_name(keys %sequence_name_to_sequences)
{
	print ">".$sequence_name.$NEWLINE;
	my @sequences = @{$sequence_name_to_sequences{$sequence_name}};
	for(my $base_index = 0; $base_index < maximum_string_length(@sequences); $base_index++)
	{
		# retrieves base from each sequence
		my %base_to_number_sequences = (); # key: base -> value: number sequences with this base
		my %unambiguous_base_to_number_sequences = ();
		foreach my $sequence(@sequences)
		{
			my $sequence_base = substr($sequence, $base_index, 1);
			if(is_base($sequence_base))
			{
				$base_to_number_sequences{$sequence_base}++;
			}
			if(is_unambiguous_base($sequence_base))
			{
				$unambiguous_base_to_number_sequences{$sequence_base}++;
			}
		}
		
		# chooses most commonly occurring unambiguous base or, if none, most common base
		my $collapsed_base = "-";
		if(scalar keys %unambiguous_base_to_number_sequences)
		{
			my @unambiguous_bases_sorted = sort {$unambiguous_base_to_number_sequences{$a} <=> $unambiguous_base_to_number_sequences{$b}} keys %unambiguous_base_to_number_sequences;
			$collapsed_base = $unambiguous_bases_sorted[-1];
		}
		elsif(scalar keys %base_to_number_sequences)
		{
			my @bases_sorted = sort {$base_to_number_sequences{$a} <=> $base_to_number_sequences{$b}} keys %base_to_number_sequences;
			$collapsed_base = $bases_sorted[-1];
		}
		print $collapsed_base;
	}
	print $NEWLINE;
}


# returns 1 if base is A, T, C, G; returns 0 if not
# input base must be capitalized
sub is_unambiguous_base
{
	my $base = $_[0]; # must be capitalized
	if($base eq "A" or $base eq "T" or $base eq "C" or $base eq "G")
	{
		return 1;
	}
	return 0;
}

# returns 1 if base is not gap, 0 if base is a gap (or whitespace or empty)
sub is_base
{
	my $base = $_[0];
	
	# empty value
	if(!$base)
	{
		return 0;
	}
	
	# only whitespace
	if($base !~ /\S/)
	{
		return 0;
	}
	
	# gap
	if($base eq "-")
	{
		return 0;
	}
	
	# base
	return 1;
}

# returns maximum length of a string in input array
sub maximum_string_length
{
	my @strings = @_;
	
	# returns if we don't have any input values
	if(scalar @strings < 1)
	{
		return 0;
	}
	
	# retrieves maximum string length
	my $max_length = 0;
	foreach my $string(@strings)
	{
		my $string_length = length($string);
		if($string_length > $max_length)
		{
			$max_length = $string_length;
		}
	}
	return $max_length;
}


# November 11, 2021
