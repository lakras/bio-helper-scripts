# bio-helper-scripts
Helper scripts for processing genomic sequence data.

Includes the following scripts—

## SARS-CoV-2 or other genome lineages ([`lineages`](/lineages))
   
- [`summarize_lineage_defining_SNPs.pl`](/lineages/summarize_lineage_defining_SNPs.pl): Prints list of lineage-defining positions and the lineage(s) consistent with each allele.

   _Usage: `perl summarize_lineage_defining_SNPs.pl [alignment fasta file path] > [output file path]`_
   
- [`estimate_allele_lineages.pl`](/lineages/estimate_allele_lineages.pl): Generates table listing lineage(s) consistent with each sample's consensus and minor alleles. See script for descriptions of input files and output table.

   _Usage: `perl estimate_allele_lineages.pl [lineage genomes aligned to reference] [consensus genomes aligned to reference] [optional list of heterozygosity tables] > [output table path]`_

## FASTA file processing ([`fasta`](/fasta))
- [`summarize_fasta_sequences.pl`](/fasta/summarize_fasta_sequences.pl): Summarizes sequences in fasta file. Produces table with, for each sequence: number bases, number unambiguous bases, A+T count, C+G count, number Ns, number gaps, number As, number Ts, number Cs, number Gs, and counts for any other [bases](https://en.wikipedia.org/wiki/Nucleic_acid_notation) that appear.

   _Usage: `perl summarize_fasta_sequences.pl [fasta file path] > [output table file path]`_

- [`retrieve_sequences_by_name.pl`](/fasta/retrieve_sequences_by_name.pl): Retrieves query sequences by name from fasta file.

   _Usage: `perl retrieve_sequences_by_name.pl [fasta file path] [query sequence name 1] [query sequence name 2] [etc.] > [output fasta file path]`_
   
- [`add_prefix_to_fasta_headers.pl`](/fasta/add_prefix_to_fasta_headers.pl): Adds prefix to each header line in fasta file(s).

   _Usage: `perl add_prefix_to_fasta_headers.pl [fasta file path] > [output fasta file path]`_

- [`split_fasta_into_n_files.pl`](/fasta/split_fasta_into_n_files.pl): Splits up fasta file into a set number of smaller files, each with about the same number of sequences.

   _Usage: `perl split_fasta_into_n_files.pl [fasta file path]  [number output files to generate]`_
   
- [`split_fasta_n_sequences_per_file.pl`](/fasta/split_fasta_n_sequences_per_file.pl): Splits up fasta file into multiple files with a set number of sequences per file.

   _Usage: `perl split_fasta_n_sequences_per_file.pl [fasta file path]  [number sequences per file]`_
   
- [`split_fasta_one_sequence_per_file.pl`](/fasta/split_fasta_one_sequence_per_file.pl): Splits up fasta file into multiple files with one sequence per file. Each output file is named using its sequence name.

   _Usage: `perl split_fasta_one_sequence_per_file.pl [fasta file path]`_
   
- [`modify_unaligned_fasta.pl`](/fasta/modify_unaligned_fasta.pl): Modifies unaligned fasta file according to allele changes specified in changes table. Not designed to handle gaps. See script for description of changes table.

   _Usage: `perl modify_unaligned_fasta.pl [alignment fasta file path] [changes table] > [output fasta file path]`_
   
## FASTA alignment file processing ([`aligned-fasta`](/aligned-fasta))
- [`modify_alignment_fasta.pl`](/aligned-fasta/modify_alignment_fasta.pl): Modifies aligned fasta file according to allele changes specified in changes table. See script for description of changes table.

   _Usage: `perl modify_alignment_fasta.pl [alignment fasta file path] [changes table] > [output fasta file path]`_

- [`remove_reference_gaps_in_alignment.pl`](/aligned-fasta/remove_reference_gaps_in_alignment.pl): Removes gaps in reference (first sequence) in alignment and bases or gaps at the corresponding positions in all other sequences in the alignment.

   _Usage: `perl remove_reference_gaps_in_alignment.pl [alignment fasta file path] > [output fasta file path]`_

## Miscellaneous ([`misc`](/misc))
- [`download_files.pl`](/misc/download_files.pl): Downloads files listed in input file from online or from google storage bucket.

   _Usage: `perl download_files.pl [file with list of files to download] [optional output directory]`_

- [`bulk_replace.pl`](/misc/bulk_replace.pl): Replaces all occurrences of values to mapped replacement values. Values to replace must be surrounded by whitespace or appear at the start or end of a line.

   _Usage: `perl bulk_replace.pl [tab-separated file mapping current values (first column) to new values (second column)] [path of file in which to replace values] [path of second file in which to replace values] [etc.]`_

- [`split_file_into_n_files.pl`](/misc/split_file_into_n_files.pl): Splits file with multiple lines up into a number of smaller files, each with about the same number of lines.

   _Usage: `perl split_file_into_n_files.pl [file path]  [number output files to generate]`_
   
- [`make_r_friendly_table.pl`](/misc/make_r_friendly_table.pl): Converts table to R-friendly format. See script for example inputs and outputs.

   _Usage: `perl make_r_friendly_table.pl [table file path] [first data column] > [output table path]`_
   
- [`merge_tables_by_column_value.pl`](/misc/merge_tables_by_column_value.pl): Merges (takes union of) two tables by the values in the specified columns.

   _Usage: `perl merge_tables_by_column_value.pl [table1 file path] [table1 column number (0-indexed)] [table2 file path] [table2 column number (0-indexed)] > [output table path]`_

More coming soon :)
