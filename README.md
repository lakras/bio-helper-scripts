# bio-helper-scripts
Helper scripts for processing genomic sequence data.

Includes the following scripts—

## FASTA file processing ([`fasta`](/fasta))
- [`retrieve_sequences_by_name.pl`](/fasta/retrieve_sequences_by_name.pl): Retrieves query sequences by name from fasta file.

   _Usage: `perl retrieve_sequences_by_name.pl [fasta file path] [query sequence name 1] [query sequence name 2] [etc.]`_
   
- [`summarize_fasta_sequences.pl`](/fasta/summarize_fasta_sequences.pl): Summarizes sequences in fasta file. Produces table with, for each sequence: number bases, number unambiguous bases, A+T count, C+G count, number Ns, number gaps, number As, number Ts, number Cs, number Gs, and counts for any other [bases](https://en.wikipedia.org/wiki/Nucleic_acid_notation) that appear.

   _Usage: `perl summarize_fasta_sequences.pl [fasta file path]`_


More coming soon :)
