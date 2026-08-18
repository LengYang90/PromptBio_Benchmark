#!/usr/bin/env python3
"""Run the read-only, two-stage PromptBio Deep Agent evaluator for one task."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from promptbio_evaluator.runner import EvaluationConfig, dry_run_manifest, evaluate_task, write_report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("task_dir", type=Path, help="Task directory, for example a-1-10")
    parser.add_argument("--result-dir", type=Path, default=Path("results_glm"), help="Result directory relative to task_dir (default: results_glm)")
    parser.add_argument("--base-url", help="OpenAI-compatible API base URL (default: BASE_URL or https://api.openai.com/v1)")
    parser.add_argument(
        "--api-mode",
        choices=("responses", "chat_completions"),
        help="API protocol (default: API_MODE or responses). gpt-5.6 tool calls require responses.",
    )
    parser.add_argument("--api-key", help="API key (default: API_KEY or OPENAI_API_KEY)")
    parser.add_argument("--model", help="Model name (default: MODEL or LLM_MODEL)")
    parser.add_argument("--timeout", type=int, default=600, help="Timeout for one model request, in seconds")
    parser.add_argument("--max-text-characters", type=int, default=1_000_000, help="Maximum source characters returned by one text/JSON/PDF-page tool call")
    parser.add_argument("--max-table-rows", type=int, default=200, help="Maximum sampled data rows returned per table inspection")
    parser.add_argument("--max-records", type=int, default=100, help="Maximum sampled records returned per bioinformatics-file inspection")
    parser.add_argument("--max-image-bytes", type=int, default=8_000_000, help="Maximum in-memory PNG preview bytes returned by image/PDF tools")
    parser.add_argument("--dry-run", action="store_true", help="Print only the answer-only stage allowlist; do not create an agent, call an API, or write a report")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        # Dry run does not require credentials, but reuses read-only limits.
        config = EvaluationConfig.from_environment(
            api_key=args.api_key or ("dry-run" if args.dry_run else None),
            model=args.model or ("dry-run" if args.dry_run else None),
            base_url=args.base_url,
            api_mode=args.api_mode,
            timeout_seconds=args.timeout,
            max_text_characters=args.max_text_characters,
            max_table_rows=args.max_table_rows,
            max_records=args.max_records,
            max_image_bytes=args.max_image_bytes,
        )
        if args.dry_run:
            print(json.dumps(dry_run_manifest(args.task_dir, result_dir=args.result_dir, config=config), ensure_ascii=False, indent=2))
            return 0
        report = evaluate_task(args.task_dir, result_dir=args.result_dir, config=config)
        result_dir = args.result_dir if args.result_dir.is_absolute() else args.task_dir.resolve() / args.result_dir
        path = write_report(report, result_dir)
        print(f"score={report.score} report={path}")
        return 0
    except Exception as exc:
        print(f"Evaluation failed: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
