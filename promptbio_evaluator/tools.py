"""Restricted LangChain tools that expose only the EvidenceStore allowlist."""

from __future__ import annotations

import json
from typing import Any

from langchain_core.tools import BaseTool, tool

from .evidence import EvidenceStore
from .policy import PolicyError


def _tool_error(exc: Exception) -> str:
    return json.dumps({"status": "error", "error": str(exc), "hint": "Choose an allowed path and an appropriate read-only inspection tool."})


def build_readonly_tools(store: EvidenceStore) -> list[BaseTool]:
    """Create stage-bound tools; none writes files, invokes code, or uses a network."""

    @tool("list_evidence_files")
    def list_evidence_files() -> str:
        """List navigation metadata for every file permitted in this stage, with role and absolute path. This does not create citable evidence IDs."""
        try:
            return json.dumps({"status": "ok", "stage": store.stage, "files": store.allowed_file_manifest()}, ensure_ascii=False)
        except Exception as exc:  # Tool errors must be visible to the agent, not crash the graph.
            return _tool_error(exc)

    @tool("get_file_metadata")
    def get_file_metadata(path: str) -> str:
        """Get navigation metadata for one allowed file. Inspect its content with another tool before citing it."""
        try:
            return json.dumps({"status": "ok", "result": store.metadata(path)}, ensure_ascii=False)
        except (PolicyError, OSError) as exc:
            return _tool_error(exc)

    @tool("read_text")
    def read_text(path: str, start_line: int = 1, line_count: int = 500) -> str:
        """Read a numbered line range from one allowed text/code/log file. Use pagination for later ranges."""
        try:
            return json.dumps({"status": "ok", "result": store.read_text(path, start_line, line_count)}, ensure_ascii=False)
        except (PolicyError, OSError) as exc:
            return _tool_error(exc)

    @tool("search_text")
    def search_text(path: str, query: str, context_lines: int = 2, max_matches: int = 20) -> str:
        """Search literal text in an allowed text/code/log file and return small contextual excerpts."""
        try:
            return json.dumps({"status": "ok", "result": store.search_text(path, query, context_lines, max_matches)}, ensure_ascii=False)
        except (PolicyError, OSError) as exc:
            return _tool_error(exc)

    @tool("inspect_json")
    def inspect_json(path: str, pointer: str = "/") -> str:
        """Inspect an allowed JSON file or a JSON Pointer subtree without executing it."""
        try:
            return json.dumps({"status": "ok", "result": store.inspect_json(path, pointer)}, ensure_ascii=False)
        except (PolicyError, OSError, KeyError, IndexError, ValueError) as exc:
            return _tool_error(exc)

    @tool("inspect_table")
    def inspect_table(path: str, sample_rows: int = 50) -> str:
        """Inspect headers and sample rows from an allowed CSV, TSV, TXT, XLSX, or XLSM file."""
        try:
            return json.dumps({"status": "ok", "result": store.inspect_table(path, sample_rows)}, ensure_ascii=False)
        except (PolicyError, OSError) as exc:
            return _tool_error(exc)

    @tool("inspect_image")
    def inspect_image(path: str, include_preview: bool = True) -> list[dict[str, Any]] | str:
        """Read metadata and an in-memory visual preview of an allowed raster image; never alter it."""
        try:
            return store.inspect_image(path, include_preview)
        except (PolicyError, OSError) as exc:
            return _tool_error(exc)

    @tool("inspect_pdf")
    def inspect_pdf(path: str, pages: list[int] | None = None, include_preview: bool = True) -> list[dict[str, Any]] | str:
        """Extract text and optional in-memory previews from selected pages of an allowed PDF."""
        try:
            return store.inspect_pdf(path, pages or [], include_preview)
        except (PolicyError, OSError) as exc:
            return _tool_error(exc)

    @tool("inspect_bio_file")
    def inspect_bio_file(path: str, record_limit: int = 50) -> str:
        """Read headers and sample records from allowed FASTA/FASTQ, VCF/BCF, BAM, or CRAM files without commands or indexes."""
        try:
            return json.dumps({"status": "ok", "result": store.inspect_bio(path, record_limit)}, ensure_ascii=False)
        except (PolicyError, OSError) as exc:
            return _tool_error(exc)

    return [
        list_evidence_files,
        get_file_metadata,
        read_text,
        search_text,
        inspect_json,
        inspect_table,
        inspect_image,
        inspect_pdf,
        inspect_bio_file,
    ]
