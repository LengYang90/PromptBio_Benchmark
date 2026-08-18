import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import chi2_contingency

task_dir = os.path.dirname(os.path.dirname(__file__))
ref_answer_dir = os.path.join(task_dir, "ref_answer")

proteomic_data = pd.read_excel(os.path.join(task_dir, "data", "Proteomic_data.xlsx"))
merip_data = pd.read_excel(os.path.join(task_dir, "data", "MeRIP_RNA_result.xlsx"))

fig, axes = plt.subplots(2, 2, figsize=(15, 12))
fig.suptitle("P-value Distributions", fontsize=16, fontweight="bold")

axes[0, 0].hist(proteomic_data["p.value"].dropna(), bins=50, alpha=0.7, color="skyblue", edgecolor="black")
axes[0, 0].set_title("Proteomic Data P-values")

axes[0, 1].hist(merip_data["m_pvalue"].dropna(), bins=50, alpha=0.7, color="lightcoral", edgecolor="black")
axes[0, 1].set_title("m6A Methylation P-values")

axes[1, 0].hist(merip_data["g_pvalue"].dropna(), bins=50, alpha=0.7, color="lightgreen", edgecolor="black")
axes[1, 0].set_title("Gene Expression P-values")

axes[1, 1].hist(proteomic_data["p.value"].dropna(), bins=30, alpha=0.5, color="skyblue", label="Proteomic", density=True)
axes[1, 1].hist(merip_data["m_pvalue"].dropna(), bins=30, alpha=0.5, color="lightcoral", label="m6A", density=True)
axes[1, 1].hist(merip_data["g_pvalue"].dropna(), bins=30, alpha=0.5, color="lightgreen", label="Gene Expression", density=True)
axes[1, 1].set_title("P-value Distribution Comparison")
axes[1, 1].legend()

plt.tight_layout()
plt.savefig(os.path.join(ref_answer_dir, "p_value_distribution.png"), dpi=300)
plt.close()

fig, axes = plt.subplots(2, 2, figsize=(15, 12))
fig.suptitle("Effect Size (Log2 Fold Change) Distributions", fontsize=16, fontweight="bold")

axes[0, 0].hist(proteomic_data["log2FC"].dropna(), bins=50, alpha=0.7, color="skyblue", edgecolor="black")
axes[0, 0].axvline(x=0, color="red", linestyle="--", alpha=0.7, label="No change")
axes[0, 0].set_title("Proteomic Data Log2FC")

axes[0, 1].hist(merip_data["m_log2FC"].dropna(), bins=50, alpha=0.7, color="lightcoral", edgecolor="black")
axes[0, 1].axvline(x=0, color="red", linestyle="--", alpha=0.7, label="No change")
axes[0, 1].set_title("m6A Methylation Log2FC")

axes[1, 0].hist(merip_data["g_log2FC"].dropna(), bins=50, alpha=0.7, color="lightgreen", edgecolor="black")
axes[1, 0].axvline(x=0, color="red", linestyle="--", alpha=0.7, label="No change")
axes[1, 0].set_title("Gene Expression Log2FC")

axes[1, 1].hist(proteomic_data["log2FC"].dropna(), bins=30, alpha=0.5, color="skyblue", label="Proteomic", density=True)
axes[1, 1].hist(merip_data["m_log2FC"].dropna(), bins=30, alpha=0.5, color="lightcoral", label="m6A", density=True)
axes[1, 1].hist(merip_data["g_log2FC"].dropna(), bins=30, alpha=0.5, color="lightgreen", label="Gene Expression", density=True)
axes[1, 1].axvline(x=0, color="red", linestyle="--", alpha=0.7, label="No change")
axes[1, 1].set_title("Effect Size Distribution Comparison")
axes[1, 1].legend()

plt.tight_layout()
plt.savefig(os.path.join(ref_answer_dir, "effect_size_distribution.png"), dpi=300)
plt.close()

merip_data["m6A_binary"] = merip_data["m6A"].apply(
    lambda x: "Modified" if x in ["m6A Hyper", "m6A Hypo"] else "Not Modified"
)
merip_data["DEG_binary"] = merip_data["DEG"].apply(
    lambda x: "Differentially Expressed" if x in ["Up", "Down"] else "Not Differentially Expressed"
)

contingency_table = pd.crosstab(merip_data["m6A_binary"], merip_data["DEG_binary"])
chi2_stat, p_value, dof, expected_freq = chi2_contingency(contingency_table)

with open(os.path.join(ref_answer_dir, "chisq_test_p_value.txt"), "w") as f:
    f.write(f"{p_value:.10e}")
