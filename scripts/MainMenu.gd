extends Control

@onready var start_button: Button = $Center/VBox/StartButton
@onready var continue_button: Button = $Center/VBox/ContinueButton
@onready var help_button: Button = $Center/VBox/HelpButton
@onready var graphics_button: Button = $Center/VBox/GraphicsButton
@onready var test_button: Button = $Center/VBox/TestButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var seed_dialog: ConfirmationDialog = $SeedDialog
@onready var seed_input: LineEdit = $SeedDialog/SeedDialogPanel/SeedInput
@onready var seed_status: Label = $SeedDialog/SeedDialogPanel/SeedStatus

var suppress_seed_validation: bool = false
var test_lab_unlocked: bool = false

func _ready() -> void:
	start_button.pressed.connect(_open_seed_dialog)
	continue_button.pressed.connect(_continue_run)
	help_button.pressed.connect(_open_help)
	graphics_button.pressed.connect(_open_graphics)
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
	_update_continue_button()

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

func _open_graphics() -> void:
	App.show_graphics()

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
