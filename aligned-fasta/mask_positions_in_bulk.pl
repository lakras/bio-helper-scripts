#!/usr/bin/env perl

# Masks (replaces with Ns) alleles at indicated positions. Operates separately on each
# sequence as described in input table.

# Positions must be relative to same reference appearing in alignment fasta file.
# Reference must be first sequence in alignment fasta file. Does not mask bases that
# align to gaps in reference.

# Usage:
# perl mask_positions_in_bulk.pl [alignment fasta file path]
# [tab-separated table containing sequence name in first column,
# first and last positions of regions to mask in this sequence, space separated, in second column]
# [optional first position in additional region to mask in all sequences]
# [optional last position in additional region to mask in all sequences]
# [optional first position in another additional region to mask in all sequences]
# [optional last position in another additional region to mask in all sequences]
# [etc.]

# Prints to console. To print to file, use
# perl mask_positions_in_bulk.pl [alignment fasta file path]
# [tab-separated table containing sequence name in first column,
# first and last positions of regions to mask in this sequence, space separated, in second column]
# [optional first position in additional region to mask in all sequences]
# [optional last position in additional region to mask in all sequences]
# [optional first position in another additional region to mask in all sequences]
# [optional last position in another additional region to mask in all sequences]
# [etc.] > [output fasta file path]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment; reference sequence must appear first
my $input_table = $ARGV[1]; # tab-separated table containing sequence name in first column, first and last positions of regions to mask, space separated, in second column
my @starts_and_ends_of_additional_regions_to_mask = @ARGV[2..$#ARGV]; # first position in region to mask (1-indexed, relative to reference), last position in region to mask (1-indexed, relative to reference), first position in another region to mask, last position in another region to mask, etc.


my $DELIMITER = "\t";
my $NEWLINE = "\n";

my $MASKED_ALLELE = "N"; # replacement to masked alelles
my $MASK_REFERENCE_SEQUENCE = 0; # if 1, masks positions in reference sequence as well

# input table columns:
my $SEQUENCE_NAME_COLUMN = 0;
my $REGIONS_TO_MASK_COLUMN = 1;
my $REGIONS_TO_MASK_DELIMITER = " ";


# verifies that fasta alignment file exists and is non-empty
if(!$alignment_file)
{
	print STDERR "Error: no input fasta alignment file provided. Exiting.\n";
	die;
}
if(!-e $alignment_file)
{
	print STDERR "Error: input fasta alignment file does not exist:\n\t"
		.$alignment_file."\nExiting.\n";
	die;
}
if(-z $alignment_file)
{
	print STDERR "Error: input fasta alignment file is empty:\n\t"
		.$alignment_file."\nExiting.\n";
	die;
}

# verifies that input table exists and is non-empty
if(!$input_table)
{
	print STDERR "Error: no input table provided. Exiting.\n";
	die;
}
if(!-e $input_table)
{
	print STDERR "Error: input table does not exist:\n\t".$input_table."\nExiting.\n";
	die;
}
if(-z $input_table)
{
	print STDERR "Error: input table is empty:\n\t".$input_table."\nExiting.\n";
	die;
}


# reads in input table: saves regions to mask for each sequence
my %sequence_name_to_regions_to_mask = (); # key: sequence name -> value: list of positions defining regions to mask (start, end, start, end, start, end, etc.)
open INPUT_TABLE, "<$input_table" || die "Could not open $input_table to read; terminating =(\n";
while(<INPUT_TABLE>) # for each line in the file
{
	# reads in this line and determines if it should be printed
	chomp;
	if($_ =~ /\S/) # non-empty line
	{
		# parses this line
		my @input_table_items = split($DELIMITER, $_);
		my $sequence_name = $input_table_items[$SEQUENCE_NAME_COLUMN];
		my @starts_and_ends_of_regions_to_mask = split($REGIONS_TO_MASK_DELIMITER, $input_table_items[$REGIONS_TO_MASK_COLUMN]);
		
		# saves regions to mask for this sequence
		$sequence_name_to_regions_to_mask{$sequence_name} = \@starts_and_ends_of_regions_to_mask;
	}
}
close INPUT_TABLE;


# reads in fasta sequences
# prints updated fasta sequences with positions to mask masked
my %position_to_string_index = (); # key: position (1-indexed) relative to reference -> value: index (0-indexed) in sequence string
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
				my $position = 0; # 1-indexed relative to reference
				for(my $base_index = 0; $base_index < length($reference_sequence); $base_index++)
				{
					my $reference_base = $reference_values[$base_index];
					if(is_base($reference_base))
					{
						# increments position only if valid base in reference sequence
						$position++;
		
						# maps position to string index
						$position_to_string_index{$position} = $base_index;
					}
				}
				
				if($MASK_REFERENCE_SEQUENCE)
				{
					process_sequence();
				}
		
				# print reference sequence and its name
				print ">".$reference_sequence_name.$NEWLINE;
				print $reference_sequence.$NEWLINE;
			}
			else # previous sequence is not reference sequence
			{
				process_sequence();
			}
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
process_sequence();
close FASTA_FILE;


# introduces changes described in changes file and prints modified sequence
sub process_sequence
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
	
	
	# retrieves list of positions defining regions to mask
	my @starts_and_ends_of_input_regions = (@starts_and_ends_of_additional_regions_to_mask,
		@{$sequence_name_to_regions_to_mask{$current_sequence_name}});

	# pulls out starts and ends of regions to mask
	my @starts_of_regions_to_mask = ();
	my @ends_of_regions_to_mask = ();
	my $index = 0;
	foreach my $position(@starts_and_ends_of_input_regions)
	{
		if($index % 2 == 0)
		{
			push(@starts_of_regions_to_mask, $position);
		}
		else
		{
			push(@ends_of_regions_to_mask, $position);
		}
		$index++;
	}


	# verifies that regions to mask are provided and make sense
	if(scalar @starts_of_regions_to_mask ne scalar @ends_of_regions_to_mask)
	{
		print STDERR "Error: different numbers of start and end positions of regions to "
			."mask. Exiting.\n";
		die;
	}
	foreach my $region_index(0..$#starts_of_regions_to_mask)
	{
		my $start_of_region_to_mask = $starts_of_regions_to_mask[$region_index];
		my $end_of_region_to_mask = $ends_of_regions_to_mask[$region_index];
	
		if($start_of_region_to_mask < 1 or $start_of_region_to_mask < 1)
		{
			print STDERR "Error: position to mask < 1: ".$start_of_region_to_mask."-"
				.$end_of_region_to_mask.". Exiting.\n";
			die;
		}
	
		if($end_of_region_to_mask < $start_of_region_to_mask)
		{
			print STDERR "Error: end earlier than start of region to mask: "
				.$start_of_region_to_mask."-".$end_of_region_to_mask.". Exiting.\n";
			die;
		}
	}


	# creates easy look-up of whether or not position should be masked
	my %position_is_in_input_region = (); # key: position -> value: 1 if position should be masked
	foreach my $region_index(0..$#starts_of_regions_to_mask)
	{
		my $start_of_region_to_mask = $starts_of_regions_to_mask[$region_index];
		my $end_of_region_to_mask = $ends_of_regions_to_mask[$region_index];
	
		foreach my $position($start_of_region_to_mask..$end_of_region_to_mask)
		{
			$position_is_in_input_region{$position} = 1;
		}
	}
	
	
	# masks positions to mask
	foreach my $position(keys %position_is_in_input_region)
	{
		if($position_is_in_input_region{$position}) # this position is in region marked for masking
		{
			# retrieves string index corresponding to this position
			# (if no gaps in reference, string index will be position-1)
			if(defined $position_to_string_index{$position})
			{
				my $string_index = $position_to_string_index{$position};
			
				# verifies that position (1-indexed) is within region
				if($string_index < length($current_sequence))
				{
					my $observed_current_allele = substr($current_sequence, $string_index, 1);
					if(is_base($observed_current_allele))
					{
						# updates allele at position
						substr($current_sequence, $string_index, 1, $MASKED_ALLELE);
					}
				}
				else
				{
					print STDERR "Warning: position ".$position." (string index ".$string_index
						.") is out of region of sequence ".$current_sequence_name.".\n";
				}
			}
			else
			{
				print STDERR "Warning: position ".$position." is out of region of sequence "
					.$current_sequence_name.".\n";
			}
		}
	}
	
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


# January 26, 2021
# July 14, 2021
# November 11, 2021
# March 20, 2022
# March 24, 2022
