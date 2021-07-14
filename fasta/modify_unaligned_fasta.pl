#!/usr/bin/env perl

# Modifies unaligned fasta file according to allele changes specified in changes table.
# Not designed to handle gaps.

# Columns in changes table, tab-separated, no header line:
# - name of sequence to change (must match sequence name in fasta)
# - position in sequence (1-indexed)
# - current allele at that position
# - allele to change it to

# Positions in changes table (1-indexed) must be relative to each individual sequence to
# change. Sequence names in unaligned fasta file and in changes table must match. Sequences
# should not have gaps, but if they do, the gaps will not get special treatment: a gap
# will count as occupying a position in the sequence just as a base would.

# Usage:
# perl modify_unaligned_fasta.pl [alignment fasta file path] [changes table]

# Prints to console. To print to file, use
# perl modify_unaligned_fasta.pl [alignment fasta file path] [changes table] > [output fasta file path]


use strict;
use warnings;

my $fasta_file = $ARGV[0]; # unaligned fasta file
my $changes_table = $ARGV[1]; # table describing changes to make to sequences in fasta file

my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in changes file

# in changes file:
my $SEQUENCE_NAME_COLUMN = 0;
my $POSITION_COLUMN = 1;
my $CURRENT_ALLELE_COLUMN = 2;
my $REPLACEMENT_ALLELE_COLUMN = 3;

# verifies that fasta alignment file exists and is non-empty
if(!$fasta_file)
{
	print STDERR "Error: no input fasta alignment file provided. Exiting.\n";
	die;
}
if(!-e $fasta_file)
{
	print STDERR "Error: input fasta alignment file does not exist:\n\t".$fasta_file."\nExiting.\n";
	die;
}
if(-z $fasta_file)
{
	print STDERR "Error: input fasta alignment file is empty:\n\t".$fasta_file."\nExiting.\n";
	die;
}

# verifies that changes table exists and is non-empty
if(!$changes_table)
{
	print STDERR "Error: no changes table provided. Exiting.\n";
	die;
}
if(!-e $changes_table)
{
	print STDERR "Error: changes table does not exist:\n\t".$changes_table."\nExiting.\n";
	die;
}
if(-z $changes_table)
{
	print STDERR "Error: changes table is empty:\n\t".$changes_table."\nExiting.\n";
	die;
}


# reads in changes to make
my %position_to_current_allele = (); # key: sequence name -> key: position -> value: current allele
my %position_to_replacement_allele = (); # key: sequence name -> key: position -> value: replacement allele
open CHANGES_FILE, "<$changes_table" || die "Could not open $changes_table to read; terminating =(\n";
while(<CHANGES_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		my @items_in_row = split($DELIMITER, $_);
		
		my $sequence_name = $items_in_row[$SEQUENCE_NAME_COLUMN];
		my $position = $items_in_row[$POSITION_COLUMN];
		my $current_allele = uc($items_in_row[$CURRENT_ALLELE_COLUMN]);
		my $replacement_allele = uc($items_in_row[$REPLACEMENT_ALLELE_COLUMN]);
		
		$position_to_current_allele{$sequence_name}{$position} = $current_allele;
		$position_to_replacement_allele{$sequence_name}{$position} = $replacement_allele;
	}
}
close CHANGES_FILE;


# reads in fasta sequences
# prints updated fasta sequences
my $current_sequence = "";
my $current_sequence_name = "";
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		process_sequence();
		
		# save new sequence name and prepare to read in new sequence
		$current_sequence_name = $1;
		$current_sequence = "";
	}
	else
	{
		$current_sequence .= uc($_);
	}
}
process_sequence();
close FASTA_FILE;


# introduces changes described in changes file and prints modified sequence
sub process_sequence
{
	# exit if no sequence read in
	if(!$current_sequence)
	{
		return;
	}
	
	# prints a warning if sequence contains gaps
	if($current_sequence =~ /-/)
	{
		print STDERR "Warning: sequence ".$current_sequence_name." contains gaps. "
			."modify_unaligned_fasta.pl is not designed to handle gaps: position is "
			."defined by a base's position in the sequence string, not taking gaps into "
			."account (a gap will count occupying as a position in the sequence just as a "
			."base would). Changes may not be made in intended positions. If this is an "
			."alignment, consider using modify_alignment_fasta.pl instead.\n";
	}
	
	# updates sequence according to changes described in change file
	foreach my $position(keys %{$position_to_current_allele{$current_sequence_name}})
	{
		my $current_allele = $position_to_current_allele{$current_sequence_name}{$position};
		my $replacement_allele = $position_to_replacement_allele{$current_sequence_name}{$position};

		# retrieves string index corresponding to this position
		my $string_index = $position - 1;

		# verifies that position (1-indexed) is within range
		if($string_index >= length($current_sequence))
		{
			print STDERR "Warning: position ".$position." (string index ".$string_index
				.") to change is out of range of sequence ".$current_sequence_name.".\n";
		}
		else
		{
			# verifies that observed current allele is expected current allele at that position
			my $observed_current_allele = substr($current_sequence, $string_index, 1);
			if($observed_current_allele ne $current_allele)
			{
				print STDERR "Warning: unexpected current allele at position ".$position
					." in sequence ".$current_sequence_name.". Expected $current_allele, "
					."instead see ".$observed_current_allele.".\n";
			}
			else
			{
				# updates allele at position
				substr($current_sequence, $string_index, 1, $replacement_allele);
			}
		}
	}
	
	# prints updated sequence
	print ">".$current_sequence_name.$NEWLINE;
	print $current_sequence.$NEWLINE;
}

# January 26, 2021
# July 14, 2021
