extends Node2D

enum GameState { MAP, PLANNING, VOLLEY, REWARD, SHOP, REST, GAME_OVER, VICTORY }

const CARD_DATA: Dictionary = {
	"strike": {"name": "Strike", "cost": 1, "desc": "+1 volley damage.", "type": "offense"},
	"twin": {"name": "Twin Launch", "cost": 1, "desc": "Gain an extra launch this volley.", "type": "offense"},
	"guard": {"name": "Guard", "cost": 1, "desc": "Gain 4 block. Block reduces threat damage this turn.", "type": "defense"},
	"widen": {"name": "Widen Paddle", "cost": 1, "desc": "Widen paddle for 2 turns.", "type": "utility"},
	"bomb": {"name": "Bomb", "cost": 2, "desc": "Destroy up to 3 random bricks.", "type": "offense"},
	"rally": {"name": "Rally", "cost": 0, "desc": "Draw 2 cards.", "type": "utility"},
	"focus": {"name": "Focus", "cost": 1, "desc": "+1 energy this turn.", "type": "utility"},
	"haste": {"name": "Haste", "cost": 1, "desc": "Paddle moves faster for 2 turns.", "type": "utility"},
	"slow": {"name": "Stasis", "cost": 1, "desc": "Slow balls this volley.", "type": "defense"},
	"wound": {"name": "Wound", "cost": 9, "desc": "Unplayable. Clutters your hand until end of turn.", "type": "curse"}
}

const CARD_TYPE_COLORS: Dictionary = {
	"offense": Color(1.0, 0.32, 0.02),
	"defense": Color(0.05, 0.5, 1.0),
	"utility": Color(0.98, 0.94, 0.08),
	"curse": Color(0.2, 0.2, 0.2)
}

const CARD_BUTTON_SIZE: Vector2 = Vector2(110, 154)
const MAX_HAND_SIZE: int = 7
const BASE_STARTING_HAND_SIZE: int = 4
const BALL_SPAWN_OFFSET: Vector2 = Vector2(0, -32)

const BALL_MOD_DATA: Dictionary = {
	"explosive": {"name": "Explosives", "desc": "Explode bricks on hit.", "cost": 50},
	"spikes": {"name": "Spikes", "desc": "Ignore brick shields on hit.", "cost": 50},
	"miracle": {"name": "Miracle", "desc": "One floor bounce per ball.", "cost": 60}
}
const BALL_MOD_ORDER: Array[String] = ["explosive", "spikes", "miracle"]
const BALL_MOD_COLORS: Dictionary = {
	"explosive": Color(0.95, 0.35, 0.35),
	"spikes": Color(0.95, 0.85, 0.25),
	"miracle": Color(0.45, 0.75, 1.0)
}

const STARTING_DECK: Array[String] = [
	"strike", "strike", "strike", "strike",
	"twin", "twin",
	"guard", "guard",
	"rally", "focus"
]

const CARD_POOL: Array[String] = [
	"strike", "twin", "guard", "widen", "bomb", "rally", "focus",
	"haste", "slow"
]

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
@onready var deck_count_label: Label = $HUD/HandBar/DeckStack/DeckCountLabel
@onready var deck_stack: Control = $HUD/HandBar/DeckStack
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
var card_art_textures: Dictionary = {
	"strike": preload("res://assets/cards/strike.png"),
	"twin": preload("res://assets/cards/twin.png")
}

var state: GameState = GameState.MAP
var deck: Array[String] = []
var draw_pile: Array[String] = []
var discard_pile: Array[String] = []
var hand: Array[String] = []

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
var deck_return_panel: String = ""
var deck_return_info: String = ""

func _update_reserve_indicator() -> void:
	if paddle and paddle.has_method("set_reserve_count"):
		if state == GameState.PLANNING:
			paddle.set_reserve_count(volley_ball_bonus)
		else:
			paddle.set_reserve_count(volley_ball_reserve)

func _ready() -> void:
	randomize()
	if get_viewport():
		get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()
	base_paddle_half_width = paddle.half_width
	base_paddle_speed = paddle.speed
	# Buttons removed; use Space to launch and cards/turn flow for control.
	if restart_button:
		restart_button.pressed.connect(_start_run)
	if menu_button:
		menu_button.pressed.connect(_go_to_menu)
	if forfeit_dialog:
		forfeit_dialog.confirmed.connect(_confirm_forfeit_volley)
	if deck_button:
		deck_button.pressed.connect(_show_deck_panel)
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
	if deck_count_label:
		deck_count_label.mouse_filter = Control.MOUSE_FILTER_STOP
		deck_count_label.tooltip_text = "Cards left in your draw pile."
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
	deck = STARTING_DECK.duplicate()
	active_balls.clear()
	for child in bricks_root.get_children():
		child.queue_free()
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	_shuffle_into_draw(deck)
	floor_index = 1
	_start_encounter(false)

func _show_map() -> void:
	state = GameState.MAP
	_hide_all_panels()
	map_panel.visible = true
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
	info_label.text = "Re-apply after use (while available)."
	_build_map_buttons()
	_update_labels()

func _build_map_buttons() -> void:
	for child in map_buttons.get_children():
		child.queue_free()
	var choices: Array[String] = _generate_room_choices()
	for room_type in choices:
		var button := Button.new()
		button.text = _room_label(room_type)
		button.pressed.connect(func() -> void:
			_enter_room(room_type)
		)
		map_buttons.add_child(button)

func _generate_room_choices() -> Array[String]:
	if floor_index >= max_combat_floors:
		return ["boss"]
	var pool: Array[String] = ["combat", "combat", "combat", "rest", "shop", "elite"]
	return [pool.pick_random(), pool.pick_random()]

func _room_label(room_type: String) -> String:
	match room_type:
		"combat":
			return "Combat"
		"elite":
			return "Elite"
		"rest":
			return "Rest"
		"shop":
			return "Shop"
		"boss":
			return "Boss"
		"victory":
			return "Victory"
		_:
			return "???"

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
	_hide_all_panels()
	info_label.text = "Plan your volley, then launch."
	_clear_active_balls()
	current_is_boss = false
	var difficulty: int = max(1, floor_index)
	current_pattern = _pick_pattern()
	encounter_speed_boost = randf() < (0.15 + 0.05 * difficulty)
	if is_elite:
		encounter_rows = 5 + int(difficulty / 2)
		encounter_cols = 9
		encounter_hp = 2 + int(difficulty / 2)
		encounter_base_threat = 0
	else:
		encounter_rows = 4 + int(difficulty / 2)
		encounter_cols = 8
		encounter_hp = 1 + int(difficulty / 3)
		encounter_base_threat = 0
	if encounter_speed_boost:
		info_label.text = "Volley Mod: Speed Boost."
	_build_bricks(encounter_rows, encounter_cols, encounter_hp, current_pattern)
	_start_turn()

func _start_boss() -> void:
	state = GameState.PLANNING
	_hide_all_panels()
	info_label.text = "Boss fight. Plan carefully."
	_clear_active_balls()
	current_is_boss = true
	var difficulty: int = max(1, floor_index)
	current_pattern = "ring"
	encounter_speed_boost = true
	encounter_rows = 6 + int(difficulty / 2)
	encounter_cols = 10
	encounter_hp = 4 + int(difficulty / 2)
	encounter_base_threat = 0
	_build_bricks(encounter_rows, encounter_cols, encounter_hp, current_pattern)
	_spawn_boss_core(encounter_rows, encounter_cols, encounter_hp + 2)
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
	_draw_cards(starting_hand_size)
	_refresh_hand()
	_refresh_mod_buttons()
	_update_labels()

func _end_turn() -> void:
	if state != GameState.PLANNING:
		return
	_discard_hand()
	var incoming: int = max(0, _calculate_threat() - block)
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
	_regen_bricks_on_drop()
	if active_balls.is_empty():
		if _check_victory():
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
	var threat: int = _calculate_threat()
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

func _check_victory() -> bool:
	return bricks_root.get_child_count() == 0

func _end_encounter() -> void:
	_hide_all_panels()
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
		var card_id: String = CARD_POOL.pick_random()
		var button := _create_card_button(card_id)
		button.pressed.connect(func() -> void:
			_add_card_to_deck(card_id)
			_show_map()
		)
		reward_buttons.add_child(button)

func _show_shop() -> void:
	state = GameState.SHOP
	_hide_all_panels()
	if map_panel:
		map_panel.visible = false
	if reward_panel:
		reward_panel.visible = false
	if deck_panel:
		deck_panel.visible = false
	if gameover_panel:
		gameover_panel.visible = false
	shop_panel.visible = true
	info_label.text = ""
	_build_shop_buttons()
	_refresh_mod_buttons()
	_update_labels()

func _build_shop_buttons() -> void:
	if shop_cards_buttons == null or shop_buffs_buttons == null or shop_ball_mods_buttons == null:
		return
	for child in shop_cards_buttons.get_children():
		child.queue_free()
	for child in shop_buffs_buttons.get_children():
		child.queue_free()
	for child in shop_ball_mods_buttons.get_children():
		child.queue_free()

	for _i in range(2):
		var card_id: String = CARD_POOL.pick_random()
		var button := _create_card_button(card_id)
		_set_card_button_desc(button, "%s\nPrice: 40g" % CARD_DATA[card_id]["desc"])
		button.pressed.connect(func() -> void:
			if gold >= 40:
				gold -= 40
				_add_card_to_deck(card_id)
				_show_map()
			else:
				info_label.text = "Not enough gold."
		)
		shop_cards_buttons.add_child(button)
	var remove := Button.new()
	remove.text = "Remove a card (30g)"
	remove.pressed.connect(func() -> void:
		if gold >= 30 and deck.size() > 0:
			gold -= 30
			deck.remove_at(randi_range(0, deck.size() - 1))
			info_label.text = "Card removed."
			_show_map()
		else:
			info_label.text = "Cannot remove."
	)
	shop_cards_buttons.add_child(remove)

	var upgrade := Button.new()
	upgrade.text = "Upgrade starting hand (+1) (60g)"
	upgrade.pressed.connect(func() -> void:
		if gold >= 60:
			gold -= 60
			starting_hand_size += 1
			info_label.text = "Starting hand increased to %d." % starting_hand_size
			_show_map()
		else:
			info_label.text = "Not enough gold."
	)
	shop_buffs_buttons.add_child(upgrade)

	var vitality_buff := Button.new()
	vitality_buff.text = "Vitality (+10 max HP, heal 10) (60g)"
	vitality_buff.pressed.connect(func() -> void:
		if gold >= 60:
			gold -= 60
			max_hp += 10
			hp = min(max_hp, hp + 10)
			info_label.text = "Max HP increased to %d." % max_hp
			_update_labels()
			_show_map()
		else:
			info_label.text = "Not enough gold."
	)
	shop_buffs_buttons.add_child(vitality_buff)

	for mod_id in BALL_MOD_ORDER:
		var count: int = int(ball_mod_counts.get(mod_id, 0))
		var mod: Dictionary = BALL_MOD_DATA[mod_id]
		var button := Button.new()
		if count > 0:
			button.text = "%s x%d (+1) (%dg)" % [mod["name"], count, mod["cost"]]
		else:
			button.text = "%s x0 (+1) (%dg)" % [mod["name"], mod["cost"]]
		button.tooltip_text = mod["desc"]
		if BALL_MOD_COLORS.has(mod_id):
			button.self_modulate = BALL_MOD_COLORS[mod_id]
		button.pressed.connect(func() -> void:
			if gold >= int(mod["cost"]):
				gold -= int(mod["cost"])
				ball_mod_counts[mod_id] = int(ball_mod_counts.get(mod_id, 0)) + 1
				info_label.text = "%s buff acquired." % mod["name"]
				_refresh_mod_buttons()
				_update_labels()
				_show_shop()
			else:
				info_label.text = "Not enough gold."
		)
		shop_ball_mods_buttons.add_child(button)

func _show_rest() -> void:
	state = GameState.REST
	_hide_all_panels()
	info_label.text = "Rest to heal."
	hp = min(max_hp, hp + 20)
	_update_labels()
	_show_map()

func _show_game_over() -> void:
	state = GameState.GAME_OVER
	_clear_active_balls()
	_hide_all_panels()
	gameover_panel.visible = true
	gameover_label.text = "Game Over"
	info_label.text = "Your run has ended."

func _show_victory() -> void:
	state = GameState.VICTORY
	_clear_active_balls()
	_hide_all_panels()
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

func _hide_all_panels() -> void:
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

func _clear_active_balls() -> void:
	for ball in active_balls:
		if is_instance_valid(ball):
			ball.queue_free()
	active_balls.clear()
	volley_ball_reserve = 0
	_update_reserve_indicator()

func _build_bricks(rows: int, cols: int, base_hp: int, pattern: String) -> void:
	for child in bricks_root.get_children():
		child.queue_free()

	for row in range(rows):
		for col in range(cols):
			if not _pattern_allows(row, col, rows, cols, pattern):
				continue
			var hp_value: int = base_hp + int(row / 2)
			_spawn_brick(row, col, rows, cols, hp_value, _row_color(row), _roll_variants())

func _spawn_brick(row: int, col: int, rows: int, cols: int, hp_value: int, color: Color, data: Dictionary) -> void:
	var brick: Node = brick_scene.instantiate()
	var total_width: float = cols * brick_size.x + (cols - 1) * brick_gap.x
	var start_x: float = (get_viewport_rect().size.x - total_width) * 0.5
	var start_y: float = top_margin
	var x: float = start_x + col * (brick_size.x + brick_gap.x) + brick_size.x * 0.5
	var y: float = start_y + row * (brick_size.y + brick_gap.y) + brick_size.y * 0.5
	brick.position = Vector2(x, y)
	brick.add_to_group("bricks")
	bricks_root.add_child(brick)
	brick.destroyed.connect(_on_brick_destroyed)
	brick.damaged.connect(_on_brick_damaged)
	brick.setup(hp_value, 1, color, data)

func _pattern_allows(row: int, col: int, rows: int, cols: int, pattern: String) -> bool:
	match pattern:
		"stagger":
			return not (row % 2 == 1 and col % 2 == 0)
		"pyramid":
			var center: int = int(cols / 2)
			var spread: int = min(center, row + 1)
			return abs(col - center) <= spread
		"zigzag":
			return (row + col) % 2 == 0
		"ring":
			return row == 0 or row == rows - 1 or col == 0 or col == cols - 1
		_:
			return true

func _pick_pattern() -> String:
	var patterns: Array[String] = ["grid", "stagger", "pyramid", "zigzag", "ring"]
	return patterns[floor_index % patterns.size()]

func _roll_variants() -> Dictionary:
	var data: Dictionary = {}
	var shield_chance: float = 0.1
	var regen_chance: float = 0.1
	var curse_chance: float = 0.08
	if current_is_boss:
		shield_chance = 0.4
		regen_chance = 0.35
		curse_chance = 0.25
	elif floor_index >= 3:
		shield_chance = 0.2
		regen_chance = 0.18
		curse_chance = 0.12
	if randf() < shield_chance:
		var sides: Array[String] = ["left", "right", "top", "bottom"]
		sides.shuffle()
		data["shielded_sides"] = [sides[0]]
	if randf() < regen_chance:
		data["regen_on_drop"] = true
		data["regen_amount"] = 1
	if randf() < curse_chance:
		data["is_cursed"] = true
	return data

func _spawn_boss_core(rows: int, cols: int, hp_value: int) -> void:
	var center_row: int = int(rows / 2)
	var center_col: int = int(cols / 2)
	for row in range(center_row - 1, center_row + 1):
		for col in range(center_col - 1, center_col + 1):
			var data: Dictionary = {
				"shielded_sides": ["left", "right"],
				"regen_on_drop": true,
				"regen_amount": 2,
				"is_cursed": true
			}
			_spawn_brick(row, col, rows, cols, hp_value + 2, Color(0.85, 0.2, 0.2), data)

func _row_color(row: int) -> Color:
	var palette: Array[Color] = [
		Color(0.86, 0.32, 0.26),
		Color(0.95, 0.60, 0.20),
		Color(0.95, 0.85, 0.25),
		Color(0.45, 0.78, 0.36),
		Color(0.26, 0.62, 0.96)
	]
	return palette[row % palette.size()]

func _on_brick_destroyed(_brick: Node) -> void:
	_update_labels()
	if _brick != null and _brick.has_method("get"):
		if _brick.get("is_cursed"):
			var suppress: bool = false
			if _brick.has_method("get"):
				suppress = bool(_brick.get("suppress_curse_on_destroy"))
			if not suppress:
				deck.append("wound")
				draw_pile.append("wound")
				draw_pile.shuffle()
				if _brick is Node2D:
					_spawn_wound_flyout((_brick as Node2D).global_position)
				_update_labels()
	if _check_victory() and (state == GameState.VOLLEY or state == GameState.PLANNING):
		_end_encounter()

func _on_brick_damaged(_brick: Node) -> void:
	_update_labels()

func _regen_bricks_on_drop() -> void:
	for brick in bricks_root.get_children():
		if brick.has_method("on_ball_drop"):
			brick.on_ball_drop()

func _calculate_threat() -> int:
	if bricks_root.get_child_count() == 0:
		return 0
	var total: int = 0
	for brick in bricks_root.get_children():
		if brick.has_method("get_threat"):
			total += brick.get_threat()
	return total + encounter_base_threat

func _draw_cards(count: int) -> void:
	for _i in range(count):
		if hand.size() >= MAX_HAND_SIZE:
			return
		if draw_pile.is_empty():
			_shuffle_into_draw(discard_pile)
			discard_pile.clear()
		if draw_pile.is_empty():
			return
		hand.append(draw_pile.pop_back())

func _discard_hand() -> void:
	for card_id in hand:
		discard_pile.append(card_id)
	hand.clear()
	_refresh_hand()

func _shuffle_into_draw(cards: Array) -> void:
	draw_pile = cards.duplicate()
	draw_pile.shuffle()

func _refresh_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	for card_id in hand:
		var button := _create_card_button(card_id)
		button.disabled = state != GameState.PLANNING
		button.pressed.connect(func() -> void:
			_play_card(card_id)
		)
		hand_container.add_child(button)

func _play_card(card_id: String) -> void:
	if state != GameState.PLANNING:
		return
	if card_id == "wound":
		info_label.text = "Wound is unplayable."
		return
	var cost: int = CARD_DATA[card_id]["cost"]
	if energy < cost:
		info_label.text = "Not enough energy."
		return
	energy -= cost
	_apply_card_effect(card_id)
	discard_pile.append(card_id)
	hand.erase(card_id)
	_refresh_hand()
	_update_reserve_indicator()
	_update_labels()

func _apply_card_effect(card_id: String) -> void:
	match card_id:
		"strike":
			volley_damage_bonus += 1
		"twin":
			volley_ball_bonus += 1
		"guard":
			block += 4
		"widen":
			paddle_buff_turns = max(paddle_buff_turns, 2)
			paddle.set_half_width(base_paddle_half_width + 30.0)
		"bomb":
			_destroy_random_bricks(3)
		"rally":
			_draw_cards(2)
		"focus":
			energy += 1
		"haste":
			paddle_speed_buff_turns = max(paddle_speed_buff_turns, 2)
			paddle.speed = base_paddle_speed * paddle_speed_multiplier
		"slow":
			volley_ball_speed_multiplier = 0.7
		"wound":
			info_label.text = "Wound is unplayable."
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
	deck.append(card_id)
	draw_pile.append(card_id)
	draw_pile.shuffle()

func _card_label(card_id: String) -> String:
	var card: Dictionary = CARD_DATA[card_id]
	return "%s [%d]" % [card["name"], card["cost"]]

func _card_tooltip(card_id: String) -> String:
	var card: Dictionary = CARD_DATA[card_id]
	return "%s (Cost %d)\n%s" % [card["name"], card["cost"], card["desc"]]

func _apply_card_style(button: Button, card_id: String) -> void:
	var card: Dictionary = CARD_DATA[card_id]
	var card_type: String = card.get("type", "utility")
	if CARD_TYPE_COLORS.has(card_type):
		var color: Color = CARD_TYPE_COLORS[card_type]
		color.a = 1.0
		button.modulate = Color(1, 1, 1, 1)
		button.self_modulate = color

func _apply_card_button_size(button: Button) -> void:
	button.custom_minimum_size = CARD_BUTTON_SIZE

func _create_card_button(card_id: String) -> Button:
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
	art_frame.custom_minimum_size = Vector2(CARD_BUTTON_SIZE.x - 12.0, 70.0)
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
	desc_label.text = CARD_DATA[card_id]["desc"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.add_theme_font_size_override("font_size", 8)
	desc_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_frame.add_child(desc_label)

	return button

func _set_card_button_desc(button: Button, text: String) -> void:
	var layout: VBoxContainer = button.get_node("CardLayout") as VBoxContainer
	if layout == null:
		return
	var desc_label: Label = layout.get_node("DescFrame/DescLabel") as Label
	if desc_label:
		desc_label.text = text

func _get_card_art(card_id: String) -> Texture2D:
	if card_art_textures.has(card_id):
		return card_art_textures[card_id]
	return card_art_textures["twin"]

func _update_labels() -> void:
	energy_label.text = "Energy: %d/%d" % [energy, max_energy]
	var draw_count: int = draw_pile.size()
	if state != GameState.PLANNING and state != GameState.VOLLEY:
		draw_count = deck.size()
	deck_label.text = "Draw: %d" % draw_count
	deck_count_label.text = "%d" % draw_count
	discard_label.text = "Discard: %d" % discard_pile.size()
	hp_label.text = "HP: %d/%d" % [hp, max_hp]
	gold_label.text = "Gold: %d" % gold
	if shop_gold_label:
		shop_gold_label.text = "Gold: %d" % gold
	threat_label.text = "Threat: %d" % _calculate_threat()
	var display_floor: int = min(max(1, floor_index), max_floors)
	floor_label.text = "Floor %d/%d" % [display_floor, max_floors]

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
	for mod_id in BALL_MOD_ORDER:
		if int(ball_mod_counts.get(mod_id, 0)) > 0:
			has_buffs = true
			break
	if not has_buffs:
		var label := Label.new()
		label.text = "No buffs yet."
		mods_buttons.add_child(label)
		return
	for mod_id in BALL_MOD_ORDER:
		var count: int = int(ball_mod_counts.get(mod_id, 0))
		if count <= 0:
			continue
		var mod: Dictionary = BALL_MOD_DATA[mod_id]
		var button := Button.new()
		button.text = "%s x%d" % [mod["name"], count]
		button.tooltip_text = mod["desc"]
		if BALL_MOD_COLORS.has(mod_id):
			button.self_modulate = BALL_MOD_COLORS[mod_id]
		button.pressed.connect(func() -> void:
			_select_ball_mod(mod_id)
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
			if ball.has_method("set_ball_mod"):
				ball.set_ball_mod(active_ball_mod)
			else:
				ball.ball_mod = active_ball_mod

func _is_persist_enabled() -> bool:
	if mods_persist_checkbox:
		return mods_persist_checkbox.button_pressed
	return persist_ball_mods

func _show_deck_panel() -> void:
	if state == GameState.GAME_OVER or state == GameState.VICTORY:
		return
	deck_return_panel = ""
	if map_panel.visible:
		deck_return_panel = "map"
	elif reward_panel.visible:
		deck_return_panel = "reward"
	elif shop_panel.visible:
		deck_return_panel = "shop"
	elif gameover_panel.visible:
		deck_return_panel = "gameover"
	deck_return_info = info_label.text
	_hide_all_panels()
	deck_panel.visible = true
	info_label.text = "Deck contents."
	_build_deck_list()

func _close_deck_panel() -> void:
	_hide_all_panels()
	match deck_return_panel:
		"map":
			map_panel.visible = true
		"reward":
			reward_panel.visible = true
		"shop":
			shop_panel.visible = true
		"gameover":
			gameover_panel.visible = true
		_:
			pass
	info_label.text = deck_return_info

func _build_deck_list() -> void:
	for child in deck_list.get_children():
		child.queue_free()
	var counts: Dictionary = {}
	for card_id in deck:
		counts[card_id] = counts.get(card_id, 0) + 1
	var card_ids: Array[String] = []
	for key in counts.keys():
		card_ids.append(String(key))
	card_ids.sort_custom(func(a: String, b: String) -> bool:
		return CARD_DATA[a]["name"] < CARD_DATA[b]["name"]
	)
	for card_id in card_ids:
		var count: int = counts[card_id]
		var card: Dictionary = CARD_DATA[card_id]
		var label := Label.new()
		label.text = "%s x%d" % [card["name"], count]
		label.tooltip_text = _card_tooltip(card_id)
		deck_list.add_child(label)
