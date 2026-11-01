extends Node3D

# Shows the kick in 3D and reads the keyboard.
# Kick rules live in KickLogic. The run lives in RunLogic.
# 1 unit = 1 yard. The goal line is Z = 0. The kicker stands on +Z and looks toward -Z.
# Negative sideways yards are -X, which is screen-left when you look up-field.

const ScreenshotDriverScript := preload("res://scripts/ScreenshotDriver.gd")
const KickerScene := preload("res://scenes/kicker.tscn")
const ARC_YARDS := 5.2
const BALL_RADIUS := 0.16

var logic := KickLogic.new()
var run := RunLogic.new()
var _taking_pictures := false
var _approach_time := 0.0

var _world: Node3D
var _camera: Camera3D
var _ball: MeshInstance3D
var _tee: MeshInstance3D
var _arrow: MeshInstance3D
var _shadow: MeshInstance3D
var _kicker: Node3D
var _hud: Control


func _ready() -> void:
	_world = $World
	_camera = $Camera3D
	_hud = $HUD/Overlay
	_hud.game = self
	_style_world()
	_build_field()
	_build_uprights()
	_build_ball()
	_kicker = KickerScene.instantiate()
	_world.add_child(_kicker)
	run.new_run()
	load_current_kick()
	if OS.get_environment("FG_SHOTS") != "1":
		return
	_taking_pictures = true
	var driver := ScreenshotDriverScript.new()
	driver.board = self
	var dir := OS.get_environment("FG_SHOT_DIR")
	if dir != "":
		driver.shot_dir = dir
	driver.name = "ScreenshotDriver"
	add_child(driver)


func load_current_kick() -> void:
	logic.reset_kick()
	logic.kick_distance = run.distance_yards()
	logic.start_lateral_yards = run.spot_yards
	logic.sync_tee()
	_approach_time = 0.0
	refresh_view()


func settle_kick() -> void:
	if logic.phase == KickLogic.Phase.RESULT:
		run.resolve_kick(logic.result_text, logic.offset_yards, logic.perfect)


func advance_run() -> bool:
	if not run.go_to_next_kick():
		return false
	load_current_kick()
	return true


func restart_run() -> void:
	run.new_run()
	load_current_kick()


func force_spot_side(side: int) -> void:
	run.set_next_side(side)


func play_locked_kick(power_value: float) -> void:
	logic.press_space()
	logic.advance(power_value / KickConstants.POWER_RISE_PER_SEC)
	logic.press_space()
	logic.advance(power_value / KickConstants.ACCURACY_FALL_PER_SEC)
	logic.press_space()
	logic.advance(logic.flight_duration)


func script_good_kick() -> void:
	run.resolve_kick("GOOD", 0.0, false)


func refresh_view() -> void:
	_place_world()
	if _hud != null:
		_hud.queue_redraw()


func _process(delta: float) -> void:
	if _taking_pictures:
		return
	if run.phase == RunLogic.Phase.PLAYING and logic.phase != KickLogic.Phase.RESULT:
		var direction := 0.0
		if Input.is_key_pressed(KEY_LEFT):
			direction -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			direction += 1.0
		if direction != 0.0:
			logic.aim(direction, delta)
		logic.advance(delta)
		settle_kick()
		if logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY:
			_approach_time += delta
	refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if _taking_pictures:
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_R and run.accepts_restart():
		restart_run()
		return
	if key.keycode != KEY_SPACE:
		return
	if run.phase != RunLogic.Phase.PLAYING:
		return
	if logic.phase == KickLogic.Phase.RESULT:
		settle_kick()
		advance_run()
		return
	logic.press_space()
	refresh_view()


func _style_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.64, 0.8, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.8, 0.9)
	env.ambient_light_energy = 0.7
	$WorldEnvironment.environment = env
	var sun := $Sun as DirectionalLight3D
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	_camera.fov = 52.0


func _build_field() -> void:
	_box(Vector3(54, 0.4, 100), Vector3(0, -0.2, 42), Color(0.28, 0.58, 0.26))
	var stripe := 0
	var z := -6.0
	while z < 88.0:
		var green := Color(0.34, 0.66, 0.3) if stripe % 2 == 0 else Color(0.27, 0.56, 0.25)
		_box(Vector3(50, 0.04, 5.0), Vector3(0, 0.02, z + 2.5), green)
		_box(Vector3(50, 0.05, 0.14), Vector3(0, 0.045, z), Color(0.93, 0.95, 0.92))
		stripe += 1
		z += 5.0
	var mark := 10
	while mark <= 70:
		_yard_sign(-18.0, float(mark), str(mark))
		_yard_sign(18.0, float(mark), str(mark))
		mark += 10


func _build_uprights() -> void:
	var half := KickConstants.POST_SEPARATION_YARDS * 0.5
	var yellow := Color(0.95, 0.82, 0.16)
	var crossbar_y := 3.33
	_box(Vector3(0.18, crossbar_y, 0.18), Vector3(0, crossbar_y * 0.5, 0), yellow)
	_box(Vector3(KickConstants.POST_SEPARATION_YARDS, 0.16, 0.16), Vector3(0, crossbar_y, 0), yellow)
	var upright_h := 9.0
	_box(Vector3(0.14, upright_h, 0.14), Vector3(-half, crossbar_y + upright_h * 0.5, 0), yellow)
	_box(Vector3(0.14, upright_h, 0.14), Vector3(half, crossbar_y + upright_h * 0.5, 0), yellow)


func _build_ball() -> void:
	var ball_mesh := SphereMesh.new()
	ball_mesh.radius = BALL_RADIUS
	ball_mesh.height = BALL_RADIUS * 2.0
	_ball = MeshInstance3D.new()
	_ball.mesh = ball_mesh
	_ball.material_override = _mat(Color(0.45, 0.24, 0.1), 0.55)
	_ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_world.add_child(_ball)
	var tee_mesh := CylinderMesh.new()
	tee_mesh.top_radius = 0.02
	tee_mesh.bottom_radius = 0.09
	tee_mesh.height = 0.16
	_tee = MeshInstance3D.new()
	_tee.mesh = tee_mesh
	_tee.material_override = _mat(Color(0.95, 0.42, 0.12), 0.7)
	_world.add_child(_tee)
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.28
	shadow_mesh.bottom_radius = 0.28
	shadow_mesh.height = 0.02
	_shadow = MeshInstance3D.new()
	_shadow.mesh = shadow_mesh
	var shade := _mat(Color(0.02, 0.05, 0.02), 1.0)
	shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shade.albedo_color.a = 0.35
	_shadow.material_override = shade
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(_shadow)
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.12, 0.03, 8.0)
	_arrow = MeshInstance3D.new()
	_arrow.mesh = shaft
	_arrow.material_override = _mat(Color(0.95, 0.95, 0.9), 0.4)
	_world.add_child(_arrow)


func _place_world() -> void:
	var tee := _tee_position()
	var spot := _ball_position()
	_ball.position = spot
	_tee.position = tee + Vector3(0, 0.08, 0)
	_tee.visible = logic.ball_forward_yards < 0.2
	_shadow.position = Vector3(spot.x, 0.05, spot.z)
	_place_arrow(tee)
	_place_camera()
	if _kicker != null and _kicker.has_method("follow"):
		_kicker.follow(tee, logic.phase, _approach_time, logic.flight_elapsed)


func _tee_position() -> Vector3:
	return Vector3(logic.start_lateral_yards, 0.0, logic.kick_distance)


func _ball_position() -> Vector3:
	var forward := logic.ball_forward_yards
	var lateral := logic.ball_lateral_yards
	var height := logic.ball_height * ARC_YARDS
	if logic.result_text == "DOINK" and (logic.phase == KickLogic.Phase.FLIGHT or logic.phase == KickLogic.Phase.RESULT):
		var span := maxf(logic.travel_yards, 0.001)
		var along := clampf((forward - span * 0.84) / (span * 0.16), 0.0, 1.0)
		forward -= along * 4.5
		var side := -1.0 if logic.offset_yards < 0.0 else 1.0
		lateral += side * along * 2.2
		height = logic.ball_height * ARC_YARDS * (1.0 - along) + sin(along * PI) * 2.4
	var y := BALL_RADIUS + height
	if forward < 0.05 and logic.phase != KickLogic.Phase.RESULT:
		y = 0.16 + BALL_RADIUS
	return Vector3(lateral, y, logic.kick_distance - forward)


func _place_arrow(tee: Vector3) -> void:
	var show := logic.phase == KickLogic.Phase.AIMING or logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY
	_arrow.visible = show
	if not show:
		return
	var aim := deg_to_rad(logic.aim_degrees)
	var dir := Vector3(sin(aim), 0.0, -cos(aim))
	_arrow.position = tee + dir * 4.6 + Vector3(0, 0.08, 0)
	if dir.length_squared() > 0.001:
		_arrow.look_at(_arrow.position + dir, Vector3.UP)


func _place_camera() -> void:
	var spot := logic.start_lateral_yards
	var dist := logic.kick_distance
	_camera.position = Vector3(spot - 0.35, 2.7, dist + 6.4)
	_camera.rotation_degrees = Vector3(-11.0, 0.0, 0.0)


func _yard_sign(x: float, z: float, label: String) -> void:
	var sign := Label3D.new()
	sign.text = label
	sign.font_size = 72
	sign.pixel_size = 0.022
	sign.modulate = Color(0.95, 0.96, 0.92)
	sign.outline_size = 12
	sign.outline_modulate = Color(0.05, 0.12, 0.05)
	sign.position = Vector3(x, 1.1, z)
	# Face the kicker so the number is not backwards.
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_world.add_child(sign)


func _box(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.position = pos
	body.material_override = _mat(color, 0.92)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(body)


func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	return mat
