# Restart R session and install packages with proper version management
# Clear workspace and detach packages
rm(list = ls())

# Update rlang first to resolve version conflict
if (!require("rlang", quietly = TRUE)) {
    install.packages("rlang")
} else {
    # Check rlang version and update if needed
    rlang_version <- packageVersion("rlang")
    if (rlang_version < "1.1.7") {
        cat("Updating rlang from", as.character(rlang_version), "to latest version...\n")
        remove.packages("rlang")
        install.packages("rlang")
    }
}

# Install devtools if not available
if (!require("devtools", quietly = TRUE)) {
    install.packages("devtools")
}

# Install required dependencies explicitly
required_packages <- c("Rcpp", "glmnet", "matrixStats", "data.table", "broom")
for (pkg in required_packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
        cat("Installing", pkg, "...\n")
        install.packages(pkg)
    }
}

# Try installing omicwas with explicit dependency management
cat("Installing omicwas package...\n")
tryCatch({
    devtools::install_github("cran/omicwas", dependencies = TRUE, force = TRUE)
}, error = function(e) {
    cat("GitHub installation failed, trying CRAN...\n")
    install.packages("omicwas")
})

# Load the omicwas library with error handling
library_loaded <- FALSE
tryCatch({
    library(omicwas)
    library_loaded <- TRUE
    cat("omicwas library loaded successfully!\n")
}, error = function(e) {
    cat("Error loading omicwas:", conditionMessage(e), "\n")
    cat("Attempting alternative approach...\n")
    
    # Try restarting R session approach
    .rs.restartR()
    Sys.sleep(2)
    library(omicwas)
    library_loaded <<- TRUE
})

# Verify ctcisQTL function is available
if (library_loaded && exists("ctcisQTL")) {
    cat("ctcisQTL function is available!\n")
} else {
    cat("ctcisQTL function not found. Checking package contents...\n")
    if (library_loaded) {
        cat("Available functions in omicwas:\n")
        print(ls("package:omicwas"))
    }
}

# Load formatted data matrices
cat("Loading formatted data matrices...\n")
X <- as.matrix(read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/snp_genotypes_formatted.csv", row.names=1))
Y <- as.matrix(read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/methylation_formatted.csv", row.names=1))
W <- as.matrix(read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/cell_composition_formatted.csv", row.names=1))
C <- as.matrix(read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/covariates_formatted.csv", row.names=1))

# Load position vectors
Xpos <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/snp_positions_formatted.csv", row.names=1)$position
Ypos <- read.csv("/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/methylation_positions_formatted.csv", row.names=1)$position

cat("Data loaded successfully!\n")
cat("Matrix dimensions:\n")
cat("X (SNPs):", nrow(X), "x", ncol(X), "\n")
cat("Y (methylation):", nrow(Y), "x", ncol(Y), "\n")
cat("W (cell composition):", nrow(W), "x", ncol(W), "\n")
cat("C (covariates):", nrow(C), "x", ncol(C), "\n")
cat("Position vectors - Xpos:", length(Xpos), "Ypos:", length(Ypos), "\n")

# Run ctcisQTL analysis with comprehensive error handling
cat("\n=== Starting ctcisQTL Analysis ===\n")

# Initialize results variable in global scope
results <- NULL
analysis_success <- FALSE

# Execute the analysis with multiple fallback approaches
if (library_loaded && exists("ctcisQTL")) {
    
    cat("Attempting ctcisQTL analysis...\n")
    
    # Method 1: Standard parameter approach
    tryCatch({
        cat("Method 1: Standard parameters\n")
        results <- ctcisQTL(X=X, Y=Y, W=W, C=C, Xpos=Xpos, Ypos=Ypos, cis=1000000)
        analysis_success <- TRUE
        cat("Method 1 SUCCESS!\n")
    }, error = function(e1) {
        cat("Method 1 failed:", conditionMessage(e1), "\n")
        
        # Method 2: Positional parameters
        tryCatch({
            cat("Method 2: Positional parameters\n")
            results <<- ctcisQTL(X, Y, W, C, Xpos, Ypos, 1000000)
            analysis_success <<- TRUE
            cat("Method 2 SUCCESS!\n")
        }, error = function(e2) {
            cat("Method 2 failed:", conditionMessage(e2), "\n")
            
            # Method 3: Without explicit cis parameter
            tryCatch({
                cat("Method 3: Default cis window\n")
                results <<- ctcisQTL(X, Y, W, C, Xpos, Ypos)
                analysis_success <<- TRUE
                cat("Method 3 SUCCESS!\n")
            }, error = function(e3) {
                cat("Method 3 failed:", conditionMessage(e3), "\n")
                cat("All methods failed. Error details:\n")
                cat("Error 1:", conditionMessage(e1), "\n")
                cat("Error 2:", conditionMessage(e2), "\n")
                cat("Error 3:", conditionMessage(e3), "\n")
            })
        })
    })
    
} else {
    cat("ERROR: omicwas library not loaded or ctcisQTL function not available\n")
    cat("Cannot proceed with analysis\n")
}

# Verify and process results
if (analysis_success && !is.null(results)) {
    
    cat("\n=== Analysis Completed Successfully! ===\n")
    cat("Results object class:", class(results), "\n")
    
    if (is.data.frame(results) || is.matrix(results)) {
        cat("Results dimensions:", nrow(results), "x", ncol(results), "\n")
        cat("Column names:", paste(colnames(results), collapse=", "), "\n")
        
        # Display first few rows
        cat("\nFirst 3 rows of results:\n")
        if (nrow(results) >= 3) {
            print(head(results, 3))
        } else {
            print(results)
        }
        
    } else {
        cat("Results structure:\n")
        str(results)
    }
    
    # Save results to TSV file with error handling
    output_file <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/mQTL_results.tsv"
    
    cat("\n=== Saving Results ===\n")
    save_success <- FALSE
    
    tryCatch({
        write.table(results, file=output_file, sep="\t", row.names=FALSE, quote=FALSE)
        save_success <- TRUE
        cat("Results saved successfully to:", output_file, "\n")
    }, error = function(e) {
        cat("TSV save failed:", conditionMessage(e), "\n")
        
        # Try CSV as backup
        tryCatch({
            csv_file <- gsub(".tsv", ".csv", output_file)
            write.csv(results, file=csv_file, row.names=FALSE)
            cat("Results saved as CSV:", csv_file, "\n")
            save_success <<- TRUE
        }, error = function(e2) {
            cat("CSV save also failed:", conditionMessage(e2), "\n")
            
            # Save as RData for debugging
            rdata_file <- gsub(".tsv", ".RData", output_file)
            save(results, file=rdata_file)
            cat("Results saved as RData for debugging:", rdata_file, "\n")
        })
    })
    
    # Verify file creation and provide summary
    if (file.exists(output_file)) {
        cat("\n=== SUCCESS: Final Output Created ===\n")
        cat("File:", output_file, "\n")
        cat("Size:", file.size(output_file), "bytes\n")
        
        # Provide analysis summary
        if (is.data.frame(results)) {
            cat("\n=== Analysis Summary ===\n")
            cat("Total associations tested:", nrow(results), "\n")
            
            if ("celltype" %in% colnames(results)) {
                cat("Cell types analyzed:", paste(unique(results$celltype), collapse=", "), "\n")
                cat("Associations per cell type:\n")
                print(table(results$celltype))
            }
            
            if ("p.value" %in% colnames(results)) {
                sig_05 <- sum(results$p.value < 0.05, na.rm=TRUE)
                sig_001 <- sum(results$p.value < 0.001, na.rm=TRUE)
                cat("Significant associations (p < 0.05):", sig_05, "\n")
                cat("Highly significant (p < 0.001):", sig_001, "\n")
            }
        }
        
    } else {
        cat("WARNING: Output file verification failed\n")
    }
    
} else {
    cat("\n=== ANALYSIS FAILED ===\n")
    cat("Results object is NULL or analysis did not complete\n")
    
    # Provide diagnostic information
    cat("\nDiagnostic Information:\n")
    cat("Library loaded:", library_loaded, "\n")
    cat("ctcisQTL exists:", exists("ctcisQTL"), "\n")
    cat("Results is NULL:", is.null(results), "\n")
    cat("Analysis success flag:", analysis_success, "\n")
}

cat("\n=== Analysis Session Complete ===\n")
