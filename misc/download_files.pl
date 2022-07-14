#!/usr/bin/env perl

# Downloads files listed in input file from online or from google storage bucket to
# new directory. If output directory is not provided, directory set to input file path
# sans extension.

# If multiple files to download have the same name, adds "_dup" to the end of the
# downloaded file path to prevent overwriting.

# Usage:
# perl download_files.pl [file with list of files to download] [optional output directory]


use strict;
use warnings;


my $files_to_download = $ARGV[0]; # file containing list of files to download, one per line
my $output_directory = $ARGV[1]; # optional directory to download to--if not provided, output directory identical to input file path sans file extension


my $OVERWRITE = 0; # set to 0 to prevent overwriting (stop script rather than overwrite)


# generates directory to contain downloaded files
if(!$output_directory) # no output directory provided
{
	if($files_to_download =~ /^(.*\/.*)[.].+$/)
	{
		$output_directory = $1;
	}
	else
	{
		print STDERR "Error: could not generate output directory for input file path\n\t"
			.$files_to_download."\nExiting.\n";
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


# generates script to download files
my $output_script = $files_to_download."_download.pl";
if(-e $output_script)
{
	print STDERR "Warning: output script already exists. Overwriting:\n\t"
		.$output_script."\n";
# 	die_if_overwrite_not_allowed();
}
my %used_output_file_paths = (); # key: output file path -> 1 if it's already been claimed
open OUT_SCRIPT, ">$output_script" || die "Could not open $output_script to write; terminating =(\n";
open FILES_TO_DOWNLOAD, "<$files_to_download" || die "Could not open $files_to_download to read; terminating =(\n";
while(<FILES_TO_DOWNLOAD>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		# retrieves file name from file path, to build output file path
		my $file_to_download = $_;
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
close FILES_TO_DOWNLOAD;
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
