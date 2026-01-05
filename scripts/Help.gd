extends Control

@onready var back_button: Button = $Bottom/BackButton

func _ready() -> void:
	back_button.pressed.connect(_back_to_menu)
	App.bind_button_feedback(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var viewport: Viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()
		App.close_help()

func _back_to_menu() -> void:
	App.close_help()
