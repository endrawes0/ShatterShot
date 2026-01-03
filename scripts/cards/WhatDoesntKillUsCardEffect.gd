extends CardEffect
class_name WhatDoesntKillUsCardEffect

func apply(main: Node, instance_id: int) -> bool:
	var wound_instance_id: int = -1
	for card in main.deck_manager.hand:
		if card is Dictionary:
			var found_id: int = int(card.get("id", -1))
			if found_id == instance_id:
				continue
			if String(card.get("card_id", "")) == "wound":
				wound_instance_id = found_id
				break
	if wound_instance_id != -1:
		main.deck_manager.remove_card_instance_from_all(wound_instance_id, true)
		main.energy += 2
		main.info_label.text = "Wound removed. +2 energy."
	return true
