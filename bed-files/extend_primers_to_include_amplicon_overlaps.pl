#!/usr/bin/env perl

# Extends primers to include positions that are in more than one amplicon. Amplicons in
# the resulting bed file do not overlap. Outputs new primer bed file.

# Only includes one left and one right primer for each amplicon. If _alt versions of
# primers are included, only includes the last _alt listed for that primer.

# Assumes that stretches of positions in more than one amplicon each neighbors a primer.

# Assumes all amplicons come from only one reference sequence.

# Uses primer names to match left and right primers. Primer names must include the primer
# number and _LEFT or _RIGHT, for example nCoV-2019_1_LEFT or nCoV-2019_26_RIGHT.
# If more multiple start primers or multiple end primers are provided for an amplicon,
# the amplicon is set to be the largest possible with all its provided primers.
# ...Or maybe try with all possible ones included!

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
# perl extend_primers_to_include_amplicon_overlaps.pl [primers bed file path]

# Prints to console. To print to file, use
# perl extend_primers_to_include_amplicon_overlaps.pl [primers bed file path]
# > [new primers bed file path]


use strict;
use warnings;


my $primers_bed_file = $ARGV[0]; # tab-separated table with columns: sequence name, first position (0-indexed), non-inclusive end position (0-indexed), primer name--primer names must end in the primer number and _LEFT or _RIGHT


# in input bed file:
my $SEQUENCE_NAME_COLUMN = 0;
my $START_POSITION_COLUMN = 1;
my $END_POSITION_COLUMN = 2;
my $PRIMER_NAME_COLUMN = 3;
my @OTHER_VALUES_COLUMNS = (4, 5); # column numbers of other values that should be included at end of output rows

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

my %amplicon_name_to_left_primer_name = ();
my %amplicon_name_to_left_primer_start = (); # first position (0-indexed)
my %amplicon_name_to_left_primer_end = (); # non-inclusive end position (0-indexed)
my %amplicon_name_to_left_primer_other_values = ();

my %amplicon_name_to_right_primer_name = ();
my %amplicon_name_to_right_primer_start = (); # first position (0-indexed)
my %amplicon_name_to_right_primer_end = (); # non-inclusive end position (0-indexed)
my %amplicon_name_to_right_primer_other_values = ();

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
		
		my $other_values = "";
		foreach my $column(@OTHER_VALUES_COLUMNS)
		{
			$other_values .= $DELIMITER.$values[$column];
		}
		
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
				
				# saves primer details
				$amplicon_name_to_left_primer_name{$amplicon_name} = $primer_name;
				$amplicon_name_to_left_primer_start{$amplicon_name} = $primer_start;
				$amplicon_name_to_left_primer_end{$amplicon_name} = $primer_end;
				$amplicon_name_to_left_primer_other_values{$amplicon_name} = $other_values;
			}
			elsif($primer_type eq $RIGHT_PRIMER)
			{
				if(!$amplicon_name_to_end{$amplicon_name}
					or $primer_start > $amplicon_name_to_end{$amplicon_name})
				{
					$amplicon_name_to_end{$amplicon_name} = $primer_start;
				}
				
				# saves primer details
				$amplicon_name_to_right_primer_name{$amplicon_name} = $primer_name;
				$amplicon_name_to_right_primer_start{$amplicon_name} = $primer_start;
				$amplicon_name_to_right_primer_end{$amplicon_name} = $primer_end;
				$amplicon_name_to_right_primer_other_values{$amplicon_name} = $other_values;
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


# determines first and last position in the genome overlapping any amplicon
# counts number of amplicons overlapping each position
my $first_position = -1; # first position in the genome overlapping any amplicon
my $last_position = -1; # last position in the genome overlapping any amplicon
my %position_to_number_overlapping_amplicons = (); # key: position -> value: number amplicons overlapping this position
foreach my $amplicon_name(
	sort {$amplicon_name_to_amplicon_number{$a} <=> $amplicon_name_to_amplicon_number{$b}}
	keys %amplicon_name_to_sequence_name)
{
	# retrieves values
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
	
	# adds to counts
	for(my $position = $amplicon_start; $position <= $amplicon_end; $position++)
	{
		$position_to_number_overlapping_amplicons{$position}++;
	}
	
	# sets min and max values
	if($first_position == -1 or $amplicon_start < $first_position)
	{
		$first_position = $amplicon_start;
	}
	if($last_position == -1 or $amplicon_end > $last_position)
	{
		$last_position = $amplicon_end;
	}
}


# for each primer, extends it in both directions until it hits a position with only
# one amplicon overlapping it
foreach my $amplicon_name(
	sort {$amplicon_name_to_amplicon_number{$a} <=> $amplicon_name_to_amplicon_number{$b}}
	keys %amplicon_name_to_left_primer_name)
{
	my @primers = ("left", "right");
	foreach my $primer(@primers)
	{
		# retrieves primer start and end
		my $primer_start = -1; # first position (0-indexed)
		my $primer_end = -1; # non-inclusive end position (0-indexed)
		if($primer eq "left")
		{
			$primer_start = $amplicon_name_to_left_primer_start{$amplicon_name};
			$primer_end = $amplicon_name_to_left_primer_end{$amplicon_name};
		}
		elsif($primer eq "right")
		{
			$primer_start = $amplicon_name_to_right_primer_start{$amplicon_name};
			$primer_end = $amplicon_name_to_right_primer_end{$amplicon_name};
		}
		else
		{
			print STDERR "Error in code: primer ".$primer." is not left or right.\n";
			die;
		}
		
		# extends primer in both directions until it hits a position with only
		# one amplicon overlapping it
		# extends primer start position left (decreases primer start position)
		while($position_to_number_overlapping_amplicons{$primer_start}
			and $position_to_number_overlapping_amplicons{$primer_start} > 1)
		{
			$position_to_number_overlapping_amplicons{$primer_start}
				= $position_to_number_overlapping_amplicons{$primer_start} - 1;
			$primer_start = $primer_start - 1;
		}
		
		# extends primer end position right (increases primer end position)
		while($position_to_number_overlapping_amplicons{$primer_end-1}
			and $position_to_number_overlapping_amplicons{$primer_end-1} > 1)
		{
			$position_to_number_overlapping_amplicons{$primer_end-1}
				= $position_to_number_overlapping_amplicons{$primer_end-1} - 1;
			$primer_end = $primer_end + 1;
		}
		
		# saves updated primer start and end
		if($primer eq "left")
		{
			$amplicon_name_to_left_primer_start{$amplicon_name} = $primer_start;
			$amplicon_name_to_left_primer_end{$amplicon_name} = $primer_end;
		}
		elsif($primer eq "right")
		{
			$amplicon_name_to_right_primer_start{$amplicon_name} = $primer_start;
			$amplicon_name_to_right_primer_end{$amplicon_name} = $primer_end;
		}
		else
		{
			print STDERR "Error in code: primer ".$primer." is not left or right.\n";
			die;
		}
	}
}


# prints output bed file with updated primers
my $output_bed_file_content = "";
foreach my $amplicon_name(
	sort {$amplicon_name_to_amplicon_number{$a} <=> $amplicon_name_to_amplicon_number{$b}}
	keys %amplicon_name_to_left_primer_name)
{
	$output_bed_file_content .= $amplicon_name_to_sequence_name{$amplicon_name}.$DELIMITER;
	$output_bed_file_content .= $amplicon_name_to_left_primer_start{$amplicon_name}.$DELIMITER;
	$output_bed_file_content .= $amplicon_name_to_left_primer_end{$amplicon_name}.$DELIMITER;
	$output_bed_file_content .= $amplicon_name_to_left_primer_name{$amplicon_name};
	$output_bed_file_content .= $amplicon_name_to_left_primer_other_values{$amplicon_name}.$NEWLINE;
	
	$output_bed_file_content .= $amplicon_name_to_sequence_name{$amplicon_name}.$DELIMITER;
	$output_bed_file_content .= $amplicon_name_to_right_primer_start{$amplicon_name}.$DELIMITER;
	$output_bed_file_content .= $amplicon_name_to_right_primer_end{$amplicon_name}.$DELIMITER;
	$output_bed_file_content .= $amplicon_name_to_right_primer_name{$amplicon_name};
	$output_bed_file_content .= $amplicon_name_to_right_primer_other_values{$amplicon_name}.$NEWLINE;
}
print $output_bed_file_content;


# reads in primer positions described in output bed file
%amplicon_name_to_start = (); # key: amplicon name, from primer names -> value: first position in amplicon (0-indexed)
%amplicon_name_to_end = (); # key: amplicon name, from primer names -> value: position after last position in amplicon (0-indexed)
%amplicon_name_to_sequence_name = (); # key: amplicon name, from primer names -> value: name of sequence the amplicon comes from
%amplicon_name_to_amplicon_number = (); # key: amplicon name, from primer names -> value: amplicon number from the name, to use for sorting output rows
my @output_bed_file_content_lines = split /$NEWLINE/, $output_bed_file_content;
foreach my $line(@output_bed_file_content_lines) # for each line in the output bed file content
{
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


# determines first and last position in the genome overlapping any amplicon
# counts number of amplicons overlapping each position in output bed file
$first_position = -1; # first position in the genome overlapping any amplicon
$last_position = -1; # last position in the genome overlapping any amplicon
%position_to_number_overlapping_amplicons = (); # key: position -> value: number amplicons overlapping this position
foreach my $amplicon_name(
	sort {$amplicon_name_to_amplicon_number{$a} <=> $amplicon_name_to_amplicon_number{$b}}
	keys %amplicon_name_to_sequence_name)
{
	# retrieves values
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
	
	# adds to counts
	for(my $position = $amplicon_start; $position <= $amplicon_end; $position++)
	{
		$position_to_number_overlapping_amplicons{$position}++;
	}
	
	# sets min and max values
	if($first_position == -1 or $amplicon_start < $first_position)
	{
		$first_position = $amplicon_start;
	}
	if($last_position == -1 or $amplicon_end > $last_position)
	{
		$last_position = $amplicon_end;
	}
}


# if a position is in more than one amplicon, sends up an error
my $error_output_list = "";
for(my $position = $first_position; $position <= $last_position; $position++)
{
	if($position_to_number_overlapping_amplicons{$position}
		and $position_to_number_overlapping_amplicons{$position} > 1)
	{
		$error_output_list .= $position."\n";
	}
}
if($error_output_list)
{
	print STDERR "Error: positions overlapping more than one amplicon:\n"
		.$error_output_list;
}


# June 9, 2022
# October 23, 2022
# November 23, 2022
