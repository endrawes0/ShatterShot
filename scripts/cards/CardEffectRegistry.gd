extends RefCounted
class_name CardEffectRegistry

const CardEffect = preload("res://scripts/cards/CardEffect.gd")
const WhatDoesntKillUsCardEffect = preload("res://scripts/cards/WhatDoesntKillUsCardEffect.gd")
const PunchCardEffect = preload("res://scripts/cards/PunchCardEffect.gd")
const TwinCardEffect = preload("res://scripts/cards/TwinCardEffect.gd")
const GuardCardEffect = preload("res://scripts/cards/GuardCardEffect.gd")
const WidenCardEffect = preload("res://scripts/cards/WidenCardEffect.gd")
const BombCardEffect = preload("res://scripts/cards/BombCardEffect.gd")
const RallyCardEffect = preload("res://scripts/cards/RallyCardEffect.gd")
const FocusCardEffect = preload("res://scripts/cards/FocusCardEffect.gd")
const HasteCardEffect = preload("res://scripts/cards/HasteCardEffect.gd")
const SlowCardEffect = preload("res://scripts/cards/SlowCardEffect.gd")
const WoundCardEffect = preload("res://scripts/cards/WoundCardEffect.gd")

var effects: Dictionary = {}

func _init() -> void:
	effects = {
		"what_doesnt_kill_us": WhatDoesntKillUsCardEffect.new(),
		"punch": PunchCardEffect.new(),
		"twin": TwinCardEffect.new(),
		"guard": GuardCardEffect.new(),
		"widen": WidenCardEffect.new(),
		"bomb": BombCardEffect.new(),
		"rally": RallyCardEffect.new(),
		"focus": FocusCardEffect.new(),
		"haste": HasteCardEffect.new(),
		"slow": SlowCardEffect.new(),
		"wound": WoundCardEffect.new()
	}

func apply(card_id: String, main: Node, instance_id: int) -> bool:
	var effect: CardEffect = effects.get(card_id, null)
	if effect == null:
		return true
	return effect.apply(main, instance_id)
