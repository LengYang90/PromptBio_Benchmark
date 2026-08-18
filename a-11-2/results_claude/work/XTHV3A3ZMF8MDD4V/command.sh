# Inspect gene expression data structure and dimensions
data <- read.table("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/data/gene_expression.txt", 
                   header = TRUE, row.names = 1, sep = "\t", check.names = FALSE)

# Print basic data structure information
cat("=== GENE EXPRESSION DATA INSPECTION ===\n")
cat("File format: Tab-delimited text file\n")
cat("Data dimensions:", dim(data)[1], "genes x", dim(data)[2], "samples\n")
cat("Data type:", class(data), "\n")

# Display first few rows and columns
cat("\n=== DATA PREVIEW ===\n")
print(data[1:min(5, nrow(data)), 1:min(5, ncol(data))])

# Check data distribution and quality
cat("\n=== DATA QUALITY ASSESSMENT ===\n")
cat("Missing values:", sum(is.na(data)), "\n")
cat("Zero values:", sum(data == 0, na.rm = TRUE), "\n")
cat("Data range: [", min(data, na.rm = TRUE), ",", max(data, na.rm = TRUE), "]\n")

# Summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Mean expression:", round(mean(as.matrix(data), na.rm = TRUE), 3), "\n")
cat("Median expression:", round(median(as.matrix(data), na.rm = TRUE), 3), "\n")
cat("Standard deviation:", round(sd(as.matrix(data), na.rm = TRUE), 3), "\n")

# Sample and gene information
cat("\n=== IDENTIFIERS ===\n")
cat("Sample names (first 5):", paste(colnames(data)[1:min(5, ncol(data))], collapse = ", "), "\n")
cat("Gene names (first 5):", paste(rownames(data)[1:min(5, nrow(data))], collapse = ", "), "\n")

# WGCNA readiness assessment
cat("\n=== WGCNA ANALYSIS READINESS ===\n")
cat("Minimum samples for WGCNA: 15 (recommended: >20)\n")
cat("Current samples:", ncol(data), ifelse(ncol(data) >= 15, "✓ SUFFICIENT", "✗ INSUFFICIENT"), "\n")
cat("Minimum genes for analysis: 5000 (recommended: >10000)\n")
cat("Current genes:", nrow(data), ifelse(nrow(data) >= 5000, "✓ SUFFICIENT", "✗ MAY NEED FILTERING"), "\n")
cat("Data appears to be:", ifelse(max(data, na.rm = TRUE) > 50, "raw counts", "normalized/log-transformed"), "\n")
