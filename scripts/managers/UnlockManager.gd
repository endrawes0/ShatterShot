extends Node
class_name UnlockManager

signal unlock_sequence_started
signal unlock_sequence_finished

const PROGRESS_PATH: String = "user://progress.cfg"

const UNLOCK_PARTICLE_COUNT: int = 22
const UNLOCK_PARTICLE_SPEED_X: Vector2 = Vector2(90.0, 210.0)
const UNLOCK_PARTICLE_SPEED_Y: Vector2 = Vector2(-320.0, -110.0)
const UNLOCK_PARTICLE_ORIGIN_JITTER: Vector2 = Vector2(6.0, 18.0)

const CARD_UNLOCK_REQUIREMENTS: Dictionary = {
	"moab": {
		"type": "use_card",
		"card_id": "bomb",
		"count": 5
	},
	"riposte": {
		"type": "use_card",
		"card_id": "parry",
		"count": 10
	},
	"what_doesnt_kill_us": {
		"type": "use_card",
		"card_id": "wound",
		"count": 10
	}
}

var _unlocked_cards: Dictionary = {}
var _card_use_counts: Dictionary = {}

var _unlock_reward_queue: Array[String] = []
var _unlock_sequence_active: bool = false
var _hand_interaction_locked: bool = false

var _hud: CanvasLayer = null
var _hud_controller: HudController = null
var _deck_manager: DeckManager = null
var _hand_container: Container = null
var _card_data: Dictionary = {}
var _card_pool: Array[String] = []
var _card_type_colors: Dictionary = {}
var _card_button_size: Vector2 = Vector2.ZERO
var _particle_scene: PackedScene = null
var _rng: RandomNumberGenerator = null
var _refresh_hand: Callable = Callable()
var _is_planning: Callable = Callable()

func bind_run_context(
	hud: CanvasLayer,
	hud_controller: HudController,
	deck_manager: DeckManager,
	hand_container: Container,
	card_data: Dictionary,
	card_pool: Array[String],
	card_type_colors: Dictionary,
	card_button_size: Vector2,
	particle_scene: PackedScene,
	rng: RandomNumberGenerator,
	refresh_hand: Callable,
	is_planning: Callable
) -> void:
	_hud = hud
	_hud_controller = hud_controller
	_deck_manager = deck_manager
	_hand_container = hand_container
	_card_data = card_data
	_card_pool = card_pool
	_card_type_colors = card_type_colors
	_card_button_size = card_button_size
	_particle_scene = particle_scene
	_rng = rng
	_refresh_hand = refresh_hand
	_is_planning = is_planning

func update_card_context(card_data: Dictionary, card_pool: Array[String]) -> void:
	_card_data = card_data
	_card_pool = card_pool

func is_unlock_sequence_active() -> bool:
	return _unlock_sequence_active

func is_hand_interaction_locked() -> bool:
	return _hand_interaction_locked

func load_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(PROGRESS_PATH)
	_unlocked_cards = {}
	_card_use_counts = {}
	if err == OK:
		var loaded_unlocked: Variant = config.get_value("progress", "unlocked_cards", {})
		if typeof(loaded_unlocked) == TYPE_DICTIONARY:
			_unlocked_cards = loaded_unlocked
		var loaded_counts: Variant = config.get_value("progress", "card_use_counts", {})
		if typeof(loaded_counts) == TYPE_DICTIONARY:
			_card_use_counts = loaded_counts

func reset_progress() -> void:
	_unlocked_cards = {}
	_card_use_counts = {}
	_save_progress()

func is_card_unlocked(card_id: String) -> bool:
	if not CARD_UNLOCK_REQUIREMENTS.has(card_id):
		return true
	return bool(_unlocked_cards.get(card_id, false))

func filter_unlocked_cards(card_ids: Array[String]) -> Array[String]:
	var filtered: Array[String] = []
	for card_id in card_ids:
		if is_card_unlocked(card_id):
			filtered.append(card_id)
	return filtered

func record_card_played(card_id: String) -> Array[String]:
	var unlocked: Array[String] = []
	var previous: int = int(_card_use_counts.get(card_id, 0))
	_card_use_counts[card_id] = previous + 1

	for unlocked_card_id in CARD_UNLOCK_REQUIREMENTS.keys():
		var unlock_id: String = String(unlocked_card_id)
		if is_card_unlocked(unlock_id):
			continue
		var requirement: Dictionary = CARD_UNLOCK_REQUIREMENTS.get(unlock_id, {})
		if String(requirement.get("type", "")) != "use_card":
			continue
		var required_card_id: String = String(requirement.get("card_id", ""))
		if required_card_id != card_id:
			continue
		var required_count: int = int(requirement.get("count", 0))
		var played_count: int = int(_card_use_counts.get(required_card_id, 0))
		if required_count > 0 and played_count >= required_count:
			_unlocked_cards[unlock_id] = true
			unlocked.append(unlock_id)

	_save_progress()
	return unlocked

func enqueue_unlock_rewards(card_ids: Array[String]) -> void:
	for card_id in card_ids:
		var id: String = String(card_id)
		if id.is_empty():
			continue
		_unlock_reward_queue.append(id)
	if _unlock_sequence_active:
		return
	_unlock_sequence_active = true
	_hand_interaction_locked = true
	_call_refresh_hand()
	unlock_sequence_started.emit()
	_run_unlock_reward_queue()

func _run_unlock_reward_queue() -> void:
	while not _unlock_reward_queue.is_empty():
		var unlock_id: String = String(_unlock_reward_queue.pop_front())
		if unlock_id.is_empty():
			continue
		if not _card_pool.has(unlock_id):
			_card_pool.append(unlock_id)
		await _show_unlock_reveal_and_gift(unlock_id)

	_unlock_sequence_active = false
	_hand_interaction_locked = false
	_call_refresh_hand()
	unlock_sequence_finished.emit()

func _call_refresh_hand() -> void:
	if _refresh_hand.is_valid():
		_refresh_hand.call()

func _show_unlock_reveal_and_gift(card_id: String) -> void:
	if _hud == null or _hud_controller == null or _deck_manager == null:
		return
	if _particle_scene == null:
		return
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()

	var card: Dictionary = _card_data.get(card_id, {})
	var card_name: String = String(card.get("name", card_id))
	var card_type: String = String(card.get("type", "utility"))
	var particle_color: Color = Color(0.95, 0.85, 0.25, 1.0)
	if _card_type_colors.has(card_type):
		particle_color = _card_type_colors[card_type]
	particle_color.a = 1.0

	var overlay: Control = Control.new()
	overlay.name = "CardUnlockOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.focus_mode = Control.FOCUS_ALL
	_hud.add_child(overlay)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(backdrop)

	var particles_root: Node2D = Node2D.new()
	particles_root.name = "Particles"
	particles_root.z_index = 1
	overlay.add_child(particles_root)

	var header: Label = Label.new()
	header.name = "Header"
	header.text = "New card unlocked!"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 22)
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 80.0
	header.offset_bottom = 120.0
	header.modulate = Color(1, 1, 1, 0)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.z_index = 30
	overlay.add_child(header)

	var mover: Control = Control.new()
	mover.name = "CardMover"
	mover.size = _card_button_size
	mover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mover.modulate = Color(1, 1, 1, 0)
	mover.pivot_offset = mover.size * 0.5
	mover.z_index = 20
	overlay.add_child(mover)

	var card_button: Button = _hud_controller.create_card_button(card_id)
	card_button.disabled = true
	card_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	mover.add_child(card_button)

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var start_pos: Vector2 = viewport_rect.position + (viewport_rect.size * 0.5) - (mover.size * 0.5)
	mover.global_position = start_pos
	mover.scale = Vector2.ONE * 0.6

	var time_scale: float = 2.0
	var intro: Tween = create_tween()
	intro.set_trans(Tween.TRANS_BACK)
	intro.set_ease(Tween.EASE_OUT)
	intro.tween_property(backdrop, "color", Color(0, 0, 0, 0.55), 0.18 * time_scale)
	intro.parallel().tween_property(header, "modulate", Color(1, 1, 1, 1), 0.12 * time_scale)
	intro.parallel().tween_property(mover, "modulate", Color(1, 1, 1, 1), 0.12 * time_scale)
	intro.parallel().tween_property(mover, "scale", Vector2.ONE, 0.28 * time_scale)
	intro.parallel().tween_property(mover, "rotation_degrees", -3.0, 0.28 * time_scale)
	await intro.finished

	_spawn_unlock_particle_streams(particles_root, Rect2(start_pos, mover.size), particle_color)
	header.text = "%s unlocked!" % card_name
	await get_tree().create_timer(0.55 * time_scale).timeout

	var new_instance_id: int = _deck_manager.add_card_to_hand_with_instance_id(card_id, true)
	_call_refresh_hand()
	await get_tree().process_frame

	var target_pos: Vector2 = start_pos
	var target_button: Button = _find_hand_button_by_instance_id(new_instance_id)
	if target_button != null:
		target_pos = target_button.get_global_rect().position
		target_button.modulate = Color(1, 1, 1, 0)
		target_button.scale = Vector2.ONE * 0.92

	var outro: Tween = create_tween()
	outro.set_trans(Tween.TRANS_QUAD)
	outro.set_ease(Tween.EASE_IN_OUT)
	outro.tween_property(mover, "global_position", target_pos, 0.34 * time_scale)
	outro.parallel().tween_property(mover, "scale", Vector2.ONE * 0.78, 0.34 * time_scale)
	outro.parallel().tween_property(mover, "rotation_degrees", 0.0, 0.34 * time_scale)
	outro.parallel().tween_property(backdrop, "color", Color(0, 0, 0, 0.0), 0.28 * time_scale)
	outro.parallel().tween_property(header, "modulate", Color(1, 1, 1, 0), 0.18 * time_scale)
	await outro.finished

	if target_button != null:
		target_button.modulate = Color(1, 1, 1, 1)
		var pop: Tween = target_button.create_tween()
		pop.set_trans(Tween.TRANS_BACK)
		pop.set_ease(Tween.EASE_OUT)
		pop.tween_property(target_button, "scale", Vector2.ONE, 0.22 * time_scale)

	overlay.queue_free()

func _find_hand_button_by_instance_id(instance_id: int) -> Button:
	if instance_id < 0 or _hand_container == null:
		return null
	for child in _hand_container.get_children():
		if child is Button:
			var button: Button = child as Button
			if button.has_meta("instance_id") and int(button.get_meta("instance_id")) == instance_id:
				return button
	return null

func _spawn_unlock_particle_streams(parent_node: Node, card_rect: Rect2, color: Color, base_count: int = UNLOCK_PARTICLE_COUNT) -> void:
	if parent_node == null:
		return
	var count: int = App.get_vfx_count(base_count)
	if count <= 0:
		return
	var per_side: int = max(1, int(ceil(float(count) * 0.5)))
	for _i in range(per_side):
		_spawn_unlock_particle(parent_node, card_rect, color, true)
	for _i in range(count - per_side):
		_spawn_unlock_particle(parent_node, card_rect, color, false)

func _spawn_unlock_particle(parent_node: Node, card_rect: Rect2, color: Color, left_side: bool) -> void:
	if parent_node == null or _particle_scene == null:
		return
	var particle: Node = _particle_scene.instantiate()
	if particle == null:
		return
	parent_node.add_child(particle)
	if particle is Node2D:
		var node: Node2D = particle as Node2D
		var side_x: float = card_rect.position.x if left_side else card_rect.position.x + card_rect.size.x
		var origin: Vector2 = Vector2(
			side_x,
			card_rect.position.y + (card_rect.size.y * 0.5)
		)
		origin.x += _rng.randf_range(-UNLOCK_PARTICLE_ORIGIN_JITTER.x, UNLOCK_PARTICLE_ORIGIN_JITTER.x)
		origin.y += _rng.randf_range(-UNLOCK_PARTICLE_ORIGIN_JITTER.y, UNLOCK_PARTICLE_ORIGIN_JITTER.y)
		node.global_position = origin
	if particle.has_method("setup"):
		var x_speed: float = _rng.randf_range(UNLOCK_PARTICLE_SPEED_X.x, UNLOCK_PARTICLE_SPEED_X.y)
		if left_side:
			x_speed = -x_speed
		var velocity: Vector2 = Vector2(
			x_speed,
			_rng.randf_range(UNLOCK_PARTICLE_SPEED_Y.x, UNLOCK_PARTICLE_SPEED_Y.y)
		)
		particle.call("setup", color, velocity)

func _save_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(PROGRESS_PATH)
	config.set_value("progress", "unlocked_cards", _unlocked_cards)
	config.set_value("progress", "card_use_counts", _card_use_counts)
	config.save(PROGRESS_PATH)

