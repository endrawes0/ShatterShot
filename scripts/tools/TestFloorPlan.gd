extends SceneTree

const GENERATOR := preload("res://scripts/data/FloorPlanGenerator.gd")
const CONFIG := preload("res://scripts/data/FloorPlanGeneratorConfig.gd")

func _init() -> void:
	var config := load("res://data/floor_plans/generator_config.tres")
	if not (config is CONFIG):
		push_error("Missing generator config resource.")
		quit(1)
		return
	config.seed = 69
	var generator := GENERATOR.new()
	var plan: Dictionary = generator.generate(config)
	if plan.is_empty():
		push_error("Generator returned empty plan.")
		quit(1)
		return
	var rooms: Array = plan.get("rooms", [])
	_print_plan(rooms)
	_validate_adjacency(rooms)
	quit()

func _print_plan(rooms: Array) -> void:
	print("Seed: 69")
	for room in rooms:
		var room_id := String(room.get("id", ""))
		if room_id == "":
			continue
		var next_entries: Array = room.get("next", [])
		var next_ids: Array[String] = []
		for entry in next_entries:
			if entry is Dictionary:
				next_ids.append(String(entry.get("id", "")))
			else:
				next_ids.append(String(entry))
		print("%s -> %s" % [room_id, ", ".join(next_ids)])

func _validate_adjacency(rooms: Array) -> void:
	var room_index: Dictionary = {}
	for room in rooms:
		var room_id := String(room.get("id", ""))
		if room_id != "":
			room_index[room_id] = room
	var violations: Array[String] = []
	for room in rooms:
		var from_id := String(room.get("id", ""))
		if from_id == "" or not from_id.begins_with("f"):
			continue
		var from_floor := _parse_floor(from_id)
		var from_index := _parse_index(from_id)
		if from_floor < 0 or from_index < 0:
			continue
		var next_entries: Array = room.get("next", [])
		for entry in next_entries:
			var next_id := ""
			if entry is Dictionary:
				next_id = String(entry.get("id", ""))
			else:
				next_id = String(entry)
			if not next_id.begins_with("f"):
				continue
			var next_floor := _parse_floor(next_id)
			var next_index := _parse_index(next_id)
			if next_floor < 0 or next_index < 0:
				continue
			if next_floor != from_floor + 1:
				continue
			if abs(next_index - from_index) > 1:
				violations.append("%s -> %s" % [from_id, next_id])
	if violations.is_empty():
		print("Adjacency check: OK")
	else:
		print("Adjacency violations:")
		for entry in violations:
			print("  %s" % entry)

func _parse_floor(room_id: String) -> int:
	var parts := room_id.split("_")
	if parts.size() != 2:
		return -1
	if not parts[0].begins_with("f"):
		return -1
	var floor_str := parts[0].substr(1, parts[0].length() - 1)
	if not floor_str.is_valid_int():
		return -1
	return int(floor_str)

func _parse_index(room_id: String) -> int:
	var parts := room_id.split("_")
	if parts.size() != 2:
		return -1
	var idx_str := parts[1]
	if not idx_str.is_valid_int():
		return -1
	return int(idx_str)
