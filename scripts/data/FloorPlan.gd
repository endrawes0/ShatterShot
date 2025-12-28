extends Resource
class_name FloorPlan

# Rooms are dictionaries with keys like: id, type, next (Array[String|Dictionary]).
# Optional fields: next entries can be { "id": String, "hidden": bool } to hide edges.
@export var rooms: Array[Dictionary] = []
@export var start_room_id: String = ""
