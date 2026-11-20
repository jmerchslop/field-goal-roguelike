extends Node3D

# Placeholder kicker. A later art pass can replace the children in Kicker.tscn.
# The game only calls follow(). Y is up. The kicker faces the goal, which is -Z.

var _torso: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D


func _ready() -> void:
	if get_child_count() == 0:
		_build_placeholder()
	_torso = get_node_or_null("Torso")
	_arm_l = get_node_or_null("Torso/ArmL")
	_arm_r = get_node_or_null("Torso/ArmR")
	_leg_l = get_node_or_null("LegL")
	_leg_r = get_node_or_null("LegR")


# tee is where the ball rests, in yards.
# phase is a KickLogic.Phase. approach_time grows while the meter is running.
# flight_time is how long the ball has been in the air.
func follow(tee: Vector3, phase: int, approach_time: float, flight_time: float) -> void:
	var stand := tee + Vector3(-1.25, 0.0, 1.7)
	var plant := tee + Vector3(-0.48, 0.0, 0.28)
	if phase == KickLogic.Phase.AIMING:
		position = stand
		_pose_stand()
		return
	if phase == KickLogic.Phase.POWER or phase == KickLogic.Phase.ACCURACY:
		var step := clampf(approach_time / 0.8, 0.0, 1.0)
		position = stand.lerp(plant, step)
		_pose_run(approach_time)
		return
	# The third Space press starts the flight. The kick swing happens at the start of it.
	position = plant
	var swing := clampf(flight_time / 0.32, 0.0, 1.0)
	_pose_kick(swing)


func _pose_stand() -> void:
	_set_x(_leg_l, 0.0)
	_set_x(_leg_r, 0.0)
	_set_x(_arm_l, 8.0)
	_set_x(_arm_r, 8.0)
	_set_x(_torso, 0.0)


func _pose_run(time: float) -> void:
	var swing := sin(time * 11.0) * 55.0
	_set_x(_leg_l, swing)
	_set_x(_leg_r, -swing)
	_set_x(_arm_l, -swing * 0.8)
	_set_x(_arm_r, swing * 0.8)
	_set_x(_torso, 14.0)


func _pose_kick(swing: float) -> void:
	# Plant the left leg. Swing the right leg through toward the goal (-Z is -X rotation).
	_set_x(_leg_l, 12.0)
	_set_x(_leg_r, lerpf(20.0, -105.0, swing))
	_set_x(_arm_l, lerpf(10.0, -40.0, swing))
	_set_x(_arm_r, lerpf(10.0, 25.0, swing))
	_set_x(_torso, lerpf(6.0, -18.0, swing))


func _set_x(part: Node3D, degrees: float) -> void:
	if part == null:
		return
	part.rotation.x = deg_to_rad(degrees)


func _build_placeholder() -> void:
	var skin := _mat(Color(0.86, 0.66, 0.48))
	var shirt := _mat(Color(0.75, 0.16, 0.14))
	var pants := _mat(Color(0.16, 0.28, 0.62))
	var cap := _mat(Color(0.94, 0.94, 0.9))
	var boots := _mat(Color(0.32, 0.18, 0.1))
	_torso = Node3D.new()
	_torso.name = "Torso"
	_torso.position = Vector3(0, 1.15, 0)
	add_child(_torso)
	_mesh_on(_torso, CapsuleMesh.new(), Vector3(0, 0.28, 0), shirt, 0.22, 0.72)
	var head := _mesh_on(_torso, SphereMesh.new(), Vector3(0, 0.82, 0), skin, 0.16, 0.32)
	_mesh_on(head, BoxMesh.new(), Vector3(0, 0.1, -0.08), cap, 0.2, 0.08, 0.22)
	_arm_l = _limb("ArmL", Vector3(-0.28, 0.5, 0), 0.08, 0.55, shirt)
	_arm_r = _limb("ArmR", Vector3(0.28, 0.5, 0), 0.08, 0.55, shirt)
	_torso.add_child(_arm_l)
	_torso.add_child(_arm_r)
	_leg_l = _limb("LegL", Vector3(-0.12, 0.95, 0), 0.1, 0.9, pants)
	_leg_r = _limb("LegR", Vector3(0.12, 0.95, 0), 0.1, 0.9, pants)
	add_child(_leg_l)
	add_child(_leg_r)
	_mesh_on(_leg_l, SphereMesh.new(), Vector3(0, -0.5, 0.04), boots, 0.1, 0.16)
	_mesh_on(_leg_r, SphereMesh.new(), Vector3(0, -0.5, 0.04), boots, 0.1, 0.16)


func _limb(limb_name: String, at: Vector3, radius: float, height: float, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = limb_name
	pivot.position = at
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = height
	_mesh_on(pivot, cap, Vector3(0, -height * 0.42, 0), mat, radius, height)
	return pivot


func _mesh_on(parent: Node3D, mesh: PrimitiveMesh, at: Vector3, mat: Material, radius: float, height: float, depth: float = -1.0) -> Node3D:
	if mesh is CapsuleMesh:
		mesh.radius = radius
		mesh.height = height
	elif mesh is SphereMesh:
		mesh.radius = radius
		mesh.height = height
	elif mesh is BoxMesh:
		mesh.size = Vector3(radius, height, depth if depth > 0.0 else radius)
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.position = at
	body.material_override = mat
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(body)
	return body


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat
