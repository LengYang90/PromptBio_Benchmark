# Define paths
data_dir <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_11/toolsgenie_20260623/data/"
out_dir <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_11/toolsgenie_20260623/"

# Load input data
rna <- read.csv(paste0(data_dir, "rna.csv"), row.names = 1, check.names = FALSE)
protein <- read.csv(paste0(data_dir, "protein.csv"), row.names = 1, check.names = FALSE)
pheno <- read.csv(paste0(data_dir, "Pheno.csv"), row.names = 1, check.names = FALSE)

# Inspect data structure
cat("RNA matrix structure:\n")
str(rna)
cat("\nProtein matrix structure:\n")
str(protein)
cat("\nPhenotype data structure:\n")
str(pheno)

# Check sample consistency
samples_rna <- colnames(rna)
samples_protein <- colnames(protein)
samples_pheno <- rownames(pheno)

cat("\nSample consistency check results:\n")
cat(paste0("RNA samples: ", length(samples_rna), "\n"))
cat(paste0("Protein samples: ", length(samples_protein), "\n"))
cat(paste0("Phenotype samples: ", length(samples_pheno), "\n"))
cat(paste0("All RNA samples present in protein: ", all(samples_rna %in% samples_protein), "\n"))
cat(paste0("All protein samples present in RNA: ", all(samples_protein %in% samples_rna), "\n"))
cat(paste0("All omics samples present in phenotype: ", all(samples_rna %in% samples_pheno), "\n"))

# Align samples to common set
common_samples <- intersect(intersect(samples_rna, samples_protein), samples_pheno)
rna_aligned <- rna[, common_samples]
protein_aligned <- protein[, common_samples]
pheno_aligned <- pheno[common_samples, ]

# Combine matrices by row binding
expr_combined <- rbind(rna_aligned, protein_aligned)

# Filter features with >10% missing values
na_pct <- rowMeans(is.na(expr_combined))
expr_filtered <- expr_combined[na_pct <= 0.1, ]

cat(paste0("\nCombined filtered matrix dimensions: ", nrow(expr_filtered), " features, ", ncol(expr_filtered), " samples\n"))

# Save output (formatted for WGCNA: features as rows, samples as columns)
write.csv(expr_filtered, file = paste0(out_dir, "combined_filtered_expression.csv"), row.names = TRUE, quote = FALSE)
write.csv(pheno_aligned, file = paste0(out_dir, "aligned_phenotype.csv"), row.names = TRUE, quote = FALSE)
