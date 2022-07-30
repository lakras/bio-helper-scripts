#!/usr/bin/env perl

# Annotates positions in input table with the names of the region(s) they are in. Adds
# column containing names of regions the position overlaps. If multiple regions overlap a
# position they are comma-separated in the new column.

# Start and end positions in regions table are assumed to be 1-indexed with inclusive end;
# see code to modify hardcoded variable to change. Positions in positions table to
# annotate are assumed to be 1-indexed; see code to modify hardcoded variable to change.

# Positions in positions table and regions must be relative to the same reference
# sequence.

# Usage:
# perl annotate_positions_with_regions_they_overlap.pl
# [table containing positions to annotate]
# "[title of column containing positions to annotate]"
# [table containing start and end positions and names of regions]
# [optional output column title (overlapping_regions by default)]

# Prints to console. To print to file, use
# perl annotate_positions_with_regions_they_overlap.pl
# [table containing positions to annotate]
# "[title of column containing positions to annotate]"
# [table containing start and end positions and names of regions]
# [optional output column title (overlapping_regions by default)] > [output table path]


use strict;
use warnings;


my $positions_table = $ARGV[0]; # table containing positions to annotate
my $position_column_title = $ARGV[1]; # title of column containing positions to annotate
my $regions_table = $ARGV[2]; # table containing start and end positions and names of regions; columns: reference sequence name, first position, end position, name of region
my $output_column_title = $ARGV[3]; # optional output column title; overlapping_regions by default


# in regions table (column indices are 0-indexed):
my $REGION_START_POSITION_COLUMN = 1;
my $REGION_END_POSITION_COLUMN = 2;
my $REGION_NAME_COLUMN = 3;

my $REGIONS_1_INDEXED = 1; # 1 if regions start and end are 1-indexed, 0 if regions start and end are 0-indexed
my $REGIONS_INCLUSIVE_END = 1; # 1 if regions have inclusive end, 0 if regions have non-inclusive end

# in positions and output table
my $DELIMITER = "\t";
my $NEWLINE = "\n";

my $POSITION_1_INDEXED = 1; # 1 if positions in position table are 1-indexed, 0 if positions are 0-indexed

# in output file
my $DEFAULT_OVERLAPPING_REGION_NAMES_OUTPUT_COLUMN = "overlapping_regions";
my $MULTIPLE_OVERLAPPING_REGION_NAMES_DELIMITER = ", ";
my $MULTIPLE_OVERLAPPING_REGIONS_EACH_IN_OWN_DUPLICATE_LINE = 0; # if 1, duplicates the line for any position with multiple overlapping regions, listing one overlapping region in each line


# sets output column title if not provided
if(!$output_column_title)
{
	$output_column_title = $DEFAULT_OVERLAPPING_REGION_NAMES_OUTPUT_COLUMN;
}

# verifies that input files exist and are non-empty
if(!$positions_table)
{
	print STDERR "Error: no positions table provided. Exiting.\n";
	die;
}
if(!-e $positions_table)
{
	print STDERR "Error: input positions table does not exist:\n\t".$positions_table
		."\nExiting.\n";
	die;
}
if(-z $positions_table)
{
	print STDERR "Error: input positions table is empty:\n\t".$positions_table
		."\nExiting.\n";
	die;
}
if(!$regions_table)
{
	print STDERR "Error: no regions table provided. Exiting.\n";
	die;
}
if(!-e $regions_table)
{
	print STDERR "Error: input regions table does not exist:\n\t".$regions_table
		."\nExiting.\n";
	die;
}
if(-z $regions_table)
{
	print STDERR "Error: input regions table is empty:\n\t".$regions_table
		."\nExiting.\n";
	die;
}


# reads in table with start and end positions of regions
# if needed, converts to 1-indexed, inclusive end position
my %region_name_to_start = (); # key: name of region -> value: start position of region; 1-indexed
my %region_name_to_end = (); # key: name of region -> value: end position of region; 1-indexed inclusive
open REGIONS_TABLE, "<$regions_table" || die "Could not open $regions_table to read; terminating =(\n";
while(<REGIONS_TABLE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # non-empty line
	{
		# retrieves sequence name and start and end
		my @values = split($DELIMITER, $line);
		my $start = $values[$REGION_START_POSITION_COLUMN];
		my $end = $values[$REGION_END_POSITION_COLUMN];
		my $region_name = $values[$REGION_NAME_COLUMN];
		
		# modifies indexing if needed
		if(!$REGIONS_1_INDEXED)
		{
			# region starts and ends are 0-indexed
			# add 1 to start and end positions to make them 1-indexed
			$start = $start + 1;
			$end = $end + 1;
		}
		if(!$REGIONS_INCLUSIVE_END)
		{
			# region end positions are non-inclusive
			# subtract 1 from end position
			$end = $end - 1;
		}
		
		# saves start and end positions
		$region_name_to_start{$region_name} = $start;
		$region_name_to_end{$region_name} = $end;
	}
}
close REGIONS_TABLE;


# reads in table with positions to annotate
# adds column containing names of regions the position overlaps
# if multiple regions overlap a position they are comma-separated in the new column
open POSITIONS_TABLE, "<$positions_table" || die "Could not open $positions_table to read; terminating =(\n";
my $first_line = 1;
my $position_column = -1;
while(<POSITIONS_TABLE>) # for each line in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		if($first_line) # column titles
		{
			# identifies positions column
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $position_column_title)
				{
					if($position_column != -1)
					{
						print STDERR "Error: title of positions column "
							.$position_column_title." appears more than once in positions"
							." table:\n\t".$positions_table."\nExiting.\n";
						die;
					}
					$position_column = $column;
				}
				$column++;
			}
			
			# verifies that we have found positions column
			if($position_column == -1)
			{
				print STDERR "Error: could not find title of positions column "
					.$position_column_title." in positions table:\n\t"
					.$positions_table."\nExiting.\n";
				die;
			}
			
			# prints header line with additional overlapping regions column title
			print $line.$DELIMITER.$output_column_title.$NEWLINE;
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# retrieves sequence name and start and end
			my @values = split($DELIMITER, $line);
			my $position = $values[$position_column];
		
			# modifies indexing if needed
			if(!$POSITION_1_INDEXED)
			{
				# position is 0-indexed
				# add 1 to position to make it 1-indexed
				$position = $position + 1;
			}
			
			# determines what regions the position overlaps
			my @overlapping_region_names = ();
			foreach my $region_name(sort keys %region_name_to_start)
			{
				my $region_start = $region_name_to_start{$region_name};
				my $region_end = $region_name_to_end{$region_name};
				
				if($position >= $region_start and $position <= $region_end)
				{
					push(@overlapping_region_names, $region_name);
				}
			}
			
			if($MULTIPLE_OVERLAPPING_REGIONS_EACH_IN_OWN_DUPLICATE_LINE)
			{
				foreach my $overlapping_region_name(@overlapping_region_names)
				{
					print $line.$DELIMITER.$overlapping_region_name.$NEWLINE;
				}
			}
			else
			{
				# prints line as is with additional overlapping region(s) column
				print $line.$DELIMITER;
				print join($MULTIPLE_OVERLAPPING_REGION_NAMES_DELIMITER, @overlapping_region_names);
				print $NEWLINE;
			}
		}
	}
}
close POSITIONS_TABLE;


# July 30, 2022
