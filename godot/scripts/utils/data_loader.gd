extends Node

# Note: this was added as an autoload, do not rename or move file
# If renamed or moved, see Godot Editor → Project → Project Settings → AutoLoad
const PROVINCE_DATA_PATH := "res://data/provinces.json"

func load_provinces_from_json() -> Dictionary:
	var result := {}
	var file := FileAccess.open(PROVINCE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open provinces.json")
		return result

	var text := file.get_as_text()
	var json := JSON.new()

	if json.parse(text) != OK:
		push_error("JSON parse error in provinces.json")
		return result

	return json.get_data()
