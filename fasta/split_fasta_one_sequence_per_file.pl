#!/usr/bin/env perl


# Splits fasta file into multiple files with one sequence per file. Each output file is
# named using the sequence name.

# Usage:
# perl split_fasta_one_sequence_per_file.pl [fasta file path]

# New files are created at filepath of old file with "_[sequence_name].fasta" appended to
# to the end. Files already at those paths will be overwritten.


use strict;
use warnings;


my $fasta_file = $ARGV[0];


# verifies that input fasta file exists and is not empty
if(!$fasta_file)
{
	print STDERR "Error: no input fasta file provided. Exiting.\n";
	die;
}
if(!-e $fasta_file)
{
	print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
	die;
}
if(-z $fasta_file)
{
	print STDERR "Error: input fasta file is empty:\n\t".$fasta_file."\nExiting.\n";
	die;
}


# reads in start of input fasta file to verify that we have enough sequences
my $number_sequences = 0;
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	if($_ =~ /^>/) # header line
	{
		$number_sequences++;
		
		# to avoid reading large files twice, stops reading once we have verified that
		# we have two sequences
		if($number_sequences >= 2)
		{
			close FASTA_FILE;
			last;
		}
	}
}
close FASTA_FILE;

if($number_sequences < 2)
{
	print STDERR "Fewer than 2 sequences in input file. My services are not needed here.\n";
	die;
}


# splits sequences in fasta file into a number of smaller files with one sequence per file
my %sequence_name_to_number_appearances = (); # key: sequence name -> value: number of times sequence name has been seen
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /^>(.*)$/) # header line
	{
		# closes current output file
		close OUT_FILE;
		
		# retrieves new sequence name
		my $sequence_name = $1;
		
		# records that we have seen this sequence
		$sequence_name_to_number_appearances{$sequence_name}++;
				
		# verifies that we have not seen this new sequence name before
		if($sequence_name_to_number_appearances{$sequence_name} > 1)
		{
			print STDERR "Warning: sequence name ".$sequence_name." appears more than once. ";
			
			# tries to give sequence a new name
			$sequence_name .= "__name_dup".($sequence_name_to_number_appearances{$sequence_name}-1);
			
			# if new name is also taken, adds to the end of it until it isn't
			while($sequence_name_to_number_appearances{$sequence_name})
			{
				$sequence_name .= "_name_dup";
			}
			
			# records that we have used this name
			$sequence_name_to_number_appearances{$sequence_name}++;
			
			print STDERR "Renaming to ".$sequence_name.".\n";
		}
		
		# opens new output file
		my $current_output_file = $fasta_file."_".make_safe_for_filename($sequence_name).".fasta";# 
		open OUT_FILE, ">$current_output_file" || die "Could not open $current_output_file to write; terminating =(\n";

	}
	print OUT_FILE $line;
	print OUT_FILE "\n";
}
close FASTA_FILE;
close OUT_FILE;


# makes string safe for use as a filename
# replaces all whitespace, |s, /s, and \s with underscores
sub make_safe_for_filename
{
	my $string = $_[0];
	
	# replaces all whitespace with _s
	$string =~ s/\s/_/g;
	
	# replaces all |s with _s
	$string =~ s/\|/_/g;
	
	# replaces all /s with _s
	$string =~ s/\//_/g;
	
	# replaces all \s with _s
	$string =~ s/\\/_/g;
	
	return $string;
}


# July 12, 2021