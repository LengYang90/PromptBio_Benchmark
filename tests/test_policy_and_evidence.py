from __future__ import annotations

import json
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from promptbio_evaluator.evidence import AccessLimits, EvidenceStore
from promptbio_evaluator.policy import PolicyError, load_task, output_pair_manifest, stage_allowed_files
from promptbio_evaluator.runner import _merged_file_manifest


class FixtureMixin:
    def make_task_fixture(self) -> tuple[tempfile.TemporaryDirectory[str], Path, Path]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        task_dir = root / "a-test"
        result_dir = task_dir / "results_agent"
        (task_dir / "ref_answer" / "nested").mkdir(parents=True)
        (task_dir / "ref_script").mkdir()
        (result_dir / "nested").mkdir(parents=True)
        (result_dir / "work").mkdir()
        (task_dir / "task.json").write_text(
            json.dumps(
                {
                    "id": "a-test",
                    "question": "Compare both required outputs as one task.",
                    "expected_output": [
                        {"file": "answer.txt", "type": "txt"},
                        {"file": "nested/table.csv", "type": "csv"},
                    ],
                }
            ),
            encoding="utf-8",
        )
        (task_dir / "ref_answer" / "answer.txt").write_text("reference answer\n", encoding="utf-8")
        (task_dir / "ref_answer" / "nested" / "table.csv").write_text("id,value\nA,1\n", encoding="utf-8")
        (task_dir / "ref_script" / "reference.py").write_text("print('reference')\n", encoding="utf-8")
        (result_dir / "answer.txt").write_text("agent answer\n", encoding="utf-8")
        (result_dir / "nested" / "table.csv").write_text("id,value\nA,2\n", encoding="utf-8")
        (result_dir / "undeclared.txt").write_text("must not be visible\n", encoding="utf-8")
        (result_dir / "log.out").write_text("agent runtime log\n", encoding="utf-8")
        (result_dir / "work" / "command.sh").write_text("echo agent\n", encoding="utf-8")
        return temporary, task_dir, result_dir


class PolicyTests(FixtureMixin, unittest.TestCase):
    def test_initial_allowlist_contains_only_task_and_declared_pairs(self) -> None:
        temporary, task_dir, result_dir = self.make_task_fixture()
        self.addCleanup(temporary.cleanup)
        task = load_task(task_dir)

        actual = {entry.path for entry in stage_allowed_files(task_dir, result_dir, task, "initial_assessment")}
        expected = {
            (task_dir / "task.json").resolve(),
            (task_dir / "ref_answer" / "answer.txt").resolve(),
            (task_dir / "ref_answer" / "nested" / "table.csv").resolve(),
            (result_dir / "answer.txt").resolve(),
            (result_dir / "nested" / "table.csv").resolve(),
        }

        self.assertSetEqual(actual, expected)
        self.assertNotIn((result_dir / "undeclared.txt").resolve(), actual)
        self.assertNotIn((task_dir / "ref_script" / "reference.py").resolve(), actual)
        self.assertNotIn((result_dir / "log.out").resolve(), actual)

    def test_audit_adds_only_permitted_method_and_log_artifacts(self) -> None:
        temporary, task_dir, result_dir = self.make_task_fixture()
        self.addCleanup(temporary.cleanup)
        task = load_task(task_dir)

        actual = {entry.path for entry in stage_allowed_files(task_dir, result_dir, task, "method_and_execution_audit")}
        self.assertIn((task_dir / "ref_script" / "reference.py").resolve(), actual)
        self.assertIn((result_dir / "work" / "command.sh").resolve(), actual)
        self.assertIn((result_dir / "log.out").resolve(), actual)
        self.assertNotIn((result_dir / "undeclared.txt").resolve(), actual)

    def test_declared_path_cannot_escape_output_root(self) -> None:
        temporary, task_dir, result_dir = self.make_task_fixture()
        self.addCleanup(temporary.cleanup)
        payload = json.loads((task_dir / "task.json").read_text(encoding="utf-8"))
        payload["expected_output"] = [{"file": "../ref_script/reference.py"}]
        (task_dir / "task.json").write_text(json.dumps(payload), encoding="utf-8")
        task = load_task(task_dir)

        with self.assertRaises(PolicyError):
            stage_allowed_files(task_dir, result_dir, task, "initial_assessment")
        with self.assertRaises(PolicyError):
            output_pair_manifest(task_dir, result_dir, task)


class EvidenceStoreTests(FixtureMixin, unittest.TestCase):
    @staticmethod
    def _pdb_atom(
        serial: int,
        atom_name: str,
        residue_name: str,
        chain_id: str,
        residue_number: int,
        coordinate: tuple[float, float, float],
        b_factor: float,
    ) -> str:
        x, y, z = coordinate
        element = atom_name.strip()[0]
        return (
            f"ATOM  {serial:5d} {atom_name:^4} {residue_name:>3} {chain_id:1}"
            f"{residue_number:4d}    {x:8.3f}{y:8.3f}{z:8.3f}{1.00:6.2f}{b_factor:6.2f}          {element:>2}\n"
        )

    @classmethod
    def _pdb_for_ca_points(cls, points: list[tuple[float, float, float]]) -> str:
        lines = ["MODEL        1\n"]
        serial = 1
        for residue_number, ca in enumerate(points, start=1):
            residue_name = ("ALA", "GLY", "SER")[residue_number - 1]
            lines.append(cls._pdb_atom(serial, "N", residue_name, "A", residue_number, (ca[0] - 0.2, ca[1], ca[2]), 80.0))
            serial += 1
            lines.append(cls._pdb_atom(serial, "CA", residue_name, "A", residue_number, ca, 80.0 + residue_number))
            serial += 1
            lines.append(cls._pdb_atom(serial, "C", residue_name, "A", residue_number, (ca[0] + 0.2, ca[1], ca[2]), 80.0))
            serial += 1
        lines.extend(["ENDMDL\n", "END\n"])
        return "".join(lines)

    def test_pdb_inspection_and_pairwise_comparison_are_read_only_content_evidence(self) -> None:
        temporary, task_dir, result_dir = self.make_task_fixture()
        self.addCleanup(temporary.cleanup)
        payload = json.loads((task_dir / "task.json").read_text(encoding="utf-8"))
        payload["expected_output"] = [{"file": "rank_001.pdb", "type": "pdb"}]
        (task_dir / "task.json").write_text(json.dumps(payload), encoding="utf-8")
        reference_points = [(0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0)]
        # 90° rotation around z plus translation: raw coordinates differ, but
        # the two structures are identical after rigid superposition.
        agent_points = [(10.0, 5.0, 2.0), (10.0, 6.0, 2.0), (9.0, 5.0, 2.0)]
        (task_dir / "ref_answer" / "rank_001.pdb").write_text(
            self._pdb_for_ca_points(reference_points), encoding="utf-8"
        )
        (result_dir / "rank_001.pdb").write_text(
            self._pdb_for_ca_points(agent_points), encoding="utf-8"
        )
        task = load_task(task_dir)
        store = EvidenceStore(task_dir, result_dir, task, "initial_assessment", AccessLimits())

        inspection = store.inspect_pdb(str(task_dir / "ref_answer" / "rank_001.pdb"), 10)
        comparison = store.compare_pdb_structures(
            str(task_dir / "ref_answer" / "rank_001.pdb"),
            str(result_dir / "rank_001.pdb"),
        )

        self.assertEqual(inspection["chain_count"], 1)
        self.assertEqual(inspection["chains"][0]["sequence_preview"], "AGS")
        self.assertEqual(inspection["complete_backbone_residue_count"], 3)
        self.assertEqual(comparison["chain_mappings"][0]["sequence_identity_fraction"], 1.0)
        self.assertEqual(comparison["overall_ca_pair_count"], 3)
        self.assertAlmostEqual(comparison["overall_ca_rmsd_after_superposition"], 0.0, places=3)
        self.assertEqual(
            [record.evidence_id for record in store.records],
            ["I-0001", "I-0002", "I-0003"],
        )

    def test_star_junction_file_is_readable_as_text(self) -> None:
        temporary, task_dir, result_dir = self.make_task_fixture()
        self.addCleanup(temporary.cleanup)
        payload = json.loads((task_dir / "task.json").read_text(encoding="utf-8"))
        payload["expected_output"] = [{"file": "K562_Chimeric.out.junction", "type": "junction"}]
        (task_dir / "task.json").write_text(json.dumps(payload), encoding="utf-8")
        junction_line = "chr9\t130854100\t-\tchr22\t23290410\t-\n"
        (task_dir / "ref_answer" / "K562_Chimeric.out.junction").write_text(junction_line, encoding="utf-8")
        (result_dir / "K562_Chimeric.out.junction").write_text(junction_line, encoding="utf-8")
        task = load_task(task_dir)
        store = EvidenceStore(task_dir, result_dir, task, "initial_assessment", AccessLimits())

        reference = store.read_text(
            str(task_dir / "ref_answer" / "K562_Chimeric.out.junction"),
            1,
            10,
        )
        agent = store.read_text(
            str(result_dir / "K562_Chimeric.out.junction"),
            1,
            10,
        )

        self.assertEqual(reference["content"], junction_line)
        self.assertEqual(agent["content"], junction_line)
        self.assertEqual([record.evidence_id for record in store.records], ["I-0001", "I-0002"])

    def test_stage_scope_and_evidence_ledger(self) -> None:
        temporary, task_dir, result_dir = self.make_task_fixture()
        self.addCleanup(temporary.cleanup)
        task = load_task(task_dir)
        initial = EvidenceStore(task_dir, result_dir, task, "initial_assessment", AccessLimits(max_text_characters=100))

        initial.allowed_file_manifest()
        initial.metadata(str(result_dir / "answer.txt"))
        self.assertEqual(initial.records, [])

        reference = initial.read_text(str(task_dir / "ref_answer" / "answer.txt"), 1, 10)
        agent = initial.read_text(str(result_dir / "answer.txt"), 1, 10)
        self.assertEqual(reference["content"], "reference answer\n")
        self.assertEqual(agent["content"], "agent answer\n")
        self.assertEqual([record.evidence_id for record in initial.records], ["I-0001", "I-0002"])
        self.assertTrue(initial.was_content_inspected(task_dir / "ref_answer" / "answer.txt"))
        with self.assertRaises(PolicyError):
            initial.read_text(str(task_dir / "ref_script" / "reference.py"), 1, 10)
        with self.assertRaises(PolicyError):
            initial.read_text(str(result_dir / "undeclared.txt"), 1, 10)

        audit = EvidenceStore(task_dir, result_dir, task, "method_and_execution_audit", AccessLimits())
        script = audit.read_text(str(task_dir / "ref_script" / "reference.py"), 1, 10)
        log = audit.read_text(str(result_dir / "log.out"), 1, 10)
        self.assertEqual(script["evidence_id"], "A-0001")
        self.assertEqual(log["evidence_id"], "A-0002")
        with self.assertRaises(PolicyError):
            audit.read_text(str(result_dir / "undeclared.txt"), 1, 10)

    def test_parallel_content_reads_have_unique_sequential_evidence_ids(self) -> None:
        temporary, task_dir, result_dir = self.make_task_fixture()
        self.addCleanup(temporary.cleanup)
        task = load_task(task_dir)
        store = EvidenceStore(task_dir, result_dir, task, "initial_assessment", AccessLimits())
        path = str(result_dir / "answer.txt")

        with ThreadPoolExecutor(max_workers=8) as pool:
            list(pool.map(lambda _: store.read_text(path, 1, 10), range(20)))

        ids = [record.evidence_id for record in store.records]
        self.assertEqual(len(ids), 20)
        self.assertEqual(set(ids), {f"I-{number:04d}" for number in range(1, 21)})

    def test_report_manifest_contains_each_physical_file_once(self) -> None:
        temporary, task_dir, result_dir = self.make_task_fixture()
        self.addCleanup(temporary.cleanup)
        task = load_task(task_dir)
        initial = EvidenceStore(task_dir, result_dir, task, "initial_assessment", AccessLimits())
        audit = EvidenceStore(task_dir, result_dir, task, "method_and_execution_audit", AccessLimits())

        manifest = _merged_file_manifest(initial, audit)
        answer_entries = [entry for entry in manifest if entry.path.endswith("results_agent/answer.txt")]
        self.assertEqual(len(answer_entries), 1)
        self.assertEqual(answer_entries[0].roles, ["agent_output"])
        self.assertEqual(
            answer_entries[0].available_in_stages,
            ["initial_assessment", "method_and_execution_audit"],
        )
