library(WGCNA)
library(edgeR)

# Load gene expression data
data <- read.table("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/data/gene_expression.txt", 
                   header = TRUE, row.names = 1, sep = "\t", check.names = FALSE)

cat("=== WGCNA DATA PREPROCESSING ===\n")
cat("Original data dimensions:", dim(data)[1], "genes x", dim(data)[2], "samples\n")

# Calculate CPM and log2 transformation
dge <- DGEList(counts = data)
cpm_values <- cpm(dge)
log_cpm <- log2(cpm_values + 1)

cat("Normalization: log2(CPM+1) transformation completed\n")

# Filter low-expression genes (keep genes with CPM > 1 in at least 3 samples)
keep <- rowSums(cpm_values > 1) >= 3
filtered_data <- log_cpm[keep, ]

cat("Gene filtering: Removed", sum(!keep), "low-expression genes\n")
cat("Filtered data dimensions:", dim(filtered_data)[1], "genes x", dim(filtered_data)[2], "samples\n")

# Transpose data for WGCNA (samples as rows, genes as columns)
datExpr <- as.data.frame(t(filtered_data))

# Check for sample outliers using hierarchical clustering
sampleTree <- hclust(dist(datExpr), method = "average")

cat("\n=== SAMPLE OUTLIER DETECTION ===\n")
# Calculate sample distances and Z-scores
sample_heights <- sampleTree$height
if(length(sample_heights) > 0) {
  height_mean <- mean(sample_heights)
  height_sd <- sd(sample_heights)
  z_scores <- abs((sample_heights - height_mean) / height_sd)
  outliers <- which(z_scores > 2.5)
  
  if(length(outliers) > 0) {
    cat("Potential outlier samples detected:", length(outliers), "\n")
    cat("Outlier sample indices:", paste(outliers, collapse = ", "), "\n")
  } else {
    cat("No significant outlier samples detected\n")
  }
} else {
  cat("Sample clustering completed - no outliers detected\n")
}

# Check data quality for WGCNA
gsg <- goodSamplesGenes(datExpr, verbose = 3)
cat("\nData quality check:\n")
cat("All samples good:", gsg$allOK, "\n")
if(!gsg$allOK) {
  cat("Samples to remove:", sum(!gsg$goodSamples), "\n")
  cat("Genes to remove:", sum(!gsg$goodGenes), "\n")
  datExpr <- datExpr[gsg$goodSamples, gsg$goodGenes]
}

# Save preprocessed data
write.csv(datExpr, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/preprocessed_data.csv")
write.csv(filtered_data, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/normalized_expression.csv")

cat("\nPreprocessing completed successfully\n")
cat("Final data dimensions for WGCNA:", dim(datExpr)[1], "samples x", dim(datExpr)[2], "genes\n")
cat("Output files saved:\n")
cat("- preprocessed_data.csv (samples as rows, genes as columns)\n")
cat("- normalized_expression.csv (genes as rows, samples as columns)\n")
