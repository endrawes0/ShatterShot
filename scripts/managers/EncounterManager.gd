extends Node
class_name EncounterManager

signal encounter_started(config: EncounterConfig)
signal encounter_finished(is_boss: bool)

var bricks_root: Node2D
var brick_scene: PackedScene
var brick_size: Vector2
var brick_gap: Vector2
var top_margin: float
var row_palette: Array[Color] = []

var pattern_registry: PatternRegistry = PatternRegistry.new()

func setup(root: Node2D, scene: PackedScene, size: Vector2, gap: Vector2, margin: float, palette: Array[Color]) -> void:
	bricks_root = root
	brick_scene = scene
	brick_size = size
	brick_gap = gap
	top_margin = margin
	row_palette = palette

func build_config_from_floor(floor_index: int, is_elite: bool, is_boss: bool) -> EncounterConfig:
	var config := EncounterConfig.new()
	config.is_boss = is_boss
	config.pattern_id = _pick_pattern(floor_index, is_boss)
	config.speed_boost = _roll_speed_boost(floor_index, is_boss)
	config.variant_policy = _variant_policy_for_floor(floor_index, is_elite, is_boss)
	if is_boss:
		config.rows = 6 + int(floor_index / 2)
		config.cols = 10
		config.base_hp = 4 + int(floor_index / 2)
		config.base_threat = 0
		config.boss_core = true
	else:
		config.rows = (5 if is_elite else 4) + int(floor_index / 2)
		config.cols = 9 if is_elite else 8
		config.base_hp = (2 if is_elite else 1) + int(floor_index / 3)
		config.base_threat = 0
	return config

func start_encounter(config: EncounterConfig, on_brick_destroyed: Callable, on_brick_damaged: Callable) -> void:
	_clear_bricks()
	_build_bricks(config, on_brick_destroyed, on_brick_damaged)
	if config.boss_core:
		_spawn_boss_core(config, on_brick_destroyed, on_brick_damaged)
	encounter_started.emit(config)

func calculate_threat(base_threat: int) -> int:
	if bricks_root == null or bricks_root.get_child_count() == 0:
		return 0
	var total: int = 0
	for brick in bricks_root.get_children():
		if brick.has_method("get_threat"):
			total += brick.get_threat()
	return total + base_threat

func check_victory() -> bool:
	return bricks_root == null or bricks_root.get_child_count() == 0

func regen_bricks_on_drop() -> void:
	if bricks_root == null:
		return
	for brick in bricks_root.get_children():
		if brick.has_method("on_ball_drop"):
			brick.on_ball_drop()

func _build_bricks(config: EncounterConfig, on_brick_destroyed: Callable, on_brick_damaged: Callable) -> void:
	if bricks_root == null:
		return
	for row in range(config.rows):
		for col in range(config.cols):
			if not pattern_registry.allows(row, col, config.rows, config.cols, config.pattern_id):
				continue
			var hp_value: int = config.base_hp + int(row / 2)
			_spawn_brick(row, col, config.rows, config.cols, hp_value, _row_color(row), _roll_variants(config.variant_policy), on_brick_destroyed, on_brick_damaged)

func _spawn_brick(row: int, col: int, rows: int, cols: int, hp_value: int, color: Color, data: Dictionary, on_brick_destroyed: Callable, on_brick_damaged: Callable) -> void:
	if bricks_root == null or brick_scene == null:
		return
	var brick: Node = brick_scene.instantiate()
	var total_width: float = cols * brick_size.x + (cols - 1) * brick_gap.x
	var start_x: float = (bricks_root.get_viewport_rect().size.x - total_width) * 0.5
	var start_y: float = top_margin
	var x: float = start_x + col * (brick_size.x + brick_gap.x) + brick_size.x * 0.5
	var y: float = start_y + row * (brick_size.y + brick_gap.y) + brick_size.y * 0.5
	if brick is Node2D:
		brick.position = Vector2(x, y)
	brick.add_to_group("bricks")
	bricks_root.add_child(brick)
	if on_brick_destroyed.is_valid():
		brick.destroyed.connect(on_brick_destroyed)
	if on_brick_damaged.is_valid():
		brick.damaged.connect(on_brick_damaged)
	brick.setup(hp_value, 1, color, data)

func _spawn_boss_core(config: EncounterConfig, on_brick_destroyed: Callable, on_brick_damaged: Callable) -> void:
	var center_row: int = int(config.rows / 2)
	var center_col: int = int(config.cols / 2)
	for row in range(center_row - 1, center_row + 1):
		for col in range(center_col - 1, center_col + 1):
			var data: Dictionary = {
				"shielded_sides": ["left", "right"],
				"regen_on_drop": true,
				"regen_amount": 2,
				"is_cursed": true
			}
			_spawn_brick(row, col, config.rows, config.cols, config.base_hp + config.boss_core_hp_bonus, Color(0.85, 0.2, 0.2), data, on_brick_destroyed, on_brick_damaged)

func _row_color(row: int) -> Color:
	if row_palette.is_empty():
		return Color(1, 1, 1)
	return row_palette[row % row_palette.size()]

func _roll_variants(policy: VariantPolicy) -> Dictionary:
	var data: Dictionary = {}
	var shield_chance: float = policy.shield_chance if policy != null else 0.1
	var regen_chance: float = policy.regen_chance if policy != null else 0.1
	var curse_chance: float = policy.curse_chance if policy != null else 0.08
	if randf() < shield_chance:
		var sides: Array[String] = ["left", "right", "top", "bottom"]
		sides.shuffle()
		data["shielded_sides"] = [sides[0]]
	if randf() < regen_chance:
		data["regen_on_drop"] = true
		data["regen_amount"] = 1
	if randf() < curse_chance:
		data["is_cursed"] = true
	return data

func _clear_bricks() -> void:
	if bricks_root == null:
		return
	for child in bricks_root.get_children():
		child.queue_free()

func _pick_pattern(floor_index: int, is_boss: bool) -> String:
	if is_boss:
		return "ring"
	var patterns: Array[String] = ["grid", "stagger", "pyramid", "zigzag", "ring"]
	return patterns[floor_index % patterns.size()]

func _roll_speed_boost(floor_index: int, is_boss: bool) -> bool:
	if is_boss:
		return true
	var difficulty: int = max(1, floor_index)
	return randf() < (0.15 + 0.05 * difficulty)

func _variant_policy_for_floor(floor_index: int, is_elite: bool, is_boss: bool) -> VariantPolicy:
	var policy := VariantPolicy.new()
	if is_boss:
		policy.shield_chance = 0.4
		policy.regen_chance = 0.35
		policy.curse_chance = 0.25
	elif floor_index >= 3 or is_elite:
		policy.shield_chance = 0.2
		policy.regen_chance = 0.18
		policy.curse_chance = 0.12
	return policy
