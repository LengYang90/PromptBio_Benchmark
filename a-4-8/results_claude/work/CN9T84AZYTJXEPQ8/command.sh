import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load data
output_dir = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-8/result_2/toolsgenie_20260430"

h3k36me3_data = pd.read_csv(f"{output_dir}/H3K36me3_binned_signal.csv")
h3k4me3_data = pd.read_csv(f"{output_dir}/H3K4me3_binned_signal.csv")
segmentation_results = pd.read_csv(f"{output_dir}/segmentation_results_2peaks.csv")

# Create figure with 2 panels
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10))

# Panel 1: H3K36me3
h3k36_seg = segmentation_results[segmentation_results['experiment'] == 'H3K36me3'].iloc[0]

# Plot background signal
ax1.plot(h3k36me3_data['position'], h3k36me3_data['signal'], color='lightgray', linewidth=0.8, alpha=0.7, label='Background')

# Create safe boolean masks with bounds checking for H3K36me3
peak1_start_idx = max(0, min(int(h3k36_seg['peak1_start_idx']), len(h3k36me3_data)-1))
peak1_end_idx = max(0, min(int(h3k36_seg['peak1_end_idx']), len(h3k36me3_data)-1))
peak2_start_idx = max(0, min(int(h3k36_seg['peak2_start_idx']), len(h3k36me3_data)-1))
peak2_end_idx = max(0, min(int(h3k36_seg['peak2_end_idx']), len(h3k36me3_data)-1))

# Highlight Peak 1
peak1_indices = range(peak1_start_idx, peak1_end_idx + 1)
if peak1_indices:
    peak1_data = h3k36me3_data.iloc[peak1_indices]
    ax1.plot(peak1_data['position'], peak1_data['signal'], 
             color='red', linewidth=2, label='Peak 1')

# Highlight Peak 2  
peak2_indices = range(peak2_start_idx, peak2_end_idx + 1)
if peak2_indices:
    peak2_data = h3k36me3_data.iloc[peak2_indices]
    ax1.plot(peak2_data['position'], peak2_data['signal'], 
             color='blue', linewidth=2, label='Peak 2')

ax1.set_title('H3K36me3 ChIP-seq Segmentation (2 Peaks)', fontsize=14, fontweight='bold')
ax1.set_xlabel('Genomic Position (bp)', fontsize=12)
ax1.set_ylabel('Signal Intensity', fontsize=12)
ax1.legend(loc='upper right')
ax1.grid(True, alpha=0.3)

# Panel 2: H3K4me3
h3k4_seg = segmentation_results[segmentation_results['experiment'] == 'H3K4me3'].iloc[0]

# Plot background signal
ax2.plot(h3k4me3_data['position'], h3k4me3_data['signal'], color='lightgray', linewidth=0.8, alpha=0.7, label='Background')

# Create safe boolean masks with bounds checking for H3K4me3
peak1_start_idx = max(0, min(int(h3k4_seg['peak1_start_idx']), len(h3k4me3_data)-1))
peak1_end_idx = max(0, min(int(h3k4_seg['peak1_end_idx']), len(h3k4me3_data)-1))
peak2_start_idx = max(0, min(int(h3k4_seg['peak2_start_idx']), len(h3k4me3_data)-1))
peak2_end_idx = max(0, min(int(h3k4_seg['peak2_end_idx']), len(h3k4me3_data)-1))

# Highlight Peak 1
peak1_indices = range(peak1_start_idx, peak1_end_idx + 1)
if peak1_indices:
    peak1_data = h3k4me3_data.iloc[peak1_indices]
    ax2.plot(peak1_data['position'], peak1_data['signal'], 
             color='red', linewidth=2, label='Peak 1')

# Highlight Peak 2
peak2_indices = range(peak2_start_idx, peak2_end_idx + 1)
if peak2_indices:
    peak2_data = h3k4me3_data.iloc[peak2_indices]
    ax2.plot(peak2_data['position'], peak2_data['signal'], 
             color='blue', linewidth=2, label='Peak 2')

ax2.set_title('H3K4me3 ChIP-seq Segmentation (2 Peaks)', fontsize=14, fontweight='bold')
ax2.set_xlabel('Genomic Position (bp)', fontsize=12)
ax2.set_ylabel('Signal Intensity', fontsize=12)
ax2.legend(loc='upper right')
ax2.grid(True, alpha=0.3)

# Add annotations for peak regions with safe data access
try:
    # H3K36me3 annotations
    if peak1_indices:
        peak1_signal_max = h3k36me3_data.iloc[peak1_indices]['signal'].max()
        ax1.annotate(f'Peak 1\n{h3k36_seg["peak1_start"]:.0f}-{h3k36_seg["peak1_end"]:.0f}', 
                     xy=(h3k36_seg['peak1_start'], peak1_signal_max), 
                     xytext=(10, 10), textcoords='offset points', fontsize=9, 
                     bbox=dict(boxstyle='round,pad=0.3', facecolor='red', alpha=0.3))
    
    if peak2_indices:
        peak2_signal_max = h3k36me3_data.iloc[peak2_indices]['signal'].max()
        ax1.annotate(f'Peak 2\n{h3k36_seg["peak2_start"]:.0f}-{h3k36_seg["peak2_end"]:.0f}', 
                     xy=(h3k36_seg['peak2_start'], peak2_signal_max), 
                     xytext=(10, -20), textcoords='offset points', fontsize=9,
                     bbox=dict(boxstyle='round,pad=0.3', facecolor='blue', alpha=0.3))

    # H3K4me3 annotations
    peak1_indices_h3k4 = range(max(0, min(int(h3k4_seg['peak1_start_idx']), len(h3k4me3_data)-1)),
                               max(0, min(int(h3k4_seg['peak1_end_idx']), len(h3k4me3_data)-1)) + 1)
    peak2_indices_h3k4 = range(max(0, min(int(h3k4_seg['peak2_start_idx']), len(h3k4me3_data)-1)),
                               max(0, min(int(h3k4_seg['peak2_end_idx']), len(h3k4me3_data)-1)) + 1)
    
    if peak1_indices_h3k4:
        peak1_signal_max = h3k4me3_data.iloc[peak1_indices_h3k4]['signal'].max()
        ax2.annotate(f'Peak 1\n{h3k4_seg["peak1_start"]:.0f}-{h3k4_seg["peak1_end"]:.0f}', 
                     xy=(h3k4_seg['peak1_start'], peak1_signal_max), 
                     xytext=(10, 10), textcoords='offset points', fontsize=9,
                     bbox=dict(boxstyle='round,pad=0.3', facecolor='red', alpha=0.3))
    
    if peak2_indices_h3k4:
        peak2_signal_max = h3k4me3_data.iloc[peak2_indices_h3k4]['signal'].max()
        ax2.annotate(f'Peak 2\n{h3k4_seg["peak2_start"]:.0f}-{h3k4_seg["peak2_end"]:.0f}', 
                     xy=(h3k4_seg['peak2_start'], peak2_signal_max), 
                     xytext=(10, -20), textcoords='offset points', fontsize=9,
                     bbox=dict(boxstyle='round,pad=0.3', facecolor='blue', alpha=0.3))

except Exception as e:
    print(f"Warning: Could not add some annotations due to: {e}")

plt.tight_layout()
plt.savefig(f"{output_dir}/segmentation_model_plot.png", dpi=300, bbox_inches='tight')
plt.close()

print(f"Publication-quality segmentation plot saved to {output_dir}/segmentation_model_plot.png")
