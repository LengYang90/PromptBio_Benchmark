TASK_DIR="$(dirname "$(dirname "$0")")"
mkdir -p "$TASK_DIR/tmp"
mkdir -p "$TASK_DIR/ref_answer"

diann   --cut K*,R*,!*P --fixed-mod Carbamidomethyl,57.021464,C --var-mod Oxidation,15.994915,M \
        --fasta "$TASK_DIR/data/REF_EColi_K12_UPS1_combined.fasta" \
        --fasta-search \
        --min-pr-mz 350 \
        --max-pr-mz 950 \
        --min-fr-mz 500 \
        --max-fr-mz 1500 \
        --missed-cleavages 1 \
        --min-pep-len 15 \
        --max-pep-len 30 \
        --min-pr-charge 2 \
        --max-pr-charge 3 \
        --var-mods 2 \
        --threads 2 \
        --predictor \
        --verbose 3 \
        --out-lib "$TASK_DIR/tmp/lib.predicted.speclib" \
        --gen-spec-lib


# DIA-NN auto-generates the output filename from the mzML input:
# RD139_Narrow_UPS1_0_1fmol_inj1.mzML -> RD139_Narrow_UPS1_0_1fmol_inj1_mzML.quant
diann   --lib "$TASK_DIR/tmp/lib.predicted.speclib" \
        --f "$TASK_DIR/data/RD139_Narrow_UPS1_0_1fmol_inj1.mzML" \
        --threads 2 \
        --verbose 3 \
        --individual-windows \
        --temp "$TASK_DIR/tmp" \
        --min-corr 2.0 \
        --corr-diff 1.0 \
        --quick-mass-acc --individual-mass-acc \
        --time-corr-only \
        --out "$TASK_DIR/ref_answer/report.tsv"