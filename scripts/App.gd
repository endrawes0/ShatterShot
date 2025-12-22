extends Node

const MENU_SCENE: PackedScene = preload("res://scenes/MainMenu.tscn")
const RUN_SCENE: PackedScene = preload("res://scenes/Main.tscn")
const HELP_SCENE: PackedScene = preload("res://scenes/Help.tscn")
const GRAPHICS_SCENE: PackedScene = preload("res://scenes/Graphics.tscn")
const TEST_SCENE: PackedScene = preload("res://scenes/TestLab.tscn")
const SETTINGS_PATH: String = "user://settings.cfg"

var menu_instance: Node = null
var run_instance: Node = null
var help_instance: Node = null
var graphics_instance: Node = null
var test_instance: Node = null

func _ready() -> void:
	_apply_saved_graphics()
	var current: Node = get_tree().current_scene
	if current and current.scene_file_path == "res://scenes/MainMenu.tscn":
		menu_instance = current

func has_run() -> bool:
	return run_instance != null and is_instance_valid(run_instance)

func start_new_run() -> void:
	if run_instance and is_instance_valid(run_instance):
		run_instance.queue_free()
	run_instance = RUN_SCENE.instantiate()
	get_tree().root.add_child(run_instance)
	run_instance.process_mode = Node.PROCESS_MODE_INHERIT
	run_instance.visible = true
	if run_instance.has_method("on_menu_closed"):
		run_instance.on_menu_closed()
	if menu_instance and is_instance_valid(menu_instance):
		menu_instance.visible = false
		menu_instance.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().current_scene = run_instance

func continue_run() -> void:
	if not has_run():
		return
	run_instance.visible = true
	run_instance.process_mode = Node.PROCESS_MODE_INHERIT
	if run_instance.has_method("on_menu_closed"):
		run_instance.on_menu_closed()
	if menu_instance and is_instance_valid(menu_instance):
		menu_instance.visible = false
		menu_instance.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().current_scene = run_instance

func show_menu() -> void:
	_ensure_menu()
	if run_instance and is_instance_valid(run_instance):
		if run_instance.has_method("on_menu_opened"):
			run_instance.on_menu_opened()
		run_instance.visible = false
		run_instance.process_mode = Node.PROCESS_MODE_DISABLED
	_hide_aux_scenes()
	menu_instance.visible = true
	menu_instance.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().current_scene = menu_instance

func _ensure_menu() -> void:
	if menu_instance == null or not is_instance_valid(menu_instance):
		menu_instance = MENU_SCENE.instantiate()
		get_tree().root.add_child(menu_instance)

func show_help() -> void:
	_ensure_help()
	_show_aux_scene(help_instance)

func show_graphics() -> void:
	_ensure_graphics()
	_show_aux_scene(graphics_instance)

func show_test_lab() -> void:
	_ensure_test_lab()
	_show_aux_scene(test_instance)

func _show_aux_scene(scene_instance: Node) -> void:
	if run_instance and is_instance_valid(run_instance):
		run_instance.visible = false
		run_instance.process_mode = Node.PROCESS_MODE_DISABLED
	if menu_instance and is_instance_valid(menu_instance):
		menu_instance.visible = false
		menu_instance.process_mode = Node.PROCESS_MODE_DISABLED
	_hide_aux_scenes()
	scene_instance.visible = true
	scene_instance.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().current_scene = scene_instance

func _hide_aux_scenes() -> void:
	for scene_instance in [help_instance, graphics_instance, test_instance]:
		if scene_instance and is_instance_valid(scene_instance):
			scene_instance.visible = false
			scene_instance.process_mode = Node.PROCESS_MODE_DISABLED

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
		get_tree().root.content_scale_size = Vector2(resolution)
