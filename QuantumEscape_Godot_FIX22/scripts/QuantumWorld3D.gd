extends Node3D

# Generated laboratory architecture. Coordinates refer to the centre of each cell.
# Static details share MultiMeshes so the neon corridors remain cheap to render.
const CELL: float = 3.0
const CYAN: Color = Color("51e8f4")
const VIOLET: Color = Color("a989ff")
const GREEN: Color = Color("6fffc1")
const GOLD: Color = Color("f8ca6b")
const NAVY: Color = Color("132b43")
const FLOOR: Color = Color("1d3449")

var _architecture: Node3D
var _environment: WorldEnvironment
var _wall_materials: Array[StandardMaterial3D] = []
var _batches: Dictionary = {}
var _animated: Array[Node3D] = []
var _link: MeshInstance3D
var _time: float = 0.0
var _accent: Color = CYAN
var _phase: bool = false


func _ready() -> void:
	_setup_environment()


func _process(delta: float) -> void:
	_time += delta
	for item in _animated:
		if not is_instance_valid(item):
			continue
		var motion: String = str(item.get_meta("motion", ""))
		if motion == "orbit":
			item.rotation.y += delta * 0.45
		elif motion == "float":
			item.position.y = float(item.get_meta("rest_y", 1.0)) + sin(_time * 1.8 + float(item.get_instance_id() % 11)) * 0.08
			item.rotation.y += delta * 0.34
		elif motion == "scan":
			item.position.y = 1.25 + sin(_time * 1.6) * 0.94
		elif motion == "portal":
			item.rotation.z += delta * 0.17


func _setup_environment() -> void:
	if is_instance_valid(_environment):
		return
	_environment = WorldEnvironment.new()
	_environment.name = "QuantumAtmosphere"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("091323")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a8c2df")
	settings.ambient_light_energy = 0.72
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	settings.fog_enabled = true
	settings.fog_light_color = Color("1a3047")
	settings.fog_light_energy = 0.38
	settings.fog_density = 0.004
	_environment.environment = settings
	add_child(_environment)
	var key := DirectionalLight3D.new()
	key.name = "LaboratoryKeyLight"
	key.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	key.light_color = Color("c4e6ff")
	key.light_energy = 1.0
	key.shadow_enabled = false
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "LaboratoryFillLight"
	fill.rotation_degrees = Vector3(-28.0, 148.0, 0.0)
	fill.light_color = Color("a989ff")
	fill.light_energy = 0.30
	fill.shadow_enabled = false
	add_child(fill)


func _begin_build(accent: Color) -> void:
	_setup_environment()
	if is_instance_valid(_architecture):
		remove_child(_architecture)
		_architecture.queue_free()
	_animated.clear()
	_batches.clear()
	_wall_materials.clear()
	_link = null
	_accent = accent
	_phase = false
	_architecture = Node3D.new()
	_architecture.name = "LaboratoryGeometry"
	add_child(_architecture)


func build_maze(maze: Array[String], protocol: int) -> void:
	_begin_build(VIOLET if protocol == 3 else CYAN)
	if maze.is_empty():
		return
	var columns: int = maze[0].length()
	var rows: int = maze.size()
	var center := Vector3(float(columns - 1) * CELL * 0.5, 0.0, float(rows - 1) * CELL * 0.5)
	var dimensions := Vector3(float(columns) * CELL, 0.20, float(rows) * CELL)
	var base := _material(Color("102236"), 0.0)
	var tile := _material(FLOOR, 0.0)
	var ceiling := _material(Color("12263c"), 0.0)
	var wall := _material(Color("25435b"), 0.0)
	var inset := _material(Color("142b43"), 0.0)
	var neon := _material(_accent, 1.15)
	var roof_light := _material(Color("c4edff"), 1.0)
	var metal := _material(Color("38536a"), 0.0)
	_wall_materials.append(wall)
	_wall_materials.append(inset)
	_arch_box(center + Vector3(0.0, -0.12, 0.0), dimensions, base)
	_static_box(center + Vector3(0.0, -0.10, 0.0), dimensions, 8)
	_arch_box(center + Vector3(0.0, 3.49, 0.0), Vector3(dimensions.x, 0.16, dimensions.z), ceiling)
	_static_box(center + Vector3(0.0, 3.49, 0.0), Vector3(dimensions.x, 0.16, dimensions.z), 8)
	for z in range(rows):
		for x in range(maze[z].length()):
			var p := Vector3(float(x) * CELL, 0.0, float(z) * CELL)
			if maze[z].substr(x, 1) == "#":
				_arch_box(p + Vector3(0.0, 1.65, 0.0), Vector3(CELL, 3.3, CELL), wall)
				_static_box(p + Vector3(0.0, 1.65, 0.0), Vector3(CELL, 3.3, CELL), 1)
				# Only exposed faces carry panels and light rails.
				for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + offset.x
					var nz: int = z + offset.y
					if nx < 0 or nz < 0 or nz >= rows or nx >= maze[nz].length():
						continue
					if maze[nz].substr(nx, 1) != "#":
						_wall_face(p, offset, inset, neon, metal, (x + z) % 4 == 0)
			else:
				_arch_box(p + Vector3(0.0, -0.015, 0.0), Vector3(2.89, 0.028, 2.89), tile)
				_arch_box(p + Vector3(0.0, 3.37, 0.0), Vector3(2.83, 0.045, 2.83), ceiling)
				# Recessed side rails outline the walkable cells like quantum circuits.
				for side in [-1.0, 1.0]:
					_arch_box(p + Vector3(side * 1.36, 0.012, 0.0), Vector3(0.022, 0.018, 2.72), neon)
					_arch_box(p + Vector3(0.0, 0.012, side * 1.36), Vector3(2.72, 0.018, 0.022), neon)
				_arch_box(p + Vector3(0.0, 3.335, 0.0), Vector3(1.72, 0.025, 0.11), roof_light)
				_arch_box(p + Vector3(0.0, 3.345, 0.0), Vector3(2.06, 0.04, 0.24), metal)
				if (x + z) % 6 == 0:
					_arch_box(p + Vector3(0.0, 0.008, 0.0), Vector3(0.72, 0.012, 0.025), metal)
					_arch_box(p + Vector3(0.0, 0.009, 0.0), Vector3(0.025, 0.012, 0.72), metal)
	_flush_boxes()
	# The ambient lights provide visibility; these add local color to key junctions.
	for i in range(4):
		var light_position := Vector3(3.0 + float(i) * maxf((dimensions.x - 6.0) / 3.0, 1.0), 2.6, center.z)
		_point_light(light_position, _accent, 0.42, 8.0)


func _wall_face(p: Vector3, direction: Vector2i, inset: StandardMaterial3D, neon: StandardMaterial3D, metal: StandardMaterial3D, has_circuit: bool) -> void:
	var normal := Vector3(float(direction.x), 0.0, float(direction.y))
	var along_x: bool = direction.x == 0
	var face := p + normal * 1.505
	_arch_box(face + Vector3(0.0, 1.63, 0.0), Vector3(2.76, 2.67, 0.022) if along_x else Vector3(0.022, 2.67, 2.76), inset)
	for height in [0.24, 3.02]:
		_arch_box(face + normal * 0.015 + Vector3(0.0, height, 0.0), Vector3(2.9, 0.032, 0.045) if along_x else Vector3(0.045, 0.032, 2.9), neon)
	for side in [-1.0, 1.0]:
		var offset := Vector3(side * 1.4, 1.65, 0.0) if along_x else Vector3(0.0, 1.65, side * 1.4)
		_arch_box(face + offset, Vector3(0.055, 3.0, 0.055), metal)
	if has_circuit:
		var horizontal := Vector3.RIGHT if along_x else Vector3.BACK
		_arch_box(face + normal * 0.021 + Vector3(0.0, 1.18, 0.0), Vector3(1.12, 0.018, 0.02) if along_x else Vector3(0.02, 0.018, 1.12), neon)
		_arch_box(face + normal * 0.021 + horizontal * 0.55 + Vector3(0.0, 1.52, 0.0), Vector3(0.026, 0.7, 0.026), neon)
		_arch_box(face + normal * 0.021 + horizontal * 0.38 + Vector3(0.0, 1.87, 0.0), Vector3(0.34, 0.018, 0.02) if along_x else Vector3(0.02, 0.018, 0.34), neon)


func build_entanglement() -> void:
	_begin_build(CYAN)
	var tile := _material(FLOOR, 0.0)
	var ceiling := _material(Color("14283d"), 0.0)
	var wall := _material(Color("25435b"), 0.0)
	var inset := _material(Color("142b43"), 0.0)
	var cyan := _material(CYAN, 1.12)
	var violet := _material(VIOLET, 1.12)
	var white := _material(Color("c4edff"), 1.0)
	var metal := _material(Color("3a546d"), 0.0)
	_wall_materials.append(wall)
	_wall_materials.append(inset)
	_arch_box(Vector3(0.0, -0.12, 0.0), Vector3(24.0, 0.2, 18.0), _material(Color("102236"), 0.0))
	_static_box(Vector3(0.0, -0.1, 0.0), Vector3(24.0, 0.2, 18.0), 8)
	_arch_box(Vector3(0.0, 3.5, 0.0), Vector3(24.0, 0.2, 18.0), ceiling)
	_static_box(Vector3(0.0, 3.5, 0.0), Vector3(24.0, 0.2, 18.0), 8)
	for z in range(6):
		for x in range(8):
			var p := Vector3(-10.5 + float(x) * CELL, 0.0, -7.5 + float(z) * CELL)
			var tint: StandardMaterial3D = cyan if x < 4 else violet
			_arch_box(p + Vector3(0.0, -0.015, 0.0), Vector3(2.89, 0.028, 2.89), tile)
			for side in [-1.0, 1.0]:
				_arch_box(p + Vector3(side * 1.4, 0.013, 0.0), Vector3(0.016, 0.018, 2.8), tint)
				_arch_box(p + Vector3(0.0, 0.013, side * 1.4), Vector3(2.8, 0.018, 0.016), tint)
			_arch_box(p + Vector3(0.0, 3.36, 0.0), Vector3(2.84, 0.035, 2.84), ceiling)
			_arch_box(p + Vector3(0.0, 3.33, 0.0), Vector3(1.8, 0.03, 0.12), white)
	for side in [-1.0, 1.0]:
		_room_wall(Vector3(0.0, 1.65, side * 9.0), Vector3(24.0, 3.3, 0.45), wall, cyan)
		_room_wall(Vector3(side * 12.0, 1.65, 0.0), Vector3(0.45, 3.3, 18.0), wall, cyan if side < 0.0 else violet)
		_room_wall(Vector3(0.0, 1.65, side * 5.3), Vector3(0.30, 3.3, 7.2), inset, violet)
		# Divider end caps frame the entanglement bridge.
		_arch_box(Vector3(0.0, 1.65, side * 1.69), Vector3(0.37, 3.3, 0.07), violet)
	_arch_box(Vector3(0.0, 3.22, 0.0), Vector3(0.4, 0.12, 3.4), cyan)
	_flush_boxes()
	for x in [-7.0, 7.0]:
		for z in [-5.0, 5.0]:
			_point_light(Vector3(x, 2.8, z), CYAN if x < 0.0 else VIOLET, 0.75, 8.0)
	var left_label := _label(_architecture, "REGISTRO 01  /  ESTADO 0", Vector3(-6.0, 2.4, -8.65), CYAN)
	left_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	left_label.rotation.y = 0.0
	var right_label := _label(_architecture, "REGISTRO 02  /  ESTADO 1", Vector3(6.0, 2.4, -8.65), VIOLET)
	right_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	right_label.rotation.y = 0.0


func _room_wall(center: Vector3, size: Vector3, material: StandardMaterial3D, neon: StandardMaterial3D) -> void:
	_arch_box(center, size, material)
	_static_box(center, size, 1)
	var strip := Vector3(size.x, 0.035, size.z + 0.04) if size.x > size.z else Vector3(size.x + 0.04, 0.035, size.z)
	for height in [0.18, 3.04]:
		_arch_box(Vector3(center.x, height, center.z), strip, neon)


func set_phase(active: bool) -> void:
	_phase = active
	for material in _wall_materials:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if active else BaseMaterial3D.TRANSPARENCY_DISABLED
		var tint: Color = material.albedo_color
		tint.a = 0.15 if active else 1.0
		material.albedo_color = tint
		material.emission_enabled = active
		material.emission = VIOLET
		material.emission_energy_multiplier = 0.12 if active else 0.0


func marker(position: Vector3, kind: String, tint: Color, caption: String = "") -> Node3D:
	if not is_instance_valid(_architecture):
		_begin_build(CYAN)
	var root := Node3D.new()
	root.name = "Marker_" + kind
	root.position = position
	root.set_meta("marker_kind", kind)
	root.set_meta("tint_meshes", [])
	_architecture.add_child(root)
	var label_height: float = 1.7
	match kind.to_lower():
		"exit", "portal":
			_portal(root, tint)
			label_height = 2.78
			if caption.is_empty():
				caption = "PORTAL"
		"detector", "detector_gold", "m":
			_detector(root, tint)
			label_height = 2.72
			if caption.is_empty():
				caption = "MEDICION  /  M"
		"pad", "station", "receiver":
			_pad(root, tint)
			label_height = 1.15
		"qubit":
			_qubit(root, tint)
			label_height = 1.95
		_:
			_pickup(root, tint)
			label_height = 1.8
	if not caption.is_empty():
		var label := _label(root, caption, Vector3(0.0, label_height, 0.0), tint)
		root.set_meta("caption", label)
	return root


func update_marker_color(node: Node3D, tint: Color, caption: String = "") -> void:
	if not is_instance_valid(node):
		return
	var meshes: Array = node.get_meta("tint_meshes", [])
	for entry in meshes:
		if not is_instance_valid(entry):
			continue
		var mesh: MeshInstance3D = entry as MeshInstance3D
		var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		var alpha: float = float(mesh.get_meta("tint_alpha", 1.0))
		material.albedo_color = Color(tint, alpha)
		material.emission = tint
	if node.has_meta("caption"):
		var label: Label3D = node.get_meta("caption") as Label3D
		if is_instance_valid(label):
			label.modulate = tint
			if not caption.is_empty():
				label.text = caption
	elif not caption.is_empty():
		var label := _label(node, caption, Vector3(0.0, 1.85, 0.0), tint)
		node.set_meta("caption", label)


func _portal(root: Node3D, tint: Color) -> void:
	_box(root, Vector3(0.0, 0.1, 0.0), Vector3(2.05, 0.2, 0.75), _material(NAVY, 0.0))
	for side in [-1.0, 1.0]:
		_box(root, Vector3(side * 1.0, 1.35, 0.0), Vector3(0.17, 2.7, 0.25), _material(Color("38536a"), 0.0))
		_color_box(root, Vector3(side * 0.95, 1.35, -0.16), Vector3(0.035, 2.4, 0.035), tint)
	var ring := _color_ring(root, Vector3(0.0, 1.34, 0.0), 0.88, 0.035, tint)
	ring.rotation.x = PI * 0.5
	ring.scale = Vector3(1.0, 1.0, 1.35)
	var inner := _color_ring(root, Vector3(0.0, 1.34, 0.0), 0.74, 0.013, tint)
	inner.rotation.x = PI * 0.5
	inner.scale = Vector3(1.0, 1.0, 1.35)
	var membrane := _color_sphere(root, Vector3(0.0, 1.34, 0.0), 0.80, tint, 0.08)
	membrane.scale = Vector3(1.0, 1.38, 0.055)
	var rotor := Node3D.new()
	rotor.position.y = 1.34
	root.add_child(rotor)
	for i in range(4):
		var a: float = TAU * float(i) / 4.0
		_color_sphere(rotor, Vector3(cos(a) * 0.89, sin(a) * 1.20, 0.0), 0.045, tint)
		_transfer_tints(root, rotor)
	rotor.set_meta("motion", "portal")
	_animated.append(rotor)


func _detector(root: Node3D, tint: Color) -> void:
	for side in [-1.0, 1.0]:
		_box(root, Vector3(side * 1.04, 1.28, 0.0), Vector3(0.13, 2.56, 0.30), _material(NAVY, 0.0))
		_color_box(root, Vector3(side * 1.04, 1.28, -0.17), Vector3(0.044, 2.43, 0.03), tint)
		_color_sphere(root, Vector3(side * 1.04, 2.38, -0.08), 0.075, tint)
	_color_box(root, Vector3(0.0, 2.5, 0.0), Vector3(2.2, 0.045, 0.12), tint)
	_color_ring(root, Vector3(0.0, 0.035, 0.0), 0.90, 0.018, tint)
	var scan := _color_box(root, Vector3(0.0, 1.25, 0.0), Vector3(1.95, 0.018, 0.10), tint, 0.72)
	scan.set_meta("motion", "scan")
	_animated.append(scan)


func _pad(root: Node3D, tint: Color) -> void:
	var plate := CylinderMesh.new()
	plate.top_radius = 0.92
	plate.bottom_radius = 0.94
	plate.height = 0.085
	plate.radial_segments = 32
	_mesh(root, plate, Vector3(0.0, 0.04, 0.0), _material(NAVY, 0.0))
	_color_ring(root, Vector3(0.0, 0.095, 0.0), 0.83, 0.020, tint)
	_color_ring(root, Vector3(0.0, 0.10, 0.0), 0.57, 0.012, tint)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		var tick := _color_box(root, Vector3(cos(a) * 0.88, 0.11, sin(a) * 0.88), Vector3(0.14, 0.015, 0.04), tint)
		tick.rotation.y = -a
	var hover := _color_ring(root, Vector3(0.0, 0.53, 0.0), 0.28, 0.013, tint, 0.65)
	hover.rotation.z = PI * 0.20
	hover.set_meta("motion", "float")
	hover.set_meta("rest_y", 0.53)
	_animated.append(hover)
	_color_sphere(root, Vector3(0.0, 0.25, 0.0), 0.07, tint)


func _qubit(root: Node3D, tint: Color) -> void:
	var globe := Node3D.new()
	globe.position.y = 0.98
	globe.set_meta("motion", "float")
	globe.set_meta("rest_y", 0.98)
	root.add_child(globe)
	var surface := _color_sphere(globe, Vector3.ZERO, 0.35, tint, 0.14)
	surface.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	_color_sphere(globe, Vector3.ZERO, 0.07, tint)
	for axis in range(3):
		var ring := _color_ring(globe, Vector3.ZERO, 0.35, 0.009, tint)
		if axis == 1:
			ring.rotation.x = PI * 0.5
		elif axis == 2:
			ring.rotation.z = PI * 0.5
	var orbit := _color_ring(globe, Vector3.ZERO, 0.49, 0.011, tint)
	orbit.rotation_degrees = Vector3(32.0, 0.0, 24.0)
	_color_sphere(globe, Vector3(0.26, 0.21, 0.0), 0.035, Color("e7f4ff"))
	_color_box(globe, Vector3(0.0, 0.0, 0.0), Vector3(0.013, 0.79, 0.013), tint, 0.60)
	_transfer_tints(root, globe)
	_animated.append(globe)
	_color_ring(root, Vector3(0.0, 0.025, 0.0), 0.37, 0.014, tint, 0.6)


func _pickup(root: Node3D, tint: Color) -> void:
	_box(root, Vector3(0.0, 0.16, 0.0), Vector3(0.66, 0.32, 0.66), _material(NAVY, 0.0))
	_color_ring(root, Vector3(0.0, 0.34, 0.0), 0.33, 0.014, tint)
	var globe := Node3D.new()
	globe.position.y = 0.92
	globe.set_meta("motion", "float")
	globe.set_meta("rest_y", 0.92)
	root.add_child(globe)
	_color_sphere(globe, Vector3.ZERO, 0.22, tint, 0.30)
	_color_sphere(globe, Vector3.ZERO, 0.11, tint)
	var ring := _color_ring(globe, Vector3.ZERO, 0.32, 0.012, tint)
	ring.rotation_degrees = Vector3(40.0, 0.0, 30.0)
	_transfer_tints(root, globe)
	_animated.append(globe)
	_color_box(root, Vector3(0.0, 0.62, 0.0), Vector3(0.018, 0.53, 0.018), tint, 0.30)


func _transfer_tints(destination: Node3D, source: Node3D) -> void:
	var meshes: Array = destination.get_meta("tint_meshes", [])
	var additions: Array = source.get_meta("tint_meshes", [])
	for entry in additions:
		if not meshes.has(entry):
			meshes.append(entry)
	destination.set_meta("tint_meshes", meshes)


func draw_link(first: Vector3, second: Vector3, tint: Color) -> void:
	if not is_instance_valid(_link):
		_link = MeshInstance3D.new()
		_link.name = "EntanglementFilament"
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.018
		cylinder.bottom_radius = 0.018
		cylinder.height = 1.0
		cylinder.radial_segments = 8
		_link.mesh = cylinder
		_link.material_override = _material(tint, 1.1, 0.75)
		_link.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_architecture.add_child(_link)
	var distance: float = first.distance_to(second)
	_link.visible = distance > 0.04 and tint.a > 0.01
	if not _link.visible:
		return
	_link.position = (first + second) * 0.5
	_link.basis = _segment_basis(first, second)
	_link.scale = Vector3(1.0, distance, 1.0)
	var material: StandardMaterial3D = _link.material_override as StandardMaterial3D
	material.albedo_color = Color(tint, 0.75)
	material.emission = tint


func spawn_beam(start: Vector3, end: Vector3, hit: bool) -> void:
	var beam := Node3D.new()
	beam.name = "QuantumPulse"
	add_child(beam)
	var distance: float = maxf(start.distance_to(end), 0.05)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.021 if hit else 0.014
	cylinder.bottom_radius = cylinder.top_radius
	cylinder.height = distance
	cylinder.radial_segments = 8
	var line := _mesh(beam, cylinder, (start + end) * 0.5, _material(CYAN, 1.75))
	line.basis = _segment_basis(start, end)
	var core := SphereMesh.new()
	core.radius = 0.105 if hit else 0.045
	core.height = core.radius * 2.0
	core.radial_segments = 12
	core.rings = 6
	_mesh(beam, core, end, _material(Color("dbfdff"), 1.5))
	var impact := _color_ring(beam, end, 0.16 if hit else 0.07, 0.014, CYAN)
	impact.basis = _segment_basis(start, end)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "scale", Vector3(0.02, 1.0, 0.02), 0.22)
	tween.tween_property(impact, "scale", Vector3.ONE * (2.8 if hit else 1.6), 0.22)
	tween.chain().tween_callback(beam.queue_free)


func _segment_basis(first: Vector3, second: Vector3) -> Basis:
	var along: Vector3 = (second - first).normalized()
	if along.length_squared() < 0.5:
		return Basis.IDENTITY
	var reference: Vector3 = Vector3.UP if absf(along.dot(Vector3.UP)) < 0.97 else Vector3.RIGHT
	var right: Vector3 = reference.cross(along).normalized()
	return Basis(right, along, right.cross(along).normalized())


func _label(parent: Node3D, text: String, position: Vector3, tint: Color) -> Label3D:
	var label := Label3D.new()
	label.name = "HolographicCaption"
	label.position = position
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.0034
	label.modulate = tint
	label.outline_modulate = Color("071422")
	label.outline_size = 7
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.fixed_size = false
	label.shaded = false
	label.visibility_range_end = 24.0
	parent.add_child(label)
	return label


func _material(tint: Color, emission: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(tint, alpha)
	material.roughness = 0.72 if emission == 0.0 else 0.30
	material.metallic = 0.20 if emission == 0.0 else 0.0
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = emission
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.no_depth_test = false
	return material


func _arch_box(position: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var key: int = material.get_instance_id()
	if not _batches.has(key):
		_batches[key] = {"material": material, "transforms": []}
	var transforms: Array = _batches[key]["transforms"]
	transforms.append(Transform3D(Basis.IDENTITY.scaled(size), position))


func _flush_boxes() -> void:
	for key in _batches:
		var data: Dictionary = _batches[key]
		var transforms: Array = data["transforms"]
		var batch := MultiMeshInstance3D.new()
		batch.name = "LaboratoryPanelBatch"
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		multi.mesh = box
		multi.instance_count = transforms.size()
		for i in range(transforms.size()):
			multi.set_instance_transform(i, transforms[i])
		batch.multimesh = multi
		batch.material_override = data["material"]
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_architecture.add_child(batch)
	_batches.clear()


func _static_box(position: Vector3, size: Vector3, layer: int) -> void:
	var body := StaticBody3D.new()
	body.position = position
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	_architecture.add_child(body)


func _mesh(parent: Node3D, shape: Mesh, position: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.position = position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func _box(parent: Node3D, position: Vector3, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(parent, box, position, material)


func _color_box(parent: Node3D, position: Vector3, size: Vector3, tint: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mesh := _box(parent, position, size, _material(tint, 1.1, alpha))
	_register_tint(parent, mesh, alpha)
	return mesh


func _color_sphere(parent: Node3D, position: Vector3, radius: float, tint: Color, alpha: float = 1.0) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	var mesh := _mesh(parent, sphere, position, _material(tint, 1.0, alpha))
	_register_tint(parent, mesh, alpha)
	return mesh


func _color_ring(parent: Node3D, position: Vector3, radius: float, thickness: float, tint: Color, alpha: float = 1.0) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(radius - thickness, 0.001)
	torus.outer_radius = radius + thickness
	torus.rings = 32
	torus.ring_segments = 6
	var mesh := _mesh(parent, torus, position, _material(tint, 1.1, alpha))
	_register_tint(parent, mesh, alpha)
	return mesh


func _register_tint(parent: Node3D, mesh: MeshInstance3D, alpha: float) -> void:
	var meshes: Array = parent.get_meta("tint_meshes", [])
	meshes.append(mesh)
	parent.set_meta("tint_meshes", meshes)
	mesh.set_meta("tint_alpha", alpha)


func _point_light(position: Vector3, tint: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = tint
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.5
	light.shadow_enabled = false
	_architecture.add_child(light)
