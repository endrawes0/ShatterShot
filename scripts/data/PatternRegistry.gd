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
	register_pattern("split_lanes", func(_row: int, col: int, _rows: int, cols: int) -> bool:
		var center: int = int(cols / 2)
		return col == center - 2 or col == center + 2
	)
	register_pattern("core", func(row: int, col: int, rows: int, cols: int) -> bool:
		if row == 0 or row == rows - 1:
			return false
		return col >= 2 and col <= cols - 3
	)
	register_pattern("criss_cross", func(row: int, col: int, rows: int, cols: int) -> bool:
		var edge_offset: int = 0 if row == 0 or row == rows - 1 else 1
		return col == edge_offset or col == cols - 1 - edge_offset
	)
	register_pattern("hollow_diamond", func(row: int, col: int, _rows: int, cols: int) -> bool:
		var center: int = int(cols / 2)
		return abs(col - center) == row
	)
	register_pattern("checker_gate", func(row: int, col: int, _rows: int, _cols: int) -> bool:
		if row % 2 == 0:
			return col % 2 == 0
		return col % 3 == 1
	)
	register_pattern("elite_ring_pylons", func(row: int, col: int, rows: int, cols: int) -> bool:
		var center_row: int = int(rows / 2)
		var center_col: int = int(cols / 2)
		if row == 0 or row == rows - 1 or col == 0 or col == cols - 1:
			return true
		if (row == 1 or row == rows - 2) and (col == center_col - 1 or col == center_col + 1):
			return true
		return row == center_row and col == center_col
	)
	register_pattern("elite_split_fortress", func(_row: int, col: int, _rows: int, cols: int) -> bool:
		return (col >= 1 and col <= 3) or (col >= cols - 4 and col <= cols - 2)
	)
	register_pattern("elite_pinwheel", func(row: int, col: int, rows: int, cols: int) -> bool:
		var center_col: int = int(cols / 2)
		if row == 0 or row == rows - 1:
			return col == center_col
		if row == 1 or row == rows - 2:
			return col == center_col - 1 or col == center_col + 1
		return col == center_col - 2 or col == center_col or col == center_col + 2
	)
	register_pattern("elite_donut", func(row: int, col: int, rows: int, cols: int) -> bool:
		if row == 0 or row == rows - 1:
			return col >= 1 and col <= cols - 2
		return col == 1 or col == cols - 2
	)
	register_pattern("boss_act1", func(row: int, col: int, rows: int, cols: int) -> bool:
		var center: int = int(cols / 2)
		if row == 0 or row == rows - 1:
			return true
		if row == 1 or row == 2:
			return col == 0 or col == cols - 1 or col == center - 1 or col == center
		if row == 3:
			return col == 0 or col == cols - 1 or col == center - 2 or col == center + 1 or col == center - 1 or col == center
		return col == 0 or col == cols - 1
	)
	register_pattern("boss_act2", func(row: int, col: int, rows: int, cols: int) -> bool:
		if row == 0 or row == rows - 1:
			return col <= 3 or col >= cols - 4
		if row == 3:
			return col == 0 or col == cols - 1 or col == 3 or col == cols - 4
		return col == 0 or col == 3 or col == cols - 4 or col == cols - 1
	)
	register_pattern("boss_act3", func(row: int, col: int, rows: int, cols: int) -> bool:
		var center: int = int(cols / 2)
		if row == 0 or row == rows - 1:
			return true
		if row == 1 or row == rows - 2:
			return col == 0 or col == cols - 1 or (col >= center - 2 and col <= center + 1)
		if row == 2:
			return col == 0 or col == cols - 1 or col == center - 2 or col == center + 1
		return col == 0 or col == cols - 1 or col == center - 2 or col == center - 1 or col == center or col == center + 1
	)
