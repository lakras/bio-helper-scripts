#!/usr/bin/env perl

# Prints list of lineage-defining positions and the lineages consistent with each allele.

# Lineage-defining positions are positions at which the aligned sequences have
# non-identical unambiguous (A, T, C, or G) bases.

# Reference sequence must be first sequence in alignment fasta. Output positions are
# 1-indexed relative to reference sequence.

# Usage:
# perl summarize_lineage_defining_SNPs.pl [alignment fasta file path]

# Prints to console. To print to file, use
# perl summarize_lineage_defining_SNPs.pl [alignment fasta file path] > [output file path]


use strict;
use warnings;


my $lineages_aligned_fasta = $ARGV[0]; # lineages aligned to reference; reference must be first sequence in file


my $DELIMITER = "\t";
my $NEWLINE = "\n";
my $NO_DATA = " ";


# verifies that input files exist and are non-empty
if(!$lineages_aligned_fasta or !-e $lineages_aligned_fasta or -z $lineages_aligned_fasta)
{
	print STDERR "Error: lineages aligned fasta is not a non-empty file:\n\t"
		.$lineages_aligned_fasta."\nExiting.\n";
	die;
}


# read in aligned lineages fasta file
my %lineage_name_to_genome = (); # key: sequence name -> value: lineage genome, including gaps froms alignment
my $reference_sequence = ""; # first sequence in alignment
my $reference_sequence_name = ""; # name of first sequence in alignment

open ALIGNED_LINEAGES_GENOMES, "<$lineages_aligned_fasta" || die "Could not open $lineages_aligned_fasta to read; terminating =(\n";
my $sequence = ""; # current sequence being read in
my $sequence_name = ""; # name of current sequence being read in
while(<ALIGNED_LINEAGES_GENOMES>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence
		$sequence = uc($sequence);
		if($sequence and $sequence_name)
		{
			if(!$reference_sequence) # reference sequence is first sequence in alignment
			{
				$reference_sequence = $sequence;
				$reference_sequence_name = $sequence_name;
			}
			else # not reference sequence
			{
				$lineage_name_to_genome{$sequence_name} = $sequence;
			}
			
		}
	
		# prepare for next sequence
		$sequence = "";
		$sequence_name = $1;
	}
	else
	{
		$sequence .= $_;
	}
}
# process final sequence
if($sequence and $sequence_name)
{
	$lineage_name_to_genome{$sequence_name} = uc($sequence);
}
close ALIGNED_LINEAGES_GENOMES;


# print list of lineages
print "lineages:\n";
foreach my $lineage_name(keys %lineage_name_to_genome)
{
	print "\t".$lineage_name."\n";
}
print "\n";


# process aligned lineages fasta file
# identify "defining positions" at which the lineages are different
my %is_lineage_defining_position = (); # key: position (1-indexed, relative to reference) -> value: 1 if position is lineage-defining position
my %position_to_base_to_matching_lineage = (); # key: lineage-defining position -> key: base -> value: lineage(s) with this base at this position
my $position = 0; # 1-indexed relative to reference
for(my $base_index = 0; $base_index < length($reference_sequence); $base_index++)
{
	my $reference_base = substr($reference_sequence, $base_index, 1);
	if(is_base($reference_base))
	{
		# increments position only if valid base in reference sequence
		$position++;
	
		# retrieves each lineage's base at this position
		# verifies that we have unambiguous bases in all lineages
		my %lineage_name_to_base = (); # key: lineage sequence name -> value: base at lineage
		my $all_lineages_have_unambiguous_bases = 1;
		foreach my $lineage_name(keys %lineage_name_to_genome)
		{
			my $lineage_genome = $lineage_name_to_genome{$lineage_name};
			if($base_index >= length($lineage_genome)) # no sequence at this index; we've gone out of range
			{
				$all_lineages_have_unambiguous_bases = 0;
			}
			else
			{
				my $base = substr($lineage_genome, $base_index, 1);
				if(!is_unambiguous_base($base))
				{
					$all_lineages_have_unambiguous_bases = 0;
				}
				$lineage_name_to_base{$lineage_name} = $base;
			}
		}
	
		# saves base from each lineage if this is a lineage-defining position
		if($all_lineages_have_unambiguous_bases)
		{
			# checks if all lineages have the same base at this position
			my $same_base_in_all_lineages = 1;
			my $previous_base = "";
			foreach my $lineage_name(keys %lineage_name_to_base)
			{
				my $lineage_base = $lineage_name_to_base{$lineage_name};
				if($previous_base)
				{
					if($lineage_base ne $previous_base)
					{
						$same_base_in_all_lineages = 0;
					}
				}
				else
				{
					$previous_base = $lineage_base;
				}
			}
		
			# saves each lineage's base at this lineage-defining position
			if(!$same_base_in_all_lineages) # lineage-defining position
			{
				# records that this is a lineage-defining position
				$is_lineage_defining_position{$position} = 1;
			
				# records lineage(s) matching each base
				foreach my $lineage_name(sort keys %lineage_name_to_base)
				{
					my $lineage_base = $lineage_name_to_base{$lineage_name};
					if($position_to_base_to_matching_lineage{$position}{$lineage_base})
					{
						$position_to_base_to_matching_lineage{$position}{$lineage_base} .= ", ";
					}
					$position_to_base_to_matching_lineage{$position}{$lineage_base} .= $lineage_name;
				}
			}
		}
	}
}


# prints lineage-defining positions and lineages consistent with each base appearing at a position
print "lineage-defining positions (1-indexed relative to reference ".$reference_sequence_name."):\n";
foreach my $position(sort {$a <=> $b} keys %is_lineage_defining_position)
{
	print add_comma_separators($position)."\n";
	foreach my $lineage_base(keys %{$position_to_base_to_matching_lineage{$position}})
	{
		my $matching_lineages = $position_to_base_to_matching_lineage{$position}{$lineage_base};
		
		print "\t".$lineage_base.": ".$matching_lineages."\n";
	}
}
print "\n";


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

# adds comma thousands separator(s)
# from https://stackoverflow.com/questions/33442240/perl-printf-to-use-commas-as-thousands-separator
sub add_comma_separators
{
	my $value = $_[0];
	
	my $text = reverse $value;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}


# July 14, 2021
