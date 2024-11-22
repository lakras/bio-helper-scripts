#!/usr/bin/env perl

# Adds number unambiguous bases (A, T, C, or G) in each sequence to table. Sequence names
# appearing in fasta file headers must appear in first column of table.

# Usage:
# perl add_number_unambiguous_bases_to_table.pl [fasta file path] [table path]

# Prints to console. To print to file, use
# perl add_number_unambiguous_bases_to_table.pl [fasta file path] [table path] >
# [output table path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my $table = $ARGV[1];


my $NEWLINE = "\n";
my $DELIMITER = "\t";
my $NO_DATA = "NA";


# verifies that fasta file exists and is non-empty
if(!$fasta_file or !-e $fasta_file or -z $fasta_file)
{
	print STDERR "Error: input fasta file not provided, does not exist, or is empty:\n"
		.$fasta_file."\nExiting.\n";
	die;
}

# verifies that table exists and is non-empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: input table not provided, does not exist, or is empty:\n"
		.$table."\nExiting.\n";
	die;
}

# reads in fasta file
my $current_sequence = "";
my $current_sequence_name = "";
my %sequence_name_to_sequence = (); # key: sequence name -> value: sequence read in
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		# process previous sequence if it has been read in
		if($current_sequence)
		{
			$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
		}
		
		# save new sequence name and prepare to read in new sequence
		$current_sequence_name = $1;
		$current_sequence = "";
	}
	else # not header line
	{
		$current_sequence .= uc($_);
	}
}
if($current_sequence)
{
	$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
}
close FASTA_FILE;


# counts number unambiguous bases in each sequence
my %sequence_name_to_number_unambiguous_bases = ();
foreach my $sequence_name(keys %sequence_name_to_sequence)
{
	# counts number unambiguous bases
	my $sequence = $sequence_name_to_sequence{$sequence_name};
	my $number_unambiguous_bases = 0;
	for my $base(split(//, $sequence))
	{
		if(is_unambiguous_base($base))
		{
			$number_unambiguous_bases++;
		}
	}
	
	# saves number unambiguous bases
	$sequence_name_to_number_unambiguous_bases{$sequence_name} = $number_unambiguous_bases;
}


# reads in table and prints with added column with number unambiguous bases
my $first_line = 1;
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		if($first_line) # column titles
		{
			# prints line as is
			print $line;
			
			# prints title of new column
			print $DELIMITER;
			print "number_unambiguous_bases";
			print $NEWLINE;
			
			$first_line = 0;
		}
		else # column values (not column titles)
		{
			# reads in sequence name
			my @items_in_line = split($DELIMITER, $line, -1);
			my $sequence_name = $items_in_line[0];
			
			# retrieves number unambiguous bases
			my $number_unambiguous_bases = $NO_DATA;
			if($sequence_name_to_number_unambiguous_bases{$sequence_name})
			{
				$number_unambiguous_bases = $sequence_name_to_number_unambiguous_bases{$sequence_name};
			}
		
			# prints line as is
			print $line;
			
			# prints number unambiguous bases
			print $DELIMITER;
			print $number_unambiguous_bases;
			print $NEWLINE;
		}
	}
}
close TABLE;


# returns 1 if base is A, T, C, or G, 0 if not
sub is_unambiguous_base
{
	my $base = $_[0];
	
	if($base eq "-")
	{
		print STDERR "Error: sequence contains gaps and is therefore an alignment. "
			."Exiting.\n";
		die;
	}
	
	if($base eq "A" or $base eq "a")
	{
		return 1;
	}
	if($base eq "T" or $base eq "t")
	{
		return 1;
	}
	if($base eq "C" or $base eq "c")
	{
		return 1;
	}
	if($base eq "G" or $base eq "g")
	{
		return 1;
	}
	
	return 0;
}


# November 21, 2024
