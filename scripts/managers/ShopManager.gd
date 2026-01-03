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
var max_card_offers: int = 0
var remove_price: int = 0
var upgrade_price: int = 0
var upgrade_hand_bonus: int = 0
var max_hand_size: int = 0
var vitality_price: int = 0
var vitality_max_hp_bonus: int = 0
var vitality_heal: int = 0
var energy_buff_price: int = 0
var energy_buff_bonus: int = 0
var paddle_width_price: int = 0
var paddle_width_bonus: float = 0.0
var paddle_speed_price: int = 0
var paddle_speed_bonus_percent: float = 0.0
var reserve_ball_price: int = 0
var reserve_ball_bonus: int = 0
var shop_discount_price: int = 0
var shop_discount_percent: float = 0.0
var shop_discount_max: int = 0
var shop_discount_purchases: int = 0
var shop_entry_card_price: int = 0
var shop_entry_card_count: int = 0
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
	max_card_offers = int(config.get("max_card_offers", 0))
	remove_price = int(config.get("remove_price", 0))
	upgrade_price = int(config.get("upgrade_price", 0))
	upgrade_hand_bonus = int(config.get("upgrade_hand_bonus", 0))
	max_hand_size = int(config.get("max_hand_size", 0))
	vitality_price = int(config.get("vitality_price", 0))
	vitality_max_hp_bonus = int(config.get("vitality_max_hp_bonus", 0))
	vitality_heal = int(config.get("vitality_heal", 0))
	energy_buff_price = int(config.get("energy_buff_price", 0))
	energy_buff_bonus = int(config.get("energy_buff_bonus", 0))
	paddle_width_price = int(config.get("paddle_width_price", 0))
	paddle_width_bonus = float(config.get("paddle_width_bonus", 0.0))
	paddle_speed_price = int(config.get("paddle_speed_price", 0))
	paddle_speed_bonus_percent = float(config.get("paddle_speed_bonus_percent", 0.0))
	reserve_ball_price = int(config.get("reserve_ball_price", 0))
	reserve_ball_bonus = int(config.get("reserve_ball_bonus", 0))
	shop_discount_price = int(config.get("shop_discount_price", 0))
	shop_discount_percent = float(config.get("shop_discount_percent", 0.0))
	shop_discount_max = int(config.get("shop_discount_max", 0))
	shop_entry_card_price = int(config.get("shop_entry_card_price", 0))
	shop_entry_card_count = int(config.get("shop_entry_card_count", 0))
	reroll_base_price = int(config.get("reroll_base_price", 0))
	reroll_multiplier = float(config.get("reroll_multiplier", 1.0))
	ball_mod_data = config.get("ball_mod_data", {})
	ball_mod_order = config.get("ball_mod_order", [])
	ball_mod_counts = config.get("ball_mod_counts", {})
	ball_mod_colors = config.get("ball_mod_colors", {})

func set_callbacks(callbacks_map: Dictionary) -> void:
	callbacks = callbacks_map

func reset_shop_limits() -> void:
	shop_discount_purchases = 0

func reset_offers(pick_card: Callable, offer_count: int = 2) -> void:
	reroll_count = 0
	card_offers = _roll_shop_card_offers(pick_card, offer_count)

func reroll_offers(pick_card: Callable, offer_count: int = 2) -> void:
	reroll_count += 1
	card_offers = _roll_shop_card_offers(pick_card, offer_count)

func add_card_offers(pick_card: Callable, offer_count: int = 1) -> Array[String]:
	var remaining: int = offer_count
	if max_card_offers > 0:
		remaining = min(remaining, max_card_offers - card_offers.size())
	if remaining <= 0:
		return []
	var offers: Array[String] = _roll_shop_card_offers(pick_card, remaining)
	for card_id in offers:
		card_offers.append(card_id)
	return offers

func get_card_offers() -> Array[String]:
	return card_offers.duplicate()

func get_reroll_price() -> int:
	var multiplier_value: float = pow(reroll_multiplier, reroll_count)
	return int(round(float(reroll_base_price) * multiplier_value))

func _get_discount_remaining() -> int:
	if shop_discount_max <= 0:
		return -1
	return max(0, shop_discount_max - shop_discount_purchases)

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
	var upgrade_text := "Upgrade starting hand (+%d) (%dg)" % [upgrade_hand_bonus, upgrade_price]
	if max_hand_size > 0:
		var hand_remaining: int = _get_hand_remaining()
		upgrade_text = "%s (%d remaining)" % [upgrade_text, hand_remaining]
	_add_shop_buff_button(
		upgrade_text,
		Callable(self, "_handle_upgrade_hand"),
		_is_hand_maxed(),
		"Starting hand is at max size."
	)

	var vitality_text := "Vitality (+%d max HP, heal %d) (%dg)" % [
		vitality_max_hp_bonus,
		vitality_heal,
		vitality_price
	]
	_add_shop_buff_button(vitality_text, Callable(self, "_handle_vitality"))

	if energy_buff_bonus > 0:
		var max_energy_remaining: int = _get_energy_remaining()
		var energy_text := "Surge (+%d max energy) (%dg)" % [energy_buff_bonus, energy_buff_price]
		energy_text = "%s (%d remaining)" % [energy_text, max(0, max_energy_remaining)]
		_add_shop_buff_button(
			energy_text,
			Callable(self, "_handle_surge"),
			max_energy_remaining <= 0,
			"Max energy bonus is capped at 2."
		)

	if paddle_width_bonus > 0.0:
		var width_text := "Wider Paddle (+%d width) (%dg)" % [int(round(paddle_width_bonus)), paddle_width_price]
		_add_shop_buff_button(width_text, Callable(self, "_handle_paddle_width"))

	if paddle_speed_bonus_percent > 0.0:
		var speed_text := "Paddle Speed (+%d%%) (%dg)" % [int(round(paddle_speed_bonus_percent)), paddle_speed_price]
		_add_shop_buff_button(speed_text, Callable(self, "_handle_paddle_speed"))

	if reserve_ball_bonus > 0:
		var reserve_remaining: int = _get_reserve_remaining()
		var reserve_text := "Reserve Ball (+%d per volley) (%dg)" % [reserve_ball_bonus, reserve_ball_price]
		reserve_text = "%s (%d remaining)" % [reserve_text, max(0, reserve_remaining)]
		_add_shop_buff_button(
			reserve_text,
			Callable(self, "_handle_reserve_ball"),
			reserve_remaining <= 0,
			"Reserve ball bonus is maxed out."
		)

	if shop_discount_percent > 0.0:
		var remaining_discounts: int = _get_discount_remaining()
		var discount_text := "Shop Discount (-%d%% prices) (%dg)" % [int(round(shop_discount_percent)), shop_discount_price]
		if shop_discount_max > 0:
			discount_text = "%s (%d remaining)" % [discount_text, remaining_discounts]
		var discount_disabled := shop_discount_max > 0 and remaining_discounts <= 0
		_add_shop_buff_button(
			discount_text,
			Callable(self, "_handle_shop_discount"),
			discount_disabled,
			"Shop discounts are maxed out."
		)

	if shop_entry_card_count > 0:
		var remaining_offers: int = _get_entry_remaining()
		var entry_text := "Shop Scribe (+%d card on entry) (%dg)" % [shop_entry_card_count, shop_entry_card_price]
		if max_card_offers > 0:
			entry_text = "%s (%d remaining)" % [entry_text, max(0, remaining_offers)]
		var entry_disabled := max_card_offers > 0 and remaining_offers <= 0
		_add_shop_buff_button(
			entry_text,
			Callable(self, "_handle_shop_scribe"),
			entry_disabled,
			"Shop is at max card offers."
		)

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

func _get_hand_remaining() -> int:
	if max_hand_size <= 0:
		return 0
	return max(0, max_hand_size - _call_get_starting_hand_size())

func _is_hand_maxed() -> bool:
	return max_hand_size > 0 and _call_get_starting_hand_size() >= max_hand_size

func _get_energy_remaining() -> int:
	return max(0, 2 - _call_get_max_energy_bonus())

func _get_reserve_remaining() -> int:
	return max(0, 1 - _call_get_reserve_ball_bonus())

func _get_entry_remaining() -> int:
	if max_card_offers <= 0:
		return 0
	return max(0, max_card_offers - card_offers.size())

func _handle_upgrade_hand() -> void:
	if _is_hand_maxed():
		_call_set_info("Starting hand is at max size.")
		purchase_failed.emit("hand_max")
		return
	_attempt_purchase(upgrade_price, func() -> void:
		var new_size: int = _call_upgrade_hand(upgrade_hand_bonus)
		_call_set_info("Starting hand increased to %d." % new_size)
		_call_refresh_shop_buttons()
	)

func _handle_vitality() -> void:
	_attempt_purchase(vitality_price, func() -> void:
		var new_max: int = _call_apply_vitality(vitality_max_hp_bonus, vitality_heal)
		_call_set_info("Max HP increased to %d." % new_max)
	)

func _handle_surge() -> void:
	if _call_get_max_energy_bonus() >= 2:
		_call_set_info("Max energy bonus is capped.")
		purchase_failed.emit("energy_max")
		return
	_attempt_purchase(energy_buff_price, func() -> void:
		var new_max: int = _call_apply_max_energy(energy_buff_bonus)
		_call_set_info("Max energy increased to %d." % new_max)
		_call_refresh_shop_buttons()
	)

func _handle_paddle_width() -> void:
	_attempt_purchase(paddle_width_price, func() -> void:
		var new_width: float = _call_apply_paddle_width(paddle_width_bonus)
		_call_set_info("Base paddle width increased to %d." % int(round(new_width)))
	)

func _handle_paddle_speed() -> void:
	_attempt_purchase(paddle_speed_price, func() -> void:
		var new_speed: float = _call_apply_paddle_speed(paddle_speed_bonus_percent)
		_call_set_info("Paddle speed increased to %d." % int(round(new_speed)))
	)

func _handle_reserve_ball() -> void:
	if _call_get_reserve_ball_bonus() >= 1:
		_call_set_info("Reserve ball bonus is maxed out.")
		purchase_failed.emit("reserve_max")
		return
	_attempt_purchase(reserve_ball_price, func() -> void:
		var new_bonus: int = _call_apply_reserve_ball(reserve_ball_bonus)
		_call_set_info("Reserve balls per volley increased to %d." % new_bonus)
		_call_refresh_shop_buttons()
	)

func _handle_shop_discount() -> void:
	var remaining: int = _get_discount_remaining()
	if shop_discount_max > 0 and remaining <= 0:
		_call_set_info("Shop discounts are maxed out.")
		purchase_failed.emit("discount_max")
		return
	_attempt_purchase(shop_discount_price, func() -> void:
		shop_discount_purchases += 1
		_call_apply_shop_discount(shop_discount_percent)
		_call_set_info("Shop prices discounted by %d%%." % int(round(shop_discount_percent)))
	)

func _handle_shop_scribe() -> void:
	if max_card_offers > 0 and card_offers.size() >= max_card_offers:
		_call_set_info("Shop has the max card offers.")
		purchase_failed.emit("max_cards")
		return
	_attempt_purchase(shop_entry_card_price, func() -> void:
		_call_apply_shop_entry_cards(shop_entry_card_count)
	)

func _attempt_purchase(price: int, on_success: Callable, fail_reason: String = "gold", fail_text: String = "Not enough gold.") -> void:
	if _call_can_afford(price):
		_call_spend_gold(price)
		if on_success.is_valid():
			on_success.call()
		_call_update_labels()
		purchase_completed.emit()
	else:
		_call_set_info(fail_text)
		purchase_failed.emit(fail_reason)

func _add_shop_buff_button(text: String, pressed_action: Callable, is_disabled: bool = false, tooltip_text: String = "") -> Button:
	var button := Button.new()
	button.text = text
	if is_disabled:
		button.disabled = true
		if tooltip_text != "":
			button.tooltip_text = tooltip_text
	if pressed_action.is_valid():
		button.pressed.connect(pressed_action)
	App.apply_neutral_button_style(button)
	App.bind_button_feedback(button)
	shop_buffs_buttons.add_child(button)
	return button

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

func _call_get_starting_hand_size() -> int:
	if callbacks.has("get_starting_hand_size") and callbacks.get_starting_hand_size.is_valid():
		return int(callbacks.get_starting_hand_size.call())
	return 0

func _call_apply_vitality(max_bonus: int, heal: int) -> int:
	if callbacks.has("apply_vitality") and callbacks.apply_vitality.is_valid():
		return int(callbacks.apply_vitality.call(max_bonus, heal))
	return 0

func _call_apply_max_energy(bonus: int) -> int:
	if callbacks.has("apply_max_energy") and callbacks.apply_max_energy.is_valid():
		return int(callbacks.apply_max_energy.call(bonus))
	return 0

func _call_get_max_energy_bonus() -> int:
	if callbacks.has("get_max_energy_bonus") and callbacks.get_max_energy_bonus.is_valid():
		return int(callbacks.get_max_energy_bonus.call())
	return 0

func _call_apply_paddle_width(bonus: float) -> float:
	if callbacks.has("apply_paddle_width") and callbacks.apply_paddle_width.is_valid():
		return float(callbacks.apply_paddle_width.call(bonus))
	return 0.0

func _call_apply_paddle_speed(bonus_percent: float) -> float:
	if callbacks.has("apply_paddle_speed") and callbacks.apply_paddle_speed.is_valid():
		return float(callbacks.apply_paddle_speed.call(bonus_percent))
	return 0.0

func _call_apply_reserve_ball(bonus: int) -> int:
	if callbacks.has("apply_reserve_ball") and callbacks.apply_reserve_ball.is_valid():
		return int(callbacks.apply_reserve_ball.call(bonus))
	return 0

func _call_get_reserve_ball_bonus() -> int:
	if callbacks.has("get_reserve_ball_bonus") and callbacks.get_reserve_ball_bonus.is_valid():
		return int(callbacks.get_reserve_ball_bonus.call())
	return 0

func _call_apply_shop_discount(percent: float) -> void:
	if callbacks.has("apply_shop_discount") and callbacks.apply_shop_discount.is_valid():
		callbacks.apply_shop_discount.call(percent)

func _call_apply_shop_entry_cards(amount: int) -> int:
	if callbacks.has("apply_shop_entry_cards") and callbacks.apply_shop_entry_cards.is_valid():
		return int(callbacks.apply_shop_entry_cards.call(amount))
	return 0

func _call_refresh_shop_buttons() -> void:
	if callbacks.has("refresh_shop_buttons") and callbacks.refresh_shop_buttons.is_valid():
		callbacks.refresh_shop_buttons.call()

func _call_refresh_mod_buttons() -> void:
	if callbacks.has("refresh_mod_buttons") and callbacks.refresh_mod_buttons.is_valid():
		callbacks.refresh_mod_buttons.call()
