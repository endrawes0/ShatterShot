extends Control

@onready var back_button: Button = $Bottom/BackButton

func _ready() -> void:
	back_button.pressed.connect(_back_to_menu)

func _back_to_menu() -> void:
	App.show_menu()
