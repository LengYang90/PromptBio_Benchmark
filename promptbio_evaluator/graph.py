"""Deterministic LangGraph routing around two restricted Deep Agent stages."""

from __future__ import annotations

from typing import Any, Literal, TypedDict

from langgraph.graph import END, START, StateGraph

from .agents import (
    AgentConfig,
    audit_prompt,
    initial_prompt,
    run_deep_agent,
    validate_initial_inspection,
)
from .evidence import AccessLimits, EvidenceStore
from .models import AuditAssessment, InitialAssessment, ModelCallUsage, TaskSpec


class EvaluationState(TypedDict, total=False):
    initial_assessment: dict[str, Any]
    audit_assessment: dict[str, Any]
    token_calls: list[dict[str, Any]]


class EvaluationGraphRuntime:
    """Owns stage-specific stores so their evidence ledgers reach the final report."""

    def __init__(
        self,
        *,
        task_dir: str,
        result_dir: str,
        task: TaskSpec,
        config: AgentConfig,
        limits: AccessLimits,
    ) -> None:
        from pathlib import Path

        self.task_dir = str(Path(task_dir).resolve())
        self.result_dir = str(Path(result_dir).resolve())
        self.task = task
        self.config = config
        self.limits = limits
        self.initial_store: EvidenceStore | None = None
        self.audit_store: EvidenceStore | None = None

    def run_initial(self, _: EvaluationState) -> EvaluationState:
        self.initial_store = EvidenceStore(
            task_dir=self.task_dir,
            result_dir=self.result_dir,
            task=self.task,
            stage="initial_assessment",
            limits=self.limits,
        )
        result = run_deep_agent(
            config=self.config,
            store=self.initial_store,
            system_prompt=initial_prompt(self.task_dir, self.result_dir, self.task),
            response_schema=InitialAssessment,
        )
        validate_initial_inspection(self.task_dir, self.result_dir, self.task, self.initial_store)
        return {
            "initial_assessment": result.assessment.model_dump(),
            "token_calls": [item.model_dump() for item in result.usage],
        }

    def route_after_initial(self, state: EvaluationState) -> Literal["finish", "audit"]:
        initial = InitialAssessment.model_validate(state["initial_assessment"])
        return "finish" if initial.verdict == "pass" else "audit"

    def run_audit(self, state: EvaluationState) -> EvaluationState:
        initial = InitialAssessment.model_validate(state["initial_assessment"])
        self.audit_store = EvidenceStore(
            task_dir=self.task_dir,
            result_dir=self.result_dir,
            task=self.task,
            stage="method_and_execution_audit",
            limits=self.limits,
        )
        result = run_deep_agent(
            config=self.config,
            store=self.audit_store,
            system_prompt=audit_prompt(self.task_dir, self.result_dir, self.task, initial),
            response_schema=AuditAssessment,
            additional_valid_evidence_ids=(self.initial_store.valid_evidence_ids if self.initial_store else set()),
        )
        prior = list(state.get("token_calls", []))
        return {
            "audit_assessment": result.assessment.model_dump(),
            "token_calls": prior + [item.model_dump() for item in result.usage],
        }

    @staticmethod
    def finish(state: EvaluationState) -> EvaluationState:
        return state


def build_evaluation_graph(runtime: EvaluationGraphRuntime):
    """Compile fixed initial → conditional-audit → finish routing."""
    graph = StateGraph(EvaluationState)
    graph.add_node("initial_assessment", runtime.run_initial)
    graph.add_node("method_and_execution_audit", runtime.run_audit)
    graph.add_node("finish", runtime.finish)
    graph.add_edge(START, "initial_assessment")
    graph.add_conditional_edges(
        "initial_assessment",
        runtime.route_after_initial,
        {"finish": "finish", "audit": "method_and_execution_audit"},
    )
    graph.add_edge("method_and_execution_audit", "finish")
    graph.add_edge("finish", END)
    return graph.compile()
