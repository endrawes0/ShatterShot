extends Node
class_name EncounterManager

const ENCOUNTER_CONFIG_SCRIPT := preload("res://scripts/data/EncounterConfig.gd")
const VARIANT_POLICY_SCRIPT := preload("res://scripts/data/VariantPolicy.gd")

signal encounter_started(config: EncounterConfig)

var bricks_root: Node2D
var brick_scene: PackedScene
var brick_size: Vector2
var brick_gap: Vector2
var top_margin: float
var row_palette: Array[Color] = []

var pattern_registry: PatternRegistry = PatternRegistry.new()
var config_library: Array[EncounterConfig] = []
var normal_variant_policy: VariantPolicy
var elite_variant_policy: VariantPolicy
var boss_variant_policy: VariantPolicy

func _init() -> void:
	normal_variant_policy = VariantPolicy.new()
	elite_variant_policy = VariantPolicy.new()
	elite_variant_policy.shield_chance = 0.2
	elite_variant_policy.regen_chance = 0.18
	elite_variant_policy.curse_chance = 0.12
	boss_variant_policy = VariantPolicy.new()
	boss_variant_policy.shield_chance = 0.4
	boss_variant_policy.regen_chance = 0.35
	boss_variant_policy.curse_chance = 0.25

func load_configs_from_dir(path: String) -> void:
	config_library.clear()
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path := path.path_join(file_name)
			var resource := ResourceLoader.load(resource_path)
			if resource is EncounterConfig:
				config_library.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()

func setup(root: Node2D, scene: PackedScene, size: Vector2, gap: Vector2, margin: float, palette: Array[Color]) -> void:
	bricks_root = root
	brick_scene = scene
	brick_size = size
	brick_gap = gap
	top_margin = margin
	row_palette = palette

func build_config_from_floor(floor_index: int, is_elite: bool, is_boss: bool) -> EncounterConfig:
	var kind := "combat"
	if is_boss:
		kind = "boss"
	elif is_elite:
		kind = "elite"
	var base_config := _select_config(floor_index, kind)
	if base_config == null:
		return _build_fallback_config(floor_index, is_elite, is_boss)
	return _materialize_config(base_config, floor_index, is_elite, is_boss)

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
	for cell in _get_layout_cells(config.rows, config.cols, config.pattern_id):
		var row: int = cell.x
		var col: int = cell.y
		var data := _roll_brick_data(row, config)
		_spawn_brick(row, col, config.rows, config.cols, data.hp_value, data.color, data.variants, on_brick_destroyed, on_brick_damaged)

func _get_layout_cells(rows: int, cols: int, pattern_id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in range(rows):
		for col in range(cols):
			if not pattern_registry.allows(row, col, rows, cols, pattern_id):
				continue
			cells.append(Vector2i(row, col))
	return cells

func _roll_brick_data(row: int, config: EncounterConfig) -> Dictionary:
	var hp_value: int = config.base_hp + int(row / 2.0)
	var policy := config.variant_policy if config.variant_policy != null else normal_variant_policy
	return {
		"hp_value": hp_value,
		"color": _row_color(row),
		"variants": policy.roll_variants()
	}

func _spawn_brick(row: int, col: int, _rows: int, cols: int, hp_value: int, color: Color, data: Dictionary, on_brick_destroyed: Callable, on_brick_damaged: Callable) -> void:
	if bricks_root == null or brick_scene == null:
		return
	var brick: Node = brick_scene.instantiate()
	var total_width: float = cols * brick_size.x + (cols - 1) * brick_gap.x
	var layout_size: Vector2 = _get_layout_size()
	var start_x: float = (layout_size.x - total_width) * 0.5
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

func _get_layout_size() -> Vector2:
	var base: Vector2i = App.get_layout_resolution()
	if base.x > 0 and base.y > 0:
		return Vector2(base)
	if bricks_root:
		return bricks_root.get_viewport_rect().size
	return Vector2.ZERO

func _spawn_boss_core(config: EncounterConfig, on_brick_destroyed: Callable, on_brick_damaged: Callable) -> void:
	var data := _boss_core_data()
	for cell in _get_boss_core_cells(config.rows, config.cols):
		var row: int = cell.x
		var col: int = cell.y
		_spawn_brick(row, col, config.rows, config.cols, config.base_hp + config.boss_core_hp_bonus, data.color, data.variants, on_brick_destroyed, on_brick_damaged)

func _get_boss_core_cells(rows: int, cols: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var center_row: int = int(rows / 2.0)
	var center_col: int = int(cols / 2.0)
	for row in range(center_row - 1, center_row + 1):
		for col in range(center_col - 1, center_col + 1):
			cells.append(Vector2i(row, col))
	return cells

func _boss_core_data() -> Dictionary:
	return {
		"color": Color(0.85, 0.2, 0.2),
		"variants": {
			"shielded_sides": ["left", "right"],
			"regen_on_drop": true,
			"regen_amount": 2,
			"is_cursed": true
		}
	}

func _row_color(row: int) -> Color:
	if row_palette.is_empty():
		return Color(1, 1, 1)
	return row_palette[row % row_palette.size()]

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
	if is_boss:
		return boss_variant_policy.duplicate() as VariantPolicy
	if floor_index >= 3 or is_elite:
		return elite_variant_policy.duplicate() as VariantPolicy
	return normal_variant_policy.duplicate() as VariantPolicy

func _build_fallback_config(floor_index: int, is_elite: bool, is_boss: bool) -> EncounterConfig:
	var config := EncounterConfig.new()
	config.is_boss = is_boss
	config.encounter_kind = "boss" if is_boss else ("elite" if is_elite else "combat")
	config.pattern_id = _pick_pattern(floor_index, is_boss)
	config.speed_boost = _roll_speed_boost(floor_index, is_boss)
	config.variant_policy = _variant_policy_for_floor(floor_index, is_elite, is_boss)
	if is_boss:
		config.rows = 6 + int(floor_index / 2.0)
		config.cols = 10
		config.base_hp = 4 + int(floor_index / 2.0)
		config.base_threat = 0
		config.boss_core = true
	else:
		config.rows = (5 if is_elite else 4) + int(floor_index / 2.0)
		config.cols = 9 if is_elite else 8
		config.base_hp = (2 if is_elite else 1) + int(floor_index / 3.0)
		config.base_threat = 0
	return config

func _select_config(floor_index: int, kind: String) -> EncounterConfig:
	var candidates: Array[EncounterConfig] = []
	for config in config_library:
		if config == null:
			continue
		var config_kind := config.encounter_kind.strip_edges().to_lower()
		if config_kind == "":
			config_kind = "boss" if config.is_boss else "combat"
		if config_kind != kind:
			continue
		if floor_index < config.min_floor or floor_index > config.max_floor:
			continue
		candidates.append(config)
	if candidates.is_empty():
		return null
	return _weighted_pick(candidates)

func _weighted_pick(candidates: Array[EncounterConfig]) -> EncounterConfig:
	var total_weight: int = 0
	for candidate in candidates:
		total_weight += max(1, candidate.weight)
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for candidate in candidates:
		cumulative += max(1, candidate.weight)
		if roll < cumulative:
			return candidate
	return candidates[0]

func _materialize_config(base_config: EncounterConfig, floor_index: int, is_elite: bool, is_boss: bool) -> EncounterConfig:
	var config := EncounterConfig.new()
	config.id = base_config.id
	config.encounter_kind = base_config.encounter_kind
	config.min_floor = base_config.min_floor
	config.max_floor = base_config.max_floor
	config.weight = base_config.weight
	config.rows = base_config.rows
	config.cols = base_config.cols
	config.base_hp = base_config.base_hp
	config.base_threat = base_config.base_threat
	config.pattern_id = base_config.pattern_id
	config.speed_boost_chance = base_config.speed_boost_chance
	config.speed_boost = base_config.speed_boost
	config.is_boss = base_config.is_boss or is_boss
	config.boss_core = base_config.boss_core
	config.boss_core_hp_bonus = base_config.boss_core_hp_bonus
	config.variant_policy = base_config.variant_policy

	if config.pattern_id == "auto":
		config.pattern_id = _pick_pattern(floor_index, config.is_boss)
	if not config.speed_boost:
		config.speed_boost = randf() < config.speed_boost_chance
	if config.variant_policy == null:
		config.variant_policy = _variant_policy_for_floor(floor_index, is_elite, is_boss)
	return config
