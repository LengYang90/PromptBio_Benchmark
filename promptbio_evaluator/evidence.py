"""Evidence inventory and read-only content access for Deep Agent tools."""

from __future__ import annotations

import base64
import csv
import io
import json
import mimetypes
from dataclasses import dataclass
from pathlib import Path
from threading import RLock
from typing import Any, Literal

from .models import EvidenceRecord, TaskSpec
from .policy import AllowedFile, PolicyError, Stage, file_sha256, stage_allowed_files


TEXT_EXTENSIONS = {
    ".txt", ".csv", ".tsv", ".json", ".jsonl", ".yaml", ".yml", ".xml",
    ".html", ".htm", ".md", ".rst", ".log", ".out", ".err", ".sh", ".py",
    ".r", ".rmd", ".pl", ".awk", ".bed", ".gff", ".gff3", ".gtf", ".vcf",
    ".fasta", ".fa", ".fna", ".ffn", ".faa", ".frn", ".fastq", ".fq", ".sam",
    # STAR Chimeric.out.junction is a tab-delimited text report. It has no
    # required header, so read_text/search_text are safer than header-based
    # table sampling for this artifact type.
    ".junction",
}
TABLE_EXTENSIONS = {".csv", ".tsv", ".txt", ".xlsx", ".xlsm"}
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".tif", ".tiff"}
BIO_EXTENSIONS = {".fa", ".fasta", ".fna", ".ffn", ".faa", ".frn", ".fq", ".fastq", ".vcf", ".bcf", ".bam", ".cram"}


@dataclass(frozen=True)
class AccessLimits:
    """Bound the size of a single read while allowing explicit pagination."""

    max_text_characters: int = 1_000_000
    max_table_rows: int = 200
    max_records: int = 100
    max_image_bytes: int = 8_000_000


class EvidenceStore:
    """Stage-scoped, immutable source catalog plus an append-only evidence ledger."""

    def __init__(
        self,
        task_dir: Path,
        result_dir: Path,
        task: TaskSpec,
        stage: Stage,
        limits: AccessLimits,
    ) -> None:
        self.task_dir = Path(task_dir).resolve()
        self.result_dir = Path(result_dir).resolve()
        self.task = task
        self.stage = stage
        self.limits = limits
        allowed = stage_allowed_files(self.task_dir, self.result_dir, task, stage)
        self._files: dict[Path, AllowedFile] = {item.path: item for item in allowed}
        self._records: list[EvidenceRecord] = []
        self._partial_paths: set[Path] = set()
        self._hashes: dict[Path, str] = {}
        self._lock = RLock()
        self._next_evidence_number = 1
        self._evidence_prefix = "I" if stage == "initial_assessment" else "A"

    def _relative_path(self, path: Path) -> str:
        for root in (self.task_dir, self.result_dir):
            try:
                return str(path.relative_to(root.parent))
            except ValueError:
                continue
        return str(path)

    def _resolve_allowed(self, raw_path: str) -> tuple[Path, AllowedFile]:
        candidate = Path(raw_path)
        if not candidate.is_absolute():
            # Tool results list absolute paths, but resolving a relative path
            # against the task root makes manual CLI inspection predictable.
            candidate = self.task_dir / candidate
        try:
            resolved = candidate.resolve(strict=True)
        except FileNotFoundError as exc:
            raise PolicyError(f"Evidence file does not exist: {raw_path}") from exc
        entry = self._files.get(resolved)
        if entry is None:
            raise PolicyError(
                f"Path is outside the {self.stage} read-only allowlist: {raw_path}"
            )
        return resolved, entry

    def _hash(self, path: Path) -> str:
        with self._lock:
            if path not in self._hashes:
                self._hashes[path] = file_sha256(path)
            return self._hashes[path]

    def cite(
        self,
        path: Path,
        *,
        locator: str,
        extractor: str,
        status: Literal["complete", "partial"],
        notes: list[str] | None = None,
    ) -> EvidenceRecord:
        """Record a content inspection with a thread-safe, unique ID."""
        with self._lock:
            evidence_id = f"{self._evidence_prefix}-{self._next_evidence_number:04d}"
            self._next_evidence_number += 1
            if status == "partial":
                self._partial_paths.add(path)
            record = EvidenceRecord(
                evidence_id=evidence_id,
                path=self._relative_path(path),
                locator=locator,
                extractor=extractor,
                sha256=self._hash(path),
                status=status,
                notes=notes or [],
            )
            self._records.append(record)
            return record

    def allowed_file_manifest(self) -> list[dict[str, Any]]:
        """List navigation metadata, without creating a citation record."""
        entries: list[dict[str, Any]] = []
        for path, item in sorted(self._files.items()):
            entries.append(
                {
                    "path": str(path),
                    "role": item.role,
                    "size_bytes": path.stat().st_size,
                    "suffix": path.suffix.lower(),
                    "mime_type": mimetypes.guess_type(path.name)[0] or "application/octet-stream",
                    "sha256": self._hash(path),
                }
            )
        return entries

    def metadata(self, raw_path: str) -> dict[str, Any]:
        path, item = self._resolve_allowed(raw_path)
        return {
            "path": str(path),
            "role": item.role,
            "size_bytes": path.stat().st_size,
            "suffix": path.suffix.lower(),
            "mime_type": mimetypes.guess_type(path.name)[0] or "application/octet-stream",
            "sha256": self._hash(path),
        }

    def report_file_manifest(self) -> list[dict[str, Any]]:
        """Return each source once for report-level file provenance."""
        return [
            {
                "path": self._relative_path(path),
                "role": item.role,
                "stage": self.stage,
                "size_bytes": path.stat().st_size,
                "suffix": path.suffix.lower(),
                "mime_type": mimetypes.guess_type(path.name)[0] or "application/octet-stream",
                "sha256": self._hash(path),
            }
            for path, item in sorted(self._files.items())
        ]

    def read_text(self, raw_path: str, start_line: int, line_count: int) -> dict[str, Any]:
        if start_line < 1 or line_count < 1:
            raise PolicyError("start_line and line_count must be positive integers")
        path, _ = self._resolve_allowed(raw_path)
        if path.suffix.lower() not in TEXT_EXTENSIONS:
            raise PolicyError(
                f"{path.name} is not a supported plain-text file; choose a type-specific inspection tool"
            )

        selected: list[str] = []
        total_lines = 0
        total_characters = 0
        was_truncated = False
        last_line = start_line - 1
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            for line_number, line in enumerate(handle, start=1):
                total_lines = line_number
                if line_number < start_line:
                    continue
                if len(selected) >= line_count:
                    was_truncated = True
                    continue
                if total_characters + len(line) > self.limits.max_text_characters:
                    was_truncated = True
                    break
                selected.append(line)
                total_characters += len(line)
                last_line = line_number

        locator = f"lines {start_line}-{last_line} of {total_lines}" if selected else f"lines {start_line}-{start_line} (empty range)"
        citation = self.cite(
            path,
            locator=locator,
            extractor="read_text",
            status="partial" if was_truncated else "complete",
            notes=["Output was limited; request the next line range for additional text."] if was_truncated else [],
        )
        return {
            "path": str(path),
            "content": "".join(selected),
            "start_line": start_line,
            "end_line": last_line,
            "total_lines_observed": total_lines,
            "truncated": was_truncated,
            "evidence_id": citation.evidence_id,
        }

    def search_text(
        self, raw_path: str, query: str, context_lines: int, max_matches: int
    ) -> dict[str, Any]:
        if not query:
            raise PolicyError("query must not be empty")
        if context_lines < 0 or max_matches < 1:
            raise PolicyError("context_lines must be non-negative and max_matches must be positive")
        path, _ = self._resolve_allowed(raw_path)
        if path.suffix.lower() not in TEXT_EXTENSIONS:
            raise PolicyError("search_text only supports plain-text evidence files")

        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        matches: list[dict[str, Any]] = []
        for index, line in enumerate(lines):
            if query not in line:
                continue
            start = max(0, index - context_lines)
            end = min(len(lines), index + context_lines + 1)
            matches.append(
                {
                    "line": index + 1,
                    "context_start_line": start + 1,
                    "context_end_line": end,
                    "content": "\n".join(lines[start:end]),
                }
            )
            if len(matches) >= max_matches:
                break
        truncated = sum(1 for line in lines if query in line) > len(matches)
        citation = self.cite(
            path,
            locator=f"search query {query!r}, {len(matches)} match(es)",
            extractor="search_text",
            status="partial" if truncated else "complete",
            notes=["Additional matches were omitted."] if truncated else [],
        )
        return {
            "path": str(path),
            "query": query,
            "matches": matches,
            "truncated": truncated,
            "evidence_id": citation.evidence_id,
        }

    def inspect_json(self, raw_path: str, pointer: str) -> dict[str, Any]:
        path, _ = self._resolve_allowed(raw_path)
        try:
            value: Any = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise PolicyError(f"Invalid JSON file {path.name}: {exc}") from exc
        if pointer and pointer != "/":
            for part in pointer.lstrip("/").split("/"):
                part = part.replace("~1", "/").replace("~0", "~")
                if isinstance(value, list):
                    value = value[int(part)]
                elif isinstance(value, dict):
                    value = value[part]
                else:
                    raise PolicyError(f"JSON pointer cannot descend into {type(value).__name__}")
        rendered = json.dumps(value, ensure_ascii=False, indent=2)
        truncated = len(rendered) > self.limits.max_text_characters
        content = rendered[: self.limits.max_text_characters] if truncated else rendered
        citation = self.cite(
            path,
            locator=f"JSON pointer {pointer or '/'}",
            extractor="inspect_json",
            status="partial" if truncated else "complete",
            notes=["Selected JSON value was truncated."] if truncated else [],
        )
        return {"path": str(path), "pointer": pointer or "/", "content": content, "truncated": truncated, "evidence_id": citation.evidence_id}

    def inspect_table(self, raw_path: str, sample_rows: int) -> dict[str, Any]:
        if sample_rows < 1:
            raise PolicyError("sample_rows must be positive")
        path, _ = self._resolve_allowed(raw_path)
        suffix = path.suffix.lower()
        row_limit = min(sample_rows, self.limits.max_table_rows)
        if suffix in {".xlsx", ".xlsm"}:
            return self._inspect_excel(path, row_limit)
        if suffix not in {".csv", ".tsv", ".txt"}:
            raise PolicyError("inspect_table supports CSV, TSV, TXT, XLSX, and XLSM files")
        delimiter = "\t" if suffix == ".tsv" else ","
        with path.open("r", encoding="utf-8", errors="replace", newline="") as handle:
            reader = csv.reader(handle, delimiter=delimiter)
            rows = list(reader)
        header = rows[0] if rows else []
        sample = rows[1 : row_limit + 1]
        citation = self.cite(
            path,
            locator=f"header and first {len(sample)} data rows of {max(len(rows) - 1, 0)}",
            extractor="inspect_table",
            status="partial" if len(rows) - 1 > len(sample) else "complete",
            notes=["Use read_text for other row ranges."] if len(rows) - 1 > len(sample) else [],
        )
        return {
            "path": str(path),
            "format": suffix.lstrip("."),
            "header": header,
            "row_count": max(len(rows) - 1, 0),
            "sample_rows": sample,
            "truncated": len(rows) - 1 > len(sample),
            "evidence_id": citation.evidence_id,
        }

    def _inspect_excel(self, path: Path, row_limit: int) -> dict[str, Any]:
        try:
            from openpyxl import load_workbook
        except ImportError as exc:
            raise PolicyError("Excel inspection requires openpyxl; install requirements.txt") from exc
        workbook = load_workbook(path, read_only=True, data_only=False)
        sheets: list[dict[str, Any]] = []
        for worksheet in workbook.worksheets:
            rows = []
            for row in worksheet.iter_rows(values_only=False):
                rows.append([cell.value for cell in row])
                if len(rows) >= row_limit + 1:
                    break
            sheets.append(
                {
                    "name": worksheet.title,
                    "max_row": worksheet.max_row,
                    "max_column": worksheet.max_column,
                    "header": rows[0] if rows else [],
                    "sample_rows": rows[1:],
                }
            )
        workbook.close()
        citation = self.cite(
            path,
            locator=f"all sheets; up to {row_limit} data rows per sheet",
            extractor="inspect_table",
            status="partial",
            notes=["Workbook inspection is sampled by row limit."],
        )
        return {"path": str(path), "format": "excel", "sheets": sheets, "truncated": True, "evidence_id": citation.evidence_id}

    def inspect_image(self, raw_path: str, include_preview: bool) -> list[dict[str, Any]]:
        path, _ = self._resolve_allowed(raw_path)
        if path.suffix.lower() not in IMAGE_EXTENSIONS:
            raise PolicyError("inspect_image only supports common raster image files")
        try:
            from PIL import Image
        except ImportError as exc:
            raise PolicyError("Image inspection requires Pillow; install requirements.txt") from exc

        with Image.open(path) as image:
            metadata = {"format": image.format, "width": image.width, "height": image.height, "mode": image.mode}
            preview: str | None = None
            if include_preview:
                image.thumbnail((1600, 1600))
                rendered = io.BytesIO()
                image.convert("RGB").save(rendered, format="PNG", optimize=True)
                payload = rendered.getvalue()
                if len(payload) <= self.limits.max_image_bytes:
                    preview = "data:image/png;base64," + base64.b64encode(payload).decode("ascii")
        citation = self.cite(
            path,
            locator="full image metadata" + (" and scaled preview" if preview else ""),
            extractor="inspect_image",
            status="complete",
            notes=["Preview omitted because it exceeded the configured byte limit."] if include_preview and not preview else [],
        )
        blocks: list[dict[str, Any]] = [{"type": "text", "text": json.dumps({**metadata, "path": str(path), "evidence_id": citation.evidence_id})}]
        if preview:
            blocks.append({"type": "image_url", "image_url": {"url": preview}})
        return blocks

    def inspect_pdf(self, raw_path: str, pages: list[int], include_preview: bool) -> list[dict[str, Any]]:
        path, _ = self._resolve_allowed(raw_path)
        if path.suffix.lower() != ".pdf":
            raise PolicyError("inspect_pdf only supports PDF files")
        try:
            import fitz  # PyMuPDF
        except ImportError as exc:
            raise PolicyError("PDF inspection requires PyMuPDF; install requirements.txt") from exc
        document = fitz.open(path)
        requested = pages or list(range(1, min(document.page_count, 5) + 1))
        output: list[dict[str, Any]] = []
        citations: list[str] = []
        for page_number in requested:
            if page_number < 1 or page_number > document.page_count:
                raise PolicyError(f"PDF page {page_number} is out of range 1-{document.page_count}")
            page = document.load_page(page_number - 1)
            text = page.get_text("text")
            text_truncated = len(text) > self.limits.max_text_characters
            citation = self.cite(
                path,
                locator=f"page {page_number} of {document.page_count}",
                extractor="inspect_pdf",
                status="partial" if text_truncated else "complete",
                notes=["Page text was truncated."] if text_truncated else [],
            )
            citations.append(citation.evidence_id)
            output.append({"type": "text", "text": json.dumps({"page": page_number, "page_count": document.page_count, "text": text[: self.limits.max_text_characters], "evidence_id": citation.evidence_id})})
            if include_preview:
                pixmap = page.get_pixmap(matrix=fitz.Matrix(1.5, 1.5), alpha=False)
                png = pixmap.tobytes("png")
                if len(png) <= self.limits.max_image_bytes:
                    output.append({"type": "image_url", "image_url": {"url": "data:image/png;base64," + base64.b64encode(png).decode("ascii")}})
        document.close()
        return output

    def inspect_bio(self, raw_path: str, record_limit: int) -> dict[str, Any]:
        if record_limit < 1:
            raise PolicyError("record_limit must be positive")
        path, _ = self._resolve_allowed(raw_path)
        suffix = path.suffix.lower()
        if suffix not in BIO_EXTENSIONS:
            raise PolicyError("inspect_bio supports FASTA/FASTQ, VCF/BCF, BAM, and CRAM files")
        record_limit = min(record_limit, self.limits.max_records)
        if suffix in {".fa", ".fasta", ".fna", ".ffn", ".faa", ".frn", ".fq", ".fastq"}:
            return self._inspect_sequence_file(path, record_limit)
        if suffix in {".vcf", ".bcf"}:
            return self._inspect_variant_file(path, record_limit)
        return self._inspect_alignment_file(path, record_limit)

    def _inspect_sequence_file(self, path: Path, record_limit: int) -> dict[str, Any]:
        try:
            from Bio import SeqIO
        except ImportError as exc:
            raise PolicyError("FASTA/FASTQ inspection requires biopython; install requirements.txt") from exc
        format_name = "fastq" if path.suffix.lower() in {".fq", ".fastq"} else "fasta"
        records = []
        for count, record in enumerate(SeqIO.parse(path, format_name), start=1):
            if count > record_limit:
                break
            item: dict[str, Any] = {"id": record.id, "description": record.description, "length": len(record.seq), "sequence_preview": str(record.seq)[:120]}
            if format_name == "fastq":
                qualities = record.letter_annotations.get("phred_quality", [])
                item["quality_length"] = len(qualities)
                item["quality_preview"] = qualities[:20]
            records.append(item)
        citation = self.cite(path, locator=f"first {len(records)} records", extractor="inspect_bio", status="partial", notes=["Record inspection is sampled."])
        return {"path": str(path), "format": format_name, "sample_records": records, "truncated": True, "evidence_id": citation.evidence_id}

    def _inspect_variant_file(self, path: Path, record_limit: int) -> dict[str, Any]:
        try:
            import pysam
        except ImportError as exc:
            raise PolicyError("VCF/BCF inspection requires pysam; install requirements.txt") from exc
        variants = pysam.VariantFile(path)
        records = []
        for count, record in enumerate(variants, start=1):
            if count > record_limit:
                break
            records.append({"contig": record.contig, "pos": record.pos, "id": record.id, "ref": record.ref, "alts": list(record.alts or []), "qual": record.qual, "filter": list(record.filter.keys()), "info": dict(record.info)})
        header = {"samples": list(variants.header.samples), "contigs": list(variants.header.contigs)[:100], "formats": list(variants.header.formats)[:100], "infos": list(variants.header.info)[:100]}
        variants.close()
        citation = self.cite(path, locator=f"header and first {len(records)} records", extractor="inspect_bio", status="partial", notes=["Variant inspection is sampled."])
        return {"path": str(path), "format": "vcf_or_bcf", "header": header, "sample_records": records, "truncated": True, "evidence_id": citation.evidence_id}

    def _inspect_alignment_file(self, path: Path, record_limit: int) -> dict[str, Any]:
        try:
            import pysam
        except ImportError as exc:
            raise PolicyError("BAM/CRAM inspection requires pysam; install requirements.txt") from exc
        mode = "rb" if path.suffix.lower() == ".bam" else "rc"
        with pysam.AlignmentFile(path, mode) as alignments:
            records = []
            for count, record in enumerate(alignments.fetch(until_eof=True), start=1):
                if count > record_limit:
                    break
                records.append({"query_name": record.query_name, "flag": record.flag, "reference_name": record.reference_name, "reference_start": record.reference_start, "mapping_quality": record.mapping_quality, "cigar": record.cigarstring, "query_length": record.query_length})
            header = alignments.header.to_dict()
        citation = self.cite(path, locator=f"header and first {len(records)} alignment records", extractor="inspect_bio", status="partial", notes=["Alignment inspection is sampled; no index or command execution is used."])
        return {"path": str(path), "format": "bam_or_cram", "header": header, "sample_records": records, "truncated": True, "evidence_id": citation.evidence_id}

    @property
    def records(self) -> list[EvidenceRecord]:
        with self._lock:
            return list(self._records)

    @property
    def valid_evidence_ids(self) -> set[str]:
        with self._lock:
            return {record.evidence_id for record in self._records}

    def was_content_inspected(self, path: Path) -> bool:
        """True when a file was inspected with a content-reading tool."""
        resolved = path.resolve()
        with self._lock:
            return any(record.path == self._relative_path(resolved) for record in self._records)

    def coverage(self) -> dict[str, Any]:
        with self._lock:
            all_paths = set(self._files)
            inspected_paths = {record.path for record in self._records}
            inspected = {path for path in all_paths if self._relative_path(path) in inspected_paths}
            return {
                "files_discovered": len(all_paths),
                "files_inspected": len(inspected),
                "files_not_inspected": [self._relative_path(path) for path in sorted(all_paths - inspected)],
                "partial_evidence_paths": [self._relative_path(path) for path in sorted(self._partial_paths)],
            }
