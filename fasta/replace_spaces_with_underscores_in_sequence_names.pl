#!/usr/bin/env perl

# Replaces spaces with underscores in sequence names. Optionally, also removes
# non-alphanumeric characters.

# Usage:
# perl replace_spaces_with_underscores_in_sequence_names.pl [fasta file path]

# Prints to console. To print to file, use
# perl replace_spaces_with_underscores_in_sequence_names.pl [fasta file path]
# > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];


my $UNDERSCORE = "_";
my $NEWLINE = "\n";


my $REMOVE_NON_ALPHANUMERIC_CHARACTERS = 1;


# verifies that input files exist and are non-empty
if(!-e $fasta_file)
{
	print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
	die;
}
if(-z $fasta_file)
{
	print STDERR "Warning: input fasta file is empty:\n\t".$fasta_file."\n";
}


# reads in fasta file; renames each header
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)$/) # header line
	{
		# replaces spaces in sequence name
		my $name = $1;
		$name =~ s/\s+/$UNDERSCORE/g;
		
		if($REMOVE_NON_ALPHANUMERIC_CHARACTERS)
		{
			$name =~ s/[^a-zA-Z0-9._-]//g;
		}
		
		# prints sequence name
		print ">".$name.$NEWLINE;
	}
	else # sequence
	{
		print $_.$NEWLINE;
	}
}
close FASTA_FILE;


# February 10, 2025
