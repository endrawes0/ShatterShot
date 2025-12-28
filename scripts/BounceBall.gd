extends "res://scripts/Ball.gd"

@export var paddle_path_override: NodePath

func setup(color: Color, initial_velocity: Vector2) -> void:
	if rect:
		rect.color = color
	if initial_velocity.length() > 0.0:
		speed = initial_velocity.length()
		velocity = initial_velocity
		launched = true

func _ready() -> void:
	if paddle_path_override != NodePath(""):
		paddle_path = paddle_path_override
	super._ready()

func _reset() -> void:
	queue_free()
