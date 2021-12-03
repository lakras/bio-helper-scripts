#!/usr/bin/env perl

# Masks (replaces with Ns) alleles with low read depths.

# Positions in read depth table must be relative to same reference appearing in
# alignment fasta file. Reference must be first sequence in alignment fasta file.
# Sequence names in alignment fasta file must match read depth file names.

# Usage:
# perl mask_low_read_depth_alleles.pl [alignment fasta file path]
# [list of read depth tables] [minimum read depth]

# Prints to console. To print to file, use
# perl mask_low_read_depth_alleles.pl [alignment fasta file path]
# [list of read depth tables] [minimum read depth] > [output fasta file path]


use strict;
use warnings;


my $alignment_file = $ARGV[0]; # fasta alignment; reference sequence must appear first
my $read_depth_files = $ARGV[1]; # file containing a list of read depth files, one for each sample; positions must be relative to same reference used in both fasta alignment files; filenames must contain sample names used in consensus genome alignment
my $minimum_read_depth = $ARGV[2]; # masks any alleles with lower read depth


my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in changes file


# columns in read-depth tables produced by samtools:
my $READ_DEPTH_REFERENCE_COLUMN = 0; # reference must be same across all input files
my $READ_DEPTH_POSITION_COLUMN = 1; # 1-indexed
my $READ_DEPTH_COLUMN = 2;


# replacement to masked alelles
my $MASKED_ALLELE = "N";


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
if(!$minimum_read_depth or $minimum_read_depth < 1)
{
	print STDERR "Error: minimum read depth ".$minimum_read_depth." is <1 or not provided. Exiting.\n";
	die;
}


# reads in sample names from alignment file
my %all_samples = (); # key: sample name -> value: 1
open FASTA_FILE, "<$alignment_file" || die "Could not open $alignment_file to read; terminating =(\n";
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
# prints updated fasta sequences with low read-depth positions masked
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
	
	if(!$read_depth_read_in_for_sample{$current_sequence_name})
	{
		# prints sequence as is
		print ">".$current_sequence_name.$NEWLINE;
		print $current_sequence.$NEWLINE;
	
		print STDERR "Warning: no read depth table read in for sequence "
			.$current_sequence_name.". Not filtering sample.\n";
		return;
	}
	
	# masks low read-depth alleles
	foreach my $position(keys %{$sample_to_position_to_read_depth{$current_sequence_name}})
	{
		# retrieves read depth at this position
		my $read_depth = $sample_to_position_to_read_depth{$current_sequence_name}{$position};
		
		# masks allele if it has low read depth
		if($read_depth < $minimum_read_depth)
		{
			# retrieves string index corresponding to this position
			# (if no gaps in reference, string index will be position-1)
			if(defined $position_to_string_index{$position})
			{
				my $string_index = $position_to_string_index{$position};
			
				# verifies that position (1-indexed) is within range
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
						.") is out of range of sequence ".$current_sequence_name.".\n";
				}
			}
			else
			{
				print STDERR "Warning: position ".$position." is out of range of sequence "
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
