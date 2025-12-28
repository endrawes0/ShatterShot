extends StaticBody2D

signal destroyed(brick: Node)
signal damaged(brick: Node)

const HIT_PARTICLE_SCENE := preload("res://scenes/HitParticle.tscn")
const BOUNCE_BALL_SCENE := preload("res://scenes/BounceBall.tscn")

@onready var rect: ColorRect = $Rect
@onready var hp_label: Label = $Rect/HpLabel
@onready var curse_label: Label = $Rect/CurseLabel
@onready var regen_label: Label = $Rect/RegenLabel
@onready var shield_left: ColorRect = $Rect/ShieldLeft
@onready var shield_right: ColorRect = $Rect/ShieldRight
@onready var shield_top: ColorRect = $Rect/ShieldTop
@onready var shield_bottom: ColorRect = $Rect/ShieldBottom

var hp: int = 1
var threat: int = 1
var shielded_sides: Array = []
var regen_on_drop: bool = false
var regen_amount: int = 1
var is_cursed: bool = false
var suppress_curse_on_destroy: bool = false
var particle_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	particle_rng.randomize()

func setup(new_hp: int, new_threat: int, color: Color, data: Dictionary = {}) -> void:
	if rect == null:
		rect = get_node("Rect") as ColorRect
	if hp_label == null and rect != null:
		hp_label = rect.get_node("HpLabel") as Label
	if curse_label == null and rect != null:
		curse_label = rect.get_node("CurseLabel") as Label
	if regen_label == null and rect != null:
		regen_label = rect.get_node("RegenLabel") as Label
	if rect != null:
		if shield_left == null:
			shield_left = rect.get_node("ShieldLeft") as ColorRect
		if shield_right == null:
			shield_right = rect.get_node("ShieldRight") as ColorRect
		if shield_top == null:
			shield_top = rect.get_node("ShieldTop") as ColorRect
		if shield_bottom == null:
			shield_bottom = rect.get_node("ShieldBottom") as ColorRect
	hp = max(1, new_hp)
	threat = max(0, new_threat)
	shielded_sides = data.get("shielded_sides", [])
	regen_on_drop = data.get("regen_on_drop", false)
	regen_amount = data.get("regen_amount", 1)
	is_cursed = data.get("is_cursed", false)
	if rect != null:
		rect.color = color
	if curse_label != null:
		curse_label.visible = is_cursed
	if regen_label != null:
		regen_label.visible = regen_on_drop
	_update_shield_visuals()
	_update_label()

func apply_damage(amount: int) -> void:
	apply_damage_with_overkill(amount)

func apply_damage_with_overkill(amount: int, normal: Vector2 = Vector2.ZERO, ignore_shield: bool = false) -> int:
	if _is_shielded(normal, ignore_shield):
		return 0
	var damage: int = max(1, amount)
	var hp_before: int = hp
	hp -= damage
	if hp <= 0:
		_spawn_hit_particles(_destroy_particle_count(damage))
		_spawn_bounce_particle()
		emit_signal("destroyed", self)
		queue_free()
		return max(0, damage - hp_before)
	emit_signal("damaged", self)
	_spawn_hit_particles(_damage_particle_count(damage))
	_update_label()
	return 0

func _update_label() -> void:
	if hp_label != null:
		hp_label.text = "%d" % hp

func get_threat() -> int:
	return hp

func on_ball_drop() -> void:
	if regen_on_drop and hp > 0:
		hp += regen_amount
		_update_label()

func _is_shielded(normal: Vector2, ignore_shield: bool = false) -> bool:
	if ignore_shield:
		return false
	if shielded_sides.is_empty() or normal == Vector2.ZERO:
		return false
	var side: String = ""
	if absf(normal.x) > absf(normal.y):
		side = "left" if normal.x < 0.0 else "right"
	else:
		side = "top" if normal.y < 0.0 else "bottom"
	return shielded_sides.has(side)

func is_shielded(normal: Vector2) -> bool:
	return _is_shielded(normal, false)

func _update_shield_visuals() -> void:
	if shield_left != null:
		shield_left.visible = shielded_sides.has("left")
	if shield_right != null:
		shield_right.visible = shielded_sides.has("right")
	if shield_top != null:
		shield_top.visible = shielded_sides.has("top")
	if shield_bottom != null:
		shield_bottom.visible = shielded_sides.has("bottom")

func suppress_curse() -> void:
	suppress_curse_on_destroy = true

func _spawn_hit_particles(count: int) -> void:
	if rect == null:
		return
	var parent_node := get_parent()
	if parent_node == null:
		return
	for _i in range(count):
		var particle := HIT_PARTICLE_SCENE.instantiate()
		if particle == null:
			continue
		parent_node.add_child(particle)
		if particle is Node2D:
			var node: Node2D = particle as Node2D
			var offset := Vector2(
				particle_rng.randf_range(-10.0, 10.0),
				particle_rng.randf_range(-8.0, 8.0)
			)
			node.global_position = global_position + offset
		if particle.has_method("setup"):
			var velocity := Vector2(
				particle_rng.randf_range(-120.0, 120.0),
				particle_rng.randf_range(-320.0, -140.0)
			)
			particle.call("setup", rect.color, velocity)

func _spawn_bounce_particle() -> void:
	if rect == null:
		return
	if particle_rng.randf() > 0.1:
		return
	var parent_node := get_parent()
	if parent_node == null:
		return
	var particle := BOUNCE_BALL_SCENE.instantiate()
	if particle == null:
		return
	parent_node.add_child(particle)
	if particle is Node2D:
		var node: Node2D = particle as Node2D
		node.global_position = global_position
	if particle.has_method("setup"):
		var velocity := Vector2(
			particle_rng.randf_range(-160.0, 160.0),
			particle_rng.randf_range(-420.0, -220.0)
		)
		particle.call("setup", rect.color, velocity)
	if particle.has_method("set"):
		particle.set("paddle_path_override", "Paddle")

func _damage_particle_count(damage: int) -> int:
	return clamp(6 + damage * 2, 6, 36)

func _destroy_particle_count(damage: int) -> int:
	return clamp(12 + damage * 4, 12, 60)
