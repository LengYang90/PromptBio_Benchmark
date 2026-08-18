# Load required libraries (omicwas already installed in previous step)
library(data.table)
library(dplyr)

# Define base path
base_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516"

# Read all data matrices
snp_geno <- read.csv(file.path(base_path, "data/Matrix_of_SNP_genotypes.csv"), row.names = 1)
methylation <- read.csv(file.path(base_path, "data/Matrix_of_bulk_omics_measurements.csv"), row.names = 1)
methylation_pos <- read.csv(file.path(base_path, "data/Matrix_of_bulk_omics_positions.csv"), row.names = 1)
snp_pos <- read.csv(file.path(base_path, "data/Matrix_of_trait_positions.csv"), row.names = 1)
cell_comp <- read.csv(file.path(base_path, "data/Matrix_of_cell_type_composition.csv"), row.names = 1)
covariates <- read.csv(file.path(base_path, "Matrix_of_covariates_corrected.csv"), row.names = 1)

# Inspect the structure of position files to understand column names
print("SNP position file structure:")
print(head(snp_pos))
print(colnames(snp_pos))

print("Methylation position file structure:")
print(head(methylation_pos))
print(colnames(methylation_pos))

# Transpose matrices to ensure proper format for ctcisQTL
# SNPs: samples as rows, features as columns
snp_geno_t <- t(snp_geno)

# Methylation: samples as rows, features as columns  
methylation_t <- t(methylation)

# Ensure sample alignment
common_samples <- intersect(intersect(rownames(snp_geno_t), rownames(methylation_t)), 
                           intersect(rownames(cell_comp), rownames(covariates)))

print(paste("Found", length(common_samples), "common samples"))

# Filter all matrices to common samples
snp_geno_final <- snp_geno_t[common_samples, ]
methylation_final <- methylation_t[common_samples, ]
cell_comp_final <- cell_comp[common_samples, ]
covariates_final <- covariates[common_samples, ]

# Create position data frames with proper format using actual column names
# Use the first two columns as CHR and POS if column names are not as expected
if(ncol(snp_pos) >= 2) {
  snp_pos_df <- data.frame(
    SNP = rownames(snp_pos),
    CHR = snp_pos[,1],  # Use first column as CHR
    POS = snp_pos[,2]   # Use second column as POS
  )
} else {
  # If only one column, assume it's position and create dummy chromosome
  snp_pos_df <- data.frame(
    SNP = rownames(snp_pos),
    CHR = rep(1, nrow(snp_pos)),
    POS = snp_pos[,1]
  )
}

if(ncol(methylation_pos) >= 2) {
  methylation_pos_df <- data.frame(
    CpG = rownames(methylation_pos),
    CHR = methylation_pos[,1],  # Use first column as CHR
    POS = methylation_pos[,2]   # Use second column as POS
  )
} else {
  # If only one column, assume it's position and create dummy chromosome
  methylation_pos_df <- data.frame(
    CpG = rownames(methylation_pos),
    CHR = rep(1, nrow(methylation_pos)),
    POS = methylation_pos[,1]
  )
}

# Save formatted matrices
write.csv(snp_geno_final, file.path(base_path, "snp_genotypes_formatted.csv"))
write.csv(methylation_final, file.path(base_path, "methylation_formatted.csv"))
write.csv(cell_comp_final, file.path(base_path, "cell_composition_formatted.csv"))
write.csv(covariates_final, file.path(base_path, "covariates_formatted.csv"))
write.csv(snp_pos_df, file.path(base_path, "snp_positions_formatted.csv"), row.names = FALSE)
write.csv(methylation_pos_df, file.path(base_path, "methylation_positions_formatted.csv"), row.names = FALSE)

print(paste("Formatted matrices for", length(common_samples), "common samples"))
print(paste("SNP matrix:", nrow(snp_geno_final), "samples x", ncol(snp_geno_final), "SNPs"))
print(paste("Methylation matrix:", nrow(methylation_final), "samples x", ncol(methylation_final), "CpGs"))
print(paste("Cell composition matrix:", nrow(cell_comp_final), "samples x", ncol(cell_comp_final), "cell types"))
print(paste("Covariates matrix:", nrow(covariates_final), "samples x", ncol(covariates_final), "covariates"))

print("Position data frames created:")
print(paste("SNP positions:", nrow(snp_pos_df), "entries"))
print(paste("Methylation positions:", nrow(methylation_pos_df), "entries"))
