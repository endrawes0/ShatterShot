extends CardEffect
class_name WoundCardEffect

func apply(main: Node, instance_id: int) -> bool:
	main.deck_manager.remove_card_instance_from_all(instance_id, true)
	main.info_label.text = "Wound removed from your deck."
	return false
