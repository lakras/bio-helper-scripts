#!/usr/bin/env perl

# Extracts a set of diverse reference sequences from the provided fasta file. Selects
# sequences without ambiguous bases that are at least N% different from already included
# sequences, considering sequences in order from longest to shortest sequence.

# Usage:
# perl extract_diverse_reference_genomes.pl [fasta file path]
# [proportion bases different between sequences in output set]
# [mafft command or file path]

# Prints to console. To print to file, use
# perl extract_diverse_reference_genomes.pl [fasta file path]
# [proportion bases different between sequences in output set]
# [mafft command or file path] > [output fasta file]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # fasta file
my $diversity = $ARGV[1]; # proportion bases different between sequences in output set
my $mafft_file_path_or_command = $ARGV[2]; 


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# reads in fasta file
my $current_sequence = "";
my $current_sequence_name = "";
my %sequence_name_to_sequence = (); # key: sequence name -> value: sequence read in
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
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
	$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
}
close FASTA_FILE;


# counts number unambiguous bases in each sequence
# only includes sequences without ambiguous bases
my %sequence_name_to_length = (); # key: sequence name -> value: length of sequence, assuming only unambiguous bases
foreach my $sequence_name(keys %sequence_name_to_sequence)
{
	# counts number unambiguous bases
	my $sequence = $sequence_name_to_sequence{$sequence_name};
	my $number_unambiguous_bases = 0;
	my $sequence_has_ambiguous_bases = 0;
	for my $base(split(//, $sequence))
	{
		if(is_unambiguous_base($base))
		{
			$number_unambiguous_bases++;
		}
		else
		{
			$sequence_has_ambiguous_bases = 1;
		}
	}
	
	# saves number unambiguous bases
	# exclude sequence if it has ambiguous bases
	if(!$sequence_has_ambiguous_bases)
	{
		$sequence_name_to_length{$sequence_name} = $number_unambiguous_bases;
	}
}


# considers each sequence with no ambiguous bases, from longest to shortest
# builds a diverse set of sequences to use as references
my @included_sequences = (); # list of names of diverse sequences to use as references
foreach my $sequence_name(sort{$sequence_name_to_length{$b} <=> $sequence_name_to_length{$a}} keys %sequence_name_to_length)
{
	my $sequence = $sequence_name_to_sequence{$sequence_name};
	my $sequence_length = $sequence_name_to_length{$sequence_name};
	
	# calculates distance between this sequence and all already included sequences
	# keeps track of smallest distance
	my $smallest_distance_to_included_sequence = -1;
	foreach my $included_sequence_name(@included_sequences)
	{
		my $included_sequence = $sequence_name_to_sequence{$included_sequence_name};
		
		# generates a file with this sequence and this lineage sequence
		my $temp_file = $fasta_file."_temp.fasta";
		open TEMP_FILE, ">$temp_file" || die "Could not open $temp_file to write; terminating =(\n";
		print TEMP_FILE ">".$included_sequence_name.$NEWLINE;
		print TEMP_FILE $included_sequence.$NEWLINE;
		print TEMP_FILE ">".$sequence_name.$NEWLINE;
		print TEMP_FILE $sequence.$NEWLINE;
		close TEMP_FILE;
		
		# aligns this sequence and this included sequence
		my $temp_file_aligned = $temp_file."_aligned.fasta";
		`$mafft_file_path_or_command $temp_file > $temp_file_aligned`;
		
		# reads in this sequence and included sequence aligned
		my $current_sequence = "";
		my $current_sequence_name = "";
		my %aligned_sequence_name_to_sequence = (); # key: sequence name -> value: sequence read in
		open ALIGNED_FASTA_FILE, "<$temp_file_aligned" || die "Could not open $temp_file_aligned to read; terminating =(\n";
		while(<ALIGNED_FASTA_FILE>) # for each line in the file
		{
			chomp;
			if($_ =~ /^>(.*)/) # header line
			{
				# process previous sequence if it has been read in
				if($current_sequence)
				{
					$aligned_sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
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
			$aligned_sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
		}
		close ALIGNED_FASTA_FILE;
		
		# counts number unambiguous differences between this sequence and included sequence
		my @included_sequence_aligned_bases = split(//, $aligned_sequence_name_to_sequence{$included_sequence_name});
		my @sequence_aligned_bases = split(//, $aligned_sequence_name_to_sequence{$sequence_name});
		
		my $max_position = 0;
		if(scalar @included_sequence_aligned_bases < scalar @sequence_aligned_bases)
		{
			$max_position = scalar @included_sequence_aligned_bases - 1;
		}
		else
		{
			$max_position = scalar @sequence_aligned_bases - 1;
		}
		
		my $number_differences = 0;
		foreach my $position(0..$max_position)
		{
			my $included_sequence_base = uc($included_sequence_aligned_bases[$position]);
			my $sequence_base = uc($sequence_aligned_bases[$position]);
			
			if(is_unambiguous_base($included_sequence_base) and is_unambiguous_base($sequence_base)
				and $included_sequence_base ne $sequence_base)
			{
				$number_differences++;
			}
		}
		
		# updates smallest distance to an included sequence
		if($smallest_distance_to_included_sequence == -1
			or $number_differences < $smallest_distance_to_included_sequence)
		{
			$smallest_distance_to_included_sequence = $number_differences;
		}
		
		# deletes temp files
		`rm $temp_file`;
		`rm $temp_file_aligned`;
	}
	
	# if there are no included sequences yet, adds this one
	# if the smallest distance from this sequence to an already included sequence is at
	# least N% the length of this sequence, adds it
	if(scalar @included_sequences == 0
		or $smallest_distance_to_included_sequence >= $diversity * $sequence_length)
	{
		push @included_sequences, $sequence_name;
		print ">".$sequence_name.$NEWLINE;
		print $sequence.$NEWLINE;
	}
}


# returns 1 if base is A, T, C, or G, 0 if not
sub is_unambiguous_base
{
	my $base = $_[0];
	
	if($base eq "A" or $base eq "a")
	{
		return 1;
	}
	if($base eq "T" or $base eq "t")
	{
		return 1;
	}
	if($base eq "C" or $base eq "c")
	{
		return 1;
	}
	if($base eq "G" or $base eq "g")
	{
		return 1;
	}
	
	return 0;
}


# May 13, 2024
