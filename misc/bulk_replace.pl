#!/usr/bin/env perl

# Replaces all occurrences of values to mapped replacement values. Values to replace must
# be surrounded by whitespace or at the start or end of a line.

# Usage:
# perl bulk_replace.pl [tab-separated file mapping current values (first column) to new
# values (second column)] [path of file in which to replace values]
# [path of second file in which to replace values] [etc.]

# New files are created at filepath of input file with "_replaced.txt" appended to the end.
# Files already at those paths will be overwritten.


use strict;
use warnings;


my $replacement_map_file = $ARGV[0];
my @input_files = @ARGV[1..$#ARGV];


my $NEWLINE = "\n";
my $DELIMITER = "\t"; # in replacement map file

# replacement map columns:
my $CURRENT_VALUE_COLUMN = 0;
my $NEW_VALUE_COLUMN = 1;

my $OVERWRITE = 1; # set to 0 to prevent overwriting (stop script rather than overwrite)


# verifies that input file exists and is not empty
if(!$replacement_map_file or !-e $replacement_map_file or -z $replacement_map_file)
{
	print STDERR "Error: replacement map file not provided, does not exist, or empty:\n\t"
		.$replacement_map_file."\nExiting.\n";
	die;
}
if(scalar @input_files == 0)
{
	print STDERR "Error: no input file provided.\n";
	die;
}
foreach my $input_file(@input_files)
{
	if(!-e $input_file or -z $input_file)
	{
		print STDERR "Error: input file does not exist or is empty:\n\t".$input_file
			."\nExiting.\n";
		die;
	}
}


# read in map of new and old values
my %current_value_to_new_value = (); # key: old value -> value: new value
open REPLACEMENT_MAP, "<$replacement_map_file" || die "Could not open $replacement_map_file to read; terminating =(\n";
while(<REPLACEMENT_MAP>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		# reads in mapped values
		my @items_in_row = split($DELIMITER, $_);
		
		my $current_value = $items_in_row[$CURRENT_VALUE_COLUMN];
		my $new_value = $items_in_row[$NEW_VALUE_COLUMN];
		
		# verifies that we haven't seen the current value before
		if($current_value_to_new_value{$current_value}
			and $current_value_to_new_value{$current_value} ne $new_value)
		{
			print STDERR "Warning: current value ".$current_value." mapped to multiple "
				."new values.\n";
		}
		
		# saves current-new value pair
		if($new_value ne $current_value)
		{
			$current_value_to_new_value{$current_value} = $new_value;
		}
	}
}
close REPLACEMENT_MAP;


# replace values in each file
foreach my $input_file(@input_files)
{
	# opens output file
	my $output_file = $input_file."_replaced.txt";
	if(-e $output_file)
	{
		print STDERR "Warning: output file already exists. Overwriting:\n\t".$output_file."\n";
		die_if_overwrite_not_allowed();
	}
	open OUTPUT_FILE, ">$output_file" || die "Could not open $output_file to write; terminating =(\n";

	# reads in and replaces values in input file
	open INPUT_FILE, "<$input_file" || die "Could not open $input_file to read; terminating =(\n";
	while(<INPUT_FILE>) # for each line in the file
	{
		chomp;
		my $line = $_;
		
		# replaces value in this line
		foreach my $current_value(reverse sort keys %current_value_to_new_value)
		{
			my $new_value = $current_value_to_new_value{$current_value};

			# whitespace-separated
			$line =~ s/^$current_value$/$new_value/g; # full line
			$line =~ s/^$current_value(\s)/$new_value$1/g; # start of line
			$line =~ s/(\s)$current_value$/$1$new_value/g; # end of line
			$line =~ s/(\s)$current_value(\s)/$1$new_value$2/g; # middle of line
			
			# comma-separated
# 			$line =~ s/^$current_value$/$new_value/g; # full line
# 			$line =~ s/^$current_value(,)/$new_value$1/g; # start of line
# 			$line =~ s/(,)$current_value$/$1$new_value/g; # end of line
# 			$line =~ s/(,)$current_value(,)/$1$new_value$2/g; # middle of line
		}
		
		# prints replaced line in output line
		print OUTPUT_FILE $line.$NEWLINE;
	}
	close OUTPUT_FILE;
}


# if overwriting not allowed (if $OVERWRITE is set to 0), prints an error and exits
sub die_if_overwrite_not_allowed
{
	if(!$OVERWRITE)
	{
		print STDERR "Error: exiting to avoid overwriting. Set \$OVERWRITE to 1 to allow "
			."overwriting.\n";
		die;
	}
}


# July 22, 2021
