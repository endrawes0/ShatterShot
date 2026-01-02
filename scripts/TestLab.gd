extends Control

var main: Node = null
@onready var debug_panel: Control = $DebugPanel
@onready var toggle_button: Button = $ToggleDebug

func _ready() -> void:
	_apply_debug_font_size(9)
	_apply_debug_theme()
	_update_toggle_button_text()
	_connect_button("ToggleDebug", _toggle_debug_panel)
	resized.connect(_layout_toggle_button)
	main = _resolve_main()
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/StartCombat", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node.floor_index = 1
			main_node._start_encounter(false)
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/StartElite", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node.floor_index = 1
			main_node._start_encounter(true)
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/StartBoss", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node.floor_index = 1
			main_node._start_boss()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/ShowMap", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node._show_map()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/ShowShop", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node._show_shop()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/ShowVictory", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node._show_victory()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/ShowDefeat", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node._show_game_over()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/AddGold", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node.gold += 100
			main_node._update_labels()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/AddPunch", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node._add_card_to_deck("punch")
			main_node._update_labels()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/LeftColumn/AddWound", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node._add_card_to_deck("wound")
			main_node._update_labels()
		)
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
		_with_main(func(main_node: Node) -> void:
			main_node._select_ball_mod("explosive")
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ModSpikes", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node._select_ball_mod("spikes")
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ModMiracle", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node._select_ball_mod("miracle")
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ClearMod", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node.active_ball_mod = ""
			main_node._apply_ball_mod_to_active_balls()
			main_node._refresh_mod_buttons()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/RefillEnergy", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node.energy = main_node.max_energy
			main_node._update_labels()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/HealFull", func() -> void:
		_with_main(func(main_node: Node) -> void:
			main_node.hp = main_node.max_hp
			main_node._update_labels()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/ClearBricks", func() -> void:
		_with_main(func(main_node: Node) -> void:
			for child in main_node.bricks_root.get_children():
				child.queue_free()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/PassLevel", func() -> void:
		_with_main(func(main_node: Node) -> void:
			for child in main_node.bricks_root.get_children():
				child.queue_free()
			if main_node.current_is_boss:
				main_node._show_victory()
			else:
				main_node._end_encounter()
		)
	)
	_connect_button("DebugPanel/VBox/ButtonColumns/RightColumn/BackMenu", func() -> void:
		App.show_menu()
	)

func _toggle_debug_panel() -> void:
	if debug_panel == null:
		return
	debug_panel.visible = not debug_panel.visible
	_update_toggle_button_text()

func _update_toggle_button_text() -> void:
	if toggle_button == null or debug_panel == null:
		return
	toggle_button.text = "Hide Panel" if debug_panel.visible else "Show Panel"
	_layout_toggle_button()

func _layout_toggle_button() -> void:
	if toggle_button == null:
		return
	var padding: Vector2 = Vector2(10.0, 44.0)
	var min_size := toggle_button.get_combined_minimum_size()
	toggle_button.size = min_size
	toggle_button.position = Vector2(size.x - min_size.x - padding.x, padding.y)

func _resolve_main() -> Node:
	var current := get_tree().current_scene
	if current != null and current.has_method("_start_encounter"):
		return current
	var fallback := get_tree().root.find_child("Main", true, false)
	return fallback if fallback != null and fallback.has_method("_start_encounter") else null

func _with_main(action: Callable) -> void:
	if main == null or not is_instance_valid(main):
		main = _resolve_main()
	if main == null or not is_instance_valid(main):
		return
	action.call(main)

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
	_with_main(func(main_node: Node) -> void:
		main_node.ball_mod_counts[mod_id] = int(main_node.ball_mod_counts.get(mod_id, 0)) + 1
		main_node._refresh_mod_buttons()
	)
