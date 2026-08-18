library(WGCNA)
library(igraph)
options(stringsAsFactors = FALSE)

task_dir <- dirname(dirname(normalizePath(sys.frames()[[1]]$ofile, mustWork = FALSE)))
tmp_dir  <- file.path(task_dir, "tmp")
dir.create(tmp_dir, showWarnings = FALSE, recursive = TRUE)

# ── 1. Data loading and preprocessing ────────────────────────────────────────
expr_data <- read.table(file.path(task_dir, "data", "gene_expression.txt"),
    header = TRUE, row.names = 1, sep = "\t")

gene_means <- rowMeans(expr_data)
gene_vars  <- apply(expr_data, 1, var)
filtered_genes <- gene_means > quantile(gene_means, 0.1) & gene_vars > quantile(gene_vars, 0.1)
expr_filtered  <- expr_data[filtered_genes, ]
datExpr <- as.data.frame(t(expr_filtered))

write.csv(datExpr, file.path(tmp_dir, "preprocessed_expression_data.csv"), row.names = TRUE)

# ── 2. Soft-thresholding power analysis ───────────────────────────────────────
powers <- c(c(1:10), seq(from = 12, to = 30, by = 2))
sft <- pickSoftThreshold(datExpr, powerVector = powers, verbose = 5)

optimal_powers <- which(sft$fitIndices[,2] >= 0.80)
if (length(optimal_powers) > 0) {
  optimal_power <- powers[optimal_powers[1]]
} else {
  optimal_power <- powers[which.max(sft$fitIndices[,2])]
}

writeLines(as.character(optimal_power), file.path(tmp_dir, "optimal_soft_threshold_power.txt"))

png(file.path(tmp_dir, "soft_threshold_analysis.png"), width = 1200, height = 600)
par(mfrow = c(1, 2))
plot(sft$fitIndices[,1], -sign(sft$fitIndices[,3]) * sft$fitIndices[,2],
     xlab = "Soft Threshold (power)", ylab = "Scale Free Topology Model Fit, signed R^2",
     type = "n", main = "Scale independence")
text(sft$fitIndices[,1], -sign(sft$fitIndices[,3]) * sft$fitIndices[,2],
     labels = powers, cex = 0.9, col = "red")
abline(h = 0.80, col = "red", lty = 2)
plot(sft$fitIndices[,1], sft$fitIndices[,5],
     xlab = "Soft Threshold (power)", ylab = "Mean Connectivity",
     type = "n", main = "Mean connectivity")
text(sft$fitIndices[,1], sft$fitIndices[,5], labels = powers, cex = 0.9, col = "red")
dev.off()

# ── 3. Network construction and module detection ──────────────────────────────
adjacency   <- adjacency(datExpr, power = optimal_power)
TOM         <- TOMsimilarity(adjacency)
dissTOM     <- 1 - TOM
geneTree    <- hclust(as.dist(dissTOM), method = "average")

dynamicMods   <- cutreeDynamic(dendro = geneTree, distM = dissTOM,
    deepSplit = 2, pamRespectsDendro = FALSE, minClusterSize = 30)
dynamicColors <- labels2colors(dynamicMods)

MEList <- moduleEigengenes(datExpr, colors = dynamicColors)
merge  <- mergeCloseModules(datExpr, dynamicColors, cutHeight = 0.25, verbose = 3)
mergedColors <- merge$colors
mergedMEs    <- merge$newMEs

module_assignments <- data.frame(Gene = colnames(datExpr), Module = mergedColors,
    stringsAsFactors = FALSE)

write.csv(module_assignments, file.path(tmp_dir, "module_assignments.csv"), row.names = FALSE)
write.csv(mergedMEs, file.path(tmp_dir, "module_eigengenes.csv"), row.names = TRUE)
write.csv(as.matrix(TOM)[1:min(100, nrow(TOM)), 1:min(100, ncol(TOM))],
    file.path(tmp_dir, "TOM_matrix_subset.csv"), row.names = TRUE)

png(file.path(tmp_dir, "module_detection.png"), width = 1200, height = 900)
par(mfrow = c(3, 1))
plot(geneTree, xlab = "", sub = "", main = "Gene clustering on TOM-based dissimilarity",
     labels = FALSE, hang = 0.04)
plotDendroAndColors(geneTree, dynamicColors, "Dynamic Tree Cut",
    dendroLabels = FALSE, hang = 0.03, addGuide = TRUE, guideHang = 0.05,
    main = "Gene dendrogram and module colors (before merging)")
plotDendroAndColors(geneTree, mergedColors, "Merged dynamic",
    dendroLabels = FALSE, hang = 0.03, addGuide = TRUE, guideHang = 0.05,
    main = "Gene dendrogram and module colors (after merging)")
dev.off()

# ── 4. Network visualization ──────────────────────────────────────────────────
ME_cor    <- cor(mergedMEs)
ME_pvalue <- corPvalueStudent(ME_cor, nrow(mergedMEs))
k_within  <- intramodularConnectivity(adjacency, mergedColors)
module_assignments$kWithin <- k_within$kWithin
module_assignments$kOut    <- k_within$kOut
module_assignments$kDiff   <- k_within$kDiff
all_kME <- signedKME(datExpr, mergedMEs)

png(file.path(tmp_dir, "coexpression_network.png"), width = 2400, height = 1800, res = 150)
par(mfrow = c(2, 3), mar = c(4, 4, 2, 1))
labeledHeatmap(Matrix = ME_cor, xLabels = names(mergedMEs), yLabels = names(mergedMEs),
    ySymbols = names(mergedMEs), colorLabels = FALSE, colors = blueWhiteRed(50),
    textMatrix = paste(signif(ME_cor, 2), "\n(", signif(ME_pvalue, 1), ")", sep = ""),
    setStdMargins = FALSE, cex.text = 0.7, zlim = c(-1, 1),
    main = "Module Eigengene Correlations")
barplot(table(mergedColors), col = names(table(mergedColors)),
    main = "Module Sizes", xlab = "Module", ylab = "Number of Genes", las = 2)
boxplot(k_within$kWithin ~ mergedColors, col = unique(mergedColors),
    main = "Intramodular Connectivity", xlab = "Module", ylab = "Connectivity", las = 2)
top_genes <- c()
for (mod in unique(mergedColors)) {
  if (mod != "grey") {
    mod_genes <- module_assignments[module_assignments$Module == mod, ]
    top_genes <- c(top_genes, mod_genes[order(mod_genes$kWithin, decreasing = TRUE)[1:min(5, nrow(mod_genes))], "Gene"])
  }
}
top_adj <- adjacency[top_genes, top_genes]
top_adj[top_adj < 0.1] <- 0
g <- graph_from_adjacency_matrix(top_adj, weighted = TRUE, mode = "undirected")
V(g)$color <- mergedColors[match(V(g)$name, module_assignments$Gene)]
V(g)$size  <- 8
E(g)$width <- E(g)$weight * 3
plot(g, layout = layout_with_fr(g), vertex.label = NA,
     main = "Top Connected Genes Network", edge.color = "grey70")
ME_tree <- hclust(as.dist(1 - ME_cor), method = "average")
plot(ME_tree, main = "Module Eigengene Clustering", xlab = "", sub = "", cex = 0.8)
plot(module_assignments$kWithin, apply(abs(all_kME), 1, max),
     col = mergedColors, pch = 19, cex = 0.6,
     xlab = "Intramodular Connectivity", ylab = "Module Membership",
     main = "Connectivity vs Module Membership")
dev.off()

# ── 5. Hub gene identification ────────────────────────────────────────────────
hub_genes_data <- data.frame(
    Gene_ID = module_assignments$Gene, Module = module_assignments$Module,
    Intramodular_Connectivity = module_assignments$kWithin,
    Extramodular_Connectivity = module_assignments$kOut,
    Total_Connectivity        = rowSums(adjacency),
    stringsAsFactors = FALSE)

hub_genes_data$Is_Hub <- FALSE
for (mod in unique(mergedColors)) {
  if (mod != "grey") {
    mod_genes  <- which(hub_genes_data$Module == mod)
    n_hubs     <- max(3, ceiling(length(mod_genes) * 0.1))
    top_indices <- mod_genes[order(hub_genes_data$Intramodular_Connectivity[mod_genes],
        decreasing = TRUE)[1:n_hubs]]
    hub_genes_data$Is_Hub[top_indices] <- TRUE
  }
}

hub_genes_data <- hub_genes_data[order(hub_genes_data$Module, -hub_genes_data$Intramodular_Connectivity), ]
write.csv(hub_genes_data, file.path(task_dir, "ref_answer", "hub_genes.csv"), row.names = FALSE)
