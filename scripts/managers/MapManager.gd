extends Node
class_name MapManager

@export var floor_plan: FloorPlan

var current_room_id: String = ""
var fallback_active: bool = false
var runtime_rooms: Array[Dictionary] = []
var runtime_start_room_id: String = ""
var runtime_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_rng(rng_instance: RandomNumberGenerator) -> void:
	if rng_instance != null:
		rng = rng_instance
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()

func reset_run() -> void:
	current_room_id = ""
	fallback_active = false
	_validate_active_floor_plan()

func set_runtime_floor_plan(plan: Dictionary) -> void:
	runtime_rooms = plan.get("rooms", [])
	runtime_start_room_id = String(plan.get("start_room_id", ""))
	runtime_seed = int(plan.get("seed", 0))
	current_room_id = ""
	fallback_active = false
	_validate_active_floor_plan()

func get_start_room_choice() -> Dictionary:
	var start_id := _active_start_room_id()
	if start_id == "":
		return {}
	var start_room := _find_room(start_id)
	if start_room.is_empty():
		return {}
	return {
		"id": String(start_room.get("id", "")),
		"type": String(start_room.get("type", "combat"))
	}

func build_room_choices(floor_index: int, max_combat_floors: int) -> Array[Dictionary]:
	if _has_active_floor_plan() and not fallback_active:
		return _choices_from_active_plan(floor_index, max_combat_floors)
	return _fallback_choices(floor_index, max_combat_floors)

func advance_to_room(room_id: String) -> void:
	if room_id != "":
		current_room_id = room_id

func room_label(room_type: String) -> String:
	match room_type:
		"combat":
			return "Combat"
		"elite":
			return "Elite"
		"rest":
			return "Rest"
		"shop":
			return "Shop"
		"boss":
			return "Boss"
		"victory":
			return "Victory"
		_:
			return "???"

func get_active_plan_summary() -> Dictionary:
	return {
		"rooms": _active_rooms(),
		"start_room_id": _active_start_room_id(),
		"current_room_id": current_room_id,
		"fallback_active": fallback_active
	}

func _choices_from_active_plan(floor_index: int, max_combat_floors: int) -> Array[Dictionary]:
	if current_room_id == "":
		var start_id := _active_start_room_id()
		if start_id == "":
			return _fallback_choices(floor_index, max_combat_floors)
		var start_room := _find_room(start_id)
		if start_room.is_empty():
			push_warning("Floor plan missing start room id '%s'. Falling back to random choices." % start_id)
			return _fallback_choices(floor_index, max_combat_floors)
		return [{
			"id": String(start_room.get("id", "")),
			"type": String(start_room.get("type", "combat"))
		}]
	var current_room := _find_room(current_room_id)
	if current_room.is_empty():
		push_warning("Floor plan missing room id '%s'. Falling back to random choices." % current_room_id)
		fallback_active = true
		current_room_id = ""
		return _fallback_choices(floor_index, max_combat_floors)
	var next_ids: Array = current_room.get("next", [])
	if next_ids.is_empty():
		return [{"id": "", "type": "victory"}]
	var choices: Array[Dictionary] = []
	for next_id in next_ids:
		var next_room := _find_room(String(next_id))
		if next_room.is_empty():
			push_warning("Floor plan missing next room id '%s' from '%s'." % [String(next_id), current_room_id])
			continue
		choices.append({
			"id": String(next_id),
			"type": String(next_room.get("type", "combat"))
		})
	if choices.is_empty():
		push_warning("Floor plan produced no valid next rooms from '%s'. Falling back to random choices." % current_room_id)
		fallback_active = true
		current_room_id = ""
		return _fallback_choices(floor_index, max_combat_floors)
	return choices

func _fallback_choices(floor_index: int, max_combat_floors: int) -> Array[Dictionary]:
	if floor_index >= max_combat_floors:
		return [{"id": "", "type": "boss"}]
	var pool: Array[String] = ["combat", "combat", "combat", "rest", "shop", "elite"]
	var first_choice: String = _pick_random(pool)
	var filtered_pool: Array[String] = []
	for entry in pool:
		if entry != first_choice:
			filtered_pool.append(entry)
	var second_choice: String = first_choice
	if not filtered_pool.is_empty():
		second_choice = _pick_random(filtered_pool)
	return [
		{"id": "", "type": first_choice},
		{"id": "", "type": second_choice}
	]

func _pick_random(values: Array[String]) -> String:
	if values.is_empty():
		return ""
	var index: int = rng.randi_range(0, values.size() - 1)
	return values[index]

func _find_room(room_id: String) -> Dictionary:
	var rooms := _active_rooms()
	if rooms.is_empty():
		return {}
	for room in rooms:
		if String(room.get("id", "")) == room_id:
			return room
	return {}

func _validate_active_floor_plan() -> void:
	var rooms := _active_rooms()
	if rooms.is_empty():
		return
	var start_room_id := _active_start_room_id()
	if start_room_id == "":
		push_warning("Floor plan start_room_id is empty.")
	var seen: Dictionary = {}
	for room in rooms:
		var room_id := String(room.get("id", ""))
		if room_id == "":
			push_warning("Floor plan contains a room without an id.")
			continue
		if seen.has(room_id):
			push_warning("Floor plan contains duplicate room id '%s'." % room_id)
		seen[room_id] = true
	if start_room_id != "" and not seen.has(start_room_id):
		push_warning("Floor plan start_room_id '%s' not found in rooms." % start_room_id)
	for room in rooms:
		var room_id := String(room.get("id", ""))
		for next_id in room.get("next", []):
			if not seen.has(String(next_id)):
				push_warning("Floor plan room '%s' references missing next id '%s'." % [room_id, String(next_id)])

func _active_rooms() -> Array[Dictionary]:
	if not runtime_rooms.is_empty():
		return runtime_rooms
	if floor_plan != null:
		return floor_plan.rooms
	return []

func _active_start_room_id() -> String:
	if not runtime_rooms.is_empty():
		return runtime_start_room_id
	if floor_plan != null:
		return floor_plan.start_room_id
	return ""

func _has_active_floor_plan() -> bool:
	if not runtime_rooms.is_empty():
		return true
	return floor_plan != null and floor_plan.rooms.size() > 0
