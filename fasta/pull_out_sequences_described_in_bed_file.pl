#!/usr/bin/env perl

# Pulls out subsets of sequences by name and position within that sequence from bed file.

# Usage:
# perl pull_out_sequences_described_in_bed_file.pl [fasta file path] [bed file path]
# [0 to output fasta sequence, 1 to add sequence as new column in bed file]

# Prints to console. To print to file, use
# perl pull_out_sequences_described_in_bed_file.pl [fasta file path] [bed file path]
# [0 to output fasta sequence, 1 to add sequence as new column in bed file]
# > [output file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0]; # fasta file
my $bed_file = $ARGV[1]; # tab-separated table with columns: sequence name, first position (0-indexed), non-inclusive end position (0-indexed), optional sub-sequence name, optional score, optional strand (+ or -); sequence names must match those in fasta file
my $output_as_column_in_bed_file = $ARGV[2]; # 0 to output fasta sequence, 1 to add sequence as new column in bed file


# in bed file:
my $SEQUENCE_NAME_COLUMN = 0;
my $START_POSITION_COLUMN = 1;
my $END_POSITION_COLUMN = 2;
my $BED_FILE_SUBSEQUENCE_NAME_COLUMN = 3; # optional
my $STRAND_COLUMN = 5; # optional

my $DELIMITER = "\t";
my $NEWLINE = "\n";


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

# verifies that input bed file exists and is non-empty
if(!$bed_file)
{
	print STDERR "Error: no input bed file provided. Exiting.\n";
	die;
}
if(!-e $bed_file)
{
	print STDERR "Error: input bed file does not exist:\n\t".$bed_file."\nExiting.\n";
	die;
}
if(-z $bed_file)
{
	print STDERR "Error: input bed file is empty:\n\t".$bed_file."\nExiting.\n";
	die;
}


# reads in sequence names in bed file
my %sequence_name_in_bed_file = (); # key: sequence name -> value: 1 if sequence name is in bed file
open BED_FILE, "<$bed_file" || die "Could not open $bed_file to read; terminating =(\n";
while(<BED_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/) # non-empty line
	{
		my @values = split($DELIMITER, $_);
		my $sequence_name = $values[$SEQUENCE_NAME_COLUMN];
		$sequence_name_in_bed_file{$sequence_name} = 1;
	}
}
close BED_FILE;


# reads in fasta sequences named in bed file
my %sequence_name_to_sequence = (); # key: sequence name -> value: sequence
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $current_sequence_name = "";
my $current_sequence = "";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /^>(.*)$/) # header line
	{
		# saves previous sequence if it appeared in bed file
		if($current_sequence_name and $current_sequence and $sequence_name_in_bed_file{$current_sequence_name})
		{
			$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
		}
		
		# updates current sequence name and clears current sequence
		$current_sequence_name = $1;
		$current_sequence = "";
	}
	else # sequence, not a header line
	{
		# adds to current sequence
		$current_sequence .= $line;
	}
}
close FASTA_FILE;

# saves last sequence if it appeared in bed file
if($current_sequence_name and $current_sequence and $sequence_name_in_bed_file{$current_sequence_name})
{
	$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
}


# reads in positions described in bed file and extracts the sequences at those positions
# from the fasta
open BED_FILE, "<$bed_file" || die "Could not open $bed_file to read; terminating =(\n";
while(<BED_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		# retrieves sequence name and start and end
		my @values = split($DELIMITER, $line);
		my $sequence_name = $values[$SEQUENCE_NAME_COLUMN];
		my $bed_file_subsequence_name = $values[$BED_FILE_SUBSEQUENCE_NAME_COLUMN];
		my $sequence_start = $values[$START_POSITION_COLUMN]; # first position (0-indexed)
		my $sequence_end = $values[$END_POSITION_COLUMN]; # non-inclusive end position (0-indexed)
		my $strand = $values[$STRAND_COLUMN]; # + or -
		
		# only retrieves sequence substring if we have read in the sequence
		my $sequence_substring = "";
		if($sequence_name_to_sequence{$sequence_name})
		{
			# retrieves described subset of sequence
			my $sequence = $sequence_name_to_sequence{$sequence_name};
			my $length_of_substring = $sequence_end - $sequence_start;
			$sequence_substring = substr($sequence, $sequence_start, $length_of_substring);
			
			# generates reverse complement if - strand
			if($strand eq "-")
			{
				my $sequence_substring_rc = "";
				foreach my $base(split //, $sequence_substring)
				{
					# retrieves complement of base
					my $base_rc = "";
					if($base eq "A")
					{
						$base_rc = "T";
					}
					elsif($base eq "T")
					{
						$base_rc = "A";
					}
					elsif($base eq "C")
					{
						$base_rc = "G";
					}
					elsif($base eq "G")
					{
						$base_rc = "C";
					}
					elsif($base eq "N")
					{
						$base_rc = "N";
					}
					elsif($base eq "a")
					{
						$base_rc = "t";
					}
					elsif($base eq "t")
					{
						$base_rc = "a";
					}
					elsif($base eq "c")
					{
						$base_rc = "g";
					}
					elsif($base eq "g")
					{
						$base_rc = "c";
					}
					elsif($base eq "n")
					{
						$base_rc = "n";
					}
					else
					{
						$base_rc = $base;
						print STDERR "Error: could not retrieve reverse-complement of "
							."base ".$base.".\n";
					}
					
					# adds base to start of sequence
					$sequence_substring_rc = $base_rc.$sequence_substring_rc;
				}
				$sequence_substring = $sequence_substring_rc;
			}
		}
		else # sequence named in bed file not found in fasta
		{
			print STDERR "Error: sequence not found in fasta: ".$sequence_name."\n";
		}
		
		# prints output
		if($output_as_column_in_bed_file) # print as extra column in bed file
		{
			print $line;
			print $DELIMITER;
			print $sequence_substring;
			print $NEWLINE;
		}
		else # print as fasta file
		{
			if($bed_file_subsequence_name)
			{
				print ">".$bed_file_subsequence_name;
			}
			else
			{
				print ">".$sequence_name."_".$sequence_start."-".$sequence_end;
			}
			print $NEWLINE;
			print $sequence_substring;
			print $NEWLINE;
		}
	}
}
close BED_FILE;


# June 9, 2022
