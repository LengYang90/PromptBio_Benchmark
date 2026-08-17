library(iClusterPlus)
library(data.table)
library(ggplot2)

set.seed(42)

task_dir <- dirname(dirname(normalizePath(sys.frames()[[1]]$ofile, mustWork = FALSE)))

exp_df <- fread(file.path(task_dir, "data", "gbm.exp.csv"), data.table = FALSE)
mut_df <- fread(file.path(task_dir, "data", "gbm.mut.csv"), data.table = FALSE)
seg_df <- fread(file.path(task_dir, "data", "gbm.cn.csv"),  data.table = FALSE)

rownames(exp_df) <- exp_df$V1; exp_df$V1 <- NULL
rownames(mut_df) <- mut_df$V1; mut_df$V1 <- NULL
rownames(seg_df) <- seg_df$V1; seg_df$V1 <- NULL

samples <- intersect(intersect(rownames(exp_df), rownames(mut_df)), rownames(seg_df))
exp_df  <- exp_df[samples, , drop = FALSE]
mut_df  <- mut_df[samples, , drop = FALSE]
seg_df  <- seg_df[samples, , drop = FALSE]

# Tune lambda at K=2 (3 clusters); cpus=1 ensures reproducibility with set.seed
cv.fit <- tune.iClusterPlus(cpus = 1,
    dt1 = as.matrix(mut_df), dt2 = as.matrix(seg_df), dt3 = as.matrix(exp_df),
    type = c("binomial", "gaussian", "gaussian"), K = 2,
    n.lambda = 101, scale.lambda = c(1, 1, 1), maxiter = 20)

BIC      <- getBIC(list(cv.fit))
minBICid <- which.min(BIC[, 1])

best_clusters <- cv.fit$fit[[minBICid]]$clusters
cluster_df    <- data.frame(sample_id = samples, cluster = best_clusters)
write.csv(cluster_df, file = file.path(task_dir, "ref_answer", "cluster.csv"),
    quote = FALSE, row.names = FALSE)

combined_for_pca <- t(scale(t(cbind(exp_df, mut_df, seg_df))))
pca    <- prcomp(combined_for_pca, scale. = FALSE)
pca_df <- data.frame(
    sample_id = rownames(pca$x),
    PC1 = pca$x[, 1], PC2 = pca$x[, 2],
    cluster = factor(best_clusters))

png(file.path(task_dir, "ref_answer", "cluster.png"))
g <- ggplot(pca_df, aes(x = PC1, y = PC2, color = cluster)) +
    geom_point(size = 3) + theme_minimal() +
    labs(title = "PCA colored by iClusterPlus cluster")
print(g)
dev.off()
