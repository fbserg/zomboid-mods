"""A green-looking CLI exit must not turn failed/missing release evidence into a pass."""
from pathlib import Path
import importlib.util
import unittest
import tempfile
import json
import hashlib

import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/pz-test'))

spec=importlib.util.spec_from_file_location('mod_checks',Path(__file__).resolve().parents[1]/'tools/pz-test/check.py')
checks=importlib.util.module_from_spec(spec);spec.loader.exec_module(checks)


class EvidenceTests(unittest.TestCase):
    def test_missing_performance_gate_fails(self):
        gates={name:{'suite':'ok'} for name in checks.REQUIRED if name!='performance'}
        with self.assertRaises(KeyError): checks.validate_gates(gates,{'ok':{}})

    def test_unknown_suite_fails(self):
        gates={name:{'suite':'missing'} for name in checks.REQUIRED}
        with self.assertRaises(AssertionError): checks.validate_gates(gates,{'ok':{}})

    def test_failed_receipt_cannot_pass_even_with_zero_exit(self):
        with self.assertRaises(AssertionError):
            checks.validate_receipt({'suite':'test','outcome':'failed','exit_code':0,'cleanup':True},'test')

    def test_failed_cleanup_cannot_pass(self):
        with self.assertRaises(AssertionError):
            checks.validate_receipt({'suite':'test','outcome':'passed','exit_code':0,'cleanup':False},'test')

    def test_changed_picture_invalidates_visual_review(self):
        with tempfile.TemporaryDirectory() as directory:
            mod=Path(directory);(mod/'workshop').mkdir()
            (mod/'shot.jpg').write_bytes(b'changed image')
            (mod/'workshop/visual-review.json').write_text(json.dumps({'scene':'home','capture_snapshot':'observed','criteria':{'checked':True},'files':{'shot.jpg':hashlib.sha256(b'old image').hexdigest()}}))
            with self.assertRaisesRegex(AssertionError,'Visual asset changed'):
                checks.visual_review(mod)

    def test_real_clean_receipt_passes(self):
        checks.validate_receipt({'suite':'test','outcome':'passed','exit_code':0,'cleanup':True},'test')


if __name__=='__main__': unittest.main()
