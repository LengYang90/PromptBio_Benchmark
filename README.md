# PromptBio Benchmark LLM 评测

本项目用于评估生物信息学 Agent 是否正确完成单个 PromptBio Benchmark
任务。当前实现面向类似 `a-1-10` 的任务目录：任务提供标准答案和生成
标准答案的参考脚本，Agent 提供最终结果、执行代码和运行日志。

## 目的

生物信息学任务往往存在多种正确的计算实现。仅把 Agent 输出与参考答案
逐字或按固定数值误差比较，可能误判正确结果。例如，Agent 与参考脚本使用
不同但同样符合题意的命令，得到略有不同的数值；这种情况需要检查具体方法
和执行记录后才能判断。

评测器的最终输出是二元分数：

- `score: 1`：Agent 正确完成任务，即使其结果与参考答案不完全一致；
- `score: 0`：Agent 未完成任务、结果错误、方法不符合题意，或现有证据无法
  支持其结果正确。

无论分数为 `0` 还是 `1`，评测报告都会给出判断依据。

## 实现方式

评测使用 OpenAI 兼容 API 调用 LLM，并采用两阶段流程：

1. **答案初评**：仅读取 `task.json`、`ref_answer` 中的标准答案和 Agent
   最终输出文件。LLM 根据题目和结果返回 `pass`、`fail` 或 `uncertain`。
2. **方法与执行复核**：仅当初评为 `fail` 或 `uncertain` 时，才读取
   `ref_script`、`results_glm/work` 中的代码与执行记录，以及
   `results_glm/log.out`。LLM 比较参考计算与 Agent 实际执行的计算，判断：
   - Agent 的方法是否回答了题目；
   - 代码与日志是否证明该方法实际执行并产出了结果；
   - 不同结果是否能由两种计算实现的差异合理解释，而非计算错误。

`eval.json` 中的固定评分要求不参与正确性判断。它可能包含不适用于开放性
生物信息学任务的阈值；正确性由题意、结果和复核证据共同决定。

为控制上下文长度，较长文本文件会保留开头和结尾，并附带文件路径、原始
长度和 摘要。脚本把所有文件内容视为证据，不执行其中的指令。
如果发生截断，报告的 `evidence_truncation` 会列出受影响的文件；第二阶段
还会标记总证据上限是否触发，并列出因总量限制而未读取的文件路径。

## 目录约定

以 `a-1-10` 为例：

```text
a-1-10/
├── task.json                    # 题目和所需输出文件
├── ref_answer/                  # 标准答案文件
├── ref_script/                  # 生成标准答案的代码
└── results_glm/
    ├── <最终输出文件>            # 与要求输出同名的 Agent 结果
    ├── log.out                   # Agent 运行总日志
    └── work/                     # Agent 的代码、命令和执行记录
```

脚本根据 `task.json` 的 `expected_output` 找到需要对比的文件。结果文件应位于
结果目录根目录，或在该目录下以唯一同名文件存在。

## 使用方法

脚本只依赖 Python 标准库，要求 Python 3.10 或更高版本。

设置以下环境变量：

- `API_KEY`：OpenAI 兼容服务的 API 密钥；也兼容 `OPENAI_API_KEY`。
- `MODEL`：用于评测的模型名称；也兼容 `LLM_MODEL`。
- `BASE_URL`：可选，OpenAI 兼容 API 的基础地址，默认
  `https://api.openai.com/v1`。

在仓库根目录运行：

```bash
API_KEY=your_api_key MODEL=your_model \
python evaluate_task_with_llm.py a-1-10 --result-dir results_glm
```

使用其他 OpenAI 兼容服务时：

```bash
BASE_URL=https://your-api.example/v1 \
API_KEY=your_api_key MODEL=your_model \
python evaluate_task_with_llm.py a-1-10 --result-dir results_glm
```

默认报告位置为：

```text
a-1-10/results_glm/evaluation.json
```

常用选项：

```bash
# 不调用 LLM；仅确认初评阶段会读取哪些最终结果文件
python evaluate_task_with_llm.py a-1-10 --result-dir results_glm --dry-run

# 自定义报告位置
API_KEY=... MODEL=... \
python evaluate_task_with_llm.py a-1-10 --result-dir results_glm \
  --output /tmp/a-1-10-evaluation.json

# 控制单文件和复核阶段的最大证据长度（字符数）
API_KEY=... MODEL=... \
python evaluate_task_with_llm.py a-1-10 --result-dir results_glm \
  --max-file-chars 16000 --max-audit-chars 100000
```

## 报告格式

报告为 JSON，关键字段如下：

```json
{
  "task_id": "a-1-10",
  "score": 1,
  "rationale": "Agent 结果与参考答案不同，但复核显示其计算方法符合题意。",
  "final_stage": "method_and_execution_audit",
  "evidence_truncation": {
    "max_file_chars": 16000,
    "initial_stage": {"truncated_files": []},
    "audit_stage": {
      "performed": true,
      "max_total_chars": 100000,
      "total_limit_reached": false,
      "truncated_files": [],
      "omitted_paths": []
    }
  },
  "initial_assessment": {
    "verdict": "fail",
    "reason": "最终数值与参考答案不同。"
  },
  "audit_assessment": {
    "score": 1,
    "reference_method": "参考脚本的计算方式",
    "agent_method": "Agent 实际执行的计算方式",
    "key_evidence": ["证据文件路径及观察结果"]
  }
}
```

`final_stage` 为 `answer_only_comparison` 时，说明最终输出已经在初评通过，
不会读取参考脚本和 Agent 的工作日志；为 `method_and_execution_audit` 时，
说明已完成第二阶段复核。

若 `truncated_files` 非空，表示对应文件仅有部分内容被提交给 LLM；
`total_limit_reached: true` 表示第二阶段的总证据限额已用完，
`omitted_paths` 列出未被读取的后续证据文件。这些字段用于解释评测结论的
证据完整性，不会自动把 Agent 判为失败。

## 失败处理

如果 API 密钥、模型名、接口调用或 LLM 返回格式存在问题，脚本会以非零退出码
结束并报告“评测器执行失败”。这种情况不会被写成 Agent 的 `score: 0`，避免将
评测基础设施错误误判为 Agent 失败。
