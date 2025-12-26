extends Node
class_name MapManager

@export var floor_plan: FloorPlan

func build_room_choices(floor_index: int, max_combat_floors: int) -> Array[String]:
	if floor_plan != null and floor_plan.rooms.size() > 0:
		return _choices_from_floor_plan(floor_index)
	return _fallback_choices(floor_index, max_combat_floors)

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

func _choices_from_floor_plan(_floor_index: int) -> Array[String]:
	# Placeholder for a room-graph traversal.
	return ["combat", "combat"]

func _fallback_choices(floor_index: int, max_combat_floors: int) -> Array[String]:
	if floor_index >= max_combat_floors:
		return ["boss"]
	var pool: Array[String] = ["combat", "combat", "combat", "rest", "shop", "elite"]
	return [pool.pick_random(), pool.pick_random()]
