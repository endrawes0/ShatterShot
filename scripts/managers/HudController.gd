extends Node
class_name HudController

var energy_label: Label
var deck_label: Label
var deck_count_label: Label
var discard_label: Label
var discard_count_label: Label
var hp_label: Label
var gold_label: Label
var shop_gold_label: Label
var threat_label: Label
var floor_label: Label

var map_panel: Panel
var reward_panel: Panel
var shop_panel: Panel
var deck_panel: Panel
var gameover_panel: Panel

var hand_container: Container

var card_data: Dictionary = {}
var card_type_colors: Dictionary = {}
var card_button_size: Vector2 = Vector2(110, 154)
var card_art_textures: Dictionary = {}

func setup(hud_nodes: Dictionary, data: Dictionary, type_colors: Dictionary, button_size: Vector2, art_textures: Dictionary) -> void:
	energy_label = hud_nodes.get("energy_label")
	deck_label = hud_nodes.get("deck_label")
	deck_count_label = hud_nodes.get("deck_count_label")
	discard_label = hud_nodes.get("discard_label")
	discard_count_label = hud_nodes.get("discard_count_label")
	hp_label = hud_nodes.get("hp_label")
	gold_label = hud_nodes.get("gold_label")
	shop_gold_label = hud_nodes.get("shop_gold_label")
	threat_label = hud_nodes.get("threat_label")
	floor_label = hud_nodes.get("floor_label")
	map_panel = hud_nodes.get("map_panel")
	reward_panel = hud_nodes.get("reward_panel")
	shop_panel = hud_nodes.get("shop_panel")
	deck_panel = hud_nodes.get("deck_panel")
	gameover_panel = hud_nodes.get("gameover_panel")
	hand_container = hud_nodes.get("hand_container")
	card_data = data
	card_type_colors = type_colors
	card_button_size = button_size
	card_art_textures = art_textures

func hide_all_panels() -> void:
	if map_panel:
		map_panel.visible = false
	if reward_panel:
		reward_panel.visible = false
	if shop_panel:
		shop_panel.visible = false
	if deck_panel:
		deck_panel.visible = false
	if gameover_panel:
		gameover_panel.visible = false

func update_labels(energy: int, max_energy: int, draw_count: int, discard_count: int, hp: int, max_hp: int, gold: int, threat: int, floor_index: int, max_floors: int) -> void:
	if energy_label:
		energy_label.text = "Energy: %d/%d" % [energy, max_energy]
	if deck_label:
		deck_label.text = "Draw: %d" % draw_count
	if deck_count_label:
		deck_count_label.text = "%d" % draw_count
	if discard_label:
		discard_label.text = "Discard: %d" % discard_count
	if discard_count_label:
		discard_count_label.text = "%d" % discard_count
	if hp_label:
		hp_label.text = "HP: %d/%d" % [hp, max_hp]
	if gold_label:
		gold_label.text = "Gold: %d" % gold
	if shop_gold_label:
		shop_gold_label.text = "Gold: %d" % gold
	if threat_label:
		threat_label.text = "Threat: %d" % threat
	if floor_label:
		var display_floor: int = min(max(1, floor_index), max_floors)
		floor_label.text = "Floor %d/%d" % [display_floor, max_floors]

func refresh_hand(cards: Array[String], disabled: bool, on_pressed: Callable) -> void:
	if hand_container == null:
		return
	populate_card_container(hand_container, cards, on_pressed, disabled)

func populate_card_container(container: Container, cards: Array, on_pressed: Callable = Callable(), disabled: bool = false, columns: int = 0) -> void:
	_clear_container(container)
	var target_container: Container = container
	if columns > 0:
		var grid := GridContainer.new()
		grid.columns = columns
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		container.add_child(grid)
		target_container = grid
	for card_id in cards:
		var selected_card_id: String = String(card_id)
		var button := create_card_button(selected_card_id)
		button.disabled = disabled
		if on_pressed.is_valid():
			button.pressed.connect(func() -> void:
				on_pressed.call(selected_card_id)
			)
		target_container.add_child(button)

func create_card_button(card_id: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = _card_tooltip(card_id)
	button.clip_text = false
	_apply_card_style(button, card_id)
	_apply_card_button_size(button)

	var layout := VBoxContainer.new()
	layout.name = "CardLayout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 6.0
	layout.offset_top = 6.0
	layout.offset_right = -6.0
	layout.offset_bottom = -6.0
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	layout.add_theme_constant_override("separation", 4)
	button.add_child(layout)

	var name_frame := Control.new()
	name_frame.name = "NameFrame"
	name_frame.custom_minimum_size = Vector2(0.0, 20.0)
	name_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(name_frame)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = _card_label(card_id)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_frame.add_child(name_label)

	var art_frame := Control.new()
	art_frame.name = "ArtFrame"
	art_frame.custom_minimum_size = Vector2(card_button_size.x - 12.0, 70.0)
	art_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(art_frame)

	var art := TextureRect.new()
	art.name = "Art"
	art.texture = _get_card_art(card_id)
	art.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art)

	var desc_frame := Control.new()
	desc_frame.name = "DescFrame"
	desc_frame.custom_minimum_size = Vector2(0.0, 44.0)
	desc_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(desc_frame)

	var desc_label := Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = card_data[card_id]["desc"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.add_theme_font_size_override("font_size", 8)
	desc_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_frame.add_child(desc_label)

	return button

func set_card_button_desc(button: Button, text: String) -> void:
	var layout: VBoxContainer = button.get_node("CardLayout") as VBoxContainer
	if layout == null:
		return
	var desc_label: Label = layout.get_node("DescFrame/DescLabel") as Label
	if desc_label:
		desc_label.text = text

func _card_label(card_id: String) -> String:
	var card: Dictionary = card_data[card_id]
	return "%s [%d]" % [card["name"], card["cost"]]

func _card_tooltip(card_id: String) -> String:
	var card: Dictionary = card_data[card_id]
	return "%s (Cost %d)\n%s" % [card["name"], card["cost"], card["desc"]]

func _apply_card_style(button: Button, card_id: String) -> void:
	var card: Dictionary = card_data[card_id]
	var card_type: String = card.get("type", "utility")
	if card_type_colors.has(card_type):
		var color: Color = card_type_colors[card_type]
		color.a = 1.0
		button.modulate = Color(1, 1, 1, 1)
		button.self_modulate = color

func _apply_card_button_size(button: Button) -> void:
	button.custom_minimum_size = card_button_size

func _get_card_art(card_id: String) -> Texture2D:
	if card_art_textures.has(card_id):
		return card_art_textures[card_id]
	return card_art_textures["twin"]

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
