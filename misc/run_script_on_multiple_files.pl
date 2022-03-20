#!/usr/bin/env perl

# Runs script individually on multiple input files, otherwise using the same input
# parameters. Script must accept input file as first parameter.

# Usage:
# perl run_script_on_multiple_files.pl [file path of script to run]
# [file with list of input files to run script on]
# [optional extension to add to input file path to create output file path]
# [optional second parameter to provide script]
# [optional third parameter to provide script] [etc.]


my $script = $ARGV[0]; # file path of script to run
my $list_of_input_files = $ARGV[1]; # file containing list of input files to run script on, one per line
my $output_file_extension = $ARGV[2]; # optional extension to add to input file path to create output file path
my @additional_parameters = @ARGV[3..$#ARGV]; # optional additional parameters to provide script


my $OVERWRITE = 0; # set to 0 to prevent overwriting (stop script rather than overwrite)


# verifies that input files are provided, exist, and are not empty
if(!$script or !-e $script or -z $script)
{
	print STDERR "Error: input script not provided, does not exist, or is empty. "
		."Exiting.\n";
	die;
}
if(!$list_of_input_files or !-e $list_of_input_files or -z $list_of_input_files)
{
	print STDERR "Error: list of input files not provided, does not exist, or is empty. "
		."Exiting.\n";
	die;
}


# prepares additional parameters
my $additional_parameters_string = "";
foreach my $additional_parameter(@additional_parameters)
{
	if($additional_parameters_string)
	{
		$additional_parameters_string .= " ";
	}
	$additional_parameters_string .= "\"".$additional_parameter."\"";
}


# runs script on each input file
open INPUT_FILES_LIST, "<$list_of_input_files" || die "Could not open $list_of_input_files to read; terminating =(\n";
while(<INPUT_FILES_LIST>) # for each line in the file
{
	chomp;
	if($_ =~ /\S/)
	{
		# retrieves input file
		my $input_file = $_;
		
		# prepares output file
		my $output_file = $input_file.$output_file_extension;
		if($output_file_extension and !$OVERWRITE and -e $output_file)
		{
			print STDERR "Error: exiting to avoid overwriting. Set \$OVERWRITE to 1 to allow "
				."overwriting.\n";
			die;
		}
		
		# runs script on input file
		if($additional_parameters_string and $output_file_extension)
		{
			# additional parameters and output file
			`perl $script $input_file $additional_parameters_string > $output_file`;
		}
		elsif($additional_parameters_string)
		{
			# no output file
			`perl $script $input_file $additional_parameters_string`;
		}
		elsif($output_file_extension)
		{
			# no additional parameters
			`perl $script $input_file > $output_file`;
		}
		else
		{
			# no additional parameters and no output file
			`perl $script $input_file`;
		}
	}
}
close INPUT_FILES_LIST;


# March 20, 2022
