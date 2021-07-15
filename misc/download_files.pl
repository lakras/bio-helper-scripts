#!/usr/bin/env perl

# Downloads files listed in input file from online or from google storage bucket to
# new directory. If output directory is not provided, directory set to input file path
# sans extension.

# If multiple files to download have the same name, adds "_dup" to the end of the
# downloaded file path to prevent overwriting.

# Usage:
# perl download_files.pl [file with list of files to download] [1 to download from GCP, 0 or blank otherwise] [optional output directory]


my $files_to_download = $ARGV[0]; # file containing list of files to download, one per line
my $GCP = $ARGV[1]; # set to 1 to download a file from a google storage bucket: if 0, downloads using curl; if 1, downloads using gsutil -m cp
my $output_directory = $ARGV[2]; # optional directory to download to--if not provided, output directory identical to input file path sans file extension


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
			print STDERR "Warning: output file $file_name already exists. Renaming to:\n\t".
				$output_file_path."\n";
		}
		
		# adds line to download script
		if($GCP)
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
close FILES_TO_DOWNLOAD;
close OUT_SCRIPT;


# runs script to download files
`perl $output_script`;


# April 13, 2021
# July 14, 2021
