#!/usr/bin/env perl

# Summarizes sequences in fasta file (number bases, number unambiguous bases, A+T,
# C+G, Ns, gaps, As, Ts, Cs, Gs, other bases).

# Usage:
# perl summarize_fasta_sequences.pl [fasta file path] [another fasta file path] [etc.]

# Output columns:
# - sequence_name
# - bases (number bases appearing in sequence; includes all characters that are not gaps or whitespace)
# - unambiguous_bases (number unambigous bases: A, T, C, or G)
# - A+T (number As + number Ts)
# - G+C (number Gs + number Cs)
# - N (number Ns)
# - - (number gaps)
# - A (number As)
# - T
# - C
# - G
# - additional columns for any other bases appearing in any sequence

# Prints to console. To print to file, use
# perl summarize_fasta_sequences.pl [fasta file path] [another fasta file path] [etc.]
# > [output file path]


use strict;
use warnings;


my @fasta_files = @ARGV; # sequence names may not appear more than once across all files


# characters whose frequencies we should print first (in order)
my @PRIVILEGED_CHARACTERS = ("N", "-", "A", "T", "C", "G"); # must be all capitalized

# for printing
my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that fasta file exists and is non-empty
if(!scalar @fasta_files)
{
	print STDERR "Error: no input fasta files provided. Exiting.\n";
	die;
}
foreach my $fasta_file(@fasta_files)
{
	if(!-e $fasta_file)
	{
		print STDERR "Error: input fasta file does not exist:\n\t".$fasta_file."\nExiting.\n";
		die;
	}
	if(-z $fasta_file)
	{
		print STDERR "Warning: input fasta file is empty:\n\t".$fasta_file."\n";
	}
}


# generates hash of privileged characters for faster use
my %character_is_privileged = (); # key: character -> value: 1 if we should print it first
foreach my $character(@PRIVILEGED_CHARACTERS)
{
	$character_is_privileged{$character} = 1;
}


# values to catalogue:
my %character_to_number_appearances = (); # key: sequence name -> key: character (A, T, C, G, N, -, etc.) -> value: number of times it appears in the sequence
my %character_appears_in_sequences = (); # key: character appearing in a sequence -> value: 1
my %sequence_name_to_length = (); # key: sequence name -> value: total number bases (characters not - or whitespace)
my %sequence_name_to_unambiguous_length = (); # key: sequence name -> value: total number unambiguous bases (A, T, C, or G)
my @sequence_names = (); # all sequence names appearing in fasta file, in the order in which they appear
my %sequence_name_to_number_appearances = (); # key: sequence name -> value: number of times sequence name has been seen

# reads in fasta file and catalogues characters appearing in each sequence
foreach my $fasta_file(@fasta_files)
{
	open FASTA_FILE, "<$fasta_file" || die "Could not open $fasta_file to read; terminating =(\n";
	my $sequence = ""; # sequence currently being read in
	my $sequence_name = ""; # name of sequence currently being read in
	while(<FASTA_FILE>) # for each line in the file
	{
		chomp;
		if($_ =~ /^>(.*)/) # header line
		{
			# process previous sequence
			catalogue_characters_in_sequence($sequence_name, $sequence);

			# prepare for next sequence
			$sequence = "";
			$sequence_name = $1;
		
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
		
			# saves sequence name in order it should appear in the output table
			push(@sequence_names, $sequence_name);
		}
		else
		{
			$sequence .= $_;
		}
	}
	# process final sequence
	catalogue_characters_in_sequence($sequence_name, $sequence);
	close FASTA_FILE;
}


# prints header line of output table: most important characters, in order, then all others
print "sequence_name".$DELIMITER;
print "bases".$DELIMITER;
print "unambiguous_bases".$DELIMITER;
print "A+T".$DELIMITER;
print "G+C";
foreach my $character(@PRIVILEGED_CHARACTERS) # for all privileged characters (A, T, C, G, N, -)
{
	print $DELIMITER.$character;
}
foreach my $character(sort keys %character_appears_in_sequences) # for every character that appears in any sequence
{
	if(!$character_is_privileged{$character}) # non-privileged characters only (since we already printed privileged characters)
	{
		print $DELIMITER.$character;
	}
}
print $NEWLINE;

# prints output table of counts for each character appearing in sequences
foreach my $sequence_name(@sequence_names) # for every sequence name, in the order in which it appeared in the input fasta file
{
	print $sequence_name.$DELIMITER;
	print prepare_value_to_print($sequence_name_to_length{$sequence_name}).$DELIMITER;
	print prepare_value_to_print($sequence_name_to_unambiguous_length{$sequence_name}).$DELIMITER;
	print prepare_value_to_print(retrieve_value_or_0($character_to_number_appearances{$sequence_name}{"A"}) + retrieve_value_or_0($character_to_number_appearances{$sequence_name}{"T"})).$DELIMITER;
	print prepare_value_to_print(retrieve_value_or_0($character_to_number_appearances{$sequence_name}{"G"}) + retrieve_value_or_0($character_to_number_appearances{$sequence_name}{"C"}));
	foreach my $character(@PRIVILEGED_CHARACTERS) # for all privileged characters (A, T, C, G, N, -)
	{
		print $DELIMITER.prepare_value_to_print($character_to_number_appearances{$sequence_name}{$character});
	}
	foreach my $character(sort keys %character_appears_in_sequences) # for every character that appears in any sequence
	{
		if(!$character_is_privileged{$character}) # non-privileged characters only (since we already printed privileged characters)
		{
			print $DELIMITER.prepare_value_to_print($character_to_number_appearances{$sequence_name}{$character});
		}
	}
	print $NEWLINE;
}


# prints number of times each character appearing in sequence
sub catalogue_characters_in_sequence
{
	my $sequence_name = $_[0];
	my $sequence = $_[1];
	
	# do nothing if either sequence name or sequence is empty
	if(!$sequence or !$sequence_name)
	{
		return;
	}
	
	# capitalize sequence
	$sequence = uc($sequence);
	
	# catalogue appearance of each character in this sequence and updates counts
	foreach my $character(split //, $sequence)
	{
		# updates number of times this character appears in this sequence
		$character_to_number_appearances{$sequence_name}{$character}++;
		
		# records that we have seen this character in any sequence
		$character_appears_in_sequences{$character} = 1;
		
		# updates this sequence's length if character is not - or whitespace
		if($character ne "-" and $character =~ /^\S+$/)
		{
			$sequence_name_to_length{$sequence_name}++;
		}
		
		# updates this sequence's unambiguous length if character is A, T, C, or G
		if($character eq "A" or $character eq "T" or $character eq "C" or $character eq "G")
		{
			$sequence_name_to_unambiguous_length{$sequence_name}++;
		}
	}
}

# turns 0s into strings to ensure they are printed
sub prepare_value_to_print
{
	my $value = $_[0];
	
	if($value)
	{
		return $value;
	}
	return "0";
}

# returns value if it exists, 0 if not
sub retrieve_value_or_0
{
	my $value = $_[0];
	
	if($value)
	{
		return $value;
	}
	return 0;
}


# July 12, 2021
