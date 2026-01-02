extends Node
class_name ActManager

var generator_config: FloorPlanGeneratorConfig
var map_manager: MapManager
var act_config_dir: String = ""
var act_config_script: Script

var act_configs_by_index: Dictionary = {}
var act_floor_lengths: Array[int] = []
var max_combat_floors: int = 0
var max_floors: int = 0

func setup(config: FloorPlanGeneratorConfig, manager: MapManager, config_dir: String, config_script: Script, default_max_combat: int) -> void:
	generator_config = config
	map_manager = manager
	act_config_dir = config_dir
	act_config_script = config_script
	_load_act_configs()
	_configure_act_lengths(default_max_combat)
	_refresh_limits()

func refresh_limits(default_max_combat: int = 0) -> void:
	if default_max_combat > 0:
		_configure_act_lengths(default_max_combat)
	_update_floor_totals()
	_update_active_combat_limit()

func get_max_combat_floors() -> int:
	return max_combat_floors

func get_max_floors() -> int:
	return max_floors

func get_active_act_config() -> Resource:
	var index: int = _active_act_index()
	var act_config: Resource = act_configs_by_index.get(index, null)
	if act_config == null:
		return act_config_script.new() if act_config_script != null else null
	return act_config

func get_intro_text(is_elite: bool, is_boss: bool) -> String:
	var act_config := get_active_act_config()
	if act_config == null:
		return "Boss fight. Plan carefully." if is_boss else "Plan your volley, then launch."
	if is_boss:
		return act_config.boss_intro
	if is_elite:
		return act_config.elite_intro
	return act_config.combat_intro

func get_ball_speed_multiplier() -> float:
	var act_config := get_active_act_config()
	return act_config.ball_speed_multiplier if act_config != null else 1.0

func get_block_threat_multiplier() -> float:
	var act_config := get_active_act_config()
	return act_config.block_threat_multiplier if act_config != null else 1.0

func _load_act_configs() -> void:
	act_configs_by_index.clear()
	if act_config_dir == "" or act_config_script == null:
		return
	var dir := DirAccess.open(act_config_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path: String = act_config_dir.path_join(file_name)
			var resource: Resource = ResourceLoader.load(resource_path)
			if resource != null and resource.get_script() == act_config_script:
				var index: int = max(1, int(resource.act_index))
				act_configs_by_index[index - 1] = resource
		file_name = dir.get_next()
	dir.list_dir_end()

func _configure_act_lengths(default_max_combat: int) -> void:
	act_floor_lengths.clear()
	if generator_config is FloorPlanGeneratorConfig:
		var config := generator_config
		if config.acts.is_empty():
			act_floor_lengths.append(max(1, int(config.floors)))
		else:
			for entry in config.acts:
				var act_dict: Dictionary = Dictionary(entry)
				var floors: int = max(0, int(act_dict.get("floors", 0)))
				if floors > 0:
					act_floor_lengths.append(floors)
	if act_floor_lengths.is_empty():
		var act_count: int = max(1, act_configs_by_index.size())
		var fallback: int = max(1, default_max_combat)
		for _i in range(act_count):
			act_floor_lengths.append(fallback)

func _update_floor_totals() -> void:
	var total_non_boss: int = 0
	for floors in act_floor_lengths:
		total_non_boss += max(1, floors)
	var total_bosses: int = max(1, act_floor_lengths.size())
	max_floors = total_non_boss + total_bosses

func _update_active_combat_limit() -> void:
	if act_floor_lengths.is_empty():
		max_combat_floors = 0
		return
	var act_index: int = _active_act_index()
	act_index = clamp(act_index, 0, act_floor_lengths.size() - 1)
	max_combat_floors = act_floor_lengths[act_index]

func _active_act_index() -> int:
	if map_manager != null and map_manager.has_acts():
		return map_manager.get_active_act_index()
	return 0
