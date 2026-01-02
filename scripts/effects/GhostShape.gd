extends Node2D
class_name GhostShape

const SHAPE_CIRCLE: String = "circle"
const SHAPE_ELLIPSE: String = "ellipse"

var shape: String = SHAPE_CIRCLE
var size: Vector2 = Vector2(16.0, 16.0)
var _ghost_color: Color = Color(1, 1, 1, 1)
var ghost_color: Color:
	set(value):
		_ghost_color = value
		queue_redraw()
	get:
		return _ghost_color

func setup(shape_type: String, draw_size: Vector2, color: Color, lifetime: float) -> void:
	shape = shape_type
	size = draw_size
	ghost_color = color
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "ghost_color", Color(color.r, color.g, color.b, 0.0), lifetime)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if ghost_color.a <= 0.0:
		return
	var height: float = max(1.0, size.y)
	var radius: float = height * 0.5
	if shape == SHAPE_ELLIPSE:
		var scale_x: float = max(0.01, size.x / height)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, 1.0))
		draw_circle(Vector2.ZERO, radius, ghost_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(Vector2.ZERO, radius, ghost_color)
