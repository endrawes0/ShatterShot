extends Resource
class_name BalanceData

@export var card_data: Dictionary = {}
@export var card_pool: Array[String] = []
@export var starting_deck: Array[String] = []

@export var ball_mod_data: Dictionary = {}
@export var ball_mod_order: Array[String] = []
@export var ball_mod_colors: Dictionary = {}

@export var shop_card_price: int = 40
@export var shop_remove_price: int = 30
@export var shop_upgrade_price: int = 60
@export var shop_upgrade_hand_bonus: int = 1
@export var shop_vitality_price: int = 60
@export var shop_vitality_max_hp_bonus: int = 10
@export var shop_vitality_heal: int = 10
@export var shop_reroll_base_price: int = 20
@export var shop_reroll_multiplier: float = 1.8
@export var reward_card_count: int = 3
