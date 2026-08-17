#!/bin/bash
set -euo pipefail

# Install Comet MS search tool via Bioconda
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda install -y comet-ms

# Define absolute paths
OUTPUT_DIR="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_11/toolsgenie_20260623"
MZML_PATH="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_11/toolsgenie_20260623/data/BSA2_F1.mzML"
FASTA_PATH="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_11/toolsgenie_20260623/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta"
COMET_PARAMS="${OUTPUT_DIR}/comet.params"
RAW_COMET_OUTPUT="${OUTPUT_DIR}/BSA2_F1_raw.txt"
FINAL_OUTPUT="${OUTPUT_DIR}/BSA2_F1_comet_psm.tsv"

# Generate default Comet parameter file
cd "${OUTPUT_DIR}"
comet -p
# Rename generated default parameter file to target path
mv comet.params.new "${COMET_PARAMS}"

# Update parameters to match required search settings
sed -i "s#^database_name =.*#database_name = ${FASTA_PATH}#" "${COMET_PARAMS}"
sed -i 's/^enzyme = .*/enzyme = 1/' "${COMET_PARAMS}" # 1 = Trypsin (K/R no cleavage before P)
sed -i 's/^missed_cleavages = .*/missed_cleavages = 2/' "${COMET_PARAMS}"
sed -i 's/^precursor_tolerance = .*/precursor_tolerance = 10/' "${COMET_PARAMS}"
sed -i 's/^precursor_tolerance_units = .*/precursor_tolerance_units = 2/' "${COMET_PARAMS}" # 2 = ppm
sed -i 's/^fragment_tolerance = .*/fragment_tolerance = 0.02/' "${COMET_PARAMS}"
sed -i 's/^fragment_tolerance_units = .*/fragment_tolerance_units = 0/' "${COMET_PARAMS}" # 0 = Da
sed -i 's/^num_fixed_mods = .*/num_fixed_mods = 1/' "${COMET_PARAMS}"
sed -i 's/^fixed_mod0 = .*/fixed_mod0 = 57.021464 C/' "${COMET_PARAMS}" # Carbamidomethylation on cysteine
sed -i 's/^num_variable_mods = .*/num_variable_mods = 1/' "${COMET_PARAMS}"
sed -i 's/^variable_mod0 = .*/variable_mod0 = 15.994915 M/' "${COMET_PARAMS}" # Oxidation on methionine
sed -i 's/^output_format = .*/output_format = 1/' "${COMET_PARAMS}" # 1 = tab-separated text output

# Run Comet search
comet -P "${COMET_PARAMS}" -o "${RAW_COMET_OUTPUT}" "${MZML_PATH}"

# Extract required columns, clean peptide sequence, write final TSV
echo -e "spectrum_id\tpeptide_sequence\tcharge\tprotein_accession" > "${FINAL_OUTPUT}"
awk 'NR>1 {
    gsub(/\[[^]]+\]/, "", $2) # Remove modification annotations from peptide sequence
    print $19 "\t" $2 "\t" $7 "\t" $1
}' "${RAW_COMET_OUTPUT}" >> "${FINAL_OUTPUT}"

# Remove intermediate files
rm -f "${COMET_PARAMS}" "${RAW_COMET_OUTPUT}"
