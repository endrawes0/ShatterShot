extends Node
class_name ShopManager

signal purchase_completed
signal purchase_failed(reason: String)

var hud_controller: HudController
var shop_cards_buttons: Container
var shop_buffs_buttons: Container
var shop_ball_mods_buttons: Container

var card_data: Dictionary = {}
var card_price: int = 0
var remove_price: int = 0
var upgrade_price: int = 0
var upgrade_hand_bonus: int = 0
var vitality_price: int = 0
var vitality_max_hp_bonus: int = 0
var vitality_heal: int = 0
var reroll_base_price: int = 0
var reroll_multiplier: float = 1.0
var ball_mod_data: Dictionary = {}
var ball_mod_order: Array[String] = []
var ball_mod_counts: Dictionary = {}
var ball_mod_colors: Dictionary = {}

var callbacks: Dictionary = {}
var card_offers: Array[String] = []
var reroll_count: int = 0

func setup(hud: HudController, cards_container: Container, buffs_container: Container, mods_container: Container) -> void:
	hud_controller = hud
	shop_cards_buttons = cards_container
	shop_buffs_buttons = buffs_container
	shop_ball_mods_buttons = mods_container

func configure(config: Dictionary) -> void:
	card_data = config.get("card_data", {})
	card_price = int(config.get("card_price", 0))
	remove_price = int(config.get("remove_price", 0))
	upgrade_price = int(config.get("upgrade_price", 0))
	upgrade_hand_bonus = int(config.get("upgrade_hand_bonus", 0))
	vitality_price = int(config.get("vitality_price", 0))
	vitality_max_hp_bonus = int(config.get("vitality_max_hp_bonus", 0))
	vitality_heal = int(config.get("vitality_heal", 0))
	reroll_base_price = int(config.get("reroll_base_price", 0))
	reroll_multiplier = float(config.get("reroll_multiplier", 1.0))
	ball_mod_data = config.get("ball_mod_data", {})
	ball_mod_order = config.get("ball_mod_order", [])
	ball_mod_counts = config.get("ball_mod_counts", {})
	ball_mod_colors = config.get("ball_mod_colors", {})

func set_callbacks(callbacks_map: Dictionary) -> void:
	callbacks = callbacks_map

func reset_offers(pick_card: Callable, offer_count: int = 2) -> void:
	reroll_count = 0
	card_offers = _roll_shop_card_offers(pick_card, offer_count)

func reroll_offers(pick_card: Callable, offer_count: int = 2) -> void:
	reroll_count += 1
	card_offers = _roll_shop_card_offers(pick_card, offer_count)

func get_card_offers() -> Array[String]:
	return card_offers.duplicate()

func get_reroll_price() -> int:
	var multiplier_value: float = pow(reroll_multiplier, reroll_count)
	return int(round(float(reroll_base_price) * multiplier_value))

func build_shop_buttons() -> void:
	if shop_cards_buttons == null or shop_buffs_buttons == null or shop_ball_mods_buttons == null:
		return
	_clear_shop_buttons()
	build_shop_card_buttons()
	_build_shop_buff_buttons()
	_build_shop_mod_buttons()

func build_shop_card_buttons() -> void:
	_clear_shop_card_buttons()
	if shop_cards_buttons == null or hud_controller == null:
		return
	var reroll_price: int = get_reroll_price()
	for card_id in card_offers:
		var shop_card_id := card_id
		var button := hud_controller.create_card_button(card_id)
		var card_button := button
		hud_controller.set_card_button_desc(button, "%s\nPrice: %dg" % [card_data[card_id]["desc"], card_price])
		button.pressed.connect(func() -> void:
			if _call_can_afford(card_price):
				_call_spend_gold(card_price)
				_call_add_card(shop_card_id)
				_call_set_info("Purchased %s." % card_data[shop_card_id]["name"])
				_call_update_labels()
				card_button.queue_free()
				purchase_completed.emit()
			else:
				_call_set_info("Not enough gold.")
				purchase_failed.emit("gold")
		)
		shop_cards_buttons.add_child(button)
	var remove := Button.new()
	remove.text = "Remove a card (%dg)" % remove_price
	remove.pressed.connect(func() -> void:
		var deck_size: int = _call_get_deck_size()
		if _call_can_afford(remove_price) and deck_size > 0:
			_call_spend_gold(remove_price)
			_call_update_labels()
			_call_show_remove_panel()
			purchase_completed.emit()
		else:
			_call_set_info("Cannot remove.")
			purchase_failed.emit("remove")
	)
	App.apply_neutral_button_style(remove)
	App.bind_button_feedback(remove)
	shop_cards_buttons.add_child(remove)
	var reroll := Button.new()
	reroll.text = "Reroll Cards (%dg)" % reroll_price
	reroll.pressed.connect(func() -> void:
		if callbacks.has("reroll") and callbacks.reroll.is_valid():
			callbacks.reroll.call()
	)
	App.apply_neutral_button_style(reroll)
	App.bind_button_feedback(reroll)
	shop_cards_buttons.add_child(reroll)

func _build_shop_buff_buttons() -> void:
	if shop_buffs_buttons == null:
		return
	var upgrade := Button.new()
	upgrade.text = "Upgrade starting hand (+%d) (%dg)" % [upgrade_hand_bonus, upgrade_price]
	upgrade.pressed.connect(func() -> void:
		if _call_can_afford(upgrade_price):
			_call_spend_gold(upgrade_price)
			var new_size: int = _call_upgrade_hand(upgrade_hand_bonus)
			_call_set_info("Starting hand increased to %d." % new_size)
			_call_update_labels()
			purchase_completed.emit()
		else:
			_call_set_info("Not enough gold.")
			purchase_failed.emit("gold")
	)
	App.apply_neutral_button_style(upgrade)
	App.bind_button_feedback(upgrade)
	shop_buffs_buttons.add_child(upgrade)

	var vitality_buff := Button.new()
	vitality_buff.text = "Vitality (+%d max HP, heal %d) (%dg)" % [
		vitality_max_hp_bonus,
		vitality_heal,
		vitality_price
	]
	vitality_buff.pressed.connect(func() -> void:
		if _call_can_afford(vitality_price):
			_call_spend_gold(vitality_price)
			var new_max: int = _call_apply_vitality(vitality_max_hp_bonus, vitality_heal)
			_call_set_info("Max HP increased to %d." % new_max)
			_call_update_labels()
			purchase_completed.emit()
		else:
			_call_set_info("Not enough gold.")
			purchase_failed.emit("gold")
	)
	App.apply_neutral_button_style(vitality_buff)
	App.bind_button_feedback(vitality_buff)
	shop_buffs_buttons.add_child(vitality_buff)

func _build_shop_mod_buttons() -> void:
	if shop_ball_mods_buttons == null:
		return
	for mod_id in ball_mod_order:
		var count: int = int(ball_mod_counts.get(mod_id, 0))
		var mod: Dictionary = ball_mod_data[mod_id]
		var shop_mod_id := mod_id
		var shop_mod := mod
		var button := Button.new()
		if count > 0:
			button.text = "%s x%d (+1) (%dg)" % [mod["name"], count, mod["cost"]]
		else:
			button.text = "%s x0 (+1) (%dg)" % [mod["name"], mod["cost"]]
		button.tooltip_text = mod["desc"]
		if ball_mod_colors.has(mod_id):
			button.self_modulate = ball_mod_colors[mod_id]
		button.pressed.connect(func() -> void:
			var cost: int = int(shop_mod["cost"])
			if _call_can_afford(cost):
				_call_spend_gold(cost)
				var new_count: int = int(ball_mod_counts.get(shop_mod_id, 0)) + 1
				ball_mod_counts[shop_mod_id] = new_count
				_call_set_info("%s buff acquired." % shop_mod["name"])
				_call_refresh_mod_buttons()
				_call_update_labels()
				button.text = "%s x%d (+1) (%dg)" % [shop_mod["name"], new_count, shop_mod["cost"]]
				purchase_completed.emit()
			else:
				_call_set_info("Not enough gold.")
				purchase_failed.emit("gold")
		)
		App.apply_neutral_button_style(button)
		App.bind_button_feedback(button)
		shop_ball_mods_buttons.add_child(button)

func _clear_shop_buttons() -> void:
	if shop_cards_buttons == null or shop_buffs_buttons == null or shop_ball_mods_buttons == null:
		return
	for child in shop_cards_buttons.get_children():
		child.queue_free()
	for child in shop_buffs_buttons.get_children():
		child.queue_free()
	for child in shop_ball_mods_buttons.get_children():
		child.queue_free()

func _clear_shop_card_buttons() -> void:
	if shop_cards_buttons == null:
		return
	for child in shop_cards_buttons.get_children():
		child.queue_free()

func _roll_shop_card_offers(pick_card: Callable, offer_count: int) -> Array[String]:
	var offers: Array[String] = []
	if not pick_card.is_valid():
		return offers
	for _i in range(offer_count):
		var card_id: String = String(pick_card.call())
		if card_id != "":
			offers.append(card_id)
	return offers

func _call_can_afford(price: int) -> bool:
	if callbacks.has("can_afford") and callbacks.can_afford.is_valid():
		return bool(callbacks.can_afford.call(price))
	return false

func _call_spend_gold(price: int) -> void:
	if callbacks.has("spend_gold") and callbacks.spend_gold.is_valid():
		callbacks.spend_gold.call(price)

func _call_add_card(card_id: String) -> void:
	if callbacks.has("add_card") and callbacks.add_card.is_valid():
		callbacks.add_card.call(card_id)

func _call_update_labels() -> void:
	if callbacks.has("update_labels") and callbacks.update_labels.is_valid():
		callbacks.update_labels.call()

func _call_set_info(text: String) -> void:
	if callbacks.has("set_info") and callbacks.set_info.is_valid():
		callbacks.set_info.call(text)

func _call_show_remove_panel() -> void:
	if callbacks.has("show_remove_card_panel") and callbacks.show_remove_card_panel.is_valid():
		callbacks.show_remove_card_panel.call()

func _call_get_deck_size() -> int:
	if callbacks.has("get_deck_size") and callbacks.get_deck_size.is_valid():
		return int(callbacks.get_deck_size.call())
	return 0

func _call_upgrade_hand(bonus: int) -> int:
	if callbacks.has("upgrade_hand") and callbacks.upgrade_hand.is_valid():
		return int(callbacks.upgrade_hand.call(bonus))
	return 0

func _call_apply_vitality(max_bonus: int, heal: int) -> int:
	if callbacks.has("apply_vitality") and callbacks.apply_vitality.is_valid():
		return int(callbacks.apply_vitality.call(max_bonus, heal))
	return 0

func _call_refresh_mod_buttons() -> void:
	if callbacks.has("refresh_mod_buttons") and callbacks.refresh_mod_buttons.is_valid():
		callbacks.refresh_mod_buttons.call()
