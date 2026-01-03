extends CardEffect
class_name ParryCardEffect

func apply(main: Node, _instance_id: int) -> bool:
	main.parry_wound_blocks = -1
	return true
