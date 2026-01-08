extends Node
class_name MapManager

var current_room_id: String = ""
var fallback_active: bool = false
var runtime_rooms: Array[Dictionary] = []
var runtime_start_room_id: String = ""
var runtime_acts: Array[Dictionary] = []
var active_act_index: int = 0
var runtime_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var discovered_rooms: Dictionary = {}
var discovered_edges: Dictionary = {}

func _to_dict_array(source) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if source == null:
		return result
	if typeof(source) != TYPE_ARRAY:
		return result
	for element in source:
		if element is Dictionary:
			result.append(element)
		else:
			result.append(Dictionary(element))
	return result

func set_rng(rng_instance: RandomNumberGenerator) -> void:
	if rng_instance != null:
		rng = rng_instance
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()

func reset_run() -> void:
	current_room_id = ""
	fallback_active = false
	discovered_rooms.clear()
	discovered_edges.clear()
	active_act_index = 0
	_validate_active_floor_plan()

func set_runtime_floor_plan(plan: Dictionary) -> void:
	runtime_acts.clear()
	var acts: Array = plan.get("acts", [])
	for entry in acts:
		if entry is Dictionary:
			runtime_acts.append(entry)
		else:
			runtime_acts.append(Dictionary(entry))
	if runtime_acts.is_empty():
		runtime_rooms = _to_dict_array(plan.get("rooms", []))
		runtime_start_room_id = String(plan.get("start_room_id", ""))
	else:
		runtime_rooms = []
		runtime_start_room_id = ""
		active_act_index = 0
	runtime_seed = int(plan.get("seed_value", plan.get("seed", plan.get("seed_plan", 0))))
	current_room_id = ""
	fallback_active = false
	discovered_rooms.clear()
	discovered_edges.clear()
	_validate_active_floor_plan()

func set_active_act(index: int) -> void:
	var count: int = get_act_count()
	if count <= 0:
		active_act_index = 0
		return
	active_act_index = clamp(index, 0, count - 1)
	current_room_id = ""
	fallback_active = false
	discovered_rooms.clear()
	discovered_edges.clear()
	_validate_active_floor_plan()

func get_active_act_index() -> int:
	return active_act_index

func get_act_count() -> int:
	var acts := _active_acts()
	return acts.size() if not acts.is_empty() else 1

func has_acts() -> bool:
	return not _active_acts().is_empty()

func is_final_act() -> bool:
	return active_act_index >= get_act_count() - 1

func advance_act() -> bool:
	if active_act_index + 1 >= get_act_count():
		return false
	set_active_act(active_act_index + 1)
	return true

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
	if room_id == "":
		return
	var previous_room_id := current_room_id
	current_room_id = room_id
	discovered_rooms[room_id] = true
	if previous_room_id != "":
		discovered_edges[_edge_key(previous_room_id, room_id)] = true

func reveal_current_mystery_room() -> String:
	if current_room_id == "":
		return ""
	var rooms := _active_rooms()
	for i in range(rooms.size()):
		var room: Dictionary = rooms[i]
		if String(room.get("id", "")) != current_room_id:
			continue
		if String(room.get("type", "")) != "mystery":
			return String(room.get("type", "combat"))
		var revealed := String(room.get("revealed_type", "combat"))
		room["type"] = revealed
		room.erase("is_mystery")
		rooms[i] = room
		if not runtime_acts.is_empty():
			var act := runtime_acts[active_act_index]
			act["rooms"] = rooms
			runtime_acts[active_act_index] = act
		elif not runtime_rooms.is_empty():
			runtime_rooms = rooms
		return revealed
	return ""

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
		"treasure":
			return "Treasure"
		"mystery":
			return "Mystery"
		"boss":
			return "Boss"
		"victory":
			return "Victory"
		_:
			return "???"

func get_active_plan_summary() -> Dictionary:
	var visible_graph := _build_visible_graph()
	return {
		"rooms": _active_rooms(),
		"start_room_id": _active_start_room_id(),
		"current_room_id": current_room_id,
		"fallback_active": fallback_active,
		"visible_room_ids": visible_graph.get("room_ids", []),
		"visible_edges": visible_graph.get("edges", []),
		"has_visibility_data": true,
		"active_act_index": active_act_index,
		"act_count": get_act_count()
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
	var next_entries := _resolve_next_entries(current_room)
	if next_entries.is_empty():
		return [{"id": "", "type": "victory"}]
	var choices: Array[Dictionary] = []
	for entry in next_entries:
		var next_id := String(entry.get("id", ""))
		var hidden_edge: bool = bool(entry.get("hidden", false))
		if hidden_edge:
			continue
		var next_room := _find_room(next_id)
		if next_room.is_empty():
			push_warning("Floor plan missing next room id '%s' from '%s'." % [next_id, current_room_id])
			continue
		choices.append({
			"id": next_id,
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
		for entry in _resolve_next_entries(room):
			var next_id := String(entry.get("id", ""))
			if next_id == "":
				continue
			if not seen.has(next_id):
				push_warning("Floor plan room '%s' references missing next id '%s'." % [room_id, next_id])

func _active_rooms() -> Array[Dictionary]:
	var acts := _active_acts()
	if not acts.is_empty():
		if active_act_index >= 0 and active_act_index < acts.size():
			return _to_dict_array(acts[active_act_index].get("rooms", []))
		return []
	if not runtime_rooms.is_empty():
		return runtime_rooms
	return []

func _active_start_room_id() -> String:
	var acts := _active_acts()
	if not acts.is_empty():
		if active_act_index >= 0 and active_act_index < acts.size():
			return String(acts[active_act_index].get("start_room_id", ""))
		return ""
	if not runtime_rooms.is_empty():
		return runtime_start_room_id
	return ""

func _has_active_floor_plan() -> bool:
	var acts := _active_acts()
	if not acts.is_empty():
		return true
	if not runtime_rooms.is_empty():
		return true
	return false

func _active_acts() -> Array[Dictionary]:
	if not runtime_acts.is_empty():
		return runtime_acts
	return []

func _resolve_next_entries(room: Dictionary) -> Array[Dictionary]:
	var entries: Array = room.get("next", [])
	var resolved: Array[Dictionary] = []
	for entry in entries:
		if entry is Dictionary:
			resolved.append({
				"id": String(entry.get("id", "")),
				"hidden": bool(entry.get("hidden", false))
			})
		else:
			resolved.append({
				"id": String(entry),
				"hidden": false
			})
	return resolved

func _build_visible_graph() -> Dictionary:
	var rooms := _active_rooms()
	var start_id := _active_start_room_id()
	var edges: Array[Dictionary] = []
	var outgoing: Dictionary = {}
	for room in rooms:
		var from_id := String(room.get("id", ""))
		if from_id == "":
			continue
		for entry in _resolve_next_entries(room):
			var to_id := String(entry.get("id", ""))
			if to_id == "":
				continue
			var hidden_edge: bool = bool(entry.get("hidden", false))
			if hidden_edge and not discovered_edges.has(_edge_key(from_id, to_id)):
				continue
			edges.append({"from": from_id, "to": to_id})
			if not outgoing.has(from_id):
				outgoing[from_id] = []
			outgoing[from_id].append(to_id)
	var reachable: Dictionary = {}
	var queue: Array[String] = []
	if start_id != "":
		reachable[start_id] = true
		queue.append(start_id)
	while not queue.is_empty():
		var room_id: String = String(queue.pop_front())
		var next_list: Array = outgoing.get(room_id, [])
		for next_id in next_list:
			var next_room_id: String = String(next_id)
			if next_room_id == "" or reachable.has(next_room_id):
				continue
			reachable[next_room_id] = true
			queue.append(next_room_id)
	if current_room_id != "" and not reachable.has(current_room_id):
		reachable[current_room_id] = true
	var room_ids: Array[String] = []
	for room_id in reachable.keys():
		room_ids.append(room_id)
	var filtered_edges: Array[Dictionary] = []
	for edge in edges:
		var from_id := String(edge.get("from", ""))
		var to_id := String(edge.get("to", ""))
		if reachable.has(from_id) and reachable.has(to_id):
			filtered_edges.append(edge)
	return {"room_ids": room_ids, "edges": filtered_edges}

func _edge_key(from_id: String, to_id: String) -> String:
	return "%s|%s" % [from_id, to_id]
