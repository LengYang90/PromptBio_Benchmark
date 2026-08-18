library(data.table)
library(ggplot2)

task_dir <- dirname(dirname(normalizePath(sys.frames()[[1]]$ofile, mustWork = FALSE)))

ChIPreads <- fread(file.path(task_dir, "data", "ChIP_data.csv"))
end.counts <- ChIPreads[, list(count = .N), by = list(experiment, chrom, chromEnd)]
aligned.dt <- rbind(
    ChIPreads[, .(bases.counted = "each", experiment, chrom, chromStart, chromEnd, count = 1)],
    end.counts[, .(bases.counted = "end", experiment, chrom, chromStart = chromEnd - 1L, chromEnd, count)]
)
seq.dt <- aligned.dt[, {
    event.dt <- rbind(
        data.table(count, pos = chromStart + 1L),
        data.table(count = -count, pos = chromEnd + 1L))
    edge.vec <- event.dt[, { as.integer(seq(min(pos), max(pos), l = 100)) }]
    event.bins <- rbind(event.dt, data.table(count = 0L, pos = edge.vec))
    total.dt <- event.bins[, .(count = sum(count)), by = list(pos)][order(pos)]
    total.dt[, cum := cumsum(count)]
    total.dt[, bin.i := cumsum(pos %in% edge.vec)]
    total.dt[, data.table(
        chromStart = pos[-.N] - 1L,
        chromEnd   = pos[-1] - 1L,
        count      = cum[-.N],
        bin.i      = bin.i[-.N])]
}, by = list(bases.counted, experiment, chrom)]
tmp_dir <- file.path(task_dir, "tmp")
segs.dt <- seq.dt[, {
    data.dir <- file.path(tmp_dir, bases.counted, experiment)
    dir.create(data.dir, showWarnings = FALSE, recursive = TRUE)
    coverage.bedGraph <- file.path(data.dir, "coverage.bedGraph")
    fwrite(.SD[, .(chrom, chromStart, chromEnd, count)], coverage.bedGraph,
        sep = "\t", quote = FALSE, col.names = FALSE)
    fit <- PeakSegDisk::sequentialSearch_dir(data.dir, 2L, verbose = 1)
    data.table(fit$segments, data.type = "model")
}, by = list(bases.counted, experiment)]
changes.dt <- segs.dt[, { .SD[-1] }, by = list(bases.counted, experiment, data.type)]
gg.model <- ggplot() +
    theme_bw() +
    theme(panel.spacing = grid::unit(0, "lines")) +
    facet_grid(bases.counted ~ experiment, scales = "free", labeller = label_both) +
    geom_step(aes(chromStart / 1e3, count, color = data.type),
        data = data.table(seq.dt, data.type = "exact")) +
    scale_color_manual(values = c(exact = "black", bins = "red", model = "deepskyblue")) +
    scale_x_continuous("Position on hg19 chrom (kb = kilo bases)") +
    geom_segment(aes(chromStart / 1e3, mean, xend = chromEnd / 1e3, yend = mean, color = data.type),
        data = segs.dt) +
    geom_vline(aes(xintercept = chromEnd / 1e3, color = data.type), data = changes.dt)
ggsave(file.path(task_dir, "ref_answer", "segmentation_model_plot.png"), gg.model, width = 8, height = 6)
