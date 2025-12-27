extends RefCounted
class_name BallModEffect

func get_overkill_flag(_ball: CharacterBody2D, _collider: Object, _collision: KinematicCollision2D) -> bool:
	return false

func on_before_damage(_ball: CharacterBody2D, _collider: Object, _collision: KinematicCollision2D) -> Dictionary:
	return {}

func on_after_overkill(
	_ball: CharacterBody2D,
	_collider: Object,
	_collision: KinematicCollision2D,
	_remaining: int,
	_context: Dictionary
) -> void:
	return

func on_ball_lost(_ball: CharacterBody2D) -> bool:
	return false
