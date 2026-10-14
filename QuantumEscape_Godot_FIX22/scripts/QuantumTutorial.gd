extends RefCounted

# A small, optional practice sequence. Main owns the scene and navigation;
# this helper observes actions without imposing timers, damage or penalties.
const MOVE_DISTANCE: float = 1.0
const LOOK_ANGLE: float = 0.20
const PORTAL_DISTANCE: float = 1.2
const STEP_COUNT: int = 4

var step: int = 0
var complete: bool = false

var _game: Node
var _position_start := Vector3.ZERO
var _look_start := Vector3.FORWARD
var _moved_distance: float = 0.0
var _looked_angle: float = 0.0
var _ability_used: bool = false


func setup(game: Node) -> void:
	reset()
	_game = game
	_capture_step_start()


func reset() -> void:
	step = 0
	complete = false
	_game = null
	_position_start = Vector3.ZERO
	_look_start = Vector3.FORWARD
	_moved_distance = 0.0
	_looked_angle = 0.0
	_ability_used = false


func tick(_delta: float) -> void:
	if complete or not is_instance_valid(_game):
		return
	var player := _player()
	if not is_instance_valid(player):
		return
	match step:
		0:
			_moved_distance = maxf(_moved_distance, _flat_distance(player.global_position, _position_start))
			if _moved_distance >= MOVE_DISTANCE:
				_advance()
		1:
			_looked_angle = maxf(_looked_angle, _look_start.angle_to(_look_direction(player)))
			if _looked_angle >= LOOK_ANGLE:
				_advance()
		3:
			if bool(_game.get("superposition_active")):
				_ability_used = true
			var portal: Node3D = _game.get("exit_area") as Node3D
			if _ability_used and is_instance_valid(portal) and _flat_distance(player.global_position, portal.global_position) < PORTAL_DISTANCE:
				complete = true


func observe_shot(hit: bool) -> void:
	if not complete and is_instance_valid(_game) and step == 2 and hit:
		_advance()


func observe_ability() -> void:
	if not complete and is_instance_valid(_game) and bool(_game.get("superposition_active")):
		_ability_used = true


func get_title() -> String:
	if complete:
		return "ENTRENAMIENTO COMPLETADO"
	var names: Array[String] = ["MUEVETE", "MIRA A TU ALREDEDOR", "CONGELA EL DRON", "ACTIVA TU ESTADO CUANTICO"]
	return "PASO %d DE %d / %s" % [step + 1, STEP_COUNT, names[step]]


func get_body() -> String:
	if complete:
		return "Ya puedes explorar, apuntar y atravesar muros.\nEl laboratorio esta listo para ti."
	match step:
		0:
			return "Camina un metro por el laboratorio.\nEste entrenamiento no tiene castigos."
		1:
			return "Mueve el raton para orientar la camara.\nBusca el dron rojo y mantenlo a la vista."
		2:
			return "Apunta al dron rojo y dispara.\nTu rayo lo congela durante unos segundos."
		_:
			if _ability_used:
				return "Superposicion aprendida. Ve al portal verde.\nPuedes atravesar muros mientras siga activa."
			return "Activa la superposicion y llega al portal verde.\nPuedes atravesar los muros; cruzarlos es opcional."


func get_controls() -> String:
	if complete:
		return "Entrenamiento terminado"
	match step:
		0:
			return "WASD - moverte"
		1:
			return "Raton - mirar"
		2:
			return "Clic izquierdo - disparar"
		_:
			return "Espacio - superposicion | WASD - ir al portal"


func get_progress() -> String:
	if complete:
		return "4 / 4"
	match step:
		0:
			return "Recorrido: %.1f / %.1f m" % [minf(_moved_distance, MOVE_DISTANCE), MOVE_DISTANCE]
		1:
			return "Orientacion: %d%%" % roundi(minf(_looked_angle / LOOK_ANGLE, 1.0) * 100.0)
		2:
			return "Inmoviliza el dron con un disparo"
		_:
			return "Llega al portal verde" if _ability_used else "Activa superposicion con Espacio"


func _advance() -> void:
	step = mini(step + 1, STEP_COUNT - 1)
	_capture_step_start()


func _capture_step_start() -> void:
	var player := _player()
	if not is_instance_valid(player):
		return
	_position_start = player.global_position
	_look_start = _look_direction(player)
	_moved_distance = 0.0
	_looked_angle = 0.0


func _player() -> Node3D:
	if not is_instance_valid(_game):
		return null
	return _game.get("player") as Node3D


func _look_direction(player: Node3D) -> Vector3:
	var camera: Camera3D = player.get("camera") as Camera3D
	return (-camera.global_basis.z).normalized() if is_instance_valid(camera) else (-player.global_basis.z).normalized()


func _flat_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()
