# Install and load required libraries
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install omicwas from CRAN
if (!require("omicwas", quietly = TRUE)) {
  tryCatch({
    install.packages("omicwas")
  }, error = function(e) {
    # If CRAN installation fails, try BiocManager
    if (!require("BiocManager", quietly = TRUE)) {
      install.packages("BiocManager")
    }
    BiocManager::install("omicwas")
  })
}

library(omicwas)
library(data.table)

# Define base path
base_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516"

# Load formatted data matrices
snp_data <- read.csv(file.path(base_path, "snp_genotypes_formatted.csv"), row.names = 1)
methylation_data <- read.csv(file.path(base_path, "methylation_formatted.csv"), row.names = 1)
cell_composition <- read.csv(file.path(base_path, "cell_composition_formatted.csv"), row.names = 1)
covariates <- read.csv(file.path(base_path, "covariates_formatted.csv"), row.names = 1)
cis_pairs <- read.csv(file.path(base_path, "cis_pairs_1mb.csv"))

# Ensure sample alignment
common_samples <- intersect(intersect(rownames(snp_data), rownames(methylation_data)),
                           intersect(rownames(cell_composition), rownames(covariates)))

snp_data <- snp_data[common_samples, ]
methylation_data <- methylation_data[common_samples, ]
cell_composition <- cell_composition[common_samples, ]
covariates <- covariates[common_samples, ]

# Transpose matrices to have samples as columns (required by omicwas)
genotype <- as.matrix(t(snp_data))  # SNPs as rows, samples as columns
methylation <- as.matrix(t(methylation_data))  # CpGs as rows, samples as columns
covariates_matrix <- as.matrix(t(covariates))  # Covariates as rows, samples as columns

# Prepare cis pairs in the correct format (SNP-CpG pairs)
snp_cpg_pairs <- cis_pairs[, c("SNP", "CpG")]

# Initialize results dataframe
mQTL_results <- data.frame()

# Run ctcisQTL for each cell type
cell_types <- c("CD4T", "CD8T", "NK")

for(cell_type in cell_types) {
  print(paste("Running ctcisQTL for cell type:", cell_type))
  
  # Extract cell type proportions and transpose
  celltype_prop <- as.matrix(t(cell_composition[, cell_type, drop = FALSE]))  # Cell props as rows, samples as columns
  
  # Run ctcisQTL analysis with corrected parameter names
  qtl_results <- ctcisQTL(
    genotype = genotype,
    methylation = methylation,
    celltype_prop = celltype_prop,
    covariates = covariates_matrix,
    snp_cpg_pairs = snp_cpg_pairs
  )
  
  # Add cell type information
  qtl_results$celltype <- cell_type
  
  # Append to main results
  mQTL_results <- rbind(mQTL_results, qtl_results)
}

# Format results with required columns
final_results <- mQTL_results[, c("term", "response", "celltype", "estimate", "statistic", "p.value")]

# Save results
write.table(final_results, 
           file.path(base_path, "mQTL_results.tsv"), 
           sep = "\t", 
           row.names = FALSE, 
           quote = FALSE)

print(paste("Analysis completed. Results saved with", nrow(final_results), "associations"))
print("Summary of results:")
print(table(final_results$celltype))
print("First 10 results:")
print(head(final_results, 10))
