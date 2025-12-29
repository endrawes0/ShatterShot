extends Node

const MENU_SCENE: PackedScene = preload("res://scenes/MainMenu.tscn")
const RUN_SCENE: PackedScene = preload("res://scenes/Main.tscn")
const HELP_SCENE: PackedScene = preload("res://scenes/Help.tscn")
const GRAPHICS_SCENE: PackedScene = preload("res://scenes/Graphics.tscn")
const TEST_SCENE: PackedScene = preload("res://scenes/TestLab.tscn")
const SETTINGS_PATH: String = "user://settings.cfg"
const FALLBACK_BASE_RESOLUTION: Vector2i = Vector2i(800, 600)
const UI_SCALE: float = 0.75

var menu_instance: Node = null
var run_instance: Node = null
var help_instance: Node = null
var graphics_instance: Node = null
var test_instance: Node = null
var _layout_resolution_cache: Vector2i = Vector2i.ZERO
var _layout_size_cache: Vector2 = Vector2.ZERO
var _global_theme: Theme = null

func _ready() -> void:
	_apply_global_theme()
	_apply_saved_graphics()
	_refresh_layout_cache()
	_connect_window_signals()
	var current: Node = get_tree().current_scene
	if current and current.scene_file_path == "res://scenes/MainMenu.tscn":
		menu_instance = current

func has_run() -> bool:
	return run_instance != null and is_instance_valid(run_instance)

func start_new_run(seed_value: int = 0) -> void:
	if run_instance and is_instance_valid(run_instance):
		run_instance.queue_free()
	run_instance = RUN_SCENE.instantiate()
	if run_instance.has_method("set_pending_seed"):
		run_instance.set_pending_seed(seed_value)
	get_tree().root.add_child(run_instance)
	if run_instance.has_method("on_menu_closed"):
		run_instance.on_menu_closed()
	_switch_to_scene(run_instance)

func continue_run() -> void:
	if not has_run():
		return
	if run_instance.has_method("on_menu_closed"):
		run_instance.on_menu_closed()
	_switch_to_scene(run_instance)

func show_menu() -> void:
	_ensure_menu()
	if run_instance and is_instance_valid(run_instance):
		if run_instance.has_method("on_menu_opened"):
			run_instance.on_menu_opened()
		_show_menu_overlay()
		return
	_switch_to_scene(menu_instance)

func _ensure_menu() -> void:
	if menu_instance == null or not is_instance_valid(menu_instance):
		menu_instance = MENU_SCENE.instantiate()
		get_tree().root.add_child(menu_instance)

func show_help() -> void:
	_ensure_help()
	_switch_to_scene(help_instance)

func show_graphics() -> void:
	_ensure_graphics()
	_switch_to_scene(graphics_instance)

func show_test_lab() -> void:
	_ensure_test_lab()
	_switch_to_scene(test_instance)

func _switch_to_scene(scene_instance: Node) -> void:
	for instance in _all_scene_instances():
		if instance == null or not is_instance_valid(instance):
			continue
		_set_scene_active(instance, instance == scene_instance)
	if scene_instance and is_instance_valid(scene_instance):
		get_tree().current_scene = scene_instance

func _set_scene_active(scene_instance: Node, active: bool) -> void:
	scene_instance.visible = active
	scene_instance.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func _show_menu_overlay() -> void:
	if menu_instance == null or not is_instance_valid(menu_instance):
		return
	menu_instance.visible = true
	menu_instance.process_mode = Node.PROCESS_MODE_INHERIT
	if run_instance and is_instance_valid(run_instance):
		run_instance.visible = true
		run_instance.process_mode = Node.PROCESS_MODE_DISABLED
	if get_tree() and get_tree().root:
		var root := get_tree().root
		root.move_child(menu_instance, root.get_child_count() - 1)

func _all_scene_instances() -> Array[Node]:
	return [menu_instance, run_instance, help_instance, graphics_instance, test_instance]

func _ensure_help() -> void:
	if help_instance == null or not is_instance_valid(help_instance):
		help_instance = HELP_SCENE.instantiate()
		get_tree().root.add_child(help_instance)

func _ensure_graphics() -> void:
	if graphics_instance == null or not is_instance_valid(graphics_instance):
		graphics_instance = GRAPHICS_SCENE.instantiate()
		get_tree().root.add_child(graphics_instance)

func _ensure_test_lab() -> void:
	if test_instance == null or not is_instance_valid(test_instance):
		test_instance = TEST_SCENE.instantiate()
		get_tree().root.add_child(test_instance)

func _apply_saved_graphics() -> void:
	var config := ConfigFile.new()
	var err: int = config.load(SETTINGS_PATH)
	var window_mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN
	var resolution: Vector2i = DisplayServer.screen_get_size()
	if err == OK:
		window_mode = int(config.get_value("graphics", "window_mode", window_mode))
		var saved: Vector2i = config.get_value("graphics", "resolution", resolution)
		if saved.x > 0 and saved.y > 0:
			resolution = saved
	DisplayServer.window_set_mode(window_mode)
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
		DisplayServer.window_set_size(resolution)
	if get_tree() and get_tree().root:
		var root := get_tree().root
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		root.content_scale_size = Vector2(get_layout_resolution())

func _apply_global_theme() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	var theme_path := String(ProjectSettings.get_setting("gui/theme/custom", ""))
	if theme_path.is_empty():
		return
	var loaded := ResourceLoader.load(theme_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is Theme:
		_global_theme = loaded
		get_tree().root.theme = loaded

func get_global_theme() -> Theme:
	return _global_theme

func get_base_resolution() -> Vector2i:
	var width: int = int(ProjectSettings.get_setting(
		"display/window/size/window_width_override",
		FALLBACK_BASE_RESOLUTION.x
	))
	var height: int = int(ProjectSettings.get_setting(
		"display/window/size/window_height_override",
		FALLBACK_BASE_RESOLUTION.y
	))
	if width <= 0 or height <= 0:
		width = int(ProjectSettings.get_setting(
			"display/window/size/viewport_width",
			FALLBACK_BASE_RESOLUTION.x
		))
		height = int(ProjectSettings.get_setting(
			"display/window/size/viewport_height",
			FALLBACK_BASE_RESOLUTION.y
		))
	if width <= 0 or height <= 0:
		return FALLBACK_BASE_RESOLUTION
	return Vector2i(width, height)

func get_layout_resolution() -> Vector2i:
	if _layout_resolution_cache != Vector2i.ZERO:
		return _layout_resolution_cache
	var base: Vector2i = get_base_resolution()
	var scale: float = max(0.1, UI_SCALE)
	_layout_resolution_cache = Vector2i(int(round(base.x / scale)), int(round(base.y / scale)))
	_layout_size_cache = Vector2(_layout_resolution_cache)
	return _layout_resolution_cache

func get_layout_size() -> Vector2:
	if _layout_size_cache != Vector2.ZERO:
		return _layout_size_cache
	_layout_size_cache = Vector2(get_layout_resolution())
	return _layout_size_cache

func refresh_layout_cache() -> void:
	_layout_resolution_cache = Vector2i.ZERO
	_layout_size_cache = Vector2.ZERO
	_layout_resolution_cache = get_layout_resolution()
	_layout_size_cache = Vector2(_layout_resolution_cache)

func _refresh_layout_cache() -> void:
	refresh_layout_cache()

func _connect_window_signals() -> void:
	if get_tree() and get_tree().root:
		var root := get_tree().root
		if not root.size_changed.is_connected(_refresh_layout_cache):
			root.size_changed.connect(_refresh_layout_cache)
