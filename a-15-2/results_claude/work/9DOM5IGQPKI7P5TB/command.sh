# First, try to install omicwas from different sources
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

if (omicwas_installed) {
  # Try to load omicwas and get help
  tryCatch({
    library(omicwas)
    print("omicwas package successfully loaded!")
    
    # Check available functions
    print("Available functions in omicwas package:")
    print(ls("package:omicwas"))
    
    # Try to get help for ctcisQTL
    if (exists("ctcisQTL")) {
      print("ctcisQTL function found. Getting help documentation:")
      help(ctcisQTL)
      print("Function signature:")
      print(args(ctcisQTL))
    } else {
      print("ctcisQTL function not found. Available QTL-related functions:")
      available_functions <- ls("package:omicwas")
      qtl_functions <- available_functions[grepl("qtl|QTL|cis", available_functions, ignore.case = TRUE)]
      print(qtl_functions)
    }
    
  }, error = function(e) {
    print(paste("Error loading omicwas:", e$message))
    omicwas_installed <- FALSE
  })
}

if (!omicwas_installed) {
  print("omicwas package installation failed. Using MatrixEQTL alternative approach:")
  
  # Install and load MatrixEQTL as alternative
  if (!require("MatrixEQTL", quietly = TRUE)) {
    install.packages("MatrixEQTL")
  }
  library(MatrixEQTL)
  
  print("MatrixEQTL loaded successfully as alternative for cell-type-specific QTL analysis")
  print("MatrixEQTL main function signature:")
  print(args(Matrix_eQTL_main))
  
  # Show how to perform cell-type-specific analysis with MatrixEQTL
  print("Cell-type-specific QTL analysis can be performed using MatrixEQTL by:")
  print("1. Including cell type proportions as covariates")
  print("2. Running separate analyses for each cell type")
  print("3. Using interaction terms for cell-type-specific effects")
  print("4. Using the Matrix_eQTL_main function with appropriate parameters:")
  print("   - snps: SNP genotype matrix")
  print("   - gene: methylation/expression matrix") 
  print("   - cvrt: covariate matrix (including cell type proportions)")
  print("   - output_file_name: output file path")
  print("   - pvOutputThreshold: p-value threshold")
  print("   - useModel: modelLINEAR for linear models")
  print("   - snpspos: SNP position matrix")
  print("   - genepos: gene/CpG position matrix")
  print("   - cisDist: cis distance threshold (1e6 for 1Mb)")
  
  # Provide example parameter structure
  cat("\nExample MatrixEQTL usage for cell-type-specific analysis:\n")
  cat("me = Matrix_eQTL_main(\n")
  cat("  snps = snps,\n")
  cat("  gene = gene_expression,\n") 
  cat("  cvrt = covariates,\n")
  cat("  output_file_name = 'mQTL_results.txt',\n")
  cat("  pvOutputThreshold = 1e-5,\n")
  cat("  useModel = modelLINEAR,\n")
  cat("  snpspos = snpspos,\n")
  cat("  genepos = genepos,\n")
  cat("  cisDist = 1e6\n")
  cat(")\n")
}
