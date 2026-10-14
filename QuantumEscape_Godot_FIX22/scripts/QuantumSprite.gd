extends Node2D

# The physics body owns movement and collision; this node only paints the actor.
@export var kind: String = "qubit"
var color: Color = Color("60e8ff"):
	set(value):
		color = value
		queue_redraw()
var radius: float = 13.0
var superposed: bool = false
var selected: bool = false

var _time: float = 0.0
const VIOLET: Color = Color("b488ff")
const WHITE: Color = Color("e1fbff")
const DARK: Color = Color("071422")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var r: float = maxf(radius, 3.0)
	match kind:
		"enemy":
			_draw_enemy(r)
		"pad":
			_draw_pad(r)
		"detector":
			_draw_detector(r)
		"exit":
			_draw_exit(r)
		_:
			_draw_qubit(r)


func _ink(tint: Color, alpha: float) -> Color:
	return Color(tint.r, tint.g, tint.b, alpha * tint.a)


func _ring(center: Vector2, r: float, tint: Color, width: float = 1.0) -> void:
	draw_arc(center, r, 0.0, TAU, 64, tint, width, true)


func _ellipse(center: Vector2, dimensions: Vector2, angle: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(65):
		var a: float = TAU * float(i) / 64.0
		var p := Vector2(cos(a) * dimensions.x, sin(a) * dimensions.y)
		points.append(center + p.rotated(angle))
	return points


func _halo(center: Vector2, r: float, tint: Color, strength: float = 1.0) -> void:
	var breath: float = 1.0 + sin(_time * 1.7) * 0.025
	for i in range(5, 0, -1):
		var spread: float = 1.0 + float(i) * 0.095
		draw_circle(center, r * spread * breath, _ink(tint, (0.012 + float(5 - i) * 0.005) * strength))


func _draw_qubit(r: float) -> void:
	var stroke: float = maxf(1.0, r * 0.012)
	if superposed:
		for sign_value in [-1.0, 1.0]:
			var ghost := Vector2(sign_value * r * 0.80, sin(_time * 1.9 + sign_value) * r * 0.13)
			_halo(ghost, r * 0.77, VIOLET, 1.2)
			_ring(ghost, r * 0.77, _ink(VIOLET, 0.35), stroke)
			draw_polyline(_ellipse(ghost, Vector2(r * 0.75, r * 0.24), -0.55), _ink(VIOLET, 0.32), stroke, true)
			draw_circle(ghost, r * 0.18, _ink(VIOLET, 0.30))
	_halo(Vector2.ZERO, r, color, 1.35)
	# Layered shading gives a glass sphere volume even at a small maze scale.
	draw_circle(Vector2.ZERO, r, DARK)
	draw_circle(Vector2(-r * 0.10, -r * 0.10), r * 0.87, _ink(color, 0.13))
	draw_circle(Vector2(-r * 0.18, -r * 0.19), r * 0.64, _ink(color, 0.075))
	_ring(Vector2.ZERO, r, _ink(color, 0.95), stroke)
	_ring(Vector2.ZERO, r * 0.94, _ink(WHITE, 0.18), stroke)

	# Bloch-sphere meridians, equator and the north/south axis.
	draw_polyline(_ellipse(Vector2.ZERO, Vector2(r * 0.34, r * 0.97), -0.27), _ink(color, 0.50), stroke, true)
	draw_polyline(_ellipse(Vector2.ZERO, Vector2(r * 0.76, r * 0.97), -0.27), _ink(color, 0.23), stroke, true)
	draw_polyline(_ellipse(Vector2.ZERO, Vector2(r * 0.98, r * 0.34), -0.27), _ink(color, 0.72), stroke, true)
	var axis := Vector2(sin(0.27), -cos(0.27))
	draw_line(-axis * r * 1.13, axis * r * 1.13, _ink(color, 0.38), stroke, true)
	draw_circle(axis * r * 1.02, maxf(1.6, r * 0.026), WHITE)
	draw_circle(-axis * r * 1.02, maxf(1.3, r * 0.020), color)

	# The state vector ends in a luminous point that slowly orbits the equator.
	var orbit_angle: float = _time * 0.68 - 0.65
	var state := Vector2(cos(orbit_angle) * r * 0.90, sin(orbit_angle) * r * 0.31).rotated(-0.27)
	draw_line(Vector2.ZERO, state, _ink(WHITE, 0.56), stroke, true)
	draw_circle(state, maxf(2.0, r * 0.055), _ink(color, 0.18))
	draw_circle(state, maxf(1.4, r * 0.030), WHITE)
	draw_circle(Vector2.ZERO, maxf(2.0, r * 0.072), _ink(color, 0.90))
	draw_circle(Vector2(-r * 0.018, -r * 0.020), maxf(1.0, r * 0.035), WHITE)
	draw_arc(Vector2.ZERO, r * 0.86, -2.4, -1.7, 18, _ink(WHITE, 0.46), stroke, true)

	if selected:
		var outer: float = r * 1.40
		var turn: float = _time * 0.38
		_ring(Vector2.ZERO, outer, _ink(color, 0.14), stroke)
		for quarter in range(4):
			var start_angle: float = float(quarter) * PI * 0.5 + turn
			draw_arc(Vector2.ZERO, outer, start_angle, start_angle + 0.63, 16, _ink(WHITE, 0.86), maxf(1.5, r * 0.014), true)


func _draw_enemy(r: float) -> void:
	var stroke: float = maxf(1.0, r * 0.045)
	_halo(Vector2.ZERO, r * 0.95, color, 1.15)
	var vertices := PackedVector2Array()
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0
		vertices.append(Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(vertices, Color("170c1c"))
	vertices.append(vertices[0])
	draw_polyline(vertices, _ink(color, 0.95), stroke, true)
	# Armor plates leave the central horizontal visor easy to read.
	draw_line(Vector2(-r * 0.40, -r * 0.62), Vector2(r * 0.40, -r * 0.62), _ink(color, 0.40), stroke, true)
	draw_line(Vector2(-r * 0.40, r * 0.62), Vector2(r * 0.40, r * 0.62), _ink(color, 0.40), stroke, true)
	draw_line(Vector2(-r * 0.64, 0), Vector2(r * 0.64, 0), _ink(color, 0.18), maxf(3.0, r * 0.34), true)
	draw_line(Vector2(-r * 0.58, 0), Vector2(r * 0.58, 0), color, maxf(1.4, r * 0.13), true)
	var scan: float = sin(_time * 2.0) * r * 0.39
	draw_circle(Vector2(scan, 0), maxf(1.3, r * 0.09), Color("fff0e6"))
	for sign_value in [-1.0, 1.0]:
		draw_line(Vector2(sign_value * r * 0.76, -r * 0.27), Vector2(sign_value * r * 0.76, r * 0.27), _ink(WHITE, 0.40), stroke, true)


func _draw_pad(r: float) -> void:
	var stroke: float = maxf(1.0, r * 0.04)
	_halo(Vector2.ZERO, r * 0.88, color, 0.90)
	draw_circle(Vector2.ZERO, r * 0.89, _ink(DARK, 0.90))
	_ring(Vector2.ZERO, r * 0.95, _ink(color, 0.36), stroke)
	_ring(Vector2.ZERO, r * 0.75, _ink(color, 0.78), stroke)
	_ring(Vector2.ZERO, r * 0.58, _ink(color, 0.20), stroke)
	for i in range(8):
		var angle: float = float(i) * TAU / 8.0
		var radial := Vector2(cos(angle), sin(angle))
		draw_line(radial * r * 0.85, radial * r * 0.97, _ink(color, 0.95), stroke, true)
	var turn: float = _time * 0.35
	for i in range(3):
		var angle: float = turn + float(i) * TAU / 3.0
		draw_arc(Vector2.ZERO, r * 0.75, angle, angle + 0.55, 12, _ink(WHITE, 0.78), stroke, true)
	draw_polyline(_ellipse(Vector2.ZERO, Vector2(r * 0.42, r * 0.20), -0.55), _ink(color, 0.50), stroke, true)
	draw_polyline(_ellipse(Vector2.ZERO, Vector2(r * 0.42, r * 0.20), 0.55), _ink(color, 0.50), stroke, true)
	draw_circle(Vector2.ZERO, r * 0.09, color)


func _draw_detector(r: float) -> void:
	var stroke: float = maxf(1.0, r * 0.04)
	_halo(Vector2.ZERO, r * 0.68, color, 0.75)
	var diamond := PackedVector2Array([Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)])
	draw_colored_polygon(diamond, Color("151922"))
	diamond.append(diamond[0])
	draw_polyline(diamond, _ink(color, 0.78), stroke, true)
	_ring(Vector2.ZERO, r * 0.48, _ink(color, 0.34), stroke)
	var scan_angle: float = _time * 0.85
	draw_arc(Vector2.ZERO, r * 0.48, scan_angle, scan_angle + PI * 0.7, 22, _ink(color, 0.92), stroke, true)
	var sweep := Vector2(cos(scan_angle), sin(scan_angle))
	draw_line(Vector2.ZERO, sweep * r * 0.45, _ink(color, 0.48), stroke, true)
	draw_circle(Vector2.ZERO, maxf(1.7, r * 0.085), WHITE)
	for sign_value in [-1.0, 1.0]:
		draw_circle(Vector2(sign_value * r * 0.77, 0), maxf(1.0, r * 0.06), color)


func _draw_exit(r: float) -> void:
	var stroke: float = maxf(1.0, r * 0.05)
	_halo(Vector2.ZERO, r * 0.94, color, 1.4)
	draw_circle(Vector2.ZERO, r * 0.88, DARK)
	_ring(Vector2.ZERO, r, _ink(color, 0.35), stroke)
	draw_polyline(_ellipse(Vector2.ZERO, Vector2(r * 0.65, r * 0.88)), color, maxf(1.4, r * 0.075), true)
	draw_polyline(_ellipse(Vector2.ZERO, Vector2(r * 0.46, r * 0.68)), _ink(color, 0.40), stroke, true)
	var pulse: float = 0.5 + 0.5 * sin(_time * 1.8)
	draw_line(Vector2(0, -r * 0.62), Vector2(0, r * 0.62), _ink(color, 0.15 + pulse * 0.10), maxf(3.0, r * 0.22), true)
	# A bright arrow identifies the gate from a distance.
	var arrow := PackedVector2Array([Vector2(-r * 0.20, -r * 0.23), Vector2(r * 0.15, 0), Vector2(-r * 0.20, r * 0.23)])
	draw_polyline(arrow, _ink(WHITE, 0.88), maxf(1.5, r * 0.075), true)
	for i in range(4):
		var angle: float = float(i) * PI * 0.5 + PI * 0.25
		var marker := Vector2(cos(angle), sin(angle)) * r
		draw_circle(marker, maxf(1.2, r * 0.07), color)
