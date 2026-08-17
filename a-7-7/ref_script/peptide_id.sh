TASK_DIR="$(dirname "$(dirname "$0")")"
mkdir -p "$TASK_DIR/ref_answer"

CometAdapter \
    -in "$TASK_DIR/data/BSA2_F1.mzML" \
    -out "$TASK_DIR/ref_answer/BSA2_F1_comet.idXML" \
    -threads 2 \
    -database "$TASK_DIR/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta" \
    -instrument high_res \
    -missed_cleavages 2 \
    -min_peptide_length 6 \
    -max_peptide_length 40 \
    -num_hits 1 \
    -num_enzyme_termini fully \
    -enzyme "Trypsin/P" \
    -isotope_error 0/1 \
    -precursor_charge 2:4 \
    -fixed_modifications 'Carbamidomethyl (C)' \
    -variable_modifications 'Oxidation (M)' \
    -max_variable_mods_in_peptide 3 \
    -precursor_mass_tolerance 5 \
    -precursor_error_units ppm \
    -fragment_mass_tolerance 0.03 \
    -fragment_bin_offset 0.0 \
    -PeptideIndexing:IL_equivalent \
    -PeptideIndexing:unmatched_action warn \
    -debug 0 \
    -force

python3 "$(dirname "$0")/idxml_to_tsv.py" \
    "$TASK_DIR/ref_answer/BSA2_F1_comet.idXML" \
    "$TASK_DIR/ref_answer/BSA2_F1_comet_psm.tsv"