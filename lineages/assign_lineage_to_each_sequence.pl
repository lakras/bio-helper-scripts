#!/usr/bin/env perl

# Assigns to each sequence the lineage that is genetically closest to it.

# Outputs table with columns:
# - sequence name
# - assigned lineage
# - distance from assigned lineage
# - distance from each lineage

# Usage:
# perl assign_lineage_to_each_sequence.pl [fasta file path]
# [lineage sequences fasta file path] [mafft command or file path]

# Prints to console. To print to file, use
# perl assign_lineage_to_each_sequence.pl [fasta file path]
# [lineage sequences fasta file path] [mafft command or file path]
# > [output table file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # fasta file
my $lineages_fasta_file = $ARGV[1]; # fasta files containing a representative sequence from each lineage
my $mafft_file_path_or_command = $ARGV[2]; 


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# reads in lineages fasta file
my $current_sequence = "";
my $current_sequence_name = "";
my %lineage_name_to_sequence = (); # key: lineage sequence name -> value: sequence read in
open LINEAGES_FASTA_FILE, "<$lineages_fasta_file" || die "Could not open $lineages_fasta_file to read; terminating =(\n";
while(<LINEAGES_FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			$lineage_name_to_sequence{$current_sequence_name} = $current_sequence;
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
	$lineage_name_to_sequence{$current_sequence_name} = $current_sequence;
}
close LINEAGES_FASTA_FILE;


# reads in fasta file
$current_sequence = "";
$current_sequence_name = "";
my %sequence_name_to_sequence = (); # key: sequence name -> value: sequence read in
my @sequences_in_order_read_in = (); # sequence names in order they appear in the fasta file
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
			push(@sequences_in_order_read_in, $current_sequence_name);
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
	push(@sequences_in_order_read_in, $current_sequence_name);
}
close FASTA_FILE;


# assigns lineage to each sequence
foreach my $sequence_name(@sequences_in_order_read_in) # for each sequence
{
	my $sequence = $sequence_name_to_sequence{$sequence_name};
	
	# compares sequence to each lineage
	my $closest_lineage = ""; # lineage closest to this sequence
	my $closest_lineage_distance = -1; # number unambiguous bases different between this sequence and closest lineage
	my $distances_to_all_lineages = ""; # IA: N, IB: N, etc.
	foreach my $lineage(sort keys %lineage_name_to_sequence) # for each lineage sequence
	{
		# generates a file with this sequence and this lineage sequence
		my $temp_file = $fasta_file."_temp.fasta";
		open TEMP_FILE, ">$temp_file" || die "Could not open $temp_file to write; terminating =(\n";
		print TEMP_FILE ">".$lineage.$NEWLINE;
		print TEMP_FILE $lineage_name_to_sequence{$lineage}.$NEWLINE;
		print TEMP_FILE ">".$sequence_name.$NEWLINE;
		print TEMP_FILE $sequence_name_to_sequence{$sequence_name}.$NEWLINE;
		close TEMP_FILE;
		
		# aligns this sequence and this lineage sequence
		my $temp_file_aligned = $temp_file."_aligned.fasta";
		`$mafft_file_path_or_command $temp_file > $temp_file_aligned`;
		
		# reads in this sequence and lineage sequence aligned
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
		
		# counts number unambiguous differences between this sequence and this lineage
		my @lineage_sequence_aligned_bases = split(//, $aligned_sequence_name_to_sequence{$lineage});
		my @sequence_aligned_bases = split(//, $aligned_sequence_name_to_sequence{$sequence_name});
		
		my $max_position = 0;
		if(scalar @lineage_sequence_aligned_bases < scalar @sequence_aligned_bases)
		{
			$max_position = scalar @lineage_sequence_aligned_bases - 1;
		}
		else
		{
			$max_position = scalar @sequence_aligned_bases - 1;
		}
		
		my $number_differences = 0;
		foreach my $position(0..$max_position)
		{
			my $lineage_base = uc($lineage_sequence_aligned_bases[$position]);
			my $sequence_base = uc($sequence_aligned_bases[$position]);
			
			if(is_unambiguous_base($lineage_base) and is_unambiguous_base($sequence_base)
				and $lineage_base ne $sequence_base)
			{
				$number_differences++;
			}
		}
		
		# determines if this is the new closest lineage
		if($closest_lineage_distance == -1
			or $number_differences < $closest_lineage_distance)
		{
			$closest_lineage = $lineage;
			$closest_lineage_distance = $number_differences;
		}
		
		# saves distance to this lineage
		if($distances_to_all_lineages)
		{
			$distances_to_all_lineages .= ", ";
		}
		$distances_to_all_lineages .= $lineage.": ".$number_differences;
		
		# deletes temporary files
		`rm $temp_file`;
		`rm $temp_file_aligned`;
	}
	
	# prints sequence name, closest lineage name, and distance from lineage
	print $sequence_name.$DELIMITER;
	print $closest_lineage.$DELIMITER;
	print $closest_lineage_distance.$DELIMITER;
	print $distances_to_all_lineages.$NEWLINE;
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

