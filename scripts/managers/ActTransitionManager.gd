extends Node
class_name ActTransitionManager

enum Step { NONE, BUFF, TREASURE, REST, SHOP }

const DEFAULT_FADE_SECONDS: float = 4.0
const DEFAULT_PAUSE_SECONDS: float = 4.0
const DEFAULT_BUFF_CHOICES: int = 3

var _main: Node = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _pending: bool = false
var _step: int = Step.NONE
var _prev_plan: Dictionary = {}
var _next_plan: Dictionary = {}
var _map_label_override_act_index: int = -1

var _update_labels: Callable = Callable()
var _hide_all_panels: Callable = Callable()
var _show_treasure_panel: Callable = Callable()
var _show_single_panel: Callable = Callable()
var _show_shop: Callable = Callable()
var _transition_event: Callable = Callable()
var _update_volley_prompt_visibility: Callable = Callable()
var _clear_map_buttons: Callable = Callable()

var _treasure_panel: Control = null
var _treasure_label: Label = null
var _treasure_rewards_container: Node = null
var _treasure_continue_button: Button = null

var _hud: CanvasLayer = null
var _map_panel: Panel = null
var _map_graph: Control = null
var _map_label: Label = null

var _shop_leave_button: Button = null
var _shop_label: Label = null
var _shop_info_label: Label = null

var _fade_overlay: ColorRect = null

func setup(
		main: Node,
		rng: RandomNumberGenerator,
		ui: Dictionary,
		hooks: Dictionary
	) -> void:
	_main = main
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_hud = ui.get("hud") as CanvasLayer
	_treasure_panel = ui.get("treasure_panel") as Control
	_treasure_label = ui.get("treasure_label") as Label
	_treasure_rewards_container = ui.get("treasure_rewards") as Node
	_treasure_continue_button = ui.get("treasure_continue_button") as Button
	_map_panel = ui.get("map_panel") as Panel
	_map_graph = ui.get("map_graph") as Control
	_map_label = ui.get("map_label") as Label

	_shop_leave_button = ui.get("shop_leave_button") as Button
	_shop_label = ui.get("shop_label") as Label
	_shop_info_label = ui.get("shop_info_label") as Label

	_update_labels = hooks.get("update_labels", Callable())
	_hide_all_panels = hooks.get("hide_all_panels", Callable())
	_show_treasure_panel = hooks.get("show_treasure_panel", Callable())
	_show_single_panel = hooks.get("show_single_panel", Callable())
	_show_shop = hooks.get("show_shop", Callable())
	_transition_event = hooks.get("transition_event", Callable())
	_update_volley_prompt_visibility = hooks.get("update_volley_prompt_visibility", Callable())
	_clear_map_buttons = hooks.get("clear_map_buttons", Callable())

	_ensure_fade_overlay()

func queue_sequence(prev_plan: Dictionary, next_plan: Dictionary) -> void:
	_prev_plan = prev_plan.duplicate(true) if prev_plan != null else {}
	_next_plan = next_plan.duplicate(true) if next_plan != null else {}
	_pending = true

func has_pending() -> bool:
	return _pending

func maybe_start_sequence() -> bool:
	if not _pending:
		return false
	_pending = false
	_step = Step.BUFF
	_show_buff_choice()
	return true

func current_step() -> int:
	return _step

func map_label_override_act_index() -> int:
	return _map_label_override_act_index

func handle_treasure_continue() -> bool:
	if _step != Step.TREASURE:
		return false
	_step = Step.REST
	call_deferred("_run_rest_transition")
	return true

func handle_shop_continue() -> bool:
	if _step != Step.SHOP:
		return false
	_step = Step.NONE
	_map_label_override_act_index = -1
	if _shop_leave_button != null:
		_shop_leave_button.text = "Leave"
	if _transition_event.is_valid():
		_transition_event.call("go_to_map")
	return true

func _clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

func _get_cfg_value(cfg: Dictionary, key: String, fallback):
	return cfg.get(key, fallback) if cfg != null else fallback

func _buff_candidates() -> Array[Dictionary]:
	if _main == null:
		return []
	var options: Array[Dictionary] = []

	var shop_upgrade_hand_bonus: int = int(_main.shop_upgrade_hand_bonus)
	var shop_max_hand_size: int = int(_main.shop_max_hand_size)
	var starting_hand_size: int = int(_main.starting_hand_size)
	options.append({
		"id": "upgrade_hand",
		"text": "Upgrade starting hand (+%d)" % shop_upgrade_hand_bonus,
		"enabled": shop_upgrade_hand_bonus > 0 and (shop_max_hand_size <= 0 or starting_hand_size < shop_max_hand_size)
	})

	var shop_vitality_max_hp_bonus: int = int(_main.shop_vitality_max_hp_bonus)
	var shop_vitality_heal: int = int(_main.shop_vitality_heal)
	options.append({
		"id": "vitality",
		"text": "Vitality (+%d max HP, heal %d)" % [shop_vitality_max_hp_bonus, shop_vitality_heal],
		"enabled": shop_vitality_max_hp_bonus > 0 or shop_vitality_heal > 0
	})

	var shop_energy_bonus: int = int(_main.shop_energy_bonus)
	var max_energy_bonus: int = int(_main.max_energy_bonus)
	options.append({
		"id": "surge",
		"text": "Surge (+%d max energy)" % shop_energy_bonus,
		"enabled": shop_energy_bonus > 0 and max_energy_bonus < 2
	})

	var shop_paddle_width_bonus: float = float(_main.shop_paddle_width_bonus)
	options.append({
		"id": "paddle_width",
		"text": "Wider Paddle (+%d width)" % int(round(shop_paddle_width_bonus)),
		"enabled": shop_paddle_width_bonus > 0.0
	})

	var shop_paddle_speed_bonus_percent: float = float(_main.shop_paddle_speed_bonus_percent)
	options.append({
		"id": "paddle_speed",
		"text": "Paddle Speed (+%d%%)" % int(round(shop_paddle_speed_bonus_percent)),
		"enabled": shop_paddle_speed_bonus_percent > 0.0
	})

	var shop_reserve_ball_bonus: int = int(_main.shop_reserve_ball_bonus)
	var volley_ball_bonus_base: int = int(_main.volley_ball_bonus_base)
	options.append({
		"id": "reserve_ball",
		"text": "Reserve Ball (+%d per volley)" % shop_reserve_ball_bonus,
		"enabled": shop_reserve_ball_bonus > 0 and volley_ball_bonus_base < 1
	})

	var shop_discount_percent: float = float(_main.shop_discount_percent)
	options.append({
		"id": "shop_discount",
		"text": "Shop Discount (-%d%% prices)" % int(round(shop_discount_percent)),
		"enabled": shop_discount_percent > 0.0
	})

	var shop_entry_card_count: int = int(_main.shop_entry_card_count)
	options.append({
		"id": "shop_scribe",
		"text": "Shop Scribe (+%d card on entry)" % shop_entry_card_count,
		"enabled": shop_entry_card_count > 0
	})

	return options

func apply_rest_rewards() -> void:
	if _main == null:
		return
	_main.hp = int(_main.max_hp)
	var removed: int = 0
	var deck_manager: Object = _main.deck_manager
	if deck_manager == null:
		return
	var wound_instance_ids: Array[int] = []
	for card in deck_manager.deck:
		if card is Dictionary and String(card.get("card_id", "")) == "wound":
			wound_instance_ids.append(int(card.get("id", -1)))
	for instance_id in wound_instance_ids:
		if removed >= 5:
			break
		deck_manager.remove_card_instance_from_all(instance_id, true)
		removed += 1

func _apply_buff(buff_id: String) -> void:
	if _main == null:
		return
	match buff_id:
		"upgrade_hand":
			_main._upgrade_starting_hand(int(_main.shop_upgrade_hand_bonus))
		"vitality":
			_main._apply_vitality(int(_main.shop_vitality_max_hp_bonus), int(_main.shop_vitality_heal))
		"surge":
			_main._apply_max_energy_buff(int(_main.shop_energy_bonus))
		"paddle_width":
			_main._apply_paddle_width_buff(float(_main.shop_paddle_width_bonus))
		"paddle_speed":
			_main._apply_paddle_speed_buff(float(_main.shop_paddle_speed_bonus_percent))
		"reserve_ball":
			_main._apply_reserve_ball_buff(int(_main.shop_reserve_ball_bonus))
		"shop_discount":
			_main._apply_shop_discount(float(_main.shop_discount_percent))
		"shop_scribe":
			_main._apply_shop_entry_cards(int(_main.shop_entry_card_count))

func _roll_buffs(count: int) -> Array[Dictionary]:
	var candidates := _buff_candidates()
	var enabled: Array[Dictionary] = []
	for option in candidates:
		if bool(option.get("enabled", true)):
			enabled.append(option)
	var picked: Array[Dictionary] = []
	if enabled.is_empty():
		return picked
	var target: int = min(count, enabled.size())
	while picked.size() < target:
		var idx: int = _rng.randi_range(0, enabled.size() - 1)
		picked.append(enabled.pop_at(idx))
	return picked

func _show_buff_choice() -> void:
	if _hide_all_panels.is_valid():
		_hide_all_panels.call()
	if _show_single_panel.is_valid() and _treasure_panel != null:
		_show_single_panel.call(_treasure_panel)
	if _treasure_label != null:
		_treasure_label.text = "Act Rewards: Buff"
	if _treasure_continue_button != null:
		_treasure_continue_button.visible = false
	_clear_children(_treasure_rewards_container)

	var buffs := _roll_buffs(DEFAULT_BUFF_CHOICES)
	if buffs.is_empty():
		_step = Step.TREASURE
		_show_treasure_step()
		return
	for buff in buffs:
		var buff_id: String = String(buff.get("id", ""))
		var text: String = String(buff.get("text", buff_id))
		var button := Button.new()
		button.text = text
		button.pressed.connect(func() -> void:
			_apply_buff(buff_id)
			if _update_labels.is_valid():
				_update_labels.call()
			_step = Step.TREASURE
			_show_treasure_step()
		)
		App.apply_neutral_button_style(button)
		App.bind_button_feedback(button)
		if _treasure_rewards_container != null:
			_treasure_rewards_container.add_child(button)

func _show_treasure_step() -> void:
	if _hide_all_panels.is_valid():
		_hide_all_panels.call()
	if _show_treasure_panel.is_valid():
		_show_treasure_panel.call(true)
	if _treasure_label != null:
		_treasure_label.text = "Act Rewards: Treasure"
	if _treasure_continue_button != null:
		_treasure_continue_button.text = "Continue"
		_treasure_continue_button.visible = true

func _run_rest_transition() -> void:
	var fade_seconds: float = DEFAULT_FADE_SECONDS
	var pause_seconds: float = DEFAULT_PAUSE_SECONDS

	App.stop_menu_music()
	App.stop_combat_music()
	App.stop_shop_music()
	App.start_rest_music()

	if not _prev_plan.is_empty():
		_show_map_preview_from_plan(_prev_plan)
	else:
		_map_label_override_act_index = -1
		if _hide_all_panels.is_valid():
			_hide_all_panels.call()

	await _fade_overlay_to(1.0, fade_seconds)

	apply_rest_rewards()
	if _update_labels.is_valid():
		_update_labels.call()

	await get_tree().create_timer(pause_seconds).timeout

	if not _next_plan.is_empty():
		_show_map_preview_from_plan(_next_plan)
	else:
		_map_label_override_act_index = -1

	await _fade_overlay_to(0.0, fade_seconds)

	_step = Step.SHOP
	_enter_shop_step()

func _enter_shop_step() -> void:
	if _show_shop.is_valid():
		_show_shop.call()
	if _shop_label != null:
		_shop_label.text = "Act Rewards: Shop"
	if _shop_info_label != null:
		_shop_info_label.text = "Spend gold, then continue."
	if _shop_leave_button != null:
		_shop_leave_button.visible = true
		_shop_leave_button.text = "Continue"
	if _update_volley_prompt_visibility.is_valid():
		_update_volley_prompt_visibility.call()

func _show_map_preview_from_plan(plan: Dictionary) -> void:
	if _map_panel == null:
		return
	if _hide_all_panels.is_valid():
		_hide_all_panels.call()
	_map_panel.visible = true
	if _clear_map_buttons.is_valid():
		_clear_map_buttons.call()
	if _map_graph != null and _map_graph.has_method("set_plan"):
		var no_choices: Array[Dictionary] = []
		_map_graph.call("set_plan", plan, no_choices)
	_map_label_override_act_index = int(plan.get("active_act_index", -1))
	if _map_label != null and _map_label_override_act_index >= 0:
		_map_label.text = "Act %d Map" % (_map_label_override_act_index + 1)

func _ensure_fade_overlay() -> void:
	if _fade_overlay != null:
		return
	if _hud == null:
		return
	var overlay := ColorRect.new()
	overlay.name = "FadeOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.top_level = true
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.visible = false
	_hud.add_child(overlay)
	overlay.z_index = 1000
	_fade_overlay = overlay
	_sync_fade_overlay_rect()

func _sync_fade_overlay_rect() -> void:
	if _fade_overlay == null:
		return
	_fade_overlay.position = Vector2.ZERO
	_fade_overlay.size = get_viewport_rect().size

func _fade_overlay_to(alpha: float, duration: float) -> void:
	_ensure_fade_overlay()
	if _fade_overlay == null:
		return
	_fade_overlay.visible = true
	_sync_fade_overlay_rect()
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color:a", clamp(alpha, 0.0, 1.0), max(0.0, duration)) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if alpha <= 0.0 and _fade_overlay != null:
		_fade_overlay.visible = false
