# Set CRAN mirror first
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install omicwas package
if (!require("omicwas", quietly = TRUE)) {
    install.packages("omicwas")
}

library(omicwas)

# Load and properly format data matrices
cat("Loading and formatting data matrices for omicwas...\n")

# Load raw data matrices
X_raw <- as.matrix(read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/snp_genotypes_formatted.csv", row.names=1))
Y_raw <- as.matrix(read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/methylation_formatted.csv", row.names=1))
W <- as.matrix(read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/cell_composition_formatted.csv", row.names=1))
C <- as.matrix(read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/covariates_formatted.csv", row.names=1))

# Load position data from original source files and inspect structure
cat("Loading and inspecting position data...\n")
snp_pos_data <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/data/Matrix_of_trait_positions.csv", row.names=1)
cpg_pos_data <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/data/Matrix_of_bulk_omics_positions.csv", row.names=1)

cat("SNP position data structure:\n")
cat("Dimensions:", nrow(snp_pos_data), "x", ncol(snp_pos_data), "\n")
cat("Column names:", paste(colnames(snp_pos_data), collapse=", "), "\n")
print(head(snp_pos_data, 3))

cat("\nCpG position data structure:\n")
cat("Dimensions:", nrow(cpg_pos_data), "x", ncol(cpg_pos_data), "\n")
cat("Column names:", paste(colnames(cpg_pos_data), collapse=", "), "\n")
print(head(cpg_pos_data, 3))

# Extract position vectors with flexible column detection
if ("position" %in% colnames(snp_pos_data)) {
    Xpos <- snp_pos_data$position
    cat("Using 'position' column for SNPs\n")
} else if (ncol(snp_pos_data) == 1) {
    Xpos <- snp_pos_data[,1]
    cat("Using first column for SNP positions:", colnames(snp_pos_data)[1], "\n")
} else {
    # Look for likely position column names
    pos_cols <- grep("pos|Position|coordinate|Coordinate", colnames(snp_pos_data), ignore.case=TRUE)
    if (length(pos_cols) > 0) {
        Xpos <- snp_pos_data[,pos_cols[1]]
        cat("Using position column:", colnames(snp_pos_data)[pos_cols[1]], "\n")
    } else {
        stop("Cannot identify position column in SNP position data")
    }
}

if ("position" %in% colnames(cpg_pos_data)) {
    Ypos <- cpg_pos_data$position
    cat("Using 'position' column for CpGs\n")
} else if (ncol(cpg_pos_data) == 1) {
    Ypos <- cpg_pos_data[,1]
    cat("Using first column for CpG positions:", colnames(cpg_pos_data)[1], "\n")
} else {
    # Look for likely position column names
    pos_cols <- grep("pos|Position|coordinate|Coordinate", colnames(cpg_pos_data), ignore.case=TRUE)
    if (length(pos_cols) > 0) {
        Ypos <- cpg_pos_data[,pos_cols[1]]
        cat("Using position column:", colnames(cpg_pos_data)[pos_cols[1]], "\n")
    } else {
        stop("Cannot identify position column in CpG position data")
    }
}

# Ensure position vectors are numeric
Xpos <- as.numeric(Xpos)
Ypos <- as.numeric(Ypos)

# Ensure position vectors match matrix dimensions
names(Xpos) <- rownames(snp_pos_data)
names(Ypos) <- rownames(cpg_pos_data)

# Align position vectors with matrix row names
Xpos <- Xpos[rownames(X_raw)]
Ypos <- Ypos[rownames(Y_raw)]

# Format matrices for ctcisQTL (features as rows, samples as columns)
X <- X_raw  # SNPs x samples
Y <- Y_raw  # CpGs x samples

cat("Data formatting completed!\n")
cat("Matrix dimensions:\n")
cat("X (SNPs):", nrow(X), "x", ncol(X), "(features x samples)\n")
cat("Y (methylation):", nrow(Y), "x", ncol(Y), "(features x samples)\n")
cat("W (cell composition):", nrow(W), "x", ncol(W), "(samples x cell types)\n")
cat("C (covariates):", nrow(C), "x", ncol(C), "(samples x covariates)\n")
cat("Position vectors - Xpos:", length(Xpos), "Ypos:", length(Ypos), "\n")
cat("Xpos range:", min(Xpos, na.rm=TRUE), "-", max(Xpos, na.rm=TRUE), "\n")
cat("Ypos range:", min(Ypos, na.rm=TRUE), "-", max(Ypos, na.rm=TRUE), "\n")

# Verify dimensions match ctcisQTL requirements
if (length(Xpos) != nrow(X)) {
    cat("ERROR: Xpos length (", length(Xpos), ") != X rows (", nrow(X), ")\n")
    stop("Position vector dimension mismatch")
}

if (length(Ypos) != nrow(Y)) {
    cat("ERROR: Ypos length (", length(Ypos), ") != Y rows (", nrow(Y), ")\n")
    stop("Position vector dimension mismatch")
}

if (ncol(X) != ncol(Y)) {
    cat("ERROR: X samples (", ncol(X), ") != Y samples (", ncol(Y), ")\n")
    stop("Sample dimension mismatch")
}

if (ncol(X) != nrow(W) || ncol(X) != nrow(C)) {
    cat("ERROR: Sample counts don't match across matrices\n")
    stop("Sample dimension mismatch")
}

cat("All dimension checks passed!\n")

# Run ctcisQTL analysis
cat("\n=== Starting ctcisQTL Analysis ===\n")
results <- NULL

tryCatch({
    # Execute ctcisQTL with 1MB cis window
    cat("Running ctcisQTL with 1MB cis window...\n")
    results <- ctcisQTL(X=X, Y=Y, W=W, C=C, Xpos=Xpos, Ypos=Ypos, max.pos.diff=1000000)
    cat("ctcisQTL analysis completed successfully!\n")
}, error = function(e) {
    cat("ctcisQTL analysis failed:", conditionMessage(e), "\n")
    
    # Try without explicit max.pos.diff parameter
    tryCatch({
        cat("Trying without max.pos.diff parameter...\n")
        results <<- ctcisQTL(X=X, Y=Y, W=W, C=C, Xpos=Xpos, Ypos=Ypos)
        cat("ctcisQTL analysis completed with default parameters!\n")
    }, error = function(e2) {
        cat("Analysis failed with default parameters:", conditionMessage(e2), "\n")
        
        # Provide detailed debugging information
        cat("\nDebugging Information:\n")
        cat("X matrix: ", nrow(X), " features x ", ncol(X), " samples\n")
        cat("Y matrix: ", nrow(Y), " features x ", ncol(Y), " samples\n")
        cat("Xpos vector: length ", length(Xpos), ", range: ", min(Xpos, na.rm=TRUE), "-", max(Xpos, na.rm=TRUE), "\n")
        cat("Ypos vector: length ", length(Ypos), ", range: ", min(Ypos, na.rm=TRUE), "-", max(Ypos, na.rm=TRUE), "\n")
        cat("W matrix: ", nrow(W), " samples x ", ncol(W), " cell types\n")
        cat("C matrix: ", nrow(C), " samples x ", ncol(C), " covariates\n")
        
        # Check for missing values
        cat("Missing values check:\n")
        cat("X:", sum(is.na(X)), "missing\n")
        cat("Y:", sum(is.na(Y)), "missing\n")
        cat("W:", sum(is.na(W)), "missing\n")
        cat("C:", sum(is.na(C)), "missing\n")
        cat("Xpos:", sum(is.na(Xpos)), "missing\n")
        cat("Ypos:", sum(is.na(Ypos)), "missing\n")
    })
})

# Process and save results
if (!is.null(results)) {
    cat("\n=== Processing Results ===\n")
    cat("Results class:", class(results), "\n")
    
    if (is.data.frame(results) || is.matrix(results)) {
        cat("Results dimensions:", nrow(results), "x", ncol(results), "\n")
        cat("Column names:", paste(colnames(results), collapse=", "), "\n")
        
        # Display first few rows
        if (nrow(results) > 0) {
            cat("First 3 rows:\n")
            print(head(results, 3))
        }
        
        # Save results to TSV file
        output_file <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/mQTL_results.tsv"
        
        tryCatch({
            write.table(results, file=output_file, sep="\t", row.names=FALSE, quote=FALSE)
            cat("Results saved successfully to:", output_file, "\n")
            
            # Verify file creation
            if (file.exists(output_file)) {
                cat("File verification: SUCCESS\n")
                cat("File size:", file.size(output_file), "bytes\n")
                
                # Analysis summary
                if (is.data.frame(results)) {
                    cat("\n=== Analysis Summary ===\n")
                    cat("Total associations tested:", nrow(results), "\n")
                    
                    if ("celltype" %in% colnames(results)) {
                        cat("Cell types analyzed:", paste(unique(results$celltype), collapse=", "), "\n")
                    }
                    
                    if ("p.value" %in% colnames(results)) {
                        sig_05 <- sum(results$p.value < 0.05, na.rm=TRUE)
                        sig_001 <- sum(results$p.value < 0.001, na.rm=TRUE)
                        cat("Significant associations (p < 0.05):", sig_05, "\n")
                        cat("Highly significant (p < 0.001):", sig_001, "\n")
                    }
                }
            }
        }, error = function(e) {
            cat("Error saving results:", conditionMessage(e), "\n")
            
            # Save key results in summary if file generation fails
            if (is.data.frame(results) && nrow(results) > 0) {
                cat("\n=== Key Results Summary ===\n")
                cat("Total associations:", nrow(results), "\n")
                if ("p.value" %in% colnames(results)) {
                    top_hits <- results[order(results$p.value)[1:min(5, nrow(results))], ]
                    cat("Top 5 associations:\n")
                    print(top_hits)
                }
            }
        })
    } else {
        cat("Unexpected results format. Structure:\n")
        str(results)
    }
} else {
    cat("ERROR: ctcisQTL analysis failed - no results generated\n")
    cat("Please check input data formatting and function parameters\n")
}

cat("\nAnalysis complete.\n")
