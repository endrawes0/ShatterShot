extends Node
class_name StateManager

signal state_changed(prev_state: int, next_state: int, context: Dictionary)

enum GameState {
	MAIN_MENU,
	SETTINGS,
	HOW_TO_PLAY,
	MAP,
	ENCOUNTER_COMBAT,
	ENCOUNTER_ELITE,
	ENCOUNTER_BOSS,
	PLANNING,
	VOLLEY,
	REWARD,
	TREASURE,
	SHOP,
	REST,
	GAME_OVER,
	VICTORY
}

const ALLOWED_TRANSITIONS: Dictionary = {
	GameState.MAIN_MENU: {
		"start_run": GameState.MAP,
		"start_test_lab": GameState.MAP,
		"continue_run": GameState.MAP,
		"open_settings": GameState.SETTINGS,
		"open_how_to_play": GameState.HOW_TO_PLAY
	},
	GameState.SETTINGS: {
		"close_settings": GameState.MAIN_MENU
	},
	GameState.HOW_TO_PLAY: {
		"close_how_to_play": GameState.MAIN_MENU
	},
	GameState.MAP: {
		"enter_room_combat": GameState.ENCOUNTER_COMBAT,
		"enter_room_elite": GameState.ENCOUNTER_ELITE,
		"enter_room_boss": GameState.ENCOUNTER_BOSS,
		"enter_room_shop": GameState.SHOP,
		"enter_room_treasure": GameState.TREASURE,
		"enter_room_rest": GameState.REST,
		"open_menu": GameState.MAIN_MENU
	},
	GameState.ENCOUNTER_COMBAT: {
		"start_encounter": GameState.PLANNING
	},
	GameState.ENCOUNTER_ELITE: {
		"start_encounter": GameState.PLANNING
	},
	GameState.ENCOUNTER_BOSS: {
		"start_encounter": GameState.PLANNING
	},
	GameState.PLANNING: {
		"launch_volley": GameState.VOLLEY,
		"advance_act": GameState.MAP,
		"volley_win": GameState.REWARD,
		"planning_lose": GameState.GAME_OVER,
		"victory": GameState.VICTORY,
		"open_menu": GameState.MAIN_MENU
	},
	GameState.VOLLEY: {
		"advance_act": GameState.MAP,
		"volley_continue": GameState.PLANNING,
		"volley_win": GameState.REWARD,
		"volley_lose": GameState.GAME_OVER,
		"victory": GameState.VICTORY,
		"open_menu": GameState.MAIN_MENU
	},
	GameState.REWARD: {
		"go_to_map": GameState.MAP,
		"open_menu": GameState.MAIN_MENU
	},
	GameState.TREASURE: {
		"go_to_map": GameState.MAP,
		"open_menu": GameState.MAIN_MENU
	},
	GameState.SHOP: {
		"go_to_map": GameState.MAP,
		"open_menu": GameState.MAIN_MENU
	},
	GameState.REST: {
		"go_to_map": GameState.MAP,
		"open_menu": GameState.MAIN_MENU
	},
	GameState.GAME_OVER: {
		"resurrect": GameState.REWARD,
		"victory": GameState.VICTORY,
		"restart_run": GameState.MAP,
		"open_menu": GameState.MAIN_MENU
	},
	GameState.VICTORY: {
		"restart_run": GameState.MAP,
		"open_menu": GameState.MAIN_MENU
	}
}

var _state: int = GameState.MAIN_MENU
var _last_run_state: int = GameState.MAP

func set_initial_state(state: int) -> void:
	_state = state

func current_state() -> int:
	return _state

func last_run_state() -> int:
	return _last_run_state

func transition_event(event: String, context: Dictionary = {}) -> bool:
	if event == "":
		return false
	if event == "continue_run":
		if _state != GameState.MAIN_MENU:
			return false
		var resume_context: Dictionary = context.duplicate()
		resume_context["resume"] = true
		return transition_to(_last_run_state, resume_context)
	var transitions: Dictionary = ALLOWED_TRANSITIONS.get(_state, {})
	if transitions.is_empty():
		return false
	if not transitions.has(event):
		return false
	var next_state: int = int(transitions[event])
	return transition_to(next_state, context)

func transition_to(next_state: int, context: Dictionary = {}) -> bool:
	if next_state == _state:
		return false
	var prev_state: int = _state
	if next_state == GameState.MAIN_MENU and _state != GameState.MAIN_MENU:
		_last_run_state = _state
	_state = next_state
	emit_signal("state_changed", prev_state, next_state, context)
	return true
