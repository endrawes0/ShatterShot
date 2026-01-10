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
var bricks: Array[Node] = []
var core_clusters: Dictionary = {}

var pattern_registry: PatternRegistry = PatternRegistry.new()
var config_library: Array[EncounterConfig] = []
var normal_variant_policy: VariantPolicy
var elite_variant_policy: VariantPolicy
var boss_variant_policy: VariantPolicy
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_rng(rng_instance: RandomNumberGenerator) -> void:
	if rng_instance != null:
		rng = rng_instance
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()

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
	encounter_started.emit(config)

func get_bricks() -> Array[Node]:
	var valid: Array[Node] = []
	for brick in bricks:
		if is_instance_valid(brick):
			valid.append(brick)
	bricks = valid
	return bricks.duplicate()

func calculate_threat(multiplier: float = 1.0) -> int:
	if bricks.is_empty():
		return 0
	var total: int = 0
	for brick in get_bricks():
		total += brick.get_threat()
	return int(round(float(total) * max(0.0, multiplier)))

func check_victory() -> bool:
	return calculate_threat() <= 0

func regen_bricks_on_drop() -> void:
	for brick in get_bricks():
		if brick.has_method("on_ball_drop"):
			brick.on_ball_drop()

func _build_bricks(config: EncounterConfig, on_brick_destroyed: Callable, on_brick_damaged: Callable) -> void:
	if bricks_root == null:
		return
	for cell in _get_layout_cells(config.rows, config.cols, config.pattern_id):
		var row: int = cell.x
		var col: int = cell.y
		var data := _roll_brick_data(row, config)
		var variants: Dictionary = _apply_cell_variants(row, col, config, data.variants)
		var color: Color = data.color
		if bool(variants.get("is_armor_core", false)):
			color = Color(0.85, 0.2, 0.2)
		_spawn_brick(row, col, config.rows, config.cols, data.hp_value, color, variants, on_brick_destroyed, on_brick_damaged)

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
		"variants": policy.roll_variants(rng)
	}

func _spawn_brick(row: int, col: int, _rows: int, cols: int, hp_value: int, color: Color, data: Dictionary, on_brick_destroyed: Callable, on_brick_damaged: Callable) -> void:
	if bricks_root == null or brick_scene == null:
		return
	var brick: Node = brick_scene.instantiate()
	var total_width: float = cols * brick_size.x + (cols - 1) * brick_gap.x
	var layout_size: Vector2 = App.get_layout_size()
	var start_x: float = (layout_size.x - total_width) * 0.5
	var start_y: float = top_margin
	var x: float = start_x + col * (brick_size.x + brick_gap.x) + brick_size.x * 0.5
	var y: float = start_y + row * (brick_size.y + brick_gap.y) + brick_size.y * 0.5
	if brick is Node2D:
		brick.position = Vector2(x, y)
	brick.add_to_group("bricks")
	bricks_root.add_child(brick)
	_register_brick(brick)
	var cluster_id: int = int(data.get("core_cluster_id", -1))
	if cluster_id >= 0:
		_register_cluster_brick(brick, cluster_id, bool(data.get("is_armor_core", false)))
	if on_brick_destroyed.is_valid():
		brick.destroyed.connect(on_brick_destroyed)
	if on_brick_damaged.is_valid():
		brick.damaged.connect(on_brick_damaged)
	brick.setup(hp_value, color, data)

func _row_color(row: int) -> Color:
	if row_palette.is_empty():
		return Color(1, 1, 1)
	return row_palette[row % row_palette.size()]

func _clear_bricks() -> void:
	if bricks_root == null:
		return
	bricks.clear()
	core_clusters.clear()
	for child in bricks_root.get_children():
		child.queue_free()

func _register_brick(brick: Node) -> void:
	bricks.append(brick)
	if brick.has_signal("destroyed"):
		brick.destroyed.connect(_on_brick_removed)
	if brick.has_signal("core_blocked_hit"):
		brick.core_blocked_hit.connect(_on_core_blocked_hit)

func _on_brick_removed(brick: Node) -> void:
	bricks.erase(brick)
	if brick != null and brick.has_method("get"):
		var cluster_id: int = int(brick.get("core_cluster_id"))
		if cluster_id >= 0:
			_unregister_cluster_brick(brick, cluster_id)

func _pick_pattern(floor_index: int, is_elite: bool, is_boss: bool) -> String:
	if is_boss:
		return "boss_act1"
	if is_elite:
		var elite_patterns: Array[String] = ["elite_ring_pylons", "elite_split_fortress", "elite_pinwheel", "elite_donut"]
		return elite_patterns[floor_index % elite_patterns.size()]
	var patterns: Array[String] = [
		"grid",
		"stagger",
		"pyramid",
		"zigzag",
		"ring",
		"split_lanes",
		"core",
		"criss_cross",
		"hollow_diamond",
		"checker_gate"
	]
	return patterns[floor_index % patterns.size()]

func _roll_speed_boost(floor_index: int, is_boss: bool) -> bool:
	if is_boss:
		return true
	var difficulty: int = max(1, floor_index)
	return rng.randf() < (0.15 + 0.05 * difficulty)

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
	config.pattern_id = _pick_pattern(floor_index, is_elite, is_boss)
	config.speed_boost = _roll_speed_boost(floor_index, is_boss)
	config.variant_policy = _variant_policy_for_floor(floor_index, is_elite, is_boss)
	if is_boss:
		config.rows = 6 + int(floor_index / 2.0)
		config.cols = 10
		config.base_hp = 4 + int(floor_index / 2.0)
		config.boss_core = false
	else:
		config.rows = (5 if is_elite else 4) + int(floor_index / 2.0)
		config.cols = 9
		config.base_hp = (2 if is_elite else 1) + int(floor_index / 3.0)
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
	var roll: int = rng.randi_range(0, total_weight - 1)
	var cumulative: int = 0
	for candidate in candidates:
		cumulative += max(1, candidate.weight)
		if roll < cumulative:
			return candidate
	return candidates[0]

func _materialize_config(base_config: EncounterConfig, floor_index: int, is_elite: bool, is_boss: bool) -> EncounterConfig:
	var config := base_config.duplicate() as EncounterConfig
	if config == null:
		config = EncounterConfig.new()
	config.is_boss = base_config.is_boss or is_boss

	if config.pattern_id == "auto":
		config.pattern_id = _pick_pattern(floor_index, is_elite, config.is_boss)
	if not config.speed_boost:
		config.speed_boost = rng.randf() < config.speed_boost_chance
	if config.variant_policy == null:
		config.variant_policy = _variant_policy_for_floor(floor_index, is_elite, is_boss)
	return config

func _apply_cell_variants(row: int, col: int, config: EncounterConfig, base_variants: Dictionary) -> Dictionary:
	var pattern_id := config.pattern_id
	var variants := base_variants.duplicate()
	if config.is_boss:
		var cluster_id: int = _boss_cluster_id_for_cell(pattern_id, row, col, config.cols)
		if cluster_id >= 0:
			variants["core_cluster_id"] = cluster_id
			var is_core: bool = _is_boss_core_cell(pattern_id, row, col, config.rows, config.cols)
			if is_core:
				variants["is_armor_core"] = true
				variants["core_locked"] = true
	return variants

func _boss_cluster_id_for_cell(pattern_id: String, _row: int, col: int, cols: int) -> int:
	match pattern_id:
		"boss_act1", "boss_act2":
			return 0 if col <= int(cols / 2.0) - 1 else 1
		"boss_act3":
			return 0
	return -1

func _is_boss_core_cell(pattern_id: String, row: int, col: int, rows: int, cols: int) -> bool:
	@warning_ignore("unused_parameter")
	var _unused_rows: int = rows
	@warning_ignore("unused_parameter")
	var _unused_cols: int = cols
	match pattern_id:
		"boss_act1":
			return false
		"boss_act2":
			return row == 3 and col == 3
		"boss_act3":
			return row == 3 and (col == 4 or col == 5)
	return false

func _register_cluster_brick(brick: Node, cluster_id: int, is_core: bool) -> void:
	if not core_clusters.has(cluster_id):
		core_clusters[cluster_id] = {
			"core_bricks": [],
			"member_bricks": []
		}
	var entry: Dictionary = core_clusters[cluster_id]
	var key := "core_bricks" if is_core else "member_bricks"
	var bucket: Array = entry.get(key, [])
	bucket.append(brick)
	entry[key] = bucket
	core_clusters[cluster_id] = entry

func _unregister_cluster_brick(brick: Node, cluster_id: int) -> void:
	if not core_clusters.has(cluster_id):
		return
	var entry: Dictionary = core_clusters[cluster_id]
	var core_bricks: Array = entry.get("core_bricks", [])
	var member_bricks: Array = entry.get("member_bricks", [])
	core_bricks.erase(brick)
	member_bricks.erase(brick)
	entry["core_bricks"] = core_bricks
	entry["member_bricks"] = member_bricks
	core_clusters[cluster_id] = entry
	if _cluster_members_cleared(member_bricks):
		_unlock_cluster_cores(core_bricks)

func _cluster_members_cleared(member_bricks: Array) -> bool:
	for brick in member_bricks:
		if is_instance_valid(brick) and brick.has_method("get") and int(brick.get("hp")) > 0:
			return false
	return true

func _unlock_cluster_cores(core_bricks: Array) -> void:
	for brick in core_bricks:
		if is_instance_valid(brick) and brick.has_method("set_core_locked"):
			brick.set_core_locked(false)

func _on_core_blocked_hit(brick: Node) -> void:
	if brick == null or not brick.has_method("get"):
		return
	var cluster_id: int = int(brick.get("core_cluster_id"))
	if cluster_id < 0 or not core_clusters.has(cluster_id):
		return
	var entry: Dictionary = core_clusters[cluster_id]
	var core_bricks: Array = entry.get("core_bricks", [])
	var member_bricks: Array = entry.get("member_bricks", [])
	if _cluster_members_cleared(member_bricks):
		_unlock_cluster_cores(core_bricks)
		return
	for member in member_bricks:
		if is_instance_valid(member) and member.has_method("restore_to_max"):
			member.restore_to_max()
	for core in core_bricks:
		if is_instance_valid(core) and core.has_method("restore_to_max"):
			core.restore_to_max()

func drop_bricks_one_row() -> void:
	var drop: Vector2 = Vector2(0.0, brick_size.y + brick_gap.y)
	for brick in get_bricks():
		if brick is Node2D:
			brick.position += drop
