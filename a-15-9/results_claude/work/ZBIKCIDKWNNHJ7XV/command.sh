# Load required libraries
library(WGCNA)

# Set output directory
output_dir <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516"

# Load data files
pheno <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/data/Pheno.csv", row.names=1)
protein <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/data/protein.csv", row.names=1)
rna <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/data/rna.csv", row.names=1)

# Transpose protein and RNA matrices so samples are rows
protein_t <- t(protein)
rna_t <- t(rna)

# Add prefixes to distinguish protein and RNA features
colnames(protein_t) <- paste0("Protein_", colnames(protein_t))
colnames(rna_t) <- paste0("RNA_", colnames(rna_t))

# Combine by row-binding features (column-binding samples with all features)
combined_data <- cbind(protein_t, rna_t)

# Ensure sample alignment with phenotype data
common_samples <- intersect(rownames(combined_data), rownames(pheno))
combined_data <- combined_data[common_samples, ]
pheno_aligned <- pheno[common_samples, , drop=FALSE]

# Print data dimensions for verification
cat("Combined data dimensions:", dim(combined_data), "\n")
cat("Phenotype data dimensions:", dim(pheno_aligned), "\n")
cat("Number of aligned samples:", length(common_samples), "\n")

# Save prepared data for WGCNA analysis
write.csv(combined_data, file.path(output_dir, "combined_expression_data.csv"))
write.csv(pheno_aligned, file.path(output_dir, "aligned_phenotype_data.csv"))

cat("Data preparation completed. Files saved:\n")
cat("- combined_expression_data.csv: samples as rows, features as columns\n")
cat("- aligned_phenotype_data.csv: aligned phenotype data\n")
