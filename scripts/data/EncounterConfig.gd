extends Resource
class_name EncounterConfig

@export var id: String = ""
@export var encounter_kind: String = "combat" # combat, elite, boss
@export var min_floor: int = 1
@export var max_floor: int = 99
@export var weight: int = 1

@export var rows: int = 4
@export var cols: int = 8
@export var base_hp: int = 1

@export var pattern_id: String = "auto"
@export var speed_boost_chance: float = 0.0
@export var speed_boost: bool = false
@export var is_boss: bool = false
@export var boss_core: bool = false
@export var boss_core_hp_bonus: int = 2
@export var variant_policy: VariantPolicy
