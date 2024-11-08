# bio-helper-scripts
Helper scripts for processing genomic sequence data.

## Contents
- [SARS-CoV-2 or other genome lineages](#sars-cov-2-or-other-genome-lineages-lineages)
- [FASTA file processing](#fasta-file-processing-fasta)
- [FASTA alignment file processing](#fasta-alignment-file-processing-aligned-fasta)
- [BLAST](#blast-blast)
- [VCF file processing](#vcf-file-processing-vcf-files)
- [BED file processing](#bed-file-processing-bed-files)
- [Read depth file processing](#read-depth-file-processing-read-depths)
- [Tables](#tables-tables)
   - [Table Format](#table-format)
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

   _Usage: `perl summarize_lineage_defining_SNPs.pl [alignment fasta file path] [optional 1 to compare all positions, including with gaps or ambiguous bases] > [output file path]`_
   
- [`estimate_allele_lineages.pl`](/lineages/estimate_allele_lineages.pl): Generates table listing lineage(s) consistent with each sample's consensus and minor alleles. See script for descriptions of input files and output table.

   _Usage: `perl estimate_allele_lineages.pl [lineage genomes aligned to reference] [consensus genomes aligned to reference] [optional list of heterozygosity tables] [optional list of read depth files] [1 to print columns for each lineage, 0 to print columns for consensus and minor alleles] > [output table path]`_

- [`annotate_heterozygosity_tables_with_estimated_lineages.pl`](/lineages/annotate_heterozygosity_tables_with_estimated_lineages.pl): Annotates heterozygosity tables with lineage consistent with minor and consensus-level alleles at lineage-defining positions. Output is printed to one file per heterozygosity table or as one table.

   _Usage: `perl annotate_heterozygosity_tables_with_estimated_lineages.pl [lineage genomes aligned to reference] [list of heterozygosity tables] [1 to print each heterozygosity table separately, 0 to print all tables to console] > [output table path]`_

- [`determine_distances_to_lineages_from_alignment.pl`](/lineages/determine_distances_to_lineages_from_alignment.pl): Generates 2d table of distances between all sequences in alignment to lineage sequences.

   _Usage: `perl determine_distances_to_lineages_from_alignment.pl [alignment fasta file path] [1 to ignore first sequence in alignment, 0 to include it] "[name of lineage sequence]" "[name of another lineage sequence]" [etc.] > [output fasta file path]`_

- [`assign_lineage_to_each_sequence.pl`](/lineages/assign_lineage_to_each_sequence.pl): Assigns to each sequence the lineage that is genetically closest to it.

   _Usage: `perl assign_lineage_to_each_sequence.pl [fasta file path] [lineage sequences fasta file path] [mafft command or file path] > [output table file path]`_


## FASTA file processing ([`fasta`](/fasta))
- [`summarize_fasta_sequences.pl`](/fasta/summarize_fasta_sequences.pl): Summarizes sequences in fasta file. Produces table with, for each sequence: number bases, number unambiguous bases, A+T count, C+G count, number Ns, number gaps, number As, number Ts, number Cs, number Gs, and counts for any other [bases](https://en.wikipedia.org/wiki/Nucleic_acid_notation) that appear.

   _Usage: `perl summarize_fasta_sequences.pl [fasta file path] [another fasta file path] [etc.] > [output table file path]`_

- [`cluster_sequences.pl`](/fasta/cluster_sequences.pl): Clusters sequences by similarity.

   _Usage: `perl cluster_sequences.pl [sequences fasta file] [percent identity, for example 80] [file path of MAFFT executable file (mafft.bat) or mafft command] > [output table]`_

- [`calculate_genome_size.pl`](/fasta/calculate_genome_size.pl): Counts number bases (including Ns and other ambiguous non-gap letters) in fasta file(s).

   _Usage: `perl calculate_genome_size.pl [fasta file path] [another fasta file path] [etc.]`_

- [`align_to_reference.pl`](/fasta/align_to_reference.pl): Aligns each input sequence with reference independently, then combines all into one fasta alignment. Bases aligned to a gap in the reference are removed. Sequences in input fastas must have unique names. Paths of fasta sequences to align can be provided directly as arguments or as one file with a list of filepaths, one per line.

   _Usage: `perl align_to_reference.pl [reference sequence] [file path of MAFFT executable file (mafft.bat) or mafft command] [filepaths of at least fasta files OR path of file containing file with list of fasta file paths, one per line] > [output fasta file path]`_

- [`align_each_fasta_file_to_reference_separately.pl`](/fasta/align_each_fasta_file_to_reference_separately.pl): Adds reference sequence to the top of each fasta file and aligns each file separately. New files are created at filepath of old file with "_aligned_to_ref.fasta" appended to the end. Temp files created with "_temp.fasta" appended to the end. Files already at those paths will be overwritten.

   _Usage: `perl align_each_fasta_file_to_reference_separately.pl [reference sequence] [file path of MAFFT executable file (mafft.bat) or mafft command] [fasta file path] [another fasta file path] [another fasta file path] [etc.]`_

- [`retrieve_sequences_by_name.pl`](/fasta/retrieve_sequences_by_name.pl): Retrieves query sequences by name from fasta file.

   _Usage: `perl retrieve_sequences_by_name.pl [fasta file path] "[query sequence name 1]" "[query sequence name 2]" [etc.] > [output fasta file path]`_

- [`remove_sequences_by_name.pl`](/fasta/remove_sequences_by_name.pl): Removes query sequences by name from fasta file.

   _Usage: `perl remove_sequences_by_name.pl [fasta file path] "[query sequence name 1]" "[query sequence name 2]" [etc.] > [output fasta file path]`_

- [`retrieve_sequences_by_names_listed_in_file.pl`](/fasta/retrieve_sequences_by_names_listed_in_file.pl): Retrieves query sequences by name from fasta file, taking query sequence names from a list in a file, one sequence name per line.

   _Usage: `perl retrieve_sequences_by_names_listed_in_file.pl [fasta file path] [file with list of query sequence names] > [output fasta file path]`_

- [`retrieve_sequences_containing_queries.pl`](/fasta/retrieve_sequences_containing_queries.pl): Prints all sequences from fasta file that contain at least one provided query in the sequence name. Case sensitive.

   _Usage: `perl retrieve_sequences_containing_queries.pl [fasta file path] "[query 1]" "[query 2]" "[query 3]" [etc.] > [output fasta file path]`_

- [`retrieve_sequences_by_position_in_fasta_file.pl`](/fasta/retrieve_sequences_by_position_in_fasta_file.pl): Retrieves query sequences by position from fasta file (in other words, retrieves the first fasta sequence in the file, or the second, or the third, and so on).

   _Usage: `perl retrieve_sequences_by_position_in_fasta_file.pl [fasta file path] [position of sequence to retrieve (1-indexed)] [position of another sequence to retrieve] [etc.] > [output fasta file path]`_

- [`remove_sequences_by_position_in_fasta_file.pl`](/fasta/remove_sequences_by_position_in_fasta_file.pl): Removes query sequences by position from fasta file.

   _Usage: `perl remove_sequences_by_position_in_fasta_file.pl [fasta file path] [position of sequence to remove (1-indexed)] [position of another sequence to remove] [etc.] > [output fasta file path]`_

- [`select_random_sequences.pl`](/fasta/select_random_sequences.pl): Selects a certain number of sequences at random from input fasta file.

   _Usage: `perl select_random_sequences.pl [fasta sequence file] [number sequences to select at random] > [output fasta file path]`_

- [`filter_sequences_by_length.pl`](/fasta/filter_sequences_by_length.pl): Filters fasta file by sequence length.

   _Usage: `perl filter_sequences_by_length.pl [fasta file path] [minimum length] [1 to filter by number of unambiguous bases, 0 to filter on number of bases (including Ns)] > [output fasta file path]`_

- [`reheader_fasta_sequences_from_filename.pl`](/fasta/reheader_fasta_sequences_from_filename.pl): Sets file name as header line in each fasta file(s). Each fasta file should have only one sequence.

   _Usage: `perl reheader_fasta_sequences_from_filename.pl [fasta file path] [another fasta file path] [etc.] > [output fasta file path]`_

- [`add_prefix_to_fasta_headers.pl`](/fasta/add_prefix_to_fasta_headers.pl): Adds prefix to each header line in fasta file(s).

   _Usage: `perl add_prefix_to_fasta_headers.pl [prefix to add to fasta file headers] [fasta file path] [another fasta file path] [etc.] > [output fasta file path]`_

- [`add_filename_as_prefix_to_fasta_headers.pl`](/fasta/add_filename_as_prefix_to_fasta_headers.pl): Adds file name as prefix to each header line in fasta file(s).

   _Usage: `perl add_filename_as_prefix_to_fasta_headers.pl [fasta file path] [another fasta file path] [etc.] > [output fasta file path]`_

- [`replace_fasta_headers_with_filenames.pl`](/fasta/replace_fasta_headers_with_filenames.pl): Replaces header line in fasta file(s) with file name.

   _Usage: `perl replace_fasta_headers_with_filenames.pl [fasta file path] [another fasta file path] [etc.] > [output fasta file path]`_

- [`split_fasta_into_n_files.pl`](/fasta/split_fasta_into_n_files.pl): Splits up fasta file into a set number of smaller files, each with about the same number of sequences.

   _Usage: `perl split_fasta_into_n_files.pl [fasta file path]  [number output files to generate]`_
   
- [`split_fasta_n_sequences_per_file.pl`](/fasta/split_fasta_n_sequences_per_file.pl): Splits up fasta file into multiple files with a set number of sequences per file.

   _Usage: `perl split_fasta_n_sequences_per_file.pl [fasta file path]  [number sequences per file]`_
   
- [`split_fasta_one_sequence_per_file.pl`](/fasta/split_fasta_one_sequence_per_file.pl): Splits up fasta file into multiple files with one sequence per file. Each output file is named using its sequence name.

   _Usage: `perl split_fasta_one_sequence_per_file.pl [fasta file path]`_

- [`extract_diverse_reference_genomes.pl`](/fasta/extract_diverse_reference_genomes.pl): Extracts a set of diverse reference sequences from the provided fasta file. Selects sequences without ambiguous bases that are at least N% different from already included sequences, considering sequences in order from longest to shortest sequence.

   _Usage: `perl extract_diverse_reference_genomes.pl [fasta file path] [proportion bases different between sequences in output set] [mafft command or file path] > [output fasta file]`_

- [`download_fasta_sequences_from_accession_numbers.pl`](/fasta/download_fasta_sequences_from_accession_numbers.pl): Given a list of accession numbers, one per line, downloads and prints fasta sequences corresponding to each accession number.

   _Usage: `perl download_fasta_sequences_from_accession_numbers.pl [path of file with list of accession numbers, one per line] [database (nucleotide by default)] > [output fasta file path]`_

- [`merge_fastas_and_remove_redundant_sequences.pl`](/fasta/merge_fastas_and_remove_redundant_sequences.pl): Merges fasta files, removing redundant sequences (so there is only one of each sequence, regardless of name). Can also be used to remove redundant sequences from a single fasta file.

   _Usage: `perl merge_fastas_and_remove_redundant_sequences.pl [fasta file path] [another fasta file path] [another fasta file path] [etc.] > [output fasta file path]`_

- [`modify_unaligned_fasta.pl`](/fasta/modify_unaligned_fasta.pl): Modifies unaligned fasta file according to allele changes specified in changes table. Not designed to handle gaps. See script for description of changes table.

   _Usage: `perl modify_unaligned_fasta.pl [alignment fasta file path] [changes table] > [output fasta file path]`_

- [`retrieve_sequence_position_in_fasta_file.pl`](/fasta/retrieve_sequence_position_in_fasta_file.pl): Prints position of sequence in fasta file.

   _Usage: `perl retrieve_sequence_position_in_fasta_file.pl [fasta sequence file] "[sequence name]"`_

- [`slice_fasta_file_before_or_after_sequence_name_query.pl`](/fasta/slice_fasta_file_before_or_after_sequence_name_query.pl): Prints either all sequences before or all sequence after sequence name appears in fasta sequence file.

   _Usage: `perl slice_fasta_file_before_or_after_sequence_name_query.pl [fasta file] [sequence name to slice before or after] [1 to print all sequences BEFORE sequence name, 0 to print all sequences AFTER sequence name] [1 to print sequences including sequence name, 0 not to] > [output fasta file]`_

- [`remove_duplicate_name_sequences.pl`](/fasta/remove_duplicate_name_sequences.pl): Removes any sequence whose full name has already appeared in the fasta file.

   _Usage: `perl remove_duplicate_name_sequences.pl [fasta file path] > [output fasta file path]`_

- [`retrieve_sequences_appearing_or_not_appearing_in_table.pl`](/fasta/retrieve_sequences_appearing_or_not_appearing_in_table.pl): Retrieves sequences whose names do or do not appear in input table.

   _Usage: `perl retrieve_sequences_appearing_or_not_appearing_in_table.pl [fasta file] [input table] [column number of sequence names (0-indexed)] [1 to retrieve sequences that DO appear in input table, 0 to retrieve sequences that DON'T] > [output fasta file path]`_

- [`search_for_query_sequences.pl`](/fasta/search_for_query_sequences.pl): Searches provided sequences for provided query sequences. Outputs table with columns: name of sequence containing at least one query sequence, number of query sequences matched.

   _Usage: `perl search_for_query_sequences.pl [fasta file path containing sequences to search] [fasta file path containing queries] > [output table file path]`_
   
- [`retrieve_sequences_matching_at_least_N_query_sequences.pl`](/fasta/retrieve_sequences_matching_at_least_N_query_sequences.pl): Searches provided sequences for provided query sequences. Outputs sequences matching at least N query sequences.

   _Usage: `perl retrieve_sequences_matching_at_least_N_query_sequences.pl [fasta file path containing sequences to search] [fasta file path containing queries] [minimum number queries to match] > [output fasta file path]`_

- [`filter_by_number_unambiguous_bases_with_minimum_read_depth.pl`](/fasta/filter_by_number_unambiguous_bases_with_minimum_read_depth.pl): Filters sequences in fasta file by number positions with an unambiguous base (A, T, C, or G) and read depth at least the minimum read depth.

   _Usage: `perl filter_by_number_unambiguous_bases_with_minimum_read_depth.pl [fasta file path] [list of read depth tables] [minimum read depth] [minimum number unabiguous bases with at least minimum read depth] > [output fasta file path]`_

- [`split_fasta_into_files_by_category_map.pl`](/fasta/split_fasta_into_files_by_category_map.pl): Splits fasta file into multiple files using map of sequence name to category.

   _Usage: `perl split_fasta_into_files_by_category_map.pl [fasta file path] [tab-separated map of sequence names to category, one sequence name per line] [directory to print output fasta files to]`_

- [`count_unambiguous_bases_in_each_sequence.pl`](/fasta/count_unambiguous_bases_in_each_sequence.pl): Counts number unambiguous bases (A, T, C, G) in each sequence. Outputs tab-separated table of sequence names and number unambiguous bases, one sequence per line.

   _Usage: `perl count_unambiguous_bases_in_each_sequence.pl [fasta file path] > [output table file path]`_

- [`blast/retrieve_sequences_with_no_blast_hits.pl`](/blast/retrieve_sequences_with_no_blast_hits.pl): Retrieves sequences that do not have blast results.

   _Usage: `perl retrieve_sequences_with_no_blast_hits.pl [blast output file] [fasta file that was input to blast] [minimum percent identity for a blast hit to be counted] [minimum query coverage for a blast hit to be counted] > [output fasta file path]`_
   
- [`blast/retrieve_sequences_with_blast_hits.pl`](/blast/retrieve_sequences_with_blast_hits.pl): Retrieves sequences that have blast results.

   _Usage: `perl retrieve_sequences_with_blast_hits.pl [blast output file] [fasta file that was input to blast] [minimum percent identity for a blast hit to be counted] [minimum query coverage for a blast hit to be counted] > [output fasta file path]`_

- [`blast/extract_hits_or_sequences_with_top_hit_in_taxon.pl`](/blast/extract_hits_or_sequences_with_top_hit_in_taxon.pl): Retrieves blast hits or fasta sequences of sequences with top hit or any hit at all in taxon of interest or its children.

   _Usage: `perl extract_hits_or_sequences_with_top_hit_in_taxon.pl [blast output table] [fasta file that was input to blast] [nodes.dmp file from NCBI] [taxon id of taxon of interest] [1 to print fasta sequences, 0 to print subset of blast output] > [output file path]`_

- [`bed-files/pull_out_sequences_described_in_bed_file.pl`](/bed-files/pull_out_sequences_described_in_bed_file.pl): Pulls out subsets of sequences by name and position within that sequence from bed file.

   _Usage: `perl pull_out_sequences_described_in_bed_file.pl [fasta file path] [bed file path] [0 to output fasta sequence, 1 to add sequence as new column in bed file] > [output file path]`_

- [`lineages/assign_lineage_to_each_sequence.pl`](/lineages/assign_lineage_to_each_sequence.pl): Assigns to each sequence the lineage that is genetically closest to it.

   _Usage: `perl assign_lineage_to_each_sequence.pl [fasta file path] [lineage sequences fasta file path] [mafft command or file path] > [output table file path]`_


## FASTA alignment file processing ([`aligned-fasta`](/aligned-fasta))

- [`generate_distance_table_from_alignment.pl`](/aligned-fasta/generate_distance_table_from_alignment.pl): Generates 2d table of distances between all sequences in alignment.

   _Usage: `perl generate_distance_table_from_alignment.pl [alignment fasta file path] [1 to ignore first sequence in alignment, 0 to include it] > [output fasta file path]`_

- [`modify_alignment_fasta.pl`](/aligned-fasta/modify_alignment_fasta.pl): Modifies aligned fasta file according to allele changes specified in changes table. See script for description of changes table.

   _Usage: `perl modify_alignment_fasta.pl [alignment fasta file path] [changes table] > [output fasta file path]`_

- [`mask_positions.pl`](/aligned-fasta/mask_positions.pl): Masks (replaces with Ns) alleles at indicated positions. Positions must be relative to same reference appearing in alignment fasta file. Reference must be first sequence in alignment fasta file. Does not mask bases that align to gaps in reference.

   _Usage: `perl mask_positions.pl [alignment fasta file path] [first position in region to mask] [last position in region to mask] [first position in another region to mask] [last position in another region to mask] [etc.] > [output fasta file path]`_

- [`mask_positions_in_bulk.pl`](/aligned-fasta/mask_positions_in_bulk.pl): Masks (replaces with Ns) alleles at indicated positions. Operates separately on each sequence as described in input table. Positions must be relative to same reference appearing in alignment fasta file. Reference must be first sequence in alignment fasta file. Does not mask bases that align to gaps in reference.

   _Usage: `perl mask_positions_in_bulk.pl [alignment fasta file path] [tab-separated table containing sequence name in first column, first and last positions of regions to mask in this sequence, space separated, in second column] [optional first position in additional region to mask in all sequences] [optional last position in additional region to mask in all sequences] [optional first position in another additional region to mask in all sequences] [optional last position in another additional region to mask in all sequences] [etc.] > [output fasta file path]`_

- [`mask_low_read_depth_alleles.pl`](/aligned-fasta/mask_low_read_depth_alleles.pl): Masks (replaces with Ns) alleles with low read depths.

   _Usage: `perl mask_low_read_depth_alleles.pl [alignment fasta file path] [list of read depth tables] [minimum read depth] > [output fasta file path]`_

- [`remove_reference_gaps_in_alignment.pl`](/aligned-fasta/remove_reference_gaps_in_alignment.pl): Removes gaps in reference (first sequence) in alignment and bases or gaps at the corresponding positions in all other sequences in the alignment.

   _Usage: `perl remove_reference_gaps_in_alignment.pl [alignment fasta file path] > [output fasta file path]`_

- [`combine_alignments_to_same_reference.pl`](/aligned-fasta/combine_alignments_to_same_reference.pl): Combines multiple fasta files including the same reference sequence into one fasta alignment. Reference fasta is printed first, with no gaps. All other sequences are printed aligned to the reference as in the input. Bases aligned to a gap in the reference are removed. Sequences in input files must have unique names. First sequence in each alignment fasta file must be reference.

   _Usage: `perl combine_alignments_to_same_reference.pl [alignment fasta file path] [another alignment fasta file path] [another alignment fasta file path] [etc.] > [output fasta file path]`_

- [`collapse_aligned_sequences_by_name.pl`](/aligned-fasta/collapse_aligned_sequences_by_name.pl): Merges aligned sequences with same name up to a ": ", such as those output by LASTZ.

   _Usage: `perl collapse_aligned_sequences_by_name.pl [alignment fasta file path] > [output fasta file path]`_

- [`get_average_sequence_of_aligned_sequences.pl`](/aligned-fasta/get_average_sequence_of_aligned_sequences.pl): Generates "average" sequence of aligned sequence from most common base at each position. If first sequence in alignment is reference, reference is not included in calculation of average sequence.

   _Usage: `perl get_average_sequence_of_aligned_sequences.pl [alignment fasta file path] [1 if alignment includes reference as first sequence, 0 if alignment does not include a reference] > [output fasta file path]`_

- [`compare_pairs_of_sequences_from_list.pl`](/aligned-fasta/compare_pairs_of_sequences_from_list.pl): Counts number unambiguous differences between each pair of sequences listed in input file.

   _Usage: `perl compare_pairs_of_sequences_from_list.pl [pairs of sequence names, space-separated, one per line] [alignment fasta file path] > [output table path]`_

- [`remove_empty_sequences.pl`](/aligned-fasta/remove_empty_sequences.pl): Removes sequences that are only -s or Ns or are length 0.

   _Usage: `perl remove_empty_sequences.pl [fasta file path] > [output fasta file path]`_

- [`remove_sequences_with_gaps_or_ambiguous_bases.pl`](/aligned-fasta/remove_sequences_with_gaps_or_ambiguous_bases.pl): Removes sequences with -s or bases that are not A, T, C, or G.

   _Usage: `perl remove_sequences_with_gaps_or_ambiguous_bases.pl [fasta file path] > [output fasta file path]`_
   

## BLAST ([`blast`](/blast))
All blast runs must use output format `-outfmt "6 qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue"`. (Otherwise, hardcoded column numbers can be modified within each script.)

Instructions for running blast in a Google Cloud Virtual Machine are in [`/blast/README.md`](/blast/README.md).

- [`count_sequences_in_blast_output.pl`](/blast/count_sequences_in_blast_output.pl): Counts the number of sequences with hits in the blast output.

   _Usage: `perl count_sequences_in_blast_output.pl [blast output table] [optional minimum percent id] [optional minimum query coverage] [1 to print sequence names, 0 to print number sequences only]`_

- [`retrieve_top_blast_hit_for_each_sequence.pl`](/blast/retrieve_top_blast_hit_for_each_sequence.pl): Retrieves top hit for each sequence (assumes they are in order in blast output).

   _Usage: `perl retrieve_top_blast_hit_for_each_sequence.pl [blast output] > [output subset of blast output table]`_

- [`retrieve_top_blast_hits_for_each_sequence.pl`](/blast/retrieve_top_blast_hits_for_each_sequence.pl): Retrieves top hit for each sequence (assumes they are in order in blast output). Prints all top hits with same e-values.

   _Usage: `perl retrieve_top_blast_hits_for_each_sequence.pl [blast output] [number by which to multiply sequence's top evalue, to use as threshold for inclusion in top hits] [1 to treat blast output as modified DIAMOND output] > [output subset of blast output table]`_

- [`filter_blast_hits.pl`](/blast/filter_blast_hits.pl): Filters blast hits: prints blast hits with at least minimum percent identity and at least minimum percent query coverage. Can also further filter with optional maximum percent identity, maximum percent query coverage provided, or minimum length of matched sequence.

   _Usage: `perl filter_blast_hits.pl [blast output] [minimum percent identity] [minimum percent query coverage] [optional maximum percent identity] [optional maximum percent query coverage] [optional minimum length of matched sequence] > [output subset of blast output table]`_

- [`retrieve_blast_outputs_for_sequences_of_interest.pl`](/blast/retrieve_blast_outputs_for_sequences_of_interest.pl): Retrieves blast hits for sequences of interest from blast output file.

   _Usage: `perl retrieve_blast_outputs_for_sequences_of_interest.pl [blast output file] [sequence name to retrieve blast hits for] [another sequence name to retrieve blast hits for] [etc.] > [subset blast output path]`_

- [`retrieve_sequences_with_no_blast_hits.pl`](/blast/retrieve_sequences_with_no_blast_hits.pl): Retrieves sequences that do not have blast results.

   _Usage: `perl retrieve_sequences_with_no_blast_hits.pl [blast output file] [fasta file that was input to blast] [minimum percent identity for a blast hit to be counted] [minimum query coverage for a blast hit to be counted] > [output fasta file path]`_
   
- [`retrieve_sequences_with_blast_hits.pl`](/blast/retrieve_sequences_with_blast_hits.pl): Retrieves sequences that have blast results.

   _Usage: `perl retrieve_sequences_with_blast_hits.pl [blast output file] [fasta file that was input to blast] [minimum percent identity for a blast hit to be counted] [minimum query coverage for a blast hit to be counted] > [output fasta file path]`_

- [`slice_blast_output_file_before_or_after_sequence_name_query.pl`](/blast/slice_blast_output_file_before_or_after_sequence_name_query.pl): Prints either all lines before or all lines after sequence name appears in blast output file.

   _Usage: `perl slice_blast_output_file_before_or_after_sequence_name_query.pl [blast output] [sequence name to slice before or after] [1 to print all lines BEFORE sequence name, 0 to print all lines AFTER sequence name] [1 to print lines including sequence name, 0 not to] > [output subset of blast output table]`_

- [`extract_hits_or_sequences_with_top_hit_in_taxon.pl`](/blast/extract_hits_or_sequences_with_top_hit_in_taxon.pl): Retrieves blast hits or fasta sequences of sequences with top hit or any hit at all in taxon of interest or its children.

   _Usage: `perl extract_hits_or_sequences_with_top_hit_in_taxon.pl [blast output table] [fasta file that was input to blast] [nodes.dmp file from NCBI] [taxon id of taxon of interest] [1 to print fasta sequences, 0 to print subset of blast output] > [output file path]`_

- [`extract_hits_or_sequences_with_no_or_poor_blast_hits_in_large_database_compared_to_in_taxon_specific_database.pl`](/blast/extract_hits_or_sequences_with_no_or_poor_blast_hits_in_large_database_compared_to_in_taxon_specific_database.pl): Retrieves blast hits or fasta sequences of sequences that produced a blast hit from the taxon of interest in a blast search within a database consisting only of sequences from the taxon of interest and produced either no hits at all in blast search within large database blast search or only hits that were comparable to or worse than hits from the blast search in the taxon-specific database.

   _Usage: `perl extract_hits_or_sequences_with_no_or_poor_blast_hits_in_large_database_compared_to_in_taxon_specific_database.pl [blast output table from taxon-specific database blast search] [blast output table from large database blast search] [fasta file that was input to blast for large database blast search] [nodes.dmp file from NCBI] [taxon id of taxon of interest] [1 to print fasta sequences, 0 to print subset of blast output] > [output file path]`_

- [`retrieve_top_blast_hits_LCA_for_each_sequence.pl`](/blast/retrieve_top_blast_hits_LCA_for_each_sequence.pl): For each sequence, extracts all top hits with same e-values (assumes they are in order in blast output). Prints lowest common ancestor (LCA) of top hits for each sequence.

   _Usage: `perl retrieve_top_blast_hits_LCA_for_each_sequence.pl [blast output] [nodes.dmp file from NCBI] [number by which to multiply sequence's top evalue, to use as threshold for inclusion in LCA] [1 to print all matched accession numbers in a final column] [1 to treat blast output as modified DIAMOND output] > [output table]`_
   
- [`generate_LCA_table_for_sequences_with_no_matches.pl`](/blast/generate_LCA_table_for_sequences_with_no_matches.pl): Generates an LCA matches table (matching output of retrieve_top_blast_hits_LCA_for_each_sequence.pl) for sequences with no blast hits.

   _Usage: `perl generate_LCA_table_for_sequences_with_no_matches.pl [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search] [fasta file that was input to blast search] > [output table]`_
   
- [`compare_LCA_matches_to_ground_truth_LCA_matches.pl`](/blast/compare_LCA_matches_to_ground_truth_LCA_matches.pl): Compares LCA match taxon from two blast outputs for each match. Uses output of retrieve_top_blast_hits_LCA_for_each_sequence.pl as input.

   _Usage: `perl compare_LCA_matches_to_ground_truth_LCA_matches.pl [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search, to be treated as ground truth] [output of another retrieve_top_blast_hits_LCA_for_each_sequence.pl for another blast search, to compare to ground truth] [nodes.dmp file from NCBI] > [output table]`_

- [`retrieve_taxonids_from_accession_numbers_of_blast_matches.pl`](/blast/retrieve_taxonids_from_accession_numbers_of_blast_matches.pl): Retrieves each match's taxon id from Entrez using match accession number column and adds taxon ids to blast or diamond output as a new column.

   _Usage: `perl retrieve_taxonids_from_accession_numbers_of_blast_matches.pl [blast or diamond output] [1 if blast or diamond output is from a nucleotide search; 0 if it is from a protein search] [column number of new taxon id column to add to output file (0-indexed)] [column number (0-indexed) of column containing match accession numbers (stitle)] [optional column number (0-indexed) of column containing match names (stitle)] > [blast or diamond output with taxon id column added]`_

- [`retrieve_taxonids_from_accession_numbers_of_blast_matches_bulk.pl`](/blast/retrieve_taxonids_from_accession_numbers_of_blast_matches_bulk.pl): Maps accession numbers to taxon ids directly from NCBI accession number to taxon id mapping file, without using Entrez. Useful for mapping thousands or millions of accession numbers, since this method does not have rate limits. Retrieves each match's taxon id from from match accession number column and adds taxon ids to blast or diamond output as a new column. Reads in mapping tables in parallel to save time. Appropriate mapping tables must be downloaded and unzipped from ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/ (see README file).

   _Usage: `perl retrieve_taxonids_from_accession_numbers_of_blast_matches_bulk.pl [blast or diamond output] [column number of new taxon id column to add to output file (0-indexed)] [column number (0-indexed) of column containing match accession numbers (stitle)] [unzipped mapping table] [another unzipped mapping table] [etc.] > [blast or diamond output with taxon id column added]`_

- [`retrieve_taxonids_from_accession_numbers.pl`](/blast/retrieve_taxonids_from_accession_numbers.pl): Given a list of accession numbers, one per line, retrieves corresponding taxon ids. Outputs tab-separating map with sequence name and taxon id.

   _Usage: `perl retrieve_taxonids_from_accession_numbers.pl [path of file with list of accession numbers, one per line] [database (nuccore by default)] > [output mapping table path]`_

- [`retrieve_taxon_names_from_taxonids.pl`](/blast/retrieve_taxon_names_from_taxonids.pl): Retrieves each match's taxon name from its taxon id and adds it to blast or diamond output as a new column.

   _Usage: `perl retrieve_taxon_names_from_taxonids.pl [blast or diamond output] [names.dmp file from NCBI] > [blast or diamond output with taxon name column added]`_

- [`retrieve_most_common_taxonids_in_LCA_output.pl`](/blast/retrieve_most_common_taxonids_in_LCA_output.pl): Retrieve NN most frequently matched species, genera, or families.

   _Usage: `perl retrieve_most_common_taxonids_in_LCA_output.pl [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search] [species, genus, or family] [number most frequent matched species, genera, or families to output] [minimum number reads matched by a taxon to report it] > [output list of taxon ids, one per line]`_

- [`retrieve_all_taxonids_in_LCA_output.pl`](/blast/retrieve_all_taxonids_in_LCA_output.pl): Retrieve all matched species, genera, or families.

   _Usage: `perl retrieve_all_taxonids_in_LCA_output.pl [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search] [species, genus, or family] > [output list of taxon ids, one per line]`_

- [`retrieve_refseq_genome_accession_numbers_from_taxon_ids.pl`](/blast/retrieve_refseq_genome_accession_numbers_from_taxon_ids.pl): Given a list of taxon ids, one per line, retrieves accession numbers of refseq genomes. Outputs list of refseq genome accession numbers, one per line.

   _Usage: `perl retrieve_refseq_genome_accession_numbers_from_taxon_ids.pl [path of file with list of accession numbers, one per line] > [output list file path]`_

- [`retrieve_most_common_accession_numbers_from_most_common_taxonids_in_LCA_output.pl`](/blast/retrieve_most_common_accession_numbers_from_most_common_taxonids_in_LCA_output.pl): Retrieve most frequent NN accession numbers matched from most frequent NN matched species, genera, or families.

   _Usage: `perl retrieve_most_common_accession_numbers_from_most_common_taxonids_in_LCA_output.pl [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search] [species, genus, or family] [number most frequent matched species, genera, or families to examine] [number accession numbers most frequent matched by descendants of most frequent species, genera, or families] > [output list of accession numbers, one per line]`_

- [`filter_LCA_matches.pl`](/blast/filter_LCA_matches.pl): Filters LCA matches by rank (at least species, genus, or family), mean percent identity, and/or mean percent query coverage. Uses output of retrieve_top_blast_hits_LCA_for_each_sequence.pl as input.

   _Usage: `perl filter_LCA_matches.pl [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search] [1 to requires output matches to be classified to at least species level] [1 to requires output matches to be classified to at least genus level] [1 to requires output matches to be classified to at least family level] [minimum mean percent identity] [maximum mean percent identity]  [minimum mean percent query coverage] [maximum mean percent query coverage]   > [output filtered LCA matches table]`_

- [`filter_taxonids_to_descendants_of_target_taxon.pl`](/blast/filter_taxonids_to_descendants_of_target_taxon.pl): Given a list of txaon ids, one per line, filters down to only descendants of parameter taxon id (for example, 10239 for Viruses).

   _Usage: `perl filter_taxonids_to_descendants_of_target_taxon.pl [path of file with list of taxon ids, one per line] [nodes.dmp file from NCBI] [taxon id to filter to] > [output list of taxon ids]`_

- [`filter_taxonids_in_table_column_to_descendants_of_target_taxon.pl`](/blast/filter_taxonids_in_table_column_to_descendants_of_target_taxon.pl): Given a table with a column of taxon ids, filters down to only descendants of parameter taxon id (for example, 10239 for Viruses).

   _Usage: `perl filter_taxonids_in_table_column_to_descendants_of_target_taxon.pl [path of table with taxon id] [number (0-indexed) of column with taxon ids] [nodes.dmp file from NCBI] [taxon id to filter to] > [output table]`_

- [`add_column_with_superkingdom_of_taxon_id.pl`](/blast/add_column_with_superkingdom_of_taxon_id.pl): Reads in column containing taxon id and adds column containing the superkingdom of that taxon id.

   _Usage: `perl add_column_with_superkingdom_of_taxon_id.pl [table] [title of column containing taxon ids] [nodes.dmp file from NCBI] > [output table path]`_

- [`kraken_summary_report_to_species_table.pl`](/blast/kraken_summary_report_to_species_table.pl): Converts Kraken summary report to table of species found in sample.

   _Usage: `perl kraken_summary_report_to_species_table.pl [kraken summary report] > [output table file path]`_

- [`LCA_table_to_kraken_output_format.pl`](/blast/LCA_table_to_kraken_output_format.pl): Converts LCA output table to kraken output format. Treats paired reads as separate reads.

   _Usage: `perl LCA_table_to_kraken_output_format.pl [output of retrieve_top_blast_hits_LCA_for_each_sequence.pl for one blast search] [fasta file that was input to blast search (to retrieve sequence lengths and names of unclassified sequences)] > [output kraken format table]`_


## VCF file processing ([`vcf-files`](/vcf-files))
Input VCF files must be in format produced by [`LoFreq call`](https://csb5.github.io/lofreq/commands/#call).

- [`vcf_file_to_heterozygosity_table.pl`](/vcf-files/vcf_file_to_heterozygosity_table.pl): Reads in vcf file output produced by [`LoFreq call`](https://csb5.github.io/lofreq/commands/#call) and prints human-readable heterozygosity table. Optionally filters output by read depth, minor allele readcount, and minor allele frequency. See code for output table format and hardcoded filtering thresholds.

   _Usage: `perl vcf_file_to_heterozygosity_table.pl [vcf file output by LoFreq] [1 to filter output, 0 to not filter] [optional 1 to not print reference column in output, to save space] > [output file path]`_

- [`detect_potential_transmission_events_from_iSNVs.pl`](/vcf-files/detect_potential_transmission_events_from_iSNVs.pl): Detects potential transmission events from iSNVs, assuming an average transmission bottleneck of one virus per transmission. If collection dates are provided, only compares sequences within hardcoded maximum collection date distance. See script for input file details and options.

   _Usage: `perl detect_potential_transmission_events_from_iSNVs.pl [consensus sequences alignment fasta file path] [list of heterozygosity tables] [optional list of read depth tables] [optional tab-separated table mapping sample names to collection dates (YYYY-MM-DD)] [0 to print one line per sample pair, 1 to print one line per iSNV] > [output fasta file path]`_

- [`mask_positions_in_heterozygosity_table.pl`](/vcf-files/mask_positions_in_heterozygosity_table.pl): Masks (removes lines corresponding to) alleles at indicated positions. See script for input file format. Positions must be relative to reference used in heterozygosity table.

   _Usage: `perl mask_positions_in_heterozygosity_table.pl [heterozygosity table] [first position in region to mask] [last position in region to mask] [first position in another region to mask] [last position in another region to mask] [etc.] > [output heterozygosity table file path]`_

- [`mask_positions_in_heterozygosity_table_in_bulk.pl`](/vcf-files/mask_positions_in_heterozygosity_table_in_bulk.pl): Masks (removes lines corresponding to) alleles at indicated positions. Operates separately on multiple files as described in input table. See script for input file format. Positions must be relative to reference used in heterozygosity table.

   _Usage: `perl mask_positions_in_heterozygosity_table_in_bulk.pl [tab-separated table containing filepath of heterozygosity table in first column, first and last positions of regions to mask in this heterozygosity table, space separated, in second column] [optional first position in additional region to mask in all heterozygosity tables] [optional last position in additional region to mask in all heterozygosity tables] [optional first position in another additional region to mask in all heterozygosity tables] [optional last position in another additional region to mask in all heterozygosity tables] [etc.]`_

- [`filter_heterozygosity_table.pl`](/vcf-files/filter_heterozygosity_table.pl): Filters input heterozygosity table. See script for input file format.

   _Usage: `perl filter_heterozygosity_table.pl [heterozygosity table] [minimum minor allele readcount] [minimum minor allele frequency] [minimum read depth] > [output filtered heterozygosity table path]`_

- [`rereference_positions_in_heterozygosity_table.pl`](/vcf-files/rereference_positions_in_heterozygosity_table.pl): Uses alignment of consensus genome to reference to update heterozygosity table positions with respect to self to positions with respect to the reference genome in the alignment.

   _Usage: `perl convert_positions_in_heterozygosity_table_from_relative_to_self_to_relative_to_reference_in_alignment.pl [consensus sequence aligned to reference fasta file] [list of heterozygosity tables, one per line]# > [output heterozygosity table]`_

- [`rereference_positions_in_read_depths_table.pl`](/vcf-files/rereference_positions_in_read_depths_table.pl): Uses alignment of consensus genome to reference to update read depths table positions with respect to self to positions with respect to the reference genome in the alignment.

   _Usage: `perl rereference_positions_in_read_depths_table.pl [consensus sequence aligned to reference fasta file] [list of read_depths tables, one per line]# > [output read_depths table]`_

- [`lineages/annotate_heterozygosity_tables_with_estimated_lineages.pl`](/lineages/annotate_heterozygosity_tables_with_estimated_lineages.pl): Annotates heterozygosity tables with lineage consistent with minor and consensus-level alleles at lineage-defining positions. Output is printed to one file per heterozygosity table or as one table.

   _Usage: `perl annotate_heterozygosity_tables_with_estimated_lineages.pl [lineage genomes aligned to reference] [list of heterozygosity tables] [1 to print each heterozygosity table separately, 0 to print all tables to console] > [output table path]`_

## BED file processing ([`bed-files`](/bed-files))
Read a description of the BED file format [on Wikipedia](https://en.wikipedia.org/wiki/BED_(file_format)).

- [`pull_out_sequences_described_in_bed_file.pl`](/bed-files/pull_out_sequences_described_in_bed_file.pl): Pulls out subsets of sequences by name and position within that sequence from bed file.

   _Usage: `perl pull_out_sequences_described_in_bed_file.pl [fasta file path] [bed file path] [0 to output fasta sequence, 1 to add sequence as new column in bed file] > [output file path]`_

- [`retrieve_amplicon_regions_from_primer_regions.pl`](/bed-files/retrieve_amplicon_regions_from_primer_regions.pl): Reads in positions of primers and outputs positions of amplicons between those primers. Uses primer names to match left and right primers. Primer names must include the primer number and \_LEFT or \_RIGHT, for example nCoV-2019\_1\_LEFT or nCoV-2019\_26_RIGHT. If more multiple start primers or multiple end primers are provided for an amplicon, the amplicon is set to be the largest possible with all its provided primers.

   _Usage: `perl retrieve_amplicon_regions_from_primer_regions.pl [primers bed file path] > [amplicons bed file path]`_

- [`modify_start_end_position_indexing_and_inclusivity.pl`](/bed-files/modify_start_end_position_indexing_and_inclusivity.pl): Modifies start and end positions in bed file from 0-indexed or 1-indexed to 0-indexed or 1-indexed and from inclusive end or non-iclusive end to inclusive end or non-iclusive end.

   _Usage: `perl modify_start_end_position_indexing_and_inclusivity.pl [bed file path] [1 if input is 1-indexed, 0 if input is 0-indexed] [1 if input has inclusive end, 0 if input has non-inclusive end] [1 if output should be 1-indexed, 0 if output should be 0-indexed] [1 if output should have inclusive end, 0 if output should have non-inclusive end] > [output bed file path]`_

- [`remove_bed_file_rows_overlapping_positions.pl`](/bed-files/remove_bed_file_rows_overlapping_positions.pl): Removes rows in bed file that overlap with parameter positions.

   _Usage: `perl remove_bed_file_rows_overlapping_positions.pl [bed file path] [position (0-indexed); any rows overlapping this position will be removed] [another position] [another position] [etc.] > [output bed file path]`_

- [`determine_regions_not_covered_by_amplicons.pl`](/bed-files/determine_regions_not_covered_by_amplicons.pl): Takes in a bed file of amplicons and outputs a bed file of positions not covered by those amplicons. Assumes all amplicons come from only one reference sequence.

   _Usage: `perl determine_regions_not_covered_by_amplicons.pl [amplicons bed file path] > [output bed file path]`_

- [`calculate_proportions_bed_file_covered_by_other_bed_files.pl`](/bed-files/calculate_proportions_bed_file_covered_by_other_bed_files.pl): Takes in one bed file and at least one other bed file to compare it to. Outputs proportion of the sequence in the regions described in the first bed file that is captured in the regions described in each additional bed file. Outputs each bed file path and the proportion it covers of the first bed file. Assumes all rows come from only one reference sequence.

   _Usage: `perl calculate_proportions_bed_file_covered_by_other_bed_files.pl [bed file path] [other bed file path] [another bed file path] [and another] [etc.] > [output file path]`_

- [`annotate_positions_with_regions_they_overlap.pl`](/bed-files/annotate_positions_with_regions_they_overlap.pl): Annotates positions in input table with the names of the region(s) they are in. Adds column containing names of regions the position overlaps. If multiple regions overlap a position they are comma-separated in the new column.

   _Usage: `perl annotate_positions_with_regions_they_overlap.pl [table containing positions to annotate] "[title of column containing positions to annotate]" [table containing start and end positions and names of regions] [optional output column title (overlapping_regions by default)] > [output table path]`_

- [`retrieve_amplicon_regions_from_primer_regions_and_count_number_amplicons_overlapping_each_position.pl`](/bed-files/retrieve_amplicon_regions_from_primer_regions_and_count_number_amplicons_overlapping_each_position.pl): Reads in positions of primers and determines positions of amplicons between those primers. Outputs total number amplicons overlapping each position.

   _Usage: `perl retrieve_amplicon_regions_from_primer_regions_and_count_number_amplicons_overlapping_each_position.pl [primers bed file path] > [amplicons bed file path]`_

- [`extend_primers_to_include_amplicon_overlaps.pl`](/bed-files/extend_primers_to_include_amplicon_overlaps.pl): Extends primers to include positions that are in more than one amplicon. Amplicons in the resulting bed file do not overlap. Outputs new primer bed file.

   _Usage: `perl extend_primers_to_include_amplicon_overlaps.pl [primers bed file path] > [new primers bed file path]`_

## Read depth file processing ([`read-depths`](/read-depths))
Input read depth tables must be in format produced by [`samtools depth`](http://www.htslib.org/doc/samtools-depth.html): tab-separated reference name, position, read depth; no header line.

- [`summarize_read_depths_across_files.pl`](/read-depths/summarize_read_depths_across_files.pl): Summarizes read depths across read depth tables. Outputs table with reference name; position; and mean, standard deviation, median, min, max, and range of read depths at each position, and number of read depth values at each position that are 0.

   _Usage: `perl summarize_read_depths_across_files.pl [read depth table] [another read depth table] [another read depth table] [etc.] > [output table path]`_

- [`retrieve_position_ranges_with_threshold_read_depth.pl`](/read-depths/retrieve_position_ranges_with_threshold_read_depth.pl): Prints ranges of positions with read depths at or above minimum read depth.

   _Usage: `perl retrieve_position_ranges_with_threshold_read_depth.pl [minimum read depth] [read depth table] [optional 1 to print output as one line] [optional 1 to print position ranges NOT passing read depth threshold, rather than positions that do] > [output path]`_

- [`aligned-fasta/mask_low_read_depth_alleles.pl`](/aligned-fasta/mask_low_read_depth_alleles.pl): Masks (replaces with Ns) alleles with low read depths.

   _Usage: `perl mask_low_read_depth_alleles.pl [alignment fasta file path] [list of read depth tables] [minimum read depth] > [output fasta file path]`_

## Tables ([`tables`](/tables))

Tables are assumed to be tab-separated (usually denoted `.tsv` or `.txt`. To use with comma-separated `.csv` files, change the value of the `$DELIMITER` variable from `"\t"` to `","` or convert from comma-separated csv tables to tab-separated tsv tables using [`csv_to_tsv.pl`](/tables/csv_to_tsv.pl).

### Table Format

- [`csv_to_tsv.pl`](/tables/csv_to_tsv.pl): Converts comma-separated csv table to tab-separated tsv table.

   _Usage: `perl csv_to_tsv.pl [table] > [output table path]`_
   
- [`tsv_to_csv.pl`](/tables/tsv_to_csv.pl): Converts tab-separated tsv table to comma-separated csv table.

   _Usage: `perl tsv_to_csv.pl [table] > [output table path]`_

- [`make_r_friendly_table.pl`](/tables/make_r_friendly_table.pl): Converts table to R-friendly format. See script for example inputs and outputs.

   _Usage: `perl make_r_friendly_table.pl [table file path] [first data column index] > [output table path]`_
   
- [`convert_variable_value_lists_to_table.pl`](/tables/convert_variable_value_lists_to_table.pl): Converts lists of variable values, such as those output by Terra, to a table. Lists of values must appear with variable on one line followed by values in the following line, comma-separated and surrounded by brackets. Lines not matching this format are ignored. Variable names must be unique (cannot repeat). List items must be in order for all variables. Expects all variables to have identical numbers of values: ignores variables with less than the largest number of values. See code for example of input and output formats.

   _Usage: `perl convert_variable_value_lists_to_table.pl [file containing input lists] [optional list item separator, ", " by default] [optional list start, "[" by default] [optional list end, "]" by default] > [output table path]`_

### Column title manipulation

- [`replace_all_spaces_parens_in_column_titles.pl`](/tables/replace_all_spaces_parens_in_column_titles.pl): Replaces all spaces and parentheses in header line with provided replacement value, or underscore by default.

   _Usage: `perl replace_all_spaces_parens_in_column_titles.pl [table] [optional value to replace spaces with in header line] > [output table path]`_

- [`replace_column_title.pl`](/tables/replace_column_title.pl): Replaces column title with new column title.

   _Usage: `perl replace_column_title.pl [table] "[current title of column to replace]" "[replacement column title]" > [output table path]`_

### Column manipulation

- [`delete_columns.pl`](/tables/delete_columns.pl): Deletes columns with specified column titles.

   _Usage: `perl delete_columns.pl [table] "[title of column to delete]" "[title of another column to delete]" "[title of another column to delete]" [etc.] > [output table path]`_

- [`replace_whole_column_with_empty_values.pl`](/tables/replace_whole_column_with_empty_values.pl): Replaces whole column (including title unless hardcoded option selected) with empty values.

   _Usage: `perl replace_whole_column_with_empty_values.pl [table] "[column title]" "[another column title]" [etc.] > [output table path]`_

- [`duplicate_columns.pl`](/tables/duplicate_columns.pl): Duplicates selected columns.

   _Usage: `perl duplicate_columns.pl [tab-separated table] "[column title]" "[another column title]" [etc.] > [output table path]`_

- [`add_one_value_column.pl`](/tables/add_one_value_column.pl): Adds column with specified title and specified value for all values.

   _Usage: `perl add_one_value_column.pl [table to add column to] "[title of column to add]" "[value of column to add]" > [output table path]`_

- [`add_column_for_selected_rows.pl`](/tables/add_column_for_selected_rows.pl): Creates new column with values in selected rows.

   _Usage: `perl add_column_for_selected_rows.pl [table to add new column to] "[title of column in table to identify rows by]" [file with list of rows to select, one per line] "[optional title of new column to add]" "[optional value to add to selected rows in new column]" "[optional value to add to all other rows in new column]" > [output table path]`_

- [`concatenate_columns.pl`](/tables/concatenate_columns.pl): Concatenates values in selected columns. Adds concatenated values in new column.

   _Usage: `perl concatenate_columns.pl [tab-separated table] "[column title]" "[another column title]" [etc.] > [output table path]`_

- [`summarize_numerical_columns.pl`](/tables/summarize_numerical_columns.pl): Summarizes selected numerical columns. Adds new columns with: mean, standard deviation, median, min, max, range, and all values sorted in a comma-separated list. If a column value contains a comma-separated list, includes all values from list.

   _Usage: `perl summarize_numerical_columns.pl [tab-separated table] "[column title]" "[another column title]" [etc.] > [output table path]`_

- [`summarize_numerical_column_holding_other_columns_constant.pl`](/tables/summarize_numerical_column_holding_other_columns_constant.pl): Summarizes values in selected numerical column while holding other columns constant. Outputs table with constant columns and new columns with statistics summarizing selected numerical column: mean, standard deviation, median, number values, min, max, range, and all values sorted in a comma-separated list.

   _Usage: `perl summarize_numerical_column_holding_other_columns_constant.pl [tab-separated table] "[title of numerical column to summarize]" "[title of column to hold constant]" "[title of another column to hold constant]" [etc.] > [output table path]`_

- [`combine_columns.pl`](/tables/combine_columns.pl): Combines each selected pair of columns into one column with all values. Does not merge values. See script for example inputs and outputs.

   _Usage: `perl combine_columns.pl [input table] [list of tab-separated groups of titles of columns to combine, one group per line] > [output table path]`_

- [`merge_columns.pl`](/tables/merge_columns.pl): Merges selected columns. Reports any conflicts.

   _Usage: `perl merge_columns.pl [table to merge] "[title of column to merge]" "[title of another column to merge]" "[title of another column to merge]" [etc.] > [output table path]`_

- [`merge_columns_with_conflict_detail_column.pl`](/tables/merge_columns_with_conflict_detail_column.pl): Merges selected columns. Reports any conflicts.

   _Usage: `perl merge_columns_with_conflict_detail_column.pl [table to merge] "[title of column to print in merge conflict message]" "[title of column to merge]" "[title of another column to merge]" "[title of another column to merge]" [etc.] > [output table path]`_

- [`add_column_with_number_occurrences_of_column_values.pl`](/tables/add_column_with_number_occurrences_of_column_values.pl): Adds column indicating number occurrences of that row's value(s) in the entirety of the parameter column(s).

   _Usage: `perl add_column_with_number_occurrences_of_column_values.pl [tab-separated table] "[column title]" "[optional additional column title]" "[optional additional column title]" [etc.] > [output table path]`_

- [`replace_values_in_columns.pl`](/tables/replace_values_in_columns.pl): Replaces query with replacement text in specified columns.

   _Usage: `perl replace_values_in_columns.pl [table] "[query text to replace]" "[replacement text]" [1 to exactly match full column value only, 0 to allow search and replace within text of column value] "[title of column to search]" "[title of another column to search]" "[title of another column to search]" [etc.] > [output table path]`_

- [`delete_values_in_columns.pl`](/tables/delete_values_in_columns.pl): Deletes query in specified columns.

   _Usage: `perl delete_values_in_columns.pl [table] "[query text to delete]" # [1 to exactly match full column value only, 0 to allow search within text of column value] "[title of column to search]" "[title of another column to search]" "[title of another column to search]" [etc.] > [output table path]`_

- [`replace_nonempty_values_in_columns.pl`](/tables/replace_nonempty_values_in_columns.pl): Replaces non-empty values with replacement text in specified columns.

   _Usage: `perl replace_nonempty_values_in_columns.pl [table] "[replacement text]" "[title of column to search]" "[title of another column to search]" "[title of another column to search]" [etc.] > [output table path]`_

- [`replace_values_with_coded_values.pl`](/tables/replace_values_with_coded_values.pl): Replaces non-empty values with coded values, e.g., Value 1 (for the most common value), Value 2 (for the second-most common value), Value 3, etc. Ties are broken alphabetically.

   _Usage: `perl replace_values_with_coded_values.pl [table] "[title of column to search]" "[optional code prefix]" > [output table path]`_

- [`bulk_replace_in_one_column.pl`](/tables/bulk_replace_in_one_column.pl): Replaces all occurrences of values in selected column to mapped replacement values.

   _Usage: `perl bulk_replace_in_one_column.pl [tab-separated file mapping current values (first column) to new values (second column)] [path of table in which to replace values] [title of column to replace values in] > [output table path]`_

- [`add_to_start_and_end_of_values_in_columns.pl`](/tables/add_to_start_and_end_of_values_in_columns.pl): Pads non-empty values in specified columns with parameter start and end text.

   _Usage: `perl add_to_start_and_end_of_values_in_columns.pl [table] "[text to add to start of each column value]" "[text to add to end of each column value]" "[title of column to search]" "[title of another column to search]" "[title of another column to search]" [etc.] > [output table path]`_

- [`add_to_start_and_end_of_values_containing_query_in_columns.pl`](/tables/add_to_start_and_end_of_values_containing_query_in_columns.pl): Pads values containing query in specified columns with parameter start and end text.

   _Usage: `perl add_to_start_and_end_of_values_containing_query_in_columns.pl [table] "[query text]" "[text to add to start of each column value]" "[text to add to end of each column value]" "[title of column to search]" "[title of another column to search]" "[title of another column to search]" [etc.] > [output table path]`_

- [`change_capitalization_in_columns.pl`](/tables/change_capitalization_in_columns.pl): Changes capitalization of values in specified columns: all capitalized, all lowercase, or first letter capitalized.

   _Usage: `perl change_capitalization_in_columns.pl [table] [uc to make all values uppercase, lc to make all values lowercase, first to capitalize first letter] "[title of column to capitalize]" "[title of another column to capitalize]" "[title of another column to capitalize]" [etc.] > [output table path]`_

- [`fill_in_empty_column_values.pl`](/tables/fill_in_empty_column_values.pl): Fills in empty values in column of interest with specified value.

   _Usage: `perl fill_in_empty_column_values.pl [table] "[title of column to fill in]" "[value to replace empty values with]" > [output table path]`_

- [`fill_in_empty_column_values_with_increasing_numerical_index.pl`](/tables/fill_in_empty_column_values_with_increasing_numerical_index.pl): Fills in empty values in column of interest with an increasing numerical index value, so that every empty cell contains a unique numerical value.

   _Usage: `perl fill_in_empty_column_values_with_increasing_numerical_index.pl [table] "[title of column to fill in]" > [output table path]`_

- [`fill_in_empty_column_values_from_other_column.pl`](/tables/fill_in_empty_column_values_from_other_column.pl): Fills in empty values in column of interest with values from other column.

   _Usage: `perl fill_in_empty_column_values_from_other_column.pl [table] "[title of column to fill in]" "[title of column with potential replacement values]" > [output table path]`_

- [`replace_column_values_with_other_column_where_present.pl`](/tables/replace_column_values_with_other_column_where_present.pl): Fills in values in column of interest with values from other column when they are present.

   _Usage: `perl replace_column_values_with_other_column_where_present.pl [table] "[title of column to fill in]" "[title of column with potential replacement values]" > [output table path]`_

- [`replace_column_values_where_other_column_present_and_nonzero.pl`](/tables/replace_column_values_where_other_column_present_and_nonzero.pl): In rows where a column has a present, non-zero value, replaces value in another column with parameter replacement value.

   _Usage: `perl replace_column_values_where_other_column_present_and_nonzero.pl [table] "[title of column to check]" "[title of column to fill in]" "[replacement value]" > [output table path]`_

- [`remove_nonunique_values_in_list_in_column.pl`](/tables/remove_nonunique_values_in_list_in_column.pl): Removes non-unique values in comma-separated lists in specified columns.

   _Usage: `perl remove_nonunique_values_in_list_in_column.pl [table] "[column title]" "[another column title]" "[another column title]" [etc.] > [output table path]`_

- [`retrieve_subset_of_columns.pl`](/tables/retrieve_subset_of_columns.pl): Subsets table to only columns of interest.

   _Usage: `perl retrieve_subset_of_columns.pl [table] "[title of first column to include in output]" "[title of second column to include]" "[title of third column to include]" [etc.] > [output table path]`_

- [`retrieve_subset_of_columns_by_column_number.pl`](/tables/retrieve_subset_of_columns_by_column_number.pl): Subsets table to only columns of interest.

   _Usage: `perl retrieve_subset_of_columns_by_column_number.pl [table] [column number of first column to include in output] [column number of second column to include] [etc.] > [output table path]`_

- [`compile_values_and_titles_in_selected_columns.pl`](/tables/compile_values_and_titles_in_selected_columns.pl): Generates a new column with the values in selected columns and their column titles, where values are present.

   _Usage: `perl compile_values_and_titles_in_selected_columns.pl [tab-separated table] "[column title]" "[another column title]" [etc.] > [output table path]`_

- [`condense_list_values_into_one_item.pl`](/tables/condense_list_values_into_one_item.pl): For any values in specified columns that are comma-separated lists, replaces comma-separated list with the first, smallest, or largest value in the list.

   _Usage: `perl condense_list_values_into_one_item.pl [table] [0 to use the first value, 1 to use the smallest value, 2 to use the greatest value] "[title of column to replace lists in]" "[title of another column to replace lists in]" "[title of another column to replace lists in]" [etc.] > [output table path]`_

- [`replace_values_with_column_proportions.pl`](/tables/replace_values_with_column_proportions.pl): Calculates sum of each column containing numerical values. Replaces values in column with the proportion of its sum.

   _Usage: `perl replace_values_with_column_proportions.pl [tab-separated table] > [output table path]`_

- [`add_filename_column_from_filepath_column.pl`](/tables/add_filename_column_from_filepath_column.pl): Retrieves filepaths from specified column (or first column by default). Adds new column with filenames retrieved from these filepaths.

   _Usage: `perl add_filename_column_from_filepath_column.pl [table to add new column to] [optional title of column containing filepaths (if not provided, uses first column)] [optional 1 to remove all file extensions in output filenames (such that filename contains no .s)] > [output table path]`_

- [`add_column_comparing_two_columns.pl`](/tables/add_column_comparing_two_columns.pl): Adds a column indicating whether or not there is a difference between two columns.

   _Usage: `perl add_column_comparing_two_columns.pl [tab-separated table] "[title of first column to compare]" "[title of second column to compare]" [1 to print the actual values when different] "[optional new column title]" "[optional new column value if values are identical]" "[optional new column value if values are different]" "[optional new column value if one value missing]" "[optional new column value if both values missing]" > [output table path]`_

- [`replace_column_values_with_other_column_where_yet_another_column_has_query_value.pl`](/tables/replace_column_values_with_other_column_where_yet_another_column_has_query_value.pl): Fills in values in column of interest with values from other column when they are present.

   _Usage: `perl replace_column_values_with_other_column_where_yet_another_column_has_query_value.pl [table] "[title of column to replace values in]" "[title of column with potential replacement values]" "[title of column to search]" "[query value]" > [output table path]`_

- [`split_column_after_query.pl`](/tables/split_column_after_query.pl): Splits column into two columns following appearance of query in each column value. If a cell does not contain the query, duplicates the column value.

   _Usage: `perl split_column_after_query.pl [table] "[column name]" "[query]" > [output table path]`_

- [`add_column_with_filename.pl`](/tables/add_column_with_filename.pl): Adds column with table filename in all values.

   _Usage: `perl add_column_with_filename.pl [table to add column to] > [output table path]`_

### Column manipulation with dates

- [`dates_in_columns_to_YYYY_MM_DD.pl`](/tables/dates_in_columns_to_YYYY_MM_DD.pl): Converts dates in specified columns to YYYY-MM-DD format. Multiple dates may be separated by a ", ". Column titles must not have spaces.

   _Usage: `perl dates_in_columns_to_YYYY_MM_DD.pl [table] "[title of column with dates]" "[title of another column with dates]" "[title of another column with dates]" [etc.] > [output table path]`_

- [`add_difference_in_dates_column.pl`](/tables/add_difference_in_dates_column.pl): Adds column listing difference in dates (in days) between columns specified in parameter column titles. Dates must be in YYYY-MM-DD format.

   _Usage: `perl add_difference_in_dates_column.pl [table] "[title of column with dates]" "[title of another column with dates]" "[optional title of new column]" > [output table path]`_

- [`add_earliest_or_latest_date_column.pl`](/tables/add_earliest_or_latest_date_column.pl): Adds column listing the latest or earliest of the specified columns. Dates must be in YYYY-MM-DD format.

   _Usage: `perl add_earliest_or_latest_date_column.pl [table] [0 to select earliest date, 1 to select latest date] "[title of column with dates]" "[title of another column with dates]" "[title of another column with dates]" [etc.] > [output table path]`_

- [`add_column_with_earliest_or_latest_date_before_cutoff.pl`](/tables/add_column_with_earliest_or_latest_date_before_cutoff.pl): Adds column listing the date that is the latest or earliest of the specified columns but earlier than the cut-off date from the cut-off date column. Dates must be in YYYY-MM-DD format.

   _Usage: `perl add_column_with_earliest_or_latest_date_before_cutoff.pl [table] [0 to select earliest date, 1 to select latest date] "[title of column with cut-off date]" "[title of column with dates to select from]" "[title of another column with dates to select from]" "[title of another column with dates to select from]" [etc.] > [output table path]`_

- [`sort_date_columns.pl`](/tables/sort_date_columns.pl): Sorts the dates in the specified columns. For each row, of the dates in the specified columns, the earliest date will go in the first specified column, the second-earliest in the second specified column, etc. Empty values go last. Dates provided must be in YYYY-MM-DD format.

   _Usage: `perl sort_date_columns.pl [table] "[title of column with dates]" "[title of another column with dates]" "[title of another column with dates]" [etc.] > [output table path]`_

- [`sort_date_columns_with_paired_label_columns.pl`](/tables/sort_date_columns_with_paired_label_columns.pl): Sorts the dates in the specified columns. For each row, of the dates in the specified columns, the earliest date will go in the first specified column, the second-earliest in the second specified column, etc. Empty values go last. Dates provided must be in YYYY-MM-DD format.

   _Usage: `perl sort_date_columns_with_paired_label_columns.pl [table] "[title of column with dates]" "[title of label column that should travel with paired dates]" "[title of another column with dates]" "[title of label column that should travel with those paired dates]" [etc.] > [output table path]`_

### Row manipulation

- [`filter_table_rows_by_column_value.pl`](/tables/filter_table_rows_by_column_value.pl): Filters table by column values. Only includes rows matching (containing, beginning with, ending with, equal to, not equal to, or not containing) column value of interest in column to filter by. Case-sensitive.

   _Usage: `perl filter_table_rows_by_column_value.pl [tab-separated table] [0 to match cells containing query, 1: beginning with, 2: ending with, 3: equal to, 4: not equal to, 5: not containing] "[title of column to filter by]" "[column value to select]" > [output table path]`_

- [`filter_table_rows_by_column_values.pl`](/tables/filter_table_rows_by_column_values.pl): Filters table by column values. Only includes rows matching (containing, beginning with, ending with, equal to, not equal to, or not containing) column values of interest in column to filter by. Case-sensitive.

   _Usage: `perl filter_table_rows_by_column_values.pl [tab-separated table] [0 to match cells containing query, 1: beginning with, 2: ending with, 3: equal to] "[title of column to filter by]" "[column value to select]" "[another column value to select]" "[etc.]" > [output table path]`_

- [`filter_table_rows_by_numerical_column_value.pl`](/tables/filter_table_rows_by_numerical_column_value.pl): Filters table by column values. Only includes rows equal to, greater than, or less than column value of interest in column to filter by.

   _Usage: `perl filter_table_rows_by_numerical_column_value.pl [tab-separated table] [0 to match cells equal to query, 1: less than, 2: less than or equal to, 3: greater than, 4: greater than or equal to] "[title of column to filter by]" "[column value to select]" > [output table path]`_

- [`retrieve_subset_of_rows.pl`](/tables/retrieve_subset_of_rows.pl): Subsets table to only rows of interest (those containing one of the specified values in the specified column).

   _Usage: `perl retrieve_subset_of_rows.pl [file path of table] "[title of column to filter by]" [file path of list of values to filter that column to] > [output table path]`_

- [`delete_table_rows_with_column_value.pl`](/tables/delete_table_rows_with_column_value.pl): Deletes rows in table by column values. Only includes rows without column value containing text to filter out in column to filter by. Case-sensitive.

   _Usage: `perl delete_table_rows_with_column_value.pl [tab-separated table] "[query to select rows to delete]" [0 to match cells containing query, 1: beginning with, 2: ending with, 3: equal to] "[title of column to filter by]" > [output table path]`_

- [`merge_rows_by_column_value.pl`](/tables/merge_rows_by_column_value.pl): Merges (takes union of) all columns in rows with shared value in column to merge by. If titles of columns not to merge by are provided, leaves one row per input row with all other columns identical. If no columns not to merge by provided, fully merges any rows sharing a value in column to merge by (one row per value).

   _Usage: `perl merge_rows_by_column_value.pl [table to merge] "[title of column to merge by]" "[optional title of column not to merge]" "[optional title of another column not to merge]" [etc.] > [output table path]`_

- [`verify_all_rows_in_one_table_appear_in_second_table.pl`](/tables/verify_all_rows_in_one_table_appear_in_second_table.pl): Verifies that all rows/lines in table 1 also appear in table 2 (that table 2 is a superset of table 1). Prints all rows from table 1 that are missing from table 2. If column numbers is specified, only compares values from that column.

   _Usage: `perl verify_all_rows_in_one_table_appear_in_second_table.pl [subset table] [superset table] [column number to compare--set to -1 to compare full row] > [output list of missing rows]`_

- [`fill_in_missing_rows.pl`](/tables/fill_in_missing_rows.pl): Catalogues all values in parameter columns. In any combination of values is missing, adds it as a row with NAs in all other columns.

   _Usage: `perl fill_in_missing_rows.pl [table] "[title of column of interest 1]"" "[title of column of interest 2]" etc. > [output table path]`_

### Table manipulation

- [`concatenate_tables.pl`](/tables/concatenate_tables.pl): Concatenates tables with potentially different columns, adding empty space for missing column values.

   _Usage: `perl concatenate_tables.pl [table1] [table2] [table3] etc. > [concatenated output table path]`_

- [`add_columns_from_other_table.pl`](/tables/add_columns_from_other_table.pl): Adds columns from another table, matching rows in the two tables by selected columns to merge by.

   _Usage: `perl add_columns_from_other_table.pl [table to add columns to] "[title of column in first table to identify rows by]" [table to add columns from] "[title of column in second table to identify rows by]" "[title of column to add]" "[title of another column to add]" [etc.] > [output table path]`_

- [`merge_two_tables_by_column_value.pl`](/tables/merge_two_tables_by_column_value.pl): Merges (takes union of) two tables by the values in the specified columns.

   _Usage: `perl merge_two_tables_by_column_value.pl [table1 file path] [table1 column number (0-indexed)] [table2 file path] [table2 column number (0-indexed)] > [output table path]`_

- [`merge_tables_by_column_value.pl`](/tables/merge_tables_by_column_value.pl): Merges (takes union of) multiple tables by the values in the specified columns. See script for description of input file.

   _Usage: `perl merge_tables_by_column_value.pl [file describing input] > [merged output table path]`_

- [`merge_tables_by_first_column_values.pl`](/tables/merge_tables_by_first_column_values.pl): Merges (takes union of) multiple tables by the values in the first column.

   _Usage: `perl merge_tables_by_first_column_values.pl [table] [another table] [another table] [etc.] > [merged output table path]`_

- [`add_newline_between_lines_with_nonconsecutive_values.pl`](/tables/add_newline_between_lines_with_nonconsecutive_values.pl): Adds newline between lines containing non-consecutive values in first column.

   _Usage: `perl add_newline_between_lines_with_nonconsecutive_values.pl [table] [column with integer values] > [output table path]`_

- [`add_header_line_to_tables.pl`](/tables/add_header_line_to_tables.pl): Adds header line to all input files. Saves output tables in new files at same path with _with_header_line.txt extension. Four spaces in the input header line are replaced with tabs.

   _Usage: `perl add_header_line_to_tables.pl "[header line]" [table] [optional additional table] [etc.]`_

- [`split_table_by_column_value.pl`](/tables/split_table_by_column_value.pl): Splits table into multiple tables, one for each column value in specified column.

   _Usage: `perl split_table_by_column_value.pl [input table file path] "[title of column to split by]"`_

### Replicates

- [`annotate_replicates.pl`](/tables/annotate_replicates.pl): Assigns a source number to all replicates from the same source. Adds source number as a column to table to annotate.

   _Usage: `perl annotate_replicates.pl [file listing replicate ids from same source, tab-separated, one line per source] [table to annotate] "[title of column containing replicate ids in table to annotate]" "[optional source column title for output]" > [annotated output table path]`_

- [`select_one_replicate.pl`](/tables/select_one_replicate.pl): Given a table with multiple replicates from the same source, selects one replicate per source, using selected column to select replicate. In the event of a tie, selects first appearing replicate.

   _Usage: `perl select_one_replicate.pl [tab-separated table] "[title of column containing source of each replicate (same value for every replicate from the same source)]" "[title of column to use to select replicate]" [0 to select replicate with smallest numerical value, 1 to select replicate with largest numerical value] > [annotated output table path]`_

- [`add_shared_values_summary_column.pl`](/tables/add_shared_values_summary_column.pl): Summarizes all values appearing in columns to summarize (sample ids and dates, for example) for each shared value (patient id, for example). Adds summary in new column.

   _Usage: `perl add_shared_values_summary_column.pl [tab-separated table] "[title of column containing values shared by rows]" "[title of column to include in summary of shared values]" "[title of another column to include in summary of shared values]" [etc.] > [output table path]`_

### Other

- [`summarize_table_columns.pl`](/tables/summarize_table_columns.pl): Summarizes values in table columns. Similar to str in R.

   _Usage: `perl summarize_table_columns.pl [tab-separated table] > [output table path]`_

- [`summarize_column_value_combination_frequencies.pl`](/tables/summarize_column_value_combination_frequencies.pl): Summarizes frequency of all column values and combinations of column values in columns of interest in table.

   _Usage: `perl summarize_column_value_combination_frequencies.pl [table to summarize] "[title of column of interest]" "[optional title of another column of interest]" "[optional title of another column of interest]" [etc.] > [output table path]`_

- [`add_column_indicating_presence_of_query.pl`](/tables/add_column_indicating_presence_of_query.pl): Adds column with values indicating presence of query in row.

   _Usage: `perl add_column_indicating_presence_of_query.pl [table] [query] > [output table path]`_

- [`add_row_indicating_presence_of_query.pl`](/tables/add_row_indicating_presence_of_query.pl): Adds row with values indicating presence of query in column.

   _Usage: `perl add_row_indicating_presence_of_query.pl [table] [query] > [output table path]`_

- [`count_occurrences_of_column_values.pl`](/tables/count_occurrences_of_column_values.pl): Counts number occurrences of each value in selected column of table.

   _Usage: `perl count_occurrences_of_column_values.pl [tab-separated table] "[column title]" > [output table path]`_

- [`verify_column_values_are_consistent_across_tables.pl`](/tables/verify_column_values_are_consistent_across_tables.pl): Verifies that the same column values always appear with row identifier values. Column titles must be consistent across tables, including title of row identifier column.

   _Usage: `perl verify_column_values_are_consistent_across_tables.pl [row identifier column title] [table1] [table2] [table 3] [etc.]`_

- [`calculate_date_range_in_column.pl`](/tables/calculate_date_range_in_column.pl): Prints minimum date, maximum date, and difference in dates (in days) in specified column in each input files. Dates must be in YYYY-MM-DD format.

   _Usage: `perl calculate_date_range_in_column.pl [column number of column with dates (0-indexed)] [table] [another table] [another table] [etc.]`_

## Miscellaneous ([`misc`](/misc))
- [`add_commas_to_all_numbers_in_file.pl`](/misc/add_commas_to_all_numbers_in_file.pl): Detects all numbers in contents of file and adds thousands-separator commas where needed.

   _Usage: `perl add_commas_to_all_numbers_in_file.pl [input file to add commas to] > [output file path]`_

- [`add_commas_to_all_numbers.pl`](/misc/add_commas_to_all_numbers.pl): Detects all numbers in input text and adds thousands-separator commas where needed.

   _Usage: `perl add_commas_to_all_numbers.pl "[text to add commas to]" > [output file path]`_

- [`run_script_on_multiple_files.pl`](/misc/run_script_on_multiple_files.pl): Runs script individually on multiple input files, otherwise using the same input parameters. Script must accept input file as first parameter.

   _Usage: `perl run_script_on_multiple_files.pl [file path of script to run] [file with list of input files to run script on] [optional extension to add to input file path to create output file path] [optional second parameter to provide script] [optional third parameter to provide script] [etc.]`_

- [`summarize_files.pl`](/misc/summarize_files.pl): Summarizes files. Generates table with filepath, filename, filename with extensions trimmed off, and number lines, words, and characters in the file.

   _Usage: `perl summarize_files.pl [file with list of files to summarize, one per line] > [output file path]`_

- [`download_files.pl`](/misc/download_files.pl): Downloads files listed in input file from online or from google storage bucket.

   _Usage: `perl download_files.pl [file with list of files to download] [optional output directory]`_

- [`download_files_listed_in_table_column.pl`](/misc/download_files_listed_in_table_column.pl): Downloads files from addresses listed in specified table column in input table. Downloads files from online or from google storage bucket to new directory. If no output directory provided, output directory set to input file path sans extension followed by column name.

   _Usage: `perl download_files_listed_in_table_column.pl [table with list of files to download in one of the columns] "[title of column containing filepaths to download]" [optional output directory]`_

- [`download_and_rename_files.pl`](/misc/download_and_rename_files.pl): Downloads files listed in input file from online or from google storage bucket to new directory and renames to specified filename.

   _Usage: `perl download_and_rename_files.pl [file with list of files to download] [optional output directory]`_

- [`retrieve_all_filepaths_in_directories.pl`](/misc/retrieve_all_filepaths_in_directories.pl): Retrieves filepaths of all files in provided directories.

   _Usage: `perl retrieve_all_filepaths_in_directories.pl [directory path] [another directory path] [another directory path] [etc.] > [output file path]`_

- [`bulk_diff_same_name_files_in_two_directories.pl`](/misc/bulk_diff_same_name_files_in_two_directories.pl): Compares all files with the same name in the two input directories. Prints any differences between same-name files. The two directories must contain files with the same names.

   _Usage: `perl bulk_diff_same_name_files_in_two_directories.pl [first directory] [second directory]`_

- [`combine_files_and_delete_duplicate_lines.pl`](/misc/combine_files_and_delete_duplicate_lines.pl): Combines input files. Prints each line only once (no duplicate lines). Prints lines in order in which they first appear in all the input files.

   _Usage: `perl combine_files_and_delete_duplicate_lines.pl [input file] [another input file] [another input file] [etc.] > [output table path]`_

- [`bulk_rename.pl`](/misc/bulk_rename.pl): Replaces all occurrences of values in file paths to mapped replacement values. Values to replace should not overlap or be substrings of each other. Files already at replacement paths will be overwritten. Paths of files to rename can be provided directly as arguments or as one file with a list of filepaths, one per line.

   _Usage: `perl bulk_rename.pl [tab-separated file mapping current values (first column) to new values (second column)] [filepaths of at least two files to rename OR path of file containing filepaths of files to rename, one per line]`_

- [`bulk_grep.pl`](/misc/bulk_grep.pl): Searches all input files for queries listed in query list file.

   _Usage: `perl bulk_grep.pl [file listing queries, one per line] [file to grep] [another file to grep] [etc.] > [output file path]`_

- [`bulk_grep_one_file.pl`](/misc/bulk_grep_one_file.pl): Searches input file for queries. Prints lines containing queries.

   _Usage: `perl bulk_grep_one_file.pl [file to grep] "[query 1]" "[query 2]" "[query 3]" [etc.] > [output file path]`_

- [`bulk_grep_is_detected.pl`](/misc/bulk_grep_is_detected.pl): Searches all input files for queries listed in query list file. Outputs query and each file it was found in, tab-separated, one line per query-file pair where query is detected. If query is not detected in any file, prints query followed by "not detected".

   _Usage: `perl bulk_grep_is_detected.pl [file listing queries, one per line] [file to grep] [another file to grep] [etc.] > [output file path]`_

- [`bulk_grep_is_detected_table.pl`](/misc/bulk_grep_is_detected_table.pl): Searches all input files for queries listed in query list file. Outputs a table with detection of all queries in all files, tab-separated, one row per query, one column per file.

   _Usage: `perl bulk_grep_is_detected_table.pl [file listing queries, one per line] [file to grep] [another file to grep] [etc.] > [output file path]`_

- [`split_file_into_n_files.pl`](/misc/split_file_into_n_files.pl): Splits file with multiple lines up into a number of smaller files, each with about the same number of lines.

   _Usage: `perl split_file_into_n_files.pl [file path]  [number output files to generate]`_
  
- [`split_file_into_2n_overlapping_files.pl`](/misc/split_file_into_2n_overlapping_files.pl): Splits file with multiple lines up into a number of overlapping smaller files. Each line will appear in two files. Either all output files will have about the same number of lines, or there will be two "jagged" half-sized output files if it is a priority for all output files to only have lines that are consecutive in the input. See script for example input and output.

   _Usage: `perl split_file_into_2n_overlapping_files.pl [file path] [number equal slices (n)] [1 to generate N=2*n approximately equal sized files, 0 to generate N=2*n+1 output files with lines that are also consecutive in the input] [optional 1 to NOT print half-sized overhang files (can be used only if previous option is set to 0)]`_

- [`split_file_into_overlapping_files_by_date.pl`](/misc/split_file_into_overlapping_files_by_date.pl): Splits file with multiple lines up into overlapping smaller files, each containing dates within twice the parameter number of days. Each line will appear in two files.

   _Usage: `perl split_file_into_overlapping_files_by_date.pl [file path] [half the date range in each output file] [column containing dates, 0-indexed]`_

- [`erase_empty_files.pl`](/misc/erase_empty_files.pl): Erases empty files.

   _Usage: `perl erase_empty_files.pl [file to check and potentially erase] [another file to check and potentially erase] [a third file to check and potentially erase] etc.`_

- [`bulk_delete_files_in_list.pl`](/misc/bulk_delete_files_in_list.pl): Deletes files in input list.

   _Usage: `perl bulk_delete_files_in_list.pl [file containing list of paths of files to delete, one per line]`_

- [`bulk_move_files_in_list.pl`](/misc/bulk_move_files_in_list.pl): Moves files in input list to provided directory.

   _Usage: `perl bulk_move_files_in_list.pl [file containing list of paths of files to move, one per line] [directory to move files to]`_

- [`match_file_paths_to_sample_names.pl`](/misc/match_file_paths_to_sample_names.pl): Matches each sample name to a file path containing that sample name. Outputs sample names with file paths, tab-separated, one sample per line.

   _Usage: `perl match_file_paths_to_sample_names.pl [file containing list of sample names, one per line] [file containing list of file paths, one per line] > [output table path]`_

- [`combine_files_and_delete_duplicate_lines.pl`](/misc/combine_files_and_delete_duplicate_lines.pl): Combines input files. Prints each line only once (no duplicate lines). Prints lines in order in which they first appear in all the input files.

   _Usage: `perl combine_files_and_delete_duplicate_lines.pl [input file] [another input file] [another input file] [etc.] > [output table path]`_

- [`select_random_lines.pl`](/misc/select_random_lines.pl): Selects a certain number of lines at random from input table or list.

   _Usage: `perl select_random_lines.pl [table or list] [number rows or lines to select at random] > [output table or list]`_


More coming soon :)
