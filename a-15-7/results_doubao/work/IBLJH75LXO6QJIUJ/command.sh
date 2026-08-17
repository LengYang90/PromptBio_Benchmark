library(iClusterPlus)

# Define paths
input_dir <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623"
exp_path <- file.path(input_dir, "preprocessed_gbm_exp.csv")
mut_path <- file.path(input_dir, "preprocessed_gbm_mut.csv")
cn_path <- file.path(input_dir, "preprocessed_gbm_cn.csv")
out_path <- file.path(input_dir, "cluster.csv")

# Load data and convert to matrices
exp_mat <- as.matrix(read.csv(exp_path, row.names = 1, check.names = FALSE))
mut_mat <- as.matrix(read.csv(mut_path, row.names = 1, check.names = FALSE))
cn_mat <- as.matrix(read.csv(cn_path, row.names = 1, check.names = FALSE))

# Run iClusterPlus with k=3 (fixed parameters)
fit <- iClusterPlus(
  dt1 = exp_mat,
  dt2 = mut_mat,
  dt3 = cn_mat,
  type = c("gaussian", "binomial", "gaussian"),
  K = 3,
  maxiter = 20,
  eps = 1e-4
)

# Extract cluster assignments
cluster_res <- data.frame(
  sample_id = rownames(exp_mat),
  cluster = fit$clusters
)

# Save output
write.csv(cluster_res, out_path, row.names = FALSE, quote = FALSE)
