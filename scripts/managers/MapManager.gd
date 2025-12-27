extends Node
class_name MapManager

@export var floor_plan: FloorPlan

var current_room_id: String = ""

func reset_run() -> void:
	current_room_id = ""

func build_room_choices(floor_index: int, max_combat_floors: int) -> Array[Dictionary]:
	if floor_plan != null and floor_plan.rooms.size() > 0:
		return _choices_from_floor_plan(floor_index, max_combat_floors)
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

func _choices_from_floor_plan(floor_index: int, max_combat_floors: int) -> Array[Dictionary]:
	if current_room_id == "":
		current_room_id = floor_plan.start_room_id
	var current_room := _find_room(current_room_id)
	if current_room.is_empty():
		return _fallback_choices(floor_index, max_combat_floors)
	var next_ids: Array = current_room.get("next", [])
	if next_ids.is_empty():
		return [{"id": "", "type": "victory"}]
	var choices: Array[Dictionary] = []
	for next_id in next_ids:
		var next_room := _find_room(String(next_id))
		if next_room.is_empty():
			continue
		choices.append({
			"id": String(next_id),
			"type": String(next_room.get("type", "combat"))
		})
	if choices.is_empty():
		return _fallback_choices(floor_index, max_combat_floors)
	return choices

func _fallback_choices(floor_index: int, max_combat_floors: int) -> Array[Dictionary]:
	if floor_index >= max_combat_floors:
		return [{"id": "", "type": "boss"}]
	var pool: Array[String] = ["combat", "combat", "combat", "rest", "shop", "elite"]
	var first_choice: String = pool.pick_random()
	var filtered_pool: Array[String] = []
	for entry in pool:
		if entry != first_choice:
			filtered_pool.append(entry)
	var second_choice: String = first_choice
	if not filtered_pool.is_empty():
		second_choice = filtered_pool.pick_random()
	return [
		{"id": "", "type": first_choice},
		{"id": "", "type": second_choice}
	]

func _find_room(room_id: String) -> Dictionary:
	if floor_plan == null:
		return {}
	for room in floor_plan.rooms:
		if String(room.get("id", "")) == room_id:
			return room
	return {}
