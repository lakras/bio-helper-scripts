#!/usr/bin/env perl

# Detects potential transmission events from iSNVs, assuming an average transmission
# bottleneck of one virus per transmission.

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
# [0 to print one line per sample pair, 1 to print one line per iSNV]

# Prints to console. To print to file, use
# perl detect_potential_transmission_events_from_iSNVs.pl
# [consensus sequences alignment fasta file path] [list of heterozygosity tables]
# [optional file containing list of read depth tables]
# [0 to print one line per sample pair, 1 to print one line per iSNV]
# > [output fasta file path]


use strict;
use warnings;


my $consensus_sequences_aligned = $ARGV[0]; # fasta alignment of consensus sequences; reference sequence must appear first
my $heterozygosity_tables = $ARGV[1]; # file containing a list of heterozygosity table files, one for each sample; positions must be relative to same reference used in fasta alignment file; filenames must contain sample names used in consensus genome alignment
my $read_depth_files = $ARGV[2]; # optional file containing a list of read depth files, one for each sample; positions must be relative to same reference used in both fasta alignment files; filenames must contain sample names used in consensus genome alignment
my $print_one_line_per_iSNV = $ARGV[3]; # if 0, prints one line per sample pair; if 1, prints line for each iSNV matched in each sample pair


# thresholds for calling a transmission event
my $FIXED_FREQUENCY = 0.9999; # minimum frequency at which we consider an allele to be fixed in a patient
my $MAXIMUM_INITIAL_ISNV_FREQUENCY = 0.90; # 90%; maximum frequency allele can be in index case
my $MAXIMUM_OTHER_CONSENSUS_DIFFERENCES = 1; # maximum number differences between consensus genomes other than transmitted iSNVs (comparing unambiguous bases, substitutions only)

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


# reads in aligned consensus sequences
my %sample_name_to_consensus_sequence = (); # key: sequence name -> value: consensus sequencw, including gaps froms alignment
my %sample_names = (); # key: name of sample -> value: 1
my $reference_sequence = ""; # first sequence in alignment
my $reference_sequence_name = ""; # name of first sequence in alignment

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
			if(!$reference_sequence) # reference sequence is first sequence in alignment
			{
				$reference_sequence = $sequence;
				$reference_sequence_name = $sequence_name;
			}
			else # not reference sequence
			{
				$sample_name_to_consensus_sequence{$sequence_name} = $sequence;
			}
			
		}
	
		# prepare for next sequence
		$sequence = "";
		$sequence_name = $1;
		if($reference_sequence_name) # if reference sequence has already been read in
		{
			# this sequence name is a sample name
			$sample_names{$sequence_name} = 1;
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
	$sample_name_to_consensus_sequence{$sequence_name} = uc($sequence);
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


# reads in base at each position in each consensus sequence
# only includes positions passing read depth filter
my %sample_to_position_to_consensus_allele = (); # key: sample name -> key: position (1-indexed relative to reference) -> value: base in consensus sequence
my @reference_bases = split(//, $reference_sequence);
foreach my $sample_name(keys %sample_name_to_consensus_sequence)
{
	my $consensus_genome = $sample_name_to_consensus_sequence{$sample_name};
	my @consensus_genome_bases = split(//, $consensus_genome);
	
	my $position = 0; # 1-indexed relative to reference
	for(my $base_index = 0; $base_index < length($reference_sequence); $base_index++)
	{
		my $reference_base = $reference_bases[$base_index];
		if(is_base($reference_base))
		{
			# increments position only if valid base in reference sequence
			$position++;
	
			# retrieves and saves sample's base at this position
			my $base = $consensus_genome_bases[$base_index];
			if(is_unambiguous_base($base)
				and (!$read_depth_read_in_for_sample{$sample_name}
					or $sample_to_position_to_read_depth{$sample_name}{$position} >= $MINIMUM_READ_DEPTH))
			{
				$sample_to_position_to_consensus_allele{$sample_name}{$position} = $base;
			}
		}
	}
}


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
	print "to_sample".$DELIMITER;
	print "position".$DELIMITER;
	print "base".$DELIMITER;
	print "frequency_in_from_sample".$DELIMITER;
	print "readcount_in_from_sample".$DELIMITER;
# 	print "sample_2_frequency".$DELIMITER;
# 	print "sample_2_readcount".$DELIMITER;
	print "other_consensus_level_differences".$NEWLINE;
}
else
{
	# index case	secondary case	number matched iSNVs in index case	median matched iSNV frequency	min matched iSNV frequency	max matched iSNV frequency	matched iSNV frequencies
	print "from_sample".$DELIMITER;
	print "to_sample".$DELIMITER;
	print "number_iSNVs".$DELIMITER;
	print "median_iSNV_frequency".$DELIMITER;
	print "min_iSNV_frequency".$DELIMITER;
	print "max_iSNV_frequency".$DELIMITER;
	print "iSNV_frequencies".$DELIMITER;
	print "iSNVs".$DELIMITER;
	print "other_consensus_level_differences".$NEWLINE;
}


# compares all pairs of samples
# prints potential transmission event if:
# - at least one allele in sample_1 at <100% frequency appears at 100% frequency in sample_2
# - consensus sequences otherwise have at most one other base difference (only substitutions compared)
my %sample_pairs_ = (); # key: sample 1 sample 2 -> value: 1
foreach my $sample_name_1(keys %sample_names)
{
	if($sample_has_iSNVs{$sample_name_1})
	{
		foreach my $sample_name_2(keys %sample_names)
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
					my $sample_1_length = length $sample_name_to_consensus_sequence{$sample_name_1};
					my $sample_2_length = length $sample_name_to_consensus_sequence{$sample_name_2};
					
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
					
					foreach my $position(sort keys %iSNV_position_to_base)
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
							print $sample_name_2.$DELIMITER;
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
						print $sample_name_2.$DELIMITER;
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


# November 27, 2021
