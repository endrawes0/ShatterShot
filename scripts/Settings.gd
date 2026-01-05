extends Control

@onready var window_mode: OptionButton = $Center/VBox/Tabs/Visual/WindowMode
@onready var resolution: OptionButton = $Center/VBox/Tabs/Visual/Resolution
@onready var vfx_toggle: CheckBox = $Center/VBox/Tabs/Visual/VfxToggle
@onready var vfx_intensity: HSlider = $Center/VBox/Tabs/Visual/VfxIntensity
@onready var master_slider: HSlider = $Center/VBox/Tabs/Audio/MasterSlider
@onready var music_slider: HSlider = $Center/VBox/Tabs/Audio/MusicSlider
@onready var sfx_slider: HSlider = $Center/VBox/Tabs/Audio/SfxSlider
@onready var ball_speed_slider: HSlider = $Center/VBox/Tabs/Gameplay/BallSpeedSlider
@onready var paddle_speed_slider: HSlider = $Center/VBox/Tabs/Gameplay/PaddleSpeedSlider
@onready var back_button: Button = $Center/VBox/BackButton

const MODE_LABELS: Array[String] = ["Windowed", "Fullscreen"]
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
	vfx_toggle.toggled.connect(_apply_vfx_toggle)
	vfx_intensity.value_changed.connect(_apply_vfx_intensity)
	master_slider.value_changed.connect(_apply_audio)
	music_slider.value_changed.connect(_apply_audio)
	sfx_slider.value_changed.connect(_apply_audio)
	ball_speed_slider.value_changed.connect(_apply_gameplay)
	paddle_speed_slider.value_changed.connect(_apply_gameplay)
	back_button.pressed.connect(_back_to_menu)
	_sync_window_mode()
	_sync_resolution()
	_sync_vfx()
	_sync_audio()
	_sync_gameplay()
	App.bind_button_feedback(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		App.close_settings()

func _sync_window_mode() -> void:
	var current: int = DisplayServer.window_get_mode()
	var index: int = 0
	if current == DisplayServer.WINDOW_MODE_FULLSCREEN:
		index = 1
	window_mode.select(index)

func _apply_window_mode(index: int) -> void:
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if index == 1 else DisplayServer.WINDOW_MODE_WINDOWED
	App.set_graphics_settings(mode, DisplayServer.window_get_size())
	_update_resolution_enabled()

func _apply_resolution(index: int) -> void:
	if index < 0 or index >= resolution_sizes.size():
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		window_mode.select(0)
	var size: Vector2i = resolution_sizes[index]
	App.set_graphics_settings(DisplayServer.WINDOW_MODE_WINDOWED, size)
	_update_resolution_enabled()

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
	App.close_settings()

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

func _sync_vfx() -> void:
	vfx_toggle.set_pressed_no_signal(App.get_vfx_enabled())
	vfx_intensity.set_value_no_signal(App.get_vfx_intensity() * 100.0)
	_update_vfx_intensity_enabled()

func _apply_vfx_toggle(enabled: bool) -> void:
	App.set_vfx_enabled(enabled)
	_update_vfx_intensity_enabled()

func _apply_vfx_intensity(value: float) -> void:
	App.set_vfx_intensity(value / 100.0)

func _update_vfx_intensity_enabled() -> void:
	vfx_intensity.editable = vfx_toggle.button_pressed

func _sync_audio() -> void:
	master_slider.set_value_no_signal(App.get_audio_master() * 100.0)
	music_slider.set_value_no_signal(App.get_audio_music() * 100.0)
	sfx_slider.set_value_no_signal(App.get_audio_sfx() * 100.0)

func _apply_audio(_value: float) -> void:
	App.set_audio_levels(
		master_slider.value / 100.0,
		music_slider.value / 100.0,
		sfx_slider.value / 100.0
	)

func _sync_gameplay() -> void:
	ball_speed_slider.set_value_no_signal(App.get_ball_speed_multiplier() * 100.0)
	paddle_speed_slider.set_value_no_signal(App.get_paddle_speed_multiplier() * 100.0)

func _apply_gameplay(_value: float) -> void:
	App.set_gameplay_speed_settings(
		ball_speed_slider.value / 100.0,
		paddle_speed_slider.value / 100.0
	)
