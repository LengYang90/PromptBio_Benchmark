set -euo pipefail

# Define absolute paths
OUTPUT_DIR="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_11/toolsgenie_20260623"
MZML_PATH="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_11/toolsgenie_20260623/data/BSA2_F1.mzML"
FASTA_PATH="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_11/toolsgenie_20260623/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta"
COMET_BIN="${OUTPUT_DIR}/comet"
COMET_PARAMS="${OUTPUT_DIR}/comet.params"
RAW_COMET_OUTPUT="${OUTPUT_DIR}/BSA2_F1_raw"
FINAL_OUTPUT="${OUTPUT_DIR}/BSA2_F1_comet_psm.tsv"

# Download precompiled Comet Linux x86_64 binary from GitHub releases, add no-check-certificate to fix TLS issue
wget -q --no-check-certificate -O "${COMET_BIN}" https://github.com/UWPR/Comet/releases/download/v2024.01.0/comet.linux.exe
chmod +x "${COMET_BIN}"

# Generate and configure Comet parameter file
cd "${OUTPUT_DIR}"
"${COMET_BIN}" -p
mv comet.params.new "${COMET_PARAMS}"

sed -i "s#^database_name =.*#database_name = ${FASTA_PATH}#" "${COMET_PARAMS}"
sed -i 's/^enzyme = .*/enzyme = 1/' "${COMET_PARAMS}"
sed -i 's/^missed_cleavages = .*/missed_cleavages = 2/' "${COMET_PARAMS}"
sed -i 's/^precursor_tolerance = .*/precursor_tolerance = 10/' "${COMET_PARAMS}"
sed -i 's/^precursor_tolerance_units = .*/precursor_tolerance_units = 2/' "${COMET_PARAMS}"
sed -i 's/^fragment_tolerance = .*/fragment_tolerance = 0.02/' "${COMET_PARAMS}"
sed -i 's/^fragment_tolerance_units = .*/fragment_tolerance_units = 0/' "${COMET_PARAMS}"
sed -i 's/^num_fixed_mods = .*/num_fixed_mods = 1/' "${COMET_PARAMS}"
sed -i 's/^fixed_mod0 = .*/fixed_mod0 = 57.021464 C/' "${COMET_PARAMS}"
sed -i 's/^num_variable_mods = .*/num_variable_mods = 1/' "${COMET_PARAMS}"
sed -i 's/^variable_mod0 = .*/variable_mod0 = 15.994915 M/' "${COMET_PARAMS}"
sed -i 's/^output_format = .*/output_format = 1/' "${COMET_PARAMS}"

# Run Comet search, fixed flag syntax: add spaces between flags and arguments
"${COMET_BIN}" -P "${COMET_PARAMS}" -O "${RAW_COMET_OUTPUT}.txt" "${MZML_PATH}"

# Extract required columns to final TSV output
echo -e "spectrum_id\tpeptide_sequence\tcharge\tprotein_accession" > "${FINAL_OUTPUT}"
awk 'NR>1 {
    gsub(/\[[^]]+\]/, "", $2)
    print $19 "\t" $2 "\t" $7 "\t" $1
}' "${RAW_COMET_OUTPUT}.txt" >> "${FINAL_OUTPUT}"

# Clean up intermediate files
rm -f "${COMET_BIN}" "${COMET_PARAMS}" "${RAW_COMET_OUTPUT}.txt"
