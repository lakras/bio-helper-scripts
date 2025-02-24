#!/usr/bin/env Rscript

# Midpoint roots the input tree.

# Usage:
# Rscript midpoint_root_tree.R [newick tree]

# Prints to console. To print to file, use
# Rscript midpoint_root_tree.R [newick tree] > [output tree]


library(ape)
library(phangorn)


args <- commandArgs(trailingOnly = TRUE)
tree_file <- args[1] # newick tree

tree <- read.tree(tree_file)
tree <- midpoint(tree)

cat(write.tree(tree), "\n")


# February 24, 2025
