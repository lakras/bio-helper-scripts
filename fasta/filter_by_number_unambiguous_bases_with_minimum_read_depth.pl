#!/usr/bin/env perl

# Filters sequences in fasta file by number positions with an unambiguous base (A, T, C,
# or G) and read depth at least the minimum read depth.

# Positions in read depth tables must be relative to position in each fasta sequence.
# Sequence names in read depth tables must match those in alignment file.

# Usage:
# perl filter_by_number_unambiguous_bases_with_minimum_read_depth.pl [fasta file path]
# [list of read depth tables] [minimum read depth]
# [minimum number unabiguous bases with at least minimum read depth]

# Prints to console. To print to file, use
# perl filter_by_number_unambiguous_bases_with_minimum_read_depth.pl [fasta file path]
# [list of read depth tables] [minimum read depth]
# [minimum number unabiguous bases with at least minimum read depth]
# > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # fasta file
my $read_depth_files = $ARGV[1]; # file containing a list of read depth files, one for each sample; positions must be relative to same reference used in both fasta alignment files; filenames must contain sample names used in consensus genome alignment
my $minimum_read_depth = $ARGV[2]; # masks any alleles with lower read depth
my $minimum_unambiguous_bases_with_read_depth = $ARGV[3]; # minimum number unabiguous bases with at least minimum read depth


my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in changes file


# columns in read-depth tables produced by samtools:
my $READ_DEPTH_REFERENCE_COLUMN = 0; # reference must be same across all input files
my $READ_DEPTH_POSITION_COLUMN = 1; # 1-indexed
my $READ_DEPTH_COLUMN = 2;


# verifies that fasta file exists and is non-empty
if(!$fasta_file)
{
	print STDERR "Error: no input fasta file provided. Exiting.\n";
	die;
}
if(!-e $fasta_file)
{
	print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
	die;
}
if(-z $fasta_file)
{
	print STDERR "Error: input fasta file is empty:\n\t".$fasta_file."\nExiting.\n";
	die;
}

# verifies that read depth table exists and is non-empty
if(!$read_depth_files)
{
	print STDERR "Error: no read depth file provided. Exiting.\n";
	die;
}
if(!-e $read_depth_files)
{
	print STDERR "Error: read depth file does not exist:\n\t".$read_depth_files."\nExiting.\n";
	die;
}
if(-z $read_depth_files)
{
	print STDERR "Error: read depth file is empty:\n\t".$read_depth_files."\nExiting.\n";
	die;
}

# verities that minimum read depth makes sense
# if(!$minimum_read_depth or $minimum_read_depth < 1)
# {
# 	print STDERR "Error: minimum read depth ".$minimum_read_depth." is <1 or not provided. Exiting.\n";
# 	die;
# }


# reads in sample names from alignment file
my %all_samples = (); # key: sample name -> value: 1
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		$all_samples{$1} = 1;
	}
}
close FASTA_FILE;


# reads in read depth tables
my %sample_to_position_to_read_depth = (); # key: sample name -> key: position (1-indexed, relative to reference) -> value: read depth at this position
my %read_depth_read_in_for_sample = (); # key: sample name -> value: 1 if read depth table read in
open READ_DEPTH_TABLES_LIST, "<$read_depth_files" || die "Could not open $read_depth_files to read; terminating =(\n";
while(<READ_DEPTH_TABLES_LIST>) # for each line in the file
{
	chomp;
	my $read_depth_table = $_;
	if($read_depth_table and $read_depth_table =~ /\S/) # non-empty string
	{
		if(!-e $read_depth_table) # file does not exist
		{
			print STDERR "Error: read depth table does not exist:\n\t"
				.$read_depth_table."\nExiting.\n";
			die;
		}
		elsif(-z $read_depth_table) # file is empty
		{
			print STDERR "Warning: skipping empty read depth table:\n\t"
				.$read_depth_table."\n";
		}
		else # file exists and is non-empty
		{
			# retrieve sample name from file name
			my $sample_name = "";
			foreach my $potential_sample_name(sort {length $a <=> length $b} keys %all_samples)
			{
				if($read_depth_table =~ /$potential_sample_name/)
				{
					$sample_name = $potential_sample_name;
				}
			}
			
			if($sample_name)
			{
				# read in read depth table
				open READ_DEPTH_TABLE, "<$read_depth_table"
					|| die "Could not open $read_depth_table to read; terminating =(\n";
				while(<READ_DEPTH_TABLE>) # for each line in the file
				{
					chomp;
					my $line = $_;
					if($line =~ /\S/) # non-empty line
					{
						# parses this line
						my @items = split($DELIMITER, $line);
						my $position = $items[$READ_DEPTH_POSITION_COLUMN];
						my $read_depth = $items[$READ_DEPTH_COLUMN];

						# saves read depth
						$sample_to_position_to_read_depth{$sample_name}{$position} = $read_depth;
					}
				}
				close READ_DEPTH_TABLE;
				$read_depth_read_in_for_sample{$sample_name} = 1;
			}
			else # sample name could not be retrieved
			{
				print STDERR "Warning: could not retrieve from filepath of read depth "
					."table a sample name that matches a sequence name from consensus "
					."genome alignment. Excluding read depth table:\n\t"
					.$read_depth_table."\n";
			}
		}
	}
}
close READ_DEPTH_TABLES_LIST;


# reads in fasta sequences
my $current_sequence = "";
my $current_sequence_name = "";
my %sequence_read_in_for_sample = (); # key: sample name -> value: 1 if sequence read in
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			process_sequence();
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


# verifies that we have seen all sequences corresponding to read depth tables
foreach my $sequence_name(keys %read_depth_read_in_for_sample)
{
	if(!$sequence_read_in_for_sample{$current_sequence_name})
	{
		print STDERR "Warning: no sequence read in corresponding to read depth table for "
			.$sequence_name.". Filtering out sample.\n"; 
	}
}


# introduces changes described in changes file and prints modified sequence
sub process_sequence
{
	# exit if no sequence or read depth table read in
	if(!$current_sequence)
	{
		return;
	}
	
	if(!$read_depth_read_in_for_sample{$current_sequence_name})
	{
		# prints sequence as is
		print ">".$current_sequence_name.$NEWLINE;
		print $current_sequence.$NEWLINE;
	
		print STDERR "Warning: no read depth table read in for sequence "
			.$current_sequence_name.". Filtering out sample.\n";
		return;
	}
	
	# records that we have seen this sequence
	$sequence_read_in_for_sample{$current_sequence_name} = 1;
	
	# counts unambiguous bases with minimum read depth
	my $number_unambiguous_bases_with_read_depth = 0;
	my @this_sequence_bases = split(//, $current_sequence);
	my $position = 0;
	foreach my $base(@this_sequence_bases)
	{
		$position++;
		my $read_depth = 0;
		if(defined $sample_to_position_to_read_depth{$current_sequence_name}{$position})
		{
			$read_depth = $sample_to_position_to_read_depth{$current_sequence_name}{$position};
		}
		if($read_depth >= $minimum_read_depth and is_unambiguous_base($base))
		{
			$number_unambiguous_bases_with_read_depth++;
		}
	}
	
	# prints sequence
	if($number_unambiguous_bases_with_read_depth >= $minimum_unambiguous_bases_with_read_depth)
	{
		print ">".$current_sequence_name.$NEWLINE;
		print $current_sequence.$NEWLINE;
	}
}


# returns 1 if base is A, T, C, or G, 0 if not
sub is_unambiguous_base
{
	my $base = $_[0];
	
	if($base eq "-")
	{
		print STDERR "Error: sequence contains gaps and is therefore an alignment. "
			."Exiting.\n";
		die;
	}
	
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

# January 26, 2021
# July 14, 2021
# November 11, 2021
# June 16, 2023
