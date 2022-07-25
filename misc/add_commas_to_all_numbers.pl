#!/usr/bin/env perl

# Detects all numbers in input text and adds thousands-separator commas where needed.

# Usage:
# perl add_commas_to_all_numbers.pl [text to add commas to]

# Prints to console. To print to file, use
# perl add_commas_to_all_numbers.pl "[text to add commas to]" > [output file path]


use strict;
use warnings;


my $text = $ARGV[0]; # text to add commas to


my $COMMA = ",";


# verifies that input text non-empty
if(!$text)
{
	print STDERR "Error: no input text provided. Nothing for me to do. Exiting.\n";
	die;
}


# adds commas to any numbers that don't have them
# from https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch02s18.html
$text = reverse $text;
$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1$COMMA/g;
$text = scalar reverse $text;


# prints updated text with commas added to numbers
print $text;


# July 25, 2022
