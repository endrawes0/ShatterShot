extends Control

@onready var start_button: Button = $Center/VBox/StartButton
@onready var continue_button: Button = $Center/VBox/ContinueButton
@onready var help_button: Button = $Center/VBox/HelpButton
@onready var graphics_button: Button = $Center/VBox/GraphicsButton
@onready var test_button: Button = $Center/VBox/TestButton
@onready var quit_button: Button = $Center/VBox/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_start_game)
	continue_button.pressed.connect(_continue_run)
	help_button.pressed.connect(_open_help)
	graphics_button.pressed.connect(_open_graphics)
	test_button.pressed.connect(_open_test_lab)
	quit_button.pressed.connect(_quit_game)
	visibility_changed.connect(_update_continue_button)
	_update_continue_button()

func _start_game() -> void:
	App.start_new_run()

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
