extends CharacterBody2D

@onready var rect: ColorRect = $Rect

var particle_velocity: Vector2 = Vector2.ZERO
var gravity: float = 900.0
var lifetime: float = 0.0
var bounce_damping: float = 0.85

func setup(color: Color, initial_velocity: Vector2) -> void:
	if rect:
		rect.color = color
	particle_velocity = initial_velocity

func _physics_process(delta: float) -> void:
	particle_velocity.y += gravity * delta
	var collision := move_and_collide(particle_velocity * delta)
	if collision:
		var collider: Object = collision.get_collider()
		if collider:
			if collider.has_method("apply_damage_with_overkill"):
				collider.apply_damage_with_overkill(1, collision.get_normal(), false)
			elif collider.has_method("apply_damage"):
				collider.apply_damage(1)
		particle_velocity = particle_velocity.bounce(collision.get_normal()) * bounce_damping
	var screen := App.get_layout_size()
	if global_position.y > screen.y + 200.0:
		queue_free()
