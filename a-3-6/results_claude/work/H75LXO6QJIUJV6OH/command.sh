#!/bin/bash

OUTPUT_DIR="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430"
JUNCTION_FILE="$OUTPUT_DIR/K562_Chimeric.out.junction"
CSV_FILE="$OUTPUT_DIR/K562_candidate_fusions.csv"

echo "=== File Validation and Summary Statistics ==="
echo

# Check file existence and basic info
echo "1. File Validation:"
ls -lh "$JUNCTION_FILE" "$CSV_FILE"
echo

# Display first few rows of junction file
echo "2. K562_Chimeric.out.junction (first 5 rows):"
head -5 "$JUNCTION_FILE"
echo

# Display first few rows of CSV file  
echo "3. K562_candidate_fusions.csv (first 5 rows):"
head -5 "$CSV_FILE"
echo

# Generate summary statistics using Python
python3 << 'EOF'
import pandas as pd

junction_file = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430/K562_Chimeric.out.junction"
csv_file = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430/K562_candidate_fusions.csv"

print("4. Summary Statistics:")
print()

# Junction file statistics
with open(junction_file, 'r') as f:
    junction_lines = sum(1 for line in f)
print(f"Junction file total lines: {junction_lines}")

# CSV file analysis
df = pd.read_csv(csv_file)
print(f"CSV file total records: {len(df)}")
print()

print("5. Chromosome Distribution:")
chr1_counts = df['chr1'].value_counts().head(10)
chr2_counts = df['chr2'].value_counts().head(10)
print("Top 10 chr1 frequencies:")
print(chr1_counts)
print("\nTop 10 chr2 frequencies:")
print(chr2_counts)
print()

print("6. Junction Types:")
junction_type_counts = df['junction_type'].value_counts()
print(junction_type_counts)
print()

print("7. Strand Distribution:")
print("Strand1 distribution:")
print(df['strand1'].value_counts())
print("Strand2 distribution:")
print(df['strand2'].value_counts())
print()

print("8. Unique Chromosomes Involved:")
unique_chr1 = set(df['chr1'].unique())
unique_chr2 = set(df['chr2'].unique())
all_chromosomes = sorted(unique_chr1.union(unique_chr2))
print(f"Total unique chromosomes: {len(all_chromosomes)}")
print(f"Chromosomes: {all_chromosomes}")
print()

print("9. Inter vs Intra-chromosomal Fusions:")
inter_chr = df[df['chr1'] != df['chr2']]
intra_chr = df[df['chr1'] == df['chr2']]
print(f"Inter-chromosomal fusions: {len(inter_chr)} ({len(inter_chr)/len(df)*100:.1f}%)")
print(f"Intra-chromosomal fusions: {len(intra_chr)} ({len(intra_chr)/len(df)*100:.1f}%)")
EOF
