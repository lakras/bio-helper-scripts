#!/usr/bin/env perl

# Removes gaps in reference (first sequence) in alignment and bases or gaps at the
# corresponding positions in all other sequences in the alignment.

# Usage:
# perl remove_reference_gaps_in_alignment.pl [alignment fasta file path]

# Prints to console. To print to file, use
# perl remove_reference_gaps_in_alignment.pl [alignment fasta file path] > [output fasta file path]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment; reference sequence must appear first


my $NEWLINE = "\n";


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
# prints updated fasta sequences
my %base_index_has_gap = (); # key: index of base in reference sequence (0-indexed) -> value: 1 if there is a gap in the reference sequence
my $reference_sequence = "";
my $reference_sequence_name = "";
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
			if(!$reference_sequence) # previous sequence is reference sequence (first sequence)
			{
				# saves reference sequence and name
				$reference_sequence = $current_sequence;
				$reference_sequence_name = $current_sequence_name;
		
				# maps position (1-indexed, relative to reference) to sequence string index (0-indexed)
				# (if there are no gaps in reference, string index will be position-1)
				my @reference_values = split(//, $reference_sequence);
				for(my $base_index = 0; $base_index < length($reference_sequence); $base_index++)
				{
					if(!is_base($reference_values[$base_index]))
					{
						$base_index_has_gap{$base_index} = 1;
					}
				}
			}
			remove_bases_at_indices_with_gaps_in_reference();
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
remove_bases_at_indices_with_gaps_in_reference();
close FASTA_FILE;


# removes bases at indices that have gaps in reference and prints modified sequence
sub remove_bases_at_indices_with_gaps_in_reference
{
	# exit if no sequence read in
	if(!$current_sequence)
	{
		return;
	}
	
	# exit if reference sequence not read in
	if(!$reference_sequence)
	{
		return;
	}
	
	# removes bases at indices that have gaps in reference
	my @current_sequence_values = split(//, $current_sequence);
	my @updated_sequence_values = ();
	for(my $base_index = 0; $base_index < length($current_sequence); $base_index++)
	{
		if(!$base_index_has_gap{$base_index})
		{
			push(@updated_sequence_values, $current_sequence_values[$base_index]);
		}
	}
	
	# generates updated sequence from array
	$current_sequence = join("", @updated_sequence_values);
	
	# prints updated sequence
	print ">".$current_sequence_name.$NEWLINE;
	print $current_sequence.$NEWLINE;
}


# returns 1 if base is not gap, 0 if not
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

# July 16, 2021
