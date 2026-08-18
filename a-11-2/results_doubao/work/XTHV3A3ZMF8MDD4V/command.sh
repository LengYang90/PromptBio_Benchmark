# Define file paths
input_file <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_11/toolsgenie_20260623/data/gene_expression.txt"
output_file <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_11/toolsgenie_20260623/preprocessed_expression_for_WGCNA.csv"

# Load raw data
expr_raw <- read.table(input_file, header = TRUE, row.names = 1, sep = "", check.names = FALSE)

# Print raw data inspection
cat("=== Raw Data Inspection ===\n")
cat("Total genes (rows):", nrow(expr_raw), "\n")
cat("Total samples (columns):", ncol(expr_raw), "\n")
cat("First 5 gene IDs:", head(rownames(expr_raw), 5), "\n")
cat("First 5 sample IDs:", head(colnames(expr_raw), 5), "\n")
cat("Raw value range:", range(expr_raw), "\n\n")

# Filter low expression genes (keep genes expressed in >=10% of samples, mean > 0.5)
min_sample_cutoff <- ceiling(0.1 * ncol(expr_raw))
keep_genes <- rowSums(expr_raw > 0) >= min_sample_cutoff & rowMeans(expr_raw) > 0.5
expr_filtered <- expr_raw[keep_genes, ]
cat("=== After Filtering ===\n")
cat("Genes retained:", nrow(expr_filtered), "\n\n")

# Normalize to log2(CPM + 1)
expr_norm <- log2((expr_filtered / rep(colSums(expr_filtered), each = nrow(expr_filtered))) * 1e6 + 1)

# Transpose to samples as rows, genes as columns (WGCNA required format)
expr_preprocessed <- t(expr_norm)

# Save preprocessed data
write.csv(expr_preprocessed, output_file, row.names = TRUE, quote = FALSE)

# Print preprocessed data summary
cat("=== Preprocessed Data Summary ===\n")
cat("Output file:", output_file, "\n")
cat("Number of samples (rows):", nrow(expr_preprocessed), "\n")
cat("Number of genes (columns):", ncol(expr_preprocessed), "\n")
cat("Mean expression value:", round(mean(expr_preprocessed), 3), "\n")
cat("Median expression value:", round(median(expr_preprocessed), 3), "\n")
cat("Preprocessed value range:", round(range(expr_preprocessed), 3), "\n")
