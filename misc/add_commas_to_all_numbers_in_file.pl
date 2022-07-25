#!/usr/bin/env perl

# Detects all numbers in contents of file and adds thousands-separator commas where needed.

# Usage:
# perl add_commas_to_all_numbers_in_file.pl [input file to add commas to]

# Prints to console. To print to file, use
# perl add_commas_to_all_numbers_in_file.pl [input file to add commas to]
# > [output file path]


use strict;
use warnings;


my $file = $ARGV[0]; # file to add commas to


my $COMMA = ",";


# verifies that input file exists and is non-empty
if(!$file or !-e $file or -z $file)
{
	print STDERR "Error: input file is empty or does not exist. Nothing for me to do. "
		."Exiting.\n";
	die;
}


# reads in and processes input file line by line
open INPUT_FILE, "<$file" || die "Could not open $file to read; terminating =(\n";
while(<INPUT_FILE>) # for each line in the file
{
	my $text = $_;
	
	# adds commas to any numbers that don't have them
	# from https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch02s18.html
	$text = reverse $text;
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1$COMMA/g;
	$text = scalar reverse $text;
	
	# prints updated text with commas added to numbers
	print $text;
}
close INPUT_FILE;


# July 25, 2022
