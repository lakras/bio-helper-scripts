#!/usr/bin/env perl

# Detects potential transmission events from iSNVs, assuming an average transmission
# bottleneck of one virus per transmission.

# If collection dates are provided, only compares sequences within hardcoded maximum
# collection date distance.

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

# Usage:
# perl detect_potential_transmission_events_from_iSNVs.pl
# [consensus sequences alignment fasta file path] [list of heterozygosity tables]
# [optional file containing list of read depth tables]
# [optional tab-separated table mapping sample names to collection dates (YYYY-MM-DD)]
# [0 to print one line per sample pair, 1 to print one line per iSNV]

# Prints to console. To print to file, use
# perl detect_potential_transmission_events_from_iSNVs.pl
# [consensus sequences alignment fasta file path] [list of heterozygosity tables]
# [optional file containing list of read depth tables]
# [optional tab-separated table mapping sample names to collection dates (YYYY-MM-DD)]
# [0 to print one line per sample pair, 1 to print one line per iSNV]
# > [output fasta file path]


use strict;
use warnings;


my $consensus_sequences_aligned = $ARGV[0]; # fasta alignment of consensus sequences; reference sequence must appear first
my $heterozygosity_tables = $ARGV[1]; # file containing a list of heterozygosity table files, one for each sample; positions must be relative to same reference used in fasta alignment file; filenames must contain sample names used in consensus genome alignment
my $read_depth_files = $ARGV[2]; # optional file containing a list of read depth files, one for each sample; positions must be relative to same reference used in both fasta alignment files; filenames must contain sample names used in consensus genome alignment
my $collection_date_table = $ARGV[3]; # optional table with two columns: sample names (must match names of consensus sequences) and collection dates, tab-separated
my $print_one_line_per_iSNV = $ARGV[4]; # if 0, prints one line per sample pair; if 1, prints line for each iSNV matched in each sample pair


# thresholds for comparing two samples
my $MAXIMUM_COLLECTION_DATE_DISTANCE = 6;
my $REQUIRE_INDEX_COLLECTION_DATE_BEFORE_RECIPIENT = 1;

# thresholds for calling a transmission event
my $FIXED_FREQUENCY = 0.9999; # minimum frequency at which we consider an allele to be fixed in a patient
my $MAXIMUM_INITIAL_ISNV_FREQUENCY = 0.90; # 90%; maximum frequency allele can be in index case
my $MAXIMUM_OTHER_CONSENSUS_DIFFERENCES = 0; # 1; # maximum number differences between consensus genomes other than transmitted iSNVs (comparing unambiguous bases, substitutions only)

# thresholds for marking position as heterozygous
my $MINIMUM_MINOR_ALLELE_READCOUNT = 10;
my $MINIMUM_MINOR_ALLELE_FREQUENCY = 0.03; # 3%
my $MINIMUM_READ_DEPTH = 100;

# intermediate file heterozygosity table columns:
my $HETEROZYGOSITY_TABLE_REFERENCE_COLUMN = 0;
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

# columns in collection dates table
my $COLLECTION_DATE_SAMPLE_NAME_COLUMN = 0;
my $COLLECTION_DATE_COLUMN = 1;

my $DELIMITER = "\t";
my $NEWLINE = "\n";
my $NO_DATA = "NA";


# verifies that fasta alignment file exists and is non-empty
if(!$consensus_sequences_aligned)
{
	print STDERR "Error: no input fasta alignment file provided. Exiting.\n";
	die;
}
if(!-e $consensus_sequences_aligned)
{
	print STDERR "Error: input fasta alignment file does not exist:\n\t".$consensus_sequences_aligned."\nExiting.\n";
	die;
}
if(-z $consensus_sequences_aligned)
{
	print STDERR "Error: input fasta alignment file is empty:\n\t".$consensus_sequences_aligned."\nExiting.\n";
	die;
}

# verifies that heterozygosity tables file exists and is non-empty
if(!$heterozygosity_tables)
{
	print STDERR "Error: no heterozygosity tables file provided. Exiting.\n";
	die;
}
if(!-e $heterozygosity_tables)
{
	print STDERR "Error: heterozygosity tables file does not exist:\n\t".$heterozygosity_tables."\nExiting.\n";
	die;
}
if(-z $heterozygosity_tables)
{
	print STDERR "Error: heterozygosity tables file is empty:\n\t".$heterozygosity_tables."\nExiting.\n";
	die;
}


# reads in collection dates
my %sample_name_to_collection_date = (); # key: sequence name -> value: collection date
if($collection_date_table)
{
	open COLLECTION_DATE_TABLE, "<$collection_date_table"
		|| die "Could not open $collection_date_table to read; terminating =(\n";
	while(<COLLECTION_DATE_TABLE>) # for each line in the file
	{
		chomp;
		my $line = $_;
		if($line =~ /\S/) # non-empty line
		{
			# parses this line
			my @items = split($DELIMITER, $line);
			my $sample_name = $items[$COLLECTION_DATE_SAMPLE_NAME_COLUMN];
			my $collection_date = $items[$COLLECTION_DATE_COLUMN];

			# saves collection date
			$sample_name_to_collection_date{$sample_name} = $collection_date;
		}
	}
	close COLLECTION_DATE_TABLE;
}


# reads in sequence names
my $reference_sequence_name = ""; # name of first sequence in alignment
my %sample_names = (); # key: name of sample -> value: 1
open ALIGNED_CONSENSUS_SEQUENCES, "<$consensus_sequences_aligned" || die "Could not open $consensus_sequences_aligned to read; terminating =(\n";
while(<ALIGNED_CONSENSUS_SEQUENCES>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# prepare for next sequence
		my $sequence_name = $1;
		if(!$reference_sequence_name)
		{
			$reference_sequence_name = $sequence_name;
		}
		elsif(!$collection_date_table or $sample_name_to_collection_date{$sequence_name})
		{
			# only include sequence if it has a collection date, unless we did not read in collection dates
			$sample_names{$sequence_name} = 1;
		}
	}
}
close ALIGNED_CONSENSUS_SEQUENCES;


# reads in read depth tables if provided
my %sample_to_position_to_read_depth = (); # key: sample name -> key: position (1-indexed, relative to reference) -> value: read depth at this position
my %read_depth_read_in_for_sample = (); # key: sample name -> value: 1 if read depth table read in
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
				# trims file path to file name
				my $sample_name = retrieve_file_name($read_depth_table);

				# retrieves largest possible sample name that collides with a sample name
				# from consensus sequences alignment
				# (file name sample1.ext1.ext2 has possible sample names sample1.ext1.ext2, sample1.ext1, sample1)
				my $sample_name_found = 0;
				while($sample_name and !$sample_name_found)
				{
					if($sample_names{$sample_name})
					{
						# potential sample name collides with a sample name from consensus genome
						# this is our sample name
						$sample_name_found = 1;
					}
					else
					{
						$sample_name = trim_off_file_extension($sample_name);
					}
				}
			
				if(!$sample_name_found)
				{
					print STDERR "Warning: skipping read depth table that could not be "
						."mapped by name to a consensus sequence:\n\t"
						.$read_depth_table.".\n";
				}
				else
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
			}
		}
	}
	close READ_DEPTH_TABLES_LIST;
}


# reads in aligned consensus sequences
my %sample_name_to_consensus_sequence_string_length = (); # key: sequence name -> value: length of consensus sequence string
my $reference_sequence_string_length = 0;
my %sample_to_position_to_consensus_allele = (); # key: sample name -> key: position (1-indexed relative to reference) -> value: base in consensus sequence
my @reference_bases;
open ALIGNED_CONSENSUS_SEQUENCES, "<$consensus_sequences_aligned" || die "Could not open $consensus_sequences_aligned to read; terminating =(\n";
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
				$reference_sequence_name = $sequence_name;
				@reference_bases = split(//, $sequence);
			}
			elsif($sample_names{$sequence_name}) # included sequence
			{
				process_sequence();
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
if($sequence and $sequence_name and $sample_names{$sequence_name})
{
	process_sequence();
}
close ALIGNED_CONSENSUS_SEQUENCES;


# reads in base at each position in each consensus sequence
# only includes positions passing read depth filter
# my %sample_to_position_to_consensus_allele = (); # key: sample name -> key: position (1-indexed relative to reference) -> value: base in consensus sequence
# my @reference_bases = split(//, $reference_sequence);
# foreach my $sample_name(keys %sample_name_to_consensus_sequence)
# {
# 	my $consensus_genome = $sample_name_to_consensus_sequence{$sample_name};
# 	my @consensus_genome_bases = split(//, $consensus_genome);
# 	
# 	my $position = 0; # 1-indexed relative to reference
# 	for(my $base_index = 0; $base_index < length($reference_sequence); $base_index++)
# 	{
# 		my $reference_base = $reference_bases[$base_index];
# 		if(is_base($reference_base))
# 		{
# 			# increments position only if valid base in reference sequence
# 			$position++;
# 	
# 			# retrieves and saves sample's base at this position
# 			my $base = $consensus_genome_bases[$base_index];
# 			if(is_unambiguous_base($base)
# 				and (!$read_depth_read_in_for_sample{$sample_name}
# 					or $sample_to_position_to_read_depth{$sample_name}{$position} >= $MINIMUM_READ_DEPTH))
# 			{
# 				$sample_to_position_to_consensus_allele{$sample_name}{$position} = $base;
# 			}
# 		}
# 	}
# }


# reads in heterozygosity tables
my %sample_has_iSNVs = (); # key: sample name -> value: 1 if sample has at least one position with heterozygosity
my %sample_to_position_to_base_to_frequency = (); # key: sample name -> key: position (1-indexed relative to reference) -> key: base -> value: frequency of allele
my %sample_to_position_to_base_to_readcount = (); # key: sample name -> key: position (1-indexed relative to reference) -> key: base -> value: allele readcount
# my %sample_to_position_to_consensus_allele_frequency = (); # key: sample name -> key: position (1-indexed relative to reference) -> value: frequency of consensus base
# my %sample_to_position_to_consensus_allele_readcount = (); # key: sample name -> key: position (1-indexed relative to reference) -> value: readcount of consensus base
# my %sample_to_position_to_minor_allele = (); # key: sample name -> key: position (1-indexed relative to reference) -> value: minor allele
# my %sample_to_position_to_minor_allele_frequency = (); # key: sample name -> key: position (1-indexed relative to reference) -> value: frequency of minor allele
# my %sample_to_position_to_minor_allele_readcount = (); # key: sample name -> key: position (1-indexed relative to reference) -> value: readcount of minor allele

open HETEROZYGOSITY_TABLES_LIST, "<$heterozygosity_tables" || die "Could not open $heterozygosity_tables to read; terminating =(\n";
while(<HETEROZYGOSITY_TABLES_LIST>) # for each line in the file
{
	chomp;
	my $heterozygosity_table = $_;
	if($heterozygosity_table and $heterozygosity_table =~ /\S/) # non-empty string
	{
		if(!-e $heterozygosity_table) # file does not exist
		{
			print STDERR "Warning: heterozygosity table does not exist:\n\t"
				.$heterozygosity_table.".\n";
		}
		elsif(-z $heterozygosity_table) # file is empty
		{
			print STDERR "Warning: skipping empty heterozygosity table:\n\t"
				.$heterozygosity_table."\n";
		}
		else # file exists and is non-empty
		{
			# trims file path to file name
			my $sample_name = retrieve_file_name($heterozygosity_table);

			# retrieves largest possible sample name that collides with a sample name
			# from consensus sequences alignment
			# (file name sample1.ext1.ext2 has possible sample names sample1.ext1.ext2, sample1.ext1, sample1)
			my $sample_name_found = 0;
			while($sample_name and !$sample_name_found)
			{
				if($sample_names{$sample_name})
				{
					# potential sample name collides with a sample name from consensus genome
					# this is our sample name
					$sample_name_found = 1;
				}
				else
				{
					$sample_name = trim_off_file_extension($sample_name);
				}
			}
			
			if(!$sample_name_found)
			{
				print STDERR "Warning: skipping heterozygosity table that could not be "
					."mapped by name to a consensus sequence:\n\t"
					.$heterozygosity_table.".\n";
			}
			else
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
						my $reference = $items[$HETEROZYGOSITY_TABLE_REFERENCE_COLUMN];
						my $position = $items[$HETEROZYGOSITY_TABLE_POSITION_COLUMN];
						my $minor_allele = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_COLUMN];
						my $minor_allele_readcount = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_READCOUNT_COLUMN];
						my $minor_allele_frequency = $items[$HETEROZYGOSITY_TABLE_MINOR_ALLELE_FREQUENCY_COLUMN];
						my $consensus_allele = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_COLUMN];
						my $consensus_allele_readcount = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_READCOUNT_COLUMN];
						my $consensus_allele_frequency = $items[$HETEROZYGOSITY_TABLE_MAJOR_ALLELE_FREQUENCY_COLUMN];
						
						# checks this heterozygous position passes thresholds for inclusion
						if($minor_allele_readcount >= $MINIMUM_MINOR_ALLELE_READCOUNT # minor allele readcount
							and $minor_allele_frequency >= $MINIMUM_MINOR_ALLELE_FREQUENCY # minor allele frequency (MAF)
							and $minor_allele_readcount + $consensus_allele_readcount >= $MINIMUM_READ_DEPTH) # read depth
						{
							# verifies that consensus allele matches that in alignment
							if(defined $sample_to_position_to_consensus_allele{$sample_name}{$position})
							{
								if($sample_to_position_to_consensus_allele{$sample_name}{$position}
									ne $consensus_allele and is_unambiguous_base($consensus_allele))
								{
									print STDERR "Warning: consensus allele in alignment ("
										.$sample_to_position_to_consensus_allele{$sample_name}{$position}
										.") and in heterozygosity table (".$consensus_allele
										.") disagree for position ".$position." in sample "
										.$sample_name.".\n";
# 										.". Using allele from heterozygosity table.\n";
# 									$sample_to_position_to_consensus_allele{$sample_name}{$position} = $consensus_allele;
								}
							}
							elsif(is_unambiguous_base($consensus_allele))
							{
								$sample_to_position_to_consensus_allele{$sample_name}{$position} = $consensus_allele;
							}

# 							$sample_to_position_to_consensus_allele_frequency{$sample_name}{$position} = $consensus_allele_frequency;
# 							$sample_to_position_to_consensus_allele_readcount{$sample_name}{$position} = $consensus_allele_readcount;
# 							$sample_to_position_to_minor_allele{$sample_name}{$position} = $minor_allele;
# 							$sample_to_position_to_minor_allele_frequency{$sample_name}{$position} = $minor_allele_frequency;
# 							$sample_to_position_to_minor_allele_readcount{$sample_name}{$position} = $minor_allele_readcount;

							$sample_has_iSNVs{$sample_name} = 1;
							$sample_to_position_to_base_to_frequency{$sample_name}{$position}{$consensus_allele} = $consensus_allele_frequency;
							$sample_to_position_to_base_to_frequency{$sample_name}{$position}{$minor_allele} = $minor_allele_frequency;
							$sample_to_position_to_base_to_readcount{$sample_name}{$position}{$consensus_allele} = $consensus_allele_readcount;
							$sample_to_position_to_base_to_readcount{$sample_name}{$position}{$minor_allele} = $minor_allele_readcount;
						}
					}
				}
				close HETEROZYGOSITY_TABLE;
			}
		}
	}
}
close HETEROZYGOSITY_TABLES_LIST;


# prints header line
if($print_one_line_per_iSNV)
{
	print "from_sample".$DELIMITER;
	if($collection_date_table)
	{
		print "from_sample_collection_date".$DELIMITER;
	}
	print "to_sample".$DELIMITER;
	if($collection_date_table)
	{
		print "to_sample_collection_date".$DELIMITER;
	}
	print "position".$DELIMITER;
	print "base".$DELIMITER;
	print "frequency_in_index_case".$DELIMITER;
	print "readcount_in_index_case".$DELIMITER;
# 	print "sample_2_frequency".$DELIMITER;
# 	print "sample_2_readcount".$DELIMITER;
	print "other_consensus_level_differences".$NEWLINE;
}
else
{
	print "index_case".$DELIMITER;
	if($collection_date_table)
	{
		print "index_case_collection_date".$DELIMITER;
	}
	print "proposed_secondary_case".$DELIMITER;
	if($collection_date_table)
	{
		print "proposed_secondary_case_collection_date".$DELIMITER;
	}
	print "number_matched_iSNVs".$DELIMITER;
	print "median_matched_iSNV_frequency".$DELIMITER;
	print "min_matched_iSNV_frequency".$DELIMITER;
	print "max_matched_iSNV_frequency".$DELIMITER;
	print "matched_iSNV_frequencies".$DELIMITER;
	print "matched_iSNVs".$DELIMITER;
	print "other_consensus_level_differences".$NEWLINE;
}


# compares all pairs of samples
# prints potential transmission event if:
# - at least one allele in sample_1 at <100% frequency appears at 100% frequency in sample_2
# - consensus sequences otherwise have at most one other base difference (only substitutions compared)
# - sample_1 collection date < sample_2 collection date
# - sample_2 - sample_1 <= 6
foreach my $sample_name_1(keys %sample_names)
{
	if($sample_has_iSNVs{$sample_name_1})
	{
		foreach my $sample_name_2(potential_recipient_sample_names_with_collection_dates_consistent_with_index($sample_name_1))
		{
			if($sample_name_1 ne $sample_name_2)
			{
				my %iSNV_position_to_base = (); # key: position -> value: base that is iSNV in sample 1 and fixed in sample 2
			
				# checks if at least one allele in sample_1 at <100% frequency appears
				# at 100% frequency in sample_2
				foreach my $position(keys %{$sample_to_position_to_base_to_frequency{$sample_name_1}}) # for each position with heterozygosity in sample 1
				{
					foreach my $base(keys %{$sample_to_position_to_base_to_frequency{$sample_name_1}{$position}}) # for each allele at position in sample 1
					{
						# check if allele appears at consensus level in sample 2 near 100%
						if($sample_to_position_to_base_to_frequency{$sample_name_1}{$position}{$base} <= $MAXIMUM_INITIAL_ISNV_FREQUENCY # allele frequency in sample 1 is not too high
							and defined $sample_to_position_to_consensus_allele{$sample_name_2}{$position}
							and $sample_to_position_to_consensus_allele{$sample_name_2}{$position} eq $base # allele is at consensus level in sample 2
							and (!exists $sample_to_position_to_base_to_frequency{$sample_name_2}{$position} # no heterozygosity at this position in sample 2
								or (defined $sample_to_position_to_base_to_frequency{$sample_name_2}{$position}{$base}
									and $sample_to_position_to_base_to_frequency{$sample_name_2}{$position}{$base} >= $FIXED_FREQUENCY))) # or allele is near enough to 100% frequency in sample 2
						{
							$iSNV_position_to_base{$position} = $base;
						}
					}
				}
				
				# checks that consensus sequences otherwise have at most one other difference
				my $consensus_sequences_have_too_many_other_differences = 0;
				my @consensus_sequence_differences = ();
				if(scalar keys %iSNV_position_to_base)
				{
					my $sample_1_length = $sample_name_to_consensus_sequence_string_length{$sample_name_1};
					my $sample_2_length = $sample_name_to_consensus_sequence_string_length{$sample_name_2};
					
					my $position = 1;
					my $number_other_consensus_differences = 0;
					while($position <= min($sample_1_length, $sample_2_length)
						and !$consensus_sequences_have_too_many_other_differences)
					{
						if(!$iSNV_position_to_base{$position}) # if this isn't a position where an allele is an iSNV in sample 1 and fixed is sample 2
						{
							my $sample_1_consensus_allele = $sample_to_position_to_consensus_allele{$sample_name_1}{$position};
							my $sample_2_consensus_allele = $sample_to_position_to_consensus_allele{$sample_name_2}{$position};
						
							# assumes all saved bases are unambiguous bases
							if(defined $sample_1_consensus_allele and defined $sample_2_consensus_allele
								and $sample_1_consensus_allele ne $sample_2_consensus_allele)
							{
								$number_other_consensus_differences++;
								push(@consensus_sequence_differences, add_comma_separators($position).$sample_1_consensus_allele.$sample_2_consensus_allele);
								if($number_other_consensus_differences > $MAXIMUM_OTHER_CONSENSUS_DIFFERENCES)
								{
									$consensus_sequences_have_too_many_other_differences = 1;
								}
							}
						}
						$position++;
					}
				}
				
				# prints result
				if(scalar keys %iSNV_position_to_base
					and !$consensus_sequences_have_too_many_other_differences)
				{
					my @sample_pair_iSNVs = ();
					my @iSNV_frequencies = ();
					
					foreach my $position(sort {$a <=> $b} keys %iSNV_position_to_base)
					{
						# retrieves information for this allele
						my $base = $iSNV_position_to_base{$position};
						
						my $sample_1_frequency = $NO_DATA;
						my $sample_1_readcount = $NO_DATA;
						if(defined $sample_to_position_to_base_to_frequency{$sample_name_1}{$position}{$base})
						{
							$sample_1_frequency = $sample_to_position_to_base_to_frequency{$sample_name_1}{$position}{$base};
							$sample_1_readcount = $sample_to_position_to_base_to_readcount{$sample_name_1}{$position}{$base};
						}
						
						my $sample_2_frequency = $NO_DATA;
						my $sample_2_readcount = $NO_DATA;
						if(defined $sample_to_position_to_base_to_frequency{$sample_name_2}{$position}{$base})
						{
							$sample_2_frequency = $sample_to_position_to_base_to_frequency{$sample_name_2}{$position}{$base};
							$sample_2_readcount = $sample_to_position_to_base_to_readcount{$sample_name_2}{$position}{$base};
						}
					
						# retrieves list of other consensus-level differences
						my $other_consensus_level_differences_string = $NO_DATA;
						if(scalar @consensus_sequence_differences)
						{
							$other_consensus_level_differences_string = join(", ", @consensus_sequence_differences);
						}
					
						# prints line for this allele
						if($print_one_line_per_iSNV)
						{
							print $sample_name_1.$DELIMITER;
							if($collection_date_table)
							{
								print $sample_name_to_collection_date{$sample_name_1}.$DELIMITER;
							}
							print $sample_name_2.$DELIMITER;
							if($collection_date_table)
							{
								print $sample_name_to_collection_date{$sample_name_2}.$DELIMITER;
							}
							print $position.$DELIMITER;
							print $base.$DELIMITER;
							print $sample_1_frequency.$DELIMITER;
							print $sample_1_readcount.$DELIMITER;
# 	 						print $sample_2_frequency.$DELIMITER;
# 	 						print $sample_2_readcount.$DELIMITER;
							print $other_consensus_level_differences_string.$NEWLINE;
						}
						
						# generates string representing iSNV at this position
						push(@sample_pair_iSNVs, add_comma_separators($position)."".$base
							.": ".round_value(100*$sample_1_frequency, 1)."% (".add_comma_separators($sample_1_readcount).")");
						
						# saves iSNV frequency for generating median, min, max iSNV frequency
						push(@iSNV_frequencies, $sample_1_frequency);
					}
					
					# prints line for this sample pair
					if(!$print_one_line_per_iSNV)
					{
						# makes iSNV frequencies pretty for printing
						my @iSNV_frequencies_to_print = ();
						foreach my $iSNV_frequency(sort @iSNV_frequencies)
						{
							push(@iSNV_frequencies_to_print, round_value(100*$iSNV_frequency, 1)."%");
						}
					
						# prints line
						print $sample_name_1.$DELIMITER;
						if($collection_date_table)
						{
							print $sample_name_to_collection_date{$sample_name_1}.$DELIMITER;
						}
						print $sample_name_2.$DELIMITER;
						if($collection_date_table)
						{
							print $sample_name_to_collection_date{$sample_name_2}.$DELIMITER;
						}
						print scalar(@iSNV_frequencies).$DELIMITER;
						print round_value(100*median(@iSNV_frequencies), 1)."%".$DELIMITER;
						print round_value(100*min(@iSNV_frequencies), 1)."%".$DELIMITER;
						print round_value(100*max(@iSNV_frequencies), 1)."%".$DELIMITER;
						print join(", ", @iSNV_frequencies_to_print).$DELIMITER;
						print join("; ", @sample_pair_iSNVs).$DELIMITER;
						print join(", ", @consensus_sequence_differences).$NEWLINE;
					}
				}
			}
		}
	}
}


# processes and saves information on consensus sequence read in
sub process_sequence
{
	# saves length of consensus sequence string
	$sample_name_to_consensus_sequence_string_length{$sequence_name} = length $sequence;
	
	# reads in base at each position in each consensus sequence
	# only includes positions passing read depth filter
	my @consensus_genome_bases = split(//, $sequence);
	
	my $position = 0; # 1-indexed relative to reference
	for(my $base_index = 0; $base_index < $reference_sequence_string_length; $base_index++)
	{
		my $reference_base = $reference_bases[$base_index];
		if(is_base($reference_base))
		{
			# increments position only if valid base in reference sequence
			$position++;
	
			# retrieves and saves sample's base at this position
			my $base = $consensus_genome_bases[$base_index];
			if(is_unambiguous_base($base)
				and (!$read_depth_read_in_for_sample{$sequence_name}
					or $sample_to_position_to_read_depth{$sequence_name}{$position} >= $MINIMUM_READ_DEPTH))
			{
				$sample_to_position_to_consensus_allele{$sequence_name}{$position} = $base;
			}
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

# returns minimum value in input array
sub min
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# retrieves minimum value
	my $min_value = $values[0];
	foreach my $value(@values)
	{
		if($value < $min_value)
		{
			$min_value = $value;
		}
	}
	return $min_value;
}

# returns maximum value in input array
sub max
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# retrieves maximum value
	my $max_value = $values[0];
	foreach my $value(@values)
	{
		if($value > $max_value)
		{
			$max_value = $value;
		}
	}
	return $max_value;
}

# retrieves file name from file path
# input: file path, ex. /Users/lakras/filepath.txt
# output: file name, ex. filepath.txt
sub retrieve_file_name
{
	my $file_path = $_[0];
	if($file_path =~ /.*\/([^\/]+)$/)
	{
		return $1;
	}
	return $file_path;
}

# trims input file path from the right through first .
# returns empty string if no .
# example input: /Users/lakras/sample1.ext1.ext2.ext3
# example output: /Users/lakras/sample1.ext1.ext2
sub trim_off_file_extension
{
	my $file_name = $_[0];
	if($file_name =~ /^(.*)[.][^.]+$/)
	{
		return $1;
	}
	return "";
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

# input: floating point value (example: 3.14159)
# output: value rounded to nth decimal point (example: 3.1)
sub round_value
{
	my $value = $_[0];
	my $number_decimals = $_[1];
	return sprintf("%.".$number_decimals."f", $value);
}

# returns median of input array
sub median
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# sorts values
	@values = sort @values;
	
	# returns center
	if(scalar @values % 2 == 0) # even number of values
	{
		return ($values[scalar @values/2] + $values[scalar @values/2-1])/2;
	}
	else # odd number of values
	{
		return $values[scalar @values/2];
	}
}

# returns absolute value of input
sub absolute_value
{
	my $value = $_[0];
	if($value < 0)
	{
		$value *= -1;
	}
	return $value;
}

# returns a list of names of potential recipient samples with collection dates consistent
# with parameter index sample name
sub potential_recipient_sample_names_with_collection_dates_consistent_with_index
{
	my $index_sample_name = $_[0];
	
	# exit right away if we didn't read in collection dates
	if(!$collection_date_table)
	{
		return keys %sample_names;
	}
	
	# retrieve collection date of index
	my $index_collection_date = $sample_name_to_collection_date{$index_sample_name};
	my @sample_names_to_return = ();
	foreach my $potential_recipient_sample_name(keys %sample_names)
	{
		my $potential_recipient_collection_date = $sample_name_to_collection_date{$potential_recipient_sample_name};
		my $date_difference = date_difference($index_collection_date, $potential_recipient_collection_date); # recipient collection date - index collection date
		
		if((!$REQUIRE_INDEX_COLLECTION_DATE_BEFORE_RECIPIENT or $date_difference > 0) # index collection date < recipient collection date
			and (absolute_value($date_difference) <= $MAXIMUM_COLLECTION_DATE_DISTANCE)) # checks that recipient collection date - index collection date <= 6
		{
			push(@sample_names_to_return, $potential_recipient_sample_name);
		}
	}
	return @sample_names_to_return;
}

# returns 1 if input year is a leap year, 0 if not
# input example: 2001
sub is_leap_year
{
	my $year = $_[0];
	if($year % 4 == 0)
	{
		return 1;
	}
	return 0;
}

# returns date 2 - date 1, in days
# for a use case like checking collection date - vaccine dose date >= 14
# input format example: 2021-07-24
sub date_difference
{
	my $date_1 = $_[0];
	my $date_2 = $_[1];
	
	my %days_in_months = (1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31,
		6 => 30, 7 => 31, 8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31);
	my $days_in_year = 365;
	
	# verifies that we have two non-empty dates to compare
	if(!defined $date_1 or !length $date_1 or !$date_1
		or $date_1 eq "NA" or $date_1 eq "N/A" or $date_1 eq "NaN"
		or $date_1 !~ /\S/)
	{
		return "";
	}
	if(!defined $date_2 or !length $date_2 or !$date_2
		or $date_2 eq "NA" or $date_2 eq "N/A" or $date_2 eq "NaN"
		or $date_2 !~ /\S/)
	{
		return "";
	}
	
	# parses date 1
	my $year_1 = 0;
	my $month_1 = 0;
	my $day_1 = 0;
	if($date_1 =~ /^(\d{4})-(\d+)-(\d+)$/)
	{
		# retrieves date
		$year_1 = int($1);
		$month_1 = int($2);
		$day_1 = int($3);
	}
	else
	{
		print STDERR "Error: could not parse date: ".$date_1.".\n";
		return "";
	}
	if(!$days_in_months{$month_1})
	{
		print STDERR "Error: month not recognized: ".$month_1.".\n";
		return "";
	}
	
	# parses date 2
	my $year_2 = 0;
	my $month_2 = 0;
	my $day_2 = 0;
	if($date_2 =~ /^(\d{4})-(\d+)-(\d+)$/)
	{
		# retrieves date
		$year_2 = int($1);
		$month_2 = int($2);
		$day_2 = int($3);
	}
	else
	{
		print STDERR "Error: could not parse date: ".$date_2.".\n";
		return "";
	}
	if(!$days_in_months{$month_2})
	{
		print STDERR "Error: month not recognized: ".$month_2.".\n";
		return "";
	}
	
	# converts months to days
	$month_1--;
	while($month_1)
	{
		if(is_leap_year($year_1) and $month_1 == 2)
		{
			$day_1 ++;
		}
		$day_1 += $days_in_months{$month_1};
		$month_1--;
	}
	$month_2--;
	while($month_2)
	{
		if(is_leap_year($year_2) and $month_2 == 2)
		{
			$day_2 ++;
		}
		$day_2 += $days_in_months{$month_2};
		$month_2--;
	}
	
	# retrieves smallest of the two years
	my $smallest_year = $year_2;
	if($year_1 < $year_2)
	{
		$smallest_year = $year_1;
	}
	
	# converts years to days since smallest year
	$year_1--;
	while($year_1 >= $smallest_year)
	{
		if(is_leap_year($year_1))
		{
			$day_1 += 1;
		}
		$day_1 += $days_in_year;
		$year_1--;
	}
	$year_2--;
	while($year_2 >= $smallest_year)
	{
		if(is_leap_year($year_2))
		{
			$day_2 += 1;
		}
		$day_2 += $days_in_year;
		$year_2--;
	}
	
	# calculates and returns difference between dates
	my $difference = $day_2 - $day_1;
	return $difference;
}


# November 27, 2021
# March 31, 2022
