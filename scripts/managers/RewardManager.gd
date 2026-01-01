extends Node
class_name RewardManager

signal reward_selected(card_id: String)

const DEFAULT_REWARD_TITLE: String = "Choose a card"
const DEFAULT_SKIP_TEXT: String = "Skip"
const DEFAULT_INFO_TEXT: String = "Room cleared. Choose a reward."
const DEFAULT_REWARD_COUNT: int = 3

var hud_controller: HudController
var reward_container: Container
var on_selected: Callable
var reward_label: Label
var reward_skip_button: Button
var info_callback: Callable
var reward_count: int = DEFAULT_REWARD_COUNT
var reward_title: String = DEFAULT_REWARD_TITLE
var reward_skip_text: String = DEFAULT_SKIP_TEXT
var reward_info_text: String = DEFAULT_INFO_TEXT

func setup(hud: HudController, container: Container) -> void:
	hud_controller = hud
	reward_container = container

func set_panel_nodes(label: Label, skip_button: Button) -> void:
	reward_label = label
	reward_skip_button = skip_button

func set_on_selected(callback: Callable) -> void:
	on_selected = callback

func set_info_callback(callback: Callable) -> void:
	info_callback = callback

func configure(config: Dictionary) -> void:
	reward_count = int(config.get("reward_count", DEFAULT_REWARD_COUNT))
	reward_title = String(config.get("reward_title", DEFAULT_REWARD_TITLE))
	reward_skip_text = String(config.get("reward_skip_text", DEFAULT_SKIP_TEXT))
	reward_info_text = String(config.get("reward_info_text", DEFAULT_INFO_TEXT))

func apply_panel_copy() -> void:
	if reward_label:
		reward_label.text = reward_title
	if reward_skip_button:
		reward_skip_button.text = reward_skip_text
	if info_callback.is_valid():
		info_callback.call(reward_info_text)

func clear_rewards() -> void:
	if reward_container == null:
		return
	for child in reward_container.get_children():
		child.queue_free()

func build_card_rewards(pick_card: Callable, count: int = -1) -> void:
	clear_rewards()
	if reward_container == null or hud_controller == null:
		return
	var reward_total := reward_count if count <= 0 else count
	for _i in range(reward_total):
		var card_id: String = ""
		if pick_card.is_valid():
			card_id = String(pick_card.call())
		if card_id == "":
			continue
		var reward_card_id := card_id
		var button := hud_controller.create_card_button(card_id)
		button.pressed.connect(func() -> void:
			if on_selected.is_valid():
				on_selected.call(reward_card_id)
			reward_selected.emit(reward_card_id)
		)
		reward_container.add_child(button)
