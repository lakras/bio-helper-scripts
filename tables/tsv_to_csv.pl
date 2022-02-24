#!/usr/bin/env perl

# Converts tab-separated tsv table to comma-separated csv table.

# Usage:
# perl tsv_to_csv.pl [table]

# Prints to console. To print to file, use
# perl tsv_to_csv.pl [table] > [output table path]


use strict;
use warnings;


my $table = $ARGV[0];


my $NEWLINE = "\n";
my $PREVIOUS_DELIMITER = "\t";
my $NEW_DELIMITER = ",";
my $ESCAPE_QUOTATIONS_CHARACTER = "\"";

my @RESERVED_CHARACTER_OPTIONS = (
	"¤", "¶", "§", "Ç", "ü", "é", "â", "ä", "à", "å", "ç", "ê", "ë", "è", "ï", "î", "ì",
	"æ", "Æ", "ô", "ö", "ò", "û", "ù", "ÿ", "¢", "£", "¥", "ƒ", "á", "í", "ó", "ú", "ñ",
	"Ñ", "‡", "‡", "¿", "¬", "½", "¼", "¡", "«", "»", "¦", "ß", "µ", "±", "°", "•", "·",
	"²", "€", "„", "…", "†", "‡", "ˆ", "‰", "Š", "‹", "Œ", "‘", "’", "“", "”", "–", "—",
	"˜", "™", "š", "›", "œ", "Ÿ", "¨", "Character	Sequence", "©", "®", "¯", "³", "´",
	"¸", "¹", "¾", "À", "Á", "Â", "Ã", "Ä", "Å", "È", "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï",
	"Ð", "Ò", "Ó", "Ô", "Õ", "Ö", "×", "Ø", "Ù", "Ú", "Û", "Ü", "Ý", "Þ", "ã", "ð", "õ",
	"÷", "ø", "ü", "ý", "þ","←", "↑", "→", "↓", "↔", "↕", "↖", "↗", "↘", "↙", "↚", "↛",
	"↜", "↝", "↞", "↟", "↠", "↡", "↢", "↣", "↤", "↥", "↦", "↧", "↨", "↩", "↪", "↫", "↬",
	"↭", "↮", "↯", "↰", "↱", "↲", "↳", "↴", "↵", "↶", "↷", "↸", "↹", "↺", "↻", "↼", "↽",
	"↾", "↿", "⇀", "⇁", "⇂", "⇃", "⇄", "⇅", "⇆", "⇇", "⇈", "⇉", "⇊", "⇋", "⇌", "⇍", "⇎",
	"⇏", "⇐", "⇑", "⇒", "⇓", "⇔", "⇕", "⇖", "⇗", "⇘", "⇙", "⇚", "⇛", "⇜", "⇝", "⇞", "⇟",
	"⇠", "⇡", "⇢", "⇣", "⇤", "⇥", "⇦", "⇧", "⇨", "⇩", "⇪", "⇫", "⇬", "⇭", "⇮", "⇯", "⇰",
	"⇱", "⇲", "⇳", "⇴", "⇵", "⇶", "⇷", "⇸", "⇹", "⇺", "⇻", "⇼", "⇽", "⇾", "⇿"
);


# verifies that input file exists and is not empty
if(!$table or !-e $table or -z $table)
{
	print STDERR "Error: table not provided, does not exist, or empty:\n\t"
		.$table."\nExiting.\n";
	die;
}


# reads in and processes input table
open TABLE, "<$table" || die "Could not open $table to read; terminating =(\n";
while(<TABLE>) # for each row in the file
{
	chomp;
	my $line = $_;
	
	# selects reserved character or character set
	my $reserved_character = generate_character_not_in_input_string($line);
	if($line =~ /$reserved_character/)
	{
		print STDERR "Error: line contains selected reserved character "
			.$reserved_character."\n";
		die;
	}
	
	# replaces all tabs within quotes with reserved character, in large groups of 8 first
	while($line =~ /$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$ESCAPE_QUOTATIONS_CHARACTER/)
	{
		$line =~ s/$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$ESCAPE_QUOTATIONS_CHARACTER/$ESCAPE_QUOTATIONS_CHARACTER$1$reserved_character$2$reserved_character$3$reserved_character$4$reserved_character$5$reserved_character$6$reserved_character$7$reserved_character$8$reserved_character$9$ESCAPE_QUOTATIONS_CHARACTER/g;
	}
	
	# replaces all tabs within quotes with reserved character, in groups of 5
	while($line =~ /$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$ESCAPE_QUOTATIONS_CHARACTER/)
	{
		$line =~ s/$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$ESCAPE_QUOTATIONS_CHARACTER/$ESCAPE_QUOTATIONS_CHARACTER$1$reserved_character$2$reserved_character$3$reserved_character$4$reserved_character$5$reserved_character$6$ESCAPE_QUOTATIONS_CHARACTER/g;
	}
	
	# replaces all tabs within quotes with reserved character in groups of 2
	while($line =~ /$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$ESCAPE_QUOTATIONS_CHARACTER/)
	{
		$line =~ s/$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)$PREVIOUS_DELIMITER(.*)$ESCAPE_QUOTATIONS_CHARACTER/$ESCAPE_QUOTATIONS_CHARACTER$1$reserved_character$2$reserved_character$3$ESCAPE_QUOTATIONS_CHARACTER/g;
	}
	
	# replaces all remaining tabs within quotes with reserved character
	while($line =~ /$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)$ESCAPE_QUOTATIONS_CHARACTER/)
	{
		$line =~ s/$ESCAPE_QUOTATIONS_CHARACTER(.*)$PREVIOUS_DELIMITER(.*)"/"$1$reserved_character$2$ESCAPE_QUOTATIONS_CHARACTER/g;
	}
	
	# replaces all tabs with commas
	$line =~ s/$PREVIOUS_DELIMITER/$NEW_DELIMITER/g;
	
	# replaces reserved character with commas
	$line =~ s/$reserved_character/$PREVIOUS_DELIMITER/g;
	
	# deletes all quotes
	$line =~ s/$ESCAPE_QUOTATIONS_CHARACTER//g;
	
	# prints resulting line
	print $line;
	print $NEWLINE;
}
close TABLE;


# generates string of characters not found in input string
sub generate_character_not_in_input_string
{
	my $input_string = $_[0];
	foreach my $reserved_character_option(@RESERVED_CHARACTER_OPTIONS)
	{
		if($input_string !~ /$reserved_character_option/)
		{
			return $reserved_character_option;
		}
	}
	return 0; # didn't find a character not in input string
}


# February 23, 2022
