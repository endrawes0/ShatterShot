extends Resource
class_name BalanceData

@export var card_data: Dictionary = {}
@export var card_pool: Array[String] = []
@export var starting_deck: Array[String] = []

@export var ball_mods: Dictionary = {
	"data": {},
	"order": [],
	"colors": {}
}

@export var shop_data: Dictionary = {
	"card_price": 40,
	"max_cards": 7,
	"remove_price": 30,
	"upgrade_price": 60,
	"upgrade_hand_bonus": 1,
	"vitality_price": 60,
	"vitality_max_hp_bonus": 10,
	"vitality_heal": 10,
	"reroll_base_price": 20,
	"reroll_multiplier": 1.8,
	"energy_price": 70,
	"energy_bonus": 1,
	"paddle_width_price": 60,
	"paddle_width_bonus": 10.0,
	"paddle_speed_price": 60,
	"paddle_speed_bonus_percent": 10.0,
	"reserve_ball_price": 80,
	"reserve_ball_bonus": 1,
	"discount_price": 50,
	"discount_percent": 20.0,
	"discount_max": 5,
	"entry_card_price": 70,
	"entry_card_count": 1
}

@export var reward_card_count: int = 3
