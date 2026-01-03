extends CardEffect
class_name BombCardEffect

const BRICK_COUNT: int = 3

func apply(main: Node, _instance_id: int) -> bool:
	main._destroy_random_bricks(BRICK_COUNT)
	return true
