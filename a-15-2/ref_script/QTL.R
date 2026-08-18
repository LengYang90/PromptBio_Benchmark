library(omicwas)

task_dir <- dirname(dirname(normalizePath(sys.frames()[[1]]$ofile, mustWork = FALSE)))

X    <- read.csv(file.path(task_dir, "data", "Matrix_of_SNP_genotypes.csv"), row.names = 1)
W    <- read.csv(file.path(task_dir, "data", "Matrix_of_cell_type_composition.csv"), row.names = 1)
Y    <- read.csv(file.path(task_dir, "data", "Matrix_of_bulk_omics_measurements.csv"), row.names = 1)
C    <- read.csv(file.path(task_dir, "data", "Matrix_of_ovariates.csv"), row.names = 1)
Xpos <- read.csv(file.path(task_dir, "data", "Matrix_of_trait_positions.csv"), row.names = 1)$Position
Ypos <- read.csv(file.path(task_dir, "data", "Matrix_of_bulk_omics_positions.csv"), row.names = 1)$Position

ctcisQTL(X, Xpos, W, Y, Ypos, C = C)
results <- read.table(file.path(tempdir(), "ctcisQTL.out.txt"), header = TRUE, sep = "\t")
write.table(results,
    file      = file.path(task_dir, "ref_answer", "mQTL_results.txt"),
    sep       = "\t",
    row.names = FALSE,
    quote     = FALSE)
