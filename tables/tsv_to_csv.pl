#!/usr/bin/env perl

# Converts tab-separated tsv table to comma-separated csv table.

# Usage:
# perl tsv_to_csv.pl [table]

# Prints to console. To print to file, use
# perl tsv_to_csv.pl [table] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];


my $NEWLINE = "\n";
my $PREVIOUS_DELIMITER = "\t";
my $NEW_DELIMITER = ",";
my $ESCAPE_QUOTATIONS_CHARACTER = "\"";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in and processes input table
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	
	# selects reserved character or character set
	my $reserved_character = generate_character_string_not_in_input_string($line);
	if($line =~ /$reserved_character/)
	{
		print STDERR "Error: line contains selected reserved character "
			.$reserved_character."\n";
		die;
	}
	
	# replaces all commas within quotes with reserved character
	while($line =~ /$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)$ESCAPE_QUOTATIONS_CHARACTER/)
	{
		print "test";
		$line =~ s/$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)"/"$1$reserved_character$2$ESCAPE_QUOTATIONS_CHARACTER/g;
	}
	
	# replaces all commas with tabs
	$line =~ s/$PREVIOUS_DELIMITER/$NEW_DELIMITER/g;
	
	# replaces reserved character with commas
	$line =~ s/$reserved_character/$PREVIOUS_DELIMITER/g;
	
	# deletes all quotes
	$line =~ s/$ESCAPE_QUOTATIONS_CHARACTER//g;
	
	# prints resulting line
	print $line;
	print $NEWLINE;
}
close TABLE;


# generates string of characters not found in input string
sub generate_character_string_not_in_input_string
{
	my $input_string = $_[0];
	my $absent_character_string = 0;
	while($input_string =~ /$absent_character_string/)
	{
		$absent_character_string++;
	}
	return $absent_character_string;
}


# February 23, 2022
