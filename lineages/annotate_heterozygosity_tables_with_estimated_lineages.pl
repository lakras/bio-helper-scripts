#!/usr/bin/env perl

# Annotates input heterozygosity tables with lineage consistent with minor and
# consensus-level alleles at lineage-defining positions: positions at which the aligned
# lineage sequences have non-identical unambiguous (A, T, C, or G) bases. Adds columns
# for each pair of lineages. Adds a header line. Output is printed to one file per
# heterozygosity table or as one table.

# Reference sequence must be first sequence in alignment fasta. Positions in
# heterozygosity tables must be relative to same reference as the alignment fasta.

# Input heterozygosity tables are in same format as that used in polyphonia
# (see https://github.com/broadinstitute/polyphonia#--het)
# or output by vcf-files/vcf_file_to_heterozygosity_table.pl
# (https://github.com/lakras/bio-helper-scripts/blob/main/vcf-files/vcf_file_to_heterozygosity_table.pl):
# - name of reference genome (e.g., NC_045512.2)
# - position of locus relative to reference genome, 1-indexed (e.g., 28928)
# - major allele at that position (e.g., C)
# - major allele readcount (e.g., 1026)
# - major allele frequency (e.g., 0.934426)
# - minor allele at that position (e.g., T)
# - minor allele readcount (e.g., 72)
# - minor allele frequency (e.g., 0.065574)

# Output table contains columns of heterozygosity table as well as:
# - lineages consistent with minor allele (of all lineages provided)
# - lineages consistent with consensus-level allele (of all lineages provided)
# - lineage consistent with minor allele (lineage 1 vs. lineage 2)
# - lineage consistent with consensus-level allele (lineage 1 vs. lineage 2)
# - lineage consistent with minor allele (lineage 2 vs. lineage 3)
# - lineage consistent with consensus-level allele (lineage 2 vs. lineage 3)
# - lineage consistent with minor allele (lineage 1 vs. lineage 3)
# - lineage consistent with consensus-level allele (lineage 1 vs. lineage 3)
# etc.

# Usage:
# perl annotate_heterozygosity_tables_with_estimated_lineages.pl
# [lineage genomes aligned to reference] [list of heterozygosity tables]
# [1 to print each heterozygosity table separately, 0 to print all tables to console]

# Prints to console unless specified to print each heterozygosity table separately.
# To print to file, use
# perl annotate_heterozygosity_tables_with_estimated_lineages.pl
# [lineage genomes aligned to reference] [list of heterozygosity tables]
# [1 to print each heterozygosity table separately, 0 to print all tables to console]
# > [output table path]


use strict;
use warnings;


my $lineages_aligned_fasta = $ARGV[0]; # lineages aligned to reference; reference must be first sequence in file; must start with same reference as other alignment file
my $heterozygosity_tables = $ARGV[1]; # file containing a list of heterozygosity table files, one for each sample; positions must be relative to same reference used in both fasta alignment files; filenames must contain sample names used in consensus genome alignment
my $print_each_file_separately = $ARGV[2]; # if 1, prints one annotated heterozygosity table per input heterozygosity table; if 0, prints all annotated tables together to console as one table


my $DELIMITER = "\t";
my $NEWLINE = "\n";
my $NO_DATA = "";


# heterozygosity table columns:
my $HETEROZYGOSITY_TABLE_REFERENCE_COLUMN = 0; # (0-indexed)
my $HETEROZYGOSITY_TABLE_POSITION_COLUMN = 1;
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_COLUMN = 2;
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_READCOUNT_COLUMN = 3;
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_FREQUENCY_COLUMN = 4;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_COLUMN = 5;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_READCOUNT_COLUMN = 6;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_FREQUENCY_COLUMN = 7;


# verifies that input files exist and are non-empty
if(!$lineages_aligned_fasta or !-e $lineages_aligned_fasta or -z $lineages_aligned_fasta)
{
	print STDERR "Error: lineages aligned fasta is not a non-empty file:\n\t"
		.$lineages_aligned_fasta."\nExiting.\n";
	die;
}
if(!$heterozygosity_tables or !-e $heterozygosity_tables or -z $heterozygosity_tables)
{
	print STDERR "Warning: list of heterozygosity table files does not exist or is empty:\n\t"
		.$heterozygosity_tables."\n";
}


# read in aligned lineages fasta file
my %lineage_name_to_genome = (); # key: sequence name -> value: lineage genome, including gaps froms alignment
my %all_lineages = (); # key: name of lineage -> value: 1
my $reference_sequence = ""; # first sequence in alignment
my $reference_sequence_name = ""; # name of first sequence in alignment

open ALIGNED_LINEAGES_GENOMES, "<$lineages_aligned_fasta" || die "Could not open $lineages_aligned_fasta to read; terminating =(\n";
my $sequence = "";
my $sequence_name = "";
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
		if($reference_sequence_name) # if reference sequence has already been read in
		{
			# this sequence name is a lineage name
			$all_lineages{$sequence_name} = 1;
		}
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
# print "lineages:".$NEWLINE;
# foreach my $lineage_name(keys %lineage_name_to_genome)
# {
# 	print $DELIMITER.$lineage_name.$NEWLINE;
# }
# print $NEWLINE;


# process aligned lineages fasta file
# identify "defining positions" at which the lineages are different
my %lineage_pairs = (); # key: [lineage] [lineage] -> value: 1
my %lineage_pair_to_lineage_defining_position_to_base_to_matching_lineage = (); # key: [lineage] [lineage] -> key: lineage-defining position -> key: base -> value: lineage(s) with this base at this position (lineage-defining positions only)
my %position_to_base_to_matching_lineages = (); # key: position -> key: base -> value: all lineage(s) with this base at this position
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
		foreach my $lineage_name(sort keys %lineage_name_to_genome)
		{
			my $lineage_genome = $lineage_name_to_genome{$lineage_name};
			if($base_index < length($lineage_genome)) # no sequence at this index; we've gone out of range
			{
				my $base = substr($lineage_genome, $base_index, 1);
				if(is_unambiguous_base($base))
				{
					$lineage_name_to_base{$lineage_name} = $base;
					if($position_to_base_to_matching_lineages{$position}{$base})
					{
						$position_to_base_to_matching_lineages{$position}{$base} .= ", ";
					}
					$position_to_base_to_matching_lineages{$position}{$base} .= $lineage_name;
				}
			}
		}
		
		# compares base at all pairs of lineages
		# saves base if this is a lineage-defining position
		my @lineage_names = sort keys %lineage_name_to_base;
		foreach my $lineage_names_index_1(0..$#lineage_names)
		{
			my $lineage_name_1 = $lineage_names[$lineage_names_index_1];
			my $lineage_name_1_base = $lineage_name_to_base{$lineage_name_1};
			if($lineage_name_1_base)
			{
				foreach my $lineage_names_index_2($lineage_names_index_1+1 .. $#lineage_names)
				{
					my $lineage_name_2 = $lineage_names[$lineage_names_index_2];
					my $lineage_name_2_base = $lineage_name_to_base{$lineage_name_2};
					if($lineage_name_2_base
						and $lineage_name_1_base ne $lineage_name_2_base)
					{
						my $lineage_pair = $lineage_name_1." ".$lineage_name_2;
						$lineage_pairs{$lineage_pair} = 1;
						$lineage_pair_to_lineage_defining_position_to_base_to_matching_lineage{$lineage_pair}{$position}{$lineage_name_1_base} = $lineage_name_1;
						$lineage_pair_to_lineage_defining_position_to_base_to_matching_lineage{$lineage_pair}{$position}{$lineage_name_2_base} = $lineage_name_2;
					}
				}
			}
		}
	}
}


# generates header line
my $header_line = "";
if(!$print_each_file_separately)
{
	$header_line .= "heterozygosity_table".$DELIMITER;
}
$header_line .= "reference".$DELIMITER."position";

$header_line .= $DELIMITER."consensus_allele".$DELIMITER."consensus_allele_readcount".$DELIMITER."consensus_allele_frequency";
$header_line .= $DELIMITER."lineages_consistent_with_consensus_allele";
foreach my $lineage_pair(sort keys %lineage_pairs)
{
	$header_line .= $DELIMITER."consensus_allele_lineage_defining_".$lineage_pair;
}

$header_line .= $DELIMITER."minor_allele".$DELIMITER."minor_allele_readcount".$DELIMITER."minor_allele_frequency";
$header_line .= $DELIMITER."lineages_consistent_with_minor_allele";
foreach my $lineage_pair(sort keys %lineage_pairs)
{
	$header_line .= $DELIMITER."minor_allele_lineage_defining_".$lineage_pair;
}

# prints header line to console
if(!$print_each_file_separately)
{
	print $header_line.$NEWLINE;
}


# read in heterozygosity tables and annotate values at lineage-defining positions
open HETEROZYGOSITY_TABLES_LIST, "<$heterozygosity_tables" || die "Could not open $heterozygosity_tables to read; terminating =(\n";
while(<HETEROZYGOSITY_TABLES_LIST>) # for each line in the file
{
	chomp;
	my $heterozygosity_table = $_;
	if($heterozygosity_table and $heterozygosity_table =~ /\S/) # non-empty string
	{
		if(!-e $heterozygosity_table) # file does not exist
		{
			print STDERR "Error: heterozygosity table does not exist:\n\t"
				.$heterozygosity_table."\nExiting.\n";
			die;
		}
		elsif(-z $heterozygosity_table) # file is empty
		{
			print STDERR "Warning: skipping empty heterozygosity table:\n\t"
				.$heterozygosity_table."\n";
		}
		else # file exists and is non-empty
		{
			# read in heterozygosity table
			my $output_lines = "";
			open HETEROZYGOSITY_TABLE, "<$heterozygosity_table" || die "Could not open $heterozygosity_table to read; terminating =(\n";
			while(<HETEROZYGOSITY_TABLE>) # for each line in the file
			{
				chomp;
				my $line = $_;
				if($line =~ /\S/) # non-empty line
				{
					# parses this line
					my @items = split($DELIMITER, $line);
					my $reference = $items[$HETEROZYGOSITY_TABLE_REFERENCE_COLUMN];
					my $position = $items[$HETEROZYGOSITY_TABLE_POSITION_COLUMN];
					my $minor_allele = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_COLUMN];
					my $minor_allele_readcount = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_READCOUNT_COLUMN];
					my $minor_allele_frequency = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_FREQUENCY_COLUMN];
					my $consensus_allele = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_COLUMN];
					my $consensus_allele_readcount = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_READCOUNT_COLUMN];
					my $consensus_allele_frequency = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_FREQUENCY_COLUMN];
					
					# retrieves lineages matching alleles at this position
					my $lineages_matching_consensus_allele = "";
					if($position_to_base_to_matching_lineages{$position}{$consensus_allele})
					{
						$lineages_matching_consensus_allele = $position_to_base_to_matching_lineages{$position}{$consensus_allele};
					}
					
					my $lineages_matching_minor_allele = "";
					if($position_to_base_to_matching_lineages{$position}{$minor_allele})
					{
						$lineages_matching_minor_allele = $position_to_base_to_matching_lineages{$position}{$minor_allele};
					}
					
					# prints info on position
					if(!$print_each_file_separately)
					{
						$output_lines .= $heterozygosity_table.$DELIMITER;
					}
					$output_lines .= $reference.$DELIMITER.$position;
					
					# prints info on consensus-level allele
					$output_lines .= $DELIMITER.$consensus_allele.$DELIMITER.$consensus_allele_readcount.$DELIMITER.$consensus_allele_frequency;
					$output_lines .= $DELIMITER.$lineages_matching_consensus_allele;
					foreach my $lineage_pair(sort keys %lineage_pairs)
					{
						my $lineage_matched = $lineage_pair_to_lineage_defining_position_to_base_to_matching_lineage{$lineage_pair}{$position}{$consensus_allele};
						if($lineage_matched)
						{
							$output_lines .= $DELIMITER.$lineage_matched;
						}
						else
						{
							$output_lines .= $DELIMITER.$NO_DATA;
						}
					}
					
					# prints info on minor allele
					$output_lines .= $DELIMITER.$minor_allele.$DELIMITER.$minor_allele_readcount.$DELIMITER.$minor_allele_frequency;
					$output_lines .= $DELIMITER.$lineages_matching_minor_allele;
					foreach my $lineage_pair(sort keys %lineage_pairs)
					{
						my $lineage_matched = $lineage_pair_to_lineage_defining_position_to_base_to_matching_lineage{$lineage_pair}{$position}{$minor_allele};
						if($lineage_matched)
						{
							$output_lines .= $DELIMITER.$lineage_matched;
						}
						else
						{
							$output_lines .= $DELIMITER.$NO_DATA;
						}
					}
					
					$output_lines .= $NEWLINE;
				}
			}
			close HETEROZYGOSITY_TABLE;
			
			if($print_each_file_separately)
			{
				# print annotated heterozygosity table with column titles to file
				my $heterozygosity_table_annotated = $heterozygosity_table."_annotated.txt";
				open HETEROZYGOSITY_TABLE_ANNOTATED, ">$heterozygosity_table_annotated"
					|| die "Could not open $heterozygosity_table_annotated to read; terminating =(\n";
				print HETEROZYGOSITY_TABLE_ANNOTATED $header_line.$NEWLINE;
				print HETEROZYGOSITY_TABLE_ANNOTATED $output_lines;
				close HETEROZYGOSITY_TABLE_ANNOTATED;

			}
			else
			{
				# print annotated heterozygosity table to console
				print $output_lines;
			}
		}
	}
}
close HETEROZYGOSITY_TABLES_LIST;


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
# November 10, 2021
# March 2, 2022
