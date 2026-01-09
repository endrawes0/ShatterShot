extends Node2D

signal toast_request_completed(token: int)

const GameState = StateManager.GameState

enum BetweenActStep { NONE, BUFF, TREASURE, REST, SHOP }

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
const ACT_CONFIG_DIR: String = "res://data/act_configs"
const FLOOR_PLAN_GENERATOR_CONFIG_PATH: String = "res://data/floor_plans/generator_config.tres"
const FLOOR_PLAN_GENERATOR := preload("res://scripts/data/FloorPlanGenerator.gd")
const FLOOR_PLAN_GENERATOR_CONFIG := preload("res://scripts/data/FloorPlanGeneratorConfig.gd")
const ACT_MANAGER_SCRIPT := preload("res://scripts/managers/ActManager.gd")
const ACT_CONFIG_SCRIPT := preload("res://scripts/data/ActConfig.gd")
const CardEffectRegistry = preload("res://scripts/cards/CardEffectRegistry.gd")
const BALANCE_DATA_PATH: String = "res://data/balance/basic.tres"
const EMOJI_FONT_PATH: String = "res://assets/fonts/NotoColorEmoji.ttf"
const OUTCOME_PARTICLE_SCENE: PackedScene = preload("res://scenes/HitParticle.tscn")
const TEST_LAB_PANEL_SCENE: PackedScene = preload("res://scenes/TestLabPanel.tscn")
const OUTCOME_PARTICLE_COUNT: int = 18
const OUTCOME_PARTICLE_SPEED_X: Vector2 = Vector2(-80.0, 80.0)
const OUTCOME_PARTICLE_SPEED_Y_VICTORY: Vector2 = Vector2(-220.0, -60.0)
const OUTCOME_PARTICLE_SPEED_Y_DEFEAT: Vector2 = Vector2(40.0, 200.0)
const VOLLEY_PROMPT_OFFSET_Y: float = -70.0
const START_PROMPT_EXTRA_OFFSET_Y: float = 40.0
const VICTORY_REVIVE_HP_BONUS: int = 25
const VICTORY_REVIVE_TOAST: String = "Resurrection: You pull yourself back from the brink of death! (+25 HP)"

@export var brick_size: Vector2 = Vector2(64, 24)
@export var brick_gap: Vector2 = Vector2(8, 8)
@export var top_margin: float = 70.0
@export var planning_victory_messages: Array[String] = ["Nice one!"]

@onready var paddle: CharacterBody2D = $Paddle
@onready var bricks_root: Node2D = $Bricks
@onready var playfield: Polygon2D = $Playfield
@onready var backdrop_rect: ColorRect = $Backdrop/BackdropRect
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
@onready var volley_prompt_label: RichTextLabel = $HUD/VolleyPromptLabel
@onready var victory_overlay: ColorRect = $HUD/VictoryOverlay
@onready var defeat_overlay: ColorRect = $HUD/DefeatOverlay
@onready var mods_panel: Panel = $HUD/ModsPanel
@onready var mods_buttons: VBoxContainer = $HUD/ModsPanel/ModsButtons
@onready var mods_persist_checkbox: CheckBox = $HUD/ModsPanel/ModsPersist
@onready var map_panel: Panel = $HUD/MapPanel
@onready var map_graph: Control = $HUD/MapPanel/MapGraph
@onready var map_buttons: HBoxContainer = $HUD/MapPanel/MapButtons
@onready var map_seed_label: Label = $HUD/MapPanel/MapSeedLabel
@onready var map_label: Label = $HUD/MapPanel/MapLabel
@onready var reward_panel: Panel = $HUD/RewardPanel
@onready var reward_label: Label = $HUD/RewardPanel/RewardLabel
@onready var reward_buttons: HBoxContainer = $HUD/RewardPanel/RewardLayout/RewardButtons
@onready var reward_skip_button: Button = $HUD/RewardPanel/RewardLayout/RewardSkipButton
@onready var treasure_panel: Panel = $HUD/TreasurePanel
@onready var treasure_label: Label = $HUD/TreasurePanel/TreasureLabel
@onready var treasure_rewards: VBoxContainer = $HUD/TreasurePanel/TreasureLayout/TreasureRewards
@onready var treasure_continue_button: Button = $HUD/TreasurePanel/TreasureLayout/TreasureContinueButton
@onready var shop_panel: Panel = $HUD/ShopPanel
@onready var shop_cards_buttons: Container = $HUD/ShopPanel/ShopLayout/CardsPanel/CardsButtons
@onready var shop_buffs_buttons: Container = $HUD/ShopPanel/ShopLayout/BuffsPanel/BuffsButtons
@onready var shop_ball_mods_buttons: Container = $HUD/ShopPanel/ShopLayout/BallModsPanel/BallModsButtons
@onready var shop_leave_button: Button = $HUD/ShopPanel/LeaveButton
@onready var shop_gold_label: Label = $HUD/ShopPanel/ShopGoldLabel
@onready var shop_label: Label = $HUD/ShopPanel/ShopLabel
@onready var shop_info_label: Label = $HUD/ShopPanel/ShopInfoLabel
@onready var shop_buffs_panel: Control = $HUD/ShopPanel/ShopLayout/BuffsPanel
@onready var shop_ball_mods_panel: Control = $HUD/ShopPanel/ShopLayout/BallModsPanel
@onready var shop_cards_panel: Control = $HUD/ShopPanel/ShopLayout/CardsPanel
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
@onready var boss_drop_player: AudioStreamPlayer = $BossDropSfx
@onready var left_wall: CollisionShape2D = $Walls/LeftWall
@onready var right_wall: CollisionShape2D = $Walls/RightWall
@onready var top_wall: CollisionShape2D = $Walls/TopWall

var brick_scene: PackedScene = preload("res://scenes/Brick.tscn")
var ball_scene: PackedScene = preload("res://scenes/Ball.tscn")
var card_emoji_font: Font
var floor_plan_generator_config: Resource
var pending_seed: int = 0
var has_pending_seed_override: bool = false
var run_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var run_seed: int = 0
var outcome_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var map_preview_active: bool = false
var map_preview_state: int = GameState.MAP
var treasure_reward_entries: Array[Dictionary] = []
var test_lab_enabled: bool = false
var test_lab_entry: bool = false
var test_lab_panel: Control = null
var state_manager: StateManager = StateManager.new()
var _end_encounter_in_progress: bool = false

var encounter_manager: EncounterManager
var map_manager: MapManager
var act_manager: Node
var deck_manager: DeckManager
var hud_controller: HudController
var reward_manager: RewardManager
var shop_manager: ShopManager
var balance_data: Resource
var card_effect_registry: CardEffectRegistry

var _between_act_step: int = BetweenActStep.NONE
var _between_act_pending: bool = false

var card_data: Dictionary = {}
var card_pool: Array[String] = []
var starting_deck: Array[String] = []
var ball_mod_data: Dictionary = {}
var ball_mod_order: Array[String] = []
var ball_mod_colors: Dictionary = {}
var reward_card_count: int = 3
var shop_card_price: int = 0
var shop_max_cards: int = 0
var shop_max_hand_size: int = 0
var shop_remove_price: int = 0
var shop_upgrade_price: int = 0
var shop_upgrade_hand_bonus: int = 0
var shop_vitality_price: int = 0
var shop_vitality_max_hp_bonus: int = 0
var shop_vitality_heal: int = 0
var shop_reroll_base_price: int = 0
var shop_reroll_multiplier: float = 1.0
var shop_energy_price: int = 0
var shop_energy_bonus: int = 0
var shop_paddle_width_price: int = 0
var shop_paddle_width_bonus: float = 0.0
var shop_paddle_speed_price: int = 0
var shop_paddle_speed_bonus_percent: float = 0.0
var shop_reserve_ball_price: int = 0
var shop_reserve_ball_bonus: int = 0
var shop_discount_price: int = 0
var shop_discount_percent: float = 0.0
var shop_discount_max: int = 0
var shop_entry_card_price: int = 0
var shop_entry_card_count: int = 0

var state: int = GameState.MAIN_MENU

var max_hp: int = 150
var hp: int = 150
var gold: int = 0
var floor_index: int = 0
var max_combat_floors: int = 5
var max_floors: int = 6
var practice_mode: bool = false
var _practice_room_type: String = "combat"
var _practice_act_index: int = 1
var _practice_layout_id: String = "grid"
var _practice_floor_index: int = 1
var _practice_pending: bool = false

var max_energy: int = 3
var energy: int = 3
var base_max_energy: int = 3
var max_energy_bonus: int = 0
var block: int = 0
var starting_hand_size: int = BASE_STARTING_HAND_SIZE
var ball_mod_counts: Dictionary = {}
var active_ball_mod: String = ""
var persist_ball_mods: bool = false

var volley_damage_bonus: int = 0
var volley_ball_bonus: int = 0
var volley_ball_bonus_base: int = 0
var volley_ball_reserve: int = 0
var volley_piercing: bool = false
var volley_ball_speed_multiplier: float = 1.0
var reserve_launch_cooldown: float = 0.0
var shop_discount_multiplier: float = 1.0
var shop_entry_card_bonus: int = 0
var parry_wound_active: bool = false
var riposte_wound_active: bool = false
var riposte_flyouts: Dictionary = {}
enum ReturnPanel { NONE, MAP, REWARD, SHOP, GAMEOVER }

var hud_layer_cache: int = 0

var base_paddle_half_width: float = 50.0
var paddle_buff_turns: int = 0
var base_paddle_speed: float = 420.0
var paddle_speed_setting_multiplier: float = 1.0
var paddle_speed_buff_turns: int = 0
var paddle_speed_multiplier: float = 1.3

var active_balls: Array[Node] = []
var encounter_hp: int = 1
var encounter_rows: int = 4
var encounter_cols: int = 8
var current_is_boss: bool = false
var current_is_elite: bool = false
var current_pattern: String = "grid"
var encounter_speed_boost: bool = false
var encounter_has_launched: bool = false
var act_ball_speed_multiplier: float = 1.0
var act_threat_multiplier: float = 1.0
var deck_return_panel: int = ReturnPanel.NONE
var deck_return_info: String = ""
var volley_prompt_tween: Tween = null
var volley_prompt_pulsing: bool = false

var active_act_config: Resource

func _init() -> void:
	state_manager.state_changed.connect(_on_state_changed)
	state_manager.set_initial_state(GameState.MAIN_MENU)
	state = state_manager.current_state()

func _update_reserve_indicator() -> void:
	if paddle and paddle.has_method("set_reserve_count"):
		var count: int = volley_ball_reserve
		if state == GameState.PLANNING:
			count += 1 + volley_ball_bonus
		paddle.set_reserve_count(count)

func _ready() -> void:
	balance_data = load(BALANCE_DATA_PATH)
	if balance_data == null:
		push_error("Missing balance data at %s" % BALANCE_DATA_PATH)
		return
	_apply_balance_data(balance_data)
	base_max_energy = max_energy
	outcome_rng.randomize()
	if get_viewport():
		get_viewport().size_changed.connect(_fit_to_viewport)
		_fit_to_viewport()
		base_paddle_half_width = paddle.half_width
		paddle_speed_setting_multiplier = App.get_paddle_speed_multiplier()
		base_paddle_speed = paddle.speed * paddle_speed_setting_multiplier
		paddle.speed = base_paddle_speed
		encounter_manager = EncounterManager.new()
		add_child(encounter_manager)
		encounter_manager.setup(bricks_root, brick_scene, brick_size, brick_gap, top_margin, ROW_PALETTE)
		encounter_manager.load_configs_from_dir(ENCOUNTER_CONFIG_DIR)
		map_manager = MapManager.new()
		add_child(map_manager)
		var generator_config_resource := load(FLOOR_PLAN_GENERATOR_CONFIG_PATH)
		if generator_config_resource is FLOOR_PLAN_GENERATOR_CONFIG:
			floor_plan_generator_config = generator_config_resource
			if has_pending_seed_override:
				floor_plan_generator_config.seed_value = pending_seed
				has_pending_seed_override = false
		act_manager = ACT_MANAGER_SCRIPT.new()
		add_child(act_manager)
		act_manager.setup(floor_plan_generator_config, map_manager, ACT_CONFIG_DIR, ACT_CONFIG_SCRIPT, max_combat_floors)
		_apply_act_limits()
		deck_manager = DeckManager.new()
		add_child(deck_manager)
		card_effect_registry = CardEffectRegistry.new()
		hud_controller = HudController.new()
		add_child(hud_controller)
		card_emoji_font = load(EMOJI_FONT_PATH)
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
		"treasure_panel": treasure_panel,
		"shop_panel": shop_panel,
		"deck_panel": deck_panel,
		"gameover_panel": gameover_panel,
		"hand_container": hand_container
	}, card_data, CARD_TYPE_COLORS, CARD_BUTTON_SIZE, card_emoji_font)
	reward_manager = RewardManager.new()
	add_child(reward_manager)
	reward_manager.setup(hud_controller, reward_buttons)
	reward_manager.set_on_selected(Callable(self, "_on_reward_selected"))
	reward_manager.set_panel_nodes(reward_label, reward_skip_button)
	reward_manager.set_info_callback(Callable(self, "_set_info_text"))
	reward_manager.configure({"reward_count": reward_card_count})
	shop_manager = ShopManager.new()
	add_child(shop_manager)
	shop_manager.setup(hud_controller, shop_cards_buttons, shop_buffs_buttons, shop_ball_mods_buttons)
	_configure_shop_manager()
	_set_test_lab_enabled(test_lab_enabled)
	_apply_hud_theme()
	App.bind_button_feedback(self)
	# Buttons removed; use Space to launch and cards/turn flow for control.
	if restart_button:
		restart_button.pressed.connect(_restart_run_same_seed)
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
		reward_skip_button.pressed.connect(_go_to_map)
	if treasure_continue_button:
		treasure_continue_button.pressed.connect(_on_treasure_continue_pressed)
	if shop_leave_button:
		shop_leave_button.pressed.connect(_on_shop_leave_pressed)
	if mods_persist_checkbox:
		mods_persist_checkbox.toggled.connect(func(pressed: bool) -> void:
			persist_ball_mods = pressed
		)
		_apply_persist_checkbox_style()
	if _practice_pending:
		call_deferred("_start_practice_now")
	_set_hud_tooltips()
	if not _practice_pending:
		_start_run()

func start_practice(room_type: String, act_index: int, layout_id: String, floor_index: int = 1) -> void:
	_practice_room_type = room_type.strip_edges().to_lower()
	_practice_act_index = max(1, act_index)
	_practice_layout_id = layout_id.strip_edges()
	_practice_floor_index = max(1, floor_index)
	_practice_pending = true
	if is_node_ready():
		call_deferred("_start_practice_now")

func is_practice_mode() -> bool:
	return practice_mode

func _start_practice_now() -> void:
	_practice_pending = false
	practice_mode = true
	hp = max_hp
	gold = 0
	floor_index = max(1, _practice_floor_index)
	current_is_boss = false
	current_is_elite = false
	starting_hand_size = BASE_STARTING_HAND_SIZE
	ball_mod_counts.clear()
	active_ball_mod = ""
	persist_ball_mods = false
	if mods_persist_checkbox:
		mods_persist_checkbox.button_pressed = false
	active_balls.clear()
	for child in bricks_root.get_children():
		child.queue_free()
	_reset_run_rng()
	if deck_manager:
		deck_manager.set_rng(run_rng)
	if encounter_manager:
		encounter_manager.set_rng(run_rng)
	deck_manager.setup(starting_deck)
	_update_labels()
	var next_state: int = GameState.ENCOUNTER_COMBAT
	match _practice_room_type:
		"boss":
			next_state = GameState.ENCOUNTER_BOSS
		"elite":
			next_state = GameState.ENCOUNTER_ELITE
	state_manager.transition_to(next_state, {})

func set_test_lab_enabled(enabled: bool, panel_visible: bool = true) -> void:
	test_lab_enabled = enabled
	if panel_visible:
		test_lab_entry = true
	_set_test_lab_enabled(enabled, panel_visible)

func _set_test_lab_enabled(enabled: bool, panel_visible: bool = true) -> void:
	if enabled:
		if test_lab_panel == null or not is_instance_valid(test_lab_panel):
			test_lab_panel = TEST_LAB_PANEL_SCENE.instantiate()
			if test_lab_panel.has_method("set_initial_debug_panel_visible"):
				test_lab_panel.set_initial_debug_panel_visible(panel_visible)
		if test_lab_panel and test_lab_panel.get_parent() == null and hud:
			hud.add_child(test_lab_panel)
		if test_lab_panel:
			test_lab_panel.visible = true
		return
	if test_lab_panel and is_instance_valid(test_lab_panel):
		test_lab_panel.queue_free()
	test_lab_panel = null

func set_pending_seed(seed_value: int) -> void:
	pending_seed = seed_value
	has_pending_seed_override = true

func _reset_run_rng() -> void:
	var seed_value: int = 0
	if floor_plan_generator_config == null:
		run_rng.randomize()
		run_seed = 0
		return
	if map_manager:
		seed_value = map_manager.runtime_seed
	if seed_value > 0:
		run_rng.seed = seed_value
		run_seed = seed_value
	else:
		run_rng.randomize()
		run_seed = run_rng.seed

func _apply_act_limits() -> void:
	if act_manager == null:
		return
	max_combat_floors = act_manager.get_max_combat_floors()
	max_floors = act_manager.get_max_floors()

func _scaled_variant_policy(policy: VariantPolicy, multiplier: float) -> VariantPolicy:
	if policy == null:
		return null
	var scaled := policy.duplicate() as VariantPolicy
	if scaled == null:
		return policy
	var scalar: float = max(0.0, multiplier)
	scaled.shield_chance = clamp(policy.shield_chance * scalar, 0.0, 1.0)
	scaled.regen_chance = clamp(policy.regen_chance * scalar, 0.0, 1.0)
	scaled.curse_chance = clamp(policy.curse_chance * scalar, 0.0, 1.0)
	return scaled

func _apply_act_config_to_encounter(config: EncounterConfig, is_elite: bool, is_boss: bool, act_config: Resource) -> void:
	if config == null or act_config == null:
		return
	if is_boss:
		config.base_hp = max(1, int(round(float(config.base_hp) * act_config.boss_hp_multiplier)))
		if act_config.boss_pattern_id != "":
			config.pattern_id = act_config.boss_pattern_id
		if act_config.boss_variant_policy != null:
			config.variant_policy = act_config.boss_variant_policy
			if act_config.boss_variant_chance_multiplier != 1.0:
				config.variant_policy = _scaled_variant_policy(config.variant_policy, act_config.boss_variant_chance_multiplier)
		elif config.variant_policy != null and act_config.variant_chance_multiplier != 1.0:
			config.variant_policy = _scaled_variant_policy(config.variant_policy, act_config.variant_chance_multiplier)
	elif is_elite:
		config.base_hp = max(1, int(round(float(config.base_hp) * act_config.elite_hp_multiplier)))
	if not is_boss and config.variant_policy != null and act_config.variant_chance_multiplier != 1.0:
		config.variant_policy = _scaled_variant_policy(config.variant_policy, act_config.variant_chance_multiplier)

func _get_encounter_gold_reward() -> int:
	if active_act_config == null:
		return 25
	if current_is_elite:
		return active_act_config.elite_gold_reward
	return active_act_config.combat_gold_reward

func _to_string_array(source) -> Array[String]:
	var result: Array[String] = []
	if source == null:
		return result
	if typeof(source) != TYPE_ARRAY:
		return result
	for element in source:
		result.append(String(element))
	return result

func _apply_balance_data(data: Resource) -> void:
	if data.card_config != null:
		card_data = data.card_config.card_data
		card_pool = _to_string_array(data.card_config.card_pool)
		starting_deck = _to_string_array(data.card_config.starting_deck)
	else:
		card_data = data.card_data
		card_pool = _to_string_array(data.card_pool)
		starting_deck = _to_string_array(data.starting_deck)
	var mods: Dictionary = data.ball_mods
	ball_mod_data = mods.get("data", {})
	ball_mod_order = _to_string_array(mods.get("order", []))
	ball_mod_colors = {}
	for mod_id in ball_mod_data.keys():
		var mod: Dictionary = ball_mod_data[mod_id]
		if mod.has("color"):
			ball_mod_colors[mod_id] = mod["color"]
	reward_card_count = data.reward_card_count
	var shop: Dictionary = data.shop_data
	shop_card_price = int(shop.get("card_price", 0))
	shop_max_cards = int(shop.get("max_cards", 0))
	shop_max_hand_size = int(shop.get("max_hand_size", 0))
	shop_remove_price = int(shop.get("remove_price", 0))
	shop_upgrade_price = int(shop.get("upgrade_price", 0))
	shop_upgrade_hand_bonus = int(shop.get("upgrade_hand_bonus", 0))
	shop_vitality_price = int(shop.get("vitality_price", 0))
	shop_vitality_max_hp_bonus = int(shop.get("vitality_max_hp_bonus", 0))
	shop_vitality_heal = int(shop.get("vitality_heal", 0))
	shop_reroll_base_price = int(shop.get("reroll_base_price", 0))
	shop_reroll_multiplier = float(shop.get("reroll_multiplier", 1.0))
	shop_energy_price = int(shop.get("energy_price", 0))
	shop_energy_bonus = int(shop.get("energy_bonus", 0))
	shop_paddle_width_price = int(shop.get("paddle_width_price", 0))
	shop_paddle_width_bonus = float(shop.get("paddle_width_bonus", 0.0))
	shop_paddle_speed_price = int(shop.get("paddle_speed_price", 0))
	shop_paddle_speed_bonus_percent = float(shop.get("paddle_speed_bonus_percent", 0.0))
	shop_reserve_ball_price = int(shop.get("reserve_ball_price", 0))
	shop_reserve_ball_bonus = int(shop.get("reserve_ball_bonus", 0))
	shop_discount_price = int(shop.get("discount_price", 0))
	shop_discount_percent = float(shop.get("discount_percent", 0.0))
	shop_discount_max = int(shop.get("discount_max", 0))
	shop_entry_card_price = int(shop.get("entry_card_price", 0))
	shop_entry_card_count = int(shop.get("entry_card_count", 0))

func _fit_to_viewport() -> void:
	var size: Vector2 = App.get_layout_size()
	_apply_world_offset(size)
	_update_playfield_background(size)
	paddle.position = Vector2(size.x * 0.5, size.y - 240.0)
	if paddle.has_method("set_locked_y"):
		paddle.set_locked_y(paddle.position.y)
	_update_volley_prompt_position()
	call_deferred("_layout_hand_container")
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
	var target_x: float = App.get_layout_size().x * 0.5
	var offset_x: float = target_x - center_x
	if absf(offset_x) < 0.5:
		return
	for brick in bricks_root.get_children():
		if brick is Node2D:
			(brick as Node2D).position.x += offset_x

func _apply_world_offset(layout_size: Vector2) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var offset := Vector2(
		max(0.0, (viewport_size.x - layout_size.x) * 0.5),
		max(0.0, (viewport_size.y - layout_size.y) * 0.5)
	)
	position = offset

func _update_playfield_background(layout_size: Vector2) -> void:
	if playfield == null:
		return
	var half := layout_size * 0.5
	playfield.position = half
	playfield.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])

func _layout_hand_container() -> void:
	if hand_bar == null or hand_container == null or deck_stack == null or discard_stack == null:
		return
	var hand_bar_rect: Rect2 = hand_bar.get_global_rect()
	var deck_rect: Rect2 = deck_stack.get_global_rect()
	var discard_rect: Rect2 = discard_stack.get_global_rect()
	var left_edge: float = (deck_rect.position.x + deck_rect.size.x) - hand_bar_rect.position.x + 12.0
	var right_edge: float = discard_rect.position.x - hand_bar_rect.position.x - 12.0
	var hand_width: float = max(0.0, right_edge - left_edge)
	hand_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hand_container.position = Vector2(left_edge, 8.0)
	hand_container.size = Vector2(hand_width, hand_bar.size.y - 16.0)
	if hand_container is BoxContainer:
		(hand_container as BoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER

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

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if map_preview_active:
			_toggle_map_preview()
			return
		if deck_panel and deck_panel.visible:
			_close_deck_panel()
			return
		App.show_menu()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var preview_key: InputEventKey = event
		if preview_key.keycode == KEY_M:
			_toggle_map_preview()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event: InputEventKey = event
		if key_event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			if state == GameState.VOLLEY and active_balls.is_empty() and volley_ball_reserve > 0:
				_prompt_forfeit_volley()
			#early return for ENTER - regardless of context
			#avoids ui_accept mapping trigger
			return
	if state == GameState.PLANNING and event.is_action_pressed("ui_accept"):
		_transition_event("launch_volley")
		get_viewport().set_input_as_handled()
	if state == GameState.VOLLEY and event.is_action_pressed("ui_accept") and reserve_launch_cooldown <= 0.0:
		_launch_reserve_ball()
		get_viewport().set_input_as_handled()
	if state == GameState.PLANNING and event.is_action_pressed("ui_select"):
		_end_turn()

func _process(delta: float) -> void:
	if reserve_launch_cooldown > 0.0:
		reserve_launch_cooldown = max(0.0, reserve_launch_cooldown - delta)
	if state == GameState.GAME_OVER and not _end_encounter_in_progress and encounter_manager and encounter_manager.check_victory():
		_handle_gameover_victory()

func _transition_event(event: String, context: Dictionary = {}) -> void:
	var did_transition: bool = state_manager.transition_event(event, context)
	if not did_transition:
		push_warning("State transition '%s' not allowed from %s." % [event, str(state)])

func _on_state_changed(prev_state: int, next_state: int, context: Dictionary) -> void:
	_on_exit_state(prev_state, next_state, context)
	state = next_state
	_on_enter_state(next_state, prev_state, context)

func _on_exit_state(_prev_state: int, _next_state: int, _context: Dictionary) -> void:
	pass

func _on_enter_state(next_state: int, _prev_state: int, context: Dictionary) -> void:
	if context.get("resume", false):
		_restore_panels_for_state(next_state)
		return
	match next_state:
		GameState.MAP:
			_show_map()
		GameState.SHOP:
			_show_shop()
		GameState.TREASURE:
			var reroll: bool = true
			if context.has("reroll"):
				reroll = bool(context["reroll"])
			_show_treasure_panel(reroll)
		GameState.REWARD:
			_show_reward_panel()
		GameState.REST:
			_show_rest()
		GameState.GAME_OVER:
			_show_game_over()
		GameState.VICTORY:
			_show_victory()
		GameState.PLANNING:
			if context.has("encounter_start") and bool(context["encounter_start"]):
				var is_elite: bool = bool(context.get("is_elite", false))
				var is_boss: bool = bool(context.get("is_boss", false))
				_begin_encounter(is_elite, is_boss)
			else:
				_start_turn()
		GameState.VOLLEY:
			_launch_volley()
		GameState.ENCOUNTER_COMBAT:
			var encounter_context: Dictionary = context.duplicate()
			encounter_context["encounter_start"] = true
			encounter_context["is_elite"] = false
			encounter_context["is_boss"] = false
			state_manager.transition_event("start_encounter", encounter_context)
		GameState.ENCOUNTER_ELITE:
			var elite_context: Dictionary = context.duplicate()
			elite_context["encounter_start"] = true
			elite_context["is_elite"] = true
			elite_context["is_boss"] = false
			state_manager.transition_event("start_encounter", elite_context)
		GameState.ENCOUNTER_BOSS:
			var boss_context: Dictionary = context.duplicate()
			boss_context["encounter_start"] = true
			boss_context["is_elite"] = false
			boss_context["is_boss"] = true
			state_manager.transition_event("start_encounter", boss_context)
func _start_run(event: String = "") -> void:
	hp = max_hp
	gold = 60
	floor_index = 0
	current_is_boss = false
	current_is_elite = false
	starting_hand_size = BASE_STARTING_HAND_SIZE
	ball_mod_counts.clear()
	active_ball_mod = ""
	persist_ball_mods = false
	if mods_persist_checkbox:
		mods_persist_checkbox.button_pressed = false
	active_balls.clear()
	for child in bricks_root.get_children():
		child.queue_free()
	_generate_floor_plan_if_needed()
	_reset_run_rng()
	if deck_manager:
		deck_manager.set_rng(run_rng)
	if encounter_manager:
		encounter_manager.set_rng(run_rng)
	if map_manager:
		map_manager.set_rng(run_rng)
	deck_manager.setup(starting_deck)
	map_manager.reset_run()
	if act_manager:
		act_manager.refresh_limits(max_combat_floors)
	_apply_act_limits()
	var start_event: String = event
	if start_event == "":
		start_event = "start_test_lab" if test_lab_entry else "start_run"
	_transition_event(start_event)

func _restart_run_same_seed() -> void:
	App.stop_combat_music()
	App.stop_shop_music()
	if floor_plan_generator_config is FLOOR_PLAN_GENERATOR_CONFIG:
		var seed_value: int = 0
		if map_manager:
			seed_value = map_manager.runtime_seed
		floor_plan_generator_config.seed_value = seed_value if seed_value > 0 else 0
	_start_run("restart_run")

func _show_map() -> void:
	if _between_act_pending:
		_between_act_pending = false
		_start_between_act_sequence()
		return
	App.stop_shop_music()
	var rest_active: bool = App.is_rest_music_active()
	if not rest_active:
		App.start_menu_music()
	_hide_all_panels()
	map_panel.visible = true
	_update_map_label()
	if get_viewport():
		get_viewport().gui_release_focus()
	var choices := _build_map_buttons()
	call_deferred("_focus_map_buttons_deferred")
	_update_map_graph(choices)
	var display_floor: int = min(floor_index + 1, max_floors)
	floor_label.text = "Floor %d/%d" % [display_floor, max_floors]
	_update_seed_display()
	map_preview_active = false
	_update_volley_prompt_visibility()

func _go_to_map() -> void:
	_transition_event("go_to_map")

func _update_map_label() -> void:
	if map_label == null:
		return
	if map_manager != null and map_manager.has_acts():
		map_label.text = "Act %d Map" % (map_manager.get_active_act_index() + 1)
	else:
		map_label.text = "Map"

func _start_between_act_sequence() -> void:
	if practice_mode:
		return
	_between_act_step = BetweenActStep.BUFF
	_show_between_act_buff_choice()

func _clear_container_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

func _between_act_buff_candidates() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	options.append({
		"id": "upgrade_hand",
		"text": "Upgrade starting hand (+%d)" % shop_upgrade_hand_bonus,
		"enabled": shop_upgrade_hand_bonus > 0 and (shop_max_hand_size <= 0 or starting_hand_size < shop_max_hand_size)
	})
	options.append({
		"id": "vitality",
		"text": "Vitality (+%d max HP, heal %d)" % [shop_vitality_max_hp_bonus, shop_vitality_heal],
		"enabled": shop_vitality_max_hp_bonus > 0 or shop_vitality_heal > 0
	})
	options.append({
		"id": "surge",
		"text": "Surge (+%d max energy)" % shop_energy_bonus,
		"enabled": shop_energy_bonus > 0 and max_energy_bonus < 2
	})
	options.append({
		"id": "paddle_width",
		"text": "Wider Paddle (+%d width)" % int(round(shop_paddle_width_bonus)),
		"enabled": shop_paddle_width_bonus > 0.0
	})
	options.append({
		"id": "paddle_speed",
		"text": "Paddle Speed (+%d%%)" % int(round(shop_paddle_speed_bonus_percent)),
		"enabled": shop_paddle_speed_bonus_percent > 0.0
	})
	options.append({
		"id": "reserve_ball",
		"text": "Reserve Ball (+%d per volley)" % shop_reserve_ball_bonus,
		"enabled": shop_reserve_ball_bonus > 0 and volley_ball_bonus_base < 1
	})
	options.append({
		"id": "shop_discount",
		"text": "Shop Discount (-%d%% prices)" % int(round(shop_discount_percent)),
		"enabled": shop_discount_percent > 0.0 and (shop_discount_max <= 0 or shop_discount_multiplier > (1.0 - float(shop_discount_max) * (shop_discount_percent / 100.0)))
	})
	options.append({
		"id": "shop_scribe",
		"text": "Shop Scribe (+%d card on entry)" % shop_entry_card_count,
		"enabled": shop_entry_card_count > 0
	})
	return options

func _roll_between_act_buffs(count: int = 3) -> Array[Dictionary]:
	var candidates := _between_act_buff_candidates()
	var enabled: Array[Dictionary] = []
	for option in candidates:
		if bool(option.get("enabled", true)):
			enabled.append(option)
	var picked: Array[Dictionary] = []
	if enabled.is_empty():
		return picked
	var target: int = min(count, enabled.size())
	while picked.size() < target:
		var idx: int = run_rng.randi_range(0, enabled.size() - 1)
		picked.append(enabled.pop_at(idx))
	return picked

func _apply_between_act_buff(buff_id: String) -> void:
	match buff_id:
		"upgrade_hand":
			_upgrade_starting_hand(shop_upgrade_hand_bonus)
		"vitality":
			_apply_vitality(shop_vitality_max_hp_bonus, shop_vitality_heal)
		"surge":
			_apply_max_energy_buff(shop_energy_bonus)
		"paddle_width":
			_apply_paddle_width_buff(shop_paddle_width_bonus)
		"paddle_speed":
			_apply_paddle_speed_buff(shop_paddle_speed_bonus_percent)
		"reserve_ball":
			_apply_reserve_ball_buff(shop_reserve_ball_bonus)
		"shop_discount":
			_apply_shop_discount(shop_discount_percent)
		"shop_scribe":
			_apply_shop_entry_cards(shop_entry_card_count)

func _show_between_act_buff_choice() -> void:
	_hide_all_panels()
	_show_single_panel(shop_panel)
	if shop_label:
		shop_label.text = "Between Acts: Choose a Buff"
	if shop_info_label:
		shop_info_label.text = "Pick one of three random buffs."
	if shop_gold_label:
		shop_gold_label.visible = false
	if shop_cards_panel:
		shop_cards_panel.visible = false
	if shop_ball_mods_panel:
		shop_ball_mods_panel.visible = false
	if shop_buffs_panel:
		shop_buffs_panel.visible = true
	if shop_leave_button:
		shop_leave_button.visible = false

	_clear_container_children(shop_buffs_buttons)
	var buffs := _roll_between_act_buffs(3)
	if buffs.is_empty():
		_between_act_step = BetweenActStep.TREASURE
		_show_between_act_treasure()
		return
	for buff in buffs:
		var buff_id: String = String(buff.get("id", ""))
		var text: String = String(buff.get("text", buff_id))
		var button := Button.new()
		button.text = text
		button.pressed.connect(func() -> void:
			_apply_between_act_buff(buff_id)
			_update_labels()
			_between_act_step = BetweenActStep.TREASURE
			_show_between_act_treasure()
		)
		App.apply_neutral_button_style(button)
		App.bind_button_feedback(button)
		shop_buffs_buttons.add_child(button)
	_focus_shop_buttons()
	_update_volley_prompt_visibility()

func _show_between_act_treasure() -> void:
	_hide_all_panels()
	_show_treasure_panel(true)
	if treasure_label:
		treasure_label.text = "Between Acts: Treasure"
	if treasure_continue_button:
		treasure_continue_button.text = "Continue"
	_between_act_step = BetweenActStep.TREASURE

func _begin_between_act_rest() -> void:
	_between_act_step = BetweenActStep.REST
	_show_rest()

func _begin_between_act_shop() -> void:
	_between_act_step = BetweenActStep.SHOP
	_show_shop()
	if shop_label:
		shop_label.text = "Between Acts: Shop"
	if shop_info_label:
		shop_info_label.text = "Spend gold, then continue."
	if shop_gold_label:
		shop_gold_label.visible = true
	if shop_cards_panel:
		shop_cards_panel.visible = true
	if shop_ball_mods_panel:
		shop_ball_mods_panel.visible = true
	if shop_leave_button:
		shop_leave_button.visible = true
		shop_leave_button.text = "Continue"

func _end_between_act_sequence() -> void:
	_between_act_step = BetweenActStep.NONE
	if shop_leave_button:
		shop_leave_button.text = "Leave"
	_transition_event("go_to_map")

func _on_treasure_continue_pressed() -> void:
	if _between_act_step == BetweenActStep.TREASURE:
		_begin_between_act_rest()
		return
	_go_to_map()

func _on_shop_leave_pressed() -> void:
	if _between_act_step == BetweenActStep.SHOP:
		_end_between_act_sequence()
		return
	_go_to_map()

func _show_map_preview() -> void:
	if map_panel == null:
		return
	_hide_all_panels()
	map_panel.visible = true
	_clear_map_buttons()
	_update_map_graph([])
	_update_seed_display()
	_update_volley_prompt_visibility()

func _hide_all_panels() -> void:
	if hud_controller:
		hud_controller.hide_all_panels()
	_hide_outcome_overlays()
	_update_volley_prompt_visibility()

func _toggle_map_preview() -> void:
	if map_preview_active:
		map_preview_active = false
		map_panel.visible = false
		_restore_panels_for_state(map_preview_state)
		return
	map_preview_active = true
	map_preview_state = state
	_show_map_preview()

func _generate_floor_plan_if_needed() -> void:
	if floor_plan_generator_config == null:
		return
	var generator := FLOOR_PLAN_GENERATOR.new()
	var plan := generator.generate(floor_plan_generator_config)
	if plan.is_empty():
		return
	map_manager.set_runtime_floor_plan(plan)
	_update_seed_display()

func _update_seed_display() -> void:
	if map_seed_label == null:
		return
	if run_seed > 0:
		map_seed_label.text = "Seed: %d" % run_seed
	else:
		map_seed_label.text = "Seed: N/A"

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

func _build_map_buttons() -> Array[Dictionary]:
	_clear_map_buttons()
	var choices: Array[Dictionary] = map_manager.build_room_choices(floor_index, max_combat_floors)
	for choice in choices:
		var room_type: String = String(choice.get("type", "combat"))
		var room_id: String = String(choice.get("id", ""))
		var selected_room_type := room_type
		var selected_room_id := room_id
		var button := Button.new()
		button.text = map_manager.room_label(selected_room_type)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(func() -> void:
			map_manager.advance_to_room(selected_room_id)
			_enter_room(selected_room_type)
		)
		App.bind_button_feedback(button)
		map_buttons.add_child(button)
	return choices

func _focus_map_buttons() -> void:
	if map_buttons == null:
		return
	var buttons: Array[Button] = []
	for child in map_buttons.get_children():
		if child is Button:
			buttons.append(child as Button)
	if buttons.is_empty():
		return
	var count := buttons.size()
	for i in range(count):
		var button := buttons[i]
		button.focus_mode = Control.FOCUS_ALL
		if count > 1:
			var next := buttons[(i + 1) % count]
			var prev := buttons[(i - 1 + count) % count]
			button.focus_next = next.get_path()
			button.focus_previous = prev.get_path()
	buttons[0].grab_focus()

func _focus_map_buttons_deferred() -> void:
	await get_tree().process_frame
	_focus_map_buttons()

func _focus_shop_buttons() -> void:
	if shop_panel == null:
		return
	var buttons: Array[BaseButton] = []
	_collect_buttons(shop_panel, buttons)
	_apply_focus_chain(buttons)

func _collect_buttons(node: Node, buttons: Array[BaseButton]) -> void:
	for child in node.get_children():
		if child is BaseButton:
			buttons.append(child as BaseButton)
		_collect_buttons(child, buttons)

func _apply_focus_chain(buttons: Array[BaseButton]) -> void:
	if buttons.is_empty():
		return
	var ordered: Array[BaseButton] = []
	for button in buttons:
		if button == null or not button.visible:
			continue
		button.focus_mode = Control.FOCUS_ALL
		ordered.append(button)
	if ordered.is_empty():
		return
	var count := ordered.size()
	for i in range(count):
		var button := ordered[i]
		if count > 1:
			var next := ordered[(i + 1) % count]
			var prev := ordered[(i - 1 + count) % count]
			button.focus_next = next.get_path()
			button.focus_previous = prev.get_path()
	ordered[0].grab_focus()

func _clear_map_buttons() -> void:
	if map_buttons == null:
		return
	for child in map_buttons.get_children():
		child.queue_free()

func _restore_panels_for_state(target_state: int) -> void:
	match target_state:
		GameState.MAP:
			_show_map()
		GameState.SHOP:
			_show_single_panel(shop_panel)
		GameState.TREASURE:
			_show_treasure_panel(false)
		GameState.REWARD:
			_show_reward_panel()
		GameState.GAME_OVER, GameState.VICTORY:
			_hide_all_panels()
			if gameover_panel:
				gameover_panel.visible = true
			_hide_outcome_overlays()
			if target_state == GameState.VICTORY and victory_overlay:
				victory_overlay.visible = true
			elif target_state == GameState.GAME_OVER and defeat_overlay:
				defeat_overlay.visible = true
		_:
			_hide_all_panels()

func _update_map_graph(choices: Array[Dictionary]) -> void:
	if map_graph == null or not map_graph.has_method("set_plan"):
		return
	var plan := map_manager.get_active_plan_summary()
	var boss_label: String = ""
	if act_manager != null:
		var act_config: Resource = act_manager.get_active_act_config()
		if act_config != null:
			boss_label = String(act_config.boss_label)
	plan["boss_label"] = boss_label
	map_graph.call("set_plan", plan, choices)

func _enter_room(room_type: String) -> void:
	if room_type == "mystery":
		var revealed := _reveal_mystery_room()
		_enter_room(revealed)
		return
	match room_type:
		"rest":
			_transition_event("enter_room_rest")
		"treasure":
			_transition_event("enter_room_treasure")
		"shop":
			_transition_event("enter_room_shop")
		"victory":
			assert(false, "Victory rooms should not be reachable from the map.")
		"elite":
			floor_index += 1
			_transition_event("enter_room_elite")
		"boss":
			floor_index += 1
			_transition_event("enter_room_boss")
		_:
			floor_index += 1
			_transition_event("enter_room_combat")

func _reveal_mystery_room() -> String:
	if map_manager == null:
		return "combat"
	var revealed := map_manager.reveal_current_mystery_room()
	if revealed == "":
		revealed = "combat"
	return revealed

func _start_encounter(is_elite: bool) -> void:
	var event_name: String = "enter_room_elite" if is_elite else "enter_room_combat"
	_transition_event(event_name)

func _start_boss() -> void:
	_transition_event("enter_room_boss")

func _begin_encounter(is_elite: bool, is_boss: bool) -> void:
	_hide_all_panels()
	current_is_elite = is_elite
	encounter_has_launched = false
	App.stop_rest_music()
	App.start_menu_music()
	if practice_mode:
		active_act_config = _load_act_config(_practice_act_index)
		if active_act_config == null:
			active_act_config = ACT_CONFIG_SCRIPT.new()
		act_ball_speed_multiplier = float(active_act_config.ball_speed_multiplier) if active_act_config != null else 1.0
		act_threat_multiplier = float(active_act_config.block_threat_multiplier) if active_act_config != null else 1.0
		info_label.text = "Practice: Boss fight." if is_boss else "Practice: Plan your volley, then launch."
	elif act_manager != null:
		active_act_config = act_manager.get_active_act_config()
		act_ball_speed_multiplier = act_manager.get_ball_speed_multiplier()
		act_threat_multiplier = act_manager.get_block_threat_multiplier()
		info_label.text = act_manager.get_intro_text(is_elite, is_boss)
	else:
		active_act_config = ACT_CONFIG_SCRIPT.new()
		act_ball_speed_multiplier = 1.0
		act_threat_multiplier = 1.0
		info_label.text = "Boss fight. Plan carefully." if is_boss else "Plan your volley, then launch."
	_clear_active_balls()
	_reset_deck_for_next_floor()
	current_is_boss = is_boss
	var config := encounter_manager.build_config_from_floor(floor_index, is_elite, is_boss)
	_apply_act_config_to_encounter(config, is_elite, is_boss, active_act_config)
	if practice_mode and _practice_layout_id != "":
		config.pattern_id = _practice_layout_id
	current_pattern = config.pattern_id
	encounter_speed_boost = config.speed_boost
	encounter_rows = config.rows
	encounter_cols = config.cols
	encounter_hp = config.base_hp
	if encounter_speed_boost and not is_boss:
		info_label.text = "Volley Mod: Speed Boost."
	encounter_manager.start_encounter(config, Callable(self, "_on_brick_destroyed"), Callable(self, "_on_brick_damaged"))
	_start_turn()

func _start_turn() -> void:
	if not encounter_has_launched:
		App.stop_rest_music()
		App.start_menu_music()
	energy = max_energy
	block = 0
	volley_damage_bonus = 0
	volley_ball_bonus = volley_ball_bonus_base
	volley_ball_reserve = 0
	parry_wound_active = false
	riposte_wound_active = false
	_update_reserve_indicator()
	volley_piercing = false
	volley_ball_speed_multiplier = 1.0
	_apply_paddle_buffs()
	deck_manager.draw_cards(starting_hand_size)
	_refresh_hand()
	_refresh_mod_buttons()
	_update_labels()
	_update_volley_prompt_visibility()
	_update_volley_prompt_position()

func _end_turn() -> void:
	print("POTENTIAL DEAD CODE: _end_turn invoked")
	if state != GameState.PLANNING:
		return
	_discard_hand()
	var incoming: int = max(0, encounter_manager.calculate_threat(act_threat_multiplier) - block)
	hp -= incoming
	hp = max(0, hp)
	info_label.text = "You take %d damage." % incoming
	if hp <= 0:
		_transition_event("planning_lose")
		return
	_start_turn()

func _launch_volley() -> void:
	encounter_has_launched = true
	App.stop_menu_music()
	App.start_combat_music()
	var total_balls: int = 1 + volley_ball_bonus
	volley_ball_reserve = max(0, total_balls - 1)
	_update_reserve_indicator()
	reserve_launch_cooldown = 0.1
	_spawn_volley_ball()
	info_label.text = "Volley in motion."
	_update_volley_prompt_visibility()

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
	speed_multiplier *= App.get_ball_speed_multiplier()
	speed_multiplier *= act_ball_speed_multiplier
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
	ball.caught.connect(_on_ball_caught)
	ball.mod_consumed.connect(_on_ball_mod_consumed)
	active_balls.append(ball)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_ball_lost(ball: Node) -> void:
	active_balls.erase(ball)
	if is_instance_valid(ball):
		ball.queue_free()
	encounter_manager.regen_bricks_on_drop()
	if current_is_boss and encounter_manager:
		encounter_manager.drop_bricks_one_row()
		App.play_boss_drop_sfx(boss_drop_player)
	if active_balls.is_empty():
		if encounter_manager.check_victory():
			_end_encounter()
			return
		if volley_ball_reserve > 0:
			info_label.text = "Press Space to launch the next ball or Enter to end the volley."
			return
		_apply_volley_threat()

func _on_ball_caught(_ball: Node) -> void:
	if state != GameState.PLANNING:
		return
	if encounter_manager and encounter_manager.check_victory():
		await _play_planning_victory_message(_get_planning_victory_message())

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
		threat = encounter_manager.calculate_threat(act_threat_multiplier)
	var incoming: int = max(0, threat - block)
	hp -= incoming
	hp = max(0, hp)
	if hp <= 0:
		_transition_event("volley_lose")
		return
	info_label.text = "Ball lost. You take %d damage." % incoming
	_transition_event("volley_continue")

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

func _end_encounter(win_event: String = "volley_win") -> void:
	if _end_encounter_in_progress:
		return
	_end_encounter_in_progress = true
	App.stop_combat_music()
	_hide_all_panels()
	_clear_active_balls()
	_reset_deck_for_next_floor()
	if practice_mode:
		_end_encounter_in_progress = false
		App.end_run_to_menu()
		return
	if current_is_boss:
		if map_manager != null and map_manager.has_acts():
			var act_index: int = map_manager.get_active_act_index()
			if map_manager.is_final_act():
				_end_encounter_in_progress = false
				_transition_event("victory")
			else:
				_spawn_act_complete_particles()
				await _play_planning_victory_message("Well done! Act %d Complete!" % (act_index + 1))
				map_manager.advance_act()
				if act_manager:
					act_manager.refresh_limits()
				_apply_act_limits()
				_between_act_pending = true
				_end_encounter_in_progress = false
				_transition_event("advance_act")
			return
		else:
			_end_encounter_in_progress = false
			_transition_event("victory")
		return
	gold += _get_encounter_gold_reward()
	if state == GameState.PLANNING:
		await _play_planning_victory_message(_get_planning_victory_message())
	_end_encounter_in_progress = false
	_transition_event(win_event)

func _load_act_config(act_index: int) -> Resource:
	var safe_index: int = max(1, act_index)
	var path: String = "%s/act_%d.tres" % [ACT_CONFIG_DIR, safe_index]
	return ResourceLoader.load(path)

func _get_planning_victory_message() -> String:
	if planning_victory_messages.is_empty():
		return "Nice one!"
	var index: int = run_rng.randi_range(0, planning_victory_messages.size() - 1)
	return String(planning_victory_messages[index])

func _play_planning_victory_message(message: String) -> void:
	await _show_toast(message, Color(1.0, 0.9, 0.2, 1.0), 2.0)

func _apply_victory_revive() -> void:
	hp = max(0, hp)
	hp = min(max_hp, hp + VICTORY_REVIVE_HP_BONUS)
	_update_labels()
	_show_toast(VICTORY_REVIVE_TOAST, Color(1.0, 0.9, 0.2, 1.0), 2.0)

func _handle_gameover_victory() -> void:
	if gameover_panel:
		gameover_panel.visible = false
	info_label.text = ""
	_apply_victory_revive()
	_end_encounter("resurrect")

func _create_toast(message: String, tint: Color, hold_duration: float) -> Dictionary:
	if info_label == null or hud == null:
		return {}
	var toast := Label.new()
	toast.text = message
	toast.modulate = tint
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.size = info_label.size
	toast.position = info_label.position
	hud.add_child(toast)
	var original_pos: Vector2 = toast.global_position
	if paddle != null:
		original_pos.y = paddle.global_position.y + VOLLEY_PROMPT_OFFSET_Y
	elif volley_prompt_label != null:
		original_pos.y = volley_prompt_label.global_position.y
	var viewport_width: float = get_viewport_rect().size.x
	toast.global_position = Vector2(viewport_width + toast.size.x, original_pos.y)
	return {"toast": toast, "pos": original_pos, "hold": max(0.0, hold_duration)}

func _animate_toast(toast_data: Dictionary) -> Tween:
	var toast := toast_data.get("toast") as Label
	var original_pos: Vector2 = toast_data.get("pos", Vector2.ZERO)
	var hold_duration: float = float(toast_data.get("hold", 2.0))
	var tween := create_tween()
	tween.tween_property(toast, "global_position:x", original_pos.x, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_duration)
	tween.tween_property(toast, "global_position:x", -toast.size.x, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if toast and is_instance_valid(toast):
			toast.queue_free()
	)
	return tween

const MAX_TOAST_QUEUE: int = 8
var _toast_queue: Array[Dictionary] = []
var _toast_runner_active: bool = false
var _toast_next_token: int = 1

func _enqueue_toast(message: String, tint: Color, hold_duration: float, token: int) -> void:
	if message.strip_edges() == "":
		toast_request_completed.emit(token)
		return
	if _toast_queue.size() >= MAX_TOAST_QUEUE:
		var dropped: Dictionary = _toast_queue.pop_front()
		if dropped.has("token"):
			toast_request_completed.emit(int(dropped.get("token")))
	_toast_queue.append({
		"message": message,
		"tint": tint,
		"hold": hold_duration,
		"token": token
	})

func _ensure_toast_runner() -> void:
	if _toast_runner_active:
		return
	_toast_runner_active = true
	call_deferred("_run_toast_queue")

func _await_toast_token(token: int) -> void:
	while true:
		var completed = await toast_request_completed
		var completed_token: int = completed if typeof(completed) == TYPE_INT else int(completed[0])
		if completed_token == token:
			return

func _run_toast_queue() -> void:
	while not _toast_queue.is_empty():
		var entry: Dictionary = _toast_queue.pop_front()
		var token: int = int(entry.get("token", 0))
		var toast_data := _create_toast(
			String(entry.get("message", "")),
			entry.get("tint", Color(1, 1, 1, 1)),
			float(entry.get("hold", 2.0))
		)
		if not toast_data.is_empty():
			var tween := _animate_toast(toast_data)
			await tween.finished
		toast_request_completed.emit(token)
	_toast_runner_active = false

func _show_toast(message: String, tint: Color, hold_duration: float) -> void:
	var token: int = _toast_next_token
	_toast_next_token += 1
	_enqueue_toast(message, tint, hold_duration, token)
	_ensure_toast_runner()
	await _await_toast_token(token)

func _reset_deck_for_next_floor() -> void:
	if deck_manager:
		deck_manager.reset_piles()
	_refresh_hand()
	_update_labels()

func _build_reward_buttons() -> void:
	if reward_manager == null:
		return
	reward_manager.build_card_rewards(Callable(self, "_pick_random_card"))

func _on_reward_selected(card_id: String) -> void:
	_add_card_to_deck(card_id)
	_go_to_map()

func test_lab_pass_level() -> void:
	if _end_encounter_in_progress:
		return
	if bricks_root != null:
		for child in bricks_root.get_children():
			child.queue_free()
	if state == GameState.GAME_OVER or state == GameState.VICTORY:
		state_manager.transition_to(GameState.PLANNING, {"resume": true})
	_end_encounter()

func _show_shop() -> void:
	App.stop_menu_music()
	var rest_active: bool = App.is_rest_music_active()
	if not rest_active:
		App.start_shop_music()
	_show_single_panel(shop_panel)
	info_label.text = ""
	shop_discount_multiplier = 1.0
	if shop_manager:
		shop_manager.reset_shop_limits()
		shop_manager.reset_offers(Callable(self, "_pick_random_card"))
		_configure_shop_manager()
	_apply_shop_entry_bonus()
	_build_shop_buttons()
	_focus_shop_buttons()
	_refresh_mod_buttons()
	_update_labels()
	_update_volley_prompt_visibility()

func _apply_shop_entry_bonus() -> void:
	if shop_entry_card_bonus <= 0:
		return
	_add_shop_entry_offers(shop_entry_card_bonus, "Shop bonus")

func _add_shop_entry_offers(amount: int, label_prefix: String) -> void:
	if amount <= 0:
		return
	if shop_manager == null:
		return
	var added_cards := shop_manager.add_card_offers(Callable(self, "_pick_random_card"), amount)
	if added_cards.is_empty():
		return
	_build_shop_buttons()
	var added_names: Array[String] = []
	for card_id in added_cards:
		if card_data.has(card_id):
			added_names.append(String(card_data[card_id]["name"]))
		else:
			added_names.append(card_id)
	if added_names.is_empty():
		return
	var names_text := ""
	for i in range(added_names.size()):
		if i > 0:
			names_text += ", "
		names_text += added_names[i]
	info_label.text = "%s: added %s." % [label_prefix, names_text]

func _apply_hud_theme() -> void:
	if hud == null:
		return
	var theme := App.get_global_theme()
	if theme == null:
		return
	_apply_theme_recursive(hud, theme)
	_apply_hud_button_exclusions()

func _apply_theme_recursive(node: Node, theme: Theme) -> void:
	if node is Control:
		(node as Control).theme = theme
	for child in node.get_children():
		_apply_theme_recursive(child, theme)

func _apply_hud_button_exclusions() -> void:
	var blank := Theme.new()
	if deck_button:
		deck_button.theme = blank
		deck_button.add_to_group(App.UI_PARTICLE_IGNORE_GROUP)
	if discard_button:
		discard_button.theme = blank
		discard_button.add_to_group(App.UI_PARTICLE_IGNORE_GROUP)
	if mods_persist_checkbox:
		mods_persist_checkbox.add_to_group(App.UI_PARTICLE_IGNORE_GROUP)

func _show_treasure() -> void:
	_show_treasure_panel()

func _build_shop_buttons() -> void:
	if shop_manager == null:
		return
	shop_manager.build_shop_buttons()

func _build_shop_card_buttons() -> void:
	if shop_manager == null:
		return
	shop_manager.build_shop_card_buttons()

func _reroll_shop_cards() -> void:
	if shop_manager == null:
		return
	var price: int = shop_manager.get_reroll_price()
	if not _can_afford(price):
		_set_info_text("Not enough gold.")
		return
	_spend_gold(price)
	shop_manager.reroll_offers(Callable(self, "_pick_random_card"))
	_build_shop_card_buttons()
	_update_labels()

func _shop_callbacks() -> Dictionary:
	return {
		"can_afford": Callable(self, "_can_afford"),
		"spend_gold": Callable(self, "_spend_gold"),
		"add_card": Callable(self, "_add_card_to_deck"),
		"update_labels": Callable(self, "_update_labels"),
		"set_info": Callable(self, "_set_info_text"),
		"show_remove_card_panel": Callable(self, "_show_remove_card_panel"),
		"get_deck_size": Callable(self, "_get_deck_size"),
		"reroll": Callable(self, "_reroll_shop_cards"),
		"upgrade_hand": Callable(self, "_upgrade_starting_hand"),
		"get_starting_hand_size": Callable(self, "_get_starting_hand_size"),
		"apply_vitality": Callable(self, "_apply_vitality"),
		"apply_max_energy": Callable(self, "_apply_max_energy_buff"),
		"get_max_energy_bonus": Callable(self, "_get_max_energy_bonus"),
		"apply_paddle_width": Callable(self, "_apply_paddle_width_buff"),
		"apply_paddle_speed": Callable(self, "_apply_paddle_speed_buff"),
		"apply_reserve_ball": Callable(self, "_apply_reserve_ball_buff"),
		"get_reserve_ball_bonus": Callable(self, "_get_reserve_ball_bonus"),
		"apply_shop_discount": Callable(self, "_apply_shop_discount"),
		"apply_shop_entry_cards": Callable(self, "_apply_shop_entry_cards"),
		"refresh_shop_buttons": Callable(self, "_build_shop_buttons"),
		"refresh_mod_buttons": Callable(self, "_refresh_mod_buttons")
	}

func _get_discounted_shop_price(price: int) -> int:
	if price <= 0:
		return price
	return max(1, int(round(float(price) * shop_discount_multiplier)))

func _configure_shop_manager() -> void:
	if shop_manager == null:
		return
	var shop_config: Dictionary = {
		"card_data": card_data,
		"card_price": _get_discounted_shop_price(shop_card_price),
		"max_card_offers": shop_max_cards,
		"remove_price": _get_discounted_shop_price(shop_remove_price),
		"upgrade_hand_bonus": shop_upgrade_hand_bonus,
		"upgrade_price": _get_discounted_shop_price(shop_upgrade_price),
		"max_hand_size": shop_max_hand_size,
		"vitality_max_hp_bonus": shop_vitality_max_hp_bonus,
		"vitality_heal": shop_vitality_heal,
		"vitality_price": _get_discounted_shop_price(shop_vitality_price),
		"energy_buff_price": _get_discounted_shop_price(shop_energy_price),
		"energy_buff_bonus": shop_energy_bonus,
		"paddle_width_price": _get_discounted_shop_price(shop_paddle_width_price),
		"paddle_width_bonus": shop_paddle_width_bonus,
		"paddle_speed_price": _get_discounted_shop_price(shop_paddle_speed_price),
		"paddle_speed_bonus_percent": shop_paddle_speed_bonus_percent,
		"reserve_ball_price": _get_discounted_shop_price(shop_reserve_ball_price),
		"reserve_ball_bonus": shop_reserve_ball_bonus,
		"shop_discount_price": shop_discount_price,
		"shop_discount_percent": shop_discount_percent,
		"shop_discount_max": shop_discount_max,
		"shop_entry_card_price": _get_discounted_shop_price(shop_entry_card_price),
		"shop_entry_card_count": shop_entry_card_count,
		"reroll_base_price": shop_reroll_base_price,
		"reroll_multiplier": shop_reroll_multiplier,
		"ball_mod_data": ball_mod_data,
		"ball_mod_order": ball_mod_order,
		"ball_mod_counts": ball_mod_counts,
		"ball_mod_colors": ball_mod_colors
	}
	shop_manager.configure(shop_config)
	shop_manager.set_callbacks(_shop_callbacks())

func _can_afford(price: int) -> bool:
	return gold >= price

func _spend_gold(price: int) -> void:
	gold -= price

func _set_info_text(text: String) -> void:
	info_label.text = text

func _get_deck_size() -> int:
	if deck_manager:
		return deck_manager.deck.size()
	return 0

func _upgrade_starting_hand(bonus: int) -> int:
	if shop_max_hand_size > 0:
		starting_hand_size = min(starting_hand_size + bonus, shop_max_hand_size)
	else:
		starting_hand_size += bonus
	return starting_hand_size

func _get_starting_hand_size() -> int:
	return starting_hand_size

func _apply_vitality(max_bonus: int, heal: int) -> int:
	max_hp += max_bonus
	hp = min(max_hp, hp + heal)
	return max_hp

func _apply_max_energy_buff(bonus: int) -> int:
	max_energy_bonus = min(2, max_energy_bonus + bonus)
	max_energy = base_max_energy + max_energy_bonus
	energy = min(max_energy, energy)
	return max_energy

func _get_max_energy_bonus() -> int:
	return max_energy_bonus

func _apply_paddle_width_buff(bonus: float) -> float:
	base_paddle_half_width += bonus
	if paddle_buff_turns > 0:
		paddle.set_half_width(paddle.half_width + bonus)
	else:
		paddle.set_half_width(base_paddle_half_width)
	return base_paddle_half_width

func _apply_paddle_speed_buff(bonus_percent: float) -> float:
	var multiplier: float = 1.0 + (bonus_percent / 100.0)
	base_paddle_speed *= multiplier
	if paddle_speed_buff_turns > 0:
		paddle.speed = base_paddle_speed * paddle_speed_multiplier
	else:
		paddle.speed = base_paddle_speed
	return base_paddle_speed

func _apply_reserve_ball_buff(bonus: int) -> int:
	volley_ball_bonus_base = min(1, volley_ball_bonus_base + bonus)
	return volley_ball_bonus_base

func _get_reserve_ball_bonus() -> int:
	return volley_ball_bonus_base

func _apply_shop_discount(percent: float) -> void:
	if percent <= 0.0:
		return
	var multiplier: float = 1.0 - (percent / 100.0)
	shop_discount_multiplier *= max(0.0, multiplier)
	_configure_shop_manager()
	_build_shop_buttons()

func _apply_shop_entry_cards(amount: int) -> int:
	shop_entry_card_bonus += amount
	if state == GameState.SHOP:
		_add_shop_entry_offers(amount, "Shop Scribe")
	return shop_entry_card_bonus

func _show_rest() -> void:
	App.stop_menu_music()
	App.stop_combat_music()
	App.stop_shop_music()
	App.start_rest_music()
	_hide_all_panels()
	info_label.text = "Rest: fully heal and remove wounds."
	hp = max_hp
	var removed: int = 0
	if deck_manager != null:
		var wound_instance_ids: Array[int] = []
		for card in deck_manager.deck:
			if card is Dictionary and String(card.get("card_id", "")) == "wound":
				wound_instance_ids.append(int(card.get("id", -1)))
		for instance_id in wound_instance_ids:
			if removed >= 5:
				break
			deck_manager.remove_card_instance_from_all(instance_id, true)
			removed += 1
	_update_labels()
	if _between_act_step == BetweenActStep.REST:
		_begin_between_act_shop()
	else:
		_transition_event("go_to_map")
	_update_volley_prompt_visibility()

func _show_game_over() -> void:
	App.stop_combat_music()
	App.stop_shop_music()
	App.stop_rest_music()
	App.notify_run_completed()
	_clear_active_balls()
	_hide_all_panels()
	gameover_panel.visible = true
	gameover_label.text = "Game Over"
	info_label.text = "Your run has ended."
	_show_outcome_overlay(false)
	_update_volley_prompt_visibility()

func _show_reward_panel() -> void:
	_show_single_panel(reward_panel)
	if reward_manager:
		reward_manager.apply_panel_copy()
	_build_reward_buttons()
	_update_labels()
	_update_volley_prompt_visibility()

func _show_treasure_panel(reroll: bool = true) -> void:
	_show_single_panel(treasure_panel)
	if treasure_label:
		treasure_label.text = "Treasure found"
	if reroll or treasure_reward_entries.is_empty():
		treasure_reward_entries = _roll_treasure_rewards()
		_apply_treasure_rewards(treasure_reward_entries)
	_render_treasure_rewards(treasure_reward_entries)
	info_label.text = "Treasure claimed."
	_update_labels()
	_update_volley_prompt_visibility()

func _roll_treasure_rewards() -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	var count: int = run_rng.randi_range(1, 3)
	var weights := _treasure_reward_weights()
	var reward_types := _pick_weighted_unique_types(weights, count)
	for reward_type in reward_types:
		match reward_type:
			"gold":
				var amount: int = 50
				rewards.append({
					"type": "gold",
					"amount": amount,
					"label": "Gold Cache (+%dg)" % amount
				})
			"mod":
				var mod_id := _pick_random_mod()
				if mod_id == "":
					continue
				var mod: Dictionary = ball_mod_data.get(mod_id, {})
				rewards.append({
					"type": "mod",
					"mod_id": mod_id,
					"label": "%s (+1)" % String(mod.get("name", mod_id))
				})
			"card":
				var card_id := _pick_random_card()
				if card_id == "":
					continue
				var card: Dictionary = card_data.get(card_id, {})
				rewards.append({
					"type": "card",
					"card_id": card_id,
					"label": "%s added" % String(card.get("name", card_id))
				})
	return rewards

func _treasure_reward_weights() -> Dictionary:
	if floor_plan_generator_config is FLOOR_PLAN_GENERATOR_CONFIG:
		var weights: Dictionary = floor_plan_generator_config.treasure_reward_weights
		if weights != null and not weights.is_empty():
			return weights
	push_error("Treasure reward weights missing from generator config.")
	return {}

func _pick_weighted_unique_types(weights: Dictionary, count: int) -> Array[String]:
	var pool: Array[String] = []
	for key in weights.keys():
		var type_id := String(key)
		var weight: int = int(weights[key])
		if type_id == "" or weight <= 0:
			continue
		pool.append(type_id)
	var picks: Array[String] = []
	var remaining: Dictionary = weights.duplicate()
	for _i in range(min(count, pool.size())):
		var pick := _pick_weighted_type(remaining)
		if pick == "":
			break
		picks.append(pick)
		remaining.erase(pick)
	return picks

func _pick_weighted_type(weights: Dictionary) -> String:
	var total: int = 0
	for key in weights.keys():
		total += max(0, int(weights[key]))
	if total <= 0:
		return ""
	var roll: int = run_rng.randi_range(1, total)
	var cumulative: int = 0
	for key in weights.keys():
		cumulative += max(0, int(weights[key]))
		if roll <= cumulative:
			return String(key)
	return ""

func _apply_treasure_rewards(rewards: Array[Dictionary]) -> void:
	for reward in rewards:
		var reward_type := String(reward.get("type", ""))
		match reward_type:
			"gold":
				gold += int(reward.get("amount", 0))
			"mod":
				var mod_id := String(reward.get("mod_id", ""))
				if mod_id != "":
					ball_mod_counts[mod_id] = int(ball_mod_counts.get(mod_id, 0)) + 1
			"card":
				var card_id := String(reward.get("card_id", ""))
				if card_id != "":
					_add_card_to_deck(card_id)
	_refresh_mod_buttons()

func _render_treasure_rewards(rewards: Array[Dictionary]) -> void:
	if treasure_rewards == null:
		return
	for child in treasure_rewards.get_children():
		child.queue_free()
	for reward in rewards:
		var label := Label.new()
		label.text = String(reward.get("label", "Treasure"))
		treasure_rewards.add_child(label)

func _show_victory() -> void:
	App.stop_combat_music()
	App.notify_run_completed()
	_clear_active_balls()
	_hide_all_panels()
	gameover_panel.visible = true
	gameover_label.text = "Victory! You beat Shatter Shot! Thank you for playing."
	info_label.text = ""
	_show_outcome_overlay(true)
	_update_volley_prompt_visibility()

func _hide_outcome_overlays() -> void:
	if victory_overlay:
		victory_overlay.visible = false
	if defeat_overlay:
		defeat_overlay.visible = false

func _show_outcome_overlay(is_victory: bool) -> void:
	_hide_outcome_overlays()
	if is_victory and victory_overlay:
		victory_overlay.visible = true
		_spawn_victory_particles()
	elif not is_victory and defeat_overlay:
		defeat_overlay.visible = true
		_spawn_outcome_particles(Color(0.35, 0.1, 0.1, 1), false)

func _spawn_act_complete_particles() -> void:
	_spawn_outcome_particles(Color(0.95, 0.85, 0.25, 1), true)

func _spawn_victory_particles() -> void:
	var base_count: int = App.get_vfx_count(OUTCOME_PARTICLE_COUNT)
	if base_count <= 0:
		return
	var palette: Array[Color] = [
		Color(0.86, 0.32, 0.26, 1),
		Color(0.95, 0.60, 0.20, 1),
		Color(0.95, 0.85, 0.25, 1),
		Color(0.45, 0.78, 0.36, 1),
		Color(0.26, 0.62, 0.96, 1)
	]
	var screen: Vector2 = App.get_layout_size()
	var total: int = base_count * 9
	var clusters_per_color: int = 3
	var per_cluster: int = max(1, int(ceil(float(total) / float(palette.size() * clusters_per_color))))
	for i in range(palette.size()):
		for _cluster in range(clusters_per_color):
			var center := Vector2(
				outcome_rng.randf_range(screen.x * 0.1, screen.x*1.1),
				outcome_rng.randf_range(screen.y * 0.1, screen.y * 0.5)
			)
			_spawn_outcome_particle_cluster(palette[i], per_cluster, center, 20.0, true)

func _spawn_outcome_particle_cluster(color: Color, count: int, center: Vector2, radius: float, is_victory: bool) -> void:
	if count <= 0:
		return
	var parent_node: Node = get_tree().root
	if hud != null:
		parent_node = hud
	if parent_node == null:
		return
	for _i in range(count):
		var particle := OUTCOME_PARTICLE_SCENE.instantiate()
		if particle == null:
			continue
		parent_node.add_child(particle)
		if particle is Node2D:
			var node := particle as Node2D
			var angle := outcome_rng.randf_range(0.0, TAU)
			var distance := outcome_rng.randf_range(0.0, radius)
			node.global_position = center + Vector2(cos(angle), sin(angle)) * distance
		if particle.has_method("setup"):
			var speed_y: Vector2 = OUTCOME_PARTICLE_SPEED_Y_VICTORY if is_victory else OUTCOME_PARTICLE_SPEED_Y_DEFEAT
			var velocity := Vector2(
				outcome_rng.randf_range(OUTCOME_PARTICLE_SPEED_X.x, OUTCOME_PARTICLE_SPEED_X.y),
				outcome_rng.randf_range(speed_y.x, speed_y.y)
			)
			particle.call("setup", color, velocity)

func _spawn_outcome_particles(color: Color, is_victory: bool, total: int = 1) -> void:
	var vfx_count: int = App.get_vfx_count(OUTCOME_PARTICLE_COUNT)
	if vfx_count <= 0:
		return
	var parent_node: Node = get_tree().root
	if hud != null:
		parent_node = hud
	if parent_node == null:
		return
	var screen: Vector2 = App.get_layout_size()
	var per_color: int = max(1, int(ceil(float(vfx_count) / float(total))))
	for _i in range(per_color):
		var particle := OUTCOME_PARTICLE_SCENE.instantiate()
		if particle == null:
			continue
		parent_node.add_child(particle)
		if particle is Node2D:
			var node := particle as Node2D
			node.global_position = Vector2(
				outcome_rng.randf_range(0.0, screen.x),
				outcome_rng.randf_range(0.0, screen.y * 0.7)
			)
		if particle.has_method("setup"):
			var speed_y: Vector2 = OUTCOME_PARTICLE_SPEED_Y_VICTORY if is_victory else OUTCOME_PARTICLE_SPEED_Y_DEFEAT
			var velocity := Vector2(
				outcome_rng.randf_range(OUTCOME_PARTICLE_SPEED_X.x, OUTCOME_PARTICLE_SPEED_X.y),
				outcome_rng.randf_range(speed_y.x, speed_y.y)
			)
			particle.call("setup", color, velocity)

func _go_to_menu() -> void:
	App.stop_combat_music()
	App.stop_shop_music()
	_hide_outcome_overlays()
	if gameover_panel:
		gameover_panel.visible = false
	_hide_all_panels()
	if hud:
		hud.visible = false
	if hand_bar:
		hand_bar.visible = false
	if mods_panel:
		mods_panel.visible = false
	App.show_menu()

func apply_gameplay_settings() -> void:
	var new_multiplier: float = App.get_paddle_speed_multiplier()
	if new_multiplier <= 0.0:
		return
	if paddle_speed_setting_multiplier <= 0.0:
		paddle_speed_setting_multiplier = 1.0
	var was_buffed: bool = paddle_speed_buff_turns > 0
	base_paddle_speed = base_paddle_speed / paddle_speed_setting_multiplier * new_multiplier
	paddle_speed_setting_multiplier = new_multiplier
	if was_buffed:
		paddle.speed = base_paddle_speed * paddle_speed_multiplier
	else:
		paddle.speed = base_paddle_speed

func on_menu_opened() -> void:
	_transition_event("open_menu")
	process_mode = Node.PROCESS_MODE_DISABLED
	if hud:
		hud_layer_cache = hud.layer
		hud.layer = -5
	for node in [paddle, bricks_root, playfield]:
		if node:
			node.visible = false

func on_menu_closed() -> void:
	_transition_event("continue_run")
	for node in [paddle, bricks_root, playfield, hud]:
		if node:
			node.visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_fit_to_viewport()
	if hud:
		hud.layer = hud_layer_cache

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
			if not suppress and parry_wound_active:
				var riposte_target_id: int = -1
				if riposte_wound_active:
					var riposte_target: Node = _pick_random_brick()
					if riposte_target != null and riposte_target is Node2D:
						riposte_target_id = riposte_target.get_instance_id()
					info_label.text = "Riposte deflects a wound."
				else:
					info_label.text = "Parry blocks a wound."
				if _brick is Node2D:
					_spawn_wound_flyout(
						(_brick as Node2D).global_position,
						true,
						riposte_target_id
					)
				_update_labels()
			elif not suppress:
				if _brick is Node2D:
					_spawn_wound_flyout(
						(_brick as Node2D).global_position,
						false,
						-1,
						Callable(self, "_add_wound_to_deck")
					)
				_update_labels()
	if encounter_manager.check_victory():
		_end_encounter()

func _on_brick_damaged(_brick: Node) -> void:
	_update_labels()

func _discard_hand() -> void:
	deck_manager.discard_hand()
	_refresh_hand()

func _refresh_hand() -> void:
	hud_controller.refresh_hand(deck_manager.hand, state != GameState.PLANNING, Callable(self, "_play_card"))

func _play_card(instance_id: int) -> void:
	if state != GameState.PLANNING:
		return
	var card_id: String = deck_manager.get_card_id_from_hand(instance_id)
	if card_id == "":
		return
	if card_id == "riposte" and not _hand_has_card("parry", instance_id):
		_show_toast("Riposte requires a Parry in hand.", Color(1, 1, 1, 1), 1.6)
		return
	var cost: int = card_data[card_id]["cost"]
	if energy < cost:
		info_label.text = "Not enough energy."
		return
	energy -= cost
	var should_discard: bool = _apply_card_effect(card_id, instance_id)
	if should_discard:
		deck_manager.discard_card_instance(instance_id)
	_refresh_hand()
	_update_reserve_indicator()
	_update_labels()

func _apply_card_effect(card_id: String, instance_id: int) -> bool:
	if card_effect_registry == null:
		return true
	return card_effect_registry.apply(card_id, self, instance_id)

func _hand_has_card(card_id: String, exclude_instance_id: int = -1) -> bool:
	if deck_manager == null:
		return false
	for card in deck_manager.hand:
		if card is Dictionary:
			var card_instance_id: int = int(card.get("id", -1))
			if card_instance_id == exclude_instance_id:
				continue
			if String(card.get("card_id", "")) == card_id:
				return true
	return false

func _destroy_random_bricks(amount: int) -> void:
	var bricks: Array = _get_active_bricks()
	_shuffle_array(bricks)
	for i in range(min(amount, bricks.size())):
		var brick: Node = bricks[i]
		_apply_brick_damage_cap(brick, 999)

func _pick_random_brick() -> Node:
	var bricks: Array = _get_active_bricks()
	_shuffle_array(bricks)
	for brick in bricks:
		if brick != null:
			return brick
	return null

func _get_active_bricks() -> Array:
	if encounter_manager != null and encounter_manager.has_method("get_bricks"):
		return encounter_manager.get_bricks()
	if bricks_root == null:
		return []
	return bricks_root.get_children()

func _apply_brick_damage_cap(brick: Node, amount: int) -> void:
	if brick == null:
		return
	var capped_amount: int = amount
	if brick.has_method("get"):
		var hp_value: Variant = brick.get("hp")
		if typeof(hp_value) == TYPE_INT and hp_value > 0:
			capped_amount = min(amount, int(hp_value))
	if brick.has_method("apply_damage"):
		brick.apply_damage(capped_amount)

func _pick_random_card() -> String:
	if card_pool.is_empty():
		return ""
	var index: int = run_rng.randi_range(0, card_pool.size() - 1)
	return String(card_pool[index])

func _pick_random_mod() -> String:
	if ball_mod_order.is_empty():
		return ""
	var index: int = run_rng.randi_range(0, ball_mod_order.size() - 1)
	return String(ball_mod_order[index])

func _pick_random_mods(count: int) -> Array[String]:
	var mods: Array[String] = ball_mod_order.duplicate()
	_shuffle_array(mods)
	if mods.is_empty():
		return []
	return mods.slice(0, min(count, mods.size()))

func _shuffle_array(values: Array) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = run_rng.randi_range(0, i)
		var temp = values[i]
		values[i] = values[j]
		values[j] = temp

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
	var threat: int = encounter_manager.calculate_threat(act_threat_multiplier)
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

func _spawn_wound_flyout(start_pos: Vector2, is_blocked: bool, reflect_target_id: int = -1, on_deck_arrive: Callable = Callable()) -> void:
	var fly_label := Label.new()
	fly_label.text = "🗡️"
	fly_label.position = start_pos
	fly_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(fly_label)
	var deck_center: Vector2 = deck_stack.get_global_rect().get_center()
	var tween := get_tree().create_tween()
	tween.tween_property(fly_label, "global_position", deck_center, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_blocked:
		tween.tween_callback(_spawn_wound_block_shield)
	if on_deck_arrive.is_valid():
		tween.tween_callback(on_deck_arrive)
	tween.tween_property(fly_label, "scale", Vector2(0.6, 0.6), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if reflect_target_id != -1:
		var fly_label_id: int = fly_label.get_instance_id()
		tween.tween_callback(_start_riposte_reflect.bind(fly_label_id, reflect_target_id, 2))
		return
	tween.tween_callback(fly_label.queue_free)

func _add_wound_to_deck() -> void:
	deck_manager.add_card("wound")
	_update_labels()

func _start_riposte_reflect(fly_label_id: int, target_id: int, retries_left: int) -> void:
	var fly_label: Object = instance_from_id(fly_label_id)
	if fly_label == null or not is_instance_valid(fly_label):
		return
	var target: Object = instance_from_id(target_id)
	if target == null or not is_instance_valid(target):
		_retarget_riposte_flyout(fly_label_id, retries_left)
		return
	var target_node := target as Node
	if target_node.has_signal("destroyed"):
		target_node.destroyed.connect(
			_on_riposte_target_destroyed.bind(fly_label_id),
			CONNECT_ONE_SHOT
		)
	var tween := get_tree().create_tween()
	riposte_flyouts[fly_label_id] = {
		"retries_left": retries_left,
		"tween": tween
	}
	var fly_control: Control = fly_label as Control
	var target_node_2d: Node2D = target_node as Node2D
	if fly_control != null and target_node_2d != null:
		var direction := target_node_2d.global_position - fly_control.global_position
		if direction.length_squared() > 0.0:
			fly_control.rotation = direction.angle() + PI
	tween.tween_property(
		fly_label as Object,
		"global_position",
		(target_node as Node2D).global_position,
		0.6
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_resolve_riposte_hit.bind(fly_label_id, target_id))

func _on_riposte_target_destroyed(_brick: Node, fly_label_id: int) -> void:
	var retries_left: int = int(riposte_flyouts.get(fly_label_id, {}).get("retries_left", 0))
	_retarget_riposte_flyout(fly_label_id, retries_left)

func _retarget_riposte_flyout(fly_label_id: int, retries_left: int) -> void:
	var fly_label: Object = instance_from_id(fly_label_id)
	if fly_label == null or not is_instance_valid(fly_label):
		riposte_flyouts.erase(fly_label_id)
		return
	if retries_left <= 0:
		riposte_flyouts.erase(fly_label_id)
		(fly_label as Node).queue_free()
		return
	var existing: Dictionary = riposte_flyouts.get(fly_label_id, {})
	var tween: Tween = existing.get("tween", null)
	if tween != null and is_instance_valid(tween):
		tween.kill()
	var new_target: Node = _pick_random_brick()
	if new_target == null or not (new_target is Node2D):
		riposte_flyouts.erase(fly_label_id)
		(fly_label as Node).queue_free()
		return
	riposte_flyouts[fly_label_id] = {
		"retries_left": retries_left - 1,
		"tween": tween
	}
	_start_riposte_reflect(fly_label_id, new_target.get_instance_id(), retries_left - 1)

func _resolve_riposte_hit(fly_label_id: int, target_id: int) -> void:
	var fly_label: Object = instance_from_id(fly_label_id)
	if fly_label == null or not is_instance_valid(fly_label):
		riposte_flyouts.erase(fly_label_id)
		return
	var target: Object = instance_from_id(target_id)
	if target == null or not is_instance_valid(target):
		var retries_left: int = int(riposte_flyouts.get(fly_label_id, {}).get("retries_left", 0))
		_retarget_riposte_flyout(fly_label_id, retries_left)
		return
	_apply_brick_damage_cap(target as Node, 999)
	riposte_flyouts.erase(fly_label_id)
	(fly_label as Node).queue_free()

func _spawn_wound_block_shield() -> void:
	if hud == null or deck_stack == null:
		return
	var deck_rect := deck_stack.get_global_rect()
	var shield_container := Control.new()
	shield_container.size = deck_rect.size
	shield_container.global_position = deck_rect.position
	shield_container.pivot_offset = deck_rect.size * 0.5
	shield_container.scale = Vector2.ONE * 0.2
	shield_container.modulate = Color(1.0, 1.0, 1.0, 0.9)
	hud.add_child(shield_container)

	var shield := Label.new()
	shield.text = "🛡️"
	shield.add_theme_font_size_override("font_size", 36)
	shield.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shield.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shield.autowrap_mode = TextServer.AUTOWRAP_OFF
	if card_emoji_font:
		shield.add_theme_font_override("font", card_emoji_font)
	shield.set_anchors_preset(Control.PRESET_FULL_RECT)
	shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield_container.add_child(shield)
	var tween := get_tree().create_tween()
	tween.tween_property(shield_container, "scale", Vector2.ONE * 1.4, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(shield_container, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(shield_container.queue_free)

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
		App.apply_neutral_button_style(button)
		App.bind_button_feedback(button)
		mods_buttons.add_child(button)
	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(func() -> void:
		active_ball_mod = ""
		_apply_ball_mod_to_active_balls()
		_refresh_mod_buttons()
	)
	App.apply_neutral_button_style(clear_button)
	App.bind_button_feedback(clear_button)
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
	_hide_all_panels()
	if panel:
		panel.visible = true

func _update_volley_prompt_visibility() -> void:
	if volley_prompt_label == null:
		return
	var should_show := state == GameState.PLANNING
	if should_show:
		if not volley_prompt_pulsing:
			_start_volley_prompt_pulse()
	else:
		if volley_prompt_pulsing:
			_stop_volley_prompt_pulse()

func _start_volley_prompt_pulse() -> void:
	if volley_prompt_label == null:
		return
	if volley_prompt_tween and volley_prompt_tween.is_running():
		volley_prompt_tween.kill()
	volley_prompt_label.visible = true
	volley_prompt_label.modulate = Color(1, 1, 1, 0)
	volley_prompt_tween = create_tween()
	volley_prompt_tween.set_loops()
	volley_prompt_tween.tween_property(volley_prompt_label, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	volley_prompt_tween.tween_property(volley_prompt_label, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	volley_prompt_pulsing = true

func _stop_volley_prompt_pulse() -> void:
	if volley_prompt_label == null:
		return
	if volley_prompt_tween and volley_prompt_tween.is_running():
		volley_prompt_tween.kill()
	volley_prompt_tween = create_tween()
	volley_prompt_tween.tween_property(volley_prompt_label, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	volley_prompt_tween.tween_callback(func() -> void:
		volley_prompt_label.visible = false
	)
	volley_prompt_pulsing = false

func _update_volley_prompt_position() -> void:
	if volley_prompt_label == null or paddle == null:
		return
	var min_size := volley_prompt_label.get_combined_minimum_size()
	var fallback_width: float = maxf(360.0, volley_prompt_label.custom_minimum_size.x)
	if min_size == Vector2.ZERO:
		min_size = Vector2(fallback_width, 0.0)
	else:
		min_size.x = max(min_size.x, fallback_width)
	volley_prompt_label.size = min_size
	var viewport := get_viewport()
	var center_x: float = App.get_layout_size().x * 0.5
	if viewport != null:
		var rect: Rect2 = viewport.get_visible_rect()
		center_x = rect.position.x + rect.size.x * 0.5
	var target_y := paddle.global_position.y + VOLLEY_PROMPT_OFFSET_Y + START_PROMPT_EXTRA_OFFSET_Y
	volley_prompt_label.global_position = Vector2(center_x - min_size.x * 0.5, target_y - min_size.y * 0.5)

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
	info_label.text = "Draw pile contents."
	hud_controller.populate_card_container(deck_list, deck_manager.draw_pile, Callable(), false, 4)

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

func _show_add_card_to_hand_panel() -> void:
	if state == GameState.GAME_OVER or state == GameState.VICTORY:
		return
	_capture_deck_return_context()
	_show_single_panel(deck_panel)
	info_label.text = "Choose a card to add to hand."
	var card_ids: Array = card_data.keys()
	card_ids.sort()
	hud_controller.populate_card_container(deck_list, card_ids, Callable(self, "_on_add_card_to_hand_selected"), false, 5)

func _on_remove_card_selected(instance_id: int) -> void:
	var card_id: String = deck_manager.get_card_id_for_instance(instance_id)
	deck_manager.remove_card_instance_from_all(instance_id, true)
	_refresh_hand()
	var card_name: String = card_data.get(card_id, {}).get("name", card_id)
	deck_return_info = "Removed %s." % card_name
	_close_deck_panel()

func _on_add_card_to_hand_selected(card_id: String) -> void:
	var added: bool = false
	if deck_manager:
		added = deck_manager.add_card_to_hand(card_id)
	if added:
		_refresh_hand()
		var card_name: String = card_data.get(card_id, {}).get("name", card_id)
		deck_return_info = "Added %s to hand." % card_name
	else:
		deck_return_info = "Hand is full."
	_close_deck_panel()

func _close_deck_panel() -> void:
	_hide_all_panels()
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
