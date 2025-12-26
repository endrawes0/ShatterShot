extends Control

@onready var main: Node = $Main

func _ready() -> void:
	_apply_debug_font_size(10)
	_connect_button("DebugPanel/VBox/StartCombat", func() -> void:
		main.floor_index = 1
		main._start_encounter(false)
	)
	_connect_button("DebugPanel/VBox/StartElite", func() -> void:
		main.floor_index = 1
		main._start_encounter(true)
	)
	_connect_button("DebugPanel/VBox/StartBoss", func() -> void:
		main.floor_index = 1
		main._start_boss()
	)
	_connect_button("DebugPanel/VBox/ShowMap", func() -> void:
		main._show_map()
	)
	_connect_button("DebugPanel/VBox/ShowShop", func() -> void:
		main._show_shop()
	)
	_connect_button("DebugPanel/VBox/AddGold", func() -> void:
		main.gold += 100
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/AddPunch", func() -> void:
		main._add_card_to_deck("punch")
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/AddWound", func() -> void:
		main._add_card_to_deck("wound")
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/UnlockExplosive", func() -> void:
		_unlock_mod("explosive")
	)
	_connect_button("DebugPanel/VBox/UnlockSpikes", func() -> void:
		_unlock_mod("spikes")
	)
	_connect_button("DebugPanel/VBox/UnlockMiracle", func() -> void:
		_unlock_mod("miracle")
	)
	_connect_button("DebugPanel/VBox/ModExplosive", func() -> void:
		main._select_ball_mod("explosive")
	)
	_connect_button("DebugPanel/VBox/ModSpikes", func() -> void:
		main._select_ball_mod("spikes")
	)
	_connect_button("DebugPanel/VBox/ModMiracle", func() -> void:
		main._select_ball_mod("miracle")
	)
	_connect_button("DebugPanel/VBox/ClearMod", func() -> void:
		main.active_ball_mod = ""
		main._apply_ball_mod_to_active_balls()
		main._refresh_mod_buttons()
	)
	_connect_button("DebugPanel/VBox/RefillEnergy", func() -> void:
		main.energy = main.max_energy
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/HealFull", func() -> void:
		main.hp = main.max_hp
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/ClearBricks", func() -> void:
		for child in main.bricks_root.get_children():
			child.queue_free()
	)
	_connect_button("DebugPanel/VBox/BackMenu", func() -> void:
		App.show_menu()
	)

func _apply_debug_font_size(size: int) -> void:
	var container := get_node("DebugPanel/VBox") as VBoxContainer
	if container == null:
		return
	for child in container.get_children():
		if child is Control:
			(child as Control).add_theme_font_size_override("font_size", size)

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node(path) as Button
	if button:
		button.pressed.connect(action)

func _unlock_mod(mod_id: String) -> void:
	main.ball_mod_counts[mod_id] = int(main.ball_mod_counts.get(mod_id, 0)) + 1
	main._refresh_mod_buttons()
