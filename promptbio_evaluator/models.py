"""Validated data models for task-level assessment and audit reporting."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class OutputSpec(BaseModel):
    """An output requirement declared by task.json."""

    file: str = Field(min_length=1)
    type: str | None = None
    description: str | None = None


class TaskSpec(BaseModel):
    """The subset of task.json used by the evaluator."""

    id: str | None = None
    question: str = Field(min_length=1)
    expected_output: list[OutputSpec] = Field(min_length=1)


class FileObservation(BaseModel):
    """A file-pair observation that supports, but does not determine, task score."""

    file: str
    assessment: Literal["consistent", "different", "uncertain"]
    reason: str
    evidence_ids: list[str] = Field(min_length=1)


class InitialAssessment(BaseModel):
    """Task-level conclusion from answer-only inspection."""

    verdict: Literal["pass", "fail", "uncertain"]
    reason: str
    file_observations: list[FileObservation] = Field(min_length=1)
    evidence_ids: list[str] = Field(min_length=1)


class AuditAssessment(BaseModel):
    """Final task-level conclusion after method and execution evidence review."""

    score: Literal[0, 1]
    reason: str
    reference_method: str
    agent_method: str
    file_observations: list[FileObservation] = Field(min_length=1)
    evidence_ids: list[str] = Field(min_length=1)
    confidence: Literal["high", "medium", "low"]


class EvidenceRecord(BaseModel):
    """A substantive source-content inspection through a read-only tool."""

    evidence_id: str
    path: str
    locator: str
    extractor: str
    sha256: str
    status: Literal["complete", "partial"]
    notes: list[str] = Field(default_factory=list)


class FileManifestEntry(BaseModel):
    """One physical source file available to one or both evaluation stages."""

    path: str
    roles: list[str] = Field(min_length=1)
    available_in_stages: list[Literal["initial_assessment", "method_and_execution_audit"]] = Field(min_length=1)
    size_bytes: int = Field(ge=0)
    suffix: str
    mime_type: str
    sha256: str


class ModelCallUsage(BaseModel):
    """Provider-reported token usage for one model response."""

    stage: Literal["initial_assessment", "method_and_execution_audit"]
    call_index: int = Field(ge=1)
    model: str
    input_tokens: int = Field(ge=0)
    output_tokens: int = Field(ge=0)
    total_tokens: int = Field(ge=0)
    cached_input_tokens: int = Field(ge=0)
    usage_reported_by_provider: bool


class TokenUsageReport(BaseModel):
    """Per-call and aggregate provider-reported token counts."""

    total_input_tokens: int = Field(ge=0)
    total_output_tokens: int = Field(ge=0)
    total_tokens: int = Field(ge=0)
    total_cached_input_tokens: int = Field(ge=0)
    calls: list[ModelCallUsage] = Field(default_factory=list)


class EvaluationReport(BaseModel):
    """Persisted evaluation.json schema."""

    task_id: str
    task_dir: str
    result_dir: str
    score: Literal[0, 1]
    rationale: str
    final_stage: Literal["answer_only_comparison", "method_and_execution_audit"]
    evaluator: dict[str, Any]
    scope: dict[str, Any]
    output_files: list[dict[str, Any]]
    file_manifest: list[FileManifestEntry]
    initial_assessment: InitialAssessment
    audit_assessment: AuditAssessment | None
    evidence_inventory: list[EvidenceRecord]
    coverage: dict[str, Any]
    token_usage: TokenUsageReport
