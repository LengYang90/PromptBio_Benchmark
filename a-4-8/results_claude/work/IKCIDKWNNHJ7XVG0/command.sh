import pandas as pd
import numpy as np

# Load ChIP-seq data
data_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-8/result_2/toolsgenie_20260430/data/ChIP_data.csv"
df = pd.read_csv(data_path, index_col=0)

# Define bin size (1kb)
bin_size = 1000

# Function to create binned signal tracks
def create_binned_signal(data, bin_size):
    # Get genomic range
    start = data['chromStart'].min()
    end = data['chromEnd'].max()
    
    # Create bins
    bins = np.arange(start, end + bin_size, bin_size)
    bin_centers = bins[:-1] + bin_size // 2
    
    # Initialize signal array
    signal = np.zeros(len(bin_centers))
    
    # Aggregate signal counts into bins
    for _, row in data.iterrows():
        region_start = row['chromStart']
        region_end = row['chromEnd']
        count = row['count']
        
        # Find overlapping bins
        start_bin = max(0, (region_start - start) // bin_size)
        end_bin = min(len(signal) - 1, (region_end - start) // bin_size)
        
        # Add signal to bins
        for bin_idx in range(int(start_bin), int(end_bin) + 1):
            signal[bin_idx] += count
    
    return bin_centers, signal

# Process each experiment
binned_data = {}
for experiment in ['H3K36me3', 'H3K4me3']:
    exp_data = df[df.index == experiment]
    bin_centers, signal = create_binned_signal(exp_data, bin_size)
    binned_data[experiment] = pd.DataFrame({
        'position': bin_centers,
        'signal': signal
    })

# Save binned signal tracks
output_dir = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-8/result_2/toolsgenie_20260430"

for experiment, data in binned_data.items():
    output_path = f"{output_dir}/{experiment}_binned_signal.csv"
    data.to_csv(output_path, index=False)
    print(f"Saved {experiment} binned signal to {output_path}")
    print(f"  - {len(data)} bins, signal range: {data['signal'].min():.1f} - {data['signal'].max():.1f}")

print(f"\nBinned genomic signal tracks created with {bin_size}bp bins")
print("Ready for segmentation analysis")
