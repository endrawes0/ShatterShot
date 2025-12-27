extends BallModEffect
class_name ExplosiveMod

func on_after_overkill(
	ball: CharacterBody2D,
	_collider: Object,
	collision: KinematicCollision2D,
	_remaining: int,
	_context: Dictionary
) -> void:
	ball._trigger_explosion(collision.get_position())
	ball._consume_mod("explosive")
