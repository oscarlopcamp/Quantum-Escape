extends Node2D
## Procedural laboratory scenery. All coordinates use the game's 1280 x 720 canvas.
## Set mode, maze, board_offset, cell_size and accent before adding this node.

var mode: String = "menu"
var maze: Array[String] = []
var board_offset: Vector2 = Vector2(240, 100)
var cell_size: float = 40.0
var accent: Color = Color("66e7ff")

const CANVAS_SIZE := Vector2(1280, 720)
const INK := Color("050b16")
const WALL_BODY := Color("142c43")
const WALL_PLATE := Color("1b354c")

var _clock: float = 0.0
var _redraw_elapsed: float = 0.0
var _stars: Array[Vector3] = []


func _ready() -> void:
	# Deterministic placement keeps the quiet star field stable on every redraw.
	for index in range(78):
		var x := fmod(float(index * 179 + 71), CANVAS_SIZE.x)
		var y := fmod(float(index * index * 31 + 47), CANVAS_SIZE.y)
		_stars.append(Vector3(x, y, 0.65 + float(index % 4) * 0.32))
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	_redraw_elapsed += delta
	if _redraw_elapsed >= 1.0 / 30.0:
		_redraw_elapsed = fmod(_redraw_elapsed, 1.0 / 30.0)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), INK)
	_draw_glow(Vector2(1030, 225), 420.0, Color("067c9d"), 0.008)
	_draw_glow(Vector2(620, 725), 350.0, Color("5944a5"), 0.007)
	_draw_star_field()
	_draw_margin_circuits()
	if mode == "maze":
		_draw_maze()
	elif mode == "entanglement":
		_draw_entanglement()
	else:
		_draw_menu()


func _draw_glow(center: Vector2, radius: float, tint: Color, opacity: float) -> void:
	for layer in range(14, 0, -1):
		var fraction := float(layer) / 14.0
		draw_circle(center, radius * fraction, _alpha(tint, opacity * (1.0 - fraction * 0.6)))


func _draw_star_field() -> void:
	for index in range(_stars.size()):
		var star: Vector3 = _stars[index]
		var shimmer := 0.17 + 0.08 * sin(_clock * 0.65 + float(index) * 1.9)
		var position := Vector2(star.x, star.y)
		draw_circle(position, star.z, _alpha(accent, shimmer))
		if index % 13 == 0:
			draw_line(position - Vector2(4, 0), position + Vector2(4, 0), _alpha(accent, 0.13))
			draw_line(position - Vector2(0, 4), position + Vector2(0, 4), _alpha(accent, 0.13))


func _draw_margin_circuits() -> void:
	var trace_color := _alpha(accent, 0.12)
	for index in range(5):
		var step := float(index) * 13.0
		var left := PackedVector2Array([
			Vector2(0, 178 + step), Vector2(32 + step, 178 + step),
			Vector2(75 + step, 221 + step), Vector2(75 + step, 465 - step),
			Vector2(48 + step, 492 - step), Vector2(0, 492 - step)
		])
		draw_polyline(left, trace_color, 1.0, true)
		var right := PackedVector2Array([
			Vector2(1280, 160 + step), Vector2(1228 - step, 160 + step),
			Vector2(1186 - step, 202 + step), Vector2(1186 - step, 499 - step),
			Vector2(1230 - step, 543 - step), Vector2(1280, 543 - step)
		])
		draw_polyline(right, trace_color, 1.0, true)
		draw_circle(Vector2(75 + step, 300 + float(index) * 24.0), 2.1, _alpha(accent, 0.28))
		draw_circle(Vector2(1186 - step, 365 - float(index) * 24.0), 2.1, _alpha(accent, 0.28))
	# The top and bottom rails frame the whole interface without covering controls.
	draw_line(Vector2(38, 30), Vector2(342, 30), _alpha(accent, 0.20), 1.0)
	draw_line(Vector2(934, 30), Vector2(1242, 30), _alpha(accent, 0.20), 1.0)
	draw_line(Vector2(38, 689), Vector2(1242, 689), _alpha(accent, 0.13), 1.0)
	for index in range(24):
		var x := 948.0 + float(index) * 12.0
		var height := 2.0 + float((index * 7) % 5) * 1.5
		draw_line(Vector2(x, 678), Vector2(x, 678 - height), _alpha(accent, 0.35), 2.0)
	draw_rect(Rect2(38, 678, 36, 3), _alpha(accent, 0.70))
	draw_rect(Rect2(81, 678, 13, 3), _alpha(accent, 0.30))


func _draw_menu() -> void:
	# Right-hand hologram mount; the actual animated qubit is drawn above it.
	var center := Vector2(885, 322)
	for radius in [211.0, 244.0, 282.0]:
		draw_arc(center, radius, -1.05, 1.14, 60, _alpha(accent, 0.13), 1.0, true)
		draw_arc(center, radius, 1.90, 3.80, 60, _alpha(accent, 0.08), 1.0, true)
	for index in range(60):
		var angle := float(index) * TAU / 60.0
		var direction := Vector2(cos(angle), sin(angle))
		var outer := 263.0 if index % 5 == 0 else 257.0
		draw_line(center + direction * 250.0, center + direction * outer, _alpha(accent, 0.20), 1.0)
	var phase := _clock * 0.11
	for index in range(3):
		var angle := phase + float(index) * TAU / 3.0
		var direction := Vector2(cos(angle), sin(angle))
		draw_circle(center + direction * 244.0, 3.0, _alpha(accent, 0.75))
		draw_arc(center, 244.0, angle - 0.18, angle, 14, _alpha(accent, 0.40), 2.0, true)
	# A sparse instrument grid sits under the hero, leaving the title area clear.
	for index in range(12):
		var x := 669.0 + float(index) * 40.0
		draw_line(Vector2(x, 176), Vector2(x, 492), _alpha(accent, 0.027), 1.0)
	for index in range(9):
		var y := 175.0 + float(index) * 40.0
		draw_line(Vector2(669, y), Vector2(1109, y), _alpha(accent, 0.027), 1.0)
	_draw_bracket(Vector2(658, 85), Vector2(1140, 563), 22.0, 0.28)
	draw_line(Vector2(716, 593), Vector2(1055, 593), _alpha(accent, 0.25), 1.0)
	for index in range(9):
		var x := 735.0 + float(index) * 36.0
		draw_rect(Rect2(x, 610, 22, 3), _alpha(accent, 0.16 + float(index % 3) * 0.09))


func _draw_maze() -> void:
	if maze.is_empty():
		return
	var board_size := Vector2(float(maze[0].length()) * cell_size, float(maze.size()) * cell_size)
	_draw_board(Rect2(board_offset, board_size), cell_size)
	for row in range(maze.size()):
		for column in range(maze[row].length()):
			var tile_position := board_offset + Vector2(float(column), float(row)) * cell_size
			if maze[row][column] == "#":
				_draw_wall(row, column, tile_position)
			elif (row + column * 3) % 9 == 0:
				var center := tile_position + Vector2.ONE * cell_size * 0.5
				draw_line(center - Vector2(3, 0), center + Vector2(3, 0), _alpha(accent, 0.09), 1.0)
				draw_line(center - Vector2(0, 3), center + Vector2(0, 3), _alpha(accent, 0.09), 1.0)


func _draw_board(bounds: Rect2, grid: float) -> void:
	# A deep floor and solid raised walls make walkable passages easy to read.
	var shadow := bounds.grow(10.0)
	shadow.position += Vector2(0, 7)
	draw_rect(shadow, Color(0, 0, 0, 0.45))
	draw_rect(bounds.grow(9.0), Color("102334"))
	draw_rect(bounds.grow(8.0), _alpha(accent, 0.24), false, 1.0)
	draw_rect(bounds.grow(3.0), Color("091523"))
	draw_rect(bounds, Color("070f1d"))
	var columns := int(bounds.size.x / grid)
	var rows := int(bounds.size.y / grid)
	for index in range(columns + 1):
		var x := bounds.position.x + float(index) * grid
		draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), _alpha(accent, 0.055), 1.0)
	for index in range(rows + 1):
		var y := bounds.position.y + float(index) * grid
		draw_line(Vector2(bounds.position.x, y), Vector2(bounds.end.x, y), _alpha(accent, 0.055), 1.0)
	var scan_y := bounds.position.y + fmod(_clock * 24.0, bounds.size.y)
	draw_rect(Rect2(bounds.position.x, scan_y, bounds.size.x, 2.0), _alpha(accent, 0.025))
	_draw_bracket(bounds.position - Vector2(11, 11), bounds.end + Vector2(11, 11), 20.0, 0.75)
	for index in range(4):
		var x := bounds.position.x + 26.0 + float(index) * 16.0
		draw_rect(Rect2(x, bounds.end.y + 12.0, 10, 2), _alpha(accent, 0.27 + float(index % 2) * 0.3))


func _draw_wall(row: int, column: int, origin: Vector2) -> void:
	var tile := Rect2(origin, Vector2.ONE * cell_size)
	draw_rect(tile, WALL_BODY)
	var plate := tile.grow(-3.0)
	draw_rect(plate, WALL_PLATE)
	draw_line(plate.position, Vector2(plate.end.x, plate.position.y), Color("315369"), 1.0)
	draw_line(Vector2(plate.position.x, plate.end.y), plate.end, Color("0b1c2c"), 2.0)
	var channel_color := _alpha(accent, 0.13)
	var center := tile.get_center()
	# Each tile reads as one chip on the laboratory's raised circuit substrate.
	if (row + column) % 3 == 0:
		draw_rect(Rect2(center - Vector2(6, 5), Vector2(12, 10)), Color("122637"))
		draw_rect(Rect2(center - Vector2(6, 5), Vector2(12, 10)), channel_color, false, 1.0)
		draw_line(origin + Vector2(4, cell_size * 0.5), center - Vector2(6, 0), channel_color, 1.0)
		draw_line(center + Vector2(6, 0), origin + Vector2(cell_size - 4, cell_size * 0.5), channel_color, 1.0)
	else:
		var channel := PackedVector2Array([
			origin + Vector2(7, cell_size - 9), origin + Vector2(7, 15),
			origin + Vector2(14, 8), origin + Vector2(cell_size - 8, 8)
		])
		draw_polyline(channel, channel_color, 1.0, true)
		draw_circle(origin + Vector2(cell_size - 8, 8), 1.6, _alpha(accent, 0.28))
	# Only exposed faces receive a bright rim, so connected walls form one barrier.
	var rim := _alpha(accent, 0.48)
	if not _is_wall(row - 1, column):
		draw_line(origin + Vector2(1, 1), origin + Vector2(cell_size - 1, 1), rim, 1.5)
	if not _is_wall(row + 1, column):
		draw_line(origin + Vector2(1, cell_size - 1), origin + Vector2(cell_size - 1, cell_size - 1), _alpha(accent, 0.26), 1.0)
	if not _is_wall(row, column - 1):
		draw_line(origin + Vector2(1, 1), origin + Vector2(1, cell_size - 1), _alpha(accent, 0.35), 1.0)
	if not _is_wall(row, column + 1):
		draw_line(origin + Vector2(cell_size - 1, 1), origin + Vector2(cell_size - 1, cell_size - 1), _alpha(accent, 0.35), 1.0)


func _is_wall(row: int, column: int) -> bool:
	if row < 0 or row >= maze.size():
		return false
	if column < 0 or column >= maze[row].length():
		return false
	return maze[row][column] == "#"


func _draw_entanglement() -> void:
	var bounds := Rect2(200, 90, 880, 540)
	_draw_board(bounds, 40.0)
	var divider_x := bounds.get_center().x
	for index in range(13):
		var y := 107.0 + float(index) * 40.0
		draw_line(Vector2(divider_x, y), Vector2(divider_x, y + 17), _alpha(accent, 0.13), 1.0)
	# Peripheral instruments identify the two quantum registers.
	_draw_register_panel(Rect2(121, 202, 57, 256), "Q1", accent)
	_draw_register_panel(Rect2(1102, 202, 57, 256), "Q2", Color("bba5ff"))
	draw_line(Vector2(220, 72), Vector2(501, 72), _alpha(accent, 0.22), 1.0)
	draw_line(Vector2(779, 72), Vector2(1060, 72), _alpha(Color("bba5ff"), 0.22), 1.0)


func _draw_register_panel(bounds: Rect2, caption: String, tint: Color) -> void:
	draw_rect(bounds, Color("0a1626"))
	draw_rect(bounds, _alpha(tint, 0.20), false, 1.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, bounds.position + Vector2(14, 28), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, _alpha(tint, 0.75))
	draw_line(bounds.position + Vector2(10, 39), bounds.position + Vector2(47, 39), _alpha(tint, 0.30), 1.0)
	for index in range(12):
		var y := bounds.position.y + 56.0 + float(index) * 14.0
		var amplitude := 9.0 + 11.0 * sin(_clock * 0.65 + float(index) * 0.7)
		draw_line(Vector2(bounds.position.x + 12.0, y), Vector2(bounds.position.x + 23.0 + amplitude, y), _alpha(tint, 0.36), 2.0)
		draw_circle(Vector2(bounds.position.x + 43.0, y), 1.0, _alpha(tint, 0.30))
	draw_circle(bounds.position + Vector2(15, bounds.size.y - 14), 2.2, _alpha(tint, 0.72))
	draw_line(bounds.position + Vector2(23, bounds.size.y - 14), bounds.position + Vector2(43, bounds.size.y - 14), _alpha(tint, 0.38), 1.0)


func _draw_bracket(start: Vector2, end: Vector2, length: float, opacity: float) -> void:
	var tint := _alpha(accent, opacity)
	for corner in [start, Vector2(end.x, start.y), end, Vector2(start.x, end.y)]:
		var direction := Vector2(1 if corner.x == start.x else -1, 1 if corner.y == start.y else -1)
		draw_line(corner, corner + Vector2(direction.x * length, 0), tint, 2.0, true)
		draw_line(corner, corner + Vector2(0, direction.y * length), tint, 2.0, true)


func _alpha(color: Color, opacity: float) -> Color:
	return Color(color.r, color.g, color.b, opacity)

