#!/usr/bin/env Rscript
suppressPackageStartupMessages({ library(MendelianRandomization) })

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
task_dir <- dirname(dirname(normalizePath(script_path, mustWork = FALSE)))

exp   <- read.csv(file.path(task_dir, "data", "snp_exp.csv"),   stringsAsFactors = FALSE)
pheno <- read.csv(file.path(task_dir, "data", "snp_pheno.csv"), stringsAsFactors = FALSE)

common_snps <- intersect(exp$SNP, pheno$SNP)
exp   <- exp[exp$SNP %in% common_snps, ]
pheno <- pheno[match(exp$SNP, pheno$SNP), ]

for (i in seq_len(nrow(exp))) {
  if (exp$effect_allele[i] != pheno$effect_allele[i])
    pheno$beta_pheno[i] <- -pheno$beta_pheno[i]
}

mr_input <- mr_input(bx = exp$beta_exp, bxse = exp$se_exp,
                     by = pheno$beta_pheno, byse = pheno$se_pheno, snps = exp$SNP)

ivw   <- mr_ivw(mr_input)
egger <- mr_egger(mr_input)

result <- data.frame(
    Method = c("IVW", "Egger"),
    Beta   = c(ivw$Estimate,   egger$Estimate),
    SE     = c(ivw$StdError,   egger$StdError.Est),
    P      = c(ivw$Pvalue,     egger$Pvalue.Est))

write.csv(result, file.path(task_dir, "ref_answer", "mr_result_summary.csv"), row.names = FALSE, quote = FALSE)
