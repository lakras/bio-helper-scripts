# bio-helper-scripts
Helper scripts for processing genomic sequence data.

Includes the following scripts—

## FASTA file processing ([`fasta`](/fasta))
- [`retrieve_sequences_by_name.pl`](/fasta/retrieve_sequences_by_name.pl): Retrieves query sequences by name from fasta file.

   _Usage: `perl retrieve_sequences_by_name.pl [fasta file path] [query sequence name 1] [query sequence name 2] [etc.]`_
   
- [`summarize_fasta_sequences.pl`](/fasta/summarize_fasta_sequences.pl): Summarizes sequences in fasta file. Produces table with number bases, number unambiguous bases, A+T, C+G, Ns, gaps, As, Ts, Cs, Gs, any other [bases](https://en.wikipedia.org/wiki/Nucleic_acid_notation) that appear in each sequence.

   _Usage: `perl summarize_fasta_sequences.pl [fasta file path]`_


More coming soon :)
