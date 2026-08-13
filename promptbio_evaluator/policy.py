"""Read-only path policy for the two evaluation stages."""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Literal

from .models import TaskSpec


Stage = Literal["initial_assessment", "method_and_execution_audit"]


class PolicyError(ValueError):
    """Raised when an agent asks for a path outside its read-only scope."""


@dataclass(frozen=True)
class AllowedFile:
    """A file made visible to a stage-specific evidence store."""

    path: Path
    role: str


def load_task(task_dir: Path) -> TaskSpec:
    """Load task.json without consulting eval.json."""
    import json

    task_path = task_dir / "task.json"
    try:
        data = json.loads(task_path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise PolicyError(f"Missing task.json: {task_path}") from exc
    except json.JSONDecodeError as exc:
        raise PolicyError(f"Invalid task.json: {exc}") from exc
    task = TaskSpec.model_validate(data)
    names = [item.file for item in task.expected_output]
    if len(names) != len(set(names)):
        raise PolicyError("task.json expected_output contains duplicate file names")
    return task


def _is_inside(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True


def _declared_output_path(root: Path, filename: str) -> Path:
    """Resolve one task-declared output under its required output root.

    ``expected_output.file`` is data supplied by a benchmark task.  It must
    name a relative result artifact, never a path into ``ref_script`` or a
    sibling result file such as ``log.out``.  Validate it before the stage
    allowlist is assembled so a malformed task cannot widen initial access.
    """
    relative = Path(filename)
    if relative.is_absolute() or ".." in relative.parts or relative == Path("."):
        raise PolicyError(f"expected_output file must be a non-traversing relative path: {filename!r}")
    target = root / relative
    # ``strict=False`` allows the manifest to report a missing expected file,
    # while still rejecting lexical escapes such as a symlinked parent.
    resolved_root = root.resolve()
    resolved_target = target.resolve(strict=False)
    if not _is_inside(resolved_target, resolved_root):
        raise PolicyError(f"expected_output path escapes its output directory: {filename!r}")
    return target


def _safe_existing_file(path: Path, permitted_roots: Iterable[Path]) -> Path | None:
    """Return a resolved file only when it cannot escape an allowed root."""
    if not path.is_file():
        return None
    resolved = path.resolve(strict=True)
    if not any(_is_inside(resolved, root.resolve(strict=True)) for root in permitted_roots):
        raise PolicyError(f"Refusing symlink/path escape outside allowed roots: {path}")
    return resolved


def _collect_tree(root: Path, role: str, permitted_roots: Iterable[Path]) -> list[AllowedFile]:
    if not root.is_dir():
        return []
    files: list[AllowedFile] = []
    for path in sorted(root.rglob("*")):
        if path.is_file():
            resolved = _safe_existing_file(path, permitted_roots)
            if resolved is not None:
                files.append(AllowedFile(resolved, role))
    return files


def stage_allowed_files(
    task_dir: Path,
    result_dir: Path,
    task: TaskSpec,
    stage: Stage,
) -> list[AllowedFile]:
    """Build a whitelist; undeclared result files are intentionally excluded."""
    task_dir = task_dir.resolve()
    result_dir = result_dir.resolve()
    ref_dir = task_dir / "ref_answer"
    allowed: list[AllowedFile] = []

    task_file = _safe_existing_file(task_dir / "task.json", (task_dir,))
    if task_file is not None:
        allowed.append(AllowedFile(task_file, "task_definition"))

    for output in task.expected_output:
        for path, role in (
            (_declared_output_path(ref_dir, output.file), "reference_answer"),
            (_declared_output_path(result_dir, output.file), "agent_output"),
        ):
            permitted_root = ref_dir if role == "reference_answer" else result_dir
            resolved = _safe_existing_file(path, (permitted_root,))
            if resolved is not None:
                allowed.append(AllowedFile(resolved, role))

    if stage == "method_and_execution_audit":
        ref_script_dir = task_dir / "ref_script"
        work_dir = result_dir / "work"
        allowed.extend(_collect_tree(ref_script_dir, "reference_script", (ref_script_dir,)))
        allowed.extend(_collect_tree(work_dir, "agent_work", (work_dir,)))
        log_path = _safe_existing_file(result_dir / "log.out", (result_dir,))
        if log_path is not None:
            allowed.append(AllowedFile(log_path, "agent_runtime_log"))

    # A set deduplicates files while retaining stable, sorted output below.
    by_path: dict[Path, AllowedFile] = {entry.path: entry for entry in allowed}
    return [by_path[path] for path in sorted(by_path)]


def output_pair_manifest(task_dir: Path, result_dir: Path, task: TaskSpec) -> list[dict[str, object]]:
    """Produce the complete required reference-result pairing manifest."""
    pairs: list[dict[str, object]] = []
    for spec in task.expected_output:
        reference = _declared_output_path(task_dir / "ref_answer", spec.file).resolve()
        agent = _declared_output_path(result_dir, spec.file).resolve()
        pairs.append(
            {
                "file": spec.file,
                "description": spec.description or "",
                "type": spec.type or "",
                "reference_path": str(reference),
                "agent_path": str(agent),
                "reference_exists": reference.is_file(),
                "agent_exists": agent.is_file(),
            }
        )
    return pairs


def file_sha256(path: Path) -> str:
    """Hash evidence incrementally without modifying it."""
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()
