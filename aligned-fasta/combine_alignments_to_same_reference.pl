#!/usr/bin/env perl

# Combines multiple fasta files including the same reference sequence into one fasta
# alignment. Reference fasta is printed first, with no gaps. All other sequences are
# printed aligned to the reference as in the input. Bases aligned to a gap in the
# reference are removed.

# Sequences in input files must have unique names. First sequence in each alignment fasta
# file must be reference.

# Usage:
# perl combine_alignments_to_same_reference.pl [alignment fasta file path]
# [another alignment fasta file path] [another alignment fasta file path] [etc.]

# Prints to console. To print to file, use
# perl combine_alignments_to_same_reference.pl [alignment fasta file path]
# [another alignment fasta file path] [another alignment fasta file path] [etc.]
# > [output fasta file path]


use strict;
use warnings;


my @alignment_files = @ARGV; # fasta alignments; reference sequences must appear first in each alignment


my $NEWLINE = "\n";
my $NO_DATA = "NA";


# verifies that fasta alignment file exists and is non-empty
if(!scalar @alignment_files)
{
	print STDERR "Error: no input fasta alignment files provided. Exiting.\n";
	die;
}


# reads in all alignments--saves bases at each position in each sequence, with positions
# defined by reference
my $reference_sequence_printed = 0;
my %reference_sequences_without_gaps = (); # key: reference sequence with gaps removed -> value: 1
foreach my $alignment_file(@alignment_files)
{
	# reads in all alignments
	my %sequence_name_to_sequence = (); # key: name of sequence in this alignment file -> value: sequence
	my $reference_sequence_name = ""; # name of reference sequence (first sequence in file)
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
			}
			if(!$reference_sequence_name)
			{
				$reference_sequence_name = $current_sequence_name;
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
	}
	
	
	# retrieves base at each position for each sequence
	my %sequence_name_to_position_to_base = (); # key: sequence name -> key: position (1-indexed) in reference -> value: base at corresponding position in sequence
	my $reference_sequence = $sequence_name_to_sequence{$reference_sequence_name};
	
	foreach my $sequence_name(keys %sequence_name_to_sequence)
	{
		my $sequence = $sequence_name_to_sequence{$sequence_name};
		
		my $position = 0; # 1-indexed relative to reference
		for(my $base_index = 0; $base_index < length($reference_sequence); $base_index++)
		{
			my $reference_base = substr($reference_sequence, $base_index, 1);
			if(is_base($reference_base))
			{
				# increments position only if valid base in reference sequence
				$position++;
	
				# retrieves sequence's base at this position
				if($base_index < length($sequence)) # no sequence at this index; we've gone out of range
				{
					my $base = substr($sequence, $base_index, 1);
					if(is_unambiguous_base($base))
					{
						$sequence_name_to_position_to_base{$sequence_name}{$position} = $base;
					}
				}
			}
		}
	}
	
	
	# saves and prints reference sequence without gaps
	$reference_sequence =~ s/-//g;
	$reference_sequence =~ s/\s//g;
	
	$reference_sequences_without_gaps{$reference_sequence} = 1;
	if(!$reference_sequence_printed)
	{
		print ">".$reference_sequence_name.$NEWLINE;
		print $reference_sequence.$NEWLINE;
		$reference_sequence_printed = 1;
	}
	
	
	# prints each aligned sequence
	for my $sequence_name(sort keys %sequence_name_to_position_to_base) 
	{
		if($sequence_name ne $reference_sequence_name)
		{
			# prints sequence name
			print ">".$sequence_name.$NEWLINE;
			
			# prints sequence
			my $last_position = max(keys %{$sequence_name_to_position_to_base{$sequence_name}});
			for(my $position = 1; $position <= $last_position; $position++)
			{
				if($sequence_name_to_position_to_base{$sequence_name}{$position})
				{
					print $sequence_name_to_position_to_base{$sequence_name}{$position};
				}
				else
				{
					print "-";
				}
			}
			
			# prints dashes until we reach the length of the reference
			for(my $position = $last_position+1; $position <= length($reference_sequence); $position++)
			{
				print "-";
			}
			print $NEWLINE;
		}
	}
}


# verifies that reference sequences without gaps are all identical
if(scalar %reference_sequences_without_gaps > 1)
{
	print STDERR "Error: more than one distinct reference provided.\n";
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

# returns 1 if base is not gap, 0 if base is a gap
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

# returns maximum value in input array
sub max
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# retrieves maximum value
	my $max_value = $values[0];
	foreach my $value(@values)
	{
		if($value > $max_value)
		{
			$max_value = $value;
		}
	}
	return $max_value;
}


# March 15, 2022
