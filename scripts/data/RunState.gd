extends Resource
class_name RunState

const GameState = StateManager.GameState

@export var state: int = GameState.MAP
@export var hp: int = 150
@export var max_hp: int = 150
@export var gold: int = 0
@export var floor_index: int = 0
@export var max_combat_floors: int = 5
@export var max_floors: int = 6

@export var max_energy: int = 3
@export var energy: int = 3
@export var block: int = 0
@export var starting_hand_size: int = 4

@export var volley_damage_bonus: int = 0
@export var volley_ball_bonus: int = 0
@export var volley_ball_bonus_base: int = 0
@export var volley_ball_reserve: int = 0
@export var volley_piercing: bool = false
@export var volley_ball_speed_multiplier: float = 1.0
@export var shop_entry_card_bonus: int = 0

@export var paddle_buff_turns: int = 0
@export var paddle_speed_buff_turns: int = 0

@export var encounter_rows: int = 4
@export var encounter_cols: int = 8
@export var encounter_hp: int = 1
@export var encounter_speed_boost: bool = false
@export var current_is_boss: bool = false
@export var current_pattern: String = "grid"
