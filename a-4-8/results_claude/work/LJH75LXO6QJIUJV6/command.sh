import pandas as pd
import numpy as np

# Load binned signal data
output_dir = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-8/result_2/toolsgenie_20260430"

h3k36me3_data = pd.read_csv(f"{output_dir}/H3K36me3_binned_signal.csv")
h3k4me3_data = pd.read_csv(f"{output_dir}/H3K4me3_binned_signal.csv")

# Dynamic programming segmentation for 2 peaks
def optimal_segmentation_2peaks(signal):
    n = len(signal)
    if n < 3:
        return [0, n//2, n-1]
    
    # Cost matrix for segments
    cost = np.zeros((n, n))
    for i in range(n):
        for j in range(i, n):
            segment_mean = np.mean(signal[i:j+1])
            cost[i, j] = np.sum((signal[i:j+1] - segment_mean) ** 2)
    
    # DP for optimal 3-segment partition (background-peak-background)
    best_cost = float('inf')
    best_breaks = [0, n//3, 2*n//3, n-1]
    
    for k1 in range(1, n-1):
        for k2 in range(k1+1, n):
            total_cost = cost[0, k1-1] + cost[k1, k2-1] + cost[k2, n-1]
            if total_cost < best_cost:
                best_cost = total_cost
                best_breaks = [0, k1, k2, n-1]
    
    return best_breaks

# Find 2 peaks using change point detection
def find_2_peaks(positions, signal):
    # First segmentation for peak 1
    breaks1 = optimal_segmentation_2peaks(signal)
    peak1_start, peak1_end = breaks1[1], breaks1[2]
    
    # Remove peak 1 region and find peak 2 in remaining signal
    remaining_signal = signal.copy()
    remaining_signal[peak1_start:peak1_end] = 0
    
    breaks2 = optimal_segmentation_2peaks(remaining_signal)
    peak2_start, peak2_end = breaks2[1], breaks2[2]
    
    # Ensure peaks don't overlap
    if peak2_start < peak1_end and peak2_end > peak1_start:
        if np.mean(signal[peak1_start:peak1_end]) > np.mean(signal[peak2_start:peak2_end]):
            peak2_start = peak1_end
            peak2_end = min(peak2_start + (peak1_end - peak1_start), len(signal)-1)
        else:
            peak1_start = peak2_end
            peak1_end = min(peak1_start + (peak2_end - peak2_start), len(signal)-1)
    
    return {
        'peak1': (positions[peak1_start], positions[peak1_end-1], peak1_start, peak1_end-1),
        'peak2': (positions[peak2_start], positions[peak2_end-1], peak2_start, peak2_end-1)
    }

# Apply segmentation to both datasets
segmentation_results = {}

# H3K36me3 segmentation
h3k36_peaks = find_2_peaks(h3k36me3_data['position'].values, h3k36me3_data['signal'].values)
segmentation_results['H3K36me3'] = h3k36_peaks

# H3K4me3 segmentation
h3k4_peaks = find_2_peaks(h3k4me3_data['position'].values, h3k4me3_data['signal'].values)
segmentation_results['H3K4me3'] = h3k4_peaks

# Print segmentation results
for experiment, peaks in segmentation_results.items():
    print(f"\n{experiment} Optimal Segmentation (2 peaks):")
    print(f"  Peak 1: position {peaks['peak1'][0]:.0f}-{peaks['peak1'][1]:.0f} (indices {peaks['peak1'][2]}-{peaks['peak1'][3]})")
    print(f"  Peak 2: position {peaks['peak2'][0]:.0f}-{peaks['peak2'][1]:.0f} (indices {peaks['peak2'][2]}-{peaks['peak2'][3]})")

# Save segmentation results
segmentation_output = []
for experiment, peaks in segmentation_results.items():
    segmentation_output.append({
        'experiment': experiment,
        'peak1_start': peaks['peak1'][0],
        'peak1_end': peaks['peak1'][1],
        'peak1_start_idx': peaks['peak1'][2],
        'peak1_end_idx': peaks['peak1'][3],
        'peak2_start': peaks['peak2'][0],
        'peak2_end': peaks['peak2'][1],
        'peak2_start_idx': peaks['peak2'][2],
        'peak2_end_idx': peaks['peak2'][3]
    })

segmentation_df = pd.DataFrame(segmentation_output)
segmentation_df.to_csv(f"{output_dir}/segmentation_results_2peaks.csv", index=False)

print(f"\nSegmentation results saved to {output_dir}/segmentation_results_2peaks.csv")
print("Optimal segmentation with 2 peaks completed for both datasets")
