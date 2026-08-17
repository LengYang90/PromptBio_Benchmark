library(WGCNA)

# Load prepared data
datExpr <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/combined_expression_data.csv", row.names=1)

# Check data quality
gsg <- goodSamplesGenes(datExpr, verbose=3)
cat("All samples good:", gsg$allOK, "\n")

# Choose soft-thresholding power
powers <- c(c(1:10), c(12,14,16,18,20))
sft <- pickSoftThreshold(datExpr, powerVector=powers, verbose=5)
softPower <- sft$powerEstimate
if(is.na(softPower)) softPower <- 6
cat("Chosen soft power:", softPower, "\n")

# Construct network and detect modules with adjusted parameters for small dataset
net <- blockwiseModules(datExpr, power=softPower, TOMType="unsigned", 
                       minModuleSize=10,  # Reduced from 30 to accommodate smaller dataset
                       reassignThreshold=0, 
                       mergeCutHeight=0.15,  # Reduced from 0.25 for more sensitive merging
                       numericLabels=TRUE, 
                       pamRespectsDendro=FALSE, 
                       saveTOMs=FALSE, 
                       verbose=3,
                       deepSplit=2,  # More sensitive module detection
                       detectCutHeight=0.995)  # Slightly more lenient cut height

# Convert labels to colors
moduleLabels <- net$colors
moduleColors <- labels2colors(net$colors)

cat("Number of modules detected:", length(unique(moduleLabels))-1, "\n")
cat("Module sizes:\n")
print(table(moduleColors))

# If still no modules detected, try alternative approach with manual clustering
if(length(unique(moduleLabels)) <= 1) {
  cat("No modules detected with standard parameters. Trying alternative approach...\n")
  
  # Calculate adjacency matrix
  adjacency <- adjacency(datExpr, power=softPower)
  
  # Calculate TOM
  TOM <- TOMsimilarity(adjacency)
  dissTOM <- 1-TOM
  
  # Hierarchical clustering
  geneTree <- hclust(as.dist(dissTOM), method="average")
  
  # Dynamic tree cutting with very lenient parameters
  dynamicMods <- cutreeDynamic(dendro=geneTree, distM=dissTOM,
                              deepSplit=4, pamRespectsDendro=FALSE,
                              minClusterSize=5)  # Very small minimum size
  
  moduleLabels <- dynamicMods
  moduleColors <- labels2colors(dynamicMods)
  
  cat("Alternative approach - Number of modules detected:", length(unique(moduleLabels))-1, "\n")
  cat("Alternative approach - Module sizes:\n")
  print(table(moduleColors))
}

# Save module assignments
module_assignments <- data.frame(
  Gene = colnames(datExpr),
  Module = moduleColors,
  ModuleNumber = moduleLabels
)

write.csv(module_assignments, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/module_assignments.csv", row.names=FALSE)

cat("Module assignments saved to module_assignments.csv\n")
cat("Summary: Detected", length(unique(moduleLabels))-1, "modules from", ncol(datExpr), "features\n")
