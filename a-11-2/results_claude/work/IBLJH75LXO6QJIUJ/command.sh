library(WGCNA)

# Load preprocessed data
datExpr <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/preprocessed_data.csv", 
                    row.names = 1, check.names = FALSE)

cat("=== SOFT-THRESHOLDING POWER SELECTION ===\n")
cat("Testing powers for scale-free topology...\n")

# Test range of soft-thresholding powers
powers <- c(1:20, seq(22, 30, by = 2))
sft <- pickSoftThreshold(datExpr, powerVector = powers, verbose = 5)

# Print results
cat("\nSoft-thresholding power analysis results:\n")
print(sft$fitIndices[, c("Power", "SFT.R.sq", "slope", "truncated.R.sq", "mean.k.")])

# Find optimal power (R² ≥ 0.8)
optimal_powers <- sft$fitIndices$Power[sft$fitIndices$SFT.R.sq >= 0.8]

if(length(optimal_powers) > 0) {
  optimal_power <- min(optimal_powers)
  cat("\nOptimal soft-thresholding power found:", optimal_power, "\n")
  cat("Scale-free topology R²:", sft$fitIndices$SFT.R.sq[sft$fitIndices$Power == optimal_power], "\n")
} else {
  # If no power achieves R² ≥ 0.8, select power with highest R²
  max_rsq_idx <- which.max(sft$fitIndices$SFT.R.sq)
  optimal_power <- sft$fitIndices$Power[max_rsq_idx]
  cat("\nNo power achieved R² ≥ 0.8. Using power with highest R²:", optimal_power, "\n")
  cat("Best achieved R²:", sft$fitIndices$SFT.R.sq[max_rsq_idx], "\n")
}

# Save results
power_results <- data.frame(
  Optimal_Power = optimal_power,
  R_squared = sft$fitIndices$SFT.R.sq[sft$fitIndices$Power == optimal_power],
  Mean_Connectivity = sft$fitIndices$mean.k.[sft$fitIndices$Power == optimal_power]
)

write.csv(sft$fitIndices, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/soft_threshold_analysis.csv")
write.csv(power_results, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/optimal_power.csv")

cat("\nSoft-thresholding analysis completed\n")
cat("Results saved to soft_threshold_analysis.csv and optimal_power.csv\n")
