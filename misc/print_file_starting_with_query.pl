#!/usr/bin/env perl

# Prints contents of input file starting with line containing input query.

# Usage:
# perl print_file_starting_with_query.pl [file] [query] > [output file]


my $file = $ARGV[0]; # file containing list of values
my $query = $ARGV[1]; # query value


my $NEWLINE = "\n";


my $printing = 0;
open FILE, "<$file" || die "Could not open $file to read; terminating =(\n";
while(<FILE>) # for each line in the file
{
	chomp;
	if($_ =~ /$query/)
	{
		$printing = 1;
	}
	
	if($printing)
	{
		print $_.$NEWLINE;
	}
}
close FILE;


# April 23, 2024
