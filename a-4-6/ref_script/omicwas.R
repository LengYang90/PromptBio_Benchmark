library(omicwas)

task_dir <- dirname(dirname(normalizePath(sys.frames()[[1]]$ofile, mustWork = FALSE)))

X <- read.csv(file.path(task_dir, "data", "Matrix_of_traits.csv"), row.names = 1)
W <- read.csv(file.path(task_dir, "data", "Matrix_of_cell_type_composition.csv"), row.names = 1)
Y <- read.csv(file.path(task_dir, "data", "Matrix_of_bulk_omics_measurements.csv"), row.names = 1)
C <- read.csv(file.path(task_dir, "data", "Matrix_of_ovariates.csv"), row.names = 1)

result <- ctassoc(X, W, Y, C = C, test = "nls.logit", regularize = TRUE)

write.table(result$coefficients,
    file = file.path(task_dir, "ref_answer", "dna_methylation_results.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE)
