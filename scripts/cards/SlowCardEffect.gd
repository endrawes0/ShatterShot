extends CardEffect
class_name SlowCardEffect

const SPEED_MULTIPLIER: float = 0.7

func apply(main: Node, _instance_id: int) -> bool:
	main.volley_ball_speed_multiplier = SPEED_MULTIPLIER
	return true
