extends Resource
class_name EncounterConfig

@export var rows: int = 4
@export var cols: int = 8
@export var base_hp: int = 1
@export var base_threat: int = 0
@export var pattern_id: String = "grid"
@export var speed_boost: bool = false
@export var is_boss: bool = false
@export var boss_core: bool = false
@export var boss_core_hp_bonus: int = 2
@export var variant_policy: VariantPolicy
