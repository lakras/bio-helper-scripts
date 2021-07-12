# bio-helper-scripts
Helper scripts for processing genomic sequence data.

Includes the following scripts—

## FASTA file processing ([`fasta`](/fasta))
- [`retrieve_sequences_by_name.pl`](/fasta/retrieve_sequences_by_name.pl): Retrieves query sequences by name from fasta file.

   _Usage: `perl retrieve_sequences_by_name.pl [fasta file path] [query sequence name 1] [query sequence name 2] [etc.] > [output fasta file path]`_
   
- [`summarize_fasta_sequences.pl`](/fasta/summarize_fasta_sequences.pl): Summarizes sequences in fasta file. Produces table with, for each sequence: number bases, number unambiguous bases, A+T count, C+G count, number Ns, number gaps, number As, number Ts, number Cs, number Gs, and counts for any other [bases](https://en.wikipedia.org/wiki/Nucleic_acid_notation) that appear.

   _Usage: `perl summarize_fasta_sequences.pl [fasta file path] > [output table file path]`_

- [`split_fasta_into_n_files.pl`](/fasta/split_fasta_into_n_files.pl): Splits fasta file with multiple sequences up into a number of smaller files, each with about the same number of sequences.

   _Usage: `perl split_fasta_into_n_files.pl [fasta file path]  [number output files to generate]`_
   
- [`split_fasta_n_sequences_per_file.pl`](/fasta/split_fasta_n_sequences_per_file.pl): Splits fasta file with multiple sequences up into multiple files, with a set number of sequences per file.

   _Usage: `perl split_fasta_n_sequences_per_file.pl [fasta file path]  [number sequences per file]`_

## Miscellaneous ([`misc`](/misc))
- [`split_file_into_n_files.pl`](/misc/split_file_into_n_files.pl): Splits file with multiple lines up into a number of smaller files, each with about the same number of lines.

   _Usage: `perl split_file_into_n_files.pl [file path]  [number output files to generate]`_

More coming soon :)
