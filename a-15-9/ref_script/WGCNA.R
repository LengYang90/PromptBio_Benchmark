#!/usr/bin/env Rscript
suppressMessages({
  library(WGCNA)
  options(stringsAsFactors = FALSE)
  allowWGCNAThreads()
})

task_dir <- dirname(dirname(normalizePath(sys.frames()[[1]]$ofile, mustWork = FALSE)))

rna     <- read.csv(file.path(task_dir, "data", "rna.csv"),     row.names = 1)
protein <- read.csv(file.path(task_dir, "data", "protein.csv"), row.names = 1)
pheno   <- read.csv(file.path(task_dir, "data", "Pheno.csv"))

common_samples <- intersect(colnames(rna), colnames(protein))
rna     <- rna[, common_samples]
protein <- protein[, common_samples]

exprData <- rbind(rna, protein)
datExpr  <- as.data.frame(apply(as.data.frame(t(exprData)), 2, as.numeric))

sampleTree <- hclust(dist(datExpr), method = "average")

powers   <- 1:10
sft      <- pickSoftThreshold(datExpr, powerVector = powers, verbose = 0)
softPower <- ifelse(is.na(sft$powerEstimate), 6, sft$powerEstimate)

net <- tryCatch({
  blockwiseModules(datExpr, power = softPower, TOMType = "unsigned",
      minModuleSize = 10, deepSplit = 4, reassignThreshold = 0,
      mergeCutHeight = 0.3, numericLabels = TRUE, pamRespectsDendro = FALSE,
      saveTOMs = FALSE, verbose = 0)
}, error = function(e) NULL)

if (is.null(net) || all(net$colors == 0)) {
  moduleColors <- rep("grey", ncol(datExpr))
} else {
  moduleColors <- labels2colors(net$colors)
}

datTraits <- data.frame(Disease = pheno$Disease)
rownames(datTraits) <- pheno$Sample

MEs <- orderMEs(moduleEigengenes(datExpr, colors = moduleColors)$eigengenes)

if (ncol(MEs) > 0) {
  moduleTraitCor    <- cor(MEs, datTraits$Disease, use = "p")
  moduleTraitPvalue <- corPvalueStudent(moduleTraitCor, nrow(datExpr))
  res <- data.frame(Module      = rownames(moduleTraitCor),
                    Correlation = moduleTraitCor[, 1],
                    Pvalue      = moduleTraitPvalue[, 1])
  write.csv(res, file.path(task_dir, "ref_answer", "module_trait_correlations.csv"), row.names = FALSE, quote = FALSE)

  png(file.path(task_dir, "ref_answer", "wgcna_module_trait_heatmap.png"), width = 2000, height = 1500, res = 150)
  labeledHeatmap(Matrix = moduleTraitCor,
      xLabels = names(datTraits), yLabels = rownames(moduleTraitCor),
      ySymbols = rownames(moduleTraitCor), colorLabels = FALSE,
      colors = blueWhiteRed(50), textMatrix = signif(moduleTraitCor, 2),
      main = "Module-Trait Relationships")
  dev.off()
}
