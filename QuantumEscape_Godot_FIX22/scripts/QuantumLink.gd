extends Node2D

var first: Node2D
var second: Node2D
var active: bool = false
var color: Color = Color("#51e8f4")
var _time: float = 0.0
var _refresh: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	_refresh += delta
	if _refresh >= 1.0 / 30.0:
		_refresh = 0.0
		queue_redraw()

func _draw() -> void:
	if not active or not is_instance_valid(first) or not is_instance_valid(second):
		return
	var start: Vector2 = to_local(first.global_position)
	var finish: Vector2 = to_local(second.global_position)
	var normal: Vector2 = (finish - start).normalized().orthogonal()
	var points := PackedVector2Array()
	for index in range(49):
		var fraction: float = float(index) / 48.0
		var wave: float = sin(fraction * TAU * 2.0 - _time * 2.0) * sin(fraction * PI) * 7.0
		points.append(start.lerp(finish, fraction) + normal * wave)
	draw_polyline(points, Color(color, 0.06), 8.0, true)
	draw_polyline(points, Color(color, 0.30), 1.0, true)
	for index in range(5):
		var fraction: float = fposmod(_time * 0.15 + float(index) / 5.0, 1.0)
		var position_on_link: Vector2 = start.lerp(finish, fraction)
		draw_circle(position_on_link, 6.0, Color(color, 0.08), true, -1.0, true)
		draw_circle(position_on_link, 2.0, Color(color, 0.8), true, -1.0, true)
