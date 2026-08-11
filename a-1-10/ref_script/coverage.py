#!/usr/bin/env python3
import subprocess
import pandas as pd
import os

task_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

bam_file = os.path.join(task_dir, "data", "example_tumor.bam")
tmp_tsv = os.path.join(task_dir, "tmp", "tmp_per_base_coverage.tsv")
output_file = os.path.join(task_dir, "ref_answer", "average_coverage.txt")

os.makedirs(os.path.join(task_dir, "tmp"), exist_ok=True)
os.makedirs(os.path.join(task_dir, "ref_answer"), exist_ok=True)

# 运行 bedtools genomecov，并保存非零覆盖位点
cmd_bedtools = f"bedtools genomecov -d -ibam {bam_file}"
with open(tmp_tsv, "w") as out:
    subprocess.run(cmd_bedtools, shell=True, stdout=subprocess.PIPE, text=True)
    # 直接写入过滤后的结果
    process = subprocess.Popen(cmd_bedtools, shell=True, stdout=subprocess.PIPE, text=True)
    with open(tmp_tsv, "w") as f:
        for line in process.stdout:
            cols = line.strip().split()
            if int(cols[2]) > 0:  # 过滤 coverage>0
                f.write(line)

# 计算平均覆盖度
df = pd.read_table(tmp_tsv, header=None)
df.columns = ["chr", "pos", "coverage"]
df_nonzero = df[df['coverage'] > 0]
average_coverage = df_nonzero['coverage'].mean()

with open(output_file, "w") as f:
    f.write(f"{average_coverage}\n")
