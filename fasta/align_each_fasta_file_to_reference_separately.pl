#!/usr/bin/env perl

# Adds reference sequence to the top of each fasta file and aligns each file separately.

# Usage:
# perl align_each_fasta_file_to_reference_separately.pl [reference sequence]
# [file path of MAFFT executable file (mafft.bat) or mafft command] [fasta file path]
# [another fasta file path] [another fasta file path] [etc.]

# New files are created at filepath of old file with "_aligned_to_ref.fasta" appended to
# the end. Temp files created with "_temp.fasta" appended to the end. Files already at
# those paths will be overwritten.


use strict;
use warnings;


my $reference_sequence = $ARGV[0];
my $mafft_file_path_or_command = $ARGV[1];
my @input_fastas = @ARGV[2..$#ARGV];


my $TEMP_FILE_EXTENSION = "_temp.fasta";
my $OUTPUT_FILE_EXTENSION = "_aligned_to_ref.fasta";
my $OVERWRITE = 1; # set to 0 to prevent overwriting (stop script rather than overwrite)


# verifies that input reference fasta exists
if(!$reference_sequence or !-e $reference_sequence or -z $reference_sequence)
{
	print STDERR "Error: input reference fasta not provided, does not exist, or empty:\n\t"
		.$reference_sequence."\n";
	next;
}

# verifies that mafft executable exists or mafft command provided
if(!$mafft_file_path_or_command)
{
	print STDERR "Error: mafft executable or command not provided:\n\t"
		.$mafft_file_path_or_command."\n";
	next;
}


# appends reference to start of each fasta file and aligns
foreach my $input_fasta(@input_fastas)
{
	my $temp_file = $input_fasta.$TEMP_FILE_EXTENSION;
	my $aligned_fasta = $input_fasta.$OUTPUT_FILE_EXTENSION;
	
	# verifies that we are not overwriting temp file or output file
	if(!$OVERWRITE and (-e $temp_file or -e $aligned_fasta))
	{
		print STDERR "Error: exiting to avoid overwriting. Set \$OVERWRITE to 1 to allow "
			."overwriting.\n";
		die;
	}
	
	# verifies that input fasta exists and is not empty
	if(!$input_fasta or !-e $input_fasta or -z $input_fasta)
	{
		print STDERR "Error: input fasta not provided, does not exist, or empty:\n\t"
			.$input_fasta."\n";
		next;
	}
	else
	{
		# adds reference sequence to fasta file
		`cat $reference_sequence $input_fasta > $temp_file`;

		# aligns
		`$mafft_file_path_or_command $temp_file > $aligned_fasta`;

		# removes temp file
		`rm $temp_file`;
	}
}


# March 11, 2022
# March 15, 2022
