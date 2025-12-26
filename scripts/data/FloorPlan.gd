extends Resource
class_name FloorPlan

# Rooms are dictionaries with keys like: id, type, next (Array[String]).
@export var rooms: Array[Dictionary] = []
@export var start_room_id: String = ""
