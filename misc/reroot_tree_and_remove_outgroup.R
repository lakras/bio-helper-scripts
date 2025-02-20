#!/usr/bin/env Rscript

# Reroots the input tree using the input outgroup, then removes the outgroup node from
# the tree.

# Usage:
# Rscript reroot_tree_and_remove_outgroup.R [newick tree] [outgroup name]

# Prints to console. To print to file, use
# Rscript reroot_tree_and_remove_outgroup.R [newick tree] [outgroup name] > [output tree]


library(ape)


args <- commandArgs(trailingOnly = TRUE)
tree_file <- args[1] # newick tree
outgroup <- args[2] # outgroup name

tree <- read.tree(tree_file)
tree <- root(tree, outgroup, resolve.root = TRUE)
tree <- drop.tip(tree, outgroup)

cat(write.tree(tree), "\n")


# February 20, 2025
