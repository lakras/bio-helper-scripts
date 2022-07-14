#!/usr/bin/env perl

# Downloads files from addresses listed in specified table column in input table.
# Downloads files from online or from google storage bucket to new directory.
# If no output directory provided, output directory set to input file path sans extension
# followed by column name.

# If multiple files to download have the same name, adds "_dup" to the end of the
# downloaded file path to prevent overwriting.

# Usage:
# perl download_files_listed_in_table_column.pl
# [table with list of files to download in one of the columns]
# [title of column containing filepaths to download] [optional output directory]


use strict;
use warnings;


my $table_with_files_to_download = $ARGV[0]; # file containing files to download in one of the columns
my $title_of_column_with_filepaths = $ARGV[1]; # title of column containing filepaths to download
my $output_directory = $ARGV[2]; # optional directory to download to--if not provided, output directory identical to input file path sans file extension


my $NEWLINE = "\n";
my $DELIMITER = "\t";

my $OVERWRITE = 0; # set to 0 to prevent overwriting (stop script rather than overwrite)


# replaces spaces with underscores in column title for output file path
my $column_title_for_filepath = $title_of_column_with_filepaths;
$column_title_for_filepath =~ s/ /_/g;

# generates directory to contain downloaded files
if(!$output_directory) # no output directory provided
{
	if($table_with_files_to_download =~ /^(.*\/.*)[.].+$/)
	{
		$output_directory = $1."__".$column_title_for_filepath;
	}
	else
	{
		print STDERR "Error: could not generate output directory for input file path\n\t"
			.$table_with_files_to_download."\nExiting.\n";
		die;
	}
}
else # output directory provided
{
	# strips trailing /
	if($output_directory =~ /^(.*)\/$/)
	{
		$output_directory = $1;
	}
}


# creates output directory if it does not already exist
if(!-e $output_directory)
{
	`mkdir $output_directory`;
}
else
{
	print STDERR "Warning: output directory already exists:\n\t".$output_directory."\n";
}


# reads in and processes input table; generates script to download files
my $output_script = $table_with_files_to_download."_".$column_title_for_filepath."_download.pl";
if(-e $output_script)
{
	print STDERR "Warning: output script already exists. Overwriting:\n\t"
		.$output_script."\n";
# 	die_if_overwrite_not_allowed();
}
my %used_output_file_paths = (); # key: output file path -> 1 if it's already been claimed
open OUT_SCRIPT, ">$output_script" || die "Could not open $output_script to write; terminating =(\n";

my $first_line = 1;
my $column_with_filepaths = -1;
open INPUT_TABLE, "<$table_with_files_to_download" || die "Could not open $table_with_files_to_download to read; terminating =(\n";
while(<INPUT_TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	if($line =~ /\S/) # if row not empty
	{
		my @items_in_line = split($DELIMITER, $line, -1);
		if($first_line) # column titles
		{
			# identifies column with filepaths
			my $column = 0;
			foreach my $column_title(@items_in_line)
			{
				if(defined $column_title and $column_title eq $title_of_column_with_filepaths)
				{
					if($column_with_filepaths != -1)
					{
						print STDERR "Error: title of column with filepaths "
							.$title_of_column_with_filepaths." appears more than once in table:"
							."\n\t".$table_with_files_to_download."\nExiting.\n";
						die;
					}
					$column_with_filepaths = $column;
				}
				$column++;
			}
			
			# verifies that we have found column with filepaths
			if($column_with_filepaths == -1)
			{
				print STDERR "Error: could not find title of column with filepaths "
					.$title_of_column_with_filepaths." in table:\n\t"
					.$table_with_files_to_download."\nExiting.\n";
				die;
			}
			
			$first_line = 0; # next line is not column titles
		}
		else # column values (not column titles)
		{
			# retrieves file name from file path, to build output file path
			my $file_to_download = $items_in_line[$column_with_filepaths];
			my $file_name = $file_to_download;
			if($file_name  =~ /\/([^\/]+)$/)
			{
				$file_name = $1;
			}
		
			# adds to name of output file if it already exists
			my $output_file_path = $output_directory."/".$file_name;
			my $file_renamed = 0;
			while($used_output_file_paths{$output_file_path})
			{
				$output_file_path .= "_dup";
				$file_renamed = 1;
			}
			if($file_renamed)
			{
				print STDERR "Warning: output file $file_name claimed. Renaming to:\n\t".
					$output_file_path."\n";
			}
			if(-e $output_file_path)
			{
				print STDERR "Warning: output file path already exists. Overwriting:\n\t"
					.$output_file_path."\n";
	# 			die_if_overwrite_not_allowed();
			}
			else
			{
				# determines if file is on GCP or elsewhere
				my $gcp = 0;
				if($file_to_download =~ /^gs:\/\//) # if file path starts with gs://, it is a GCP file
				{
					$gcp = 1;
				}
		
				# adds line to download script
				if($gcp)
				{
					print OUT_SCRIPT "`gsutil -m cp ".$file_to_download." ".$output_file_path."`;\n";
				}
				else
				{
					print OUT_SCRIPT "`curl ".$file_to_download." > ".$output_file_path."`;\n";
				}
				$used_output_file_paths{$output_file_path} = 1;
			}
		}
	}
}
close INPUT_TABLE;
close OUT_SCRIPT;


# runs script to download files
`perl $output_script`;


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


# April 13, 2021
# July 14, 2021
# July 14, 2022
