extends Control

# Oscar is drawn by the game itself: no image, font download or mouse input is needed.
const Design = preload("res://scripts/QuantumTheme.gd")

var dialogue_text: String = "Hola, soy Oscar. Te ayudare a escapar del laboratorio."
var topic_text: String = "TU ASISTENTE CUANTICO"
var mood: String = "normal"
var dialogue_label: Label
var name_label: Label
var topic_label: Label

var _menu_layout: bool = true
var _portrait_layout: bool = false
var _clock: float = 0.0
var _talk_remaining: float = 0.0
var _bubble_rect := Rect2(18.0, 306.0, 474.0, 168.0)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	# Children stay inside the card; long speech wraps instead of being clipped.
	clip_contents = false


func _ready() -> void:
	_ensure_labels()
	_apply_layout()


func configure_menu() -> void:
	_menu_layout = true
	_portrait_layout = false
	size = Vector2(490.0, 92.0)
	_ensure_labels()
	_apply_layout()


func configure_hud() -> void:
	_menu_layout = false
	_portrait_layout = false
	size = Vector2(214.0, 376.0)
	_ensure_labels()
	_apply_layout()


func configure_portrait() -> void:
	_portrait_layout = true
	_menu_layout = false
	size = Vector2(64.0, 78.0)
	_ensure_labels()
	_apply_layout()


func speak(text: String, topic: String = "", expression: String = "normal") -> void:
	# Repeated game updates must not restart Oscar's talking animation.
	if dialogue_text == text and topic_text == topic and mood == expression:
		return
	dialogue_text = text
	topic_text = topic
	mood = expression
	_talk_remaining = clampf(float(text.length()) * 0.035, 1.2, 5.0)
	_ensure_labels()
	_update_labels()
	queue_redraw()


func _ensure_labels() -> void:
	if is_instance_valid(dialogue_label):
		return
	name_label = _make_label("OSCAR", 20, Design.CYAN)
	topic_label = _make_label(topic_text, 12, Design.MUTED)
	topic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label = _make_label(dialogue_text, 18, Design.TEXT)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_update_labels()


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	Design.style_label(label, font_size, color)
	add_child(label)
	return label


func _apply_layout() -> void:
	for label: Label in [name_label, topic_label, dialogue_label]:
		label.visible = not _portrait_layout
	if _portrait_layout:
		queue_redraw()
		return
	if _menu_layout:
		name_label.position = Vector2(78.0, 10.0)
		name_label.size = Vector2(396.0, 20.0)
		name_label.add_theme_font_size_override("font_size", 14)
		topic_label.visible = false
		dialogue_label.position = Vector2(78.0, 34.0)
		dialogue_label.size = Vector2(394.0, 46.0)
		dialogue_label.add_theme_font_size_override("font_size", 14)
	else:
		_bubble_rect = Rect2(1.0, 112.0, 212.0, 262.0)
		name_label.position = Vector2(86.0, 20.0)
		name_label.size = Vector2(115.0, 25.0)
		name_label.add_theme_font_size_override("font_size", 18)
		topic_label.position = Vector2(86.0, 46.0)
		topic_label.size = Vector2(113.0, 43.0)
		topic_label.add_theme_font_size_override("font_size", 11)
		dialogue_label.position = Vector2(16.0, 121.0)
		dialogue_label.size = Vector2(182.0, 247.0)
		dialogue_label.add_theme_font_size_override("font_size", 15)
	_fit_dialogue()
	queue_redraw()


func _update_labels() -> void:
	dialogue_label.text = dialogue_text
	topic_label.text = topic_text
	topic_label.add_theme_color_override("font_color", _accent())
	if is_inside_tree():
		_fit_dialogue.call_deferred()


func _fit_dialogue() -> void:
	if _portrait_layout or not is_inside_tree():
		return
	var font_size: int = 14 if _menu_layout else 15
	var budget: float = 46.0 if _menu_layout else 247.0
	dialogue_label.add_theme_font_size_override("font_size", font_size)
	# Only exceptionally wide 200-character messages need a smaller size.
	while dialogue_label.get_minimum_size().y > budget and font_size > 10:
		font_size -= 1
		dialogue_label.add_theme_font_size_override("font_size", font_size)
	dialogue_label.size.y = budget


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_clock += delta
	_talk_remaining = maxf(_talk_remaining - delta, 0.0)
	queue_redraw()


func _accent() -> Color:
	if mood in ["alert", "warning", "worried"]:
		return Design.GOLD
	if mood in ["thinking", "quantum"]:
		return Design.VIOLET
	return Design.CYAN


func _draw() -> void:
	if size.x < 1.0:
		return
	var accent: Color = _accent()
	if _portrait_layout:
		_draw_robot(Vector2(32.0, 42.0), 0.35, accent)
		return
	var card: StyleBoxFlat = Design.panel_style(accent, Color("#091725"))
	card.shadow_size = 0
	card.border_color = Color(accent, 0.30)
	draw_style_box(card, Rect2(Vector2.ONE, size - Vector2.ONE * 2.0))
	if _menu_layout:
		_draw_robot(Vector2(37.0, 47.0), 0.35, accent)
		return
	var bubble: StyleBoxFlat = Design.panel_style(accent, Color("#0c2032"))
	bubble.shadow_size = 0
	bubble.border_color = Color(accent, 0.22)
	draw_style_box(bubble, _bubble_rect)
	# A little tail makes the instruction card read as Oscar's speech.
	var tail_x: float = 45.0
	var tail_y: float = _bubble_rect.position.y
	draw_colored_polygon(PackedVector2Array([
		Vector2(tail_x - 9.0, tail_y + 1.0),
		Vector2(tail_x, tail_y - 10.0),
		Vector2(tail_x + 9.0, tail_y + 1.0),
	]), Color("#0c2032"))
	draw_polyline(PackedVector2Array([
		Vector2(tail_x - 9.0, tail_y),
		Vector2(tail_x, tail_y - 10.0),
		Vector2(tail_x + 9.0, tail_y),
	]), Color(accent, 0.24), 1.0, true)
	_draw_robot(Vector2(45.0, 56.0), 0.48, accent)
	var pulse: float = 0.50 + sin(_clock * 2.0) * 0.16
	draw_circle(Vector2(193.0, 25.0), 2.3, Color(accent, pulse), true, -1.0, true)


func _draw_robot(origin: Vector2, robot_scale: float, accent: Color) -> void:
	var bob: float = sin(_clock * 1.7) * 3.0
	var talking: bool = _talk_remaining > 0.0
	var face_shift: float = sin(_clock * 0.8) * 1.8
	var blink_phase: float = fmod(_clock, 4.6)
	var blinking: bool = blink_phase > 4.42
	var eye_height: float = 1.1 if blinking else 6.2
	var antenna_glow: float = 0.65 + sin(_clock * 3.0) * 0.18
	draw_set_transform(origin, 0.0, Vector2.ONE * robot_scale)
	# Ground glow and a restrained halo hold the same quantum-console palette.
	_draw_ellipse(Vector2(0.0, 67.0), Vector2(61.0, 7.0), Color(accent, 0.12), 1.2)
	draw_arc(Vector2(0.0, -9.0), 85.0, -2.7, -0.7, 38, Color(Design.VIOLET, 0.18), 1.0, true)
	draw_arc(Vector2(0.0, -9.0), 85.0, 0.45, 2.2, 38, Color(accent, 0.20), 1.0, true)
	draw_set_transform(origin + Vector2(0.0, bob * robot_scale), 0.0, Vector2.ONE * robot_scale)
	# Antenna, rounded ears and a metal shell; Oscar is deliberately softer than a drone.
	draw_line(Vector2(0.0, -59.0), Vector2(0.0, -73.0), Design.MUTED, 3.0, true)
	draw_circle(Vector2(0.0, -77.0), 7.3, Color(accent, 0.11), true, -1.0, true)
	draw_circle(Vector2(0.0, -77.0), 4.0, Color(accent, antenna_glow), true, -1.0, true)
	_draw_round_rect(Rect2(-53.0, -42.0, 12.0, 26.0), 5, Color("#243c54"), accent)
	_draw_round_rect(Rect2(41.0, -42.0, 12.0, 26.0), 5, Color("#243c54"), accent)
	_draw_round_rect(Rect2(-43.0, -59.0, 86.0, 61.0), 15, Color("#25435b"), Color(accent, 0.75))
	draw_line(Vector2(-25.0, -53.0), Vector2(25.0, -53.0), Color(Design.TEXT, 0.22), 1.6, true)
	_draw_round_rect(Rect2(-34.0, -47.0, 68.0, 39.0), 11, Color("#071420"), Color(accent, 0.22))
	# Eyes blink, glance a little and lift their eyebrows when danger is near.
	var eye_y: float = -31.0
	for eye_x: float in [-16.0, 16.0]:
		_draw_round_rect(Rect2(eye_x - 5.0 + face_shift, eye_y - eye_height, 10.0, eye_height * 2.0), 4, accent, Color.TRANSPARENT)
		if not blinking:
			draw_circle(Vector2(eye_x - 1.0 + face_shift, eye_y - 2.7), 1.4, Color.WHITE, true, -1.0, true)
	if mood in ["alert", "warning", "worried"]:
		draw_line(Vector2(-25.0, -44.0), Vector2(-12.0, -46.0), accent, 2.0, true)
		draw_line(Vector2(12.0, -46.0), Vector2(25.0, -44.0), accent, 2.0, true)
	elif mood == "happy":
		draw_circle(Vector2(-26.0, -22.0), 3.0, Color(Design.VIOLET, 0.4), true, -1.0, true)
		draw_circle(Vector2(26.0, -22.0), 3.0, Color(Design.VIOLET, 0.4), true, -1.0, true)
	var mouth := PackedVector2Array()
	for point in range(13):
		var x: float = -9.0 + point * 1.5
		var y: float = -18.0 + (1.0 - pow(x / 9.0, 2.0)) * 3.2
		if talking:
			y += sin(_clock * 18.0 + point * 0.7) * 1.0
		mouth.append(Vector2(x + face_shift, y))
	draw_polyline(mouth, Color(accent, 0.9), 1.8, true)
	# Arms have a friendly, small wave; hands never enter the speech card.
	var hand_lift: float = sin(_clock * 4.0) * 3.5 if talking else sin(_clock * 1.2) * 1.5
	draw_polyline(PackedVector2Array([Vector2(-27.0, 17.0), Vector2(-42.0, 13.0), Vector2(-49.0, 25.0)]), Color("#60839e"), 5.0, true)
	draw_polyline(PackedVector2Array([Vector2(27.0, 17.0), Vector2(42.0, 12.0), Vector2(49.0, 1.0 + hand_lift)]), Color("#60839e"), 5.0, true)
	draw_circle(Vector2(-49.0, 25.0), 5.1, Color("#26465e"), true, -1.0, true)
	draw_circle(Vector2(-49.0, 25.0), 5.1, accent, false, 1.2, true)
	draw_circle(Vector2(49.0, 1.0 + hand_lift), 5.1, Color("#26465e"), true, -1.0, true)
	draw_circle(Vector2(49.0, 1.0 + hand_lift), 5.1, accent, false, 1.2, true)
	draw_line(Vector2(-15.0, 43.0), Vector2(-15.0, 54.0), Design.MUTED, 4.0, true)
	draw_line(Vector2(15.0, 43.0), Vector2(15.0, 54.0), Design.MUTED, 4.0, true)
	_draw_round_rect(Rect2(-27.0, 51.0, 20.0, 9.0), 4, Color("#23415a"), Color(accent, 0.4))
	_draw_round_rect(Rect2(7.0, 51.0, 20.0, 9.0), 4, Color("#23415a"), Color(accent, 0.4))
	_draw_round_rect(Rect2(-29.0, 7.0, 58.0, 40.0), 12, Color("#1a334b"), Color(accent, 0.50))
	draw_circle(Vector2(0.0, 26.0), 9.0, Color(accent, 0.16), true, -1.0, true)
	_draw_ellipse(Vector2(0.0, 26.0), Vector2(15.0, 6.0), accent, 1.3, -0.48)
	_draw_ellipse(Vector2(0.0, 26.0), Vector2(15.0, 6.0), Color(Design.VIOLET, 0.8), 1.3, 0.48)
	draw_circle(Vector2(0.0, 26.0), 3.5, Design.TEXT, true, -1.0, true)
	var orbit_phase: float = _clock * 1.8
	var orbit_at := Vector2(cos(orbit_phase) * 14.5, sin(orbit_phase) * 5.8).rotated(-0.48) + Vector2(0.0, 26.0)
	draw_circle(orbit_at, 2.4, accent, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_round_rect(rect: Rect2, radius: int, fill: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color, width: float, angle: float = 0.0) -> void:
	var points := PackedVector2Array()
	for point in range(49):
		var phase: float = float(point) / 48.0 * TAU
		points.append(center + Vector2(cos(phase) * radius.x, sin(phase) * radius.y).rotated(angle))
	draw_polyline(points, color, width, true)
