options(stringsAsFactors = FALSE)
library(WGCNA)
library(pheatmap)

# Define absolute paths
expr_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_11/toolsgenie_20260623/combined_filtered_expression.csv"
pheno_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_11/toolsgenie_20260623/aligned_phenotype.csv"
out_cor_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_11/toolsgenie_20260623/module_trait_correlations.csv"
out_heatmap_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_11/toolsgenie_20260623/wgcna_module_trait_heatmap.png"

# Load and preprocess data
expr <- read.csv(expr_path, row.names = 1, check.names = FALSE)
expr_t <- t(expr) # Transpose to samples as rows, features as columns
pheno <- read.csv(pheno_path, row.names = 1, check.names = FALSE)
disease_trait <- pheno$Disease
n_samples <- nrow(expr_t)

# Select soft threshold power
sft <- pickSoftThreshold(expr_t, powerVector = 1:10, verbose = 0)
soft_power <- ifelse(is.na(sft$powerEstimate), 6, sft$powerEstimate)

# Run WGCNA module detection
net <- blockwiseModules(expr_t, power = soft_power,
                        TOMType = "unsigned",
                        deepSplit = 4,
                        minModuleSize = 10,
                        mergeCutHeight = 0.3,
                        verbose = 0)

# Calculate module-trait correlations and p-values
MEs <- net$MEs
module_names <- gsub("^ME", "", colnames(MEs))
cor_vals <- cor(MEs, disease_trait, use = "pairwise.complete.obs")
p_vals <- corPvalueStudent(cor_vals, n_samples - 2)

# Save correlation results
cor_res <- data.frame(
  Module = module_names,
  Correlation = round(cor_vals[,1], 4),
  Pvalue = round(p_vals[,1], 6)
)
write.csv(cor_res, out_cor_path, row.names = FALSE, quote = FALSE)

# Generate module-trait heatmap
heat_mat <- matrix(cor_vals[,1], ncol = 1, dimnames = list(module_names, "Disease"))
text_mat <- matrix(paste0(round(cor_vals[,1], 2), "\n(p=", 
                          ifelse(p_vals[,1] < 0.001, "<0.001", round(p_vals[,1], 3)), ")"),
                   ncol = 1)

png(out_heatmap_path, width = 1200, height = 800, res = 300)
pheatmap(heat_mat,
         display_numbers = text_mat,
         number_color = "black",
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         color = colorRampPalette(c("navy", "white", "firebrick3"))(100),
         breaks = seq(-1, 1, length.out = 100),
         xlab = "Phenotype",
         ylab = "WGCNA Modules",
         main = "Module-Trait Correlations")
dev.off()
