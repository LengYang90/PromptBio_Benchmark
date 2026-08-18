pheno_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/data/Pheno.csv"
protein_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/data/protein.csv"
rna_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_714/toolsgenie_20260714/data/rna.csv"

pheno <- read.csv(pheno_path, check.names = FALSE, row.names = NULL)
protein <- read.csv(protein_path, check.names = FALSE, row.names = NULL)
rna <- read.csv(rna_path, check.names = FALSE, row.names = NULL)

cat("=== Pheno.csv ===\n")
cat("Dimensions:", dim(pheno), "\n")
cat("Column names:", paste(colnames(pheno), collapse = ", "), "\n")
cat("Column classes:\n")
print(sapply(pheno, class))
cat("\nFirst 5 rows:\n")
print(head(pheno, 5))
cat("\nStructure of Disease column:\n")
cat("Class:", class(pheno$Disease), "\n")
cat("Levels/Unique values:", paste(unique(pheno$Disease), collapse = ", "), "\n")
cat("Summary:\n")
print(table(pheno$Disease, useNA = "ifany"))

cat("\n=== protein.csv ===\n")
cat("Dimensions:", dim(protein), "\n")
cat("Column names (first 10):", paste(head(colnames(protein), 10), collapse = ", "), "\n")
cat("Column classes (first 5):", paste(head(sapply(protein, class), 5), collapse = ", "), "\n")
cat("\nFirst 5 rows (first 6 cols):\n")
print(head(protein[, 1:min(6, ncol(protein))], 5))
cat("\nFirst column values (potential row names):\n")
print(head(protein[, 1], 5))

cat("\n=== rna.csv ===\n")
cat("Dimensions:", dim(rna), "\n")
cat("Column names (first 10):", paste(head(colnames(rna), 10), collapse = ", "), "\n")
cat("Column classes (first 5):", paste(head(sapply(rna, class), 5), collapse = ", "), "\n")
cat("\nFirst 5 rows (first 6 cols):\n")
print(head(rna[, 1:min(6, ncol(rna))], 5))
cat("\nFirst column values (potential row names):\n")
print(head(rna[, 1], 5))

cat("\n=== Row names check ===\n")
cat("protein first column name:", colnames(protein)[1], "\n")
cat("rna first column name:", colnames(rna)[1], "\n")
cat("protein row.names identical to first column:", identical(row.names(protein), as.character(protein[, 1])), "\n")
cat("rna row.names identical to first column:", identical(row.names(rna), as.character(rna[, 1])), "\n")
