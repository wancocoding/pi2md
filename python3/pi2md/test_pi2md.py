import os
import unittest
from pathlib import Path

from pi2md import detect_file, download_image, simple_hash_text


class TestPi2md(unittest.TestCase):
    def test_simple_hash_text(self):
        hash = simple_hash_text("")
        self.assertEqual(len(hash), 32)

    def test_simple_hash_text2(self):
        to_hash = """f:\\Dropbox\\Dropbox\\docs\\md\\notes\\Diary\\2020\\11\\
            78e63c5a-66e1-40d6-adc4-23b4accd219b.jpg"""
        hash = simple_hash_text(to_hash)
        self.assertEqual(len(hash), 32)

    def test_detect_file(self):
        fname = "d:\\test2.txt"
        self.assertEqual(detect_file(fname), 1)
        self.assertEqual(detect_file("d:\\akhsdkasjdhjkashwyqgdqbwd"), 0)

    def test_download_image(self):
        p_path = "f:\\downloads\\temp\\0000.jpg"
        fname = """https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy
            /it/u=2115546205,172279996&fm=11&gp=0.jpg"""
        download_image(fname, p_path)
        fp = Path(p_path)
        self.assertTrue(fp.exists())
        os.remove(p_path)


if __name__ == "__main__":
    unittest.main()
