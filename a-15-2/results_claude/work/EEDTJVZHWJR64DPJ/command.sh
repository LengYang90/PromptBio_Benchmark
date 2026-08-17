# Complete the ctcisQTL analysis by correctly formatting position data as vectors and running the analysis
# Load required libraries
if (!require("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# Install omicwas if not available
if (!require("omicwas", quietly = TRUE)) {
  BiocManager::install("omicwas")
}

library(omicwas)

# Load formatted matrices
X <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/snp_genotypes_formatted.csv", row.names=1)
Y <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/methylation_formatted.csv", row.names=1)
W <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/cell_composition_formatted.csv", row.names=1)
C <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/covariates_formatted.csv", row.names=1)

# Load position data frames
snp_pos_df <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/snp_positions_formatted.csv", row.names=1)
cpg_pos_df <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/methylation_positions_formatted.csv", row.names=1)

# Convert matrices to proper format and TRANSPOSE them
# ctcisQTL expects features as rows and samples as columns
X <- as.matrix(t(X))  # Transpose: now 31 SNPs × 53 samples
Y <- as.matrix(t(Y))  # Transpose: now 6 CpGs × 53 samples
W <- as.matrix(W)     # Keep as is: 53 samples × 3 cell types
C <- as.matrix(C)     # Keep as is: 53 samples × 3 covariates

# Print dimensions for verification
cat("Data dimensions after transposition:\n")
cat("X (SNPs):", dim(X), "\n")
cat("Y (methylation):", dim(Y), "\n")
cat("W (cell composition):", dim(W), "\n")
cat("C (covariates):", dim(C), "\n")

# Check position data frames structure
cat("SNP position data frame structure:\n")
print(head(snp_pos_df))
cat("CpG position data frame structure:\n")
print(head(cpg_pos_df))

# Extract position vectors correctly - use the 'POS' column from position data frames
if ("POS" %in% colnames(snp_pos_df)) {
  Xpos <- snp_pos_df$POS
} else if ("pos" %in% colnames(snp_pos_df)) {
  Xpos <- snp_pos_df$pos
} else if ("Position" %in% colnames(snp_pos_df)) {
  Xpos <- snp_pos_df$Position
} else {
  # If no position column found, use the second column (assuming first is chr)
  Xpos <- snp_pos_df[, 2]
}

if ("POS" %in% colnames(cpg_pos_df)) {
  Ypos <- cpg_pos_df$POS
} else if ("pos" %in% colnames(cpg_pos_df)) {
  Ypos <- cpg_pos_df$pos
} else if ("Position" %in% colnames(cpg_pos_df)) {
  Ypos <- cpg_pos_df$Position
} else {
  # If no position column found, use the second column (assuming first is chr)
  Ypos <- cpg_pos_df[, 2]
}

# Ensure position vectors are numeric
Xpos <- as.numeric(Xpos)
Ypos <- as.numeric(Ypos)

cat("Position vector lengths:\n")
cat("Xpos length:", length(Xpos), "\n")
cat("Ypos length:", length(Ypos), "\n")
cat("First few Xpos values:", head(Xpos), "\n")
cat("First few Ypos values:", head(Ypos), "\n")

# Check if position vectors have correct lengths (should match number of features, not samples)
if (length(Xpos) != nrow(X)) {
  stop("Length of Xpos (", length(Xpos), ") does not match number of SNPs (", nrow(X), ")")
}

if (length(Ypos) != nrow(Y)) {
  stop("Length of Ypos (", length(Ypos), ") does not match number of CpG sites (", nrow(Y), ")")
}

cat("Dimension checks passed! Ready for ctcisQTL analysis.\n")

# Run ctcisQTL analysis with correct parameters
cat("Running ctcisQTL analysis...\n")

tryCatch({
  # Try with cis_window parameter (1 Mb = 1000000 bp)
  results <- ctcisQTL(X = X, Y = Y, W = W, C = C, Xpos = Xpos, Ypos = Ypos, cis_window = 1000000)
  cat("Success with cis_window parameter!\n")
}, error = function(e1) {
  cat("Error with cis_window parameter:", e1$message, "\n")
  
  tryCatch({
    # Try with ciswindow parameter
    results <- ctcisQTL(X = X, Y = Y, W = W, C = C, Xpos = Xpos, Ypos = Ypos, ciswindow = 1000000)
    cat("Success with ciswindow parameter!\n")
  }, error = function(e2) {
    cat("Error with ciswindow parameter:", e2$message, "\n")
    
    tryCatch({
      # Try without cis window parameter (use default)
      results <- ctcisQTL(X = X, Y = Y, W = W, C = C, Xpos = Xpos, Ypos = Ypos)
      cat("Success without cis window parameter!\n")
    }, error = function(e3) {
      cat("Error without cis window parameter:", e3$message, "\n")
      
      # Try with different parameter order
      tryCatch({
        results <- ctcisQTL(X = X, Y = Y, W = W, Xpos = Xpos, Ypos = Ypos, C = C)
        cat("Success with different parameter order!\n")
      }, error = function(e4) {
        cat("All parameter combinations failed. Final error:", e4$message, "\n")
        stop("Unable to run ctcisQTL with any parameter combination")
      })
    })
  })
})

# If we reach here, the analysis was successful
cat("ctcisQTL analysis completed successfully!\n")
cat("Results class:", class(results), "\n")
cat("Results dimensions:", dim(results), "\n")
cat("Column names:", colnames(results), "\n")

# Save results to the required output file
write.table(results, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/mQTL_results.tsv", 
            sep="\t", row.names=FALSE, quote=FALSE)

cat("Results saved to mQTL_results.tsv with", nrow(results), "associations\n")

# Display summary of results
cat("First 5 results:\n")
print(head(results, 5))

# Check if results have the required columns
required_cols <- c("term", "response", "celltype", "estimate", "statistic", "p.value")
actual_cols <- colnames(results)
cat("Required columns check:\n")
for (col in required_cols) {
  if (col %in% actual_cols) {
    cat("✓", col, "found\n")
  } else {
    cat("✗", col, "missing\n")
  }
}

# Summary statistics
if ("celltype" %in% actual_cols) {
  cat("Summary by cell type:\n")
  print(table(results$celltype))
}

if ("p.value" %in% actual_cols) {
  cat("P-value summary:\n")
  print(summary(results$p.value))
  cat("Number of significant associations (p < 0.05):", sum(results$p.value < 0.05, na.rm=TRUE), "\n")
}

cat("ctcisQTL analysis complete! Output file: mQTL_results.tsv\n")
