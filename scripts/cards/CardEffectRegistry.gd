extends RefCounted
class_name CardEffectRegistry

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
