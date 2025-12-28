extends Resource
class_name FloorPlanGeneratorConfig

@export var enabled: bool = true
@export var seed: int = 0
@export var floors: int = 6
@export var min_choices: int = 2
@export var max_choices: int = 2
@export var hidden_edge_chance: float = 0.0
@export var treasure_reward_weights: Dictionary = {}
@export var room_weights: Dictionary = {}
# Acts can override floors/weights/choices per segment.
# Each entry may contain: floors (int), room_weights (Dictionary), min_choices (int), max_choices (int).
@export var acts: Array[Dictionary] = []
