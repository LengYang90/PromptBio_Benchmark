library(ggplot2)

# Define paths
base_dir <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623"
exp_path <- file.path(base_dir, "preprocessed_gbm_exp.csv")
mut_path <- file.path(base_dir, "preprocessed_gbm_mut.csv")
cn_path <- file.path(base_dir, "preprocessed_gbm_cn.csv")
cluster_path <- file.path(base_dir, "cluster.csv")
out_plot_path <- file.path(base_dir, "cluster.png")

# Load and combine omics matrices
exp_mat <- read.csv(exp_path, row.names = 1, check.names = FALSE)
mut_mat <- read.csv(mut_path, row.names = 1, check.names = FALSE)
cn_mat <- read.csv(cn_path, row.names = 1, check.names = FALSE)
combined_mat <- cbind(exp_mat, mut_mat, cn_mat)

# Run PCA with feature standardization
pca <- prcomp(combined_mat, scale. = TRUE)

# Align cluster assignments with PCA results
cluster_df <- read.csv(cluster_path)
cluster_df <- cluster_df[match(rownames(pca$x), cluster_df$sample_id), ]

# Prepare plot data
plot_df <- data.frame(
  PC1 = pca$x[,1],
  PC2 = pca$x[,2],
  Cluster = as.factor(cluster_df$cluster)
)

# Calculate variance explained for axis labels
pc1_var <- round(summary(pca)$importance[2,1] * 100, 1)
pc2_var <- round(summary(pca)$importance[2,2] * 100, 1)

# Generate PCA scatter plot
p <- ggplot(plot_df, aes(x=PC1, y=PC2, color=Cluster)) +
  geom_point(size=2) +
  labs(
    title = "GBM Molecular Subtypes (PCA of Integrated Multi-omics Data)",
    x = paste0("PC1 (", pc1_var, "%)"),
    y = paste0("PC2 (", pc2_var, "%)")
  ) +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

# Save publication quality plot
ggsave(out_plot_path, plot = p, width = 8, height = 6, dpi = 300)
