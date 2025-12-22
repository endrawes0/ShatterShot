extends CharacterBody2D

signal lost(ball: Node)
signal mod_consumed(mod_id: String)

@export var speed: float = 320.0
@export var paddle_path: NodePath

@onready var paddle: Node2D = get_node(paddle_path) as Node2D
@onready var rect: ColorRect = $Rect

var launched: bool = false
const OFFSET: Vector2 = Vector2(0, -32)
var damage: int = 1
var piercing: bool = false
var base_damage: int = 1
var ball_mod: String = ""

const EXPLOSION_RADIUS: float = 80.0
const MOD_COLORS: Dictionary = {
	"explosive": Color(0.95, 0.35, 0.35),
	"spikes": Color(0.95, 0.85, 0.25),
	"miracle": Color(0.45, 0.75, 1.0),
	"": Color(0.95, 0.95, 1, 1)
}

func _ready() -> void:
	randomize()
	base_damage = damage
	_update_ball_color()

func _physics_process(delta: float) -> void:
	if not launched:
		global_position = paddle.global_position + OFFSET
		return

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		var collider: Object = collision.get_collider()
		if collider and collider.is_in_group("bricks"):
			if collider.has_method("apply_damage_with_overkill"):
				var used_spikes: bool = false
				if ball_mod == "spikes" and collider.has_method("is_shielded"):
					used_spikes = collider.is_shielded(collision.get_normal())
				var remaining: int = collider.apply_damage_with_overkill(
					damage,
					collision.get_normal(),
					ball_mod == "spikes"
				)
				if ball_mod == "spikes" and used_spikes:
					_consume_mod("spikes")
				if ball_mod == "explosive":
					_trigger_explosion(collision.get_position())
					_consume_mod("explosive")
				if remaining > 0:
					damage = remaining
				elif not piercing:
					velocity = velocity.bounce(collision.get_normal())
				velocity = velocity.normalized() * speed
				return
			elif collider.has_method("apply_damage"):
				collider.apply_damage(damage)
		if collider and collider.name == "Paddle":
			_bounce_from_paddle(collider as Node2D)
		elif not piercing:
			velocity = velocity.bounce(collision.get_normal())

	velocity = velocity.normalized() * speed
	if global_position.y > get_viewport_rect().size.y + 40:
		if ball_mod == "miracle":
			velocity = Vector2(velocity.x, -absf(velocity.y))
			_consume_mod("miracle")
			return
		if ball_mod == "spikes":
			_consume_mod("spikes")
		_reset()
		emit_signal("lost", self)

func launch_with_angle(angle: float) -> void:
	launched = true
	base_damage = damage
	velocity = Vector2(0, -1).rotated(angle) * speed

func _bounce_from_paddle(paddle_node: Node2D) -> void:
	var rel: float = (global_position.x - paddle_node.global_position.x) / 60.0
	var angle: float = clamp(rel, -1.0, 1.0) * 0.9
	damage = base_damage
	var direction_y: float = -1.0
	if global_position.y > paddle_node.global_position.y:
		direction_y = 1.0
	velocity = Vector2(angle, direction_y).normalized() * speed

func _reset() -> void:
	launched = false
	velocity = Vector2.ZERO

func set_ball_mod(mod_id: String) -> void:
	ball_mod = mod_id
	_update_ball_color()

func _update_ball_color() -> void:
	if rect == null:
		return
	var color: Color = MOD_COLORS.get(ball_mod, MOD_COLORS[""])
	rect.color = color

func _trigger_explosion(center: Vector2) -> void:
	var bricks: Array = get_tree().get_nodes_in_group("bricks")
	for brick in bricks:
		if brick is Node2D and (brick as Node2D).global_position.distance_to(center) <= EXPLOSION_RADIUS:
			if brick.has_method("apply_damage_with_overkill"):
				if brick.has_method("suppress_curse"):
					brick.suppress_curse()
				brick.apply_damage_with_overkill(999, Vector2.ZERO, true)
			elif brick.has_method("apply_damage"):
				brick.apply_damage(999)

func _consume_mod(mod_id: String) -> void:
	set_ball_mod("")
	emit_signal("mod_consumed", mod_id)
