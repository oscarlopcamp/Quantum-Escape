extends Node3D

const QuantumSprite = preload("res://scripts/QuantumSprite.gd")
const QuantumBackdrop = preload("res://scripts/QuantumBackdrop.gd")
const Design = preload("res://scripts/QuantumTheme.gd")
const QuantumAudio = preload("res://scripts/QuantumAudio.gd")
const QuantumWorld = preload("res://scripts/QuantumWorld3D.gd")
const QuantumPlayer = preload("res://scripts/QuantumPlayer3D.gd")
const QuantumDrone = preload("res://scripts/QuantumDrone3D.gd")
const TacticalHUD = preload("res://scripts/QuantumTacticalHUD.gd")
const SCREEN_SIZE := Vector2(1280, 720)
const CELL: float = 3.0
const FREEZE_SECONDS: float = 3.5
const SHOT_COOLDOWN: float = 0.65

var level: int = 1
var game_started: bool = false
var game_over: bool = false
var superposition_active: bool = false
var superposition_locked: bool = false
var deaths_level_1: int = 0
var deaths_level_3: int = 0
var transitioning_to_level_2: bool = false
var active_qubit: int = 1
var entangled: bool = false
var entanglement_round: int = 0
var requested_color_name: String = ""
var requested_color_value: Color = Color.WHITE
var current_entangled_color_name: String = ""
var current_entangled_color_value: Color = Color.WHITE
var delivery_pending: bool = false
var ray_cooldown: float = 0.0
var last_shot_hit: bool = false
var last_shot_result: Dictionary = {}
var _path_timer: float = 0.0
var player: QuantumPlayer
var qbit1: QuantumPlayer
var qbit2: QuantumPlayer
var qbit1_visual: Node3D
var qbit2_visual: Node3D
var world: QuantumWorld
var generated_root: Node3D
var enemies: Array[QuantumDrone] = []
var detector_areas: Array[Node3D] = []
var color_pickups: Array[Node3D] = []
var exit_area: Node3D
var q1_station: Node3D
var q2_station: Node3D
var delivery_area: Node3D
var delivery_visual: Node3D
var soundtrack: QuantumAudio
var hud: CanvasLayer
var menu_layer: CanvasLayer
var modal_layer: CanvasLayer
var title_label: Label
var hud_label: Label
var level_title_label: Label
var instructions_label: Label
var message: Label
var phase_label: Label
var field_guide_label: Label
var controller_status_label: Label
var modal_title: Label
var modal_body: Label
var modal_action: Label
var modal_mode: String = ""
var start_button: Button
var quit_button: Button
var restart_button: Button
var menu_button: Button
var audio_toggle_button: Button
var tactical_hud: TacticalHUD
var weapon_label: Label
var phase_overlay: ColorRect

var maze: Array[String] = [
	"####################", "#P     #        #  #", "# ### ### ####### ##",
	"#   #     #        #", "### ##### # ###### #", "#     #   #   #    #",
	"# ### # ##### # ####", "# #   #     # #    #", "# # ####### # #### #",
	"# #       # #    # #", "# ####### # #### # #", "#       #        #E#",
	"####################"
]

func _ready() -> void:
	soundtrack = QuantumAudio.new()
	soundtrack.name = "QuantumAudio"
	add_child(soundtrack)
	create_menu()
	create_hud()
	create_modal()
	create_audio_controls()
	adapt_fps_interface()
	show_menu()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	update_controller_status()

func _physics_process(delta: float) -> void:
	if not game_started or game_over or is_modal_open():
		return
	ray_cooldown = maxf(0.0, ray_cooldown - delta)
	if Input.is_action_pressed("fire") and ray_cooldown <= 0.0:
		shoot_ray()
	if level == 4:
		check_entanglement_level()
		update_entanglement_visuals()
	else:
		_path_timer -= delta
		if _path_timer <= 0.0:
			_path_timer = 0.55
			update_drone_paths()
		if is_instance_valid(exit_area) and flat_distance(player.position, exit_area.position) < 0.82:
			_on_exit_entered(player)
		if level == 3 and superposition_active and not game_over:
			for detector in detector_areas:
				if flat_distance(player.position, detector.position) < 0.95:
					_on_detector_entered(player, detector)
					break
	update_hud()

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_music"):
		_toggle_audio()
		get_viewport().set_input_as_handled()
		return

	# Se procesa antes de la GUI: A acepta cuadros o usa la habilidad,
	# segun el contexto, sin activar tambien un boton con foco.
	if is_modal_open():
		if event.is_action_pressed("confirm"):
			accept_modal()
		elif event.is_action_pressed("back") or event.is_action_pressed("open_menu"):
			show_menu()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif event.is_action_pressed("back"):
		if game_started:
			show_menu()
		else:
			get_tree().quit()
	elif event.is_action_pressed("open_menu"):
		show_menu()
	elif not game_started:
		# Truco secreto para presentacion: desde el menu principal,
		# presiona 1, 2, 3 o 4 para saltar directo a ese nivel.
		if event is InputEventKey and event.pressed and (event.keycode == KEY_1 or event.keycode == KEY_KP_1):
			start_secret_level(1)
		elif event is InputEventKey and event.pressed and (event.keycode == KEY_2 or event.keycode == KEY_KP_2):
			start_secret_level(2)
		elif event is InputEventKey and event.pressed and (event.keycode == KEY_3 or event.keycode == KEY_KP_3):
			start_secret_level(3)
		elif event is InputEventKey and event.pressed and (event.keycode == KEY_4 or event.keycode == KEY_KP_4):
			start_secret_level(4)
		elif event.is_action_pressed("move_down"):
			quit_button.grab_focus()
		elif event.is_action_pressed("move_up"):
			start_button.grab_focus()
		elif event.is_action_pressed("confirm"):
			if quit_button.has_focus():
				_on_quit_pressed()
			else:
				_on_start_pressed()
		else:
			return
	elif game_over and not transitioning_to_level_2:
		if event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			menu_button.grab_focus()
		elif event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			restart_button.grab_focus()
		elif event.is_action_pressed("restart"):
			_on_restart_pressed()
		elif event.is_action_pressed("confirm"):
			if menu_button.has_focus():
				_on_menu_pressed()
			else:
				_on_restart_pressed()
		else:
			return
	elif not game_over and event.is_action_pressed("superposition"):
		if level == 4:
			handle_entanglement_space()
		elif level >= 2:
			toggle_superposition()
	else:
		return
	get_viewport().set_input_as_handled()

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	update_controller_status.call_deferred()

func update_controller_status() -> void:
	var controllers: Array[int] = Input.get_connected_joypads()
	if controllers.is_empty():
		controller_status_label.text = "Mando no detectado. Conecta tu control Xbox por USB."
	else:
		controller_status_label.text = "Mando detectado: %s" % Input.get_joy_name(controllers[0])

func create_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)

	var bg := QuantumBackdrop.new()
	bg.mode = "menu"
	menu_layer.add_child(bg)

	add_interface_label(menu_layer, "Q / LAB     ·     COMPUTACIÓN CUÁNTICA", Rect2(100, 48, 600, 30), 14, Design.CYAN)
	add_interface_label(menu_layer, "VERSIÓN 3D  /  04 PROTOCOLOS", Rect2(794, 48, 386, 30), 12, Design.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	title_label = add_interface_label(menu_layer, "QUANTUM\nESCAPE", Rect2(94, 116, 570, 179), 64, Design.TEXT)
	var display_font := SystemFont.new()
	display_font.font_names = PackedStringArray(["Avenir Next", "Arial"])
	display_font.font_weight = 800
	title_label.add_theme_font_override("font", display_font)
	add_interface_label(menu_layer, "Entra al laboratorio en primera persona.\nInmoviliza drones con tu rayo\ny rompe los límites del mundo clásico.", Rect2(100, 306, 500, 90), 20, Design.MUTED)

	var hero := QuantumSprite.new()
	hero.position = Vector2(903, 312)
	hero.radius = 126.0
	hero.color = Design.CYAN
	hero.selected = true
	menu_layer.add_child(hero)
	add_interface_label(menu_layer, "REGISTRO CUÁNTICO  /  |ψ⟩", Rect2(708, 114, 390, 28), 14, Design.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	add_interface_label(menu_layer, "|0⟩", Rect2(875, 152, 56, 28), 20, Design.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	add_interface_label(menu_layer, "|1⟩", Rect2(875, 455, 56, 28), 20, Design.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	add_interface_label(menu_layer, "|ψ⟩ = α |0⟩ + β |1⟩", Rect2(698, 499, 410, 40), 22, Design.VIOLET, HORIZONTAL_ALIGNMENT_CENTER)
	add_interface_label(menu_layer, "01  CLÁSICO      02  SUPERPOSICIÓN\n03  MEDICIÓN    04  ENTRELAZAMIENTO", Rect2(693, 558, 430, 52), 13, Design.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	start_button = Button.new()
	start_button.text = "INICIAR EN 3D    →"
	start_button.position = Vector2(100, 414)
	start_button.size = Vector2(330, 56)
	Design.style_button(start_button, true)
	start_button.pressed.connect(_on_start_pressed)
	menu_layer.add_child(start_button)
	start_button.focus_mode = Control.FOCUS_ALL

	quit_button = Button.new()
	quit_button.text = "Salir"
	quit_button.position = Vector2(100, 484)
	quit_button.size = Vector2(330, 46)
	Design.style_button(quit_button)
	quit_button.pressed.connect(_on_quit_pressed)
	menu_layer.add_child(quit_button)
	quit_button.focus_mode = Control.FOCUS_ALL

	Design.create_panel(menu_layer, Rect2(64, 642, 1152, 52))
	add_interface_label(menu_layer, "XBOX   Stick / Cruceta: elegir · A: aceptar · B: salir", Rect2(86, 657, 1108, 28), 14, Design.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	controller_status_label = add_interface_label(menu_layer, "", Rect2(100, 553, 510, 55), 14, Design.MUTED)
	controller_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	start_button.grab_focus()

func add_interface_label(parent: Node, text: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Design.style_label(label, font_size, color)
	parent.add_child(label)
	return label

func create_audio_controls() -> void:
	var audio_controls := CanvasLayer.new()
	audio_controls.layer = 3
	add_child(audio_controls)
	audio_toggle_button = Button.new()
	audio_toggle_button.name = "AudioToggle"
	audio_toggle_button.text = "Sonido: ON · Y"
	audio_toggle_button.position = Vector2(86, 654)
	audio_toggle_button.size = Vector2(158, 34)
	audio_toggle_button.focus_mode = Control.FOCUS_NONE
	Design.style_button(audio_toggle_button)
	audio_toggle_button.add_theme_font_size_override("font_size", 13)
	audio_toggle_button.pressed.connect(_toggle_audio)
	audio_controls.add_child(audio_toggle_button)

func _toggle_audio() -> void:
	soundtrack.set_muted(not soundtrack.muted)
	audio_toggle_button.text = "Sonido: OFF · Y" if soundtrack.muted else "Sonido: ON · Y"

func create_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 2
	add_child(hud)

	Design.create_panel(hud, Rect2(56, 16, 1168, 64))
	level_title_label = add_interface_label(hud, "", Rect2(80, 26, 485, 28), 18, Design.TEXT)
	add_interface_label(hud, "QUANTUM ESCAPE   /   ESTADO DEL SISTEMA", Rect2(82, 54, 480, 18), 10, Design.MUTED)
	hud_label = add_interface_label(hud, "", Rect2(571, 29, 630, 40), 14, Design.CYAN, HORIZONTAL_ALIGNMENT_RIGHT)
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	Design.create_panel(hud, Rect2(20, 122, 164, 390), Design.VIOLET)
	add_interface_label(hud, "PROTOCOLO ACTIVO", Rect2(36, 140, 133, 25), 11, Design.MUTED)
	phase_label = add_interface_label(hud, "01 / 04", Rect2(36, 167, 136, 38), 25, Design.VIOLET)
	message = add_interface_label(hud, "", Rect2(36, 224, 132, 273), 15, Design.TEXT)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	Design.create_panel(hud, Rect2(1100, 122, 160, 390))
	add_interface_label(hud, "GUÍA DE CAMPO", Rect2(1116, 140, 130, 24), 11, Design.CYAN)
	field_guide_label = add_interface_label(hud, "", Rect2(1116, 183, 128, 315), 14, Design.MUTED)
	field_guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Design.create_panel(hud, Rect2(36, 649, 1208, 49))
	instructions_label = add_interface_label(hud, "", Rect2(52, 663, 1176, 26), 14, Design.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	restart_button = Button.new()
	restart_button.text = "Reiniciar (X)"
	restart_button.position = Vector2(20, 530)
	restart_button.size = Vector2(164, 44)
	Design.style_button(restart_button, true)
	restart_button.add_theme_font_size_override("font_size", 16)
	restart_button.pressed.connect(_on_restart_pressed)
	hud.add_child(restart_button)
	restart_button.focus_mode = Control.FOCUS_ALL

	menu_button = Button.new()
	menu_button.text = "Menu (B)"
	menu_button.position = Vector2(20, 586)
	menu_button.size = Vector2(164, 44)
	Design.style_button(menu_button)
	menu_button.add_theme_font_size_override("font_size", 16)
	menu_button.pressed.connect(_on_menu_pressed)
	hud.add_child(menu_button)
	menu_button.focus_mode = Control.FOCUS_ALL

	hud.visible = false

func create_modal() -> void:
	modal_layer = CanvasLayer.new()
	modal_layer.layer = 20
	add_child(modal_layer)

	var shade: ColorRect = ColorRect.new()
	shade.name = "ModalShade"
	shade.color = Color(0.01, 0.025, 0.06, 0.88)
	shade.size = SCREEN_SIZE
	modal_layer.add_child(shade)

	var panel: Panel = Design.create_panel(modal_layer, Rect2(290, 145, 700, 430), Design.VIOLET)
	panel.name = "ModalPanel"
	add_interface_label(panel, "TRANSMISIÓN CUÁNTICA   /   Q-LAB", Rect2(34, 21, 630, 22), 11, Design.VIOLET)
	var emblem := QuantumSprite.new()
	emblem.radius = 22.0
	emblem.position = Vector2(57, 73)
	emblem.color = Design.VIOLET
	panel.add_child(emblem)
	modal_title = add_interface_label(panel, "", Rect2(94, 52, 573, 50), 32, Design.TEXT)

	var line: ColorRect = ColorRect.new()
	line.color = Color(Design.CYAN, 0.35)
	line.position = Vector2(34, 112)
	line.size = Vector2(632, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(line)

	modal_body = add_interface_label(panel, "", Rect2(45, 132, 610, 193), 21, Design.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	modal_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Design.create_panel(panel, Rect2(34, 348, 632, 50))
	modal_action = add_interface_label(panel, "", Rect2(44, 361, 612, 30), 18, Design.CYAN, HORIZONTAL_ALIGNMENT_CENTER)

	modal_layer.visible = false

func adapt_fps_interface() -> void:
	# The original holographic console remains, with compact field cards for FPS.
	menu_layer.get_children()[0].name = "HolographicMenuBackdrop"
	phase_overlay = ColorRect.new()
	phase_overlay.size = SCREEN_SIZE
	phase_overlay.color = Color(Design.VIOLET, 0.045)
	phase_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(phase_overlay)
	hud.move_child(phase_overlay, 0)
	phase_overlay.visible = false
	phase_label.position = Vector2(36, 167)
	message.position = Vector2(36, 224)
	message.size = Vector2(132, 273)
	field_guide_label.text = ""
	field_guide_label.size.y = 250
	for item in hud.get_children():
		if item is Panel and item.position == Vector2(1100, 122):
			item.size.y = 326
	tactical_hud = TacticalHUD.new()
	tactical_hud.game = self
	hud.add_child(tactical_hud)
	weapon_label = add_interface_label(hud, "RAYO DE COHERENCIA · LISTO", Rect2(375, 594, 530, 29), 14, Design.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	instructions_label.add_theme_font_size_override("font_size", 13)

func is_modal_open() -> bool:
	return modal_layer != null and modal_layer.visible

func _set_gameplay_enabled(value: bool) -> void:
	if is_instance_valid(qbit1):
		qbit1.set_enabled(false)
	if is_instance_valid(qbit2):
		qbit2.set_enabled(false)
	if is_instance_valid(player):
		player.set_enabled(value)
		# Keep the paused scene behind dialogs while releasing the pointer.
		if not value:
			player.camera.current = true
	for drone in enemies:
		drone.enabled = value
		if not value:
			drone.velocity = Vector3.ZERO
	if tactical_hud != null:
		tactical_hud.visible = value
	if weapon_label != null:
		weapon_label.visible = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE

func show_modal(title: String, body: String, action: String, mode: String) -> void:
	soundtrack.set_scene("modal")
	modal_mode = mode
	modal_title.text = title
	modal_body.text = body
	modal_action.text = action
	modal_layer.visible = true
	_set_gameplay_enabled(false)
	var focused_control := get_viewport().gui_get_focus_owner()
	if focused_control != null:
		focused_control.release_focus()

func hide_modal() -> void:
	modal_layer.visible = false
	modal_mode = ""

func accept_modal() -> void:
	soundtrack.play_cue("confirm")
	var mode: String = modal_mode
	hide_modal()
	if mode == "to_level_2":
		build_level(2)
	elif mode == "to_level_3":
		deaths_level_3 = 0
		build_level(3)
	elif mode == "to_level_4":
		build_level(4)
	elif mode == "restart_level":
		build_level(level)
	else:
		show_menu()

func show_menu() -> void:
	_set_gameplay_enabled(false)
	if modal_layer != null:
		hide_modal()
	game_started = false
	game_over = false
	transitioning_to_level_2 = false
	deaths_level_1 = 0
	deaths_level_3 = 0
	clear_old_level()
	soundtrack.set_scene("menu")
	menu_layer.visible = true
	hud.visible = false
	start_button.grab_focus()

func start_secret_level(target_level: int) -> void:
	deaths_level_1 = 0
	deaths_level_3 = 0
	game_started = true
	menu_layer.visible = false
	hud.visible = true
	build_level(target_level)

func _on_start_pressed() -> void:
	soundtrack.play_cue("confirm")
	start_secret_level(1)

func _on_quit_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().quit()

func _on_restart_pressed() -> void:
	soundtrack.play_cue("confirm")
	build_level(level)

func _on_menu_pressed() -> void:
	soundtrack.play_cue("confirm")
	show_menu()

func clear_old_level() -> void:
	if is_instance_valid(generated_root):
		generated_root.free()
	generated_root = null
	world = null
	player = null
	qbit1 = null
	qbit2 = null
	qbit1_visual = null
	qbit2_visual = null
	exit_area = null
	q1_station = null
	q2_station = null
	delivery_area = null
	delivery_visual = null
	enemies.clear()
	detector_areas.clear()
	color_pickups.clear()

func build_level(new_level: int) -> void:
	_set_gameplay_enabled(false)
	hide_modal()
	clear_old_level()
	level = new_level
	game_started = true
	game_over = false
	transitioning_to_level_2 = false
	superposition_active = false
	superposition_locked = false
	ray_cooldown = 0.0
	_path_timer = 0.0
	last_shot_hit = false
	last_shot_result = {}
	menu_layer.visible = false
	hud.visible = true
	restart_button.visible = false
	menu_button.visible = false
	phase_overlay.visible = false
	generated_root = Node3D.new()
	generated_root.name = "GeneratedLevel"
	add_child(generated_root)
	world = QuantumWorld.new()
	world.name = "QuantumLaboratory"
	generated_root.add_child(world)
	soundtrack.set_scene("entanglement" if level == 4 else ("quantum" if level >= 2 else "classic"))
	if level == 4:
		create_entanglement_level()
	else:
		world.build_maze(maze, level)
		for z in range(maze.size()):
			for x in range(maze[z].length()):
				var glyph: String = maze[z].substr(x, 1)
				var at := Vector3(x * CELL, 0.0, z * CELL)
				if glyph == "P":
					player = create_player(at + Vector3(0, 0.85, 0), -PI / 2.0)
					player.movement_bounds = Rect2(1.9, 1.9, (maze[0].length() - 1) * CELL - 3.8, (maze.size() - 1) * CELL - 3.8)
				elif glyph == "E":
					exit_area = world.marker(at, "exit", Color("#6fffc1"), "SALIDA / PORTAL")
		create_enemies()
		if level == 3:
			create_detectors()
		message.text = "Busca el portal verde.\n\nRT inmoviliza a los drones por 3,5 s."
		if level == 2:
			message.text = "A activa la superposición.\n\nAtraviesa los muros y alcanza el portal."
		elif level == 3:
			message.text = "Evita los escáneres M mientras estás en superposición."
	_set_gameplay_enabled(true)
	update_hud()

func create_player(at: Vector3, yaw: float) -> QuantumPlayer:
	var body := QuantumPlayer.new()
	body.position = at
	generated_root.add_child(body)
	body.set_look_angles(yaw)
	return body

func create_enemies() -> void:
	for cell in [Vector2i(15, 1), Vector2i(1, 9), Vector2i(17, 7)]:
		var drone := QuantumDrone.new()
		drone.name = "QuantumSentinel"
		drone.position = Vector3(cell.x * CELL, 1.3, cell.y * CELL)
		drone.target = player
		generated_root.add_child(drone)
		drone.caught_player.connect(die)
		enemies.append(drone)
	update_drone_paths()

func create_detectors() -> void:
	var walls: Array[Vector2i] = [Vector2i(7, 1), Vector2i(4, 3), Vector2i(10, 4), Vector2i(14, 5), Vector2i(12, 8), Vector2i(17, 10)]
	var paths: Array[Vector2i] = [Vector2i(5, 1), Vector2i(9, 3), Vector2i(3, 5), Vector2i(8, 5), Vector2i(11, 7), Vector2i(5, 9), Vector2i(14, 11)]
	for cell in walls:
		create_detector(cell, true)
	for cell in paths:
		create_detector(cell, false)

func create_detector(cell: Vector2i, in_wall: bool) -> void:
	var detector := world.marker(Vector3(cell.x * CELL, 0, cell.y * CELL), "detector", Design.GOLD, "MEDICIÓN / M")
	detector.set_meta("in_wall", in_wall)
	if in_wall:
		detector.rotation.y = PI / 2.0
	detector_areas.append(detector)

func shoot_ray() -> bool:
	if not game_started or game_over or is_modal_open() or ray_cooldown > 0.0 or not is_instance_valid(player) or not player.enabled:
		return false
	ray_cooldown = SHOT_COOLDOWN
	last_shot_result = player.fire_ray()
	var endpoint: Vector3 = player.camera.global_position - player.camera.global_basis.z * QuantumPlayer.RAY_RANGE
	last_shot_hit = false
	if not last_shot_result.is_empty():
		endpoint = last_shot_result["position"]
		var drone: QuantumDrone = last_shot_result.get("collider") as QuantumDrone
		if drone != null and drone.enabled:
			drone.freeze(FREEZE_SECONDS)
			last_shot_hit = true
	world.spawn_beam(player.get_muzzle_position(), endpoint, last_shot_hit)
	player.animate_shot()
	tactical_hud.shot_flash = 0.16
	tactical_hud.hit_flash = 0.18 if last_shot_hit else 0.0
	soundtrack.play_cue("freeze" if last_shot_hit else "ray")
	return last_shot_hit

func toggle_superposition() -> void:
	if level < 2 or level > 3 or superposition_locked:
		message.text = "Tu estado colapsó. Ya no puedes activar la superposición en este intento."
		return
	if superposition_active and is_wall_at(player.position):
		message.text = "Sal del muro antes de volver al estado clásico."
		return
	superposition_active = not superposition_active
	player.superposed = superposition_active
	world.set_phase(superposition_active)
	phase_overlay.visible = superposition_active
	soundtrack.play_cue("superposition_on" if superposition_active else "superposition_off")
	message.text = "Superposición activa. Puedes atravesar los muros." if superposition_active else "Estado clásico. Los muros vuelven a ser sólidos."
	update_hud()

func _on_detector_entered(body: Node3D, detector: Node3D) -> void:
	if body != player or game_over or level != 3 or not superposition_active:
		return
	superposition_active = false
	superposition_locked = true
	player.superposed = false
	world.set_phase(false)
	phase_overlay.visible = false
	soundtrack.play_cue("collapse")
	if bool(detector.get_meta("in_wall")):
		handle_wall_collapse()
	else:
		message.text = "¡MEDICIÓN! Tu estado colapsó. Debes llegar al portal sin atravesar muros."
	update_hud()

func handle_wall_collapse() -> void:
	deaths_level_3 += 1
	game_over = true
	if deaths_level_3 >= 3:
		start_final_game_over()
	else:
		show_modal("ATRAPADO", "Colapsaste dentro del muro.\nReinicia el nivel.\nIntento %d de 3." % deaths_level_3, "[A] Reiniciar", "restart_level")

func die() -> void:
	if not game_started or game_over or is_modal_open():
		return
	soundtrack.play_cue("caught")
	if level == 1:
		deaths_level_1 += 1
		if deaths_level_1 >= 3:
			start_quantum_transition()
			return
	elif level == 3:
		deaths_level_3 += 1
		if deaths_level_3 >= 3:
			start_final_game_over()
			return
	game_over = true
	_set_gameplay_enabled(false)
	message.text = "Un dron te alcanzó.\n\nReinicia o vuelve al menú."
	restart_button.visible = true
	menu_button.visible = true
	restart_button.grab_focus()
	update_hud()

func start_quantum_transition() -> void:
	transitioning_to_level_2 = true
	game_over = true
	restart_button.visible = false
	menu_button.visible = false
	show_modal("NUEVO ESTADO", "El mundo clásico tiene límites.\n\nActiva la SUPERPOSICIÓN para atravesar muros. Tu rayo de coherencia seguirá inmovilizando drones.", "[A] Continuar al Nivel 2", "to_level_2")

func start_final_game_over() -> void:
	game_over = true
	restart_button.visible = false
	menu_button.visible = false
	show_modal("FIN DEL JUEGO", "Llegaste al tercer intento del nivel de medición.\n\nLa superposición colapsa al ser medida. Vuelve al laboratorio e inténtalo de nuevo.", "[A] Menú Principal", "to_menu")

func _on_exit_entered(body: Node3D) -> void:
	if body != player or game_over or is_modal_open():
		return
	soundtrack.play_cue("confirm")
	if level == 1:
		deaths_level_1 = 0
		build_level(2)
	elif level == 2:
		game_over = true
		show_modal("MEDICIÓN CUÁNTICA", "Ya puedes atravesar muros.\n\nAhora evita los escáneres M: si te miden, tu estado colapsará.", "[A] Continuar al Nivel 3", "to_level_3")
	elif level == 3:
		game_over = true
		show_modal("ENTRELAZAMIENTO", "Dos qubits compartirán un estado.\n\nA cambia la perspectiva entre Q1 y Q2. Acerca ambos a E y entrega los colores que pide el receptor.", "[A] Continuar al Nivel 4", "to_level_4")

func create_entanglement_level() -> void:
	world.build_entanglement()
	active_qubit = 1
	entangled = false
	entanglement_round = 0
	requested_color_name = ""
	current_entangled_color_name = ""
	current_entangled_color_value = Color.WHITE
	delivery_pending = false
	# Presenta la cámara hacia E sin un cristal de color pegado a la mira.
	var q1_start := Vector3(-8, 0.85, -2.4)
	qbit1 = create_player(q1_start, -PI / 2.0 - atan2(2.4, 6.1))
	qbit2 = create_player(Vector3(8, 0.85, 0), PI / 2.0)
	qbit1.movement_bounds = Rect2(-10.0, -7.0, 8.85, 14.0)
	qbit2.movement_bounds = Rect2(1.15, -7.0, 8.85, 14.0)
	qbit1_visual = world.marker(q1_start - Vector3(0, 0.85, 0), "qubit", Design.CYAN, "QUBIT 1")
	qbit2_visual = world.marker(Vector3(8, 0, 0), "qubit", Design.VIOLET, "QUBIT 2")
	q1_station = world.marker(Vector3(-1.9, 0, 0), "pad", Design.CYAN, "E / Q1")
	q2_station = world.marker(Vector3(1.9, 0, 0), "pad", Design.VIOLET, "E / Q2")
	delivery_area = world.marker(Vector3(7, 0, 4.5), "pad", Design.GOLD, "RECEPTOR / R")
	delivery_visual = delivery_area
	create_color_pickup(Vector3(-7, 0, -4.6), "rojo", Color("#ff667c"))
	create_color_pickup(Vector3(-7, 0, 0), "azul", Color("#51a8ff"))
	create_color_pickup(Vector3(-7, 0, 4.6), "verde", Color("#6fffc1"))
	player = qbit1
	message.text = "A cambia de qubit.\n\nAcerca Q1 y Q2 a sus estaciones E para enlazarlos."
	update_entanglement_visuals()

func create_color_pickup(at: Vector3, color_name: String, value: Color) -> void:
	var pickup := world.marker(at, "pickup", value, color_name.to_upper())
	pickup.set_meta("color_name", color_name)
	pickup.set_meta("color_value", value)
	color_pickups.append(pickup)

func _activate_qubit(which: int) -> void:
	qbit1.set_enabled(false)
	qbit2.set_enabled(false)
	active_qubit = which
	player = qbit1 if which == 1 else qbit2
	player.set_enabled(game_started and not game_over and not is_modal_open())
	update_entanglement_visuals()

func handle_entanglement_space() -> void:
	soundtrack.play_cue("switch")
	_activate_qubit(2 if active_qubit == 1 else 1)
	message.text = "Controlas Q%d.\n\n%s" % [active_qubit, "Llega a tu estación E." if not entangled else ("Toma el color pedido." if active_qubit == 1 else "Entrega el color en el receptor.")]
	update_hud()

func check_entanglement_level() -> void:
	if game_over or is_modal_open() or not is_instance_valid(qbit1) or not is_instance_valid(qbit2):
		return
	if not entangled:
		if flat_distance(qbit1.position, q1_station.position) < 1.0 and flat_distance(qbit2.position, q2_station.position) < 1.0:
			entangled = true
			start_next_entanglement_round()
			_activate_qubit(1)
			soundtrack.play_cue("entangled")
			message.text = "Enlace establecido.\n\nQ1 toma %s y Q2 lo entrega al receptor." % requested_color_name.to_upper()
		return
	if delivery_pending and active_qubit == 2 and flat_distance(qbit2.position, delivery_area.position) < 1.15:
		deliver_entangled_color()
		return
	if not delivery_pending and active_qubit == 1:
		for pickup in color_pickups:
			if flat_distance(qbit1.position, pickup.position) < 0.95:
				var picked: String = str(pickup.get_meta("color_name"))
				if picked != current_entangled_color_name:
					apply_entangled_color(picked, pickup.get_meta("color_value") as Color)
				return

func apply_entangled_color(color_name: String, color_value: Color) -> void:
	if not entangled or delivery_pending:
		return
	current_entangled_color_name = color_name
	current_entangled_color_value = color_value
	world.update_marker_color(qbit1_visual, color_value)
	world.update_marker_color(qbit2_visual, color_value)
	if color_name == requested_color_name:
		delivery_pending = true
		_activate_qubit(2)
		soundtrack.play_cue("confirm")
		message.text = "Ambos qubits son %s.\n\nLleva Q2 al receptor para entregar." % color_name.to_upper()
	else:
		message.text = "El receptor pide %s.\n\nQ1 debe tomar ese color." % requested_color_name.to_upper()
	update_hud()

func deliver_entangled_color() -> void:
	if not delivery_pending or current_entangled_color_name != requested_color_name:
		return
	entanglement_round += 1
	delivery_pending = false
	soundtrack.play_cue("victory" if entanglement_round >= 3 else "delivery")
	if entanglement_round >= 3:
		game_over = true
		show_modal("MISIÓN CUMPLIDA", "Has escapado del mundo clásico.\n\nDominaste la superposición, la medición y el entrelazamiento.", "[A] Menú Principal", "to_menu")
	else:
		start_next_entanglement_round()
		qbit2.position = Vector3(8, 0.85, 0)
		qbit2.set_look_angles(PI / 2.0)
		_activate_qubit(1)
		message.text = "Entrega completa.\n\nAhora Q1 toma %s." % requested_color_name.to_upper()
	update_hud()

func start_next_entanglement_round() -> void:
	var names: Array[String] = ["rojo", "azul", "verde"]
	var values: Array[Color] = [Color("#ff667c"), Color("#51a8ff"), Color("#6fffc1")]
	requested_color_name = names[entanglement_round % 3]
	requested_color_value = values[entanglement_round % 3]
	world.update_marker_color(delivery_visual, requested_color_value, "RECEPTOR / " + requested_color_name.to_upper())

func update_entanglement_visuals() -> void:
	if not is_instance_valid(qbit1_visual):
		return
	qbit1_visual.position = qbit1.position - Vector3(0, 0.85, 0)
	qbit2_visual.position = qbit2.position - Vector3(0, 0.85, 0)
	qbit1_visual.visible = active_qubit != 1
	qbit2_visual.visible = active_qubit != 2
	if entangled:
		world.draw_link(qbit1.position + Vector3(0, 0.35, 0), qbit2.position + Vector3(0, 0.35, 0), current_entangled_color_value if not current_entangled_color_name.is_empty() else Design.CYAN)

func flat_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()

func cell_at(at: Vector3) -> Vector2i:
	return Vector2i(roundi(at.x / CELL), roundi(at.z / CELL))

func is_wall_at(at: Vector3) -> bool:
	return not is_walkable(cell_at(at))

func is_walkable(cell: Vector2i) -> bool:
	return cell.y >= 0 and cell.y < maze.size() and cell.x >= 0 and cell.x < maze[cell.y].length() and maze[cell.y].substr(cell.x, 1) != "#"

func nearest_walkable(at: Vector2i) -> Vector2i:
	if is_walkable(at):
		return at
	var closest := Vector2i(1, 1)
	var distance: int = 1000000
	for z in range(maze.size()):
		for x in range(maze[z].length()):
			var candidate := Vector2i(x, z)
			var steps: int = absi(at.x - x) + absi(at.y - z)
			if is_walkable(candidate) and steps < distance:
				distance = steps
				closest = candidate
	return closest

func find_path(start: Vector2i, destination: Vector2i) -> Array[Vector3]:
	var result: Array[Vector3] = []
	start = nearest_walkable(start)
	destination = nearest_walkable(destination)
	if start == destination:
		return result
	var frontier: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var cursor: int = 0
	while cursor < frontier.size():
		var current: Vector2i = frontier[cursor]
		cursor += 1
		if current == destination:
			break
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + offset
			if is_walkable(next) and not previous.has(next):
				previous[next] = current
				frontier.append(next)
	if not previous.has(destination):
		return result
	var current: Vector2i = destination
	while current != start:
		result.push_front(Vector3(current.x * CELL, 1.3, current.y * CELL))
		current = previous[current]
	return result

func update_drone_paths() -> void:
	if not is_instance_valid(player):
		return
	for drone in enemies:
		if drone.frozen_time <= 0.0:
			drone.set_path(find_path(cell_at(drone.position), cell_at(player.position)))

func update_hud() -> void:
	var names: Array[String] = ["LABERINTO CLÁSICO", "SUPERPOSICIÓN", "MEDICIÓN Y COLAPSO", "ENTRELAZAMIENTO"]
	level_title_label.text = "PROTOCOLO %02d   /   %s" % [level, names[level - 1]]
	phase_label.text = "%02d / 04" % level
	if level == 4:
		hud_label.text = "Q%d  |  %s  |  ENTREGAS %d/3" % [active_qubit, "RECEPTOR: " + requested_color_name.to_upper() if entangled else "ENLACE PENDIENTE", entanglement_round]
		field_guide_label.text = "A · QUBITS\nCambia entre\nQ1 y Q2.\n\nQ1 toma el\ncolor pedido.\nQ2 lo entrega.\n\n%s" % (requested_color_name.to_upper() if entangled else "Ambos a E.")
	else:
		var state: String = "COLAPSADO" if superposition_locked else ("SUPERPOSICIÓN ACTIVA" if superposition_active else "ESTADO CLÁSICO")
		hud_label.text = "%s  |  DRONES %d" % [state, enemies.size()]
		field_guide_label.text = "RT · RAYO\nDetiene drones\n3,5 s · 28 m\n\n%s" % ("M · MEDICIÓN\nEvita escáneres\nal atravesar\nmuros." if level == 3 else ("A · ESTADO\nEl halo violeta\npermite cruzar\nlos muros." if level == 2 else "PORTAL VERDE\nTu salida del\nlaboratorio."))
		if level == 1 or level == 3:
			field_guide_label.text += "\n\nINTENTOS %d/3" % (deaths_level_1 if level == 1 else deaths_level_3)
	if game_over:
		instructions_label.text = "Stick / Cruceta: Elegir    A: Aceptar    X: Reiniciar    B / Start: Menú"
	elif level == 4:
		instructions_label.text = "Stick izq.: Mover    Stick der.: Mirar    RT: Rayo    A: Cambiar qubit    B / Start: Menú"
	elif level >= 2:
		instructions_label.text = "Stick izq.: Mover    Stick der.: Mirar    RT: Rayo    A: Superposición    B / Start: Menú"
	else:
		instructions_label.text = "Stick izq.: Mover    Stick der.: Mirar    RT: Rayo    B / Start: Menú"
	weapon_label.text = "RAYO DE COHERENCIA · LISTO" if ray_cooldown <= 0.0 else "RECARGA DEL EMISOR · %.1f s" % ray_cooldown
	weapon_label.add_theme_color_override("font_color", Design.CYAN if ray_cooldown <= 0.0 else Design.GOLD)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
