extends Control

const TYPE_COLORS: Dictionary = {
	"combat": Color(0.74, 0.28, 0.28),
	"elite": Color(0.86, 0.52, 0.12),
	"rest": Color(0.26, 0.62, 0.36),
	"shop": Color(0.22, 0.54, 0.84),
	"boss": Color(0.62, 0.22, 0.72),
	"victory": Color(0.9, 0.9, 0.9)
}
const TYPE_LABELS: Dictionary = {
	"combat": "C",
	"elite": "E",
	"rest": "R",
	"shop": "S",
	"boss": "B",
	"victory": "V"
}

var rooms: Array[Dictionary] = []
var start_room_id: String = ""
var current_room_id: String = ""
var choice_ids: Array[String] = []
var fallback_active: bool = false

func set_plan(plan: Dictionary, choices: Array[Dictionary]) -> void:
	rooms = plan.get("rooms", [])
	start_room_id = String(plan.get("start_room_id", ""))
	current_room_id = String(plan.get("current_room_id", ""))
	fallback_active = bool(plan.get("fallback_active", false))
	choice_ids = []
	for choice in choices:
		choice_ids.append(String(choice.get("id", "")))
	queue_redraw()

func _draw() -> void:
	if rooms.is_empty() or fallback_active:
		_draw_placeholder()
		return
	var room_index := _build_room_index()
	if start_room_id == "" or not room_index.has(start_room_id):
		_draw_placeholder()
		return
	var depths := _build_depths(room_index)
	var positions := _layout_positions(room_index, depths)
	_draw_edges(room_index, positions)
	_draw_nodes(room_index, positions)

func _draw_placeholder() -> void:
	var font: Font = get_theme_default_font()
	var text: String = "Map unavailable"
	var size: Vector2 = get_size()
	var text_size: Vector2 = font.get_string_size(text)
	var pos: Vector2 = Vector2((size.x - text_size.x) * 0.5, (size.y + text_size.y) * 0.5)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))

func _build_room_index() -> Dictionary:
	var index: Dictionary = {}
	for room in rooms:
		var room_id := String(room.get("id", ""))
		if room_id != "":
			index[room_id] = room
	return index

func _build_depths(room_index: Dictionary) -> Dictionary:
	var depths: Dictionary = {}
	var queue: Array[String] = []
	depths[start_room_id] = 0
	queue.append(start_room_id)
	while not queue.is_empty():
		var room_id: String = queue.pop_front()
		var room: Dictionary = room_index.get(room_id, {})
		var next_ids: Array = room.get("next", [])
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

func _layout_positions(room_index: Dictionary, depths: Dictionary) -> Dictionary:
	var depth_groups: Dictionary = {}
	var max_depth: int = 0
	for room in rooms:
		var room_id := String(room.get("id", ""))
		if room_id == "":
			continue
		var depth: int = int(depths.get(room_id, 0))
		max_depth = max(max_depth, depth)
		if not depth_groups.has(depth):
			depth_groups[depth] = []
		depth_groups[depth].append(room_id)
	var size: Vector2 = get_size()
	var margin: float = 16.0
	var usable_height: float = max(1.0, size.y - margin * 2.0)
	var depth_count: int = max(1, max_depth + 1)
	var row_spacing: float = 0.0
	if depth_count > 1:
		row_spacing = usable_height / float(depth_count - 1)
	var positions: Dictionary = {}
	for depth_key in depth_groups.keys():
		var depth: int = int(depth_key)
		var rooms_at_depth: Array = depth_groups[depth]
		var count: int = rooms_at_depth.size()
		var usable_width: float = max(1.0, size.x - margin * 2.0)
		var col_spacing: float = 0.0
		if count > 1:
			col_spacing = usable_width / float(count - 1)
		for i in range(count):
			var x: float = margin + (col_spacing * float(i) if count > 1 else usable_width * 0.5)
			var y: float = size.y - margin - row_spacing * float(depth)
			positions[rooms_at_depth[i]] = Vector2(x, y)
	return positions

func _draw_edges(room_index: Dictionary, positions: Dictionary) -> void:
	var base_color: Color = Color(0.55, 0.55, 0.6)
	for room_id in room_index.keys():
		var room: Dictionary = room_index[room_id]
		var from_pos: Vector2 = positions.get(room_id, Vector2.ZERO)
		for next_id in room.get("next", []):
			var next_room_id := String(next_id)
			if not positions.has(next_room_id):
				continue
			var to_pos: Vector2 = positions[next_room_id]
			var edge_color: Color = base_color
			if next_room_id in choice_ids or room_id == current_room_id:
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
		var text_size: Vector2 = font.get_string_size(label)
		var text_pos: Vector2 = pos + Vector2(-text_size.x * 0.5, text_size.y * 0.35)
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.1, 0.1, 0.1))

func _node_radius() -> float:
	var size: Vector2 = get_size()
	return clamp(min(size.x, size.y) * 0.045, 8.0, 14.0)
