extends Node

const MENU_SCENE: PackedScene = preload("res://scenes/MainMenu.tscn")
const RUN_SCENE: PackedScene = preload("res://scenes/Main.tscn")
const HELP_SCENE: PackedScene = preload("res://scenes/Help.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/Settings.tscn")
const SETTINGS_PATH: String = "user://settings.cfg"
const FALLBACK_BASE_RESOLUTION: Vector2i = Vector2i(800, 600)
const UI_SCALE: float = 0.75
const UI_PARTICLE_SCENE: PackedScene = preload("res://scenes/HitParticle.tscn")
const UI_PARTICLE_IGNORE_GROUP: String = "ui_particles_ignore"
const UI_PARTICLE_COUNT: int = 8
const UI_PARTICLE_SPEED_X: Vector2 = Vector2(-120.0, 120.0)
const UI_PARTICLE_SPEED_Y: Vector2 = Vector2(-220.0, -80.0)
const NEUTRAL_BUTTON_NORMAL: Color = Color(0.14, 0.14, 0.16)
const NEUTRAL_BUTTON_HOVER: Color = Color(0.18, 0.18, 0.22)
const NEUTRAL_BUTTON_PRESSED: Color = Color(0.12, 0.12, 0.14)

var menu_instance: Node = null
var run_instance: Node = null
var help_instance: Node = null
var settings_instance: Node = null
var _layout_resolution_cache: Vector2i = Vector2i.ZERO
var _layout_size_cache: Vector2 = Vector2.ZERO
var _global_theme: Theme = null
var _ui_particles_layer: CanvasLayer = null
var _ui_particles_root: Node2D = null
var _ui_particle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _menu_music_restart_after_run: bool = false
var _rest_music_active_until_planning: bool = false
var _settings_window_mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN
var _settings_resolution: Vector2i = Vector2i.ZERO
var _settings_vfx_enabled: bool = true
var _settings_vfx_intensity: float = 1.0
var _settings_ball_speed_multiplier: float = 1.0
var _settings_paddle_speed_multiplier: float = 1.0
var _test_lab_unlocked: bool = false

func _ready() -> void:
	_ui_particle_rng.randomize()
	_ensure_paddle_keyboard_inputs()
	_apply_global_theme()
	_apply_saved_settings()
	_refresh_layout_cache()
	_connect_window_signals()
	start_menu_music()
	var current: Node = get_tree().current_scene
	if current and current.scene_file_path == "res://scenes/MainMenu.tscn":
		menu_instance = current

func _ensure_paddle_keyboard_inputs() -> void:
	_ensure_action_key("ui_left", KEY_A)
	_ensure_action_key("ui_right", KEY_D)

func _ensure_action_key(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if _action_has_key(action, keycode):
		return
	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action, event)

func _action_has_key(action: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).keycode == keycode:
			return true
	return false

func has_run() -> bool:
	return run_instance != null and is_instance_valid(run_instance)

func set_test_lab_unlocked(unlocked: bool) -> void:
	_test_lab_unlocked = unlocked

func is_test_lab_unlocked() -> bool:
	return _test_lab_unlocked

func start_new_run(seed_value: int = 0) -> void:
	_menu_music_restart_after_run = false
	stop_combat_music()
	stop_rest_music()
	if run_instance and is_instance_valid(run_instance):
		run_instance.queue_free()
	run_instance = RUN_SCENE.instantiate()
	if run_instance.has_method("set_pending_seed"):
		run_instance.set_pending_seed(seed_value)
	if run_instance.has_method("set_test_lab_enabled"):
		if _test_lab_unlocked:
			run_instance.set_test_lab_enabled(true, false)
		else:
			run_instance.set_test_lab_enabled(false)
	get_tree().root.add_child(run_instance)
	if run_instance.has_method("on_menu_closed"):
		run_instance.on_menu_closed()
	_switch_to_scene(run_instance)

func continue_run() -> void:
	if not has_run():
		return
	_menu_music_restart_after_run = false
	stop_rest_music()
	if run_instance.has_method("on_menu_closed"):
		run_instance.on_menu_closed()
	_switch_to_scene(run_instance)

func show_menu() -> void:
	_ensure_menu()
	if _menu_music_restart_after_run:
		start_menu_music()
		_menu_music_restart_after_run = false
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
	if run_instance and is_instance_valid(run_instance):
		_show_menu_overlay()
	else:
		_ensure_menu()
		_set_scene_active(menu_instance, true)
	_show_help_overlay()

func show_settings() -> void:
	_ensure_settings()
	if run_instance and is_instance_valid(run_instance):
		_show_menu_overlay()
	else:
		_ensure_menu()
		_set_scene_active(menu_instance, true)
	_show_settings_overlay()

func close_settings() -> void:
	if settings_instance and is_instance_valid(settings_instance):
		_set_scene_active(settings_instance, false)
	if run_instance and is_instance_valid(run_instance):
		_show_menu_overlay()
		return
	_ensure_menu()
	_set_scene_active(menu_instance, true)

func close_help() -> void:
	if help_instance and is_instance_valid(help_instance):
		_set_scene_active(help_instance, false)
	if run_instance and is_instance_valid(run_instance):
		_show_menu_overlay()
		return
	_ensure_menu()
	_set_scene_active(menu_instance, true)

func _show_settings_overlay() -> void:
	if settings_instance == null or not is_instance_valid(settings_instance):
		return
	settings_instance.visible = true
	settings_instance.process_mode = Node.PROCESS_MODE_INHERIT
	if get_tree() and get_tree().root:
		var root: Window = get_tree().root
		root.move_child(settings_instance, root.get_child_count() - 1)

func _show_help_overlay() -> void:
	if help_instance == null or not is_instance_valid(help_instance):
		return
	help_instance.visible = true
	help_instance.process_mode = Node.PROCESS_MODE_INHERIT
	if get_tree() and get_tree().root:
		var root: Window = get_tree().root
		root.move_child(help_instance, root.get_child_count() - 1)

func show_test_lab() -> void:
	_menu_music_restart_after_run = false
	stop_menu_music()
	stop_rest_music()
	if run_instance and is_instance_valid(run_instance):
		run_instance.queue_free()
	run_instance = RUN_SCENE.instantiate()
	get_tree().root.add_child(run_instance)
	if run_instance.has_method("set_test_lab_enabled"):
		run_instance.set_test_lab_enabled(true, true)
	if run_instance.has_method("on_menu_closed"):
		run_instance.on_menu_closed()
	_switch_to_scene(run_instance)

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
	return [menu_instance, run_instance, help_instance, settings_instance]

func _ensure_help() -> void:
	if help_instance == null or not is_instance_valid(help_instance):
		help_instance = HELP_SCENE.instantiate()
		get_tree().root.add_child(help_instance)

func _ensure_settings() -> void:
	if settings_instance == null or not is_instance_valid(settings_instance):
		settings_instance = SETTINGS_SCENE.instantiate()
		get_tree().root.add_child(settings_instance)

func _apply_saved_settings() -> void:
	var config := ConfigFile.new()
	var err: int = config.load(SETTINGS_PATH)
	_settings_window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	_settings_resolution = DisplayServer.screen_get_size()
	var audio_master: float = 1.0
	var audio_music: float = 1.0
	var audio_sfx: float = 1.0
	_settings_vfx_enabled = true
	_settings_vfx_intensity = 1.0
	_settings_ball_speed_multiplier = 1.0
	_settings_paddle_speed_multiplier = 1.0
	if err == OK:
		_settings_window_mode = int(config.get_value("graphics", "window_mode", _settings_window_mode))
		var saved: Vector2i = config.get_value("graphics", "resolution", _settings_resolution)
		if saved.x > 0 and saved.y > 0:
			_settings_resolution = saved
		audio_master = float(config.get_value("audio", "master", audio_master))
		audio_music = float(config.get_value("audio", "music", audio_music))
		audio_sfx = float(config.get_value("audio", "sfx", audio_sfx))
		_settings_vfx_enabled = bool(config.get_value("visual", "vfx_enabled", _settings_vfx_enabled))
		_settings_vfx_intensity = float(config.get_value("visual", "vfx_intensity", _settings_vfx_intensity))
		_settings_ball_speed_multiplier = float(config.get_value("gameplay", "ball_speed_multiplier", _settings_ball_speed_multiplier))
		_settings_paddle_speed_multiplier = float(config.get_value("gameplay", "paddle_speed_multiplier", _settings_paddle_speed_multiplier))
	audio_master = clampf(audio_master, 0.0, 1.0)
	audio_music = clampf(audio_music, 0.0, 1.0)
	audio_sfx = clampf(audio_sfx, 0.0, 1.0)
	_settings_vfx_intensity = clampf(_settings_vfx_intensity, 0.0, 1.0)
	_settings_ball_speed_multiplier = clampf(_settings_ball_speed_multiplier, 0.5, 1.5)
	_settings_paddle_speed_multiplier = clampf(_settings_paddle_speed_multiplier, 0.5, 1.5)
	_audio_call("set_audio_levels", [audio_master, audio_music, audio_sfx])
	_apply_graphics_settings()

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

func bind_button_feedback(root: Node) -> void:
	if root == null:
		return
	_bind_button_feedback_recursive(root)

func _bind_button_feedback_recursive(node: Node) -> void:
	if node is BaseButton:
		_bind_button_feedback(node as BaseButton)
	for child in node.get_children():
		_bind_button_feedback_recursive(child)

func _bind_button_feedback(button: BaseButton) -> void:
	if button.is_in_group(UI_PARTICLE_IGNORE_GROUP):
		return
	if button.has_meta("ui_particles_bound"):
		return
	button.set_meta("ui_particles_bound", true)
	button.pressed.connect(func() -> void:
		var color := _button_particle_color(button)
		var position := _button_particle_position(button)
		_spawn_button_particles(position, color, UI_PARTICLE_COUNT)
	)

func _button_particle_position(button: Control) -> Vector2:
	if button.is_hovered() and button.get_viewport():
		return button.get_viewport().get_mouse_position()
	return button.get_global_rect().get_center()

func _button_particle_color(button: Control) -> Color:
	var color := button.self_modulate
	if color != Color(1, 1, 1, 1):
		return color
	var pressed := button.get_theme_stylebox("pressed", "Button")
	if pressed is StyleBoxFlat:
		return (pressed as StyleBoxFlat).bg_color
	return button.get_theme_color("font_color", "Button")

func _spawn_button_particles(position: Vector2, color: Color, count: int) -> void:
	var scaled_count: int = get_vfx_count(count)
	if scaled_count <= 0:
		return
	_ensure_ui_particles_root()
	if _ui_particles_root == null:
		return
	for _i in range(scaled_count):
		var particle := UI_PARTICLE_SCENE.instantiate()
		if particle == null:
			continue
		_ui_particles_root.add_child(particle)
		if particle is Node2D:
			var node := particle as Node2D
			var jitter := Vector2(
				_ui_particle_rng.randf_range(-6.0, 6.0),
				_ui_particle_rng.randf_range(-6.0, 6.0)
			)
			node.position = position + jitter
		if particle.has_method("setup"):
			var velocity := Vector2(
				_ui_particle_rng.randf_range(UI_PARTICLE_SPEED_X.x, UI_PARTICLE_SPEED_X.y),
				_ui_particle_rng.randf_range(UI_PARTICLE_SPEED_Y.x, UI_PARTICLE_SPEED_Y.y)
			)
			particle.call("setup", color, velocity)

func _ensure_ui_particles_root() -> void:
	if _ui_particles_layer != null and is_instance_valid(_ui_particles_layer):
		return
	if get_tree() == null or get_tree().root == null:
		return
	_ui_particles_layer = CanvasLayer.new()
	_ui_particles_layer.layer = 100
	_ui_particles_root = Node2D.new()
	_ui_particles_layer.add_child(_ui_particles_root)
	get_tree().root.add_child(_ui_particles_layer)

func apply_neutral_button_style(button: BaseButton) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _make_button_box(NEUTRAL_BUTTON_NORMAL))
	button.add_theme_stylebox_override("hover", _make_button_box(NEUTRAL_BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _make_button_box(NEUTRAL_BUTTON_PRESSED))

func apply_neutral_button_style_no_hover(button: BaseButton) -> void:
	if button == null:
		return
	var normal := _make_button_box(NEUTRAL_BUTTON_NORMAL)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", _make_button_box(NEUTRAL_BUTTON_PRESSED))

func _make_button_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.content_margin_left = 10
	box.content_margin_top = 6
	box.content_margin_right = 10
	box.content_margin_bottom = 6
	return box

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

func _apply_graphics_settings() -> void:
	DisplayServer.window_set_mode(_settings_window_mode)
	if _settings_window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
		if _settings_resolution.x > 0 and _settings_resolution.y > 0:
			DisplayServer.window_set_size(_settings_resolution)
	if get_tree() and get_tree().root:
		var root := get_tree().root
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		root.content_scale_size = Vector2(get_layout_resolution())

func notify_run_completed() -> void:
	_menu_music_restart_after_run = true

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("graphics", "window_mode", _settings_window_mode)
	config.set_value("graphics", "resolution", _settings_resolution)
	config.set_value("audio", "master", get_audio_master())
	config.set_value("audio", "music", get_audio_music())
	config.set_value("audio", "sfx", get_audio_sfx())
	config.set_value("visual", "vfx_enabled", _settings_vfx_enabled)
	config.set_value("visual", "vfx_intensity", _settings_vfx_intensity)
	config.set_value("gameplay", "ball_speed_multiplier", _settings_ball_speed_multiplier)
	config.set_value("gameplay", "paddle_speed_multiplier", _settings_paddle_speed_multiplier)
	config.save(SETTINGS_PATH)

func set_graphics_settings(window_mode: int, resolution: Vector2i) -> void:
	_settings_window_mode = window_mode
	if resolution.x > 0 and resolution.y > 0:
		_settings_resolution = resolution
	_apply_graphics_settings()
	_save_settings()

func get_graphics_window_mode() -> int:
	return _settings_window_mode

func get_graphics_resolution() -> Vector2i:
	return _settings_resolution

func set_audio_levels(master: float, music: float, sfx: float) -> void:
	_audio_call("set_audio_levels", [master, music, sfx])
	_save_settings()

func get_audio_master() -> float:
	return _audio_get_float("get_audio_master", 1.0)

func get_audio_music() -> float:
	return _audio_get_float("get_audio_music", 1.0)

func get_audio_sfx() -> float:
	return _audio_get_float("get_audio_sfx", 1.0)

func start_combat_music() -> void:
	_audio_call("start_combat_music")

func stop_combat_music() -> void:
	_audio_call("stop_combat_music")

func start_shop_music() -> void:
	_audio_call("start_shop_music")

func stop_shop_music() -> void:
	_audio_call("stop_shop_music")

func start_rest_music() -> void:
	_rest_music_active_until_planning = true
	_audio_call("start_rest_music")

func stop_rest_music() -> void:
	_rest_music_active_until_planning = false
	_audio_call("stop_rest_music")

func is_rest_music_active() -> bool:
	return _rest_music_active_until_planning

func start_menu_music() -> void:
	_audio_call("start_menu_music")

func stop_menu_music() -> void:
	_audio_call("stop_menu_music")

func play_bounce_sfx(player: AudioStreamPlayer) -> void:
	_audio_call("play_bounce_sfx", [player])

func play_boss_drop_sfx(player: AudioStreamPlayer) -> void:
	_audio_call("play_boss_drop_sfx", [player])

func _audio_node() -> Node:
	return get_node_or_null("/root/Audio")

func _audio_call(method: String, args: Array = []) -> void:
	var audio := _audio_node()
	if audio == null or not audio.has_method(method):
		return
	audio.callv(method, args)

func _audio_get_float(method: String, default_value: float) -> float:
	var audio := _audio_node()
	if audio == null or not audio.has_method(method):
		return default_value
	var value: Variant = audio.call(method)
	return float(value)

func set_vfx_enabled(enabled: bool) -> void:
	_settings_vfx_enabled = enabled
	_save_settings()

func set_vfx_intensity(intensity: float) -> void:
	_settings_vfx_intensity = clampf(intensity, 0.0, 1.0)
	_save_settings()

func get_vfx_enabled() -> bool:
	return _settings_vfx_enabled

func get_vfx_intensity() -> float:
	return _settings_vfx_intensity

func get_vfx_count(base_count: int) -> int:
	if not _settings_vfx_enabled:
		return 0
	return int(round(float(base_count) * _settings_vfx_intensity))

func set_gameplay_speed_settings(ball_multiplier: float, paddle_multiplier: float) -> void:
	_settings_ball_speed_multiplier = clampf(ball_multiplier, 0.5, 1.5)
	_settings_paddle_speed_multiplier = clampf(paddle_multiplier, 0.5, 1.5)
	_save_settings()
	if run_instance and is_instance_valid(run_instance):
		if run_instance.has_method("apply_gameplay_settings"):
			run_instance.apply_gameplay_settings()

func get_ball_speed_multiplier() -> float:
	return _settings_ball_speed_multiplier

func get_paddle_speed_multiplier() -> float:
	return _settings_paddle_speed_multiplier
