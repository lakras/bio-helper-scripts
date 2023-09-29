#!/usr/bin/env perl

# Uses alignment of consensus genome to reference to update read depths table positions
# with respect to self to positions with respect to the reference genome in the alignment.

# Reference must be first sequence in alignment fasta file. Consensus sequence names
# in read_depths tables and fasta alignment must match.

# Usage:
# perl rereference_positions_in_read_depths_table.pl
# [consensus sequence aligned to reference fasta file]
# [list of read_depths tables, one per line]

# Prints to console. To print to file, use
# perl rereference_positions_in_read_depths_table.pl
# [consensus sequence aligned to reference fasta file]
# [list of read_depths tables, one per line]# > [output read_depths table]


use strict;
use warnings;


my $consensus_sequence_aligned_to_reference = $ARGV[0]; # fasta alignment of consensus sequence aligned to reference; reference sequence must appear first; reference sequence may contain gaps
my $read_depths_tables_list = $ARGV[1]; # file containing list of filepaths of read_depths tables, one per line; in each read_depths table, reference must appear in first column and position must appear in second column


my $DELIMITER = "\t";
my $NEWLINE = "\n";

my $OUTPUT_FILE_EXTENSION = "_to_ref.txt";


# reads in aligned consensus sequences
my $reference_sequence_string_length = 0;
my %sequence_name_to_consensus_sequence = (); # key: sample name -> value: sequence
my $reference_sequence_name = "";
my @reference_bases;
open ALIGNED_CONSENSUS_SEQUENCES, "<$consensus_sequence_aligned_to_reference" || die "Could not open $consensus_sequence_aligned_to_reference to read; terminating =(\n";
my $sequence = "";
my $sequence_name = "";
while(<ALIGNED_CONSENSUS_SEQUENCES>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence
		$sequence = uc($sequence);
		if($sequence and $sequence_name)
		{
			if(!$reference_sequence_string_length) # reference sequence is first sequence in alignment
			{
				$reference_sequence_string_length = length $sequence;
				@reference_bases = split(//, $sequence);
				
				# removes anything after whitespace in reference sequence name
				$reference_sequence_name = $sequence_name;
				if($reference_sequence_name =~ /^(\S+)\s.*$/)
				{
					$reference_sequence_name = $1;
				}
			}
			else
			{
				# saves aligned sequence string
				$sequence_name_to_consensus_sequence{$sequence_name} = $sequence;
			}
		}
	
		# prepare for next sequence
		$sequence = "";
		$sequence_name = $1;
	}
	else
	{
		$sequence .= uc($_);
	}
}
# process final sequence
if($sequence and $sequence_name)
{
	# saves aligned sequence string
	$sequence_name_to_consensus_sequence{$sequence_name} = $sequence;
}
close ALIGNED_CONSENSUS_SEQUENCES;


# maps positions in consensus sequences to positions in reference
my %sequence_name_to_consensus_sequence_position_to_reference_sequence_position = ();
my %sequence_name_to_consensus_sequence_position_to_base = ();
for my $this_sequence_name(keys %sequence_name_to_consensus_sequence)
{
	my $this_consensus_sequence = $sequence_name_to_consensus_sequence{$this_sequence_name};
	my @this_consensus_sequence_bases = split(//, $this_consensus_sequence);
	
	my $reference_position = 0; # 1-indexed relative to reference
	my $this_consensus_sequence_position = 0; # 1-indexed relative to this consensus sequence
	for(my $base_index = 0; $base_index < $reference_sequence_string_length; $base_index++)
	{
		my $reference_base = $reference_bases[$base_index];
		if(is_base($reference_base))
		{
			# increments position only if valid base in reference sequence
			$reference_position++;
		}
		
		my $this_consensus_sequence_base = $this_consensus_sequence_bases[$base_index];
		if(is_base($this_consensus_sequence_base))
		{
			# increments position only if valid base in consensus sequence
			$this_consensus_sequence_position++;
		}
		
		if(is_base($this_consensus_sequence_base))
		{
			# maps position in this consensus sequence to position in reference sequence
			$sequence_name_to_consensus_sequence_position_to_reference_sequence_position
				{$this_sequence_name}{$this_consensus_sequence_position} = $reference_position;
		}
	}
}


# reads in read depths tables
# renumbers positions and outputs updated tables
open READ_DEPTHS_TABLES_LIST, "<$read_depths_tables_list"
	|| die "Could not open $read_depths_tables_list to read; terminating =(\n";
while(<READ_DEPTHS_TABLES_LIST>) # for each line in the file
{
	chomp;
	my $read_depths_table = $_;
	if($read_depths_table and $read_depths_table =~ /\S/) # non-empty string
	{
		# read in read_depths table
		open READ_DEPTHS_TABLE, "<$read_depths_table" || die "Could not open $read_depths_table to read; terminating =(\n";
		my $output_file = $read_depths_table.$OUTPUT_FILE_EXTENSION;
		open OUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";
		while(<READ_DEPTHS_TABLE>) # for each line in the file
		{
			chomp;
			my $line = $_;
			if($line =~ /\S/) # non-empty line
			{
				# parses this line
				my $consensus_sequence_name = "";
				my $position = -1;
				my $rest_of_line = "";
				if($line =~ /^([^\t]+)$DELIMITER(\d+)$DELIMITER(.+)$/)
				{
					$consensus_sequence_name = $1;
					$position = $2;
					$rest_of_line = $3;
				}
				
				# replaces position
				if($position != -1)
				{
					if(!$sequence_name_to_consensus_sequence_position_to_reference_sequence_position
						{$consensus_sequence_name}{$position})
					{
						print STDERR "Error: no reference sequence position corresponding "
							."to consensus sequence ".$consensus_sequence_name
							." position ".$position."\n";
					}
					$position = $sequence_name_to_consensus_sequence_position_to_reference_sequence_position
						{$consensus_sequence_name}{$position};
				}
				
				# prints result
				print OUT_FILE $reference_sequence_name.$DELIMITER;
				print OUT_FILE $position.$DELIMITER;
				print OUT_FILE $rest_of_line.$NEWLINE;
				
			}
		}
		close READ_DEPTHS_TABLE;
		close OUT_FILE;
	}
}
close READ_DEPTHS_TABLES_LIST;


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


# June 13, 2023
# June 15, 2023

