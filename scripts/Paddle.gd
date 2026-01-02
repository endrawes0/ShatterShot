extends CharacterBody2D

const GhostShape = preload("res://scripts/effects/GhostShape.gd")

@export var speed: float = 420.0
@export var half_width: float = 60.0

@onready var rect: ColorRect = $Rect
@onready var collider: CollisionPolygon2D = $CollisionPolygon2D

var locked_y: float = 0.0
var reserve_count: int = 0
var _ghost_last_pos: Vector2 = Vector2.ZERO
const RESERVE_SIZE: float = 6.0
const RESERVE_GAP: float = 3.0
const RESERVE_COLOR: Color = Color(0.05, 0.05, 0.05, 1)
const PADDLE_COLOR: Color = Color(0.9, 0.9, 0.9, 1)
const COLLIDER_SEGMENTS: int = 256
const GHOST_SPACING: float = 12.0
const GHOST_LIFETIME: float = 0.18
const GHOST_ALPHA: float = 0.35

func _ready() -> void:
	locked_y = position.y
	_ghost_last_pos = position
	_update_collider_polygon()

func _physics_process(_delta: float) -> void:
	var right_strength: float = float(Input.get_action_strength("ui_right"))
	var left_strength: float = float(Input.get_action_strength("ui_left"))
	var direction: float = right_strength - left_strength

	velocity.x = direction * speed
	velocity.y = 0.0
	move_and_slide()

	var layout_width: float = App.get_layout_size().x
	var clamped_x: float = clamp(position.x, half_width, layout_width - half_width)
	position.x = clamped_x
	position.y = locked_y
	_update_ghosts()

func _draw() -> void:
	_draw_paddle()
	_draw_reserve()

func _draw_paddle() -> void:
	var size: Vector2 = rect.size if rect else Vector2(half_width * 2.0, 16.0)
	var color: Color = rect.color if rect else PADDLE_COLOR
	var half_size: Vector2 = size * 0.5
	var points := PackedVector2Array()
	for i in range(256):
		var angle: float = TAU * float(i) / 256.0
		points.append(Vector2(cos(angle) * half_size.x, sin(angle) * half_size.y))
	var backing_points := PackedVector2Array()
	for point in points:
		backing_points.append(point * 1.01)
	draw_colored_polygon(backing_points, Color(0.65, 0.65, 0.68, 1.0))
	draw_colored_polygon(points, color)

func _draw_reserve() -> void:
	var count: int = reserve_count
	if count <= 0:
		return
	var total_width: float = count * RESERVE_SIZE + max(0, count - 1) * RESERVE_GAP
	var start_x: float = -total_width * 0.5
	var y: float = -RESERVE_SIZE * 0.5
	var radius: float = RESERVE_SIZE * 0.5
	for i in range(count):
		var x: float = start_x + i * (RESERVE_SIZE + RESERVE_GAP)
		var center := Vector2(x + radius, y + radius)
		draw_circle(center, radius, RESERVE_COLOR)

func _update_ghosts() -> void:
	if not App.get_vfx_enabled():
		return
	var intensity: float = App.get_vfx_intensity()
	if intensity <= 0.0:
		return
	var spacing: float = GHOST_SPACING / max(0.1, intensity)
	if _ghost_last_pos.distance_to(position) < spacing:
		return
	_ghost_last_pos = position
	_spawn_ghost(intensity)

func _spawn_ghost(intensity: float) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var ghost := GhostShape.new()
	ghost.position = position
	ghost.z_index = rect.z_index if rect else 0
	parent_node.add_child(ghost)
	var size: Vector2 = rect.size if rect else Vector2(half_width * 2.0, 16.0)
	var base_color: Color = rect.color if rect else PADDLE_COLOR
	base_color.a = clampf(GHOST_ALPHA * intensity, 0.0, 1.0)
	ghost.setup(GhostShape.SHAPE_ELLIPSE, size, base_color, GHOST_LIFETIME)

func set_half_width(value: float) -> void:
	half_width = max(20.0, value)
	rect.size.x = half_width * 2.0
	rect.position.x = -half_width
	_update_collider_polygon()
	queue_redraw()

func _update_collider_polygon() -> void:
	if collider == null:
		return
	var size: Vector2 = rect.size if rect else Vector2(half_width * 2.0, 16.0)
	var half_size: Vector2 = size * 0.5
	var points := PackedVector2Array()
	for i in range(COLLIDER_SEGMENTS):
		var angle: float = TAU * float(i) / float(COLLIDER_SEGMENTS)
		points.append(Vector2(cos(angle) * half_size.x, sin(angle) * half_size.y))
	collider.polygon = points

func set_locked_y(value: float) -> void:
	locked_y = value

func set_reserve_count(value: int) -> void:
	reserve_count = max(0, value)
	queue_redraw()
