extends Control

@onready var start_button: Button = $Center/VBox/Buttons/StartButton
@onready var continue_button: Button = $Center/VBox/Buttons/ContinueRow/ContinueButton
@onready var end_button: Button = $Center/VBox/Buttons/ContinueRow/EndButton
@onready var help_button: Button = $Center/VBox/Buttons/HelpButton
@onready var settings_button: Button = $Center/VBox/Buttons/SettingsButton
@onready var test_button: Button = $Center/VBox/Buttons/TestButton
@onready var quit_button: Button = $Center/VBox/Buttons/QuitButton
@onready var seed_dialog: ConfirmationDialog = $SeedDialog
@onready var seed_input: LineEdit = $SeedDialog/SeedDialogPanel/SeedInput
@onready var seed_status: Label = $SeedDialog/SeedDialogPanel/SeedStatus
@onready var practice_dialog: ConfirmationDialog = $PracticeDialog
@onready var practice_room_type_option: OptionButton = $PracticeDialog/PracticeDialogPanel/RoomTypeRow/RoomTypeOption
@onready var practice_floor_row: HBoxContainer = $PracticeDialog/PracticeDialogPanel/FloorRow
@onready var practice_floor_slider: HSlider = $PracticeDialog/PracticeDialogPanel/FloorRow/FloorSlider
@onready var practice_floor_value: Label = $PracticeDialog/PracticeDialogPanel/FloorRow/FloorValue
@onready var practice_layout_grid: GridContainer = $PracticeDialog/PracticeDialogPanel/LayoutRow/LayoutScroll/LayoutGrid

var suppress_seed_validation: bool = false
var test_lab_unlocked: bool = false
var _practice_room_type: String = "combat"
var _practice_layout_id: String = "grid"
var _practice_floor_index: int = 1
var _layout_button_group: ButtonGroup = null
var _pattern_registry: PatternRegistry = PatternRegistry.new()
var _menu_palette: Array[Color] = [
	Color(0.86, 0.32, 0.26),
	Color(0.95, 0.60, 0.20),
	Color(0.95, 0.85, 0.25),
	Color(0.45, 0.78, 0.36),
	Color(0.26, 0.62, 0.96),
	Color(0.72, 0.46, 0.86)
]

func _ready() -> void:
	start_button.pressed.connect(_open_seed_dialog)
	continue_button.pressed.connect(_continue_or_practice)
	if end_button:
		end_button.pressed.connect(_end_run_or_practice)
	help_button.pressed.connect(_open_help)
	settings_button.pressed.connect(_open_settings)
	test_button.pressed.connect(_open_test_lab)
	quit_button.pressed.connect(_quit_game)
	visibility_changed.connect(_update_continue_button)
	if seed_dialog:
		seed_dialog.dialog_hide_on_ok = false
		seed_dialog.confirmed.connect(_start_game)
		var ok_button: Button = seed_dialog.get_ok_button()
		if ok_button:
			ok_button.pressed.connect(_start_game)
	if seed_input:
		seed_input.text_changed.connect(_on_seed_text_changed)
	_layout_button_group = ButtonGroup.new()
	_setup_practice_dialog()
	_lock_test_lab()
	_apply_menu_palette()
	_update_continue_button()
	App.bind_button_feedback(self)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and App.has_run():
		App.continue_run()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		_try_unlock_test_lab(event as InputEventKey)

func _lock_test_lab() -> void:
	test_lab_unlocked = false
	App.set_test_lab_unlocked(false)
	if test_button:
		test_button.visible = false

func _try_unlock_test_lab(event: InputEventKey) -> void:
	if test_lab_unlocked or test_button == null:
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_T and event.alt_pressed and event.ctrl_pressed and event.shift_pressed:
		test_lab_unlocked = true
		App.set_test_lab_unlocked(true)
		test_button.visible = true
		_apply_menu_palette()

func _open_seed_dialog() -> void:
	if seed_dialog == null:
		_start_game()
		return
	_set_seed_status("")
	seed_input.text = ""
	seed_dialog.popup_centered()
	if seed_input:
		seed_input.grab_focus()

func _start_game() -> void:
	var result := _read_seed_input()
	if not bool(result.get("valid", false)):
		return
	_set_seed_status("")
	App.start_new_run(int(result.get("seed", 0)))
	if seed_dialog:
		seed_dialog.hide()

func _continue_or_practice() -> void:
	if App.has_run():
		App.continue_run()
		return
	_open_practice_dialog()

func _end_run_or_practice() -> void:
	if not App.has_run():
		return
	App.end_run_to_menu()

func _open_help() -> void:
	App.show_help()

func _open_settings() -> void:
	App.show_settings()

func _open_test_lab() -> void:
	App.show_test_lab()

func _quit_game() -> void:
	get_tree().quit()

func _update_continue_button() -> void:
	if continue_button == null:
		return
	if App.has_run():
		continue_button.text = "Continue"
		continue_button.disabled = false
		if end_button:
			end_button.visible = true
			end_button.disabled = false
			end_button.text = "End Practice" if App.is_practice_run() else "End Run"
	else:
		continue_button.text = "Practice"
		continue_button.disabled = false
		if end_button:
			end_button.visible = false
	_apply_menu_palette()

func _setup_practice_dialog() -> void:
	if practice_dialog == null:
		return
	practice_dialog.dialog_hide_on_ok = false
	practice_dialog.confirmed.connect(_start_practice)
	var ok_button: Button = practice_dialog.get_ok_button()
	if ok_button:
		ok_button.pressed.connect(_start_practice)
	if practice_room_type_option:
		practice_room_type_option.clear()
		practice_room_type_option.add_item("Combat", 0)
		practice_room_type_option.add_item("Elite", 1)
		practice_room_type_option.add_item("Boss", 2)
		practice_room_type_option.item_selected.connect(_on_practice_room_type_selected)
	if practice_floor_slider:
		practice_floor_slider.value_changed.connect(_on_practice_floor_changed)
		_sync_practice_floor_widgets()
	_on_practice_room_type_selected(0)

func _open_practice_dialog() -> void:
	if practice_dialog == null:
		return
	_sync_practice_floor_widgets()
	_refresh_practice_layout_grid()
	practice_dialog.popup_centered()

func _on_practice_room_type_selected(index: int) -> void:
	match index:
		2:
			_practice_room_type = "boss"
		1:
			_practice_room_type = "elite"
		_:
			_practice_room_type = "combat"
	if practice_floor_row:
		practice_floor_row.visible = _practice_room_type != "boss"
	if _practice_room_type == "boss":
		_practice_floor_index = 1
	_sync_practice_floor_widgets()
	_refresh_practice_layout_grid()

func _on_practice_floor_changed(value: float) -> void:
	_practice_floor_index = max(1, int(round(value)))
	_sync_practice_floor_widgets()

func _sync_practice_floor_widgets() -> void:
	if practice_floor_slider:
		var safe_value: float = float(max(1, _practice_floor_index))
		if absf(practice_floor_slider.value - safe_value) > 0.01:
			practice_floor_slider.value = safe_value
	if practice_floor_value:
		practice_floor_value.text = str(max(1, _practice_floor_index))

func _practice_layout_ids_for_selection() -> Array[String]:
	if _practice_room_type == "boss":
		return ["boss_act1", "boss_act2", "boss_act3"]
	if _practice_room_type == "elite":
		return [
			"elite_ring_pylons",
			"elite_split_fortress",
			"elite_pinwheel",
			"elite_donut"
		]
	return [
		"grid",
		"stagger",
		"pyramid",
		"zigzag",
		"ring",
		"split_lanes",
		"core",
		"criss_cross",
		"hollow_diamond",
		"checker_gate"
	]

func _layout_label(layout_id: String) -> String:
	if layout_id.begins_with("boss_act"):
		var suffix: String = layout_id.trim_prefix("boss_act")
		return "Boss Act %s" % suffix
	if layout_id.begins_with("elite_"):
		return "Elite: %s" % layout_id.trim_prefix("elite_").replace("_", " ").capitalize()
	return layout_id.replace("_", " ").capitalize()

func _make_layout_preview(pattern_id: String, rows: int, cols: int, with_border: bool) -> Texture2D:
	var width: int = 120
	var height: int = 84
	var border: int = 3
	var gap: int = 2

	var background: Color = Color(0.08, 0.08, 0.10, 1.0)
	var cell_off: Color = Color(0.10, 0.10, 0.12, 1.0)
	var cell_on: Color = Color(0.90, 0.90, 0.92, 1.0)
	var border_color: Color = Color(0.95, 0.85, 0.25, 1.0)

	var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(background)

	if with_border:
		for x in range(width):
			for y in range(border):
				img.set_pixel(x, y, border_color)
				img.set_pixel(x, height - 1 - y, border_color)
		for y in range(height):
			for x in range(border):
				img.set_pixel(x, y, border_color)
				img.set_pixel(width - 1 - x, y, border_color)

	var inner_left: int = border
	var inner_top: int = border
	var inner_width: int = width - border * 2
	var inner_height: int = height - border * 2

	var cell_w: int = int(floor((float(inner_width - gap * (cols - 1))) / float(cols)))
	var cell_h: int = int(floor((float(inner_height - gap * (rows - 1))) / float(rows)))
	cell_w = max(2, cell_w)
	cell_h = max(2, cell_h)

	var used_w: int = cell_w * cols + gap * (cols - 1)
	var used_h: int = cell_h * rows + gap * (rows - 1)
	var start_x: int = inner_left + int(floor(float(inner_width - used_w) * 0.5))
	var start_y: int = inner_top + int(floor(float(inner_height - used_h) * 0.5))

	for row in range(rows):
		for col in range(cols):
			var on: bool = _pattern_registry.allows(row, col, rows, cols, pattern_id)
			var color: Color = cell_on if on else cell_off
			var x0: int = start_x + col * (cell_w + gap)
			var y0: int = start_y + row * (cell_h + gap)
			for y in range(cell_h):
				for x in range(cell_w):
					img.set_pixel(x0 + x, y0 + y, color)

	return ImageTexture.create_from_image(img)

func _layout_preview_grid_size(layout_id: String) -> Vector2i:
	if layout_id.begins_with("boss_act"):
		return Vector2i(6, 10)
	if layout_id.begins_with("elite_"):
		return Vector2i(5, 9)
	return Vector2i(4, 9)

func _refresh_practice_layout_grid() -> void:
	if practice_layout_grid == null:
		return
	for child: Node in practice_layout_grid.get_children():
		child.queue_free()

	var layout_ids: Array[String] = _practice_layout_ids_for_selection()
	if layout_ids.is_empty():
		_practice_layout_id = ""
		return
	if not layout_ids.has(_practice_layout_id):
		_practice_layout_id = layout_ids[0]

	for layout_id: String in layout_ids:
		var selected_layout_id: String = layout_id
		var grid_size: Vector2i = _layout_preview_grid_size(layout_id)
		var rows: int = grid_size.x
		var cols: int = grid_size.y

		var normal_tex: Texture2D = _make_layout_preview(selected_layout_id, rows, cols, false)
		var pressed_tex: Texture2D = _make_layout_preview(selected_layout_id, rows, cols, true)

		var button: TextureButton = TextureButton.new()
		button.toggle_mode = true
		button.button_group = _layout_button_group
		button.texture_normal = normal_tex
		button.texture_hover = pressed_tex
		button.texture_pressed = pressed_tex
		button.texture_focused = pressed_tex
		button.custom_minimum_size = Vector2(120.0, 84.0)
		button.tooltip_text = _layout_label(selected_layout_id)
		button.toggled.connect(func(pressed: bool) -> void:
			if pressed:
				_practice_layout_id = selected_layout_id
		)
		if selected_layout_id == _practice_layout_id:
			button.button_pressed = true

		var label: Label = Label.new()
		label.text = _layout_label(selected_layout_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var cell: VBoxContainer = VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(button)
		cell.add_child(label)
		practice_layout_grid.add_child(cell)

func _start_practice() -> void:
	if _practice_layout_id == "":
		return
	var room_type: String = _practice_room_type
	var act_index: int = 1
	if room_type == "boss" and _practice_layout_id.begins_with("boss_act"):
		var act_suffix: String = _practice_layout_id.trim_prefix("boss_act")
		var parsed: int = act_suffix.to_int()
		act_index = clampi(parsed, 1, 3)
	var floor_index: int = max(1, _practice_floor_index)
	if room_type == "boss":
		floor_index = 1
	App.start_practice(room_type, act_index, _practice_layout_id, floor_index)
	if practice_dialog:
		practice_dialog.hide()

func _read_seed_input() -> Dictionary:
	if seed_input == null:
		return {"valid": true, "seed": 0}
	var raw := seed_input.text.strip_edges()
	if raw.is_empty():
		return {"valid": true, "seed": 0}
	if not raw.is_valid_int():
		return {"valid": true, "seed": 0}
	var seed_value: int = int(raw)
	if seed_value <= 0:
		return {"valid": true, "seed": 0}
	return {"valid": true, "seed": seed_value}

func _on_seed_text_changed(text: String) -> void:
	if suppress_seed_validation:
		return
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		_set_seed_status("")
		return
	if not trimmed.is_valid_int() or int(trimmed) <= 0:
		suppress_seed_validation = true
		seed_input.text = ""
		suppress_seed_validation = false
		_set_seed_status("")

func _set_seed_status(message: String) -> void:
	if seed_status == null:
		return
	seed_status.text = message

func _apply_menu_palette() -> void:
	var buttons := _menu_buttons()
	var palette_size := _menu_palette.size()
	for i in range(buttons.size()):
		var button := buttons[i]
		if button == null:
			continue
		var color := _menu_palette[i % palette_size]
		var hover := color.darkened(0.12)
		var pressed := color.darkened(0.22)
		button.add_theme_stylebox_override("normal", _make_button_box(color))
		button.add_theme_stylebox_override("hover", _make_button_box(hover))
		button.add_theme_stylebox_override("pressed", _make_button_box(pressed))

func _menu_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	if start_button:
		buttons.append(start_button)
	if continue_button:
		buttons.append(continue_button)
	if end_button and end_button.visible:
		buttons.append(end_button)
	if help_button:
		buttons.append(help_button)
	if settings_button:
		buttons.append(settings_button)
	if test_button and test_button.visible:
		buttons.append(test_button)
	if quit_button:
		buttons.append(quit_button)
	return buttons

func _make_button_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.content_margin_left = 10
	box.content_margin_top = 6
	box.content_margin_right = 10
	box.content_margin_bottom = 6
	box.shadow_color = Color.WHITE
	box.shadow_size = 2
	return box
