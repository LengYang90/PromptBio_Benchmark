# Install required package first
import subprocess
import sys
subprocess.check_call([sys.executable, "-m", "pip", "install", "pyteomics"])

from pyteomics import mzml

# Input file paths
FASTA_PATH = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_11/toolsgenie_20260623/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta"
MZML_PATH = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_11/toolsgenie_20260623/data/BSA2_F1.mzML"

# Count FASTA entries
total_fasta_entries = 0
decoy_entries = 0
with open(FASTA_PATH, 'r') as f:
    for line in f:
        if line.startswith('>'):
            total_fasta_entries += 1
            if 'DECOY' in line.strip():
                decoy_entries += 1
target_entries = total_fasta_entries - decoy_entries
print(f"FASTA Integrity Check:\nTotal entries: {total_fasta_entries}\nTarget entries: {target_entries}\nDecoy entries: {decoy_entries}\n")

# Validate mzML and count MS2 spectra
ms2_count = 0
valid_dda = True
with mzml.MzML(MZML_PATH) as mzml_reader:
    for spectrum in mzml_reader:
        ms_level = spectrum.get('ms level', 0)
        if ms_level == 2:
            ms2_count += 1
            if 'precursorList' not in spectrum or len(spectrum['precursorList']['precursor']) < 1:
                valid_dda = False

print(f"mzML Validation Check:\nValid DDA file: {valid_dda}\nTotal MS2 spectra: {ms2_count}")
