setwd("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714")

if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager", repos="https://cloud.r-project.org")
if (!requireNamespace("WGCNA", quietly = TRUE)) BiocManager::install("WGCNA", update=FALSE, ask=FALSE)
library(WGCNA)
if (!requireNamespace("pheatmap", quietly = TRUE)) install.packages("pheatmap", repos="https://cloud.r-project.org")
library(pheatmap)

pheno <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/data/Pheno.csv", check.names=FALSE, stringsAsFactors=FALSE)
protein <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/data/protein.csv", check.names=FALSE, stringsAsFactors=FALSE)
rna <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/data/rna.csv", check.names=FALSE, stringsAsFactors=FALSE)

rna_mat <- as.matrix(rna[, -1])
rownames(rna_mat) <- paste0("rna_", rna[, 1])
protein_mat <- as.matrix(protein[, -1])
rownames(protein_mat) <- paste0("protein_", protein[, 1])

expr <- rbind(rna_mat, protein_mat)
expr <- apply(expr, 2, as.numeric)
rownames(expr) <- c(paste0("rna_", rna[, 1]), paste0("protein_", protein[, 1]))

sample_order <- pheno$Sample
expr <- expr[, sample_order, drop=FALSE]

var_genes <- apply(expr, 1, var)
keep <- var_genes > 0
expr <- expr[keep, , drop=FALSE]
cat("Genes removed (zero variance):", sum(!keep), "\n")
cat("Expression matrix dim (features x samples):", dim(expr), "\n")

datExpr <- t(expr)
datExpr <- as.data.frame(datExpr)
cat("datExpr dim (samples x features):", dim(datExpr), "\n")
cat("datExpr column names sample:", head(colnames(datExpr), 5), "\n")

trait <- data.frame(Disease = pheno$Disease, row.names = pheno$Sample)
rownames(datExpr) <- pheno$Sample
cat("Row names of datExpr match Pheno Sample:", identical(rownames(datExpr), as.character(pheno$Sample)), "\n")
cat("Disease trait vector:\n")
print(table(trait$Disease))

sft <- pickSoftThreshold(datExpr, powerVector=1:10, verbose=5)
cat("\n=== pickSoftThreshold results ===\n")
print(sft$fitIndices[, c("Power", "SFT.R.sq", "slope", "truncated.R.sq", "mean.k.", "median.k.", "max.k.")])
softPower <- ifelse(is.na(sft$powerEstimate), 6, sft$powerEstimate)
cat("Selected soft power:", softPower, "\n")

net <- blockwiseModules(datExpr, power=softPower, TOMType="unsigned", deepSplit=4,
                        minModuleSize=10, mergeCutHeight=0.3, numericLabels=TRUE,
                        saveTOMs=FALSE, verbose=3)
cat("\n=== blockwiseModules results ===\n")
cat("Module sizes (table):\n")
print(table(net$colors))
cat("Number of modules (excluding 0/grey):", length(unique(net$colors)) - ifelse(0 %in% net$colors, 1, 0), "\n")

moduleColors <- labels2colors(net$colors)
MEs <- moduleEigengenes(datExpr, moduleColors)$eigengenes
MEs <- orderMEs(MEs)
cat("\n=== Module Eigengenes ===\n")
cat("MEs dimensions:", dim(MEs), "\n")
cat("MEs column names:", colnames(MEs), "\n")

disease_vec <- as.numeric(trait$Disease)
names(disease_vec) <- rownames(trait)
moduleTraitCor <- cor(MEs, disease_vec, use="p", method="pearson")
moduleTraitPvalue <- corPvalueStudent(moduleTraitCor, nSamples=nrow(datExpr))

cat("\n=== Module-Trait Correlations ===\n")
print(moduleTraitCor)
cat("\n=== Module-Trait P-values ===\n")
print(moduleTraitPvalue)

result_df <- data.frame(
  Module = rownames(moduleTraitCor),
  Correlation = as.numeric(moduleTraitCor[, 1]),
  Pvalue = as.numeric(moduleTraitPvalue[, 1]),
  stringsAsFactors = FALSE
)
write.csv(result_df, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/module_trait_correlations.csv", row.names=FALSE)
cat("\nWrote module_trait_correlations.csv\n")
print(result_df)

mat <- matrix(result_df$Correlation, nrow=nrow(result_df), ncol=1)
rownames(mat) <- result_df$Module
colnames(mat) <- "Disease"
text_mat <- matrix(paste0("r=", round(result_df$Correlation, 3), "\np=", formatC(result_df$Pvalue, format="e", digits=2)),
                   nrow=nrow(result_df), ncol=1)
rownames(text_mat) <- result_df$Module
colnames(text_mat) <- "Disease"

png("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/wgcna_module_trait_heatmap.png",
    width=6, height=max(6, nrow(mat)*0.4), units="in", res=300)
pheatmap(mat,
         cluster_rows=FALSE, cluster_cols=FALSE,
         color=colorRampPalette(c("blue", "white", "red"))(50),
         display_numbers=text_mat,
         number_color="black",
         fontsize_number=8,
         main="WGCNA Module-Trait Correlation (Disease)",
         fontsize_row=9, fontsize_col=12,
         border_color="grey60",
         breaks=seq(-1, 1, length.out=51))
dev.off()
cat("\nWrote wgcna_module_trait_heatmap.png\n")
cat("\n=== WGCNA Analysis Complete ===\n")
