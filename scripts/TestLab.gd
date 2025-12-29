extends Control

@onready var main: Node = $Main

func _ready() -> void:
	_apply_debug_font_size(9)
	_apply_debug_theme()
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/StartCombat", func() -> void:
		main.floor_index = 1
		main._start_encounter(false)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/StartElite", func() -> void:
		main.floor_index = 1
		main._start_encounter(true)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/StartBoss", func() -> void:
		main.floor_index = 1
		main._start_boss()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/ShowMap", func() -> void:
		main._show_map()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/ShowShop", func() -> void:
		main._show_shop()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/ShowVictory", func() -> void:
		main._show_victory()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/ShowDefeat", func() -> void:
		main._show_game_over()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/AddGold", func() -> void:
		main.gold += 100
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/AddPunch", func() -> void:
		main._add_card_to_deck("punch")
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/AddWound", func() -> void:
		main._add_card_to_deck("wound")
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/UnlockExplosive", func() -> void:
		_unlock_mod("explosive")
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/UnlockSpikes", func() -> void:
		_unlock_mod("spikes")
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/UnlockMiracle", func() -> void:
		_unlock_mod("miracle")
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ModExplosive", func() -> void:
		main._select_ball_mod("explosive")
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ModSpikes", func() -> void:
		main._select_ball_mod("spikes")
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ModMiracle", func() -> void:
		main._select_ball_mod("miracle")
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ClearMod", func() -> void:
		main.active_ball_mod = ""
		main._apply_ball_mod_to_active_balls()
		main._refresh_mod_buttons()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/RefillEnergy", func() -> void:
		main.energy = main.max_energy
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/HealFull", func() -> void:
		main.hp = main.max_hp
		main._update_labels()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ClearBricks", func() -> void:
		for child in main.bricks_root.get_children():
			child.queue_free()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/PassLevel", func() -> void:
		for child in main.bricks_root.get_children():
			child.queue_free()
		if main.current_is_boss:
			main._show_victory()
		else:
			main._end_encounter()
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/BackMenu", func() -> void:
		if main and main.has_method("on_menu_opened"):
			main.on_menu_opened()
		App.show_menu()
	)

func _apply_debug_font_size(size: int) -> void:
	var root := get_node("DebugPanel") as Control
	if root == null:
		return
	_apply_font_size_recursive(root, size)

func _apply_font_size_recursive(node: Node, size: int) -> void:
	if node is Control:
		(node as Control).add_theme_font_size_override("font_size", size)
	for child in node.get_children():
		_apply_font_size_recursive(child, size)

func _apply_debug_theme() -> void:
	var panel := get_node("DebugPanel") as Control
	if panel == null:
		return
	panel.theme = Theme.new()
	_mark_debug_buttons()

func _mark_debug_buttons() -> void:
	var root := get_node("DebugPanel") as Control
	if root == null:
		return
	_mark_buttons_recursive(root)

func _mark_buttons_recursive(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).add_to_group(App.UI_PARTICLE_IGNORE_GROUP)
	for child in node.get_children():
		_mark_buttons_recursive(child)
func _connect_button(path: String, action: Callable) -> void:
	var button := get_node(path) as Button
	if button:
		button.pressed.connect(action)

func _unlock_mod(mod_id: String) -> void:
	main.ball_mod_counts[mod_id] = int(main.ball_mod_counts.get(mod_id, 0)) + 1
	main._refresh_mod_buttons()
