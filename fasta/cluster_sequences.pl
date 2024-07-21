#!/usr/bin/env perl

# Clusters sequences by similarity.

# Usage:
# perl cluster_sequences.pl [sequences fasta file] [percent identity, for example 80]
# [file path of MAFFT executable file (mafft.bat) or mafft command]

# Prints to console. To print to file, use
# perl cluster_sequences.pl [sequences fasta file] [percent identity, for example 80]
# [file path of MAFFT executable file (mafft.bat) or mafft command] > [output table]


use strict;
use warnings;

my $sequences_fasta = $ARGV[0];
my $minimum_identity = $ARGV[1];
my $mafft_file_path_or_command = $ARGV[2];


my $TEMP_FILE_EXTENSION = "_temp.fasta";
my $ALIGNMENT_FILE_EXTENSION = "_aligned.fasta";


# verifies that input fasta exists
if(!$sequences_fasta or !-e $sequences_fasta or -z $sequences_fasta)
{
	print STDERR "Error: input fasta not provided, does not exist, or empty:\n\t"
		.$sequences_fasta."\n";
	next;
}

# verifies that mafft executable exists or mafft command provided
if(!$mafft_file_path_or_command)
{
	print STDERR "Error: mafft executable or command not provided:\n\t"
		.$mafft_file_path_or_command."\n";
	next;
}

# verifies that identity is >0
if(!$minimum_identity or $minimum_identity < 1)
{
	print STDERR "Error: minimum identity not entered or is <1: ".$minimum_identity."\n";
	next;
}


# reads in sequences
my %sequence_name_to_sequence = (); # key: sequence name -> value: sequence
my %sequence_name_to_length = (); # key: sequence name -> value: sequence length
open FASTA_FILE, "<$sequences_fasta" || die "Could not open $sequences_fasta to read; terminating =(\n";
my $sequence_name = "";
my $sequence = "";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# processes previous sequence
		if($sequence_name and $sequence)
		{
			$sequence_name_to_sequence{$sequence_name} = $sequence;
			$sequence_name_to_length{$sequence_name} = sequence_length($sequence);
		}
	
		# stars processing this sequence
		$sequence_name = $1;
		$sequence = "";
	}
	else
	{
		$sequence .= $_;
	}
}
close FASTA_FILE;

# processes final sequence
if($sequence_name and $sequence)
{
	$sequence_name_to_sequence{$sequence_name} = $sequence;
	$sequence_name_to_length{$sequence_name} = sequence_length($sequence);
}


# sort sequence names by their sequence lengths in descending order
my @sequence_names_sorted_by_sequence_length_descending = sort { $sequence_name_to_length{$b} <=> $sequence_name_to_length{$a} } keys %sequence_name_to_sequence;

# for each sequence, sorted from longest to shortest
my %cluster_id_to_name_of_longest_sequence = (); # key: cluster id -> value: sequence name of longest sequence in cluster
# my %cluster_id_to_sequences_list = (); # key: cluster id -> value: list of names of sequences in this cluster, as a string
my %sequence_name_to_cluster_id = (); # key: sequence name -> value: cluster sequence is assigned to
my $cluster_count = 0; # most recently created cluster
foreach my $sequence_name(@sequence_names_sorted_by_sequence_length_descending)
{
	print STDERR "processing ".$sequence_name."...\n";
	my $sequence = $sequence_name_to_sequence{$sequence_name};
	my $sequence_assigned_to_cluster = 0;

	# for each cluster:
	foreach my $cluster_id(keys %cluster_id_to_name_of_longest_sequence)
	{
		if(!$sequence_assigned_to_cluster) # if sequence hasn't been assigned to a cluster:
		{
			my $name_of_longest_sequence_in_cluster = $cluster_id_to_name_of_longest_sequence{$cluster_id};
			my $longest_sequence_in_cluster = $sequence_name_to_sequence{$name_of_longest_sequence_in_cluster};
			
			# print sequence and longest cluster sequence to a file
			my $temp_file = $sequences_fasta.$TEMP_FILE_EXTENSION;
			open TEMP_FILE, ">$temp_file" || die "Could not open $temp_file to write; terminating =(\n";
			print TEMP_FILE ">".$sequence_name."\n";
			print TEMP_FILE $sequence."\n";
			print TEMP_FILE ">".$name_of_longest_sequence_in_cluster."\n";
			print TEMP_FILE $longest_sequence_in_cluster."\n";
			close TEMP_FILE;
			
			# align sequence to longest sequence in cluster
			my $temp_file_aligned = $temp_file.$ALIGNMENT_FILE_EXTENSION;
			`$mafft_file_path_or_command $temp_file > $temp_file_aligned`;
			
			# read in aligned sequences
			my $sequence_aligned = "";
			my $longest_sequence_in_cluster_aligned = "";
			open ALIGNMENT, "<$temp_file_aligned" || die "Could not open $temp_file_aligned to read; terminating =(\n";
			my $current_sequence_name = "";
			my $current_sequence = "";
			while(<ALIGNMENT>) # for each line in the file
			{
				chomp;
				if($_ =~ /^>(.*)$/) # header line
				{
					# processes previous sequence
					if($current_sequence_name and $current_sequence)
					{
						$sequence_aligned = $current_sequence;
					}
				
					# stars processing this sequence
					$current_sequence_name = $1;
					$current_sequence = "";
				}
				else
				{
					$current_sequence .= $_;
				}
			}
			close ALIGNMENT;
			
			# processes final sequence
			if($current_sequence_name and $current_sequence)
			{
				$longest_sequence_in_cluster_aligned = $current_sequence;
			}
			
			# count number bases of sequence matched by cluster sequence
			my $number_bases_matched = 0;
			for(my $base_index = 0; $base_index < length($longest_sequence_in_cluster_aligned); $base_index++)
			{
				my $sequence_base = substr($sequence_aligned, $base_index, 1);
				my $longest_sequence_in_cluster_base = substr($longest_sequence_in_cluster_aligned, $base_index, 1);
		
				if(is_unambiguous_base($sequence_base) and is_unambiguous_base($longest_sequence_in_cluster_base)
					and $sequence_base eq $longest_sequence_in_cluster_base)
				{
					$number_bases_matched++;
				}
			}
			
			# if proportion bases matched >80% of sequence length, add sequence to cluster and mark to stop comparing
			if($number_bases_matched / $sequence_name_to_length{$sequence_name} * 100 >= $minimum_identity)
			{
				$sequence_assigned_to_cluster = 1;
				$sequence_name_to_cluster_id{$sequence_name} = $cluster_id;
			}
		}
	}
	
	# if sequence hasn't been assigned to a cluster, create a new cluster with this sequence
	if(!$sequence_assigned_to_cluster)
	{
		$cluster_count++;
		$cluster_id_to_name_of_longest_sequence{$cluster_count} = $sequence_name;
		$sequence_name_to_cluster_id{$sequence_name} = $cluster_count;
	}
}

# for each sequence, print cluster id and sequence name, tab separated
foreach my $sequence_name(keys %sequence_name_to_cluster_id)
{
	print $sequence_name_to_cluster_id{$sequence_name};
	print "\t";
	print $sequence_name;
	print "\n";
}

	
# returns sequence length
sub sequence_length
{
	my $sequence = $_[0];
	
	# capitalize sequence
	$sequence = uc($sequence);
	
	# counts number bases or unambiguous bases in this sequence
	my $sequence_length = 0;
	foreach my $base(split //, $sequence)
	{
		if(is_base($base))
		{
			$sequence_length++;
		}
	}
	return $sequence_length;
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


# July 19, 2024

