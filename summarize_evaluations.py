#!/usr/bin/env python3
"""Export selected fields from one or more task evaluation.json reports to CSV."""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path
from typing import Any


CSV_COLUMNS = [
    "question_id",
    "score",
    "rationale",
    "total_input_tokens",
    "total_output_tokens",
]


class SummaryError(ValueError):
    """Raised when a requested evaluation report is absent or malformed."""


def _positive_int(value: Any, *, field: str, report_path: Path) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise SummaryError(f"{report_path}: {field} must be a non-negative integer")
    return value


def _report_path(task_id: str, result_dir: Path) -> Path:
    task_path = Path(task_id)
    if task_path.is_absolute() or ".." in task_path.parts:
        raise SummaryError(f"question id must be a non-traversing relative task path: {task_id!r}")
    if result_dir.is_absolute() or ".." in result_dir.parts:
        raise SummaryError("--result-dir must be a non-traversing path relative to each question id")
    return task_path / result_dir / "evaluation.json"


def load_row(task_id: str, result_dir: Path) -> dict[str, str | int]:
    """Read and validate one task report, returning exactly the CSV columns."""
    report_path = _report_path(task_id, result_dir)
    try:
        payload = json.loads(report_path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SummaryError(f"Missing evaluation report: {report_path}") from exc
    except json.JSONDecodeError as exc:
        raise SummaryError(f"Invalid JSON in {report_path}: {exc}") from exc

    if not isinstance(payload, dict):
        raise SummaryError(f"{report_path}: evaluation report must be a JSON object")
    score = payload.get("score")
    if score not in (0, 1) or isinstance(score, bool):
        raise SummaryError(f"{report_path}: score must be 0 or 1")
    rationale = payload.get("rationale")
    if not isinstance(rationale, str):
        raise SummaryError(f"{report_path}: rationale must be a string")
    token_usage = payload.get("token_usage")
    if not isinstance(token_usage, dict):
        raise SummaryError(f"{report_path}: token_usage must be a JSON object")

    return {
        "question_id": task_id,
        "score": score,
        "rationale": rationale,
        "total_input_tokens": _positive_int(
            token_usage.get("total_input_tokens"),
            field="token_usage.total_input_tokens",
            report_path=report_path,
        ),
        "total_output_tokens": _positive_int(
            token_usage.get("total_output_tokens"),
            field="token_usage.total_output_tokens",
            report_path=report_path,
        ),
    }


def write_summary(task_ids: list[str], *, result_dir: Path, output: Path) -> Path:
    """Collect all requested reports before writing one UTF-8 CSV file."""
    if not task_ids:
        raise SummaryError("at least one question id is required")
    rows = [load_row(task_id, result_dir) for task_id in task_ids]
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)
    return output


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "question_ids",
        nargs="+",
        help="One or more task IDs/directories, for example a-1-10 a-2-8",
    )
    parser.add_argument(
        "--result-dir",
        type=Path,
        default=Path("results_glm"),
        help="Result directory relative to every question ID (default: results_glm)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Output CSV path and filename, for example reports/evaluation_summary.csv",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        output = write_summary(args.question_ids, result_dir=args.result_dir, output=args.output)
    except SummaryError as exc:
        print(f"Summary failed: {exc}", file=sys.stderr)
        return 2
    print(f"rows={len(args.question_ids)} csv={output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
