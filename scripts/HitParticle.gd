extends Node2D

@onready var rect: ColorRect = $Rect

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 700.0
var lifetime: float = 0.0

func setup(color: Color, initial_velocity: Vector2) -> void:
	if rect:
		rect.color = color
	velocity = initial_velocity

func _process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta
	var screen := App.get_layout_size()
	if global_position.y > screen.y + 100.0:
		queue_free()
