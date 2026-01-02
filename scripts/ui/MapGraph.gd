extends Control

const TYPE_COLORS: Dictionary = {
	"combat": Color(0.74, 0.28, 0.28),
	"elite": Color(0.86, 0.52, 0.12),
	"rest": Color(0.26, 0.62, 0.36),
	"shop": Color(0.22, 0.54, 0.84),
	"treasure": Color(0.9, 0.78, 0.2),
	"mystery": Color(0.65, 0.65, 0.7),
	"boss": Color(0.62, 0.22, 0.72),
	"victory": Color(0.9, 0.9, 0.9)
}
const TYPE_LABELS: Dictionary = {
	"combat": "💀",
	"elite": "☠️",
	"rest": "⛺",
	"shop": "💰",
	"treasure": "💎",
	"mystery": "❓",
	"boss": "👹",
	"victory": "V"
}
const TYPE_NAMES: Dictionary = {
	"combat": "Combat",
	"elite": "Elite",
	"rest": "Rest",
	"shop": "Shop",
	"treasure": "Treasure",
	"mystery": "Mystery",
	"boss": "Boss",
	"victory": "Victory"
}

var rooms: Array[Dictionary] = []
var start_room_id: String = ""
var current_room_id: String = ""
var choice_ids: Array[String] = []
var fallback_active: bool = false
var visible_room_ids: Dictionary = {}
var visible_edges: Array[Dictionary] = []
var has_visibility_data: bool = false
var visible_outgoing: Dictionary = {}
var node_positions: Dictionary = {}

func set_plan(plan: Dictionary, choices: Array[Dictionary]) -> void:
	rooms = plan.get("rooms", [])
	start_room_id = String(plan.get("start_room_id", ""))
	current_room_id = String(plan.get("current_room_id", ""))
	fallback_active = bool(plan.get("fallback_active", false))
	visible_room_ids = _array_to_set(plan.get("visible_room_ids", []))
	visible_edges = plan.get("visible_edges", [])
	has_visibility_data = bool(plan.get("has_visibility_data", false))
	visible_outgoing = _build_outgoing_edges(visible_edges)
	choice_ids = []
	for choice in choices:
		choice_ids.append(String(choice.get("id", "")))
	queue_redraw()

func _draw() -> void:
	if rooms.is_empty() or fallback_active:
		_draw_placeholder()
		return
	var rooms_to_draw: Array[Dictionary] = rooms
	if has_visibility_data and not visible_room_ids.is_empty():
		rooms_to_draw = _filter_visible_rooms(rooms)
	var room_index := _build_room_index(rooms_to_draw)
	if start_room_id == "" or not room_index.has(start_room_id):
		_draw_placeholder()
		return
	var depths := _build_depths(room_index, rooms_to_draw)
	var positions := _layout_positions(room_index, depths, rooms_to_draw)
	node_positions = positions
	_draw_edges(room_index, positions)
	_draw_nodes(room_index, positions)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_tooltip(event.position)

func _update_tooltip(mouse_pos: Vector2) -> void:
	var radius := _node_radius()
	var hover_room_id := ""
	var closest_dist := radius
	for room_id in node_positions.keys():
		var pos: Vector2 = node_positions[room_id]
		var dist := pos.distance_to(mouse_pos)
		if dist <= closest_dist:
			closest_dist = dist
			hover_room_id = String(room_id)
	if hover_room_id == "":
		tooltip_text = ""
		return
	var room_type := _room_type_for_id(hover_room_id)
	var name := String(TYPE_NAMES.get(room_type, "Unknown"))
	tooltip_text = "%s" % name

func _room_type_for_id(room_id: String) -> String:
	for room in rooms:
		if String(room.get("id", "")) == room_id:
			return String(room.get("type", "combat"))
	return "combat"

func _draw_placeholder() -> void:
	var font: Font = get_theme_default_font()
	var text: String = "Map unavailable"
	var size: Vector2 = get_size()
	var text_size: Vector2 = font.get_string_size(text)
	var pos: Vector2 = Vector2((size.x - text_size.x) * 0.5, (size.y + text_size.y) * 0.5)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))

func _build_room_index(source_rooms: Array[Dictionary]) -> Dictionary:
	var index: Dictionary = {}
	for room in source_rooms:
		var room_id := String(room.get("id", ""))
		if room_id != "":
			index[room_id] = room
	return index

func _build_depths(room_index: Dictionary, source_rooms: Array[Dictionary]) -> Dictionary:
	var depths: Dictionary = {}
	var queue: Array[String] = []
	depths[start_room_id] = 0
	queue.append(start_room_id)
	while not queue.is_empty():
		var room_id: String = queue.pop_front()
		var next_ids: Array = []
		if has_visibility_data and not visible_outgoing.is_empty():
			next_ids = visible_outgoing.get(room_id, [])
		else:
			var room: Dictionary = room_index.get(room_id, {})
			next_ids = _resolve_next_ids(room)
		for next_id in next_ids:
			var next_room_id := String(next_id)
			if not room_index.has(next_room_id):
				continue
			if not depths.has(next_room_id):
				depths[next_room_id] = int(depths[room_id]) + 1
				queue.append(next_room_id)
	var max_depth: int = 0
	for value in depths.values():
		max_depth = max(max_depth, int(value))
	for room_id in room_index.keys():
		if not depths.has(room_id):
			max_depth += 1
			depths[room_id] = max_depth
	return depths

func _layout_positions(room_index: Dictionary, depths: Dictionary, source_rooms: Array[Dictionary]) -> Dictionary:
	var depth_groups: Dictionary = {}
	var max_depth: int = 0
	var global_max_index: int = 0
	for room in source_rooms:
		var room_id := String(room.get("id", ""))
		if room_id == "":
			continue
		var room_index_value := _room_floor_index(room_id)
		global_max_index = max(global_max_index, room_index_value)
		var depth: int = int(depths.get(room_id, 0))
		max_depth = max(max_depth, depth)
		if not depth_groups.has(depth):
			depth_groups[depth] = []
		depth_groups[depth].append(room_id)
	var size: Vector2 = get_size()
	var margin: float = 6.0
	var usable_height: float = max(1.0, size.y - margin * 2.0)
	var depth_count: int = max(1, max_depth + 1)
	var row_spacing: float = 0.0
	if depth_count > 1:
		row_spacing = usable_height / float(depth_count - 1)
	var positions: Dictionary = {}
	for depth_key in depth_groups.keys():
		var depth: int = int(depth_key)
		var rooms_at_depth: Array = depth_groups[depth]
		var usable_width: float = max(1.0, size.x - margin * 2.0)
		var radius: float = _node_radius()
		var ordered_rooms := _order_room_ids(rooms_at_depth)
		var center_x: float = usable_width * 0.5 + margin
		var max_slots: int = max(1, global_max_index)
		var col_spacing: float = usable_width / float(max(1, max_slots - 1))
		var row_count: int = ordered_rooms.size()
		var row_width: float = col_spacing * float(max(0, row_count - 1))
		var start_x: float = center_x - row_width * 0.5
		for i in range(row_count):
			var room_id := String(ordered_rooms[i])
			var x: float = start_x + col_spacing * float(i)
			if room_id in ["start", "boss", "victory"]:
				x = center_x
			else:
				x = clamp(x, margin + radius, margin + usable_width - radius)
			var y: float = size.y - margin - row_spacing * float(depth)
			positions[room_id] = Vector2(x, y)
	return positions

func _draw_edges(room_index: Dictionary, positions: Dictionary) -> void:
	var base_color: Color = Color(0.55, 0.55, 0.6)
	var edges: Array[Dictionary] = visible_edges
	if edges.is_empty() and not has_visibility_data:
		for room_id in room_index.keys():
			var room: Dictionary = room_index[room_id]
			var from_pos: Vector2 = positions.get(room_id, Vector2.ZERO)
			for next_room_id in _resolve_next_ids(room):
				if not positions.has(next_room_id):
					continue
				var to_pos: Vector2 = positions[next_room_id]
				var edge_color: Color = base_color
				if room_id == current_room_id and next_room_id in choice_ids:
					edge_color = Color(0.9, 0.9, 0.95)
				draw_line(from_pos, to_pos, edge_color, 2.0)
		return
	for edge in edges:
		var from_id := String(edge.get("from", ""))
		var to_id := String(edge.get("to", ""))
		if not positions.has(from_id) or not positions.has(to_id):
			continue
		var from_pos: Vector2 = positions[from_id]
		var to_pos: Vector2 = positions[to_id]
		var edge_color: Color = base_color
		if from_id == current_room_id and to_id in choice_ids:
			edge_color = Color(0.9, 0.9, 0.95)
		draw_line(from_pos, to_pos, edge_color, 2.0)

func _draw_nodes(room_index: Dictionary, positions: Dictionary) -> void:
	var font: Font = get_theme_default_font()
	var radius: float = _node_radius()
	for room_id in positions.keys():
		var room: Dictionary = room_index.get(room_id, {})
		var room_type := String(room.get("type", "combat"))
		var pos: Vector2 = positions[room_id]
		var color: Color = TYPE_COLORS.get(room_type, Color(0.8, 0.8, 0.8))
		draw_circle(pos, radius, color)
		if room_id == start_room_id:
			draw_arc(pos, radius + 2.0, 0.0, TAU, 48, Color(1, 1, 1), 2.0)
		if room_id == current_room_id:
			draw_arc(pos, radius + 4.0, 0.0, TAU, 48, Color(0.2, 0.9, 1.0), 2.0)
		if room_id in choice_ids:
			draw_arc(pos, radius + 6.0, 0.0, TAU, 48, Color(0.95, 0.85, 0.2), 2.0)
		var label: String = String(TYPE_LABELS.get(room_type, "?"))
		var font_size: int = 18
		if room_type in ["elite", "rest", "shop", "boss"]:
			font_size = int(round(float(font_size) * 1.3))
		var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var ascent: float = font.get_ascent(font_size)
		var descent: float = font.get_descent(font_size)
		var text_pos: Vector2 = Vector2(
			pos.x - text_size.x * 0.5,
			pos.y + (ascent - descent) * 0.5
		)
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.1, 0.1, 0.1))

func _node_radius() -> float:
	var size: Vector2 = get_size()
	return clamp(min(size.x, size.y) * 0.045, 10.0, 18.0)

func _resolve_next_ids(room: Dictionary) -> Array[String]:
	var resolved: Array[String] = []
	var entries: Array = room.get("next", [])
	for entry in entries:
		if entry is Dictionary:
			resolved.append(String(entry.get("id", "")))
		else:
			resolved.append(String(entry))
	return resolved

func _array_to_set(values: Array) -> Dictionary:
	var set: Dictionary = {}
	for value in values:
		var key := String(value)
		if key != "":
			set[key] = true
	return set

func _room_visible(room_id: String) -> bool:
	if visible_room_ids.is_empty():
		return true
	return visible_room_ids.has(room_id)

func _filter_visible_rooms(source_rooms: Array[Dictionary]) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for room in source_rooms:
		var room_id := String(room.get("id", ""))
		if room_id == "":
			continue
		if _room_visible(room_id):
			filtered.append(room)
	return filtered

func _build_outgoing_edges(edges: Array[Dictionary]) -> Dictionary:
	var outgoing: Dictionary = {}
	for edge in edges:
		var from_id := String(edge.get("from", ""))
		var to_id := String(edge.get("to", ""))
		if from_id == "" or to_id == "":
			continue
		if not outgoing.has(from_id):
			outgoing[from_id] = []
		outgoing[from_id].append(to_id)
	return outgoing

func _order_room_ids(room_ids: Array) -> Array:
	# NOTE: This ordering assumes "f<floor>_<index>" room ids; other schemes will fall back to sort-by-id.
	var indexed: Array[Dictionary] = []
	var fallback: Array[String] = []
	for room_id in room_ids:
		var key := String(room_id)
		var index := _room_floor_index(key)
		if index > 0:
			indexed.append({"id": key, "index": index})
		else:
			fallback.append(key)
	indexed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_index: int = int(a.get("index", 0))
		var b_index: int = int(b.get("index", 0))
		if a_index == b_index:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return a_index < b_index
	)
	fallback.sort()
	var ordered: Array[String] = []
	for entry in indexed:
		ordered.append(String(entry.get("id", "")))
	for entry in fallback:
		if not ordered.has(entry):
			ordered.append(entry)
	return ordered

func _room_floor_index(room_id: String) -> int:
	if room_id.begins_with("f"):
		var parts := room_id.split("_")
		if parts.size() == 2:
			var idx_str := parts[1]
			if idx_str.is_valid_int():
				return int(idx_str)
	return -1
