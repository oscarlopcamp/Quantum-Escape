extends CharacterBody3D

signal caught_player

const CHASE_SPEED: float = 2.0
const RED: Color = Color("#ff667c")
const CYAN: Color = Color("#51e8f4")

var target: Node3D
var enabled: bool = true
var frozen_time: float = 0.0
var waypoints: Array[Vector3] = []

var _visual: Node3D
var _core_material: StandardMaterial3D
var _freeze_ring: MeshInstance3D
var _freeze_caption: Label3D
var _clock: float = 0.0
var _caught: bool = false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 9
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.42
	collision.shape = sphere
	add_child(collision)
	_build_drone()


func set_path(points: Array[Vector3]) -> void:
	waypoints = points.duplicate()


func freeze(duration: float = 3.5) -> void:
	frozen_time = maxf(frozen_time, duration)
	velocity = Vector3.ZERO
	_update_frozen_visual()


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not enabled:
		return
	_clock += delta
	if is_instance_valid(_visual):
		_visual.position.y = sin(_clock * 2.6) * 0.075
	if frozen_time > 0.0:
		frozen_time = maxf(0.0, frozen_time - delta)
		velocity = Vector3.ZERO
		_update_frozen_visual()
		if is_instance_valid(_freeze_ring):
			_freeze_ring.rotation.y += delta * 1.4
		return
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	var flat_distance := Vector2(global_position.x - target.global_position.x,
		global_position.z - target.global_position.z).length()
	if flat_distance < 0.8:
		velocity = Vector3.ZERO
		if not _caught:
			_caught = true
			caught_player.emit()
		return

	while not waypoints.is_empty():
		var offset := waypoints[0] - global_position
		offset.y = 0.0
		if offset.length() >= 0.20:
			break
		waypoints.remove_at(0)
	var destination: Vector3 = waypoints[0] if not waypoints.is_empty() else target.global_position
	var direction := destination - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
		velocity = direction * CHASE_SPEED
		if is_instance_valid(_visual):
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-direction.x, -direction.z), minf(delta * 5.0, 1.0))
	else:
		velocity = Vector3.ZERO
	move_and_slide()


func _update_frozen_visual() -> void:
	if not is_instance_valid(_core_material):
		return
	var frozen: bool = frozen_time > 0.0
	var color: Color = CYAN if frozen else RED
	_core_material.albedo_color = color
	_core_material.emission = color
	_freeze_ring.visible = frozen
	_freeze_caption.visible = frozen
	if frozen:
		_freeze_caption.text = "INMOVILIZADO · %.1f s" % frozen_time


func _material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.6 if glow == 0.0 else 0.0
	material.roughness = 0.4
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _mesh(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.position = at
	parent.add_child(visual)
	return visual


func _ring(parent: Node3D, radius: float, material: Material) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.015
	torus.outer_radius = radius + 0.015
	torus.rings = 32
	torus.ring_segments = 8
	return _mesh(parent, torus, material, Vector3.ZERO)


func _build_drone() -> void:
	_visual = Node3D.new()
	_visual.name = "Sentinel"
	add_child(_visual)
	var metal := _material(Color("#1a2639"))
	_core_material = _material(RED, 1.5)
	var cyan := _material(CYAN, 1.6)
	var violet := _material(Color("#a989ff"), 1.1)
	var sphere := SphereMesh.new()
	sphere.radius = 0.26
	sphere.height = 0.52
	sphere.radial_segments = 12
	sphere.rings = 6
	_mesh(_visual, sphere, metal, Vector3.ZERO)
	var core := SphereMesh.new()
	core.radius = 0.135
	core.height = 0.27
	core.radial_segments = 16
	core.rings = 8
	_mesh(_visual, core, _core_material, Vector3(0.0, 0.0, -0.2))
	_ring(_visual, 0.31, _core_material).rotation.z = PI / 10.0
	_ring(_visual, 0.31, metal).rotation.x = PI / 2.0
	for side: float in [-1.0, 1.0]:
		var wing := BoxMesh.new()
		wing.size = Vector3(0.19, 0.085, 0.24)
		_mesh(_visual, wing, metal, Vector3(side * 0.32, 0.0, 0.035))
		var strip := BoxMesh.new()
		strip.size = Vector3(0.16, 0.017, 0.025)
		_mesh(_visual, strip, _core_material, Vector3(side * 0.32, -0.045, -0.055))
	var bottom := CylinderMesh.new()
	bottom.top_radius = 0.11
	bottom.bottom_radius = 0.045
	bottom.height = 0.15
	bottom.radial_segments = 8
	_mesh(_visual, bottom, violet, Vector3(0.0, -0.29, 0.0))

	_freeze_ring = _ring(self, 0.53, cyan)
	_freeze_ring.rotation.x = PI / 4.0
	_freeze_ring.visible = false
	_freeze_caption = Label3D.new()
	_freeze_caption.position.y = 0.7
	_freeze_caption.font_size = 30
	_freeze_caption.pixel_size = 0.004
	_freeze_caption.modulate = CYAN
	_freeze_caption.outline_modulate = Color("#060c19")
	_freeze_caption.outline_size = 8
	_freeze_caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_freeze_caption.no_depth_test = false
	_freeze_caption.visible = false
	add_child(_freeze_caption)
