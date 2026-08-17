#!/bin/bash

# STAR alignment with chimeric detection parameters for fusion gene detection
OUTPUT_DIR="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430"
FASTQ1="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430/data/K562f_1.fq.gz"
FASTQ2="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430/data/K562f_2.fq.gz"
STAR_INDEX="/mnt/data/ims/genome/references/wts/STARIndex/"
GTF_FILE="/mnt/data/ims/genome/references/wts/Annotation/ref_annot.gtf"

cd "$OUTPUT_DIR"

# Run STAR alignment with chimeric detection parameters
STAR \
  --genomeDir "$STAR_INDEX" \
  --readFilesIn "$FASTQ1" "$FASTQ2" \
  --readFilesCommand zcat \
  --runThreadN 8 \
  --outFileNamePrefix K562_ \
  --outSAMtype BAM SortedByCoordinate \
  --chimSegmentMin 15 \
  --chimJunctionOverhangMin 15 \
  --chimOutType Junctions SeparateSAMold \
  --chimSegmentReadGapMax 0 \
  --chimScoreMin 15 \
  --chimScoreDropMax 20 \
  --chimNonchimScoreDropMin 10 \
  --chimOutJunctionFormat 1

# Parse chimeric junction file to CSV format
python3 << 'EOF'
import pandas as pd

# Read STAR chimeric junction file
junction_file = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430/K562_Chimeric.out.junction"
output_csv = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430/K562_candidate_fusions.csv"

# Parse chimeric junction format (STAR format)
data = []
with open(junction_file, 'r') as f:
    for line in f:
        fields = line.strip().split('\t')
        if len(fields) >= 14:
            chr1 = fields[0]
            base1 = int(fields[1])
            strand1 = fields[2]
            chr2 = fields[3]  
            base2 = int(fields[4])
            strand2 = fields[5]
            junction_type = fields[6]
            read_name = fields[9]
            
            data.append({
                'chr1': chr1,
                'base1': base1,
                'strand1': strand1,
                'chr2': chr2,
                'base2': base2,
                'strand2': strand2,
                'junction_type': junction_type,
                'read_name': read_name
            })

# Create DataFrame and save to CSV
df = pd.DataFrame(data)
df.to_csv(output_csv, index=False)

print(f"Generated {len(df)} candidate fusion junctions")
print(f"Output files:")
print(f"- {junction_file}")
print(f"- {output_csv}")
EOF
