extends CardEffect
class_name RallyCardEffect

const DRAW_COUNT: int = 2

func apply(main: Node, _instance_id: int) -> bool:
	main.deck_manager.draw_cards(DRAW_COUNT)
	return true
