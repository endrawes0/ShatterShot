extends Node2D

@onready var rect: ColorRect = $Rect

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 700.0
var lifetime: float = 0.0
var max_speed: float = 320.0

func setup(color: Color, initial_velocity: Vector2) -> void:
	if rect:
		rect.color = color
	velocity = _clamp_velocity(initial_velocity)

func _process(delta: float) -> void:
	velocity.y += gravity * delta
	velocity = _clamp_velocity(velocity)
	position += velocity * delta
	var screen := App.get_layout_size()
	if global_position.y > screen.y + 100.0:
		queue_free()

func _clamp_velocity(value: Vector2) -> Vector2:
	var speed := value.length()
	if speed <= max_speed or speed == 0.0:
		return value
	return value.normalized() * max_speed
