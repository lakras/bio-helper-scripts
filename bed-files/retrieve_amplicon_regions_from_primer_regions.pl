#!/usr/bin/env perl

# Reads in positions of primers and outputs positions of amplicons between those primers.
# Uses primer names to match left and right primers. Primer names must include the primer
# number and _LEFT or _RIGHT, for example nCoV-2019_1_LEFT or nCoV-2019_26_RIGHT.

# If more multiple start primers or multiple end primers are provided for an amplicon,
# the amplicon is set to be the largest possible with all its provided primers.

# Input primer positions are assumed to be indicated by first position (0-indexed) and
# non-inclusive end position (0-indexed). Output amplicon positions are also indicated by
# first position (0-indexed) and non-inclusive end position (0-indexed).

# Example rows of an input bed file, from the ARTICv3 primer set:

# MN908947.3	30	54	nCoV-2019_1_LEFT	1	+
# MN908947.3	385	410	nCoV-2019_1_RIGHT	1	-
# MN908947.3	320	342	nCoV-2019_2_LEFT	2	+
# MN908947.3	704	726	nCoV-2019_2_RIGHT	2	-
# ...
# MN908947.3	7626	7651	nCoV-2019_26_LEFT	2	+
# MN908947.3	7997	8019	nCoV-2019_26_RIGHT	2	-
# MN908947.3	7943	7968	nCoV-2019_27_LEFT	1	+
# MN908947.3	8319	8341	nCoV-2019_27_RIGHT	1	-

# and so on.


# Usage:
# perl retrieve_amplicon_regions_from_primer_regions.pl [primers bed file path]

# Prints to console. To print to file, use
# perl retrieve_amplicon_regions_from_primer_regions.pl [primers bed file path]
# > [amplicons bed file path]


use strict;
use warnings;


my $primers_bed_file = $ARGV[0]; # tab-separated table with columns: sequence name, first position (0-indexed), non-inclusive end position (0-indexed), primer name--primer names must end in the primer number and _LEFT or _RIGHT


# in input bed file:
my $SEQUENCE_NAME_COLUMN = 0;
my $START_POSITION_COLUMN = 1;
my $END_POSITION_COLUMN = 2;
my $PRIMER_NAME_COLUMN = 3;

my $DELIMITER = "\t";
my $NEWLINE = "\n";

my $LEFT_PRIMER = "LEFT";
my $RIGHT_PRIMER = "RIGHT";


# verifies that input bed file exists and is non-empty
if(!$primers_bed_file)
{
	print STDERR "Error: no input bed file provided. Exiting.\n";
	die;
}
if(!-e $primers_bed_file)
{
	print STDERR "Error: input bed file does not exist:\n\t".$primers_bed_file."\nExiting.\n";
	die;
}
if(-z $primers_bed_file)
{
	print STDERR "Error: input bed file is empty:\n\t".$primers_bed_file."\nExiting.\n";
	die;
}


# reads in primer positions described in bed file
my %amplicon_name_to_start = (); # key: amplicon name, from primer names -> value: first position in amplicon (0-indexed)
my %amplicon_name_to_end = (); # key: amplicon name, from primer names -> value: position after last position in amplicon (0-indexed)
my %amplicon_name_to_sequence_name = (); # key: amplicon name, from primer names -> value: name of sequence the amplicon comes from
my %amplicon_name_to_amplicon_number = (); # key: amplicon name, from primer names -> value: amplicon number from the name, to use for sorting output rows
open BED_FILE, "<$primers_bed_file" || die "Could not open $primers_bed_file to read; terminating =(\n";
while(<BED_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		# retrieves sequence name and start and end
		my @values = split($DELIMITER, $line);
		my $sequence_name = $values[$SEQUENCE_NAME_COLUMN];
		my $primer_name = $values[$PRIMER_NAME_COLUMN];
		my $primer_start = $values[$START_POSITION_COLUMN]; # first position (0-indexed)
		my $primer_end = $values[$END_POSITION_COLUMN]; # non-inclusive end position (0-indexed)
		
		# determines whether this is a left primer or a right primer, and the primer number
		if($primer_name =~ /(.*_)(\d+)_($LEFT_PRIMER|$RIGHT_PRIMER)/)
		{
			# retrieves primer number and left or right from name
			my $start_of_primer_name = $1;
			my $primer_number = $2;
			my $primer_type = $3;
			
			# determines amplicon name
			my $amplicon_name = $start_of_primer_name.$primer_number;
			$amplicon_name_to_amplicon_number{$amplicon_name} = $primer_number;
			
			# determines and saves start or end of amplicon
			if($primer_type eq $LEFT_PRIMER)
			{
				if(!$amplicon_name_to_start{$amplicon_name}
					or $primer_end < $amplicon_name_to_start{$amplicon_name})
				{
					$amplicon_name_to_start{$amplicon_name} = $primer_end;
				}
			}
			elsif($primer_type eq $RIGHT_PRIMER)
			{
				if(!$amplicon_name_to_end{$amplicon_name}
					or $primer_start > $amplicon_name_to_end{$amplicon_name})
				{
					$amplicon_name_to_end{$amplicon_name} = $primer_start;
				}
			}
			else
			{
				print STDERR "Error: could not parse primer name ".$primer_name."\n";
			}
			
			# saves sequence name
			$amplicon_name_to_sequence_name{$amplicon_name} = $sequence_name;
		}
		else
		{
			print STDERR "Error: could not parse primer name ".$primer_name."\n";
		}
	}
}
close BED_FILE;


# prints amplicon stars and ends
foreach my $amplicon_name(
	sort {$amplicon_name_to_amplicon_number{$a} <=> $amplicon_name_to_amplicon_number{$b}}
	keys %amplicon_name_to_sequence_name)
{
	# retrieves values
	my $sequence_name = "";
	if($amplicon_name_to_sequence_name{$amplicon_name})
	{
		$sequence_name = $amplicon_name_to_sequence_name{$amplicon_name};
	}
	
	my $amplicon_start = "";
	if($amplicon_name_to_start{$amplicon_name})
	{
		$amplicon_start = $amplicon_name_to_start{$amplicon_name};
	}
	
	my $amplicon_end = "";
	if($amplicon_name_to_end{$amplicon_name})
	{
		$amplicon_end = $amplicon_name_to_end{$amplicon_name};
	}
	
	# prints values
	print $sequence_name.$DELIMITER;
	print $amplicon_start.$DELIMITER;
	print $amplicon_end.$DELIMITER;
	print $amplicon_name.$NEWLINE;
}


# June 9, 2022
