#!/usr/bin/env perl

# Aligns each input sequence with reference independently, then combines all into one
# fasta alignment. Bases aligned to a gap in the reference are removed.

# Sequences in input fastas must have unique names. Paths of fasta sequences to align can
# be provided directly as arguments or as one file with a list of filepaths, one per line.

# Usage:
# perl align_to_reference.pl [reference sequence]
# [file path of MAFFT executable file (mafft.bat) or mafft command]
# [file with list of fasta file paths, one per line]
# [filepaths of at least fasta files OR path of file containing file with list of fasta
# file paths, one per line]

# Prints to console. To print to file, use
# perl align_to_reference.pl [reference sequence]
# [file path of MAFFT executable file (mafft.bat) or mafft command]
# [filepaths of at least fasta files OR path of file containing file with list of fasta
# file paths, one per line] > [output fasta file path]

# Temp files are created at filepath of old file with "_aligned_to_ref.fasta" appended to
# the end and with "_temp.fasta" appended to the end. Files already at those paths will be
# overwritten.

# Borrows from:
# - align_each_fasta_file_with_reference_separately.pl
# - combine_alignments_to_same_reference.pl
# - split_fasta_one_sequence_per_file.pl


use strict;
use warnings;


my $reference_sequence = $ARGV[0];
my $mafft_file_path_or_command = $ARGV[1];
my $input_fastas_list;
my @input_fastas;
if(scalar @ARGV > 3)
{
	@input_fastas = @ARGV[2..$#ARGV];
}
else
{
	$input_fastas_list = $ARGV[2];
}


my $NEWLINE = "\n";
my $NO_DATA = "NA";

my $TEMP_FILE_EXTENSION = "_temp.fasta";
my $ALIGNMENT_FILE_EXTENSION = "_aligned_to_ref.fasta";
my $OVERWRITE = 1; # set to 0 to prevent overwriting (stop script rather than overwrite)
my $USE_EXISTING_ALIGNMENTS_IF_AVAILABLE = 1;


# verifies that list of input fasta files exists
if((!$input_fastas_list or !-e $input_fastas_list or -z $input_fastas_list)
	and !scalar @input_fastas)
{
	print STDERR "Error: list of input fasta files not provided, does not exist, or "
		."empty. Exiting.\n";
	die;
}


# if needed, reads in list of input fasta files
if($input_fastas_list and !scalar @input_fastas)
{
	open INPUT_FASTAS, "<$input_fastas_list" || die "Could not open $input_fastas_list to read; terminating =(\n";
	while(<INPUT_FASTAS>) # for each line in the file
	{
		chomp;
		if($_ =~ /\S/) # header line
		{
			push(@input_fastas, $_);
		}
	}
	close INPUT_FASTAS;
}
if(!scalar @input_fastas)
{
	print STDERR "Error: list of input fasta files not provided, does not exist, or "
		."empty. Exiting.\n";
	die;
}


# verifies that we have read in a list of input fasta files
if(!scalar @input_fastas)
{
	print STDERR "Error: no input fastas provided. Exiting.\n";
	die;
}


# verifies that input reference fasta exists
if(!$reference_sequence or !-e $reference_sequence or -z $reference_sequence)
{
	print STDERR "Error: input reference fasta not provided, does not exist, or empty:\n\t"
		.$reference_sequence."\n";
	die;
}

# verifies that mafft executable exists or mafft command provided
if(!$mafft_file_path_or_command)
{
	print STDERR "Error: mafft executable not provided:\n\t"
		.$mafft_file_path_or_command."\n";
	die;
}


# splits fasta files containing more than one sequence into one file per sequence
my @input_fastas_one_sequence_per_file = ();
my @temp_files_to_delete_at_end = ();
foreach my $input_fasta(@input_fastas)
{
	if($input_fasta and -e $input_fasta and !-z $input_fasta)
	{
		# counts number sequences in file
		my $number_sequences = 0;
		open FASTA_FILE, "<$input_fasta" || die "Could not open $input_fasta to read; terminating =(\n";
		while(<FASTA_FILE>) # for each line in the file
		{
			if($_ =~ /^>/) # header line
			{
				$number_sequences++;
		
				# to avoid reading large files twice, stops reading once we have verified that
				# we have two sequences
				if($number_sequences >= 2)
				{
					close FASTA_FILE;
					last;
				}
			}
		}
		close FASTA_FILE;
		
		# if only one sequence, saves file as is
		if($number_sequences == 1)
		{
			push(@input_fastas_one_sequence_per_file, $input_fasta)
		}
		
		# if more than one sequence, splits sequences in fasta file into a number of
		# smaller files with one sequence per file
		elsif($number_sequences > 1)
		{
			my %sequence_name_to_number_appearances = (); # key: sequence name -> value: number of times sequence name has been seen
			open FASTA_FILE, "<$input_fasta" || die "Could not open $input_fasta to read; terminating =(\n";
			while(<FASTA_FILE>) # for each line in the file
			{
				chomp;
				my $line = $_;
				if($line =~ /^>(.*)$/) # header line
				{
					# closes current output file
					close OUT_FILE;
		
					# retrieves new sequence name
					my $sequence_name = $1;
		
					# records that we have seen this sequence
					$sequence_name_to_number_appearances{$sequence_name}++;
				
					# verifies that we have not seen this new sequence name before
					if($sequence_name_to_number_appearances{$sequence_name} > 1)
					{
						print STDERR "Warning: sequence name ".$sequence_name." appears more than once. ";
			
						# tries to give sequence a new name
						$sequence_name .= "__name_dup".($sequence_name_to_number_appearances{$sequence_name}-1);
			
						# if new name is also taken, adds to the end of it until it isn't
						while($sequence_name_to_number_appearances{$sequence_name})
						{
							$sequence_name .= "_name_dup";
						}
			
						# records that we have used this name
						$sequence_name_to_number_appearances{$sequence_name}++;
			
						print STDERR "Renaming to ".$sequence_name.".\n";
					}
		
					# opens new output file
					my $current_output_file = $input_fasta."_".make_safe_for_filename($sequence_name).".fasta";
					push(@input_fastas_one_sequence_per_file, $current_output_file);
					push(@temp_files_to_delete_at_end, $current_output_file);
					if(-e $current_output_file)
					{
						print STDERR "Warning: output file already exists. Overwriting:\n\t"
							.$current_output_file."\n";
						if(!$OVERWRITE)
						{
							print STDERR "Error: exiting to avoid overwriting. Set \$OVERWRITE to 1 to allow "
								."overwriting.\n";
							die;
						}
					}
					open OUT_FILE, ">$current_output_file" || die "Could not open $current_output_file to write; terminating =(\n";

				}
				print OUT_FILE $line;
				print OUT_FILE "\n";
			}
			close FASTA_FILE;
			close OUT_FILE;
		}
	}
}


# appends reference to start of each fasta file and aligns
my @alignment_files = ();
foreach my $input_fasta(@input_fastas_one_sequence_per_file)
{
	my $temp_file = $input_fasta.$TEMP_FILE_EXTENSION;
	my $aligned_fasta = $input_fasta.$ALIGNMENT_FILE_EXTENSION;
	
	if($USE_EXISTING_ALIGNMENTS_IF_AVAILABLE and -e $aligned_fasta and !-z $aligned_fasta)
	{
		# saves path of alignment file
		push(@alignment_files, $aligned_fasta);
	}
	else # generate alignment file
	{
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
		
			# saves path of alignment file
			push(@alignment_files, $aligned_fasta);
			push(@temp_files_to_delete_at_end, $aligned_fasta);
		}
	}
}


# verifies that fasta alignment files exist
if(!scalar @alignment_files)
{
	print STDERR "Error: no aligned fasta files generated. Exiting.\n";
	die;
}


# reads in all alignments--saves bases at each position in each sequence, with positions
# defined by reference
my $reference_sequence_printed = 0;
my %reference_sequences_without_gaps = (); # key: reference sequence with gaps removed -> value: 1
foreach my $alignment_file(@alignment_files)
{
	# reads in all alignments
	my %sequence_name_to_sequence = (); # key: name of sequence in this alignment file -> value: sequence
	my $reference_sequence_name = ""; # name of reference sequence (first sequence in file)
	my $current_sequence_name = ""; # name of sequence currently being read in
	my $current_sequence = ""; # sequence currently being read in
	open FASTA_FILE, "<$alignment_file" || die "Could not open $alignment_file to read; terminating =(\n";
	while(<FASTA_FILE>) # for each line in the file
	{
		chomp;
		if($_ =~ /^>(.*)/) # header line
		{
			# saves sequence that was just read in
			if($current_sequence_name and $current_sequence)
			{
				$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
			}
			if(!$reference_sequence_name)
			{
				$reference_sequence_name = $current_sequence_name;
			}
		
			# sets up new current sequence
			$current_sequence_name = $1;
			$current_sequence = "";
		}
		else # sequence (not header line)
		{
			# adds to sequence
			$current_sequence .= uc($_);
		}
	}
	close FASTA_FILE;
	if($current_sequence_name and $current_sequence)
	{
		$sequence_name_to_sequence{$current_sequence_name} = $current_sequence;
	}
	
	
	# retrieves base at each position for each sequence
	my %sequence_name_to_position_to_base = (); # key: sequence name -> key: position (1-indexed) in reference -> value: base at corresponding position in sequence
	my $reference_sequence = $sequence_name_to_sequence{$reference_sequence_name};
	
	foreach my $sequence_name(keys %sequence_name_to_sequence)
	{
		my $sequence = $sequence_name_to_sequence{$sequence_name};
		
		my $position = 0; # 1-indexed relative to reference
		for(my $base_index = 0; $base_index < length($reference_sequence); $base_index++)
		{
			my $reference_base = substr($reference_sequence, $base_index, 1);
			if(is_base($reference_base))
			{
				# increments position only if valid base in reference sequence
				$position++;
	
				# retrieves sequence's base at this position
				if($base_index < length($sequence)) # no sequence at this index; we've gone out of range
				{
					my $base = substr($sequence, $base_index, 1);
					if(is_unambiguous_base($base))
					{
						$sequence_name_to_position_to_base{$sequence_name}{$position} = $base;
					}
				}
			}
		}
	}
	
	
	# saves and prints reference sequence without gaps
	$reference_sequence =~ s/-//g;
	$reference_sequence =~ s/\s//g;
	
	$reference_sequences_without_gaps{$reference_sequence} = 1;
	if(!$reference_sequence_printed)
	{
		print ">".$reference_sequence_name.$NEWLINE;
		print $reference_sequence.$NEWLINE;
		$reference_sequence_printed = 1;
	}
	
	
	# prints each aligned sequence
	for my $sequence_name(sort keys %sequence_name_to_position_to_base) 
	{
		if($sequence_name ne $reference_sequence_name)
		{
			# prints sequence name
			print ">".$sequence_name.$NEWLINE;
			
			# prints sequence
			my $last_position = max(keys %{$sequence_name_to_position_to_base{$sequence_name}});
			for(my $position = 1; $position <= $last_position; $position++)
			{
				if($sequence_name_to_position_to_base{$sequence_name}{$position})
				{
					print $sequence_name_to_position_to_base{$sequence_name}{$position};
				}
				else
				{
					print "-";
				}
			}
			
			# prints dashes until we reach the length of the reference
			for(my $position = $last_position+1; $position <= length($reference_sequence); $position++)
			{
				print "-";
			}
			print $NEWLINE;
		}
	}
}


# verifies that reference sequences without gaps are all identical
if(scalar %reference_sequences_without_gaps > 1)
{
	print STDERR "Error: more than one distinct reference provided.\n";
}


# removes temp files
# foreach my $temp_file(@temp_files_to_delete_at_end)
# {
# 	`rm $temp_file`;
# }


# returns 1 if base is A, T, C, G; returns 0 if not
# input base must be capitalized
sub is_unambiguous_base
{
	my $base = $_[0]; # must be capitalized
	if($base eq "A" or $base eq "T" or $base eq "C" or $base eq "G")
	{
		return 1;
	}
	return 0;
}

# returns 1 if base is not gap, 0 if base is a gap
sub is_base
{
	my $base = $_[0];
	
	# empty value
	if(!$base)
	{
		return 0;
	}
	
	# only whitespace
	if($base !~ /\S/)
	{
		return 0;
	}
	
	# gap
	if($base eq "-")
	{
		return 0;
	}
	
	# base
	return 1;
}

# returns maximum value in input array
sub max
{
	my @values = @_;
	
	# returns if we don't have any input values
	if(scalar @values < 1)
	{
		return $NO_DATA;
	}
	
	# retrieves maximum value
	my $max_value = $values[0];
	foreach my $value(@values)
	{
		if($value > $max_value)
		{
			$max_value = $value;
		}
	}
	return $max_value;
}

# makes string safe for use as a filename
# replaces all whitespace, |s, /s, and \s with underscores
sub make_safe_for_filename
{
	my $string = $_[0];
	
	# replaces all whitespace with _s
	$string =~ s/\s/_/g;
	
	# replaces all |s with _s
	$string =~ s/\|/_/g;
	
	# replaces all /s with _s
	$string =~ s/\//_/g;
	
	# replaces all \s with _s
	$string =~ s/\\/_/g;
	
	# replaces all ; with _s
	$string =~ s/;/_/g;
	
	# replaces all : with _s
	$string =~ s/:/_/g;
	
	# replaces all , with _s
	$string =~ s/,/_/g;
	
	# replaces all ! with _s
	$string =~ s/[!]/_/g;
	
	return $string;
}


# March 11, 2022
# March 15, 2022
# March 16, 2022
