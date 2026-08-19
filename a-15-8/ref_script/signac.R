# https://stuartlab.org/signac/articles/pbmc_multiomic
library(Signac)
library(Seurat)
library(EnsDb.Hsapiens.v86)
library(BSgenome.Hsapiens.UCSC.hg38)

task_dir <- dirname(dirname(normalizePath(sys.frames()[[1]]$ofile, mustWork = FALSE)))

counts   <- Read10X_h5(file.path(task_dir, "data", "pbmc_granulocyte_sorted_10k_filtered_feature_bc_matrix.h5"))
fragpath <- file.path(task_dir, "data", "pbmc_granulocyte_sorted_10k_atac_fragments.tsv.gz")

annotation <- GetGRangesFromEnsDb(ensdb = EnsDb.Hsapiens.v86)
seqlevels(annotation) <- paste0('chr', seqlevels(annotation))

pbmc <- CreateSeuratObject(counts = counts$`Gene Expression`, assay = "RNA")

pbmc[["ATAC"]] <- CreateChromatinAssay(
    counts = counts$Peaks, sep = c(":", "-"),
    fragments = fragpath, annotation = annotation)

DefaultAssay(pbmc) <- "ATAC"
pbmc <- NucleosomeSignal(pbmc)
pbmc <- TSSEnrichment(pbmc)
pbmc <- subset(x = pbmc,
    subset = nCount_ATAC < 100000 & nCount_RNA < 25000 &
             nCount_ATAC > 1800   & nCount_RNA > 1000 &
             nucleosome_signal < 2 & TSS.enrichment > 1)

DefaultAssay(pbmc) <- "RNA"
pbmc <- SCTransform(pbmc)
pbmc <- RunPCA(pbmc)

DefaultAssay(pbmc) <- "ATAC"
pbmc <- FindTopFeatures(pbmc, min.cutoff = 5)
pbmc <- RunTFIDF(pbmc)
pbmc <- RunSVD(pbmc)

pbmc_single <- RunUMAP(pbmc, reduction = "lsi", verbose = TRUE, dims = 2:40)
pbmc_single <- FindNeighbors(pbmc_single, reduction = 'lsi', dims = 2:30)
pbmc_single <- FindClusters(pbmc_single, verbose = FALSE, algorithm = 3)

pbmc <- FindMultiModalNeighbors(pbmc,
    reduction.list = list("pca", "lsi"), dims.list = list(1:50, 2:40),
    modality.weight.name = "RNA.weight", verbose = TRUE)
pbmc <- RunUMAP(pbmc, nn.name = "weighted.nn", assay = "RNA", verbose = TRUE)
pbmc <- FindClusters(pbmc, graph.name = "wsnn", algorithm = 3, verbose = FALSE)

png(file.path(task_dir, "ref_answer", "umap_multiple.png"), width = 960, height = 480)
p1 <- DimPlot(pbmc_single, label = TRUE) + NoLegend() + ggtitle("ATAC only")
p2 <- DimPlot(pbmc,        label = TRUE) + NoLegend() + ggtitle("Joint RNA+ATAC")
print(p1 | p2)
dev.off()
