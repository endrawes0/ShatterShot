extends CardEffect
class_name HasteCardEffect

const BUFF_TURNS: int = 2

func apply(main: Node, _instance_id: int) -> bool:
	main.paddle_speed_buff_turns = max(main.paddle_speed_buff_turns, BUFF_TURNS)
	main.paddle.speed = main.base_paddle_speed * main.paddle_speed_multiplier
	return true
