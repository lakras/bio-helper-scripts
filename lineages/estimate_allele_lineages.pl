#!/usr/bin/env perl

# Generates table listing lineage(s) consistent with each sample's consensus and minor
# alleles.

# Output table includes only lineage-defining positions: positions at which the aligned
# lineage sequences have non-identical unambiguous (A, T, C, or G) bases.

# Reference sequence must be first sequence in both alignment fastas. Both alignment
# fastas must use the same reference. Output positions are 1-indexed relative to reference
# sequence. If heterozygosity tables or read depth tables are provided, positions must be
# relative to same reference as the two alignment fastas.

# Optional input heterozygosity table is in same format as that used in polyphonia
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

# Optional input read depth table is in format produced by samtools depth:
# - name of reference genome (e.g., NC_045512.2)
# - position of locus relative to reference genome, 1-indexed (e.g., 28928)
# - read depth at that position (e.g., 1098)

# Output table contains columns:
# - sample
# - lineage_defining_position_([reference])
# - consensus_allele
# - consensus_allele_lineage

# and, if read depth tables are included:
# - read_depth

# and, if heteroyzgosity tables are included:
# - consensus_allele_readcount
# - consensus_allele_frequency
# - minor_allele
# - minor_allele_lineage
# - minor_allele_readcount
# - minor_allele_frequency

# Usage:
# perl estimate_allele_lineages.pl [lineage genomes aligned to reference]
# [consensus genomes aligned to reference] [optional list of heterozygosity tables]
# [optional list of read depth files]

# Prints to console. To print to file, use
# perl estimate_allele_lineages.pl [lineage genomes aligned to reference]
# [consensus genomes aligned to reference] [optional list of heterozygosity tables]
# [optional list of read depth files] > [output table path]


use strict;
use warnings;


my $lineages_aligned_fasta = $ARGV[0]; # lineages aligned to reference; reference must be first sequence in file; must start with same reference as other alignment file
my $sample_consensuses_aligned_fasta = $ARGV[1]; # sample consensus sequences aligned to reference; reference must be first sequence in file; must start with same reference as other alignment file
my $heterozygosity_tables = $ARGV[2]; # optional file containing a list of heterozygosity table files, one for each sample; positions must be relative to same reference used in both fasta alignment files; filenames must contain sample names used in consensus genome alignment
my $read_depth_files = $ARGV[3]; # optional file containing a list of read depth files, one for each sample; positions must be relative to same reference used in both fasta alignment files; filenames must contain sample names used in consensus genome alignment


my $DELIMITER = "\t";
my $NEWLINE = "\n";
my $NO_DATA = "";


# heterozygosity table columns:
my $HETEROZYGOSITY_TABLE_POSITION_COLUMN = 1; # (0-indexed)
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_COLUMN = 2;
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_READCOUNT_COLUMN = 3;
my $HETEROZYGOSITY_TABLE_MAJOR_ALLELE_FREQUENCY_COLUMN = 4;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_COLUMN = 5;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_READCOUNT_COLUMN = 6;
my $HETEROZYGOSITY_TABLE_MINOR_ALLELE_FREQUENCY_COLUMN = 7;

# columns in read-depth tables produced by samtools:
my $READ_DEPTH_REFERENCE_COLUMN = 0; # reference must be same across all input files
my $READ_DEPTH_POSITION_COLUMN = 1; # 1-indexed
my $READ_DEPTH_COLUMN = 2;


# if 0, prints all lineage-defining positions even if there is no consensus allele
my $ONLY_PRINT_POSITIONS_WITH_CONSENSUS_ALLELE = 1;

# if 1, uses read depth as estimate of consensus-level readcount at positions with no heterozygosity
# if 0, leaves readcount blank for positions without heterozygosity
my $ESTIMATE_NO_VARIATION_CONSENSUS_READCOUNT_AS_READ_DEPTH = 1;


# verifies that input files exist and are non-empty
if(!$lineages_aligned_fasta or !-e $lineages_aligned_fasta or -z $lineages_aligned_fasta)
{
	print STDERR "Error: lineages aligned fasta is not a non-empty file:\n\t"
		.$lineages_aligned_fasta."\nExiting.\n";
	die;
}
if(!$sample_consensuses_aligned_fasta or !-e $sample_consensuses_aligned_fasta or -z $sample_consensuses_aligned_fasta)
{
	print STDERR "Error: consensus genomes aligned fasta is not a non-empty file:\n\t"
		.$sample_consensuses_aligned_fasta."\nExiting.\n";
	die;
}
if($heterozygosity_tables and (!-e $heterozygosity_tables or -z $heterozygosity_tables))
{
	print STDERR "Warning: list of heterozygosity table files does not exist or is empty:\n\t"
		.$heterozygosity_tables."\n";
}
if($read_depth_files and (!-e $read_depth_files or -z $read_depth_files))
{
	print STDERR "Warning: list of read depth table files does not exist or is empty:\n\t"
		.$read_depth_files."\n";
}


# read in aligned lineages fasta file
my %lineage_name_to_genome = (); # key: sequence name -> value: lineage genome, including gaps froms alignment
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
# print "lineage-defining positions (1-indexed relative to reference ".$reference_sequence_name."):\n";
# foreach my $position(sort {$a <=> $b} keys %is_lineage_defining_position)
# {
# 	print add_comma_separators($position).$NEWLINE;
# 	foreach my $lineage_base(keys %{$position_to_base_to_matching_lineage{$position}})
# 	{
# 		my $matching_lineages = $position_to_base_to_matching_lineage{$position}{$lineage_base};
# 		
# 		print $DELIMITER.$lineage_base.": ".$matching_lineages.$NEWLINE;
# 	}
# }
# print $NEWLINE;


# read in aligned consensus genomes fasta file
my %sequence_name_to_consensus = (); # key: sequence name -> value: consensus sequence, including gaps froms alignment
$reference_sequence = ""; # first sequence in alignment
$sequence = "";
$sequence_name = "";
my %all_samples = (); # key: sample name -> value: 1
open ALIGNED_CONSENSUS_GENOMES, "<$sample_consensuses_aligned_fasta" || die "Could not open $sample_consensuses_aligned_fasta to read; terminating =(\n";
while(<ALIGNED_CONSENSUS_GENOMES>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# save previous sequence
		$sequence = uc($sequence);
		if($sequence and $sequence_name)
		{
			$sequence_name_to_consensus{$sequence_name} = $sequence;
			if($reference_sequence) # if reference was previously read in
			{
				$all_samples{$sequence_name} = 1;
			}
		}
		if(!$reference_sequence) # reference sequence is first sequence in alignment
		{
			$reference_sequence = $sequence;
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
# save final sequence
if($sequence and $sequence_name)
{
	$sequence_name_to_consensus{$sequence_name} = uc($sequence);
	if($reference_sequence) # if reference was previously read in
	{
		$all_samples{$sequence_name} = 1;
	}
}
if(!$reference_sequence) # reference sequence is first sequence in alignment
{
	$reference_sequence = $sequence;
}
close ALIGNED_CONSENSUS_GENOMES;


# hashes with information to print later
my %sample_to_position_to_consensus_allele = (); # key: sample name -> key: position (1-indexed, relative to reference) -> value: consensus allele at this position
my %sample_to_position_to_consensus_allele_readcount = ();
my %sample_to_position_to_consensus_allele_frequency = ();
my %sample_to_position_to_minor_allele = ();
my %sample_to_position_to_minor_allele_readcount = ();
my %sample_to_position_to_minor_allele_frequency = ();
my %sample_to_position_to_read_depth = ();


# read in heterozygosity tables and save values at lineage-defining positions
if($heterozygosity_tables)
{
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
				# retrieve sample name from file name
				my $sample_name = "";
				foreach my $potential_sample_name(sort {length $a <=> length $b} keys %all_samples)
				{
					if($heterozygosity_table =~ /$potential_sample_name/)
					{
						$sample_name = $potential_sample_name;
					}
				}
				
				if($sample_name)
				{
					# read in heterozygosity table
					open HETEROZYGOSITY_TABLE, "<$heterozygosity_table" || die "Could not open $heterozygosity_table to read; terminating =(\n";
					while(<HETEROZYGOSITY_TABLE>) # for each line in the file
					{
						chomp;
						my $line = $_;
						if($line =~ /\S/) # non-empty line
						{
							# parses this line
							my @items = split($DELIMITER, $line);
							my $position = $items[$HETEROZYGOSITY_TABLE_POSITION_COLUMN];
							my $minor_allele = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_COLUMN];
							my $minor_allele_readcount = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_READCOUNT_COLUMN];
							my $minor_allele_frequency = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_FREQUENCY_COLUMN];
							my $consensus_allele = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_COLUMN];
							my $consensus_allele_readcount = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_READCOUNT_COLUMN];
							my $consensus_allele_frequency = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_FREQUENCY_COLUMN];

							if($is_lineage_defining_position{$position}
								and $minor_allele_frequency > 0 and $minor_allele_readcount > 0)
							{
								# saves information on consensus-level allele
								$sample_to_position_to_consensus_allele{$sample_name}{$position} = $consensus_allele;
								$sample_to_position_to_consensus_allele_readcount{$sample_name}{$position} = $consensus_allele_readcount;
								$sample_to_position_to_consensus_allele_frequency{$sample_name}{$position} = $consensus_allele_frequency;
						
								# saves information on minor allele
								$sample_to_position_to_minor_allele{$sample_name}{$position} = $minor_allele;
								$sample_to_position_to_minor_allele_readcount{$sample_name}{$position} = $minor_allele_readcount;
								$sample_to_position_to_minor_allele_frequency{$sample_name}{$position} = $minor_allele_frequency;
							}
						}
					}
					close HETEROZYGOSITY_TABLE;
				}
				else # sample name could not be retrieved
				{
					print STDERR "Warning: could not retrieve from filepath of heterozygosity "
						."table a sample name that matches a sequence name from consensus "
						."genome alignment. Excluding heterozygosity table:\n\t"
						.$heterozygosity_table."\n";
				}
			}
		}
	}
	close HETEROZYGOSITY_TABLES_LIST;
}


# read in read depth tables and save values at lineage-defining positions
if($read_depth_files)
{
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
					# read in heterozygosity table
					open READ_DEPTH_TABLE, "<$read_depth_table" || die "Could not open $read_depth_table to read; terminating =(\n";
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

							if($is_lineage_defining_position{$position})
							{
								# saves read depth
								$sample_to_position_to_read_depth{$sample_name}{$position} = $read_depth;
							}
						}
					}
					close READ_DEPTH_TABLE;
				}
				else # sample name could not be retrieved
				{
					print STDERR "Warning: could not retrieve from filepath of read depth "
						."table a sample name that matches a sequence name from consensus "
						."genome alignment. Excluding heterozygosity table:\n\t"
						.$read_depth_table."\n";
				}
			}
		}
	}
	close READ_DEPTH_TABLES_LIST;
}


# processes aligned consensus genomes
# save values at lineage-defining positions
$position = 0; # 1-indexed relative to referece
for(my $base_index = 0; $base_index < length($reference_sequence); $base_index++)
{
	my $reference_base = substr($reference_sequence, $base_index, 1);
	if(is_base($reference_base))
	{
		# increments position only if valid base in reference sequence
		$position++;
		
		if($is_lineage_defining_position{$position})
		{
			# retrieves and saves base at this position for each consensus genome
			for my $sample_name(keys %sequence_name_to_consensus)
			{
				my $base = substr($sequence_name_to_consensus{$sample_name}, $base_index, 1);
				if(is_unambiguous_base($base))
				{
					# saves allele if we haven't already read it in in heterozygosity table
					if(!$sample_to_position_to_consensus_allele{$sample_name}{$position})
					{
						$sample_to_position_to_consensus_allele{$sample_name}{$position} = $base;
						$sample_to_position_to_consensus_allele_frequency{$sample_name}{$position} = 1;
					}
				}
			}
		}
	}
}


# print output table header line
print "sample".$DELIMITER;
print "lineage_defining_position_(".$reference_sequence_name.")".$DELIMITER;
if($read_depth_files)
{
	print "read_depth".$DELIMITER;
}
print "consensus_allele".$DELIMITER;
print "consensus_allele_lineage";

if($heterozygosity_tables)
{
	print $DELIMITER;
	print "consensus_allele_readcount".$DELIMITER;
	print "consensus_allele_frequency".$DELIMITER;

	print "minor_allele".$DELIMITER;
	print "minor_allele_lineage".$DELIMITER;
	print "minor_allele_readcount".$DELIMITER;
	print "minor_allele_frequency";
}
print $NEWLINE;


# print output table
foreach my $sample(sort keys %all_samples)
{
	foreach my $position(sort {$a <=> $b} keys %is_lineage_defining_position)
	{
		# retrieves read depth for this position
		my $read_depth = $NO_DATA;
		if($sample_to_position_to_read_depth{$sample}{$position})
		{
			$read_depth = $sample_to_position_to_read_depth{$sample}{$position};
		}
	
		# retrieves consensus-level allele information for this line
		my $consensus_allele = $NO_DATA;
		my $consensus_allele_readcount = $NO_DATA;
		my $consensus_allele_frequency = $NO_DATA;
		my $consensus_allele_lineage = $NO_DATA;
		if($sample_to_position_to_consensus_allele{$sample}{$position})
		{
			$consensus_allele = $sample_to_position_to_consensus_allele{$sample}{$position};
			if($sample_to_position_to_consensus_allele_readcount{$sample}{$position})
			{
				$consensus_allele_readcount = $sample_to_position_to_consensus_allele_readcount{$sample}{$position};
			}
 			$consensus_allele_frequency = $sample_to_position_to_consensus_allele_frequency{$sample}{$position};
 			if($position_to_base_to_matching_lineage{$position}{$consensus_allele})
 			{
 				$consensus_allele_lineage = $position_to_base_to_matching_lineage{$position}{$consensus_allele};
 			}
		}
		
		# substitutes in read depth for consensus allele readcount
		if($ESTIMATE_NO_VARIATION_CONSENSUS_READCOUNT_AS_READ_DEPTH
			and $read_depth_files
			and $consensus_allele_readcount eq $NO_DATA)
		{
			$consensus_allele_readcount = $read_depth;
		}
		
		# retrieves minor allele information for this line
		my $minor_allele = $NO_DATA;
		my $minor_allele_readcount = $NO_DATA;
		my $minor_allele_frequency = $NO_DATA;
		my $minor_allele_lineage = $NO_DATA;
		if($sample_to_position_to_minor_allele{$sample}{$position})
		{
			$minor_allele = $sample_to_position_to_minor_allele{$sample}{$position};
 			$minor_allele_readcount = $sample_to_position_to_minor_allele_readcount{$sample}{$position};
 			$minor_allele_frequency = $sample_to_position_to_minor_allele_frequency{$sample}{$position};
 			if($position_to_base_to_matching_lineage{$position}{$minor_allele})
 			{
 				$minor_allele_lineage = $position_to_base_to_matching_lineage{$position}{$minor_allele};
 			}
		}
		
		# prints line
		if($consensus_allele ne $NO_DATA or !$ONLY_PRINT_POSITIONS_WITH_CONSENSUS_ALLELE)
		{
			print $sample.$DELIMITER;
			print $position.$DELIMITER;
			
			if($read_depth_files)
			{
				print $read_depth.$DELIMITER;
			}

			print $consensus_allele.$DELIMITER;
			print $consensus_allele_lineage;
			
			if($heterozygosity_tables)
			{
				print $DELIMITER;
				print $consensus_allele_readcount.$DELIMITER;
				print $consensus_allele_frequency.$DELIMITER;

				print $minor_allele.$DELIMITER;
				print $minor_allele_lineage.$DELIMITER;
				print $minor_allele_readcount.$DELIMITER;
				print $minor_allele_frequency;
			}
			print $NEWLINE;
		}
	}
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
