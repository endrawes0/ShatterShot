extends Resource
class_name VariantPolicy

@export var shield_chance: float = 0.1
@export var regen_chance: float = 0.1
@export var regen_amount: int = 1
@export var curse_chance: float = 0.08

func roll_variants(rng: RandomNumberGenerator = null) -> Dictionary:
	var active_rng: RandomNumberGenerator = rng
	if active_rng == null:
		active_rng = RandomNumberGenerator.new()
		active_rng.randomize()
	var data: Dictionary = {}
	if active_rng.randf() < shield_chance:
		var sides: Array[String] = ["left", "right", "top", "bottom"]
		_shuffle_array(sides, active_rng)
		data["shielded_sides"] = [sides[0]]
	if active_rng.randf() < regen_chance:
		data["regen_on_drop"] = true
		data["regen_amount"] = regen_amount
	if active_rng.randf() < curse_chance:
		data["is_cursed"] = true
	return data

func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp = values[i]
		values[i] = values[j]
		values[j] = temp
