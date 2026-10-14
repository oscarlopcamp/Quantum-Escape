extends CharacterBody3D

const WALK_SPEED: float = 4.6
const LOOK_SPEED: float = 1.9
const MOUSE_SENSITIVITY: float = 0.0025
const MAX_PITCH: float = deg_to_rad(75.0)
const RAY_RANGE: float = 28.0
const CYAN: Color = Color("#51e8f4")
const VIOLET: Color = Color("#a989ff")

var camera: Camera3D
var enabled: bool = false
var movement_bounds: Rect2 = Rect2()
var superposed: bool = false:
	set(value):
		superposed = value
		collision_mask = 8 if value else 9

var _pitch_pivot: Node3D
var _emitter: Node3D
var _qubit: Node3D
var _muzzle: Marker3D
var _flash: MeshInstance3D
var _shot_time: float = 0.0
var _clock: float = 0.0
var _gravity: float = 15.0
var _emitter_home := Vector3(0.34, -0.27, -0.6)


func _ready() -> void:
	name = "QuantumPlayer"
	collision_layer = 2
	collision_mask = 8 if superposed else 9
	floor_snap_length = 0.3
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.7
	collision.shape = capsule
	add_child(collision)

	_pitch_pivot = Node3D.new()
	_pitch_pivot.name = "LookPivot"
	_pitch_pivot.position.y = 0.65
	add_child(_pitch_pivot)
	camera = Camera3D.new()
	camera.name = "FirstPersonCamera"
	camera.fov = 75.0
	camera.near = 0.05
	camera.far = 140.0
	_pitch_pivot.add_child(camera)
	camera.current = false
	_build_emitter()


func set_enabled(value: bool) -> void:
	enabled = value
	if not value:
		velocity = Vector3.ZERO
	if is_instance_valid(camera):
		camera.current = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE


func set_look_angles(yaw: float, pitch: float = 0.0) -> void:
	rotation.y = yaw
	if is_instance_valid(_pitch_pivot):
		_pitch_pivot.rotation.x = clampf(pitch, -MAX_PITCH, MAX_PITCH)


func _unhandled_input(event: InputEvent) -> void:
	if enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		_pitch_pivot.rotation.x = clampf(
			_pitch_pivot.rotation.x - event.relative.y * MOUSE_SENSITIVITY,
			-MAX_PITCH, MAX_PITCH
		)


func _physics_process(delta: float) -> void:
	move_step(delta)


func move_step(delta: float) -> void:
	if not enabled:
		return
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	rotation.y -= look.x * LOOK_SPEED * delta
	_pitch_pivot.rotation.x = clampf(
		_pitch_pivot.rotation.x - look.y * LOOK_SPEED * delta,
		-MAX_PITCH, MAX_PITCH
	)
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector3 = global_basis * Vector3(movement.x, 0.0, movement.y)
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()
	if movement_bounds.size.x > 0.0 and movement_bounds.size.y > 0.0:
		var bounded := global_position
		bounded.x = clampf(bounded.x, movement_bounds.position.x, movement_bounds.end.x)
		bounded.z = clampf(bounded.z, movement_bounds.position.y, movement_bounds.end.y)
		global_position = bounded


func aim_ray() -> Dictionary:
	if not is_instance_valid(camera) or not is_inside_tree():
		return {}
	var start := camera.global_position
	var end := start - camera.global_basis.z * RAY_RANGE
	var query := PhysicsRayQueryParameters3D.create(start, end, 13, [get_rid()])
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query)


func fire_ray() -> Dictionary:
	return aim_ray()


func get_muzzle_position() -> Vector3:
	return _muzzle.global_position if is_instance_valid(_muzzle) else global_position


func animate_shot() -> void:
	_shot_time = 0.12
	if is_instance_valid(_flash):
		_flash.visible = true


func _process(delta: float) -> void:
	if not is_instance_valid(_emitter):
		return
	if enabled:
		_clock += delta
		_shot_time = maxf(0.0, _shot_time - delta)
	var kick: float = _shot_time / 0.12
	_emitter.position = _emitter_home + Vector3(0.0, sin(_clock * 2.0) * 0.002, kick * 0.05)
	_emitter.rotation.x = kick * 0.055
	_qubit.rotation.y = _clock * 0.75
	_qubit.rotation.z = sin(_clock * 0.8) * 0.3
	_flash.visible = _shot_time > 0.07
	_flash.scale = Vector3.ONE * (0.7 + kick * 0.6)


func _material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.65 if glow == 0.0 else 0.1
	material.roughness = 0.35
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _mesh(parent: Node3D, mesh: Mesh, material: Material, position_at: Vector3) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position_at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)
	return visual


func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(parent, box, material, at)


func _ring(parent: Node3D, radius: float, at: Vector3, material: Material) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.009
	torus.outer_radius = radius + 0.009
	torus.rings = 32
	torus.ring_segments = 8
	return _mesh(parent, torus, material, at)


func _build_emitter() -> void:
	var metal := _material(Color("#15233a"))
	var dark := _material(Color("#09121f"))
	var cyan := _material(CYAN, 1.6)
	var violet := _material(VIOLET, 1.3)
	_emitter = Node3D.new()
	_emitter.name = "QuantumEmitter"
	_emitter.position = _emitter_home
	camera.add_child(_emitter)
	_box(_emitter, Vector3(0.18, 0.12, 0.27), Vector3(0.0, 0.0, 0.035), metal)
	_box(_emitter, Vector3(0.105, 0.19, 0.085), Vector3(0.0, -0.125, 0.085), dark)
	_box(_emitter, Vector3(0.012, 0.014, 0.23), Vector3(0.095, 0.025, 0.03), cyan)
	_box(_emitter, Vector3(0.012, 0.014, 0.23), Vector3(-0.095, 0.025, 0.03), violet)
	_box(_emitter, Vector3(0.12, 0.016, 0.15), Vector3(0.0, -0.064, 0.018), cyan)

	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.042
	barrel.bottom_radius = 0.06
	barrel.height = 0.15
	barrel.radial_segments = 16
	_mesh(_emitter, barrel, dark, Vector3(0.0, 0.0, -0.16)).rotation.x = PI / 2.0
	_ring(_emitter, 0.051, Vector3(0.0, 0.0, -0.20), cyan).rotation.x = PI / 2.0
	_ring(_emitter, 0.046, Vector3(0.0, 0.0, -0.235), violet).rotation.x = PI / 2.0

	_qubit = Node3D.new()
	_qubit.position = Vector3(0.0, 0.092, -0.005)
	_emitter.add_child(_qubit)
	var core := SphereMesh.new()
	core.radius = 0.027
	core.height = 0.054
	core.radial_segments = 16
	core.rings = 8
	_mesh(_qubit, core, cyan, Vector3.ZERO)
	_ring(_qubit, 0.054, Vector3.ZERO, violet).rotation.z = PI / 3.0
	_ring(_qubit, 0.049, Vector3.ZERO, cyan).rotation.x = PI / 2.0

	_muzzle = Marker3D.new()
	_muzzle.position = Vector3(0.0, 0.0, -0.245)
	_emitter.add_child(_muzzle)
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.025
	flash_mesh.height = 0.05
	flash_mesh.radial_segments = 12
	flash_mesh.rings = 6
	_flash = _mesh(_muzzle, flash_mesh, cyan, Vector3.ZERO)
	_flash.visible = false
