extends Control

const Design = preload("res://scripts/QuantumTheme.gd")
var game: Node
var hit_flash: float = 0.0
var shot_flash: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	hit_flash = maxf(hit_flash - delta, 0.0)
	shot_flash = maxf(shot_flash - delta, 0.0)
	if visible:
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game):
		return
	var tint: Color = Design.GOLD if hit_flash > 0.0 else Design.CYAN
	var center := Vector2(640, 360)
	var gap: float = 8.0 + shot_flash * 28.0
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * gap, center + direction * (gap + 7.0), Color(tint, 0.8), 1.5, true)
	draw_circle(center, 1.6, tint, true, -1.0, true)
	if hit_flash > 0.0:
		for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			draw_line(center + direction * 5.0, center + direction * 10.0, Design.GOLD, 2.0, true)
	var card := Rect2(1046, 474, 210, 153)
	draw_style_box(Design.panel_style(), card)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(1064, 497), "RADAR CUANTICO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Design.CYAN)
	var player: Node3D = game.get("player") as Node3D
	if not is_instance_valid(player):
		return
	var level: int = int(game.get("level"))
	if level == 4:
		_draw_registers(player)
		return
	var maze: Array = game.get("maze")
	var cell: float = 7.8
	var origin := Vector2(1073, 510)
	for row in range(maze.size()):
		for column in range(str(maze[row]).length()):
			var glyph: String = str(maze[row]).substr(column, 1)
			if glyph == "#":
				draw_rect(Rect2(origin + Vector2(column, row) * cell, Vector2.ONE * (cell - 0.7)), Color("#25435b"))
			elif glyph == "E":
				draw_circle(origin + Vector2(column + 0.5, row + 0.5) * cell, 3.2, Color("#6fffc1"))
	var enemies: Array = game.get("enemies")
	for enemy: Node3D in enemies:
		if is_instance_valid(enemy):
			var p := Vector2(enemy.position.x, enemy.position.z) / 3.0 + Vector2.ONE * 0.5
			var frozen: bool = float(enemy.get("frozen_time")) > 0.0
			draw_circle(origin + p * cell, 2.4, Design.CYAN if frozen else Color("#ff6b83"))
	var p := origin + (Vector2(player.position.x, player.position.z) / 3.0 + Vector2.ONE * 0.5) * cell
	_draw_player(p, player.rotation.y)

func _draw_registers(player: Node3D) -> void:
	var bounds := Rect2(1070, 510, 162, 105)
	draw_rect(bounds, Color("#12263c"))
	draw_rect(bounds, Color(Design.CYAN, 0.35), false, 1.0)
	draw_line(Vector2(1151, 510), Vector2(1151, 615), Color(Design.VIOLET, 0.45), 1.0)
	for marker_name in ["q1_station", "q2_station", "delivery_area"]:
		var marker: Node3D = game.get(marker_name) as Node3D
		if is_instance_valid(marker):
			draw_circle(_room_point(marker.position, bounds), 3.0, Design.GOLD if marker_name == "delivery_area" else Design.VIOLET)
	for qubit_name in ["qbit1", "qbit2"]:
		var qubit: Node3D = game.get(qubit_name) as Node3D
		if is_instance_valid(qubit) and qubit != player:
			draw_circle(_room_point(qubit.position, bounds), 3.6, Design.VIOLET)
	_draw_player(_room_point(player.position, bounds), player.rotation.y)

func _room_point(position_at: Vector3, bounds: Rect2) -> Vector2:
	return bounds.position + Vector2((position_at.x + 12.0) / 24.0, (position_at.z + 9.0) / 18.0) * bounds.size

func _draw_player(at: Vector2, yaw: float) -> void:
	var forward := Vector2(-sin(yaw), -cos(yaw))
	draw_circle(at, 3.3, Design.CYAN, true, -1.0, true)
	draw_line(at, at + forward * 8.0, Design.TEXT, 1.5, true)
