extends CharacterBody2D

const BallModEffect = preload("res://scripts/ball_mods/BallModEffect.gd")
const ExplosiveMod = preload("res://scripts/ball_mods/ExplosiveMod.gd")
const SpikesMod = preload("res://scripts/ball_mods/SpikesMod.gd")
const MiracleMod = preload("res://scripts/ball_mods/MiracleMod.gd")
const GhostShape = preload("res://scripts/effects/GhostShape.gd")

signal lost(ball: Node)
signal mod_consumed(mod_id: String)
signal caught(ball: Node)

@export var speed: float = 320.0
@export var paddle_path: NodePath

@onready var paddle: Node2D = _resolve_paddle()
@onready var bounce_player: AudioStreamPlayer = $BounceSfx
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
const BOUNCE_BASE_FREQ: float = 200.0
const BOUNCE_FREQ_VARIANCE: float = 20.0
const GHOST_SPACING: float = 10.0
const GHOST_LIFETIME: float = 0.22
const GHOST_ALPHA: float = 0.45
var mod_colors: Dictionary = {}
static var _bounce_stream: AudioStreamWAV = null
var _ghost_last_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	base_damage = damage
	_ensure_bounce_stream()
	_init_mod_effects()
	_update_ball_color()
	_ghost_last_pos = position

func _physics_process(delta: float) -> void:
	if not launched:
		if paddle == null:
			paddle = _resolve_paddle()
			if paddle == null:
				return
		global_position = paddle.global_position + OFFSET
		_ghost_last_pos = position
		return

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		_play_bounce_sfx()
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
			emit_signal("caught", self)
		elif not piercing:
			velocity = velocity.bounce(collision.get_normal())

	velocity = velocity.normalized() * speed
	_update_ghosts()
	if position.y > App.get_layout_size().y + 40:
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
	var half_width := 60.0
	if paddle_node.has_method("get"):
		half_width = float(paddle_node.get("half_width"))
	var rel: float = (global_position.x - paddle_node.global_position.x) / max(1.0, half_width)
	var angle: float = clamp(rel, -1.0, 1.0) * 0.9
	damage = base_damage
	var direction_y: float = -1.0
	if global_position.y > paddle_node.global_position.y:
		direction_y = 1.0
	velocity = Vector2(angle, direction_y).normalized() * speed

func _reset() -> void:
	launched = false
	velocity = Vector2.ZERO
	_ghost_last_pos = position

func set_ball_mod(mod_id: String) -> void:
	if mod_effects.is_empty():
		_init_mod_effects()
	ball_mod = mod_id
	active_mod_effect = mod_effects.get(mod_id, null)
	_update_ball_color()

func set_mod_colors(colors: Dictionary) -> void:
	mod_colors = colors
	_update_ball_color()

func _resolve_paddle() -> Node2D:
	if paddle_path != NodePath(""):
		var node := get_node_or_null(paddle_path)
		if node is Node2D:
			return node
	var fallback := get_tree().root.find_child("Paddle", true, false)
	return fallback if fallback is Node2D else null

func _play_bounce_sfx() -> void:
	if bounce_player == null:
		return
	if _bounce_stream == null:
		_ensure_bounce_stream()
	if bounce_player.stream == null:
		bounce_player.stream = _bounce_stream
	var min_ratio: float = (BOUNCE_BASE_FREQ - BOUNCE_FREQ_VARIANCE) / BOUNCE_BASE_FREQ
	var max_ratio: float = (BOUNCE_BASE_FREQ + BOUNCE_FREQ_VARIANCE) / BOUNCE_BASE_FREQ
	bounce_player.pitch_scale = randf_range(min_ratio, max_ratio)
	bounce_player.play()

func _update_ball_color() -> void:
	if rect == null:
		return
	var color: Color = DEFAULT_MOD_COLOR
	if not mod_colors.is_empty():
		color = mod_colors.get(ball_mod, mod_colors.get("", DEFAULT_MOD_COLOR))
	rect.color = color
	queue_redraw()

func _draw() -> void:
	if rect == null:
		return
	var radius: float = rect.size.x * 0.5
	draw_circle(Vector2.ZERO, radius, rect.color)

func _update_ghosts() -> void:
	if not App.get_vfx_enabled():
		return
	var intensity: float = App.get_vfx_intensity()
	if intensity <= 0.0:
		return
	if _ghost_last_pos == Vector2.ZERO:
		_ghost_last_pos = position
		return
	var spacing: float = GHOST_SPACING / max(0.1, intensity)
	if _ghost_last_pos.distance_to(position) < spacing:
		return
	_ghost_last_pos = position
	_spawn_ghost()

func _spawn_ghost() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var ghost := GhostShape.new()
	ghost.position = position
	ghost.z_index = rect.z_index if rect else 0
	parent_node.add_child(ghost)
	var base_color := rect.color if rect else DEFAULT_MOD_COLOR
	base_color.a = clampf(GHOST_ALPHA * App.get_vfx_intensity(), 0.0, 1.0)
	var size: Vector2 = rect.size if rect else Vector2(16, 16)
	ghost.setup(GhostShape.SHAPE_CIRCLE, size, base_color, GHOST_LIFETIME)

func _trigger_explosion(center: Vector2) -> void:
	var bricks: Array = get_tree().get_nodes_in_group("bricks")
	for brick in bricks:
		if brick is Node2D and (brick as Node2D).global_position.distance_to(center) <= EXPLOSION_RADIUS:
			_apply_explosion_damage(brick)

func _apply_explosion_damage(brick: Object) -> void:
	if brick == null:
		return
	var capped_amount: int = 999
	if brick.has_method("get"):
		var hp_value: Variant = brick.get("hp")
		if typeof(hp_value) == TYPE_INT and hp_value > 0:
			capped_amount = min(capped_amount, int(hp_value))
	if brick.has_method("apply_damage_with_overkill"):
		if brick.has_method("suppress_curse"):
			brick.suppress_curse()
		brick.apply_damage_with_overkill(capped_amount, Vector2.ZERO, true)
	elif brick.has_method("apply_damage"):
		brick.apply_damage(capped_amount)

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

func _ensure_bounce_stream() -> void:
	if _bounce_stream != null:
		return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = 22050
	var freq: float = BOUNCE_BASE_FREQ
	var duration: float = 0.1
	var samples: int = int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / float(stream.mix_rate)
		var env: float = exp(-18.0 * t)
		var sample: float = sin(TAU * freq * t) * env * 0.5
		var value: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	stream.data = data
	_bounce_stream = stream
	if bounce_player:
		bounce_player.stream = _bounce_stream
