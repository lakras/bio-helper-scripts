#!/usr/bin/env perl

# Replaces column title with new column title.

# Usage:
# perl replace_column_title.pl [table] "[current title of column to replace]"
# "[replacement column title]"

# Prints to console. To print to file, use
# perl replace_column_title.pl [table] "[current title of column to replace]"
# "[replacement column title]" > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];
my $column_title_to_replace = $ARGV[1];
my $new_column_title = $ARGV[2];


my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in and processes input table
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
			my $column_title_to_replace_found = 0;
			my $header_line_to_print = "";
			my @items_in_line = split($DELIMITER, $line, -1);
			foreach my $column_title(@items_in_line)
			{
				# adds delimiter (tab)
				if($header_line_to_print)
				{
					$header_line_to_print .= $DELIMITER;
				}
			
				# adds column title
				if($column_title eq $column_title_to_replace)
				{
					if($column_title_to_replace_found)
					{
						print STDERR "Warning: column title to replace ".$column_title_to_replace
							." encountered more than once in table:\n\t".$table
							."\nReplacing all occurrences.\n";
					}
				
					$header_line_to_print .= $new_column_title;
					$column_title_to_replace_found = 1;
				}
				else
				{
					$header_line_to_print .= $column_title;
				}
			}
			
			# verifies that we have found column title to replace
			if(!$column_title_to_replace_found)
			{
				print STDERR "Warning: column title to replace ".$column_title_to_replace
					." not found in table:\n\t".$table."\n";
			}
			
			# prints output header line with replaced column title
			print $header_line_to_print.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# prints output line
			print $line.$NEWLINE;
		}
	}
}
close TABLE;


# August 24, 2021
