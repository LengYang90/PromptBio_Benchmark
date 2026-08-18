# Load required libraries
library(data.table)

# Define base path
base_path <- "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516"

# Read position data
snp_pos <- read.csv(file.path(base_path, "snp_positions_formatted.csv"))
methylation_pos <- read.csv(file.path(base_path, "methylation_positions_formatted.csv"))

# Create cis-window pairs within 1 Mb (1,000,000 bp)
cis_window <- 1000000
cis_pairs <- data.frame()

for(i in 1:nrow(snp_pos)) {
  for(j in 1:nrow(methylation_pos)) {
    snp_chr <- snp_pos$CHR[i]
    cpg_chr <- methylation_pos$CHR[j]
    snp_pos_bp <- snp_pos$POS[i]
    cpg_pos_bp <- methylation_pos$POS[j]
    
    # Check if on same chromosome and within 1 Mb distance
    if(snp_chr == cpg_chr) {
      distance <- abs(snp_pos_bp - cpg_pos_bp)
      if(distance <= cis_window) {
        cis_pairs <- rbind(cis_pairs, data.frame(
          SNP = snp_pos$SNP[i],
          CpG = methylation_pos$CpG[j],
          SNP_CHR = snp_chr,
          SNP_POS = snp_pos_bp,
          CpG_CHR = cpg_chr,
          CpG_POS = cpg_pos_bp,
          Distance = distance
        ))
      }
    }
  }
}

# Save cis pairs dataframe
write.csv(cis_pairs, file.path(base_path, "cis_pairs_1mb.csv"), row.names = FALSE)

print(paste("Created", nrow(cis_pairs), "valid cis SNP-CpG pairs within 1 Mb"))
print("Distance distribution:")
print(summary(cis_pairs$Distance))
print("First 10 cis pairs:")
print(head(cis_pairs, 10))
