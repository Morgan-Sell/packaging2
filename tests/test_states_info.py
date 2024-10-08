from packaging2.states_info import is_city_capital_of_state
import pytest

@pytest.mark.parametrize(
        argnames="city_name, state, is_capitol",
        argvalues=[
            ("Montgomery", "Alabama", True),
            ("Oklahoma City", "Oklahoma", True),
            ("Salem", "Oregon", True),
            ("Salt Lake City", "Alabama", False)
        ]
)
def test_is_city_capitol_of_state_true_for_correct_city_state_pair(city_name: str, state: str, is_capitol: bool):
    assert is_city_capital_of_state(city_name, state) == is_capitol

