#!/bin/bash
set -e

OUTDIR="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-13/result_714/toolsgenie_20260714"
TRINITY_OUT="${OUTDIR}/trinity_out"
FINAL_FILE="${OUTDIR}/trinity_out.Trinity.fasta"
LEFT="${OUTDIR}/data/SRX9161265_SRR12681119_2k_1.fastq.gz"
RIGHT="${OUTDIR}/data/SRX9161265_SRR12681119_2k_2.fastq.gz"

# ---------------------------------------------------------------------------
# Step 1: Ensure Trinity is available; install if missing
# ---------------------------------------------------------------------------
if ! command -v Trinity &> /dev/null; then
  echo "Trinity not found in PATH. Attempting installation via conda/mamba..."

  if command -v mamba &> /dev/null; then
    echo "Using mamba to install trinity from bioconda..."
    mamba install -y -c bioconda trinity
  elif command -v conda &> /dev/null; then
    echo "Using conda to install trinity from bioconda..."
    conda install -y -c bioconda trinity
  else
    echo "ERROR: Neither conda nor mamba is available to install Trinity." >&2
    echo "Please install Trinity manually (e.g., from https://github.com/trinityrnaseq/trinityrnaseq)" >&2
    exit 1
  fi

  # Re-check after installation
  if ! command -v Trinity &> /dev/null; then
    echo "ERROR: Trinity still not found after installation attempt." >&2
    exit 1
  fi
fi

echo "Trinity found: $(which Trinity)"
Trinity --version 2>&1 || true

# ---------------------------------------------------------------------------
# Step 2: Clean up any partial previous output
# ---------------------------------------------------------------------------
if [ -d "${TRINITY_OUT}" ]; then
  echo "Removing previous partial Trinity output directory: ${TRINITY_OUT}"
  rm -rf "${TRINITY_OUT}"
fi

# ---------------------------------------------------------------------------
# Step 3: Run Trinity de novo transcriptome assembly
# ---------------------------------------------------------------------------
Trinity --seqType fq \
  --left "${LEFT}" \
  --right "${RIGHT}" \
  --CPU 4 \
  --max_memory 8G \
  --output "${TRINITY_OUT}"

# ---------------------------------------------------------------------------
# Step 4: Locate and copy the final assembly to the required path
# ---------------------------------------------------------------------------
# Trinity v2.15.2 may write the final filtered assembly directly to
# ${FINAL_FILE} (via filter_transcripts_require_min_cov.pl redirect),
# so the conventional ${TRINITY_OUT}/Trinity.fasta may not exist.
if [ -f "${TRINITY_OUT}/Trinity.fasta" ]; then
  cp "${TRINITY_OUT}/Trinity.fasta" "${FINAL_FILE}"
  echo "Copied ${TRINITY_OUT}/Trinity.fasta -> ${FINAL_FILE}"
elif [ -f "${FINAL_FILE}" ]; then
  echo "Final assembly already present at ${FINAL_FILE} (written directly by Trinity)"
else
  echo "ERROR: Could not locate Trinity assembly output." >&2
  echo "Neither ${TRINITY_OUT}/Trinity.fasta nor ${FINAL_FILE} exists." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 5: Verify output
# ---------------------------------------------------------------------------
echo "Done. Final output: ${FINAL_FILE}"
echo "Transcript count:"
grep -c ">" "${FINAL_FILE}"
echo "First 2 transcript headers:"
grep ">" "${FINAL_FILE}" | head -n 2
