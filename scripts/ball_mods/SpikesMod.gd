extends BallModEffect
class_name SpikesMod

func get_overkill_flag(_ball: CharacterBody2D, _collider: Object, _collision: KinematicCollision2D) -> bool:
	return true

func on_before_damage(_ball: CharacterBody2D, collider: Object, collision: KinematicCollision2D) -> Dictionary:
	var used_spikes: bool = false
	if collider.has_method("is_shielded"):
		used_spikes = collider.is_shielded(collision.get_normal())
	return {"used_spikes": used_spikes}

func on_after_overkill(
	ball: CharacterBody2D,
	_collider: Object,
	_collision: KinematicCollision2D,
	_remaining: int,
	context: Dictionary
) -> void:
	if bool(context.get("used_spikes", false)):
		ball._consume_mod("spikes")

func on_ball_lost(ball: CharacterBody2D) -> bool:
	ball._consume_mod("spikes")
	return false
