extends Node2D

const SCREEN_SIZE: Vector2 = Vector2(1280, 720)
const CELL: int = 40
const OFFSET: Vector2 = Vector2(240, 100)
const PLAYER_SPEED: float = 170.0
const ENEMY_SPEED: float = 95.0

var level: int = 1
var game_started: bool = false
var game_over: bool = false
var superposition_active: bool = false
var deaths_level_1: int = 0
var deaths_level_3: int = 0
var transitioning_to_level_2: bool = false
var superposition_locked: bool = false

var player: CharacterBody2D
var player_shape: CollisionShape2D
var exit_area: Area2D
var walls_node: StaticBody2D
var hud: CanvasLayer
var menu_layer: CanvasLayer
var title_label: Label
var hud_label: Label
var level_title_label: Label
var instructions_label: Label
var message: Label
var start_button: Button
var quit_button: Button
var restart_button: Button
var menu_button: Button
var modal_layer: CanvasLayer
var modal_title: Label
var modal_body: Label
var modal_action: Label
var modal_mode: String = ""
var enemies: Array[CharacterBody2D] = []
var wall_shapes: Array[CollisionShape2D] = []
var detector_areas: Array[Area2D] = []
var qbit1: CharacterBody2D
var qbit2: CharacterBody2D
var qbit1_visual: ColorRect
var qbit2_visual: ColorRect
var active_qubit: int = 1
var entangled: bool = false
var entanglement_round: int = 0
var requested_color_name: String = ""
var requested_color_value: Color = Color.WHITE
var delivery_pending: bool = false
var current_entangled_color_name: String = ""
var current_entangled_color_value: Color = Color.WHITE
var color_pickups: Array[Area2D] = []
var q1_station: Area2D
var q2_station: Area2D
var delivery_area: Area2D
var delivery_visual: ColorRect
var delivery_label: Label
var entanglement_status_label: Label
var generated_root: Node2D

var maze: Array[String] = [
	"####################",
	"#P     #        #  #",
	"# ### ### ####### ##",
	"#   #     #        #",
	"### ##### # ###### #",
	"#     #   #   #    #",
	"# ### # ##### # ####",
	"# #   #     # #    #",
	"# # ####### # #### #",
	"# #       # #    # #",
	"# ####### # #### # #",
	"#       #        #E#",
	"####################"
]

func _ready() -> void:
	create_menu()
	create_hud()
	create_modal()
	show_menu()

func _physics_process(delta: float) -> void:
	if not game_started or game_over or is_modal_open():
		return
	if level == 4:
		move_entanglement_qubits(delta)
		check_entanglement_level()
		update_hud()
		return
	update_superposition(delta)
	move_player(delta)
	move_enemies(delta)
	check_enemy_collision()
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if is_modal_open():
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				accept_modal()
			elif event.keycode == KEY_ESCAPE:
				show_menu()
			return

		if game_started and level == 4 and event.keycode == KEY_SPACE:
			handle_entanglement_space()
			return

		if event.keycode == KEY_F11:
			var mode := DisplayServer.window_get_mode()
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

		elif event.keycode == KEY_ESCAPE:
			if game_started:
				show_menu()
			else:
				get_tree().quit()

		elif not game_started:
			# Truco secreto para presentacion: desde el menu principal,
			# presiona 1, 2, 3 o 4 para saltar directo a ese nivel.
			if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
				start_secret_level(1)
			elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
				start_secret_level(2)
			elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
				start_secret_level(3)
			elif event.keycode == KEY_4 or event.keycode == KEY_KP_4:
				start_secret_level(4)
			elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
				quit_button.grab_focus()
			elif event.keycode == KEY_UP or event.keycode == KEY_W:
				start_button.grab_focus()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				if quit_button.has_focus():
					_on_quit_pressed()
				else:
					_on_start_pressed()

		elif event.keycode == KEY_R:
			if game_over and not transitioning_to_level_2:
				_on_restart_pressed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if game_over and not transitioning_to_level_2:
				_on_restart_pressed()
		elif event.keycode == KEY_M:
			show_menu()

func create_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.10)
	bg.size = SCREEN_SIZE
	menu_layer.add_child(bg)

	title_label = Label.new()
	title_label.text = "QUANTUM ESCAPE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 54)
	title_label.position = Vector2(0, 120)
	title_label.size = Vector2(SCREEN_SIZE.x, 80)
	menu_layer.add_child(title_label)

	var subtitle: Label = Label.new()
	subtitle.text = "Un laberinto clasico primero. Una propiedad cuantica despues."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.position = Vector2(160, 210)
	subtitle.size = Vector2(960, 40)
	menu_layer.add_child(subtitle)

	start_button = Button.new()
	start_button.text = "Iniciar juego"
	start_button.position = Vector2(520, 310)
	start_button.size = Vector2(240, 58)
	start_button.pressed.connect(_on_start_pressed)
	menu_layer.add_child(start_button)
	start_button.focus_mode = Control.FOCUS_ALL

	quit_button = Button.new()
	quit_button.text = "Salir"
	quit_button.position = Vector2(520, 390)
	quit_button.size = Vector2(240, 58)
	quit_button.pressed.connect(_on_quit_pressed)
	menu_layer.add_child(quit_button)
	quit_button.focus_mode = Control.FOCUS_ALL

	var controls: Label = Label.new()
	controls.text = "WASD o Flechas: Elegir    ENTER: Aceptar    ESC: Salir"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 18)
	controls.position = Vector2(0, 635)
	controls.size = Vector2(SCREEN_SIZE.x, 40)
	menu_layer.add_child(controls)

	start_button.grab_focus()

func create_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	level_title_label = Label.new()
	level_title_label.position = Vector2(0, 8)
	level_title_label.size = Vector2(SCREEN_SIZE.x, 36)
	level_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_title_label.add_theme_font_size_override("font_size", 25)
	hud.add_child(level_title_label)

	hud_label = Label.new()
	hud_label.position = Vector2(0, 44)
	hud_label.size = Vector2(SCREEN_SIZE.x, 30)
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(hud_label)

	message = Label.new()
	message.position = Vector2(0, 74)
	message.size = Vector2(SCREEN_SIZE.x, 86)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 20)
	hud.add_child(message)

	instructions_label = Label.new()
	instructions_label.position = Vector2(0, 670)
	instructions_label.size = Vector2(SCREEN_SIZE.x, 36)
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(instructions_label)

	restart_button = Button.new()
	restart_button.text = "Reiniciar"
	restart_button.position = Vector2(490, 585)
	restart_button.size = Vector2(140, 45)
	restart_button.pressed.connect(_on_restart_pressed)
	hud.add_child(restart_button)
	restart_button.focus_mode = Control.FOCUS_ALL

	menu_button = Button.new()
	menu_button.text = "Menu"
	menu_button.position = Vector2(650, 585)
	menu_button.size = Vector2(140, 45)
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
	shade.color = Color(0, 0, 0, 0.68)
	shade.size = SCREEN_SIZE
	modal_layer.add_child(shade)

	var panel: Panel = Panel.new()
	panel.name = "ModalPanel"
	panel.position = Vector2(315, 145)
	panel.size = Vector2(650, 430)
	modal_layer.add_child(panel)

	modal_title = Label.new()
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.add_theme_font_size_override("font_size", 34)
	modal_title.position = Vector2(25, 28)
	modal_title.size = Vector2(600, 52)
	panel.add_child(modal_title)

	var line: ColorRect = ColorRect.new()
	line.color = Color(0.2, 0.8, 1.0, 0.9)
	line.position = Vector2(45, 92)
	line.size = Vector2(560, 3)
	panel.add_child(line)

	modal_body = Label.new()
	modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_theme_font_size_override("font_size", 24)
	modal_body.position = Vector2(55, 120)
	modal_body.size = Vector2(540, 210)
	panel.add_child(modal_body)

	modal_action = Label.new()
	modal_action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_action.add_theme_font_size_override("font_size", 22)
	modal_action.position = Vector2(25, 350)
	modal_action.size = Vector2(600, 45)
	panel.add_child(modal_action)

	modal_layer.visible = false

func is_modal_open() -> bool:
	return modal_layer != null and modal_layer.visible

func show_modal(title: String, body: String, action: String, mode: String) -> void:
	modal_mode = mode
	modal_title.text = title
	modal_body.text = body
	modal_action.text = action
	modal_layer.visible = true

func hide_modal() -> void:
	modal_layer.visible = false
	modal_mode = ""

func accept_modal() -> void:
	var mode: String = modal_mode
	hide_modal()
	if mode == "to_level_2":
		build_level(2)
	elif mode == "to_level_3":
		deaths_level_3 = 0
		build_level(3)
		message.text = "Nivel 3: evita las compuertas M en paredes y caminos. Si te miden, colapsas."
	elif mode == "to_level_4":
		build_level(4)
	elif mode == "to_menu":
		show_menu()
	elif mode == "restart_level":
		build_level(level)


func show_menu() -> void:
	if modal_layer != null:
		hide_modal()
	game_started = false
	game_over = false
	transitioning_to_level_2 = false
	deaths_level_1 = 0
	deaths_level_3 = 0
	clear_old_level()
	menu_layer.visible = true
	hud.visible = false
	if start_button != null:
		start_button.grab_focus()


func start_secret_level(target_level: int) -> void:
	menu_layer.visible = false
	hud.visible = true
	game_started = true
	game_over = false
	deaths_level_1 = 0
	deaths_level_3 = 0
	transitioning_to_level_2 = false
	build_level(target_level)

func _on_start_pressed() -> void:
	menu_layer.visible = false
	hud.visible = true
	game_started = true
	deaths_level_1 = 0
	deaths_level_3 = 0
	transitioning_to_level_2 = false
	build_level(1)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_restart_pressed() -> void:
	transitioning_to_level_2 = false
	build_level(level)

func _on_menu_pressed() -> void:
	show_menu()

func build_level(new_level: int) -> void:
	if modal_layer != null:
		hide_modal()
	level = new_level
	game_over = false
	transitioning_to_level_2 = false
	superposition_active = false
	superposition_locked = false
	message.text = ""
	restart_button.visible = false
	menu_button.visible = false
	clear_old_level()
	if level == 4:
		create_entanglement_level()
		update_hud()
		return
	create_background()
	create_walls_and_positions()
	if level == 3:
		create_detectors()
	create_enemies()
	if level == 2:
		message.text = "Nivel 2: presiona ESPACIO para activar/desactivar superposicion"
	elif level == 3:
		message.text = "Nivel 3: evita las compuertas M en paredes y caminos. Si te miden, colapsas."
	update_hud()

func clear_old_level() -> void:
	# Limpieza fuerte: todo el nivel vive dentro de un solo contenedor.
	# Al reiniciar, morir o cambiar de nivel, se elimina completo y luego
	# se crean exactamente los mismos 3 enemigos.
	if generated_root != null and is_instance_valid(generated_root):
		generated_root.free()

	for child in get_children():
		if child.name.begins_with("Generated"):
			child.free()

	generated_root = Node2D.new()
	generated_root.name = "GeneratedLevel"
	add_child(generated_root)
	enemies.clear()
	wall_shapes.clear()
	detector_areas.clear()
	color_pickups.clear()
	player = null
	exit_area = null
	walls_node = null
	qbit1 = null
	qbit2 = null
	qbit1_visual = null
	qbit2_visual = null
	q1_station = null
	q2_station = null
	delivery_area = null
	delivery_visual = null
	delivery_label = null
	entanglement_status_label = null

func create_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.name = "GeneratedBackground"
	bg.color = Color(0.05, 0.07, 0.12)
	bg.size = SCREEN_SIZE
	generated_root.add_child(bg)
	generated_root.move_child(bg, 0)

func create_walls_and_positions() -> void:
	walls_node = StaticBody2D.new()
	walls_node.name = "GeneratedWalls"
	generated_root.add_child(walls_node)

	for y in maze.size():
		for x in maze[y].length():
			var c: String = maze[y].substr(x, 1)
			var pos: Vector2 = OFFSET + Vector2(x * CELL + CELL / 2, y * CELL + CELL / 2)
			if c == "#":
				create_wall(pos)
			elif c == "P":
				create_player(pos)
			elif c == "E":
				create_exit(pos)

func create_wall(pos: Vector2) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.name = "GeneratedWallVisual"
	rect.color = Color(0.19, 0.35, 0.62)
	rect.position = pos - Vector2(CELL / 2, CELL / 2)
	rect.size = Vector2(CELL, CELL)
	generated_root.add_child(rect)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(CELL, CELL)
	shape.shape = box
	shape.position = pos
	walls_node.add_child(shape)
	wall_shapes.append(shape)

func create_player(pos: Vector2) -> void:
	player = CharacterBody2D.new()
	player.name = "GeneratedPlayer"
	player.position = pos
	generated_root.add_child(player)

	player_shape = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 13
	player_shape.shape = circle
	player.add_child(player_shape)

	var sprite: ColorRect = ColorRect.new()
	sprite.name = "PlayerVisual"
	sprite.color = Color(0.2, 0.95, 1.0)
	sprite.size = Vector2(26, 26)
	sprite.position = Vector2(-13, -13)
	player.add_child(sprite)

func create_exit(pos: Vector2) -> void:
	exit_area = Area2D.new()
	exit_area.name = "GeneratedExit"
	exit_area.position = pos
	generated_root.add_child(exit_area)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(28, 28)
	shape.shape = box
	exit_area.add_child(shape)

	var visual: ColorRect = ColorRect.new()
	visual.color = Color(0.45, 1.0, 0.35)
	visual.size = Vector2(28, 28)
	visual.position = Vector2(-14, -14)
	exit_area.add_child(visual)
	exit_area.body_entered.connect(_on_exit_entered)

func create_enemies() -> void:
	enemies.clear()
	var enemy_positions: Array[Vector2] = [Vector2(15, 1), Vector2(1, 9), Vector2(17, 7)]
	for cell in enemy_positions:
		var e: CharacterBody2D = CharacterBody2D.new()
		e.name = "GeneratedEnemy"
		e.position = OFFSET + Vector2(cell.x * CELL + CELL / 2, cell.y * CELL + CELL / 2)
		generated_root.add_child(e)

		var shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 14
		shape.shape = circle
		e.add_child(shape)

		var visual: ColorRect = ColorRect.new()
		visual.color = Color(1.0, 0.18, 0.22)
		visual.size = Vector2(28, 28)
		visual.position = Vector2(-14, -14)
		e.add_child(visual)
		enemies.append(e)

func create_detectors() -> void:
	detector_areas.clear()
	# Nivel 3: hay compuertas de medicion en paredes y tambien en el camino.
	# Las de pared castigan cruzar muros en superposicion; las del camino
	# obligan al jugador a decidir por donde avanzar para evitar colapsar.
	var wall_detector_positions: Array[Vector2] = [
		Vector2(7, 1),
		Vector2(4, 3),
		Vector2(10, 4),
		Vector2(14, 5),
		Vector2(12, 8),
		Vector2(17, 10)
	]
	var path_detector_positions: Array[Vector2] = [
		Vector2(5, 1),
		Vector2(9, 3),
		Vector2(3, 5),
		Vector2(8, 5),
		Vector2(11, 7),
		Vector2(5, 9),
		Vector2(14, 11)
	]

	for cell in wall_detector_positions:
		create_detector(cell, true)
	for cell in path_detector_positions:
		create_detector(cell, false)

func create_detector(cell: Vector2, in_wall: bool) -> void:
	var detector: Area2D = Area2D.new()
	detector.name = "GeneratedWallDetector" if in_wall else "GeneratedPathDetector"
	detector.position = OFFSET + Vector2(cell.x * CELL + CELL / 2, cell.y * CELL + CELL / 2)
	detector.set_meta("in_wall", in_wall)
	generated_root.add_child(detector)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(42, 42)
	shape.shape = box
	detector.add_child(shape)

	var visual: ColorRect = ColorRect.new()
	visual.name = "DetectorVisual"
	visual.color = Color(1.0, 0.86, 0.15, 0.72)
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	detector.add_child(visual)

	var inner: ColorRect = ColorRect.new()
	inner.color = Color(0.19, 0.35, 0.62, 0.95) if in_wall else Color(0.05, 0.07, 0.12, 0.95)
	inner.size = Vector2(26, 26)
	inner.position = Vector2(-13, -13)
	detector.add_child(inner)

	var label: Label = Label.new()
	label.text = "M"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	label.position = Vector2(-20, -20)
	label.size = Vector2(40, 40)
	detector.add_child(label)

	detector.body_entered.connect(_on_detector_entered.bind(detector))
	detector_areas.append(detector)

func move_player(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	player.velocity = input_vector.normalized() * PLAYER_SPEED

	if superposition_active:
		player.position += player.velocity * delta
	else:
		player.move_and_slide()

func move_enemies(_delta: float) -> void:
	for e in enemies:
		var direction: Vector2 = (player.global_position - e.global_position).normalized()
		e.velocity = direction * ENEMY_SPEED
		e.move_and_slide()

func update_superposition(_delta: float) -> void:
	if level >= 2 and Input.is_action_just_pressed("superposition"):
		if level == 3 and superposition_locked:
			message.text = "Tu estado ya colapso por una medicion. No puedes volver a activar la superposicion en este intento."
			return

		superposition_active = not superposition_active
		set_player_superposition_visual(superposition_active)
		if superposition_active:
			if level == 3:
				message.text = "Superposicion activa. Cuidado: si una compuerta M te mide, colapsas definitivamente."
			else:
				message.text = "Superposicion activa: puedes atravesar paredes sin limite de tiempo"
		else:
			message.text = "Superposicion desactivada"

func set_player_superposition_visual(active: bool) -> void:
	# Importante: no apagamos las paredes.
	# El jugador atraviesa porque en move_player se mueve por posicion,
	# pero los enemigos siguen usando move_and_slide y chocan con el laberinto.
	if player != null:
		var player_visual: ColorRect = player.get_node("PlayerVisual") as ColorRect
		if player_visual != null:
			if active:
				player_visual.modulate = Color(1, 1, 1, 0.35)
			else:
				player_visual.modulate = Color(1, 1, 1, 1)

func check_enemy_collision() -> void:
	for e in enemies:
		if e.global_position.distance_to(player.global_position) < 27.0:
			die()
			return

func die() -> void:
	if game_over or transitioning_to_level_2:
		return

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
	if level == 1:
		message.text = "Te atraparon. Moriste. Intento %d de 3." % deaths_level_1
	elif level == 3:
		message.text = "Te atraparon. Intento %d de 3 en el nivel de medicion." % deaths_level_3
	else:
		message.text = "Te atraparon. Moriste."
	restart_button.visible = true
	menu_button.visible = true
	restart_button.grab_focus()

func start_quantum_transition() -> void:
	transitioning_to_level_2 = true
	game_over = true
	restart_button.visible = false
	menu_button.visible = false
	message.text = ""
	show_modal(
		"¡INTERESANTE!",
		"¿Ves? No es tan facil encontrar la salida cuando estas limitado a una unica posicion.\n\nAhora probemos una propiedad cuantica: la SUPERPOSICION.",
		"[ENTER] Continuar al Nivel 2",
		"to_level_2"
	)

func start_final_game_over() -> void:
	game_over = true
	restart_button.visible = false
	menu_button.visible = false
	message.text = ""
	show_modal(
		"FIN DEL JUEGO",
		"Llegaste al tercer intento del nivel de medicion.\n\nLa superposicion es poderosa, pero al ser medida colapsa y ya no puede usarse en ese intento.",
		"[ENTER] Volver al Menu Principal",
		"to_menu"
	)

func _on_exit_entered(body: Node2D) -> void:
	if body != player or game_over:
		return
	if level == 1:
		deaths_level_1 = 0
		build_level(2)
		message.text = "Nivel 2: presiona ESPACIO para activar/desactivar superposicion"
	elif level == 2:
		game_over = true
		restart_button.visible = false
		menu_button.visible = false
		message.text = ""
		show_modal(
			"NUEVO CONCEPTO",
			"Ya usaste la superposicion para atravesar paredes.\n\nAhora veras que al medir un sistema cuantico, su superposicion puede colapsar.",
			"[ENTER] Continuar al Nivel 3",
			"to_level_3"
		)
	elif level == 3:
		game_over = true
		restart_button.visible = false
		menu_button.visible = false
		message.text = ""
		show_modal(
			"NUEVO CONCEPTO",
			"Completaste el nivel de medicion y colapso.\n\nAhora veremos el ENTRELAZAMIENTO: dos qubits compartiran un mismo estado, de modo que cambiar uno afectara al otro.",
			"[ENTER] Continuar al Nivel 4",
			"to_level_4"
		)

func _on_detector_entered(body: Node2D, detector: Area2D) -> void:
	if body != player or game_over or level != 3:
		return

	# La medicion solo castiga si el jugador todavia estaba en superposicion.
	# Si ya colapso antes, tocar otra compuerta M no debe reiniciar el nivel.
	if not superposition_active:
		return

	var in_wall: bool = detector.get_meta("in_wall") as bool
	superposition_active = false
	superposition_locked = true
	set_player_superposition_visual(false)

	if in_wall:
		handle_wall_collapse()
	else:
		message.text = "¡MEDICION! Colapsaste. Ya no puedes activar superposicion en este intento."

func handle_wall_collapse() -> void:
	deaths_level_3 += 1
	if deaths_level_3 >= 3:
		start_final_game_over()
		return

	game_over = true
	restart_button.visible = false
	menu_button.visible = false
	message.text = ""
	show_modal(
		"ATRAPADO",
		"Colapsaste dentro del muro.\nReinicia el nivel.\nIntento %d de 3." % deaths_level_3,
		"[ENTER] Reiniciar",
		"restart_level"
	)

func create_entanglement_level() -> void:
	create_background()
	enemies.clear()
	active_qubit = 1
	entangled = false
	entanglement_round = 0
	requested_color_name = ""
	requested_color_value = Color.WHITE
	delivery_pending = false
	current_entangled_color_name = ""
	current_entangled_color_value = Color.WHITE
	message.text = "Nivel 4: cambia de qubit con ESPACIO. Acerca ambos a las estaciones E del centro."

	# Marco exterior
	create_entanglement_wall(Vector2(640, 90), Vector2(880, 24))
	create_entanglement_wall(Vector2(640, 630), Vector2(880, 24))
	create_entanglement_wall(Vector2(200, 360), Vector2(24, 540))
	create_entanglement_wall(Vector2(1080, 360), Vector2(24, 540))

	# Division central: separa los dos espacios.
	create_entanglement_wall(Vector2(640, 245), Vector2(24, 250))
	create_entanglement_wall(Vector2(640, 475), Vector2(24, 250))


	q1_station = create_entanglement_pad(Vector2(585, 360), Color(0.2, 0.8, 1.0, 0.65), "E")
	q2_station = create_entanglement_pad(Vector2(695, 360), Color(0.7, 0.3, 1.0, 0.65), "E")

	qbit1 = create_qubit(Vector2(320, 360), Color(0.2, 0.95, 1.0), "1")
	qbit2 = create_qubit(Vector2(960, 360), Color(0.7, 0.3, 1.0), "2")

	delivery_area = create_entanglement_pad(Vector2(960, 510), Color(1.0, 0.9, 0.25, 0.55), "R")
	delivery_visual = delivery_area.get_node("PadVisual") as ColorRect
	delivery_label = delivery_area.get_node("PadLabel") as Label
	create_entanglement_label("Receptor", Vector2(900, 555), 18)

	create_color_pickup(Vector2(330, 220), "rojo", Color(1.0, 0.16, 0.16))
	create_color_pickup(Vector2(330, 360), "azul", Color(0.2, 0.45, 1.0))
	create_color_pickup(Vector2(330, 500), "verde", Color(0.25, 1.0, 0.35))

	entanglement_status_label = null
	update_entanglement_visuals()

func create_entanglement_wall(center: Vector2, size: Vector2) -> void:
	var wall: ColorRect = ColorRect.new()
	wall.name = "GeneratedEntanglementWall"
	wall.color = Color(0.19, 0.35, 0.62)
	wall.position = center - size / 2
	wall.size = size
	generated_root.add_child(wall)

func create_entanglement_label(text: String, pos: Vector2, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.position = pos
	label.size = Vector2(260, 32)
	generated_root.add_child(label)
	return label

func create_entanglement_pad(pos: Vector2, color: Color, label_text: String) -> Area2D:
	var area: Area2D = Area2D.new()
	area.position = pos
	generated_root.add_child(area)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(58, 58)
	shape.shape = box
	area.add_child(shape)

	var visual: ColorRect = ColorRect.new()
	visual.name = "PadVisual"
	visual.color = color
	visual.size = Vector2(58, 58)
	visual.position = Vector2(-29, -29)
	area.add_child(visual)

	var label: Label = Label.new()
	label.name = "PadLabel"
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.position = Vector2(-29, -29)
	label.size = Vector2(58, 58)
	area.add_child(label)
	return area

func create_qubit(pos: Vector2, color: Color, label_text: String) -> CharacterBody2D:
	var q: CharacterBody2D = CharacterBody2D.new()
	q.position = pos
	generated_root.add_child(q)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 18
	shape.shape = circle
	q.add_child(shape)

	var visual: ColorRect = ColorRect.new()
	visual.name = "QubitVisual"
	visual.color = color
	visual.size = Vector2(36, 36)
	visual.position = Vector2(-18, -18)
	q.add_child(visual)

	var label: Label = Label.new()
	label.name = "PadLabel"
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.position = Vector2(-18, -18)
	label.size = Vector2(36, 36)
	q.add_child(label)

	if label_text == "1":
		qbit1_visual = visual
	else:
		qbit2_visual = visual
	return q

func create_color_pickup(pos: Vector2, color_name: String, color_value: Color) -> void:
	var area: Area2D = Area2D.new()
	area.position = pos
	area.set_meta("color_name", color_name)
	area.set_meta("color_value", color_value)
	generated_root.add_child(area)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(54, 54)
	shape.shape = box
	area.add_child(shape)

	var visual: ColorRect = ColorRect.new()
	visual.name = "PadVisual"
	visual.color = color_value
	visual.size = Vector2(54, 54)
	visual.position = Vector2(-27, -27)
	area.add_child(visual)

	var label: Label = Label.new()
	label.text = color_name.substr(0, 1).to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.position = Vector2(-27, -27)
	label.size = Vector2(54, 54)
	area.add_child(label)
	color_pickups.append(area)

func handle_entanglement_space() -> void:
	active_qubit = 2 if active_qubit == 1 else 1
	if entangled:
		if delivery_pending and active_qubit == 2:
			message.text = "Ahora controla el Qubit 2 y llevalo al receptor para entregar %s." % current_entangled_color_name.to_upper()
		elif active_qubit == 1:
			message.text = "Controlas el Qubit 1. Toma el color que pide el receptor."
		else:
			message.text = "Controlas el Qubit 2. Cuando Qubit 1 tome un color, ven al receptor a entregarlo."
	else:
		message.text = "Ahora controlas el Qubit %d. Acercalo a su estacion E." % active_qubit
	update_entanglement_visuals()

func move_entanglement_qubits(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var movement: Vector2 = input_vector.normalized() * PLAYER_SPEED * delta
	if movement == Vector2.ZERO:
		return

	var q: CharacterBody2D = qbit1 if active_qubit == 1 else qbit2
	if q == null:
		return
	q.position = clamp_entanglement_position(q.position + movement, active_qubit)

func clamp_entanglement_position(pos: Vector2, qid: int) -> Vector2:
	pos.y = clamp(pos.y, 120.0, 600.0)
	if qid == 1:
		pos.x = clamp(pos.x, 230.0, 610.0)
	else:
		pos.x = clamp(pos.x, 670.0, 1050.0)
	return pos

func check_entanglement_level() -> void:
	if qbit1 == null or qbit2 == null:
		return
	if not entangled:
		var q1_ready: bool = qbit1.global_position.distance_to(q1_station.global_position) < 36.0
		var q2_ready: bool = qbit2.global_position.distance_to(q2_station.global_position) < 36.0
		if q1_ready and q2_ready:
			entangled = true
			active_qubit = 1
			start_next_entanglement_round()
			message.text = "⚡ Entrelazamiento establecido. Ahora toma con el Qubit 1 el color que pide el receptor."
		else:
			var status: String = ""
			status += "Qubit 1 en E: SI" if q1_ready else "Qubit 1 en E: NO"
			status += "    |    "
			status += "Qubit 2 en E: SI" if q2_ready else "Qubit 2 en E: NO"
			# Estado visible arriba en el HUD; evitamos texto abajo para no encimar el receptor.
		update_entanglement_visuals()
		return

	if delivery_pending and active_qubit == 2 and qbit2.global_position.distance_to(delivery_area.global_position) < 48.0:
		deliver_entangled_color()
		return

	if not delivery_pending and active_qubit == 1:
		for pickup in color_pickups:
			if qbit1.global_position.distance_to(pickup.global_position) < 42.0:
				var picked_name: String = pickup.get_meta("color_name") as String
				var picked_color: Color = pickup.get_meta("color_value") as Color
				apply_entangled_color(picked_name, picked_color)
				return
	update_entanglement_visuals()

func apply_entangled_color(color_name: String, color_value: Color) -> void:
	if not entangled or delivery_pending:
		return
	qbit1_visual.color = color_value
	qbit2_visual.color = color_value
	current_entangled_color_name = color_name
	current_entangled_color_value = color_value

	if color_name == requested_color_name:
		delivery_pending = true
		active_qubit = 2
		message.text = "Ambos qubits cambiaron a %s. Ahora controla el Qubit 2 y llevalo al receptor." % color_name.to_upper()
	else:
		message.text = "Ese color no era el pedido. Ambos qubits cambiaron, pero el receptor necesita %s." % requested_color_name.to_upper()
	update_entanglement_visuals()

func deliver_entangled_color() -> void:
	if not delivery_pending:
		return
	if current_entangled_color_name != requested_color_name:
		delivery_pending = false
		active_qubit = 1
		message.text = "Entrega rechazada. Vuelve con Qubit 1 y toma el color correcto: %s." % requested_color_name.to_upper()
		update_entanglement_visuals()
		return

	entanglement_round += 1
	delivery_pending = false
	if entanglement_round >= 3:
		game_over = true
		restart_button.visible = false
		menu_button.visible = false
		message.text = ""
		show_modal(
			"MISIÓN CUMPLIDA",
			"Has escapado del mundo clásico.",
			"[ENTER] Menú Principal",
			"to_menu"
		)
	else:
		message.text = "Entrega correcta: %s. Ahora vuelve al Qubit 1 y toma el siguiente color." % current_entangled_color_name.to_upper()
		start_next_entanglement_round()
		active_qubit = 1
		# Regresamos el Qubit 2 a su zona para que cada entrega requiera moverlo de nuevo.
		qbit2.position = Vector2(960, 360)
	update_entanglement_visuals()

func start_next_entanglement_round() -> void:
	var names: Array[String] = ["rojo", "azul", "verde"]
	var values: Array[Color] = [Color(1.0, 0.16, 0.16), Color(0.2, 0.45, 1.0), Color(0.25, 1.0, 0.35)]
	var idx: int = entanglement_round % names.size()
	requested_color_name = names[idx]
	requested_color_value = values[idx]
	current_entangled_color_name = ""
	current_entangled_color_value = Color.WHITE
	update_delivery_visuals()

func update_delivery_visuals() -> void:
	if delivery_visual == null or delivery_label == null:
		return
	delivery_visual.color = Color(requested_color_value.r, requested_color_value.g, requested_color_value.b, 0.75)
	delivery_label.text = requested_color_name.substr(0, 1).to_upper()
	delivery_label.add_theme_font_size_override("font_size", 26)

func update_entanglement_visuals() -> void:
	if qbit1_visual != null:
		qbit1_visual.scale = Vector2(1.25, 1.25) if active_qubit == 1 else Vector2(1.0, 1.0)
	if qbit2_visual != null:
		qbit2_visual.scale = Vector2(1.25, 1.25) if active_qubit == 2 else Vector2(1.0, 1.0)
	if entanglement_status_label != null and entangled:
		var control_text: String = "Qubit %d" % active_qubit
		if delivery_pending:
			entanglement_status_label.text = "Control: %s    |    Qubit 2 debe entregar: %s    |    Entregas: %d/3" % [control_text, current_entangled_color_name.to_upper(), entanglement_round]
		else:
			entanglement_status_label.text = "Control: %s    |    Receptor pide: %s    |    Qubit 1 toma el color    |    Entregas: %d/3" % [control_text, requested_color_name.to_upper(), entanglement_round]

func update_hud() -> void:
	var quantum_text: String = ""
	if level == 1:
		quantum_text = "Superposicion bloqueada hasta el nivel 2"
	elif level == 2:
		if superposition_active:
			quantum_text = "Superposicion: ACTIVA sin limite"
		else:
			quantum_text = "ESPACIO: activar/desactivar superposicion"
	elif level == 3:
		if superposition_locked:
			quantum_text = "Estado: COLAPSADO | Ya no puedes reactivar superposicion"
		elif superposition_active:
			quantum_text = "Superposicion: ACTIVA | Compuertas M = medicion y colapso"
		else:
			quantum_text = "Estado: CLASICO | ESPACIO: activar superposicion"
	else:
		if entangled:
			var control_text: String = "Qubit %d" % active_qubit
			if delivery_pending:
				quantum_text = "Controlando: %s | Receptor espera: %s | Completadas: %d/3" % [control_text, current_entangled_color_name.to_upper(), entanglement_round]
			else:
				quantum_text = "Controlando: %s | Receptor espera: %s | Completadas: %d/3" % [control_text, requested_color_name.to_upper(), entanglement_round]
		else:
			quantum_text = "Entrelazamiento pendiente | Coloca ambos qubits en las estaciones E"
	if level == 1:
		level_title_label.text = "Nivel: 1 \"Laberinto sin superposicion\""
	elif level == 2:
		level_title_label.text = "Nivel: 2 \"Laberinto con superposicion\""
	elif level == 3:
		level_title_label.text = "Nivel: 3 \"Medicion y colapso\""
	else:
		level_title_label.text = "Nivel 4: Entrelazamiento cuantico"
	hud_label.text = quantum_text
	if level == 4:
		instructions_label.text = "WASD: Moverte    ESPACIO: Cambiar qubit controlado"
	else:
		instructions_label.text = "WASD: Moverte    ESPACIO: Activar/Desactivar Superposición"
