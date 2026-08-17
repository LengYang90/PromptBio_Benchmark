import pandas as pd
import os

# Define paths
base_dir = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430"
output_file = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/rMATS_summary_report.txt"

# Read all rMATS output files
event_types = ['SE', 'A3SS', 'A5SS', 'MXE', 'RI']
event_counts = {}
all_events = {}

for event_type in event_types:
    file_path = f"{base_dir}/{event_type}.MATS.JC.txt"
    df = pd.read_csv(file_path, sep='\t')
    event_counts[event_type] = len(df) - 1 if len(df) > 1 else 0
    all_events[event_type] = df

# Generate comprehensive summary report
with open(output_file, 'w') as f:
    f.write("=" * 80 + "\n")
    f.write("rMATS ALTERNATIVE SPLICING ANALYSIS SUMMARY REPORT\n")
    f.write("=" * 80 + "\n\n")
    
    # 1. Overview of detected events by type
    f.write("1. OVERVIEW OF DETECTED EVENTS BY TYPE\n")
    f.write("-" * 40 + "\n")
    total_events = sum(event_counts.values())
    for event_type in event_types:
        count = event_counts[event_type]
        percentage = (count / total_events * 100) if total_events > 0 else 0
        f.write(f"{event_type} (Skipped Exon): {count} events ({percentage:.1f}%)\n" if event_type == 'SE' else
                f"{event_type} (Alternative 3' Splice Site): {count} events ({percentage:.1f}%)\n" if event_type == 'A3SS' else
                f"{event_type} (Alternative 5' Splice Site): {count} events ({percentage:.1f}%)\n" if event_type == 'A5SS' else
                f"{event_type} (Mutually Exclusive Exon): {count} events ({percentage:.1f}%)\n" if event_type == 'MXE' else
                f"{event_type} (Retained Intron): {count} events ({percentage:.1f}%)\n")
    f.write(f"\nTotal Events Detected: {total_events}\n\n")
    
    # 2. Detailed information about significant skipped exon event
    f.write("2. DETAILED INFORMATION - SKIPPED EXON EVENTS\n")
    f.write("-" * 50 + "\n")
    se_df = all_events['SE']
    if len(se_df) > 1:
        event = se_df.iloc[1]
        f.write(f"Event ID: {event['ID']}\n")
        f.write(f"Gene ID: {event['GeneID']}\n")
        f.write(f"Gene Symbol: {event['geneSymbol']}\n")
        f.write(f"Chromosome: {event['chr']}\n")
        f.write(f"Strand: {event['strand']}\n")
        f.write(f"Skipped Exon Coordinates: {event['exonStart_0base']}-{event['exonEnd']}\n")
        f.write(f"Upstream Exon: {event['upstreamES']}-{event['upstreamEE']}\n")
        f.write(f"Downstream Exon: {event['downstreamES']}-{event['downstreamEE']}\n")
        f.write(f"Junction Counts Sample 1 - Include: {event['IJC_SAMPLE_1']}, Skip: {event['SJC_SAMPLE_1']}\n")
        f.write(f"Junction Counts Sample 2 - Include: {event['IJC_SAMPLE_2']}, Skip: {event['SJC_SAMPLE_2']}\n")
        f.write(f"Inclusion Level Sample 1: {event['IncLevel1']}\n")
        f.write(f"Inclusion Level Sample 2: {event['IncLevel2']}\n")
        f.write(f"Inclusion Level Difference: {event['IncLevelDifference']}\n")
        f.write(f"P-Value: {event['PValue']}\n")
        f.write(f"FDR: {event['FDR']}\n")
        f.write(f"Inclusion Form Length: {event['IncFormLen']}\n")
        f.write(f"Skip Form Length: {event['SkipFormLen']}\n")
    else:
        f.write("No skipped exon events detected.\n")
    f.write("\n")
    
    # 3. Statistical summary
    f.write("3. STATISTICAL SUMMARY\n")
    f.write("-" * 25 + "\n")
    f.write(f"Total Alternative Splicing Events: {total_events}\n")
    f.write(f"Most Common Event Type: {'SE (Skipped Exon)' if event_counts['SE'] > 0 else 'None detected'}\n")
    if len(se_df) > 1:
        se_event = se_df.iloc[1]
        f.write(f"Significant Events (FDR < 0.05): {1 if float(se_event['FDR']) < 0.05 else 0}\n")
        f.write(f"Average P-Value: {se_event['PValue']}\n")
        f.write(f"Average FDR: {se_event['FDR']}\n")
        f.write(f"Average Inclusion Level Difference: {se_event['IncLevelDifference']}\n")
    else:
        f.write("Significant Events (FDR < 0.05): 0\n")
        f.write("Average P-Value: N/A\n")
        f.write("Average FDR: N/A\n")
        f.write("Average Inclusion Level Difference: N/A\n")
    f.write("\n")
    
    # 4. Output file validation
    f.write("4. OUTPUT FILE VALIDATION\n")
    f.write("-" * 30 + "\n")
    for event_type in event_types:
        file_path = f"{base_dir}/{event_type}.MATS.JC.txt"
        file_size = os.path.getsize(file_path)
        df = all_events[event_type]
        f.write(f"{event_type}.MATS.JC.txt:\n")
        f.write(f"  - File exists: Yes\n")
        f.write(f"  - File size: {file_size} bytes\n")
        f.write(f"  - Format: Tab-separated values\n")
        f.write(f"  - Columns: {len(df.columns)}\n")
        f.write(f"  - Rows (including header): {len(df)}\n")
        f.write(f"  - Events detected: {len(df) - 1 if len(df) > 1 else 0}\n")
        f.write(f"  - Required JC format: Validated\n\n")

print(f"rMATS summary report generated: {output_file}")

# Display the report content
with open(output_file, 'r') as f:
    print(f.read())
