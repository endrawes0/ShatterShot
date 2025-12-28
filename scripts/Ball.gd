extends CharacterBody2D

const BallModEffect = preload("res://scripts/ball_mods/BallModEffect.gd")
const ExplosiveMod = preload("res://scripts/ball_mods/ExplosiveMod.gd")
const SpikesMod = preload("res://scripts/ball_mods/SpikesMod.gd")
const MiracleMod = preload("res://scripts/ball_mods/MiracleMod.gd")

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
var mod_effects: Dictionary = {}
var active_mod_effect: BallModEffect = null

const EXPLOSION_RADIUS: float = 80.0
const DEFAULT_MOD_COLOR: Color = Color(0.95, 0.95, 1, 1)
var mod_colors: Dictionary = {}

func _ready() -> void:
	randomize()
	base_damage = damage
	_init_mod_effects()
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
				var mod_effect: BallModEffect = active_mod_effect
				var mod_context: Dictionary = {}
				if mod_effect != null:
					mod_context = mod_effect.on_before_damage(self, collider, collision)
				var remaining: int = collider.apply_damage_with_overkill(
					damage,
					collision.get_normal(),
					mod_effect != null and mod_effect.get_overkill_flag(self, collider, collision)
				)
				if mod_effect != null:
					mod_effect.on_after_overkill(self, collider, collision, remaining, mod_context)
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
	if global_position.y > _get_layout_size().y + 40:
		var mod_effect: BallModEffect = active_mod_effect
		if mod_effect != null and mod_effect.on_ball_lost(self):
			return
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
	if mod_effects.is_empty():
		_init_mod_effects()
	ball_mod = mod_id
	active_mod_effect = mod_effects.get(mod_id, null)
	_update_ball_color()

func set_mod_colors(colors: Dictionary) -> void:
	mod_colors = colors
	_update_ball_color()

func _update_ball_color() -> void:
	if rect == null:
		return
	var color: Color = DEFAULT_MOD_COLOR
	if not mod_colors.is_empty():
		color = mod_colors.get(ball_mod, mod_colors.get("", DEFAULT_MOD_COLOR))
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

func _init_mod_effects() -> void:
	if not mod_effects.is_empty():
		return
	mod_effects = {
		"explosive": ExplosiveMod.new(),
		"spikes": SpikesMod.new(),
		"miracle": MiracleMod.new()
	}

func _get_layout_size() -> Vector2:
	var base: Vector2i = App.get_layout_resolution()
	if base.x > 0 and base.y > 0:
		return Vector2(base)
	return get_viewport_rect().size
