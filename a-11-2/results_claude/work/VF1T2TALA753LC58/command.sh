library(WGCNA)

# Load preprocessed data and module assignments
datExpr <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/preprocessed_data.csv", 
                    row.names = 1, check.names = FALSE)
gene_modules <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/gene_modules.csv")

cat("=== CALCULATING COMPREHENSIVE CONNECTIVITY MEASURES ===\n")

# Calculate adjacency matrix using optimal power
softPower <- 7
adjacency <- adjacency(datExpr, power = softPower)

# Calculate total connectivity (degree)
total_connectivity <- apply(adjacency, 1, sum) - 1  # Subtract 1 to exclude self-connection

cat("Total connectivity calculated for", length(total_connectivity), "genes\n")

# Calculate intramodular and extramodular connectivity
moduleLabels <- gene_modules$Module_Number
names(moduleLabels) <- gene_modules$Gene_ID

intramodular_connectivity <- numeric(length(total_connectivity))
extramodular_connectivity <- numeric(length(total_connectivity))
names(intramodular_connectivity) <- names(total_connectivity)
names(extramodular_connectivity) <- names(total_connectivity)

# Calculate connectivity measures for each gene
for(i in 1:length(total_connectivity)) {
  gene_name <- names(total_connectivity)[i]
  gene_module <- moduleLabels[gene_name]
  
  if(gene_module == 0) {  # Grey module (unassigned)
    intramodular_connectivity[i] <- 0
    extramodular_connectivity[i] <- total_connectivity[i]
  } else {
    # Genes in same module
    same_module_genes <- names(moduleLabels)[moduleLabels == gene_module]
    same_module_genes <- same_module_genes[same_module_genes != gene_name]  # Exclude self
    
    # Intramodular connectivity
    if(length(same_module_genes) > 0) {
      intramodular_connectivity[i] <- sum(adjacency[gene_name, same_module_genes])
    } else {
      intramodular_connectivity[i] <- 0
    }
    
    # Extramodular connectivity
    extramodular_connectivity[i] <- total_connectivity[i] - intramodular_connectivity[i]
  }
}

cat("Intramodular and extramodular connectivity calculated\n")

# Create comprehensive connectivity results
connectivity_results <- data.frame(
  Gene_ID = names(total_connectivity),
  Module = gene_modules$Module_Color[match(names(total_connectivity), gene_modules$Gene_ID)],
  Intramodular_Connectivity = intramodular_connectivity,
  Extramodular_Connectivity = extramodular_connectivity,
  Total_Connectivity = total_connectivity,
  stringsAsFactors = FALSE
)

# Define hub genes (top 10% by total connectivity within each module)
connectivity_results$Is_Hub <- FALSE

for(module in unique(connectivity_results$Module)) {
  if(module != "grey") {  # Skip grey module
    module_genes <- connectivity_results$Module == module
    module_connectivities <- connectivity_results$Total_Connectivity[module_genes]
    
    # Top 10% threshold
    threshold <- quantile(module_connectivities, 0.9)
    hub_indices <- which(module_genes & connectivity_results$Total_Connectivity >= threshold)
    connectivity_results$Is_Hub[hub_indices] <- TRUE
  }
}

# Summary statistics
cat("\n=== CONNECTIVITY SUMMARY ===\n")
cat("Total genes analyzed:", nrow(connectivity_results), "\n")
cat("Hub genes identified:", sum(connectivity_results$Is_Hub), "\n")

# Module-wise summary
cat("\nModule-wise hub gene counts:\n")
hub_summary <- table(connectivity_results$Module[connectivity_results$Is_Hub])
for(module in names(hub_summary)) {
  cat(module, "module:", hub_summary[module], "hub genes\n")
}

# Save results
write.csv(connectivity_results, "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_10/toolsgenie_20260516/hub_genes.csv", row.names = FALSE)

cat("\nConnectivity analysis completed\n")
cat("Results saved to hub_genes.csv\n")
cat("File contains: Gene_ID, Module, Intramodular_Connectivity, Extramodular_Connectivity, Total_Connectivity, Is_Hub\n")
