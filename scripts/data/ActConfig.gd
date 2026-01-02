extends Resource
class_name ActConfig

@export var act_index: int = 1

@export var combat_intro: String = "Plan your volley, then launch."
@export var elite_intro: String = "Plan your volley, then launch."
@export var boss_intro: String = "Boss fight. Plan carefully."

@export var combat_gold_reward: int = 25
@export var elite_gold_reward: int = 25
@export var boss_gold_reward: int = 0

@export var ball_speed_multiplier: float = 1.0
@export var variant_chance_multiplier: float = 1.0
@export var elite_hp_multiplier: float = 1.0
@export var elite_threat_multiplier: float = 1.0
@export var boss_hp_multiplier: float = 1.0
@export var boss_threat_multiplier: float = 1.0
