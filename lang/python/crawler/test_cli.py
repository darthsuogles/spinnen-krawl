import unittest2 as unittest


class NumbersTest(unittest.TestCase):
    def test_even(self):
        """
        Test that numbers between 0 and 5 are all even. sdadssdjsuaidhwuiadiwsssssadsadsa
        """
        for i in range(0, 6):
            with self.subTest(i=i): self.assertEqual(i % 2, 0)
