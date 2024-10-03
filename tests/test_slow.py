from packaging2.slow import slow_add
import pytest

@pytest.mark.slow 
def test_slow_add():
    sum_ = slow_add(1, 2)
    assert sum_ == 3