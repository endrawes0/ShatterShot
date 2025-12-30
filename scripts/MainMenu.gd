extends Control

@onready var start_button: Button = $Center/VBox/Buttons/StartButton
@onready var continue_button: Button = $Center/VBox/Buttons/ContinueButton
@onready var help_button: Button = $Center/VBox/Buttons/HelpButton
@onready var settings_button: Button = $Center/VBox/Buttons/SettingsButton
@onready var test_button: Button = $Center/VBox/Buttons/TestButton
@onready var quit_button: Button = $Center/VBox/Buttons/QuitButton
@onready var seed_dialog: ConfirmationDialog = $SeedDialog
@onready var seed_input: LineEdit = $SeedDialog/SeedDialogPanel/SeedInput
@onready var seed_status: Label = $SeedDialog/SeedDialogPanel/SeedStatus

var suppress_seed_validation: bool = false
var test_lab_unlocked: bool = false
var _menu_palette: Array[Color] = [
	Color(0.86, 0.32, 0.26),
	Color(0.95, 0.60, 0.20),
	Color(0.95, 0.85, 0.25),
	Color(0.45, 0.78, 0.36),
	Color(0.26, 0.62, 0.96),
	Color(0.72, 0.46, 0.86)
]

func _ready() -> void:
	start_button.pressed.connect(_open_seed_dialog)
	continue_button.pressed.connect(_continue_run)
	help_button.pressed.connect(_open_help)
	settings_button.pressed.connect(_open_settings)
	test_button.pressed.connect(_open_test_lab)
	quit_button.pressed.connect(_quit_game)
	visibility_changed.connect(_update_continue_button)
	if seed_dialog:
		seed_dialog.dialog_hide_on_ok = false
		seed_dialog.confirmed.connect(_start_game)
		var ok_button := seed_dialog.get_ok_button()
		if ok_button:
			ok_button.pressed.connect(_start_game)
	if seed_input:
		seed_input.text_changed.connect(_on_seed_text_changed)
	_lock_test_lab()
	_apply_menu_palette()
	_update_continue_button()
	App.bind_button_feedback(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and App.has_run():
		App.continue_run()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		_try_unlock_test_lab(event as InputEventKey)

func _lock_test_lab() -> void:
	test_lab_unlocked = false
	if test_button:
		test_button.visible = false

func _try_unlock_test_lab(event: InputEventKey) -> void:
	if test_lab_unlocked or test_button == null:
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_T and event.alt_pressed and event.ctrl_pressed and event.shift_pressed:
		test_lab_unlocked = true
		test_button.visible = true
		_apply_menu_palette()

func _open_seed_dialog() -> void:
	if seed_dialog == null:
		_start_game()
		return
	_set_seed_status("")
	seed_input.text = ""
	seed_dialog.popup_centered()
	if seed_input:
		seed_input.grab_focus()

func _start_game() -> void:
	var result := _read_seed_input()
	if not bool(result.get("valid", false)):
		return
	_set_seed_status("")
	App.start_new_run(int(result.get("seed", 0)))
	if seed_dialog:
		seed_dialog.hide()

func _continue_run() -> void:
	App.continue_run()

func _open_help() -> void:
	App.show_help()

func _open_settings() -> void:
	App.show_settings()

func _open_test_lab() -> void:
	App.show_test_lab()

func _quit_game() -> void:
	get_tree().quit()

func _update_continue_button() -> void:
	if continue_button == null:
		return
	continue_button.disabled = not App.has_run()

func _read_seed_input() -> Dictionary:
	if seed_input == null:
		return {"valid": true, "seed": 0}
	var raw := seed_input.text.strip_edges()
	if raw.is_empty():
		return {"valid": true, "seed": 0}
	if not raw.is_valid_int():
		return {"valid": true, "seed": 0}
	var seed_value: int = int(raw)
	if seed_value <= 0:
		return {"valid": true, "seed": 0}
	return {"valid": true, "seed": seed_value}

func _on_seed_text_changed(text: String) -> void:
	if suppress_seed_validation:
		return
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		_set_seed_status("")
		return
	if not trimmed.is_valid_int() or int(trimmed) <= 0:
		suppress_seed_validation = true
		seed_input.text = ""
		suppress_seed_validation = false
		_set_seed_status("")

func _set_seed_status(message: String) -> void:
	if seed_status == null:
		return
	seed_status.text = message

func _apply_menu_palette() -> void:
	var buttons := _menu_buttons()
	var palette_size := _menu_palette.size()
	for i in range(buttons.size()):
		var button := buttons[i]
		if button == null:
			continue
		var color := _menu_palette[i % palette_size]
		var hover := color.darkened(0.12)
		var pressed := color.darkened(0.22)
		button.add_theme_stylebox_override("normal", _make_button_box(color))
		button.add_theme_stylebox_override("hover", _make_button_box(hover))
		button.add_theme_stylebox_override("pressed", _make_button_box(pressed))

func _menu_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	if start_button:
		buttons.append(start_button)
	if continue_button:
		buttons.append(continue_button)
	if help_button:
		buttons.append(help_button)
	if settings_button:
		buttons.append(settings_button)
	if test_button and test_button.visible:
		buttons.append(test_button)
	if quit_button:
		buttons.append(quit_button)
	return buttons

func _make_button_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.content_margin_left = 10
	box.content_margin_top = 6
	box.content_margin_right = 10
	box.content_margin_bottom = 6
	return box
