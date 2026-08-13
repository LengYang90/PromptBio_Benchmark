from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from promptbio_evaluator.agents import (
    AgentConfig,
    READ_ONLY_EXCLUDED_TOOLS,
    READ_ONLY_TOOL_NAMES,
    StageRun,
    _ReadOnlyToolGate,
    _build_model,
    extract_usage,
)
from promptbio_evaluator.evidence import AccessLimits
from promptbio_evaluator.graph import EvaluationGraphRuntime, build_evaluation_graph
from promptbio_evaluator.models import AuditAssessment, FileObservation, InitialAssessment, ModelCallUsage
from promptbio_evaluator.policy import load_task


class GraphFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.task_dir = Path(self.temporary.name) / "task"
        self.result_dir = self.task_dir / "results_agent"
        (self.task_dir / "ref_answer").mkdir(parents=True)
        (self.task_dir / "ref_script").mkdir()
        (self.result_dir / "work").mkdir(parents=True)
        (self.task_dir / "task.json").write_text(
            json.dumps(
                {
                    "id": "graph-test",
                    "question": "Evaluate output.",
                    "expected_output": [{"file": "answer.txt", "type": "txt"}],
                }
            ),
            encoding="utf-8",
        )
        (self.task_dir / "ref_answer" / "answer.txt").write_text("reference\n", encoding="utf-8")
        (self.task_dir / "ref_script" / "reference.py").write_text("reference method\n", encoding="utf-8")
        (self.result_dir / "answer.txt").write_text("agent\n", encoding="utf-8")
        (self.result_dir / "work" / "command.sh").write_text("agent method\n", encoding="utf-8")
        (self.result_dir / "log.out").write_text("run complete\n", encoding="utf-8")
        self.task = load_task(self.task_dir)
        self.runtime = EvaluationGraphRuntime(
            task_dir=str(self.task_dir),
            result_dir=str(self.result_dir),
            task=self.task,
            config=AgentConfig("unused", "test-model", "https://example.invalid/v1", 1),
            limits=AccessLimits(),
        )

    @staticmethod
    def observation(evidence_id: str) -> list[FileObservation]:
        return [FileObservation(file="answer.txt", assessment="different", reason="test observation", evidence_ids=[evidence_id])]

    def test_pass_skips_audit(self) -> None:
        calls: list[str] = []

        def fake_run(*, store, response_schema, **_kwargs):
            calls.append(store.stage)
            store.read_text(str(self.task_dir / "ref_answer" / "answer.txt"), 1, 10)
            store.read_text(str(self.result_dir / "answer.txt"), 1, 10)
            return StageRun(
                InitialAssessment(
                    verdict="pass",
                    reason="files establish completion",
                    file_observations=self.observation("I-0001"),
                    evidence_ids=["I-0001", "I-0002"],
                ),
                [ModelCallUsage(stage="initial_assessment", call_index=1, model="test-model", input_tokens=3, output_tokens=2, total_tokens=5, cached_input_tokens=0, usage_reported_by_provider=True)],
            )

        with patch("promptbio_evaluator.graph.run_deep_agent", side_effect=fake_run):
            state = build_evaluation_graph(self.runtime).invoke({})

        self.assertEqual(calls, ["initial_assessment"])
        self.assertNotIn("audit_assessment", state)
        self.assertEqual(state["token_calls"][0]["total_tokens"], 5)

    def test_fail_routes_to_audit_and_keeps_both_usage_records(self) -> None:
        calls: list[str] = []

        def fake_run(*, store, response_schema, **_kwargs):
            calls.append(store.stage)
            if response_schema is InitialAssessment:
                store.read_text(str(self.task_dir / "ref_answer" / "answer.txt"), 1, 10)
                store.read_text(str(self.result_dir / "answer.txt"), 1, 10)
                return StageRun(
                    InitialAssessment(
                        verdict="fail",
                        reason="results differ",
                        file_observations=self.observation("I-0001"),
                        evidence_ids=["I-0001", "I-0002"],
                    ),
                    [ModelCallUsage(stage="initial_assessment", call_index=1, model="test-model", input_tokens=3, output_tokens=2, total_tokens=5, cached_input_tokens=0, usage_reported_by_provider=True)],
                )
            store.read_text(str(self.task_dir / "ref_script" / "reference.py"), 1, 10)
            store.read_text(str(self.result_dir / "work" / "command.sh"), 1, 10)
            store.read_text(str(self.result_dir / "log.out"), 1, 10)
            return StageRun(
                AuditAssessment(
                    score=1,
                    reason="method is supported",
                    reference_method="reference method",
                    agent_method="agent method",
                    file_observations=self.observation("A-0001"),
                    evidence_ids=["A-0001", "A-0002", "A-0003"],
                    confidence="high",
                ),
                [ModelCallUsage(stage="method_and_execution_audit", call_index=1, model="test-model", input_tokens=7, output_tokens=4, total_tokens=11, cached_input_tokens=1, usage_reported_by_provider=True)],
            )

        with patch("promptbio_evaluator.graph.run_deep_agent", side_effect=fake_run):
            state = build_evaluation_graph(self.runtime).invoke({})

        self.assertEqual(calls, ["initial_assessment", "method_and_execution_audit"])
        self.assertEqual(state["audit_assessment"]["score"], 1)
        self.assertEqual([item["total_tokens"] for item in state["token_calls"]], [5, 11])


class AgentSafetyAndUsageTests(unittest.TestCase):
    def test_gpt56_deep_agent_defaults_to_responses_api(self) -> None:
        with patch("promptbio_evaluator.agents.ChatOpenAI") as chat_openai:
            _build_model(AgentConfig("test-key", "gpt-5.6-terra", "https://api.openai.com/v1", 30))
        self.assertTrue(chat_openai.call_args.kwargs["use_responses_api"])

    def test_tool_gate_filters_and_blocks_non_evidence_tools(self) -> None:
        gate = _ReadOnlyToolGate()
        tools = [SimpleNamespace(name="read_text"), {"name": "inspect_table"}, SimpleNamespace(name="execute")]
        seen: list[list[str]] = []

        request = SimpleNamespace(
            tools=tools,
            override=lambda **kwargs: SimpleNamespace(tools=kwargs["tools"]),
        )
        gate.wrap_model_call(
            request,
            lambda filtered: seen.append(
                [tool.get("name") if isinstance(tool, dict) else tool.name for tool in filtered.tools]
            )
            or "ok",
        )
        self.assertEqual(seen, [["read_text", "inspect_table"]])

        denied = gate.wrap_tool_call(SimpleNamespace(tool_call={"name": "execute", "id": "call-1"}), lambda _request: "not reached")
        self.assertEqual(denied.status, "error")
        self.assertTrue(READ_ONLY_TOOL_NAMES.isdisjoint(READ_ONLY_EXCLUDED_TOOLS))

    def test_extract_usage_supports_both_langchain_and_chat_completion_shapes(self) -> None:
        messages = [
            SimpleNamespace(
                usage_metadata={
                    "input_tokens": 10,
                    "output_tokens": 4,
                    "total_tokens": 14,
                    "input_token_details": {"cache_read": 3},
                },
                response_metadata={},
            ),
            SimpleNamespace(
                usage_metadata=None,
                response_metadata={
                    "token_usage": {
                        "prompt_tokens": 7,
                        "completion_tokens": 2,
                        "total_tokens": 9,
                        "prompt_tokens_details": {"cached_tokens": 1},
                    }
                },
            ),
        ]
        result = extract_usage(messages, "initial_assessment", "test-model")
        self.assertEqual([(call.input_tokens, call.output_tokens, call.total_tokens, call.cached_input_tokens) for call in result], [(10, 4, 14, 3), (7, 2, 9, 1)])
