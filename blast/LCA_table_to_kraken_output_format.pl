#!/usr/bin/env perl

# Converts LCA output table to kraken output format. Treats paired reads as separate reads.

# Input table is output of retrieve_top_blast_hits_LCA_for_each_sequence.pl, with
# column titles (tab-separated):
# - sequence_name
# - LCA_taxon_id
# - LCA_taxon_rank
# - LCA_taxon_species
# - LCA_taxon_genus
# - LCA_taxon_family
# - evalue_of_top_hits
# - lowest_pident_of_top_hits
# - mean_pident_of_top_hits
# - highest_pident_of_top_hits
# - lowest_qcovs_of_top_hits
# - mean_qcovs_of_top_hits
# - highest_qcovs_of_top_hits
# - number_top_hits

# Kraken output format:
# https://github.com/DerrickWood/kraken2/blob/master/docs/MANUAL.markdown#standard-kraken-output-format


# Usage:
# perl LCA_table_to_kraken_output_format.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search]
# [fasta file that was input to blast search (to retrieve sequence lengths and names of unclassified sequences)] 


# Prints to console. To print to file, use
# perl LCA_table_to_kraken_output_format.pl
# [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search]
# [fasta file that was input to blast search (to retrieve sequence lengths and names of unclassified sequences)]
# > [output kraken format table]


use strict;
use warnings;


my $LCA_matches = $ARGV[0]; # output of retrieve_top_blast_hits_LCA_for_each_sequence.pl
my $fasta_file = $ARGV[1]; # fasta file that was input to blast search (to retrieve sequence lengths and names of unclassified sequences)

my $NO_DATA = "NA";
my $NEWLINE = "\n";
my $DELIMITER = "\t";

my $INCLUDE_AMBIGUOUS_BASES_IN_SEQUENCE_LENGTH = 1;

# blast LCA table columns:
my $sequence_name_column = 0;
my $LCA_taxon_id_column = 1;
my $LCA_taxon_rank_column = 2;
my $LCA_taxon_species_column = 3;
my $LCA_taxon_genus_column = 4;
my $LCA_taxon_family_column = 5;
my $evalue_of_top_hits_column = 6;
my $lowest_pident_of_top_hits_column = 7;
my $mean_pident_of_top_hits_column = 8;
my $highest_pident_of_top_hits_column = 9;
my $lowest_qcovs_of_top_hits_column = 10;
my $mean_qcovs_of_top_hits_column = 11;
my $highest_qcovs_of_top_hits_column = 12;
my $number_top_hits_column = 13;



# reads in sequence names and lengths from fasta file
my %sequence_name_to_length = (); # key: sequence name -> value: length of sequence
my %sequence_name_appears_in_LCA_table = (); # key: sequence name from fasta file -> value: 1 if sequence appears in LCA table, 0 if not
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
my $sequence_name = "";
my $sequence = "";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# processes previous sequence
		$sequence_name_to_length{$sequence_name} = sequence_length($sequence);
		$sequence_name_appears_in_LCA_table{$sequence_name} = 0;
	
		# starts processing this sequence
		$sequence_name = $1;
		$sequence = "";
	}
	else
	{
		$sequence .= $_;
	}
}
close FASTA_FILE;


# reads LCA table and prints rows for reads with hits
my $first_row = 1;
open LCA_MATCHES, "<$LCA_matches" || die "Could not open $LCA_matches to read\n";
while(<LCA_MATCHES>)
{
	chomp;
	my $line = $_;
	if($line =~ /\S/)
	{
		if($first_row)
		{
			# prints header line as is
			print $line.$NEWLINE;
			$first_row = 0;
		}
		else
		{
			# reads in relevant lines in row
			my @items = split($DELIMITER, $line);
			my $assigned_taxon_id = $items[$LCA_taxon_id_column];
			
			# prints kraken format row for unclassified sequence
			# "C"/"U": a one letter code indicating that the sequence was either classified
			# or unclassified.
			print "C".$DELIMITER;
		
			# The sequence ID, obtained from the FASTA/FASTQ header.
			print $sequence_name.$DELIMITER;
		
			# The taxonomy ID Kraken 2 used to label the sequence; this is 0 if the sequence
			# is unclassified.
			print $assigned_taxon_id.$DELIMITER;
		
			# The length of the sequence in bp. In the case of paired read data, this will be
			# a string containing the lengths of the two sequences in bp, separated by a pipe
			# character, e.g. "98|94".
			print $sequence_name_to_length{$sequence_name}.$DELIMITER;
		
			# A space-delimited list indicating the LCA mapping of each k-mer in the sequence(s)
			print $NO_DATA.$NEWLINE;
		}
	}
}
close LCA_MATCHES;


# prints rows for reads without hits
foreach my $sequence_name(sort keys %sequence_name_appears_in_LCA_table)
{
	if(!$sequence_name_appears_in_LCA_table{$sequence_name})
	{
		# prints kraken format row for unclassified sequence
		# "C"/"U": a one letter code indicating that the sequence was either classified
		# or unclassified.
		print "U".$DELIMITER;
		
		# The sequence ID, obtained from the FASTA/FASTQ header.
		print $sequence_name.$DELIMITER;
		
		# The taxonomy ID Kraken 2 used to label the sequence; this is 0 if the sequence
		# is unclassified.
		print "0".$DELIMITER;
		
		# The length of the sequence in bp. In the case of paired read data, this will be
		# a string containing the lengths of the two sequences in bp, separated by a pipe
		# character, e.g. "98|94".
		print $sequence_name_to_length{$sequence_name}.$DELIMITER;
		
		# A space-delimited list indicating the LCA mapping of each k-mer in the sequence(s)
		print $NO_DATA.$NEWLINE;
	}
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
		if(!$INCLUDE_AMBIGUOUS_BASES_IN_SEQUENCE_LENGTH and is_unambiguous_base($base))
		{
			$sequence_length++;
		}
		elsif($INCLUDE_AMBIGUOUS_BASES_IN_SEQUENCE_LENGTH and is_base($base))
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


# September 29, 2023