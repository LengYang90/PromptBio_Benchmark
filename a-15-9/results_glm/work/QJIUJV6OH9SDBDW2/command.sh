csv_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/module_trait_correlations.csv"
png_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/wgcna_module_trait_heatmap.png"

cat("=== 1. Contents of module_trait_correlations.csv ===\n")
csv_data <- read.csv(csv_path, check.names=FALSE, stringsAsFactors=FALSE)
print(csv_data)
cat("\nCSV dimensions:", nrow(csv_data), "rows x", ncol(csv_data), "columns\n")
cat("Column names:", paste(colnames(csv_data), collapse=", "), "\n")

cat("\n=== 2. PNG file existence and size ===\n")
cat("wgcna_module_trait_heatmap.png exists:", file.exists(png_path), "\n")
file_size <- file.size(png_path)
cat("File size:", file_size, "bytes (", round(file_size/1024, 2), "KB )\n")

cat("\n=== 3. PNG image dimensions (via R) ===\n")
if (!requireNamespace("png", quietly=TRUE)) install.packages("png", repos="https://cloud.r-project.org")
library(png)
img <- readPNG(png_path)
cat("Width:", ncol(img), "pixels\n")
cat("Height:", nrow(img), "pixels\n")
cat("Channels:", dim(img)[3], "\n")
