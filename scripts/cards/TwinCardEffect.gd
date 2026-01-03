extends CardEffect
class_name TwinCardEffect

func apply(main: Node, _instance_id: int) -> bool:
	main.volley_ball_bonus += 1
	return true
