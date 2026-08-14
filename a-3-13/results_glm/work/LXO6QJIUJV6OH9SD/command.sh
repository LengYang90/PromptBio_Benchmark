#!/bin/bash
set -e

FASTA="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-13/result_714/toolsgenie_20260714/trinity_out.Trinity.fasta"
GENE_TRANS_MAP="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-13/result_714/toolsgenie_20260714/trinity_out.Trinity.fasta.gene_trans_map"

# 1. File exists and is non-empty
if [ ! -s "$FASTA" ]; then
  echo "ERROR: FASTA file missing or empty: $FASTA" >&2
  exit 1
fi
echo "=== 1. File Check ==="
echo "Path: $FASTA"
echo "Size: $(stat -c%s "$FASTA") bytes"

# 2. Count total transcripts
echo "=== 2. Total Transcripts ==="
grep -c ">" "$FASTA"

# 3. First 5 transcript headers
echo "=== 3. First 5 Transcript Headers ==="
grep ">" "$FASTA" | head -n 5

# 4. Basic statistics using awk (handles multi-line FASTA)
echo "=== 4. Transcript Length Statistics ==="
awk 'BEGIN{tot=0;n=0;min=1e9;max=0;seqlen=0}
     /^>/{
       if(n>0){
         tot+=seqlen;
         if(seqlen<min)min=seqlen;
         if(seqlen>max)max=seqlen;
       }
       n++;
       seqlen=0;
       next
     }
     {seqlen+=length($0)}
     END{
       if(n>0){
         tot+=seqlen;
         if(seqlen<min)min=seqlen;
         if(seqlen>max)max=seqlen;
         printf "Total bases: %d\nTranscripts: %d\nMin length: %d\nMax length: %d\nMean length: %.2f\n", tot, n, min, max, tot/n
       }
     }' "$FASTA"

# 5. Validate FASTA format (multi-line FASTA: headers start with ">", sequence lines do not)
echo "=== 5. FASTA Format Validation ==="
awk 'BEGIN{headers=0;seqlines=0;first=1}
     /^>/{headers++;first=0;next}
     {
       if(first==1 && NF>0){
         print "INVALID: line " NR " - sequence data before first header"
         exit 1
       }
       if(NF>0) seqlines++
     }
     END{
       if(headers==0){
         print "INVALID: no headers found"
         exit 1
       }
       if(seqlines==0){
         print "INVALID: no sequence lines found"
         exit 1
       }
       print "VALID: " headers " headers, " seqlines " sequence lines, " NR " total lines"
     }' "$FASTA"

# 6. Check gene_trans_map file exists and is non-empty
echo "=== 6. Gene-Trans Map File ==="
if [ ! -s "$GENE_TRANS_MAP" ]; then
  echo "ERROR: gene_trans_map file missing or empty: $GENE_TRANS_MAP" >&2
  exit 1
fi
echo "Path: $GENE_TRANS_MAP"
echo "Size: $(stat -c%s "$GENE_TRANS_MAP") bytes"
echo "Line count: $(wc -l < "$GENE_TRANS_MAP")"
echo "First 3 lines:"
head -n 3 "$GENE_TRANS_MAP"
