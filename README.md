# bio-helper-scripts
Helper scripts for processing genomic sequence data.

## Contents
- [SARS-CoV-2 or other genome lineages](#sars-cov-2-or-other-genome-lineages-lineages)
- [FASTA file processing](#fasta-file-processing-fasta)
- [FASTA alignment file processing](#fasta-alignment-file-processing-aligned-fasta)
- [Tables](#tables-tables)
   - [Column title manipulation](#column-title-manipulation)
   - [Column manipulation](#column-manipulation)
   - [Column manipulation with dates](#column-manipulation-with-dates)
   - [Row manipulation](#row-manipulation)
   - [Table manipulation](#table-manipulation)
   - [Replicates](#replicates)
   - [Other](#other)
- [Miscellaneous](#miscellaneous-misc)

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

- [`retrieve_sequences_by_names_listed_in_file.pl`](/fasta/retrieve_sequences_by_names_listed_in_file.pl): Retrieves query sequences by name from fasta file, taking query sequence names from a list in a file, one sequence name per line.

   _Usage: `perl retrieve_sequences_by_names_listed_in_file.pl [fasta file path] [file with list of query sequence names] > [output fasta file path]`_
   
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

## Tables ([`tables`](/tables))

### Column title manipulation

- [`replace_all_spaces_parens_in_column_titles.pl`](/tables/replace_all_spaces_parens_in_column_titles.pl): Replaces all spaces and parentheses in header line with provided replacement value, or underscore by default.

   _Usage: `perl replace_all_spaces_parens_in_column_titles.pl [table] [optional value to replace spaces with in header line] > [output table path]`_

- [`replace_column_title.pl`](/tables/replace_column_title.pl): Replaces column title with new column title.

   _Usage: `perl replace_column_title.pl [table] [current title of column to replace (no spaces)] [replacement column title] > [output table path]`_

### Column manipulation

- [`delete_column.pl`](/tables/delete_column.pl): Deletes column with input column title.

   _Usage: `perl delete_column.pl [table] [title of column to delete] > [output table path]`_

- [`concatenate_columns.pl`](/tables/concatenate_columns.pl): Concatenates selected columns. Adds concatenated values in new column.

   _Usage: `perl concatenate_columns.pl [tab-separated table] [column title] [another column title] [etc.] > [output table path]`_

- [`merge_columns.pl`](/tables/merge_columns.pl): Merges selected columns. Reports any conflicts. Input column titles cannot have whitespace.

   _Usage: `perl merge_columns.pl [table to merge] [title of column to merge] [title of another column to merge] [title of another column to merge] [etc.] > [output table path]`_

- [`replace_values_in_columns.pl`](/tables/replace_values_in_columns.pl): Replaces query with replacement text in specified columns.

   _Usage: `perl replace_values_in_columns.pl [table] [query text to replace] [replacement text] [1 to exactly match full column value only, 0 to allow search and replace within text of column value] [title of column to search] [title of another column to search] [title of another column to search] [etc.] > [output table path]`_

- [`delete_values_in_columns.pl`](/tables/delete_values_in_columns.pl): Deletes query in specified columns.

   _Usage: `perl delete_values_in_columns.pl [table] [query text to delete] [title of column to search] [title of another column to search] [title of another column to search] [etc.] > [output table path]`_

- [`add_to_start_and_end_of_values_in_columns.pl`](/tables/add_to_start_and_end_of_values_in_columns.pl): Pads non-empty values in specified columns with parameter start and end text. Start and end text may not contain whitespace.

   _Usage: `perl add_to_start_and_end_of_values_in_columns.pl [table] [text to add to start of each column value] [text to add to end of each column value] [title of column to search] [title of another column to search] [title of another column to search] [etc.] > [output table path]`_

- [`change_capitalization_in_columns.pl`](/tables/change_capitalization_in_columns.pl): Changes capitalization of values in specified columns: all capitalized, all lowercase, or first letter capitalized.

   _Usage: `perl change_capitalization_in_columns.pl [table] [uc to make all values uppercase, lc to make all values lowercase, first to capitalize first letter] [title of column to capitalize] [title of another column to capitalize] [title of another column to capitalize] [etc.] > [output table path]`_

- [`fill_in_empty_column_values.pl`](/tables/fill_in_empty_column_values.pl): Fills in empty values in column of interest with specified value.

   _Usage: `perl fill_in_empty_column_values.pl [table] [title of column to fill in (no spaces)] [value to replace empty values with] > [output table path]`_

- [`fill_in_empty_column_values_from_other_column.pl`](/tables/fill_in_empty_column_values_from_other_column.pl): Fills in empty values in column of interest with values from other column. No spaces allowed in parameter column titles.

   _Usage: `perl fill_in_empty_column_values_from_other_column.pl [table] [title of column to fill in] [title of column with potential replacement values] > [output table path]`_

- [`replace_column_values_with_other_column_where_present.pl`](/tables/replace_column_values_with_other_column_where_present.pl): Fills in values in column of interest with values from other column when they are present. No spaces allowed in parameter column titles.

   _Usage: `perl replace_column_values_with_other_column_where_present.pl [table] [title of column to fill in] [title of column with potential replacement values] > [output table path]`_

- [`replace_column_values_where_other_column_present_and_nonzero.pl`](/tables/replace_column_values_where_other_column_present_and_nonzero.pl): In rows where a column has a present, non-zero value, replaces value in another column with parameter replacement value

   _Usage: `perl replace_column_values_where_other_column_present_and_nonzero.pl [table] [title of column to check] [title of column to fill in] [replacement value] > [output table path]`_

- [`retrieve_subset_of_columns.pl`](/tables/retrieve_subset_of_columns.pl): Subsets table to only columns of interest.

   _Usage: `perl retrieve_subset_of_columns.pl [table] [title of first column to include in output] [title of second column to include] [title of third column to include] [etc.] > [output table path]`_

### Column manipulation with dates

- [`dates_in_columns_to_YYYY_MM_DD.pl`](/tables/dates_in_columns_to_YYYY_MM_DD.pl): Converts dates in specified columns to YYYY-MM-DD format. Multiple dates may be separated by a ", ". Column titles must not have spaces.

   _Usage: `perl dates_in_columns_to_YYYY_MM_DD.pl [table] [title of column with dates] [title of another column with dates] [title of another column with dates] [etc.] > [output table path]`_

- [`add_difference_in_dates_column.pl`](/tables/add_difference_in_dates_column.pl): Adds column listing difference in dates between columns specified in parameter column titles. Dates must be in YYYY-MM-DD format. Column titles must not have spaces. Not guaranteed to work for dates outside of 2021 (sorry!).

   _Usage: `perl add_difference_in_dates_column.pl [table] [title of column with dates] [title of another column with dates] > [output table path]`_

- [`sort_date_columns.pl`](/tables/sort_date_columns.pl): Sorts the dates in the specified columns. For each row, of the dates in the specified columns, the earliest date will go in the first specified column, the second-earliest in the second specified column, etc. Empty values go last. Dates provided must be in YYYY-MM-DD format.

   _Usage: `perl sort_date_columns.pl [table] [title of column with dates] [title of another column with dates] [title of another column with dates] [etc.] > [output table path]`_

- [`sort_date_columns_with_paired_label_columns.pl`](/tables/sort_date_columns_with_paired_label_columns.pl): Sorts the dates in the specified columns. For each row, of the dates in the specified columns, the earliest date will go in the first specified column, the second-earliest in the second specified column, etc. Empty values go last. Dates provided must be in YYYY-MM-DD format.

   _Usage: `perl sort_date_columns_with_paired_label_columns.pl [table] [title of column with dates] [title of label column that should travel with paired dates] [title of another column with dates] [title of label column that should travel with those paired dates] [etc.] > [output table path]`_

### Row manipulation

- [`filter_table_rows_by_column_value.pl`](/tables/filter_table_rows_by_column_value.pl): Filters table by column values. Only includes rows matching (containing, beginning with, ending with, or equal to) column value of interest in column to filter by. Case-sensitive. Column title must not have spaces.

   _Usage: `perl filter_table_rows_by_column_value.pl [tab-separated table] [0 to match cells containing query, 1: beginning with, 2: ending with, 3: equal to] [title of column to filter by] [value of column to select] > [output table path]`_

- [`delete_table_rows_with_column_value.pl`](/tables/delete_table_rows_with_column_value.pl): Deletes rows in table by column values. Only includes rows without column value containing text to filter out in column to filter by. Case-sensitive. Text to filter out must not have spaces.

   _Usage: `perl delete_table_rows_with_column_value.pl [tab-separated table] [query to select rows to delete] [0 to match cells containing query, 1: beginning with, 2: ending with, 3: equal to] [title of column to filter by] > [output table path]`_

- [`merge_rows_by_column_value.pl`](/tables/merge_rows_by_column_value.pl): Merges (takes union of) all columns in rows with shared value in column to merge by. If titles of columns not to merge by are provided, leaves one row per input row with all other columns identical. If no columns not to merge by provided, fully merges any rows sharing a value in column to merge by (one row per value).

   _Usage: `perl merge_rows_by_column_value.pl [table to merge] [title of column to merge by] [optional title of column not to merge] [optional title of another column not to merge] [etc.] > [output table path]`_

### Table manipulation

- [`concatenate_tables.pl`](/tables/concatenate_tables.pl): Concatenates tables with potentially different columns, adding empty space for missing column values.

   _Usage: `perl concatenate_tables.pl [table1] [table2] [table3] etc. > [concatenated output table path]`_

- [`merge_two_tables_by_column_value.pl`](/tables/merge_two_tables_by_column_value.pl): Merges (takes union of) two tables by the values in the specified columns.

   _Usage: `perl merge_two_tables_by_column_value.pl [table1 file path] [table1 column number (0-indexed)] [table2 file path] [table2 column number (0-indexed)] > [output table path]`_

- [`merge_tables_by_column_value.pl`](/tables/merge_tables_by_column_value.pl): Merges (takes union of) multiple tables by the values in the specified columns. See script for description of input file.

   _Usage: `perl merge_tables_by_column_value.pl [file describing input] > [merged output table path]`_

### Replicates

- [`annotate_replicates.pl`](/tables/annotate_replicates.pl): Assigns a source number to all replicates from the same source. Adds source number as a column to table to annotate.

   _Usage: `perl annotate_replicates.pl [tab-separated replicate ids, one line per source] [table to annotate] [title of column containing replicate ids in table to annotate] [optional source column title for output] > [annotated output table path]`_

- [`add_shared_values_summary_column.pl`](/tables/add_shared_values_summary_column.pl): Summarizes all values appearing in columns to summarize (sample ids and dates, for example) for each shared value (patient id, for example). Adds summary in new column.

   _Usage: `perl add_shared_values_summary_column.pl [tab-separated table] [title of column containing values shared by rows] [title of column to include in summary of shared values] [title of another column to include in summary of shared values] [etc.] > [output table path]`_

### Other

- [`summarize_table_columns.pl`](/tables/summarize_table_columns.pl): Summarizes values in table columns. Similar to str in R.

   _Usage: `perl summarize_table_columns.pl [tab-separated table] > [output table path]`_

- [`make_r_friendly_table.pl`](/tables/make_r_friendly_table.pl): Converts table to R-friendly format. See script for example inputs and outputs.

   _Usage: `perl make_r_friendly_table.pl [table file path] [first data column] > [output table path]`_

## Miscellaneous ([`misc`](/misc))
- [`download_files.pl`](/misc/download_files.pl): Downloads files listed in input file from online or from google storage bucket.

   _Usage: `perl download_files.pl [file with list of files to download] [optional output directory]`_

- [`bulk_replace.pl`](/misc/bulk_replace.pl): Replaces all occurrences of values to mapped replacement values. Values to replace must be surrounded by whitespace or appear at the start or end of a line.

   _Usage: `perl bulk_replace.pl [tab-separated file mapping current values (first column) to new values (second column)] [path of file in which to replace values] [path of second file in which to replace values] [etc.]`_

- [`bulk_grep.pl`](/misc/bulk_grep.pl): Searches all input files for queries listed in query list file.

   _Usage: `perl bulk_grep.pl [file listing queries, one per line] [file to grep] [another file to grep] [etc.] > [output file path]`_

- [`split_file_into_n_files.pl`](/misc/split_file_into_n_files.pl): Splits file with multiple lines up into a number of smaller files, each with about the same number of lines.

   _Usage: `perl split_file_into_n_files.pl [file path]  [number output files to generate]`_
     
More coming soon :)
