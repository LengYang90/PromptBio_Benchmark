from __future__ import annotations

import csv
import json
import os
import tempfile
import unittest
from pathlib import Path

from summarize_evaluations import CSV_COLUMNS, SummaryError, load_row, write_summary


class SummarizeEvaluationsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        original_directory = Path.cwd()
        os.chdir(self.root)
        self.addCleanup(os.chdir, original_directory)

    def write_report(self, task_id: str, *, score: int, rationale: str, input_tokens: int, output_tokens: int) -> None:
        path = self.root / task_id / "results_glm"
        path.mkdir(parents=True)
        (path / "evaluation.json").write_text(
            json.dumps(
                {
                    "score": score,
                    "rationale": rationale,
                    "token_usage": {
                        "total_input_tokens": input_tokens,
                        "total_output_tokens": output_tokens,
                    },
                }
            ),
            encoding="utf-8",
        )

    def test_write_summary_preserves_order_and_csv_quoting(self) -> None:
        self.write_report("a-1-10", score=1, rationale="Correct, with evidence.", input_tokens=101, output_tokens=11)
        self.write_report("a-2-8", score=0, rationale="Line one\nLine two", input_tokens=202, output_tokens=22)
        output = self.root / "reports" / "summary.csv"

        written = write_summary(
            ["a-2-8", "a-1-10"],
            result_dir=Path("results_glm"),
            output=output,
        )

        self.assertEqual(written, output.resolve())
        with output.open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(CSV_COLUMNS, list(rows[0]))
        self.assertEqual(rows[0]["question_id"], "a-2-8")
        self.assertEqual(rows[0]["rationale"], "Line one\nLine two")
        self.assertEqual(rows[1]["score"], "1")

    def test_failure_does_not_create_partial_csv(self) -> None:
        self.write_report("a-1-10", score=1, rationale="Correct", input_tokens=1, output_tokens=2)
        output = self.root / "summary.csv"

        with self.assertRaisesRegex(SummaryError, "Missing evaluation report"):
            write_summary(
                ["a-1-10", "missing-task"],
                result_dir=Path("results_glm"),
                output=output,
            )
        self.assertFalse(output.exists())

    def test_rejects_invalid_score_and_path_traversal(self) -> None:
        self.write_report("a-1-10", score=2, rationale="Bad", input_tokens=1, output_tokens=2)
        with self.assertRaisesRegex(SummaryError, "score must be 0 or 1"):
            load_row("a-1-10", Path("results_glm"))
        with self.assertRaisesRegex(SummaryError, "non-traversing"):
            load_row("../a-1-10", Path("results_glm"))
