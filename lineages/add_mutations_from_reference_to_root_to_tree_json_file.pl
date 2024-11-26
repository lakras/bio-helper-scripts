#!/usr/bin/env perl

# Adds mutations from reference to root to tree.json file for use in Nextclade.

# Usage:
# perl add_mutations_from_reference_to_root_to_tree_json_file.pl [tree.json file]
# [reference sequence fasta file] [ancestral sequences fasta file]
# [mafft command or filepath]

# Prints to console. To print to file, use
# perl add_mutations_from_reference_to_root_to_tree_json_file.pl [tree.json file]
# [reference sequence fasta file] [ancestral sequences fasta file]
# [mafft command or filepath] > [updated tree.json file]


use strict;
use warnings;


my $tree_json_file = $ARGV[0];
my $reference_fasta = $ARGV[1];
my $ancestral_fasta = $ARGV[2];
my $mafft = $ARGV[3];


my $NEWLINE = "\n";
my $ROOT_SEQUENCE_NAME = "NODE_0000000";


# verifies that input files exist and are non-empty
if(!$tree_json_file or !-e $tree_json_file or -z $tree_json_file)
{
	print STDERR "Error: input tree.json file does not exist or is empty:\n\t"
		.$tree_json_file."\nExiting.\n";
	die;
}
if(!$reference_fasta or !-e $reference_fasta or -z $reference_fasta)
{
	print STDERR "Error: input reference fasta file does not exist or is empty:\n\t"
		.$reference_fasta."\nExiting.\n";
	die;
}
if(!$ancestral_fasta or !-e $ancestral_fasta or -z $ancestral_fasta)
{
	print STDERR "Error: input ancestral fasta file does not exist or is empty:\n\t"
		.$ancestral_fasta."\nExiting.\n";
	die;
}


# read in root sequence (NODE_0000000) in ancestral sequences fasta file and print just
# that first sequence to temp file
# reads in fasta file and retrieves sequences matching query sequence names
my $root_fasta = $ancestral_fasta."_".$ROOT_SEQUENCE_NAME.".fasta";
open ROOT, ">$root_fasta" || die "Could not open $root_fasta to write; terminating =(\n";
open ANCESTRAL_FASTA, "<$ancestral_fasta" || die "Could not open $ancestral_fasta to read; terminating =(\n";
my $printing_this_sequence = 0; # 1 if we are printing the sequence we are currently reading
while(<ANCESTRAL_FASTA>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# checks if this sequence name is one of our query sequences
		my $sequence_name = $1;
		$printing_this_sequence = 0;
		if($sequence_name eq $ROOT_SEQUENCE_NAME)
		{
			# records that we are printing lines belonging to this sequence
			$printing_this_sequence = 1;
		}
	}
	
	# prints this line (header or sequence) if we are printing this sequence
	if($printing_this_sequence)
	{
		print ROOT $_."\n";
	}
}
close ANCESTRAL_FASTA;


# aligns reference sequence and root sequence
my $concat_file = $reference_fasta."_".$ROOT_SEQUENCE_NAME.".fasta";
`cat $reference_fasta $root_fasta > $concat_file`;
my $alignment_file = $reference_fasta."_".$ROOT_SEQUENCE_NAME."_aligned.fasta";
`$mafft $concat_file > $alignment_file`;


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


# reads in the two aligned fasta sequences
my $sequence_1 = "";
my $sequence_2 = "";
my $reading_sequence_number = 0;
open FASTA_FILE, "<$alignment_file" || die "Could not open $alignment_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		$reading_sequence_number++;
	}
	else
	{
		if($reading_sequence_number == 1)
		{
			$sequence_1 .= $_;
		}
		elsif($reading_sequence_number == 2)
		{
			$sequence_2 .= $_;
		}
		else
		{
			print STDERR "Warning: more than two aligned sequences provided; ignoring"
				." additional sequences.\n";
		}
	}
}
close FASTA_FILE;


# retrieves bases
my @sequence_1_bases = split('', $sequence_1);
my @sequence_2_bases = split('', $sequence_2);


# verifies that they are the same length
if(scalar @sequence_1_bases != scalar @sequence_2_bases)
{
	print STDERR "Error: aligned sequences are not the same character length. Exiting.\n";
	die;
}

# saves differences
my $differences = "";
for (my $index = 0; $index < scalar @sequence_1_bases; $index++)
{
	if(uc $sequence_1_bases[$index] ne uc $sequence_2_bases[$index])
	{
		if($differences)
		{
			$differences .= ", ";
		}
		$differences .= "\"";
		$differences .= uc $sequence_1_bases[$index];
		$differences .= $index + 1;
		$differences .= uc $sequence_2_bases[$index];
		$differences .= "\"";
	}
}


# read in tree.json file and add differences between reference sequence and root sequence
# to first instance of ""mutations": "
my $first_mutations_instance_found = 0;
open TREE_JSON, "<$tree_json_file" || die "Could not open $tree_json_file to read; terminating =(\n";
while(<TREE_JSON>) # for each line in the file
{
	chomp;
	if($_ =~ /      "mutations": \{\}/)
	{
		if(!$first_mutations_instance_found)
		{
			$_ = "      \"mutations\": { \"nuc\": [".$differences."]}"
		}
		$first_mutations_instance_found = 1;
	}
	print $_.$NEWLINE;
}
close TREE_JSON;


# November 26, 2024
