extends RefCounted

# Shared visual language for the quantum console and its controls.
const BG: Color = Color("#060c19")
const PANEL: Color = Color("#0b182a")
const CYAN: Color = Color("#51e8f4")
const VIOLET: Color = Color("#a989ff")
const TEXT: Color = Color("#e7f4ff")
const MUTED: Color = Color("#829cb7")
const GOLD: Color = Color("#f8ca6b")


static func panel_style(accent: Color = CYAN, fill: Color = PANEL) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(accent, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 4.0)
	style.content_margin_left = 18.0
	style.content_margin_top = 18.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 18.0
	return style


static func style_button(button: Button, primary: bool = false) -> void:
	var accent: Color = CYAN if primary else VIOLET
	var normal_fill: Color = Color("#123747") if primary else Color("#142139")
	var normal := panel_style(accent, normal_fill)
	normal.set_corner_radius_all(8)
	normal.shadow_size = 0
	normal.border_color = Color(accent, 0.48 if primary else 0.30)
	normal.content_margin_left = 16.0
	normal.content_margin_top = 10.0
	normal.content_margin_right = 16.0
	normal.content_margin_bottom = 10.0

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal_fill.lightened(0.09)
	hover.border_color = Color(accent, 0.82)
	hover.shadow_color = Color(accent, 0.10)
	hover.shadow_size = 5
	hover.shadow_offset = Vector2.ZERO

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal_fill.darkened(0.15)
	pressed.border_color = accent

	# Godot draws focus over the current button state; keep its interior clear.
	var focus: StyleBoxFlat = normal.duplicate()
	focus.draw_center = false
	focus.border_color = CYAN
	focus.set_border_width_all(2)
	focus.shadow_color = Color(CYAN, 0.17)
	focus.shadow_size = 5
	focus.shadow_offset = Vector2.ZERO

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = PANEL
	disabled.border_color = Color(MUTED, 0.18)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", CYAN)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


static func style_label(label: Label, font_size: int = 18, color: Color = TEXT) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.30))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)


static func create_panel(parent: Node, rect: Rect2, accent: Color = CYAN) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", panel_style(accent))
	parent.add_child(panel)
	return panel
