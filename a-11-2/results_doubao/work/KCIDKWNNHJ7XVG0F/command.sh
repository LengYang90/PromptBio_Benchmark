options(stringsAsFactors = FALSE)
library(WGCNA)
allowWGCNAThreads()

# Define absolute paths
input_file <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_11/toolsgenie_20260623/preprocessed_expression_for_WGCNA.csv"
output_file <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-2/result_11/toolsgenie_20260623/hub_genes.csv"

# Load preprocessed data (samples as rows, genes as columns)
expr_data <- read.csv(input_file, row.names = 1, check.names = FALSE)

# Step 1: Select soft threshold power using scale-free topology criterion
powers <- 1:20
sft <- pickSoftThreshold(expr_data, powerVector = powers, verbose = 0)
soft_power <- ifelse(is.na(sft$powerEstimate), 12, sft$powerEstimate)

# Step 2: Build network and detect co-expression modules
adj_matrix <- adjacency(expr_data, power = soft_power)
tom_matrix <- TOMsimilarity(adj_matrix, verbose = 0)
diss_tom <- 1 - tom_matrix
hclust_tree <- hclust(as.dist(diss_tom), method = "average")
module_labels <- cutreeDynamic(dendro = hclust_tree, distM = diss_tom, verbose = 0)

# Step 3: Calculate connectivity metrics
connectivity <- intramodularConnectivity(adj_matrix, module_labels)

# Step 4: Identify hub genes (top 10% highest intramodular connectivity per module)
result_df <- data.frame(
  Gene_ID = rownames(connectivity),
  Module = module_labels,
  Intramodular_Connectivity = connectivity$kWithin,
  Extramodular_Connectivity = connectivity$kOut,
  Total_Connectivity = connectivity$kTotal,
  Is_Hub = FALSE,
  check.names = FALSE
)

for (mod in unique(result_df$Module)) {
  mod_rows <- result_df$Module == mod
  threshold <- quantile(result_df$Intramodular_Connectivity[mod_rows], 0.9)
  result_df$Is_Hub[mod_rows] <- result_df$Intramodular_Connectivity[mod_rows] >= threshold
}

# Export final results
write.csv(result_df, output_file, row.names = FALSE, quote = FALSE)
