import os
import math
from Bio.SeqUtils.ProtParam import ProteinAnalysis

task_dir = os.path.dirname(os.path.dirname(__file__))


def predict_solubility(sequence):
    analysis = ProteinAnalysis(sequence)
    gravy = analysis.gravy()
    return 1 / (1 + math.exp(2 * gravy))


def suggest_improving_mutations(sequence, num_suggestions=3):
    original_sol = predict_solubility(sequence)
    hydrophobic = set("AILMFWYV")
    hydrophilic = list("STNQEDHRKP")

    suggestions = []
    for i, aa in enumerate(sequence):
        if aa not in hydrophobic:
            continue
        for new_aa in hydrophilic:
            new_seq = sequence[:i] + new_aa + sequence[i + 1:]
            delta = predict_solubility(new_seq) - original_sol
            if delta > 0:
                suggestions.append((i + 1, aa, new_aa, delta))

    suggestions.sort(key=lambda x: x[3], reverse=True)
    return suggestions[:num_suggestions]


if __name__ == "__main__":
    sequence = "MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG"

    original_solubility = predict_solubility(sequence)
    mutations = suggest_improving_mutations(sequence)

    ref_dir = os.path.join(task_dir, "ref_answer")

    with open(os.path.join(ref_dir, "summary.txt"), "w") as f:
        f.write(f"original_sequence: {sequence}\n")
        f.write(f"original_solubility: {original_solubility:.4f}\n")
        if mutations:
            best_pos, best_orig, best_sugg, _ = mutations[0]
            best_seq = sequence[:best_pos - 1] + best_sugg + sequence[best_pos:]
            best_sol = predict_solubility(best_seq)
            f.write(f"best_mutant_sequence: {best_seq}\n")
            f.write(f"best_mutant_solubility: {best_sol:.4f}\n")

    with open(os.path.join(ref_dir, "mutations.tsv"), "w") as f:
        f.write("position\toriginal\tmutant\tsolubility_gain\n")
        for pos, orig, sugg, gain in mutations:
            f.write(f"{pos}\t{orig}\t{sugg}\t{gain:.4f}\n")
