import math

# Kyte-Doolittle hydropathy indices
kd = {
    'A': 1.8, 'R': -4.5, 'N': -3.5, 'D': -3.5, 'C': 2.5,
    'Q': -3.5, 'E': -3.5, 'G': -0.4, 'H': -3.2, 'I': 4.5,
    'L': 3.8, 'K': -3.9, 'M': 1.9, 'F': 2.8, 'P': -1.6,
    'S': -0.8, 'T': -0.7, 'W': -0.9, 'Y': -1.3, 'V': 4.2
}
hydrophobic = {'A', 'I', 'L', 'M', 'F', 'W', 'Y', 'V'}
hydrophilic = {'S', 'T', 'N', 'Q', 'E', 'D', 'H', 'R', 'K', 'P'}

seq = "MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG"

def calc_gravy(s):
    return sum(kd[c] for c in s) / len(s)

def calc_solubility(gravy):
    return 1 / (1 + math.exp(2 * gravy))

# Calculate original values
orig_gravy = calc_gravy(seq)
orig_sol = calc_solubility(orig_gravy)

# Generate all valid mutations
mutations = []
for idx in range(len(seq)):
    orig_res = seq[idx]
    if orig_res not in hydrophobic:
        continue
    for new_res in hydrophilic:
        new_seq = seq[:idx] + new_res + seq[idx+1:]
        new_gravy = calc_gravy(new_seq)
        new_sol = calc_solubility(new_gravy)
        delta = new_sol - orig_sol
        mutations.append((delta, idx+1, orig_res, new_res, new_seq, new_sol))

# Sort mutations by delta descending
mutations.sort(reverse=True, key=lambda x: x[0])
top3 = mutations[:3]
best = top3[0]

# Write results
out_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-13-5/result_11/toolsgenie_20260623/solubility_results.txt"
with open(out_path, 'w') as f:
    f.write(f"Original sequence: {seq}\n")
    f.write(f"Original solubility score: {orig_sol:.6f}\n")
    f.write("Top 3 mutations:\n")
    for i, mut in enumerate(top3, 1):
        delta, pos, orig, new, _, _ = mut
        f.write(f"Mutation {i}: Position {pos}, Original residue {orig}, Mutated residue {new}, Delta solubility {delta:.6f}\n")
    f.write(f"Best mutant sequence: {best[4]}\n")
    f.write(f"Best mutant solubility score: {best[5]:.6f}\n")
