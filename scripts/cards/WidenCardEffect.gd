extends CardEffect
class_name WidenCardEffect

const WIDTH_BONUS: float = 30.0
const BUFF_TURNS: int = 2

func apply(main: Node, _instance_id: int) -> bool:
	main.paddle_buff_turns = max(main.paddle_buff_turns, BUFF_TURNS)
	main.paddle.set_half_width(main.base_paddle_half_width + WIDTH_BONUS)
	return true
