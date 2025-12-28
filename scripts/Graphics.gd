extends Control

@onready var window_mode: OptionButton = $Center/VBox/WindowMode
@onready var resolution: OptionButton = $Center/VBox/Resolution
@onready var back_button: Button = $Center/VBox/BackButton

const MODE_LABELS: Array[String] = ["Windowed", "Fullscreen"]
const SETTINGS_PATH: String = "user://settings.cfg"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(640, 480),
	Vector2i(1024, 576),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(3840, 2160)
]

var resolution_sizes: Array[Vector2i] = []
var display_resolution: Vector2i = Vector2i.ZERO

func _ready() -> void:
	for label in MODE_LABELS:
		window_mode.add_item(label)
	_build_resolution_options()
	window_mode.item_selected.connect(_apply_window_mode)
	resolution.item_selected.connect(_apply_resolution)
	back_button.pressed.connect(_back_to_menu)
	_sync_window_mode()
	_sync_resolution()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		App.show_menu()

func _sync_window_mode() -> void:
	var current: int = DisplayServer.window_get_mode()
	var index: int = 0
	if current == DisplayServer.WINDOW_MODE_FULLSCREEN:
		index = 1
	window_mode.select(index)

func _apply_window_mode(index: int) -> void:
	match index:
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	_apply_content_scale()
	_update_resolution_enabled()
	_save_graphics_settings()

func _apply_resolution(index: int) -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
		_update_resolution_enabled()
	if index < 0 or index >= resolution_sizes.size():
		return
	var size: Vector2i = resolution_sizes[index]
	DisplayServer.window_set_size(size)
	_apply_content_scale()
	_save_graphics_settings()

func _sync_resolution() -> void:
	var current: Vector2i = DisplayServer.window_get_size()
	var index: int = 0
	var found: bool = false
	for i in range(resolution_sizes.size()):
		if resolution_sizes[i] == current:
			index = i
			found = true
			break
	if not found:
		for i in range(resolution_sizes.size()):
			if resolution_sizes[i] == display_resolution:
				index = i
				break
	resolution.select(index)
	_update_resolution_enabled()

func _update_resolution_enabled() -> void:
	var is_fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	resolution.disabled = is_fullscreen

func _back_to_menu() -> void:
	App.show_menu()

func _build_resolution_options() -> void:
	resolution.clear()
	display_resolution = DisplayServer.screen_get_size()
	var items: Array = []
	for size in RESOLUTIONS:
		items.append({"size": size, "label": "%dx%d" % [size.x, size.y]})
	var has_display: bool = false
	for item in items:
		if item["size"] == display_resolution:
			has_display = true
			item["label"] = "%s (Display)" % item["label"]
			break
	if not has_display and display_resolution.x > 0 and display_resolution.y > 0:
		items.append({
			"size": display_resolution,
			"label": "%dx%d (Display)" % [display_resolution.x, display_resolution.y]
		})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var size_a: Vector2i = a["size"]
		var size_b: Vector2i = b["size"]
		if size_a.x == size_b.x:
			return size_a.y < size_b.y
		return size_a.x < size_b.x
	)
	resolution_sizes = []
	for item in items:
		resolution_sizes.append(item["size"])
		resolution.add_item(item["label"])

func _save_graphics_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("graphics", "window_mode", DisplayServer.window_get_mode())
	config.set_value("graphics", "resolution", DisplayServer.window_get_size())
	config.save(SETTINGS_PATH)

func _apply_content_scale() -> void:
	if get_tree() and get_tree().root:
		var root := get_tree().root
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		root.content_scale_size = Vector2(App.get_layout_resolution())
