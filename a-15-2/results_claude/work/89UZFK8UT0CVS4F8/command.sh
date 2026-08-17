# Install omicwas package first
install_omicwas <- function() {
  # Try CRAN first
  tryCatch({
    install.packages("omicwas", repos = "https://cran.r-project.org")
    return(TRUE)
  }, error = function(e1) {
    print(paste("CRAN installation failed:", e1$message))
    
    # Try BiocManager
    tryCatch({
      if (!require("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager")
      }
      BiocManager::install("omicwas")
      return(TRUE)
    }, error = function(e2) {
      print(paste("BiocManager installation failed:", e2$message))
      
      # Try GitHub installation
      tryCatch({
        if (!require("devtools", quietly = TRUE)) {
          install.packages("devtools")
        }
        devtools::install_github("cran/omicwas")
        return(TRUE)
      }, error = function(e3) {
        print(paste("GitHub installation failed:", e3$message))
        return(FALSE)
      })
    })
  })
}

# Attempt installation
omicwas_installed <- install_omicwas()

if (!omicwas_installed) {
  stop("Failed to install omicwas package")
}

# Load required libraries
library(omicwas)

# Set output directory
outdir <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516"

# Load data matrices
X <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/data/Matrix_of_SNP_genotypes.csv", row.names=1)
Y <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/data/Matrix_of_bulk_omics_measurements.csv", row.names=1)
W <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/data/Matrix_of_cell_type_composition.csv", row.names=1)
C <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/Matrix_of_covariates_corrected.csv", row.names=1)
Xpos <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/data/Matrix_of_trait_positions.csv", row.names=1)
Ypos <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/data/Matrix_of_bulk_omics_positions.csv", row.names=1)

# Check original dimensions
print("Original matrix dimensions:")
print(paste("X (SNP genotypes):", paste(dim(X), collapse=" x ")))
print(paste("Y (methylation):", paste(dim(Y), collapse=" x ")))
print(paste("W (cell compositions):", paste(dim(W), collapse=" x ")))
print(paste("C (covariates):", paste(dim(C), collapse=" x ")))
print(paste("Xpos (SNP positions):", paste(dim(Xpos), collapse=" x ")))
print(paste("Ypos (CpG positions):", paste(dim(Ypos), collapse=" x ")))

# Prepare position matrices for ctcisQTL - convert to proper format
# ctcisQTL expects position matrices with chr and pos columns
# Since we only have Position column, we'll assume all are on same chromosome

# Create proper position matrices
Xpos_formatted <- data.frame(
  chr = rep(1, nrow(Xpos)),  # Assume chromosome 1
  pos = Xpos$Position
)
rownames(Xpos_formatted) <- rownames(Xpos)

Ypos_formatted <- data.frame(
  chr = rep(1, nrow(Ypos)),  # Assume chromosome 1  
  pos = Ypos$Position
)
rownames(Ypos_formatted) <- rownames(Ypos)

print("Position matrices formatted for ctcisQTL:")
print("Xpos_formatted structure:")
print(head(Xpos_formatted))
print("Ypos_formatted structure:")
print(head(Ypos_formatted))

# Ensure all matrices have consistent sample ordering
common_samples <- intersect(intersect(colnames(X), colnames(Y)), 
                           intersect(rownames(W), rownames(C)))

print(paste("Number of common samples:", length(common_samples)))

# Order matrices to have consistent samples
X_ordered <- X[, common_samples]
Y_ordered <- Y[, common_samples]
W_ordered <- W[common_samples, ]
C_ordered <- C[common_samples, ]

print("Final matrix dimensions after sample alignment:")
print(paste("X (SNP genotypes):", paste(dim(X_ordered), collapse=" x ")))
print(paste("Y (methylation):", paste(dim(Y_ordered), collapse=" x ")))
print(paste("W (cell compositions):", paste(dim(W_ordered), collapse=" x ")))
print(paste("C (covariates):", paste(dim(C_ordered), collapse=" x ")))

# Run ctcisQTL analysis using the correct parameter names
print("Running ctcisQTL analysis with correct parameters...")

# Execute ctcisQTL with proper parameters
result <- ctcisQTL(
  X = X_ordered,                    # SNP genotype matrix
  Xpos = Xpos_formatted,           # SNP positions  
  W = W_ordered,                   # Cell type composition matrix
  Y = Y_ordered,                   # Methylation data matrix
  Ypos = Ypos_formatted,          # Methylation positions
  C = C_ordered,                   # Covariates matrix
  max.pos.diff = 1e6,             # 1 Mb cis window
  outdir = outdir,                 # Output directory
  outfile = "mQTL_results.tsv"     # Output file name
)

print("ctcisQTL analysis completed!")

# Check if output file was created
output_file <- file.path(outdir, "mQTL_results.tsv")
if (file.exists(output_file)) {
  # Read and display results
  results <- read.table(output_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  
  print("Results loaded successfully!")
  print(paste("Number of results:", nrow(results)))
  print("Column names:")
  print(colnames(results))
  print("First few results:")
  print(head(results))
  
  # Summary statistics
  if ("p.value" %in% colnames(results)) {
    print("Summary statistics:")
    print(paste("Total associations tested:", nrow(results)))
    print(paste("Significant associations (p < 0.05):", sum(results$p.value < 0.05, na.rm = TRUE)))
    print(paste("Highly significant associations (p < 0.001):", sum(results$p.value < 0.001, na.rm = TRUE)))
  }
  
} else {
  print("Warning: Output file was not created. Checking ctcisQTL return value:")
  print(result)
  
  # If ctcisQTL doesn't create the expected file, try to work with returned results
  if (!is.null(result) && is.data.frame(result)) {
    print("Results returned as data frame. Saving manually...")
    write.table(result, output_file, sep = "\t", row.names = FALSE, quote = FALSE)
    print(paste("Results saved to:", output_file))
  }
}

print("Analysis completed!")
