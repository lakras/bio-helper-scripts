# bio-helper-scripts
Helper scripts for processing genomic sequence data.

Includes the following scripts—

## FASTA file processing ([`fasta`](/fasta))
- [`retrieve_sequences_by_name.pl`](/fasta/retrieve_sequences_by_name.pl): Retrieves query sequences by name from fasta file.

   _Usage: `perl retrieve_sequences_by_name.pl [fasta file path] [query sequence name 1] [query sequence name 2] [etc.] > [output fasta file path]`_
   
- [`summarize_fasta_sequences.pl`](/fasta/summarize_fasta_sequences.pl): Summarizes sequences in fasta file. Produces table with, for each sequence: number bases, number unambiguous bases, A+T count, C+G count, number Ns, number gaps, number As, number Ts, number Cs, number Gs, and counts for any other [bases](https://en.wikipedia.org/wiki/Nucleic_acid_notation) that appear.

   _Usage: `perl summarize_fasta_sequences.pl [fasta file path] > [output table file path]`_

- [`split_fasta_into_n_files.pl`](/fasta/split_fasta_into_n_files.pl): Splits up fasta file into a set number of smaller files, each with about the same number of sequences.

   _Usage: `perl split_fasta_into_n_files.pl [fasta file path]  [number output files to generate]`_
   
- [`split_fasta_n_sequences_per_file.pl`](/fasta/split_fasta_n_sequences_per_file.pl): Splits up fasta file into multiple files with a set number of sequences per file.

   _Usage: `perl split_fasta_n_sequences_per_file.pl [fasta file path]  [number sequences per file]`_
   
- [`split_fasta_one_sequence_per_file.pl`](/fasta/split_fasta_one_sequence_per_file.pl): Splits up fasta file into multiple files with one sequence per file. Each output file is named using its sequence name.

   _Usage: `perl split_fasta_one_sequence_per_file.pl [fasta file path]`_
   
- [`modify_unaligned_fasta.pl`](/fasta/modify_unaligned_fasta.pl): Modifies unaligned fasta file according to allele changes specified in changes table. Not designed to handle gaps.

   _Usage: `perl modify_unaligned_fasta.pl [alignment fasta file path] [changes table] > [output fasta file path]`_
   
## FASTA alignment file processing ([`aligned-fasta`](/fasta))
- [`modify_alignment_fasta.pl`](/aligned-fasta/modify_alignment_fasta.pl): Modifies aligned fasta file according to allele changes specified in changes table. See script for description of changes table.

   _Usage: `perl modify_alignment_fasta.pl [alignment fasta file path] [changes table] > [output fasta file path]`_
   
- [`summarize_lineage_defining_SNPs.pl`](/aligned-fasta/summarize_lineage_defining_SNPs.pl): Prints list of lineage-defining positions and the lineages consistent with each allele.

   _Usage: `perl summarize_lineage_defining_SNPs.pl [alignment fasta file path] > [output file path]`_
   
- [`estimate_allele_lineages.pl`](/aligned-fasta/estimate_allele_lineages.pl): Generates table listing lineages consistent with each sample's consensus and minor alleles. See script for description of input files and output table.

   _Usage: `perl estimate_allele_lineages.pl [lineage genomes aligned to reference] [consensus genomes aligned to reference] [optional list of heterozygosity tables] > [output table path]`_

## Miscellaneous ([`misc`](/misc))
- [`split_file_into_n_files.pl`](/misc/split_file_into_n_files.pl): Splits file with multiple lines up into a number of smaller files, each with about the same number of lines.

   _Usage: `perl split_file_into_n_files.pl [file path]  [number output files to generate]`_
   
- [`make_r_friendly_table.pl`](/misc/make_r_friendly_table.pl): Converts table to R-friendly format. See script for example inputs and outputs.

   _Usage: `perl make_r_friendly_table.pl [table file path] [first data column] > [output table path]`_

More coming soon :)
