#!/usr/bin/env perl

# Downloads files listed in input file from google storage bucket to new directory.
# If directory is not provided, directory set to input file path sans extension.

# Usage:
# perl download_files_GCP.pl [file with list of files to download] [optional output directory]


my $files_to_download = $ARGV[0]; # file containing list of files to download, one per line
my $output_directory = $ARGV[1]; # optional directory to download to--if not provided, output directory identical to input file path sans file extension


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
}
open OUT_SCRIPT, ">$output_script" || die "Could not open $output_script to write; terminating =(\n";
open FILES_TO_DOWNLOAD, "<$files_to_download" || die "Could not open $files_to_download to read; terminating =(\n";
while(<FILES_TO_DOWNLOAD>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		my $file_to_download = $_;
		print OUT_SCRIPT "`gsutil -m cp ".$file_to_download." ".$output_directory."/.`;\n";
	}
}
close FILES_TO_DOWNLOAD;
close OUT_SCRIPT;


# runs script to download files
`perl $output_script`;


# April 13, 2021
# July 14, 2021
