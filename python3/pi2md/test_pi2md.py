import unittest
from pi2md import simple_hash_text, detect_file


class TestPi2md(unittest.TestCase):

    def test_simple_hash_text(self):
        hash = simple_hash_text('')
        self.assertEqual(len(hash), 32)


    def test_detect_file(self):
        fname = 'd:\\test2.txt'
        self.assertEqual(detect_file(fname), 1)
        self.assertEqual(detect_file('d:\\akhsdkasjdhjkashwyqgdqbwd'), 0)
if __name__ == "__main__":
    unittest.main()
