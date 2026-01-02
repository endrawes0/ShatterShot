extends Node
class_name DeckManager

signal hand_changed(hand: Array)
signal piles_changed(draw_pile: Array, discard_pile: Array, deck: Array)

const MAX_HAND_SIZE: int = 7

var deck: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var next_card_instance_id: int = 1

func set_rng(rng_instance: RandomNumberGenerator) -> void:
	if rng_instance != null:
		rng = rng_instance
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()

func setup(starting_deck: Array[String]) -> void:
	next_card_instance_id = 1
	deck.clear()
	for card_id in starting_deck:
		deck.append(_make_card_instance(String(card_id)))
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	_shuffle_into_draw(deck)
	_emit_piles_changed()
	_emit_hand_changed()

func reset_piles() -> void:
	draw_pile = deck.duplicate()
	discard_pile.clear()
	hand.clear()
	_shuffle_array(draw_pile)
	_emit_piles_changed()
	_emit_hand_changed()

func draw_cards(count: int) -> void:
	for _i in range(count):
		if hand.size() >= MAX_HAND_SIZE:
			break
		if draw_pile.is_empty():
			_shuffle_into_draw(discard_pile)
			discard_pile.clear()
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())
	_emit_hand_changed()
	_emit_piles_changed()

func discard_hand() -> void:
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	_emit_hand_changed()
	_emit_piles_changed()

func discard_card_instance(instance_id: int) -> void:
	var card := _remove_one_instance_from_array(hand, instance_id)
	if not card.is_empty():
		discard_pile.append(card)
	_emit_hand_changed()
	_emit_piles_changed()

func add_card(card_id: String) -> void:
	var card := _make_card_instance(card_id)
	deck.append(card)
	draw_pile.append(card)
	_shuffle_array(draw_pile)
	_emit_piles_changed()

func add_card_to_hand(card_id: String) -> bool:
	if hand.size() >= MAX_HAND_SIZE:
		return false
	var card := _make_card_instance(card_id)
	hand.append(card)
	_emit_hand_changed()
	return true

func remove_card_instance_from_all(instance_id: int, remove_from_deck: bool = true) -> void:
	if remove_from_deck:
		_remove_one_instance_from_array(deck, instance_id)
	_remove_one_instance_from_array(draw_pile, instance_id)
	_remove_one_instance_from_array(discard_pile, instance_id)
	_remove_one_instance_from_array(hand, instance_id)
	_emit_hand_changed()
	_emit_piles_changed()

func remove_card_from_deck(card_id: String) -> void:
	_remove_one_by_card_id(deck, card_id)
	_emit_piles_changed()

func play_card_instance(instance_id: int) -> void:
	_remove_one_instance_from_array(hand, instance_id)
	_emit_hand_changed()

func _shuffle_into_draw(cards: Array) -> void:
	draw_pile = cards.duplicate()
	_shuffle_array(draw_pile)

func _shuffle_array(values: Array) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp = values[i]
		values[i] = values[j]
		values[j] = temp

func _make_card_instance(card_id: String) -> Dictionary:
	var card := {
		"id": next_card_instance_id,
		"card_id": card_id
	}
	next_card_instance_id += 1
	return card

func get_card_id_from_hand(instance_id: int) -> String:
	var card := _get_instance_from_array(hand, instance_id)
	return String(card.get("card_id", ""))

func get_card_id_for_instance(instance_id: int) -> String:
	var card := _get_instance_from_array(hand, instance_id)
	if not card.is_empty():
		return String(card.get("card_id", ""))
	card = _get_instance_from_array(draw_pile, instance_id)
	if not card.is_empty():
		return String(card.get("card_id", ""))
	card = _get_instance_from_array(discard_pile, instance_id)
	if not card.is_empty():
		return String(card.get("card_id", ""))
	card = _get_instance_from_array(deck, instance_id)
	if not card.is_empty():
		return String(card.get("card_id", ""))
	return ""

func _get_instance_from_array(values: Array, instance_id: int) -> Dictionary:
	for card in values:
		if card is Dictionary and int(card.get("id", -1)) == instance_id:
			return card
	return {}

func _remove_one_instance_from_array(values: Array, instance_id: int) -> Dictionary:
	for index in range(values.size()):
		var card = values[index]
		if card is Dictionary and int(card.get("id", -1)) == instance_id:
			values.remove_at(index)
			return card
	return {}

func _remove_one_by_card_id(values: Array, card_id: String) -> void:
	for index in range(values.size()):
		var card = values[index]
		if card is Dictionary and String(card.get("card_id", "")) == card_id:
			values.remove_at(index)
			return

func _emit_hand_changed() -> void:
	hand_changed.emit(hand.duplicate())

func _emit_piles_changed() -> void:
	piles_changed.emit(draw_pile.duplicate(), discard_pile.duplicate(), deck.duplicate())
