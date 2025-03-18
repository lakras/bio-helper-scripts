#!/usr/bin/env perl

# Prints all pairs of items from a list.

# Usage:
# perl all_pairs_from_a_list.pl [file with list, one item per line]

# Prints to console. To print to file, use
# perl all_pairs_from_a_list.pl [file with list, one item per line]
# > [file with all pairs, one pair per line, tab-separated]


my $list_file = $ARGV[0]; # file with list, one item per line


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file is provided, exists, and is not empty
if(!$list_file or !-e $list_file or -z $list_file)
{
	print STDERR "Error: list not provided, does not exist, or is empty. Exiting.\n";
	die;
}


# reads in the list
my %list = (); # key: value in list -> value: 1
open LIST, "<$list_file" || die "Could not open $list_file to read; terminating =(\n";
while(<LIST>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		$list{$_} = 1;
	}
}
close LIST;
my @items = keys %list;


# prints all pairs
for(my $i = 0; $i < @items; $i++)
{
    for(my $j = $i + 1; $j < @items; $j++)
    {
        print $items[$i].$DELIMITER.$items[$j].$NEWLINE;
    }
}


# March 18, 2025
