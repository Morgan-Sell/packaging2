import json
from pathlib import Path
from typing import (
    Dict,
    List,
)

THIS_DIR = Path(__file__).parent
CITIES_JSON_FPATH = THIS_DIR / "./my_folder/cities.json"

def is_city_capital_of_state(city_name: str, state:str) -> bool:
    cities_json_contents = CITIES_JSON_FPATH.read_text()
    cities: List[dict] = json.loads(cities_json_contents)
    matching_cities: List[dict] = [city for city in cities if city["city"] == city_name]
    if len(matching_cities) == 0:
        return False
    matched_city = matching_cities[0]
    return matched_city["state"] == state

if __name__ == "__main__":
    is_capital = is_city_capital_of_state(city_name="Provo", state="Alabama")
    print(is_capital)
