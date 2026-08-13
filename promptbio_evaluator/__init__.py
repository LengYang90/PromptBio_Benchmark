"""Read-only, Deep Agent-based evaluator for PromptBio Benchmark tasks."""

from .runner import EvaluationConfig, evaluate_task

__all__ = ["EvaluationConfig", "evaluate_task"]
