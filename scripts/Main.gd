extends Node2D

enum GameState { MAP, PLANNING, VOLLEY, REWARD, SHOP, REST, GAME_OVER, VICTORY }

const CARD_TYPE_COLORS: Dictionary = {
	"offense": Color(1.0, 0.32, 0.02),
	"defense": Color(0.05, 0.5, 1.0),
	"utility": Color(0.98, 0.94, 0.08),
	"curse": Color(0.2, 0.2, 0.2)
}
const ROW_PALETTE: Array[Color] = [
	Color(0.86, 0.32, 0.26),
	Color(0.95, 0.60, 0.20),
	Color(0.95, 0.85, 0.25),
	Color(0.45, 0.78, 0.36),
	Color(0.26, 0.62, 0.96)
]

const CARD_BUTTON_SIZE: Vector2 = Vector2(110, 154)
const BASE_STARTING_HAND_SIZE: int = 4
const BALL_SPAWN_OFFSET: Vector2 = Vector2(0, -32)
const ENCOUNTER_CONFIG_DIR: String = "res://data/encounters"
const FLOOR_PLAN_PATH: String = "res://data/floor_plans/basic.tres"
const BALANCE_DATA_PATH: String = "res://data/balance/basic.tres"

@export var brick_size: Vector2 = Vector2(64, 24)
@export var brick_gap: Vector2 = Vector2(8, 8)
@export var top_margin: float = 70.0

@onready var paddle: CharacterBody2D = $Paddle
@onready var bricks_root: Node2D = $Bricks
@onready var hud: CanvasLayer = $HUD
@onready var hand_bar: Control = $HUD/HandBar
@onready var hand_container: HBoxContainer = $HUD/HandBar/HandContainer
@onready var energy_label: Label = $HUD/TopBar/EnergyLabel
@onready var deck_label: Label = $HUD/TopBar/DeckLabel
@onready var deck_stack: Control = $HUD/HandBar/DeckStack
@onready var discard_stack: Control = $HUD/HandBar/DiscardStack
@onready var discard_label: Label = $HUD/TopBar/DiscardLabel
@onready var hp_label: Label = $HUD/TopBar/HpLabel
@onready var gold_label: Label = $HUD/TopBar/GoldLabel
@onready var threat_label: Label = $HUD/TopBar/ThreatLabel
@onready var floor_label: Label = $HUD/TopBar/FloorLabel
@onready var info_label: Label = $HUD/InfoLabel
@onready var mods_panel: Panel = $HUD/ModsPanel
@onready var mods_buttons: VBoxContainer = $HUD/ModsPanel/ModsButtons
@onready var mods_persist_checkbox: CheckBox = $HUD/ModsPanel/ModsPersist
@onready var map_panel: Panel = $HUD/MapPanel
@onready var map_buttons: HBoxContainer = $HUD/MapPanel/MapButtons
@onready var reward_panel: Panel = $HUD/RewardPanel
@onready var reward_buttons: HBoxContainer = $HUD/RewardPanel/RewardLayout/RewardButtons
@onready var reward_skip_button: Button = $HUD/RewardPanel/RewardLayout/RewardSkipButton
@onready var shop_panel: Panel = $HUD/ShopPanel
@onready var shop_cards_buttons: Container = $HUD/ShopPanel/ShopLayout/CardsPanel/CardsButtons
@onready var shop_buffs_buttons: Container = $HUD/ShopPanel/ShopLayout/BuffsPanel/BuffsButtons
@onready var shop_ball_mods_buttons: Container = $HUD/ShopPanel/ShopLayout/BallModsPanel/BallModsButtons
@onready var shop_leave_button: Button = $HUD/ShopPanel/LeaveButton
@onready var shop_gold_label: Label = $HUD/ShopPanel/ShopGoldLabel
@onready var deck_panel: Panel = $HUD/DeckPanel
@onready var deck_list: VBoxContainer = $HUD/DeckPanel/DeckScroll/DeckList
@onready var deck_close_button: Button = $HUD/DeckPanel/DeckCloseButton
@onready var deck_button: Button = $HUD/HandBar/DeckStack/DeckButton
@onready var discard_button: Button = $HUD/HandBar/DiscardStack/DiscardButton
@onready var gameover_panel: Panel = $HUD/GameOverPanel
@onready var gameover_label: Label = $HUD/GameOverPanel/GameOverLabel
@onready var restart_button: Button = $HUD/GameOverPanel/RestartButton
@onready var menu_button: Button = $HUD/GameOverPanel/MenuButton
@onready var forfeit_dialog: ConfirmationDialog = $HUD/ForfeitDialog
@onready var left_wall: CollisionShape2D = $Walls/LeftWall
@onready var right_wall: CollisionShape2D = $Walls/RightWall
@onready var top_wall: CollisionShape2D = $Walls/TopWall

var brick_scene: PackedScene = preload("res://scenes/Brick.tscn")
var ball_scene: PackedScene = preload("res://scenes/Ball.tscn")
var card_art_textures: Dictionary = {}

var encounter_manager: EncounterManager
var map_manager: MapManager
var deck_manager: DeckManager
var hud_controller: HudController
var balance_data: Resource

var card_data: Dictionary = {}
var card_pool: Array[String] = []
var starting_deck: Array[String] = []
var ball_mod_data: Dictionary = {}
var ball_mod_order: Array[String] = []
var ball_mod_colors: Dictionary = {}
var shop_card_price: int = 0
var shop_remove_price: int = 0
var shop_upgrade_price: int = 0
var shop_upgrade_hand_bonus: int = 0
var shop_vitality_price: int = 0
var shop_vitality_max_hp_bonus: int = 0
var shop_vitality_heal: int = 0

var state: GameState = GameState.MAP

var max_hp: int = 150
var hp: int = 150
var gold: int = 0
var floor_index: int = 0
var max_combat_floors: int = 5
var max_floors: int = 6

var max_energy: int = 3
var energy: int = 3
var block: int = 0
var starting_hand_size: int = BASE_STARTING_HAND_SIZE
var ball_mod_counts: Dictionary = {}
var active_ball_mod: String = ""
var persist_ball_mods: bool = false

var volley_damage_bonus: int = 0
var volley_ball_bonus: int = 0
var volley_ball_reserve: int = 0
var volley_piercing: bool = false
var volley_ball_speed_multiplier: float = 1.0
var reserve_launch_cooldown: float = 0.0
enum ReturnPanel { NONE, MAP, REWARD, SHOP, GAMEOVER }

var base_paddle_half_width: float = 50.0
var paddle_buff_turns: int = 0
var base_paddle_speed: float = 420.0
var paddle_speed_buff_turns: int = 0
var paddle_speed_multiplier: float = 1.3

var active_balls: Array[Node] = []
var encounter_base_threat: int = 5
var encounter_hp: int = 1
var encounter_rows: int = 4
var encounter_cols: int = 8
var current_is_boss: bool = false
var current_pattern: String = "grid"
var encounter_speed_boost: bool = false
var deck_return_panel: int = ReturnPanel.NONE
var deck_return_info: String = ""

func _update_reserve_indicator() -> void:
	if paddle and paddle.has_method("set_reserve_count"):
		if state == GameState.PLANNING:
			paddle.set_reserve_count(volley_ball_bonus)
		else:
			paddle.set_reserve_count(volley_ball_reserve)

func _ready() -> void:
	randomize()
	balance_data = load(BALANCE_DATA_PATH)
	if balance_data == null:
		push_error("Missing balance data at %s" % BALANCE_DATA_PATH)
		return
	_apply_balance_data(balance_data)
	if get_viewport():
		get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()
	base_paddle_half_width = paddle.half_width
	base_paddle_speed = paddle.speed
	encounter_manager = EncounterManager.new()
	add_child(encounter_manager)
	encounter_manager.setup(bricks_root, brick_scene, brick_size, brick_gap, top_margin, ROW_PALETTE)
	encounter_manager.load_configs_from_dir(ENCOUNTER_CONFIG_DIR)
	map_manager = MapManager.new()
	add_child(map_manager)
	var floor_plan_resource := load(FLOOR_PLAN_PATH)
	if floor_plan_resource != null:
		map_manager.floor_plan = floor_plan_resource
	deck_manager = DeckManager.new()
	add_child(deck_manager)
	hud_controller = HudController.new()
	add_child(hud_controller)
	hud_controller.setup({
		"energy_label": energy_label,
		"deck_label": deck_label,
		"discard_label": discard_label,
		"deck_button": deck_button,
		"discard_button": discard_button,
		"hp_label": hp_label,
		"gold_label": gold_label,
		"shop_gold_label": shop_gold_label,
		"threat_label": threat_label,
		"floor_label": floor_label,
		"map_panel": map_panel,
		"reward_panel": reward_panel,
		"shop_panel": shop_panel,
		"deck_panel": deck_panel,
		"gameover_panel": gameover_panel,
		"hand_container": hand_container
	}, card_data, CARD_TYPE_COLORS, CARD_BUTTON_SIZE, card_art_textures)
	# Buttons removed; use Space to launch and cards/turn flow for control.
	if restart_button:
		restart_button.pressed.connect(_start_run)
	if menu_button:
		menu_button.pressed.connect(_go_to_menu)
	if forfeit_dialog:
		forfeit_dialog.confirmed.connect(_confirm_forfeit_volley)
	if deck_button:
		deck_button.pressed.connect(_show_deck_panel)
	if discard_button:
		discard_button.pressed.connect(_show_discard_panel)
	if deck_close_button:
		deck_close_button.pressed.connect(_close_deck_panel)
	if reward_skip_button:
		reward_skip_button.pressed.connect(_show_map)
	if shop_leave_button:
		shop_leave_button.pressed.connect(_show_map)
	if mods_persist_checkbox:
		mods_persist_checkbox.toggled.connect(func(pressed: bool) -> void:
			persist_ball_mods = pressed
		)
		_apply_persist_checkbox_style()
	_set_hud_tooltips()
	_start_run()

func _apply_balance_data(data: Resource) -> void:
	card_data = data.card_data
	card_pool = data.card_pool
	starting_deck = data.starting_deck
	ball_mod_data = data.ball_mod_data
	ball_mod_order = data.ball_mod_order
	ball_mod_colors = data.ball_mod_colors
	shop_card_price = data.shop_card_price
	shop_remove_price = data.shop_remove_price
	shop_upgrade_price = data.shop_upgrade_price
	shop_upgrade_hand_bonus = data.shop_upgrade_hand_bonus
	shop_vitality_price = data.shop_vitality_price
	shop_vitality_max_hp_bonus = data.shop_vitality_max_hp_bonus
	shop_vitality_heal = data.shop_vitality_heal
	card_art_textures.clear()
	for card_id in card_data.keys():
		var entry: Dictionary = card_data[card_id]
		var art_path: String = String(entry.get("art_path", ""))
		if art_path.is_empty():
			continue
		var texture := load(art_path)
		if texture:
			card_art_textures[card_id] = texture

func _fit_to_viewport() -> void:
	var size: Vector2 = get_viewport_rect().size
	paddle.global_position = Vector2(size.x * 0.5, size.y - 240.0)
	if paddle.has_method("set_locked_y"):
		paddle.set_locked_y(paddle.global_position.y)
	if left_wall and left_wall.shape is RectangleShape2D:
		var left_shape: RectangleShape2D = left_wall.shape as RectangleShape2D
		left_shape.size = Vector2(20.0, size.y + 200.0)
	if left_wall:
		left_wall.position = Vector2(-10.0, size.y * 0.5)
	if right_wall and right_wall.shape is RectangleShape2D:
		var right_shape: RectangleShape2D = right_wall.shape as RectangleShape2D
		right_shape.size = Vector2(20.0, size.y + 200.0)
	if right_wall:
		right_wall.position = Vector2(size.x + 10.0, size.y * 0.5)
	if top_wall and top_wall.shape is RectangleShape2D:
		var top_shape: RectangleShape2D = top_wall.shape as RectangleShape2D
		top_shape.size = Vector2(size.x + 40.0, 20.0)
	if top_wall:
		top_wall.position = Vector2(size.x * 0.5, -10.0)
	_center_bricks_in_viewport()

func _center_bricks_in_viewport() -> void:
	if bricks_root == null or bricks_root.get_child_count() == 0:
		return
	var half_w: float = brick_size.x * 0.5
	var half_h: float = brick_size.y * 0.5
	var min_x: float = INF
	var max_x: float = -INF
	for brick in bricks_root.get_children():
		if brick is Node2D:
			var pos: Vector2 = (brick as Node2D).position
			min_x = min(min_x, pos.x - half_w)
			max_x = max(max_x, pos.x + half_w)
	if min_x == INF or max_x == -INF:
		return
	var center_x: float = (min_x + max_x) * 0.5
	var target_x: float = get_viewport_rect().size.x * 0.5
	var offset_x: float = target_x - center_x
	if absf(offset_x) < 0.5:
		return
	for brick in bricks_root.get_children():
		if brick is Node2D:
			(brick as Node2D).position.x += offset_x

func _set_hud_tooltips() -> void:
	energy_label.mouse_filter = Control.MOUSE_FILTER_STOP
	energy_label.tooltip_text = "Energy is spent to play cards each turn."
	deck_label.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_label.tooltip_text = "Cards left in your draw pile."
	if deck_button:
		deck_button.tooltip_text = "View your deck."
	discard_label.mouse_filter = Control.MOUSE_FILTER_STOP
	discard_label.tooltip_text = "Cards that were played this fight."
	hp_label.mouse_filter = Control.MOUSE_FILTER_STOP
	hp_label.tooltip_text = "Your health. If it reaches 0, the run ends."
	gold_label.mouse_filter = Control.MOUSE_FILTER_STOP
	gold_label.tooltip_text = "Spend gold at shops."
	threat_label.mouse_filter = Control.MOUSE_FILTER_STOP
	threat_label.tooltip_text = "Incoming damage if you end the turn without clearing."
	floor_label.mouse_filter = Control.MOUSE_FILTER_STOP
	floor_label.tooltip_text = "Current room in the run."
	info_label.mouse_filter = Control.MOUSE_FILTER_STOP
	info_label.tooltip_text = "Status and prompts for the current room."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		App.show_menu()
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event: InputEventKey = event
		if key_event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			if state == GameState.VOLLEY and active_balls.is_empty() and volley_ball_reserve > 0:
				_prompt_forfeit_volley()
				return
	if state == GameState.PLANNING and event.is_action_pressed("ui_accept"):
		_launch_volley()
	if state == GameState.VOLLEY and event.is_action_pressed("ui_select") and active_balls.is_empty() and volley_ball_reserve > 0:
		_prompt_forfeit_volley()
	if state == GameState.VOLLEY and event.is_action_pressed("ui_accept") and reserve_launch_cooldown <= 0.0:
		if event is InputEventKey:
			var launch_key: InputEventKey = event
			if launch_key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
				return
		_launch_reserve_ball()
	if state == GameState.PLANNING and event.is_action_pressed("ui_select"):
		_end_turn()

func _process(delta: float) -> void:
	if reserve_launch_cooldown > 0.0:
		reserve_launch_cooldown = max(0.0, reserve_launch_cooldown - delta)

func _start_run() -> void:
	hp = max_hp
	gold = 60
	floor_index = 0
	current_is_boss = false
	starting_hand_size = BASE_STARTING_HAND_SIZE
	ball_mod_counts.clear()
	active_ball_mod = ""
	persist_ball_mods = false
	if mods_persist_checkbox:
		mods_persist_checkbox.button_pressed = false
	active_balls.clear()
	for child in bricks_root.get_children():
		child.queue_free()
	deck_manager.setup(starting_deck)
	map_manager.reset_run()
	var start_room := map_manager.get_start_room_choice()
	if start_room.is_empty():
		floor_index = 1
		_start_encounter(false)
		return
	map_manager.advance_to_room(String(start_room.get("id", "")))
	_enter_room(String(start_room.get("type", "combat")))

func _show_map() -> void:
	state = GameState.MAP
	hud_controller.hide_all_panels()
	map_panel.visible = true
	_build_map_buttons()
	var display_floor: int = min(floor_index + 1, max_floors)
	floor_label.text = "Floor %d/%d" % [display_floor, max_floors]

func _apply_persist_checkbox_style() -> void:
	if mods_persist_checkbox == null:
		return
	var size: int = 16
	var border: Color = Color(0, 0, 0, 1)
	var fill: Color = Color(1, 1, 1, 1)
	var unchecked := Image.create(size, size, false, Image.FORMAT_RGBA8)
	unchecked.fill(fill)
	for i in range(size):
		unchecked.set_pixel(i, 0, border)
		unchecked.set_pixel(i, size - 1, border)
		unchecked.set_pixel(0, i, border)
		unchecked.set_pixel(size - 1, i, border)
	var checked := unchecked.duplicate()
	for i in range(3, 12):
		checked.set_pixel(i, i, border)
		checked.set_pixel(i, size - 1 - i, border)
		checked.set_pixel(i, i + 1, border)
		checked.set_pixel(i, size - 2 - i, border)
	var unchecked_tex := ImageTexture.create_from_image(unchecked)
	var checked_tex := ImageTexture.create_from_image(checked)
	mods_persist_checkbox.add_theme_icon_override("unchecked", unchecked_tex)
	mods_persist_checkbox.add_theme_icon_override("checked", checked_tex)

func _build_map_buttons() -> void:
	for child in map_buttons.get_children():
		child.queue_free()
	var choices: Array[Dictionary] = map_manager.build_room_choices(floor_index, max_combat_floors)
	for choice in choices:
		var room_type: String = String(choice.get("type", "combat"))
		var room_id: String = String(choice.get("id", ""))
		var selected_room_type := room_type
		var selected_room_id := room_id
		var button := Button.new()
		button.text = map_manager.room_label(selected_room_type)
		button.pressed.connect(func() -> void:
			map_manager.advance_to_room(selected_room_id)
			_enter_room(selected_room_type)
		)
		map_buttons.add_child(button)

func _enter_room(room_type: String) -> void:
	if room_type == "victory":
		_show_victory()
		return
	match room_type:
		"rest":
			_show_rest()
		"shop":
			_show_shop()
		"elite":
			floor_index += 1
			_start_encounter(true)
		"boss":
			floor_index += 1
			_start_boss()
		_:
			floor_index += 1
			_start_encounter(false)

func _start_encounter(is_elite: bool) -> void:
	state = GameState.PLANNING
	hud_controller.hide_all_panels()
	info_label.text = "Plan your volley, then launch."
	_clear_active_balls()
	current_is_boss = false
	var config := encounter_manager.build_config_from_floor(floor_index, is_elite, false)
	current_pattern = config.pattern_id
	encounter_speed_boost = config.speed_boost
	encounter_rows = config.rows
	encounter_cols = config.cols
	encounter_hp = config.base_hp
	encounter_base_threat = config.base_threat
	if encounter_speed_boost:
		info_label.text = "Volley Mod: Speed Boost."
	encounter_manager.start_encounter(config, Callable(self, "_on_brick_destroyed"), Callable(self, "_on_brick_damaged"))
	_start_turn()

func _start_boss() -> void:
	state = GameState.PLANNING
	hud_controller.hide_all_panels()
	info_label.text = "Boss fight. Plan carefully."
	_clear_active_balls()
	current_is_boss = true
	var config := encounter_manager.build_config_from_floor(floor_index, false, true)
	current_pattern = config.pattern_id
	encounter_speed_boost = config.speed_boost
	encounter_rows = config.rows
	encounter_cols = config.cols
	encounter_hp = config.base_hp
	encounter_base_threat = config.base_threat
	encounter_manager.start_encounter(config, Callable(self, "_on_brick_destroyed"), Callable(self, "_on_brick_damaged"))
	_start_turn()

func _start_turn() -> void:
	state = GameState.PLANNING
	energy = max_energy
	block = 0
	volley_damage_bonus = 0
	volley_ball_bonus = 0
	volley_ball_reserve = 0
	_update_reserve_indicator()
	volley_piercing = false
	volley_ball_speed_multiplier = 1.0
	_apply_paddle_buffs()
	deck_manager.draw_cards(starting_hand_size)
	_refresh_hand()
	_refresh_mod_buttons()
	_update_labels()

func _end_turn() -> void:
	if state != GameState.PLANNING:
		return
	_discard_hand()
	var incoming: int = max(0, encounter_manager.calculate_threat(encounter_base_threat) - block)
	hp -= incoming
	info_label.text = "You take %d damage." % incoming
	if hp <= 0:
		_show_game_over()
		return
	_start_turn()

func _launch_volley() -> void:
	if state != GameState.PLANNING:
		return
	state = GameState.VOLLEY
	var total_balls: int = 1 + volley_ball_bonus
	volley_ball_reserve = max(0, total_balls - 1)
	_update_reserve_indicator()
	reserve_launch_cooldown = 0.1
	_spawn_volley_ball()
	info_label.text = "Volley in motion."

func _launch_reserve_ball() -> void:
	if state != GameState.VOLLEY:
		return
	if volley_ball_reserve <= 0:
		return
	volley_ball_reserve -= 1
	_update_reserve_indicator()
	_spawn_volley_ball()
	info_label.text = "Extra ball launched."

func _spawn_volley_ball() -> void:
	var ball: CharacterBody2D = ball_scene.instantiate() as CharacterBody2D
	ball.paddle_path = NodePath("../Paddle")
	ball.damage = 1 + volley_damage_bonus
	ball.piercing = volley_piercing
	var speed_multiplier: float = volley_ball_speed_multiplier
	if encounter_speed_boost:
		speed_multiplier *= 1.25
	ball.speed *= speed_multiplier
	if ball.has_method("set_mod_colors"):
		ball.set_mod_colors(ball_mod_colors)
	if ball.has_method("set_ball_mod"):
		ball.set_ball_mod(active_ball_mod)
	else:
		ball.ball_mod = active_ball_mod
	add_child(ball)
	ball.global_position = paddle.global_position + BALL_SPAWN_OFFSET
	ball.launch_with_angle(0.0)
	ball.lost.connect(_on_ball_lost)
	ball.mod_consumed.connect(_on_ball_mod_consumed)
	active_balls.append(ball)

func _on_ball_lost(ball: Node) -> void:
	active_balls.erase(ball)
	if is_instance_valid(ball):
		ball.queue_free()
	encounter_manager.regen_bricks_on_drop()
	if active_balls.is_empty():
		if encounter_manager.check_victory():
			_end_encounter()
			return
		if volley_ball_reserve > 0:
			info_label.text = "Press Space to launch the next ball or Enter to end the volley."
			return
		_apply_volley_threat()

func _forfeit_volley() -> void:
	if state != GameState.VOLLEY:
		return
	if not active_balls.is_empty():
		return
	if volley_ball_reserve <= 0:
		return
	volley_ball_reserve = 0
	_update_reserve_indicator()
	_apply_volley_threat()

func _prompt_forfeit_volley() -> void:
	if forfeit_dialog == null:
		_forfeit_volley()
		return
	forfeit_dialog.popup_centered()

func _confirm_forfeit_volley() -> void:
	_forfeit_volley()

func _apply_volley_threat() -> void:
	var threat: int = 0
	if encounter_manager:
		threat = encounter_manager.calculate_threat(encounter_base_threat)
	hp -= threat
	if hp <= 0:
		_show_game_over()
		return
	info_label.text = "Ball lost. You take %d damage." % threat
	_start_turn()

func _on_ball_mod_consumed(mod_id: String) -> void:
	if active_ball_mod != mod_id:
		return
	if ball_mod_counts.has(mod_id):
		ball_mod_counts[mod_id] = max(0, int(ball_mod_counts[mod_id]) - 1)
	if _is_persist_enabled() and int(ball_mod_counts.get(mod_id, 0)) > 0:
		active_ball_mod = mod_id
	else:
		active_ball_mod = ""
	_apply_ball_mod_to_active_balls()
	_refresh_mod_buttons()

func _end_encounter() -> void:
	hud_controller.hide_all_panels()
	_clear_active_balls()
	if current_is_boss:
		_show_victory()
		return
	state = GameState.REWARD
	reward_panel.visible = true
	gold += 25
	info_label.text = "Room cleared. Choose a reward."
	_build_reward_buttons()
	_update_labels()

func _build_reward_buttons() -> void:
	for child in reward_buttons.get_children():
		child.queue_free()
	for _i in range(3):
		var card_id: String = card_pool.pick_random()
		var reward_card_id := card_id
		var button := hud_controller.create_card_button(card_id)
		button.pressed.connect(func() -> void:
			_add_card_to_deck(reward_card_id)
			_show_map()
		)
		reward_buttons.add_child(button)

func _show_shop() -> void:
	state = GameState.SHOP
	_show_single_panel(shop_panel)
	info_label.text = ""
	_build_shop_buttons()
	_refresh_mod_buttons()
	_update_labels()

func _build_shop_buttons() -> void:
	if shop_cards_buttons == null or shop_buffs_buttons == null or shop_ball_mods_buttons == null:
		return
	_clear_shop_buttons()
	_build_shop_card_buttons()
	_build_shop_buff_buttons()
	_build_shop_mod_buttons()

func _clear_shop_buttons() -> void:
	for child in shop_cards_buttons.get_children():
		child.queue_free()
	for child in shop_buffs_buttons.get_children():
		child.queue_free()
	for child in shop_ball_mods_buttons.get_children():
		child.queue_free()

func _build_shop_card_buttons() -> void:
	for _i in range(2):
		var card_id: String = card_pool.pick_random()
		var shop_card_id := card_id
		var button := hud_controller.create_card_button(card_id)
		hud_controller.set_card_button_desc(button, "%s\nPrice: %dg" % [card_data[card_id]["desc"], shop_card_price])
		button.pressed.connect(func() -> void:
			if gold >= shop_card_price:
				gold -= shop_card_price
				_add_card_to_deck(shop_card_id)
				_show_map()
			else:
				info_label.text = "Not enough gold."
		)
		shop_cards_buttons.add_child(button)
	var remove := Button.new()
	remove.text = "Remove a card (%dg)" % shop_remove_price
	remove.pressed.connect(func() -> void:
		if gold >= shop_remove_price and deck_manager.deck.size() > 0:
			gold -= shop_remove_price
			_update_labels()
			_show_remove_card_panel()
		else:
			info_label.text = "Cannot remove."
	)
	shop_cards_buttons.add_child(remove)

func _build_shop_buff_buttons() -> void:
	var upgrade := Button.new()
	upgrade.text = "Upgrade starting hand (+%d) (%dg)" % [shop_upgrade_hand_bonus, shop_upgrade_price]
	upgrade.pressed.connect(func() -> void:
		if gold >= shop_upgrade_price:
			gold -= shop_upgrade_price
			starting_hand_size += shop_upgrade_hand_bonus
			info_label.text = "Starting hand increased to %d." % starting_hand_size
			_show_map()
		else:
			info_label.text = "Not enough gold."
	)
	shop_buffs_buttons.add_child(upgrade)

	var vitality_buff := Button.new()
	vitality_buff.text = "Vitality (+%d max HP, heal %d) (%dg)" % [
		shop_vitality_max_hp_bonus,
		shop_vitality_heal,
		shop_vitality_price
	]
	vitality_buff.pressed.connect(func() -> void:
		if gold >= shop_vitality_price:
			gold -= shop_vitality_price
			max_hp += shop_vitality_max_hp_bonus
			hp = min(max_hp, hp + shop_vitality_heal)
			info_label.text = "Max HP increased to %d." % max_hp
			_update_labels()
			_show_map()
		else:
			info_label.text = "Not enough gold."
	)
	shop_buffs_buttons.add_child(vitality_buff)

func _build_shop_mod_buttons() -> void:
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
			if gold >= int(shop_mod["cost"]):
				gold -= int(shop_mod["cost"])
				ball_mod_counts[shop_mod_id] = int(ball_mod_counts.get(shop_mod_id, 0)) + 1
				info_label.text = "%s buff acquired." % shop_mod["name"]
				_refresh_mod_buttons()
				_update_labels()
				_show_shop()
			else:
				info_label.text = "Not enough gold."
		)
		shop_ball_mods_buttons.add_child(button)

func _show_rest() -> void:
	state = GameState.REST
	hud_controller.hide_all_panels()
	info_label.text = "Rest to heal."
	hp = min(max_hp, hp + 20)
	_update_labels()
	_show_map()

func _show_game_over() -> void:
	state = GameState.GAME_OVER
	_clear_active_balls()
	hud_controller.hide_all_panels()
	gameover_panel.visible = true
	gameover_label.text = "Game Over"
	info_label.text = "Your run has ended."

func _show_victory() -> void:
	state = GameState.VICTORY
	_clear_active_balls()
	hud_controller.hide_all_panels()
	gameover_panel.visible = true
	gameover_label.text = "Victory!"
	info_label.text = "You cleared the run."

func _go_to_menu() -> void:
	App.show_menu()

func on_menu_opened() -> void:
	for node in [paddle, bricks_root, hud]:
		if node:
			node.visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func on_menu_closed() -> void:
	for node in [paddle, bricks_root, hud]:
		if node:
			node.visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_fit_to_viewport()

func _clear_active_balls() -> void:
	for ball in active_balls:
		if is_instance_valid(ball):
			ball.queue_free()
	active_balls.clear()
	volley_ball_reserve = 0
	_update_reserve_indicator()

func _on_brick_destroyed(_brick: Node) -> void:
	_update_labels()
	if _brick != null and _brick.has_method("get"):
		if _brick.get("is_cursed"):
			var suppress: bool = false
			if _brick.has_method("get"):
				suppress = bool(_brick.get("suppress_curse_on_destroy"))
			if not suppress:
				deck_manager.add_card("wound")
				if _brick is Node2D:
					_spawn_wound_flyout((_brick as Node2D).global_position)
				_update_labels()
	if encounter_manager.check_victory() and (state == GameState.VOLLEY or state == GameState.PLANNING):
		_end_encounter()

func _on_brick_damaged(_brick: Node) -> void:
	_update_labels()

func _discard_hand() -> void:
	deck_manager.discard_hand()
	_refresh_hand()

func _refresh_hand() -> void:
	hud_controller.refresh_hand(deck_manager.hand, state != GameState.PLANNING, Callable(self, "_play_card"))

func _play_card(card_id: String) -> void:
	if state != GameState.PLANNING:
		return
	var cost: int = card_data[card_id]["cost"]
	if energy < cost:
		info_label.text = "Not enough energy."
		return
	energy -= cost
	_apply_card_effect(card_id)
	if card_id != "wound":
		deck_manager.discard_card(card_id)
	deck_manager.play_card(card_id)
	_refresh_hand()
	_update_reserve_indicator()
	_update_labels()

func _apply_card_effect(card_id: String) -> void:
	match card_id:
		"punch":
			volley_damage_bonus += 1
		"twin":
			volley_ball_bonus += 1
		"guard":
			block += 5
		"widen":
			paddle_buff_turns = max(paddle_buff_turns, 2)
			paddle.set_half_width(base_paddle_half_width + 30.0)
		"bomb":
			_destroy_random_bricks(3)
		"rally":
			deck_manager.draw_cards(2)
		"focus":
			energy += 1
		"haste":
			paddle_speed_buff_turns = max(paddle_speed_buff_turns, 2)
			paddle.speed = base_paddle_speed * paddle_speed_multiplier
		"slow":
			volley_ball_speed_multiplier = 0.7
		"wound":
			deck_manager.remove_card_from_deck("wound")
			info_label.text = "Wound removed from your deck."
		_:
			pass

func _destroy_random_bricks(amount: int) -> void:
	var bricks: Array = bricks_root.get_children()
	bricks.shuffle()
	for i in range(min(amount, bricks.size())):
		var brick: Node = bricks[i]
		if brick.has_method("apply_damage"):
			brick.apply_damage(999)

func _apply_paddle_buffs() -> void:
	if paddle_buff_turns > 0:
		paddle_buff_turns -= 1
		if paddle_buff_turns == 0:
			paddle.set_half_width(base_paddle_half_width)
	if paddle_speed_buff_turns > 0:
		paddle_speed_buff_turns -= 1
		if paddle_speed_buff_turns == 0:
			paddle.speed = base_paddle_speed

func _add_card_to_deck(card_id: String) -> void:
	deck_manager.add_card(card_id)

func _update_labels() -> void:
	var draw_count: int = deck_manager.draw_pile.size()
	if state != GameState.PLANNING and state != GameState.VOLLEY:
		draw_count = deck_manager.deck.size()
	var threat: int = encounter_manager.calculate_threat(encounter_base_threat)
	hud_controller.update_labels(
		energy,
		max_energy,
		draw_count,
		deck_manager.discard_pile.size(),
		hp,
		max_hp,
		gold,
		threat,
		floor_index,
		max_floors
	)

func _spawn_wound_flyout(start_pos: Vector2) -> void:
	var fly_label := Label.new()
	fly_label.text = "🤕"
	fly_label.position = start_pos
	fly_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(fly_label)
	var target: Vector2 = deck_stack.get_global_rect().get_center()
	var tween := get_tree().create_tween()
	tween.tween_property(fly_label, "global_position", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(fly_label, "scale", Vector2(0.6, 0.6), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(fly_label.queue_free)

func _refresh_mod_buttons() -> void:
	for child in mods_buttons.get_children():
		child.queue_free()
	var has_buffs: bool = false
	for mod_id in ball_mod_order:
		if int(ball_mod_counts.get(mod_id, 0)) > 0:
			has_buffs = true
			break
	if not has_buffs:
		var label := Label.new()
		label.text = "No buffs yet."
		mods_buttons.add_child(label)
		return
	for mod_id in ball_mod_order:
		var count: int = int(ball_mod_counts.get(mod_id, 0))
		if count <= 0:
			continue
		var mod: Dictionary = ball_mod_data[mod_id]
		var active_mod_id := mod_id
		var button := Button.new()
		button.text = "%s x%d" % [mod["name"], count]
		button.tooltip_text = mod["desc"]
		if ball_mod_colors.has(mod_id):
			button.self_modulate = ball_mod_colors[mod_id]
		button.pressed.connect(func() -> void:
			_select_ball_mod(active_mod_id)
		)
		mods_buttons.add_child(button)
	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(func() -> void:
		active_ball_mod = ""
		_apply_ball_mod_to_active_balls()
		_refresh_mod_buttons()
	)
	mods_buttons.add_child(clear_button)

func _select_ball_mod(mod_id: String) -> void:
	if int(ball_mod_counts.get(mod_id, 0)) <= 0:
		return
	active_ball_mod = mod_id
	_apply_ball_mod_to_active_balls()

func _apply_ball_mod_to_active_balls() -> void:
	for ball in active_balls:
		if is_instance_valid(ball):
			if ball.has_method("set_mod_colors"):
				ball.set_mod_colors(ball_mod_colors)
			if ball.has_method("set_ball_mod"):
				ball.set_ball_mod(active_ball_mod)
			else:
				ball.ball_mod = active_ball_mod

func _is_persist_enabled() -> bool:
	if mods_persist_checkbox:
		return mods_persist_checkbox.button_pressed
	return persist_ball_mods

func _show_single_panel(panel: Control) -> void:
	hud_controller.hide_all_panels()
	if panel:
		panel.visible = true

func _capture_deck_return_context() -> void:
	deck_return_panel = ReturnPanel.NONE
	if map_panel.visible:
		deck_return_panel = ReturnPanel.MAP
	elif reward_panel.visible:
		deck_return_panel = ReturnPanel.REWARD
	elif shop_panel.visible:
		deck_return_panel = ReturnPanel.SHOP
	elif gameover_panel.visible:
		deck_return_panel = ReturnPanel.GAMEOVER
	deck_return_info = info_label.text

func _show_deck_panel() -> void:
	if state == GameState.GAME_OVER or state == GameState.VICTORY:
		return
	_capture_deck_return_context()
	_show_single_panel(deck_panel)
	info_label.text = "Deck contents."
	hud_controller.populate_card_container(deck_list, deck_manager.deck, Callable(), false, 4)

func _show_discard_panel() -> void:
	if state == GameState.GAME_OVER or state == GameState.VICTORY:
		return
	_capture_deck_return_context()
	_show_single_panel(deck_panel)
	info_label.text = "Discard contents."
	hud_controller.populate_card_container(deck_list, deck_manager.discard_pile, Callable(), false, 5)

func _show_remove_card_panel() -> void:
	if state == GameState.GAME_OVER or state == GameState.VICTORY:
		return
	_capture_deck_return_context()
	_show_single_panel(deck_panel)
	info_label.text = "Choose a card to remove."
	hud_controller.populate_card_container(deck_list, deck_manager.deck, Callable(self, "_on_remove_card_selected"), false, 5)

func _on_remove_card_selected(card_id: String) -> void:
	deck_manager.remove_card_from_all(card_id, true)
	_refresh_hand()
	var card_name: String = card_data[card_id]["name"]
	deck_return_info = "Removed %s." % card_name
	_close_deck_panel()

func _close_deck_panel() -> void:
	hud_controller.hide_all_panels()
	match deck_return_panel:
		ReturnPanel.MAP:
			map_panel.visible = true
		ReturnPanel.REWARD:
			reward_panel.visible = true
		ReturnPanel.SHOP:
			shop_panel.visible = true
			_update_labels()
		ReturnPanel.GAMEOVER:
			gameover_panel.visible = true
		_:
			pass
	info_label.text = deck_return_info
