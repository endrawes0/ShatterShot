extends CardEffect
class_name PunchCardEffect

func apply(main: Node, _instance_id: int) -> bool:
	main.volley_damage_bonus += 1
	return true
