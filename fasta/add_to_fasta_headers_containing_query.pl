#!/usr/bin/env perl

# Adds text to sequence names containing query.

# Usage:
# perl add_to_fasta_headers_containing_query.pl "[query 1]"
# "[text to add to sequence names containing query 1]" "[query 2]"
# "[text to add to sequence names containing query 2]" [etc.]

# Prints to console. To print to file, use
# perl add_to_fasta_headers_containing_query.pl "[query 1]"
# "[text to add to sequence names containing query 1]" "[query 2]"
# "[text to add to sequence names containing query 2]" [etc.] > [output fasta file path]


use strict;
use warnings;


my $fasta_file = $ARGV[0];
my @queries = @ARGV[grep {$_ % 2 == 1} 1..$#ARGV];
my @text_to_add = @ARGV[grep {$_ % 2 == 0} 2..$#ARGV];


my $NEWLINE = "\n";


# verifies that fasta file exists and is non-empty
if(!-e $fasta_file)
	{
		print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
		die;
	}
	if(-z $fasta_file)
	{
		print STDERR "Warning: input fasta file is empty:\n\t".$fasta_file."\n";
	}


# reads in fasta file; adds text to each sequence name with query text in it
open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
while(<FASTA_FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /^>(.*)/) # header line
	{
		for my $index(0..$#queries)
		{
			my $query = $queries[$index];
			my $this_text_to_add = $text_to_add[$index];
			
			if($1 =~ /$query/)
			{
				$_ .= $this_text_to_add;
			}
		}
	}
	print $_;
	print $NEWLINE;
}
close FASTA_FILE;


# February 14, 2025
