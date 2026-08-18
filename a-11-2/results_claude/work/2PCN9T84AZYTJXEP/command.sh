library(WGCNA)

# Load preprocessed data
datExpr <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/preprocessed_data.csv", 
                    row.names = 1, check.names = FALSE)

cat("=== WGCNA CO-EXPRESSION NETWORK CONSTRUCTION ===\n")
cat("Using optimal soft-thresholding power: 7\n")

# Set network construction parameters
softPower <- 7
maxBlockSize <- 5000
minModuleSize <- 30
mergeCutHeight <- 0.25

cat("Network parameters:\n")
cat("- Soft-thresholding power:", softPower, "\n")
cat("- Maximum block size:", maxBlockSize, "\n")
cat("- Minimum module size:", minModuleSize, "\n")
cat("- Module merge cut height:", mergeCutHeight, "\n")

# Construct co-expression network and identify modules
net <- blockwiseModules(datExpr, 
                       power = softPower,
                       TOMType = "unsigned",
                       minModuleSize = minModuleSize,
                       reassignThreshold = 0,
                       mergeCutHeight = mergeCutHeight,
                       numericLabels = TRUE,
                       pamRespectsDendro = FALSE,
                       saveTOMs = FALSE,
                       maxBlockSize = maxBlockSize,
                       verbose = 3)

# Get module assignments
moduleLabels <- net$colors
moduleColors <- labels2colors(net$colors)

cat("\n=== MODULE DETECTION RESULTS ===\n")
cat("Number of modules detected:", length(unique(moduleLabels)) - 1, "\n")
cat("Number of genes in grey module (unassigned):", sum(moduleLabels == 0), "\n")

# Print module sizes
module_table <- table(moduleLabels)
cat("\nModule sizes:\n")
for(i in names(module_table)) {
  if(i == "0") {
    cat("Grey module (unassigned):", module_table[i], "genes\n")
  } else {
    cat("Module", i, "(", labels2colors(as.numeric(i)), "):", module_table[i], "genes\n")
  }
}

# Create gene-to-module assignment table
gene_modules <- data.frame(
  Gene_ID = colnames(datExpr),
  Module_Number = moduleLabels,
  Module_Color = moduleColors,
  stringsAsFactors = FALSE
)

# Save results
write.csv(gene_modules, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/gene_modules.csv", row.names = FALSE)

cat("\nCo-expression network construction completed\n")
cat("Gene-to-module assignments saved to gene_modules.csv\n")
cat("Ready for connectivity analysis and hub gene identification\n")
