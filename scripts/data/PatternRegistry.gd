extends RefCounted
class_name PatternRegistry

var _patterns: Dictionary = {}

func _init() -> void:
	_register_default_patterns()

func register_pattern(pattern_id: String, handler: Callable) -> void:
	_patterns[pattern_id] = handler

func allows(row: int, col: int, rows: int, cols: int, pattern_id: String) -> bool:
	if _patterns.has(pattern_id):
		return _patterns[pattern_id].call(row, col, rows, cols)
	return true

func _register_default_patterns() -> void:
	register_pattern("grid", func(_row: int, _col: int, _rows: int, _cols: int) -> bool:
		return true
	)
	register_pattern("stagger", func(row: int, col: int, _rows: int, _cols: int) -> bool:
		return not (row % 2 == 1 and col % 2 == 0)
	)
	register_pattern("pyramid", func(row: int, col: int, _rows: int, cols: int) -> bool:
		var center: int = int(cols / 2)
		var spread: int = min(center, row + 1)
		return abs(col - center) <= spread
	)
	register_pattern("zigzag", func(row: int, col: int, _rows: int, _cols: int) -> bool:
		return (row + col) % 2 == 0
	)
	register_pattern("ring", func(row: int, col: int, rows: int, cols: int) -> bool:
		return row == 0 or row == rows - 1 or col == 0 or col == cols - 1
	)
