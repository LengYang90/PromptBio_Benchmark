"""High-level task evaluation runner and deterministic report assembly."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal, cast

from .agents import AgentConfig
from .evidence import AccessLimits, EvidenceStore
from .graph import EvaluationGraphRuntime, build_evaluation_graph
from .models import (
    AuditAssessment,
    EvaluationReport,
    FileManifestEntry,
    InitialAssessment,
    ModelCallUsage,
    TokenUsageReport,
)
from .policy import PolicyError, load_task, output_pair_manifest


DEFAULT_BASE_URL = "https://api.openai.com/v1"
ApiMode = Literal["responses", "chat_completions"]


@dataclass(frozen=True)
class EvaluationConfig:
    """Runtime options; API values may be supplied by environment variables."""

    api_key: str
    model: str
    base_url: str = DEFAULT_BASE_URL
    api_mode: ApiMode = "responses"
    timeout_seconds: int = 600
    max_text_characters: int = 1_000_000
    max_table_rows: int = 200
    max_records: int = 100
    max_image_bytes: int = 8_000_000

    @classmethod
    def from_environment(
        cls,
        *,
        api_key: str | None = None,
        model: str | None = None,
        base_url: str | None = None,
        api_mode: str | None = None,
        timeout_seconds: int = 600,
        max_text_characters: int = 1_000_000,
        max_table_rows: int = 200,
        max_records: int = 100,
        max_image_bytes: int = 8_000_000,
    ) -> "EvaluationConfig":
        resolved_api_key = api_key or os.getenv("API_KEY") or os.getenv("OPENAI_API_KEY")
        resolved_model = model or os.getenv("MODEL") or os.getenv("LLM_MODEL")
        if not resolved_api_key:
            raise ValueError("API key is missing. Set API_KEY or pass --api-key.")
        if not resolved_model:
            raise ValueError("Model is missing. Set MODEL or pass --model.")
        resolved_api_mode = api_mode or os.getenv("API_MODE") or "responses"
        if resolved_api_mode not in {"responses", "chat_completions"}:
            raise ValueError("API mode must be 'responses' or 'chat_completions'.")
        return cls(
            api_key=resolved_api_key,
            model=resolved_model,
            base_url=base_url or os.getenv("BASE_URL") or DEFAULT_BASE_URL,
            api_mode=cast(ApiMode, resolved_api_mode),
            timeout_seconds=timeout_seconds,
            max_text_characters=max_text_characters,
            max_table_rows=max_table_rows,
            max_records=max_records,
            max_image_bytes=max_image_bytes,
        )

    def limits(self) -> AccessLimits:
        return AccessLimits(
            max_text_characters=self.max_text_characters,
            max_table_rows=self.max_table_rows,
            max_records=self.max_records,
            max_image_bytes=self.max_image_bytes,
        )


def _validate_config(config: EvaluationConfig) -> None:
    if config.timeout_seconds < 1:
        raise ValueError("timeout_seconds must be positive")
    if config.max_text_characters < 1:
        raise ValueError("max_text_characters must be positive")
    if config.max_table_rows < 1 or config.max_records < 1 or config.max_image_bytes < 1:
        raise ValueError("all read-only inspection limits must be positive")


def _token_report(raw_calls: list[dict[str, Any]]) -> TokenUsageReport:
    calls = [ModelCallUsage.model_validate(item) for item in raw_calls]
    return TokenUsageReport(
        total_input_tokens=sum(item.input_tokens for item in calls),
        total_output_tokens=sum(item.output_tokens for item in calls),
        total_tokens=sum(item.total_tokens for item in calls),
        total_cached_input_tokens=sum(item.cached_input_tokens for item in calls),
        calls=calls,
    )


def _merged_coverage(initial_store: EvidenceStore, audit_store: EvidenceStore | None) -> dict[str, Any]:
    stages: dict[str, Any] = {"initial_assessment": initial_store.coverage()}
    all_records = initial_store.records
    if audit_store is not None:
        stages["method_and_execution_audit"] = audit_store.coverage()
        all_records += audit_store.records
    inspected_paths = {record.path for record in all_records}
    partial_paths = {record.path for record in all_records if record.status == "partial"}
    discovered_paths = {
        *[record.path for record in initial_store.records],
        *([record.path for record in audit_store.records] if audit_store else []),
    }
    return {
        "by_stage": stages,
        "evidence_paths_discovered": len(discovered_paths),
        "evidence_paths_inspected": len(inspected_paths),
        "partial_evidence_paths": sorted(partial_paths),
    }


def _merged_file_manifest(
    initial_store: EvidenceStore,
    audit_store: EvidenceStore | None,
) -> list[FileManifestEntry]:
    """Merge stage-scoped navigation metadata into one row per physical file."""
    entries: dict[str, dict[str, Any]] = {}
    for store in (initial_store, audit_store):
        if store is None:
            continue
        for item in store.report_file_manifest():
            current = entries.get(item["path"])
            if current is None:
                entries[item["path"]] = {
                    "path": item["path"],
                    "roles": {item["role"]},
                    "available_in_stages": {item["stage"]},
                    "size_bytes": item["size_bytes"],
                    "suffix": item["suffix"],
                    "mime_type": item["mime_type"],
                    "sha256": item["sha256"],
                }
                continue
            if (
                current["size_bytes"] != item["size_bytes"]
                or current["sha256"] != item["sha256"]
            ):
                raise RuntimeError(
                    "An evidence source changed during evaluation and cannot be represented "
                    f"as one immutable manifest entry: {item['path']}"
                )
            current["roles"].add(item["role"])
            current["available_in_stages"].add(item["stage"])

    return [
        FileManifestEntry(
            path=item["path"],
            roles=sorted(item["roles"]),
            available_in_stages=sorted(item["available_in_stages"]),
            size_bytes=item["size_bytes"],
            suffix=item["suffix"],
            mime_type=item["mime_type"],
            sha256=item["sha256"],
        )
        for _, item in sorted(entries.items())
    ]


def evaluate_task(
    task_dir: str | Path,
    *,
    result_dir: str | Path = "results_glm",
    config: EvaluationConfig,
) -> EvaluationReport:
    """Evaluate a single task through the fixed two-stage LangGraph workflow."""
    _validate_config(config)
    resolved_task_dir = Path(task_dir).resolve()
    resolved_result_dir = Path(result_dir)
    if not resolved_result_dir.is_absolute():
        resolved_result_dir = resolved_task_dir / resolved_result_dir
    resolved_result_dir = resolved_result_dir.resolve()
    if not resolved_result_dir.is_dir():
        raise PolicyError(f"Result directory is missing: {resolved_result_dir}")

    task = load_task(resolved_task_dir)
    runtime = EvaluationGraphRuntime(
        task_dir=str(resolved_task_dir),
        result_dir=str(resolved_result_dir),
        task=task,
        config=AgentConfig(
            api_key=config.api_key,
            model=config.model,
            base_url=config.base_url,
            timeout_seconds=config.timeout_seconds,
            use_responses_api=config.api_mode == "responses",
        ),
        limits=config.limits(),
    )
    graph = build_evaluation_graph(runtime)
    final_state = graph.invoke({})
    if runtime.initial_store is None:
        raise RuntimeError("Initial evidence store was not initialized")

    initial = InitialAssessment.model_validate(final_state["initial_assessment"])
    audit = (
        AuditAssessment.model_validate(final_state["audit_assessment"])
        if final_state.get("audit_assessment") is not None
        else None
    )
    score = 1 if initial.verdict == "pass" else (audit.score if audit else 0)
    rationale = initial.reason if initial.verdict == "pass" else (audit.reason if audit else "Method-and-execution audit did not return a score.")
    final_stage = "answer_only_comparison" if initial.verdict == "pass" else "method_and_execution_audit"
    evidence = runtime.initial_store.records + (runtime.audit_store.records if runtime.audit_store else [])
    return EvaluationReport(
        task_id=task.id or resolved_task_dir.name,
        task_dir=str(resolved_task_dir),
        result_dir=str(resolved_result_dir),
        score=score,
        rationale=rationale,
        final_stage=final_stage,
        evaluator={
            "model": config.model,
            "base_url": config.base_url,
            "api_mode": config.api_mode,
            "architecture": "LangGraph fixed routing with stage-scoped read-only Deep Agents",
            "strategy": "all declared output pairs assessed together; conditional method-and-execution audit",
        },
        scope={
            "original_input_files_available": False,
            "scripts_executed": False,
            "network_access_used_by_agent_tools": False,
            "task_files_modified": False,
            "undeclared_result_files_used_as_evidence": False,
        },
        output_files=output_pair_manifest(resolved_task_dir, resolved_result_dir, task),
        file_manifest=_merged_file_manifest(runtime.initial_store, runtime.audit_store),
        initial_assessment=initial,
        audit_assessment=audit,
        evidence_inventory=evidence,
        coverage=_merged_coverage(runtime.initial_store, runtime.audit_store),
        token_usage=_token_report(list(final_state.get("token_calls", []))),
    )


def dry_run_manifest(task_dir: str | Path, *, result_dir: str | Path, config: EvaluationConfig) -> dict[str, Any]:
    """Show the initial-stage source allowlist without constructing or calling a model."""
    _validate_config(config)
    resolved_task_dir = Path(task_dir).resolve()
    resolved_result_dir = Path(result_dir)
    if not resolved_result_dir.is_absolute():
        resolved_result_dir = resolved_task_dir / resolved_result_dir
    task = load_task(resolved_task_dir)
    store = EvidenceStore(resolved_task_dir, resolved_result_dir, task, "initial_assessment", config.limits())
    return {
        "task_id": task.id or resolved_task_dir.name,
        "stage": "initial_assessment",
        "output_pairs": output_pair_manifest(resolved_task_dir, resolved_result_dir, task),
        "allowed_file_manifest": store.allowed_file_manifest(),
        "scope": {
            "ref_script_readable": False,
            "work_readable": False,
            "log_out_readable": False,
            "scripts_executed": False,
        },
    }


def write_report(report: EvaluationReport, result_dir: str | Path) -> Path:
    """The sole authorized write: result_dir/evaluation.json."""
    target_dir = Path(result_dir).resolve()
    if not target_dir.is_dir():
        raise PolicyError(f"Cannot write report; missing result directory: {target_dir}")
    output = target_dir / "evaluation.json"
    output.write_text(report.model_dump_json(indent=2) + "\n", encoding="utf-8")
    return output
