extends Node
class_name DeckManager

signal hand_changed(hand: Array[String])
signal piles_changed(draw_pile: Array[String], discard_pile: Array[String], deck: Array[String])

const MAX_HAND_SIZE: int = 7

var deck: Array[String] = []
var draw_pile: Array[String] = []
var discard_pile: Array[String] = []
var hand: Array[String] = []

func setup(starting_deck: Array[String]) -> void:
	deck = starting_deck.duplicate()
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	_shuffle_into_draw(deck)
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
	for card_id in hand:
		discard_pile.append(card_id)
	hand.clear()
	_emit_hand_changed()
	_emit_piles_changed()

func discard_card(card_id: String) -> void:
	discard_pile.append(card_id)
	_emit_piles_changed()

func add_card(card_id: String) -> void:
	deck.append(card_id)
	draw_pile.append(card_id)
	draw_pile.shuffle()
	_emit_piles_changed()

func remove_card_from_all(card_id: String, remove_from_deck: bool = true) -> void:
	if remove_from_deck:
		_remove_one_from_array(deck, card_id)
	_remove_one_from_array(draw_pile, card_id)
	_remove_one_from_array(discard_pile, card_id)
	_remove_one_from_array(hand, card_id)
	_emit_hand_changed()
	_emit_piles_changed()

func remove_card_from_deck(card_id: String) -> void:
	_remove_one_from_array(deck, card_id)
	_emit_piles_changed()

func play_card(card_id: String) -> void:
	hand.erase(card_id)
	_emit_hand_changed()

func _shuffle_into_draw(cards: Array) -> void:
	draw_pile = cards.duplicate()
	draw_pile.shuffle()

func _remove_one_from_array(values: Array, target: String) -> void:
	var index: int = values.find(target)
	if index >= 0:
		values.remove_at(index)

func _emit_hand_changed() -> void:
	hand_changed.emit(hand.duplicate())

func _emit_piles_changed() -> void:
	piles_changed.emit(draw_pile.duplicate(), discard_pile.duplicate(), deck.duplicate())
