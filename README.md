# PromptBio Benchmark 评测

本项目评测一个生物信息学 Agent 是否完成了**单个** PromptBio Benchmark
任务，例如 `a-1-10`。推荐入口是
[`evaluate_task_with_deep_agent.py`](./evaluate_task_with_deep_agent.py)。

评测的最终结论

- `score: 1`：现有结果与证据支持 Agent 已正确回答题目；即使最终文件与参考答案
  不完全相同，也可以得分为 1。
- `score: 0`：现有证据支持结果错误、方法不回答题目、执行记录不足以证明结果，或
  无法支持其正确性。

无论分数是 0 还是 1，`evaluation.json` 都包含判断依据、逐文件观察和可追溯的内容证据。

## 为什么不直接比较参考答案

生物信息学问题常有多种可行的计算实现。不同实现可能产生不完全一致的数值或
表格，却同样正确地回答题目。因此，本项目不使用 `eval.json` 中的固定阈值，也
不会把“结果不同”自动判为失败。

例如，参考实现和 Agent 分别采用两种符合题意的覆盖度计算实现，得到略有不同的
小数。初评会先把此情况标记为需要复核；复核阶段再查看已有代码和日志，判断差异
是否确实来自两种计算实现，而不是计算错误。

## 评测流程

```text
task.json + 所有“参考答案—Agent 结果”配对
                    │
                    ▼
       初评 Deep Agent（只能读配对结果）
             │ pass              │ fail / uncertain
             ▼                   ▼
          score 1       复核 Deep Agent（再读脚本、work、log）
                                      │
                                      ▼
                                 final score 0/1
                                      │
                                      ▼
                    results_*/evaluation.json
```

### 阶段一：仅比较最终结果

初评只能读取：

- `task.json`；
- `ref_answer/<expected_output.file>`；
- `<results_dir>/<expected_output.file>`。

`task.json` 的 `expected_output` 中声明了一个或多个输出文件。所有声明输出的
“参考答案—Agent 结果”配对会一次性提供给**同一个** LLM/Deep Agent，由它进行
任务整体判断，而不是每个文件独立调用模型、也不是“有一个文件不同就自动 0 分”。

初评必须实际检查每一对文件。它可返回 `pass`、`fail` 或 `uncertain`。只有
`pass` 才会直接给出 `score: 1`；`fail` 和 `uncertain` 都进入复核。

### 阶段二：方法与执行复核

仅当阶段一不是 `pass` 时，复核 Agent 额外可读：

- `ref_script/**`；
- `<results_dir>/work/**`；
- `<results_dir>/log.out`。

它判断参考实现做了什么、Agent 实际采用什么方法、日志是否证明该方法产生了结果，
以及结果差异是否能由两种计算实现的差异合理解释。代码或计划只表示意图；日志和
命令记录才可作为实际执行的证据。

复核仍然对所有声明输出的文件作整体判断。文件级观察只是证据，最终 `score` 由任务整体
结论决定。

## 严格只读范围

评测器不会访问原始输入数据，也不会重新运行参考脚本、Agent 代码、命令或验证
脚本。它只能基于目录中已有的文件判断。

Deep Agent 只获得项目自定义的只读工具，并有模型请求过滤和执行时工具白名单两层
限制。工具只支持读取或生成内存中的预览：

- 文本、JSON、CSV/TSV、代码和日志的分页读取、搜索与结构化检查；
- Excel 表格的只读采样；
- 图片和 PDF 的元数据、文本提取及内存预览；
- FASTA/FASTQ、VCF/BCF、BAM/CRAM 的 header 与记录采样。

文件列表与文件元数据工具仅用于导航；只有实际读取正文、表格、图片、PDF 或生物信息常用
文件内容的工具才产生可引用的证据 ID。解析器不修改源文件。不会向 Agent 暴露 Shell、Python 执行、网络、写入、删除、
编辑、默认文件系统工具或子 Agent 工具。结果目录根目录下未在 `expected_output`
声明的其他文件也不会成为证据；例如不会把未声明的附加文本当成 Agent 答案。

评测器唯一会写入的文件是 `<results_dir>/evaluation.json`。

## 目录约定

以 `a-1-10` 为例：

```text
a-1-10/
├── task.json
├── eval.json                     # 不参与正确性判断
├── ref_answer/
│   ├── required_result_1.txt     # 与 expected_output 同名
│   └── required_result_2.csv
├── ref_script/
│   └── coverage.py               # 仅在复核阶段可读
└── results_glm/
    ├── required_result_1.txt     # 与 ref_answer 中声明文件同名
    ├── required_result_2.csv
    ├── log.out                   # 仅在复核阶段可读
    └── work/                     # 仅在复核阶段可读
        ├── command.sh
        ├── command_log.txt
        └── ...
```

`ref_answer/` 和结果目录根目录都可以有多个文件，但只能使用 `task.json` 的
`expected_output[].file` 所声明的同名配对。声明的文件名必须是相对于其输出目录的
非越界路径。

## 安装

要求 Python 3.10 或更高版本。安装依赖：

```bash
python -m pip install -r requirements.txt
```

其中 `deepagents`、`langgraph` 和 `langchain-openai` 用于受限 Agent 编排；其余
依赖用于**只读**解析图片、PDF、表格和生物信息学文件。若不需要某类文件，相关库
不会被导入。

## 使用 OpenAI `gpt-5.6-terra`

在仓库根目录设置环境变量后运行。评测器默认通过 **Responses API** 调用模型；这是
`gpt-5.6-terra` 在使用函数工具和多轮工作流时所需的接口。不会显式传递
`temperature`，从而避免该模型对非默认 temperature 的限制。

```bash
export OPENAI_API_KEY='你的 OpenAI API Key'
export MODEL='gpt-5.6-terra'
export BASE_URL='https://api.openai.com/v1'   # 可省略，这是默认值

python evaluate_task_with_deep_agent.py a-1-10 --result-dir results_glm
```

也兼容 `API_KEY`（优先于 `OPENAI_API_KEY`）和 `LLM_MODEL`（在 `MODEL` 未设置时
使用）。如果使用其他 OpenAI 兼容服务且它实现了 Responses API：

```bash
API_KEY='your-key' MODEL='your-model' \
python evaluate_task_with_deep_agent.py a-1-10 --result-dir results_glm
```

成功时会输出类似：

```text
score=1 report=/absolute/path/a-1-10/results_glm/evaluation.json
```

模型接口、工具调用或结构化结果失败时，程序以非零状态结束，且**不把评测器故障
写成 Agent 的 `score: 0`**。

### 先检查权限范围

不需要 API Key 即可检查阶段一实际能看到的文件：

```bash
python evaluate_task_with_deep_agent.py a-1-10 --result-dir results_glm --dry-run
```

输出会列出所有输出配对以及初评的允许文件；其中不应出现 `ref_script/`、`work/`
或 `log.out`。

### 读取与预览的单次上限

Deep Agent 可以多次分页读取或按需搜索，所以不存在旧版“把全部证据一次性拼进
prompt”的全局审计字符上限。以下参数只限制**单个工具调用**返回给模型的内容，
防止一页异常大而无法处理；被截断的证据会在报告中明确标记，Agent 仍可请求下一页
或更具体的范围。

```bash
python evaluate_task_with_deep_agent.py a-1-10 --result-dir results_glm \
  --max-text-characters 1000000 \
  --max-table-rows 200 \
  --max-records 100 \
  --max-image-bytes 8000000 \
  --timeout 600
```

默认值已经偏向充分保留证据。若单条记录或单个 PDF 页特别大，可增大
`--max-text-characters`；没有总量上限，复核 Agent 可继续调用只读工具。

## `evaluation.json` 关键字段

```json
{
  "score": 1,
  "rationale": "任务级最终判断依据",
  "final_stage": "method_and_execution_audit",
  "initial_assessment": {
    "verdict": "fail",
    "reason": "答案文件存在需解释的差异"
  },
  "audit_assessment": {
    "score": 1,
    "reference_method": "从参考脚本读出的计算实现",
    "agent_method": "从 Agent 代码和日志读出的计算实现",
    "reason": "差异仍符合题意的原因"
  },
  "file_manifest": [
    {
      "path": "a-1-10/results_glm/average_coverage.txt",
      "roles": ["agent_output"],
      "available_in_stages": ["initial_assessment", "method_and_execution_audit"],
      "sha256": "..."
    }
  ],
  "evidence_inventory": [
    {
      "evidence_id": "A-0003",
      "path": ".../work/command_log.txt",
      "locator": "lines 1-120",
      "status": "complete"
    }
  ],
  "coverage": {
    "partial_evidence_paths": []
  },
  "token_usage": {
    "total_input_tokens": 0,
    "total_output_tokens": 0,
    "total_cached_input_tokens": 0,
    "total_tokens": 0,
    "calls": []
  }
}
```

`file_manifest` 是文件级元数据：每个物理文件在整份报告中只出现一次，记录角色、
可用阶段、大小、类型和 SHA-256。`evidence_inventory` 只记录实际内容检查，不再记录
文件列表或元数据查询；同一文件若读取了不同正文范围，才会有多个证据 ID。初评证据
ID 以 `I-` 开头，复核证据 ID 以 `A-` 开头。`coverage` 会列出未检查和只检查部分内容
的文件，因此截断不会被静默隐藏。

`token_usage.calls` 记录每次实际模型响应的输入、输出、缓存输入和总 token；汇总
字段是全任务两阶段调用的合计。若接口未返回某一项 token 数，报告保留 0，而不会
虚构用量。

## 测试

以下测试不调用模型 API，也不会修改任何任务文件：

```bash
python -m unittest discover -s tests -v
```

它验证两阶段目录隔离、未声明结果文件排除、路径越界拒绝、一次性文件清单、
并发读取下唯一的证据编号、初评到复核的 LangGraph 路由、token 统计，以及 Deep
Agent 的工具调用白名单。

旧的 `evaluate_task_with_llm.py` 仍保留作为早期纯文本评测实现；它不会按需解析
多种文件格式，也不具备本 README 所述的受限 Deep Agent 多步读取能力。
