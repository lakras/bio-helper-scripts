#!/usr/bin/env perl

# Prints intersection of two lists.

# Usage:
# perl intersection_of_two_lists.pl [file with first list, one item per line]
# [file with second list, one item per line]

# Prints to console unless specified to print each heterozygosity table separately.
# To print to file, use
# perl intersection_of_two_lists.pl [file with first list, one item per line]
# [file with second list, one item per line] > [file with intersection]


my $list1_file = $ARGV[0]; # file with first list, one item per line
my $list2_file = $ARGV[1]; # file with second list, one item per line

my $NEWLINE = "\n";


# verifies that input files are provided, exist, and are not empty
if(!$list1_file or !-e $list1_file or -z $list1_file)
{
	print STDERR "Error: first list not provided, does not exist, or is empty. "
		."Exiting.\n";
	die;
}
if(!$list2_file or !-e $list2_file or -z $list2_file)
{
	print STDERR "Error: second list not provided, does not exist, or is empty. "
		."Exiting.\n";
	die;
}


# reads in the two lists
my %list1 = (); # key: value in first list -> value: 1
open LIST1, "<$list1_file" || die "Could not open $list1_file to read; terminating =(\n";
while(<LIST1>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		$list1{$_} = 1;
	}
}
close LIST1;

my %list2 = (); # key: value in second list -> value: 1
open LIST2, "<$list2_file" || die "Could not open $list2_file to read; terminating =(\n";
while(<LIST2>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		$list2{$_} = 1;
	}
}
close LIST2;


# identifies and prints values appearing in both lists
foreach my $value(sort keys %list1)
{
	if($list2{$value})
	{
		print $value.$NEWLINE;
	}
}


# January 27, 2025
