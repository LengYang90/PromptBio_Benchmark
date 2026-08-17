library(WGCNA)

# Load aligned phenotype data and module assignments
pheno <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/aligned_phenotype_data.csv", row.names=1)
datExpr <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/combined_expression_data.csv", row.names=1)
module_assignments <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/module_assignments.csv")

# Get module colors
moduleColors <- module_assignments$Module

# Calculate module eigengenes
MEs <- moduleEigengenes(datExpr, moduleColors)$eigengenes

# Align samples
MEs <- MEs[rownames(pheno), ]

# Calculate correlations with Disease status
moduleTraitCor <- cor(MEs, pheno$Disease, use="p")
moduleTraitPvalue <- corPvalueStudent(moduleTraitCor, nrow(MEs))

# Prepare results
results <- data.frame(
  Module = gsub("ME", "", rownames(moduleTraitCor)),
  Correlation = as.numeric(moduleTraitCor),
  Pvalue = as.numeric(moduleTraitPvalue)
)

# Save correlation results
write.csv(results, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/module_trait_correlations.csv", row.names=FALSE)

# Create heatmap
png("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/wgcna_module_trait_heatmap.png", width=800, height=600)
labeledHeatmap(Matrix=moduleTraitCor, 
               xLabels="Disease", 
               yLabels=names(MEs),
               ySymbols=names(MEs),
               colorLabels=FALSE,
               colors=blueWhiteRed(50),
               textMatrix=paste(signif(moduleTraitCor, 2), "\n(", signif(moduleTraitPvalue, 1), ")", sep=""),
               setStdMargins=FALSE,
               cex.text=0.8,
               zlim=c(-1,1),
               main="Module-trait relationships")
dev.off()

cat("Module-trait correlations calculated and saved\n")
print(results)
