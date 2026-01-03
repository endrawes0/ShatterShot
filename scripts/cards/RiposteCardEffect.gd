extends CardEffect
class_name RiposteCardEffect

func apply(main: Node, instance_id: int) -> bool:
	var parry_instance_id: int = -1
	for card in main.deck_manager.hand:
		if card is Dictionary:
			var found_id: int = int(card.get("id", -1))
			if found_id == instance_id:
				continue
			if String(card.get("card_id", "")) == "parry":
				parry_instance_id = found_id
				break
	if parry_instance_id == -1:
		return true
	main.deck_manager.discard_card_instance(parry_instance_id)
	main.parry_wound_blocks = -1
	main.riposte_wound_blocks = -1
	return true
