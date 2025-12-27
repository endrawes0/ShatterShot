extends Resource
class_name VariantPolicy

@export var shield_chance: float = 0.1
@export var regen_chance: float = 0.1
@export var regen_amount: int = 1
@export var curse_chance: float = 0.08

func roll_variants() -> Dictionary:
	var data: Dictionary = {}
	if randf() < shield_chance:
		var sides: Array[String] = ["left", "right", "top", "bottom"]
		sides.shuffle()
		data["shielded_sides"] = [sides[0]]
	if randf() < regen_chance:
		data["regen_on_drop"] = true
		data["regen_amount"] = regen_amount
	if randf() < curse_chance:
		data["is_cursed"] = true
	return data
