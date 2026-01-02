extends RefCounted
class_name FloorPlanGenerator

const RESERVED_TYPES: Array[String] = ["boss", "victory", "start"]

func generate(config: FloorPlanGeneratorConfig) -> Dictionary:
	if config == null:
		return {}
	var rng := RandomNumberGenerator.new()
	var seed_value: int = config.seed
	if seed_value == 0:
		seed_value = int(Time.get_unix_time_from_system())
	rng.seed = seed_value

	var plan := {
		"acts": [],
		"seed": seed_value
	}

	var act_defs: Array[Dictionary] = []
	for entry in config.acts:
		var act := Dictionary(entry)
		var floors: int = max(0, int(act.get("floors", 0)))
		if floors <= 0:
			continue
		act_defs.append({
			"floors": floors,
			"room_weights": act.get("room_weights", config.room_weights),
			"min_choices": act.get("min_choices", config.min_choices),
			"max_choices": act.get("max_choices", config.max_choices),
			"hidden_edge_chance": act.get("hidden_edge_chance", config.hidden_edge_chance)
		})
	if act_defs.is_empty():
		act_defs.append({
			"floors": max(1, int(config.floors)),
			"room_weights": config.room_weights,
			"min_choices": config.min_choices,
			"max_choices": config.max_choices,
			"hidden_edge_chance": config.hidden_edge_chance
		})

	for act_index in range(act_defs.size()):
		var act_settings: Dictionary = act_defs[act_index]
		var floors: int = int(act_settings.get("floors", 1))
		var act_prefix := "a%d" % (act_index + 1)
		var rooms: Array[Dictionary] = []
		var room_index: Dictionary = {}

		var start_id := "%s_start" % act_prefix
		var start_room: Dictionary = {"id": start_id, "type": "combat", "next": []}
		rooms.append(start_room)
		room_index[start_id] = 0
		var prev_ids: Array[String] = [start_id]

		for floor in range(floors):
			var weights := _sanitize_weights(Dictionary(act_settings.get("room_weights", config.room_weights)))
			var min_choices: int = max(1, int(act_settings.get("min_choices", config.min_choices)))
			var max_choices: int = max(min_choices, int(act_settings.get("max_choices", config.max_choices)))
			var choice_count: int = rng.randi_range(min_choices, max_choices)

			var floor_ids: Array[String] = []
			for index in range(choice_count):
				var room_type := _pick_weighted(weights, rng)
				var room_id := "%s_f%d_%d" % [act_prefix, floor + 1, index + 1]
				var resolved_type := room_type
				var revealed_type := ""
				if room_type == "mystery":
					revealed_type = _pick_revealed_type(weights, rng)
					resolved_type = "mystery"
				var room: Dictionary = {
					"id": room_id,
					"type": resolved_type,
					"next": []
				}
				if revealed_type != "":
					room["is_mystery"] = true
					room["revealed_type"] = revealed_type
				room_index[room_id] = rooms.size()
				rooms.append(room)
				floor_ids.append(room_id)
			var prev_count: int = prev_ids.size()
			for prev_index in range(prev_count):
				_append_next_adjacent(rooms, room_index, prev_ids[prev_index], prev_index, floor_ids)
			prev_ids = floor_ids

		var boss_id := "%s_boss" % act_prefix
		var boss_room: Dictionary = {"id": boss_id, "type": "boss", "next": []}
		room_index[boss_id] = rooms.size()
		rooms.append(boss_room)
		for prev_id in prev_ids:
			_append_next(rooms, room_index, prev_id, [boss_id])

		# No explicit victory node; final act ends on boss defeat.

		_ensure_forward_edges(rooms, room_index, boss_id)
		_apply_hidden_edges(rooms, room_index, rng, float(act_settings.get("hidden_edge_chance", config.hidden_edge_chance)))

		plan["acts"].append({
			"act_index": act_index,
			"rooms": rooms,
			"start_room_id": start_id,
			"boss_room_id": boss_id
		})
	return plan

func _resolve_floor_count(config: FloorPlanGeneratorConfig) -> int:
	if config.acts.is_empty():
		return max(1, config.floors)
	var total: int = 0
	for act in config.acts:
		total += max(0, int(act.get("floors", 0)))
	return max(1, total if total > 0 else config.floors)

func _act_settings_for_floor(config: FloorPlanGeneratorConfig, floor_index: int) -> Dictionary:
	if config.acts.is_empty():
		return {}
	var cursor: int = 0
	for act in config.acts:
		var act_floors: int = max(0, int(act.get("floors", 0)))
		if act_floors == 0:
			continue
		if floor_index < cursor + act_floors:
			return act
		cursor += act_floors
	return {}

func _sanitize_weights(weights: Dictionary) -> Dictionary:
	var sanitized: Dictionary = {}
	for key in weights.keys():
		var room_type := String(key).strip_edges().to_lower()
		if room_type == "" or RESERVED_TYPES.has(room_type):
			continue
		var weight: int = int(weights[key])
		if weight > 0:
			sanitized[room_type] = weight
	if sanitized.is_empty():
		push_error("Room weights missing or empty in generator config.")
	return sanitized

func _pick_weighted(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var keys: Array = weights.keys()
	keys.sort()
	var total: int = 0
	for key in keys:
		total += int(weights[key])
	if total <= 0:
		return "combat"
	var roll: int = rng.randi_range(1, total)
	var cumulative: int = 0
	for key in keys:
		cumulative += int(weights[key])
		if roll <= cumulative:
			return String(key)
	return "combat"

func _append_next(rooms: Array[Dictionary], room_index: Dictionary, room_id: String, next_ids: Array[String]) -> void:
	if not room_index.has(room_id):
		return
	var index: int = int(room_index[room_id])
	var entry: Dictionary = rooms[index]
	var next_list: Array = entry.get("next", [])
	for next_id in next_ids:
		if not next_list.has(next_id):
			next_list.append(next_id)
	entry["next"] = next_list
	rooms[index] = entry

func _append_next_adjacent(rooms: Array[Dictionary], room_index: Dictionary, room_id: String, room_index_on_floor: int, next_ids: Array[String]) -> void:
	if not room_index.has(room_id):
		return
	var index: int = int(room_index[room_id])
	var entry: Dictionary = rooms[index]
	var next_list: Array = entry.get("next", [])
	for next_index in range(next_ids.size()):
		if abs(next_index - room_index_on_floor) > 1:
			continue
		var next_id: String = next_ids[next_index]
		if not next_list.has(next_id):
			next_list.append(next_id)
	entry["next"] = next_list
	rooms[index] = entry

func _ensure_forward_edges(rooms: Array[Dictionary], room_index: Dictionary, boss_id: String) -> void:
	# Make sure every floor room can advance at least once.
	var floor_map := _build_floor_map(rooms)
	var max_floor: int = int(floor_map.get("max_floor", 0))
	var floors: Dictionary = floor_map.get("floors", {})
	for floor_index in range(1, max_floor + 1):
		var current_ids: Array = floors.get(floor_index, [])
		for room_id in current_ids:
			_ensure_room_forward_edge(rooms, room_index, floors, floor_index, room_id, max_floor, boss_id)

func _ensure_room_forward_edge(
	rooms: Array[Dictionary],
	room_index: Dictionary,
	floors: Dictionary,
	floor_index: int,
	room_id: String,
	max_floor: int,
	boss_id: String
) -> void:
	if not room_index.has(room_id):
		return
	var idx: int = int(room_index[room_id])
	var entry: Dictionary = rooms[idx]
	var next_list: Array = entry.get("next", [])
	if not next_list.is_empty():
		return
	var room_index_on_floor := _parse_room_index(room_id)
	if floor_index == max_floor:
		if room_index.has(boss_id):
			next_list.append(boss_id)
	else:
		var next_floor_ids: Array = floors.get(floor_index + 1, [])
		var target_id := _nearest_room_id_by_index(next_floor_ids, room_index_on_floor)
		if target_id != "":
			next_list.append(target_id)
	if not next_list.is_empty():
		entry["next"] = next_list
		rooms[idx] = entry

func _build_floor_map(rooms: Array[Dictionary]) -> Dictionary:
	var floors: Dictionary = {}
	var max_floor: int = 0
	for room in rooms:
		var room_id := String(room.get("id", ""))
		var floor_index := _parse_floor_index(room_id)
		if floor_index < 0:
			continue
		max_floor = max(max_floor, floor_index)
		if not floors.has(floor_index):
			floors[floor_index] = []
		floors[floor_index].append(room_id)
	return {"floors": floors, "max_floor": max_floor}

func _adjacent_room_id(floor_index: int, room_index_on_floor: int) -> String:
	if floor_index <= 0 or room_index_on_floor <= 0:
		return ""
	return "f%d_%d" % [floor_index, room_index_on_floor]

func _parse_floor_index(room_id: String) -> int:
	var parts := room_id.split("_")
	for part in parts:
		if not String(part).begins_with("f"):
			continue
		var floor_str := String(part).substr(1, String(part).length() - 1)
		if floor_str.is_valid_int():
			return int(floor_str)
	return -1

func _parse_room_index(room_id: String) -> int:
	var parts := room_id.split("_")
	if parts.size() < 2:
		return -1
	var idx_str := String(parts[parts.size() - 1])
	if not idx_str.is_valid_int():
		return -1
	return int(idx_str)

func _nearest_room_id_by_index(room_ids: Array, room_index_on_floor: int) -> String:
	var best_id := ""
	var best_delta: int = 0
	for room_id in room_ids:
		var idx := _parse_room_index(String(room_id))
		if idx <= 0:
			continue
		var delta: int = abs(idx - room_index_on_floor)
		if best_id == "" or delta < best_delta:
			best_id = String(room_id)
			best_delta = delta
	return best_id

func _apply_hidden_edges(rooms: Array[Dictionary], room_index: Dictionary, rng: RandomNumberGenerator, hidden_edge_chance: float) -> void:
	if hidden_edge_chance <= 0.0:
		return
	for i in range(rooms.size()):
		var room: Dictionary = rooms[i]
		var from_id := String(room.get("id", ""))
		if from_id == "":
			continue
		var next_entries: Array = room.get("next", [])
		var next_list: Array[Dictionary] = []
		var visible_count: int = 0
		for entry in next_entries:
			var next_id := ""
			var pre_hidden: bool = false
			if entry is Dictionary:
				next_id = String(entry.get("id", ""))
				pre_hidden = bool(entry.get("hidden", false))
			else:
				next_id = String(entry)
			var next_room_type := ""
			if room_index.has(next_id):
				var next_room: Dictionary = rooms[int(room_index[next_id])]
				next_room_type = String(next_room.get("type", ""))
			var should_hide := pre_hidden or rng.randf() < hidden_edge_chance
			if RESERVED_TYPES.has(next_room_type):
				should_hide = false
			if should_hide:
				next_list.append({"id": next_id, "hidden": true})
			else:
				next_list.append({"id": next_id})
				visible_count += 1
		if visible_count == 0 and not next_list.is_empty():
			next_list[0]["hidden"] = false
		room["next"] = next_list
		rooms[i] = room

func _pick_revealed_type(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var filtered: Dictionary = weights.duplicate()
	filtered.erase("mystery")
	if filtered.is_empty():
		return "combat"
	return _pick_weighted(filtered, rng)
