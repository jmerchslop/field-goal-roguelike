extends Node3D

# Shows the kick in 3D and reads the keyboard.
# Kick rules live in KickLogic. The run lives in RunLogic.
# 1 unit = 1 yard. The goal line is Z = 0. The kicker stands on +Z and looks toward -Z.
# Negative sideways yards are -X, which is screen-left when you look up-field.

const ScreenshotDriverScript := preload("res://scripts/ScreenshotDriver.gd")
const ARC_YARDS := 6.4
const BALL_RADIUS := 0.18

var logic := KickLogic.new()
var run := RunLogic.new()
var _taking_pictures := false
var _approach_time := 0.0
var _bank_time := 0.0
var selecting := false
var showing_records := false
var front := FrontEnd.new()
var paused := false
var _twist_time := 0.0
var _twist_armed := false
var _clock_done := false
var _posts_judged := false
var pause_index := 0
var _checkpoint: Dictionary = {}
var save_note := ""
var _note_time := 0.0
var _trophy_time := 0.0
var _unlock_time := 0.0
var _unlock_seen := ""
var _frame_watch := 0.0
var _frame_peak := 0.0
var _cash_time := 0.0
var _vitamin_time := 0.0
var highlight := -1
var tad_picker_slot := -1
var meter_time := 0.0
var _pose := "idle"
var _run_time := 0.0
var _swing_time := 0.0
var _swing_from := 0.0
var _early_swing := false
var _swinging := false
var _sway_time := 0.0
var _power_press_queued := false

var _world: Node3D
var _camera: Camera3D
var _ball: Sprite3D
var _tee: MeshInstance3D
var _arrow: MeshInstance3D
var aim_corridor := {
	"visible": false,
	"origin": Vector3.ZERO,
	"far": Vector3.ZERO,
	"width": 0.0,
	"left": Vector3.ZERO,
	"right": Vector3.ZERO,
}
var _shadow: MeshInstance3D
var _shadow_mat: StandardMaterial3D
var _ball_edge: Sprite3D
var _ball_doinked := false
var _ball_doink_time := 0.0
var _ball_held := false
var _ball_hold_sy := 1.0
var _ball_hold_sx := 1.0
var _ball_hold_roll := 0.0
var _kicker_sprite: Sprite3D
var _post_l: MeshInstance3D
var _goal_stem: MeshInstance3D
var _post_r: MeshInstance3D
var _crossbar: MeshInstance3D
var _mud: MeshInstance3D
var _marks: Node3D
var _stands: Node3D
var _floods: Node3D
var _ring: Sprite3D
var _ring_pop := -1.0
var glare_time := 0.0
var _beams: Node3D
var _beam_mat: ShaderMaterial
var _pool_mat: ShaderMaterial
var _glare_mat: ShaderMaterial
var _skirt_mat: ShaderMaterial
var _beam_span := -1.0
var _beam_tee_x := 0.0
var _beam_tee_z := -1.0
var _stand_mats: Array[StandardMaterial3D] = []
var lights_look := {
	"on": false,
	"beams": 0,
	"sky": Color.WHITE,
	"stands": Color.WHITE,
	"breath_sec": BEAM_BREATH_SEC,
	"peak": BEAM_PEAK,
	"pool": BEAM_POOL,
}
var _sky_mat: ShaderMaterial
var sky_texture_path := ""
var _weather_anchor: Node3D
var _rain: GPUParticles3D
var _snow: GPUParticles3D
var weather_state := {
	"kind": "none",
	"amount": 0,
	"fall": 0.0,
	"dim": 1.0,
}
var grass_bounds := {
	"min_z": 0.0,
	"max_z": 0.0,
	"tile": GRASS_TILE_YARDS,
}
var _field_distance := -1.0
# Grass box is 54 yards wide. Painted sidelines sit at ±25. Stands sit just outside the grass.
const STAND_X := 27.45
const STAND_HEIGHT := 14.0
const STAND_TILE := 28.0
const STAND_BOWL_Z := -2.4
# Lamp underside sits on the 14-yard roof. Empty canvas padding is not steel.
const LIGHT_SIDE_PIXEL := 14.0 / 569.0
const LIGHT_END_PIXEL := 14.0 / 370.0
# The low kick camera looks up at a roof that is closer than the mast, so the
# lamps have to sit a little above the 14-yard wall or the stands swallow them.
const LIGHT_SIDE_LIFT := 0.95
const LIGHT_SIDE_OUT := 3.2
const LIGHT_END_BACK := 2.6
const LIGHT_SPACING := 90.0
# Lamp rows measured from the gantry art. The beam starts on the yellow faces.
const LAMP_SIDE_ROW := 429.0
const LAMP_END_ROW := 211.0
const LAMP_SIDE_CANVAS := 1024.0
const LAMP_END_CANVAS := 640.0
const LAMP_SIDE_FOOT := 1008.0
const LAMP_END_FOOT := 624.0
const BEAM_MAX := 8
const BEAM_BREATH_SEC := 2.0
const BEAM_BREATH := 0.15
const BEAM_PEAK := 0.30
const BEAM_POOL := 0.15
const BEAM_FADE_POW := 1.35
const GLARE_PEAK := 0.32
const GLARE_RADIUS := 2.0
const PLAY_HALF := 27.0
const PLAY_Z := -8.0
const CLEAR_EDGE := Color(0.64, 0.80, 0.95)
# About 35% darker than white, pulled toward cool navy. Stands are about 20% darker.
const DUSK_SKY := Color(0.58, 0.66, 0.82)
const DUSK_STAND := Color(0.78, 0.80, 0.84)
const LIGHT_SIDE_PATH := "res://art/field/floodlight-sideline.png"
const LIGHT_SIDE_B_PATH := "res://art/field/floodlight-sideline-b.png"
const LIGHT_END_PATH := "res://art/field/floodlight-endzone.png"
const RING_PATH := "res://art/field/bonus-coin.png"
const RING_PIXEL := 3.0 / 713.0
const RING_CENTER_Y := 5.33
const RING_POP_SEC := 0.25
const GRASS_TILE_YARDS := 12.0
const GRASS_PATH := "res://art/field/grass-tile.png"
const SKY_CLEAR_PATH := "res://art/field/sky-clear.png"
const SKY_OVERCAST_PATH := "res://art/field/sky-overcast.png"
const SUN_ENERGY := 1.25
const AMBIENT_ENERGY := 0.7
const OVERCAST_DIM := 0.74
const RAIN_PARTICLES := 360
const MONSOON_PARTICLES := 780
const SNOW_PARTICLES := 200
const RAIN_FALL := 16.0
const MONSOON_FALL := 28.0
const SNOW_FALL := 2.4
const _STAND_PATHS: Array[String] = [
	"res://art/field/crowd-stand-strip-a.png",
	"res://art/field/crowd-stand-strip-b.png",
	"res://art/field/crowd-stand-strip-c.png",
]
# Left A-C-B, right B-A-C, bowl A-B-C. Not mirrored.
const _STAND_LEFT: Array[int] = [0, 2, 1]
const _STAND_RIGHT: Array[int] = [1, 0, 2]
const _STAND_BOWL: Array[int] = [0, 1, 2]
var stand_bounds := {
	"min_z": 0.0,
	"max_z": 0.0,
	"x": STAND_X,
	"height": STAND_HEIGHT,
	"nodes": 0,
	"variants": 3,
}
# 0 is the real kick. 1..4 preview 75, 200, 500, 1000, then back to the real kick.
var _preview_step := 0
var too_weak_age := -1.0
var too_weak_flavor := ""
var too_weak_numbers := ""
var too_weak_debug := ""
var _too_weak_sounded := false
var result_age := 0.0
const _PREVIEW_DISTANCES: Array[float] = [75.0, 200.0, 500.0, 1000.0]
var _ribbon_l: MeshInstance3D
var _ribbon_r: MeshInstance3D
var _ribbon_time := 0.0
const _POST_TOP_Y := 13.33
const CONE_LENGTH_YARDS := 5.0
const CONE_MOUTH_YARDS := 0.12
const CONE_NEAR_HALF := 0.16
const TRAIL_POINT_CAP := 80
const TRAIL_FADE_SEC := 0.55
const TRAIL_WORLD_HALF := 0.028
const TRAIL_MIN_PIXELS := 3.2
# Visual only. Jordan can tune these without touching the kick.
const BALL_TEE_HEIGHT_YD := 0.65
const BALL_EDGE_ON := true
const BALL_EDGE_BRIGHTNESS := 0.45
const BALL_ART_LONG_PX := 17.0
const BALL_SHADOW_FALLOFF_YD := 3.0
const BALL_SHADOW_TEE_ALPHA := 0.35
const BALL_SHADOW_MIN_ALPHA := 0.12
const BALL_SHADOW_PEAK_YD := 6.4
const BALL_SHADOW_OVAL := 1.35
const BALL_TUMBLE_MIN := 0.62
const BALL_SPIN_MIN_RPS := 1.8
const BALL_SPIN_MAX_RPS := 3.6
const BALL_SPIN_OVERPOWER_RPS := 4.2
const BALL_ROLL_DEG := 6.0
const BALL_ROLL_HZ := 1.2
const BALL_SHANK_SPIN := 0.6
const BALL_SHANK_ROLL_DEG := 25.0
const BALL_SHANK_HZ_A := 2.3
const BALL_SHANK_HZ_B := 3.7
const BALL_SHANK_SX_MIN := 0.85
const BALL_DOINK_ROLL_DEG := 20.0
const BALL_DOINK_ROLL_SEC := 0.3
const BALL_SETTLE_SEC := 0.15
const BALL_POP := 0.20
const BALL_POP_PEAK_YD := 6.4
const BALL_MIN_PIXELS := 8.0
const BALL_MIN_REF_HEIGHT := 576.0
const BALL_TRAIL_START_YD := 0.12
const TRAIL_COLOR := Color(1.0, 0.93, 0.8, 1.0)
var _trail: MeshInstance3D
var _trail_points := PackedVector3Array()
var _trail_alpha := 1.0
var _trail_fade := 0.0
var _hud


func _ready() -> void:
	Loadout.print_sprite_map()
	logic.stats = run.stats
	_world = $World
	_camera = $Camera3D
	_hud = $HUD/Overlay
	_hud.game = self
	_style_world()
	_build_field()
	_build_uprights()
	_build_ball()
	_build_kicker_sprite()
	selecting = false
	front.screen = FrontEnd.Screen.TITLE
	highlight = -1
	_show_fresh_unlocks()
	get_tree().set_auto_accept_quit(false)
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
	_clear_trail()
	logic.reset_kick()
	_copy_run_onto_kick()
	if _preview_step > 0:
		logic.kick_distance = shown_distance()
	logic.sync_tee()
	_approach_time = 0.0
	_bank_time = 0.0
	_arm_boss_twist()
	if OS.is_debug_build() and OS.get_environment("FX1_FRAMES") == "1":
		_frame_watch = 1.0
		_frame_peak = 0.0
	consider_too_weak()
	refresh_view()


func _copy_run_onto_kick() -> void:
	logic.kick_distance = run.distance_yards()
	logic.start_lateral_yards = run.spot_yards
	run.prepare_kick_stats()
	logic.stats = run.stats
	logic.wind_speed = run.wind_speed
	logic.wind_direction = run.wind_direction
	logic.insurance_ready = run.insurance_left > 0
	logic.insured = false
	_copy_weather_onto_kick()
	logic.post_half_gap = run.post_half_gap()
	logic.hold_result = run.posts_move() and not run.practicing
	logic.heavy_ball = run.has_curse(Loadout.HEAVY)
	logic.howling_wind = run.has_curse(Loadout.HOWLING)
	logic.shaky = run.has_curse(Loadout.SHAKY)
	logic.angle_scale = run.stats.angle_scale
	logic.practice_swing = run.practicing
	meter_time = 0.0
	_reset_kick_pose()
	Sfx.begin_kick()
	_remember_run()


func settle_kick() -> void:
	if logic.phase == KickLogic.Phase.RESULT and not ResultStamp.hold_ready(result_age):
		return
	if _preview_step > 0 and logic.phase == KickLogic.Phase.RESULT:
		var dist := shown_distance()
		logic.reset_kick()
		logic.kick_distance = dist
		logic.start_lateral_yards = run.spot_yards
		logic.sync_tee()
		_reset_kick_pose()
		refresh_view()
		return
	if logic.phase != KickLogic.Phase.RESULT:
		return
	if run.kick_resolved or run.awaiting_mulligan or run.awaiting_offer:
		return
	if run.practicing:
		run.end_practice()
		load_current_kick()
		return
	if run.can_mulligan(logic.result_text):
		run.begin_mulligan(logic.result_text, logic.offset_yards, logic.perfect)
		return
	if logic.insured:
		run.consume_insurance()
	run.resolve_kick(logic.result_text, logic.offset_yards, logic.perfect)
	_cash_time = 0.0
	_finish_resolved_kick()


func _finish_resolved_kick() -> void:
	if run.ring_offer_pending:
		if run.open_ring_offer():
			_remember_run()
			return
		if run.phase == RunLogic.Phase.PLAYING:
			run.begin_retry()
			load_current_kick()
		return
	if run.wants_upgrade():
		run.roll_offer()
		_remember_run()
	elif run.phase == RunLogic.Phase.PLAYING:
		run.begin_retry()
		load_current_kick()


func retake_with_mulligan() -> void:
	if not run.use_mulligan():
		return
	_cue("mulligan")
	var distance := logic.kick_distance
	var spot := logic.start_lateral_yards
	logic.reset_kick()
	logic.kick_distance = distance
	logic.start_lateral_yards = spot
	_copy_run_onto_kick()
	logic.sync_tee()
	_approach_time = 0.0
	_bank_time = 0.0
	consider_too_weak()
	refresh_view()


func _cue(context: String) -> void:
	Sfx.cue(context)


func _sync_kick_audio(phase_before: int, forward_before: float) -> void:
	# Practice Swing uses this same path. It does not pick a different pool.
	var flying := logic.phase == KickLogic.Phase.FLIGHT or logic.phase == KickLogic.Phase.RESULT
	var was_meter := phase_before == KickLogic.Phase.AIMING or phase_before == KickLogic.Phase.POWER or phase_before == KickLogic.Phase.ACCURACY
	if was_meter and flying:
		Sfx.struck(logic.shanked, logic.accuracy_error, logic.stats.perfect_band, logic.stats.good_band, logic.perfect)
	var hits_post := logic.result_text == "DOINK" or logic.bank_shot
	if hits_post and forward_before < logic.kick_distance and logic.ball_forward_yards >= logic.kick_distance:
		Sfx.post()


func _choose_card(index: int) -> void:
	if not run.pick_card(index):
		return
	_cue("offer")
	_after_cards()


func _after_cards() -> void:
	if run.last_result_made:
		if run.follow_offer() == "shop":
			_remember_run()
			refresh_view()
			return
		advance_run()
	else:
		run.begin_retry()
		load_current_kick()
	refresh_view()


func _leave_shop() -> void:
	if not run.awaiting_shop:
		return
	run.leave_shop()
	if run.last_result_made:
		advance_run()
	refresh_view()


func confirm_kicker() -> void:
	_preview_step = 0
	var id := Kickers.id_for_slot(highlight)
	if id == "":
		return
	if not Kickers.is_unlocked(id):
		save_note = Kickers.unlock_hint(id)
		refresh_view()
		return
	tad_picker_slot = -1
	too_weak_debug = ""
	too_weak_age = -1.0
	selecting = false
	front.came_from_gate = false
	var mode := front.run_mode
	_cue("select")
	run.start_with_kicker(id)
	run.run_mode = mode
	var picked := 0
	if mode == "standard":
		picked = SaveData.tad_selected(id)
	run.open_tad(picked)
	front.screen = FrontEnd.Screen.PLAY
	_tint_ball()
	load_current_kick()


func tap_f9() -> void:
	save_note = SaveData.press_f9(Time.get_ticks_msec() / 1000.0)
	_note_time = 0.0
	refresh_view()


func open_select() -> void:
	selecting = true
	showing_records = false
	tad_picker_slot = -1
	front.screen = FrontEnd.Screen.SELECT
	highlight = 1
	_show_fresh_unlocks()
	refresh_view()


func _show_fresh_unlocks() -> void:
	if SaveData.fresh_unlocks.is_empty():
		return
	save_note = ", ".join(SaveData.fresh_unlocks)
	_note_time = 0.0


func _select_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var moved := event as InputEventMouseMotion
		var hover: int = _hud.kicker_slot_at(moved.position)
		if hover >= 0 and hover != highlight:
			highlight = hover
			tad_picker_slot = -1
			refresh_view()
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and (mouse.button_index == MOUSE_BUTTON_WHEEL_UP or mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if front.run_mode == "standard" and _hud.tad_wheel_at(mouse.position):
				var wheel := 1 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else -1
				_step_tad(wheel)
			return
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
			if tad_picker_slot >= 0:
				tad_picker_slot = -1
				refresh_view()
			return
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var nudged := int(_hud.tad_step_at(mouse.position))
			if nudged != 0 and tad_picker_slot == highlight:
				_step_tad(nudged)
				return
			_click_select_card(_hud.kicker_slot_at(mouse.position))
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_F9:
		tap_f9()
		return
	if Settings.pressed_event(event, "trophy"):
		showing_records = true
		front.records_return = FrontEnd.Screen.SELECT
		_cue("records")
		refresh_view()
		return
	if Settings.pressed_event(event, "back") and showing_records:
		showing_records = false
		_cue("records")
		refresh_view()
		return
	if Settings.pressed_event(event, "back") and not showing_records:
		if tad_picker_slot >= 0:
			tad_picker_slot = -1
			refresh_view()
			return
		_leave_character_select()
		return
	if showing_records:
		return
	if Settings.pressed_event(event, "choose_1"):
		_press_select_slot(0)
	elif Settings.pressed_event(event, "choose_2"):
		_press_select_slot(1)
	elif Settings.pressed_event(event, "choose_3"):
		_press_select_slot(2)
	elif key.keycode == KEY_4 or key.keycode == KEY_KP_4:
		_press_select_slot(3)
	elif key.keycode == KEY_5 or key.keycode == KEY_KP_5:
		_press_select_slot(4)
	elif key.keycode == KEY_6 or key.keycode == KEY_KP_6:
		_press_select_slot(5)
	elif key.keycode == KEY_7 or key.keycode == KEY_KP_7:
		_press_select_slot(6)
	elif key.keycode == KEY_8 or key.keycode == KEY_KP_8:
		_press_select_slot(7)
	elif key.keycode == KEY_LEFT or Settings.pressed_event(event, "menu_left"):
		highlight = SelectCard.step_highlight(highlight, -1, 0)
		tad_picker_slot = -1
		refresh_view()
	elif key.keycode == KEY_RIGHT or Settings.pressed_event(event, "menu_right"):
		highlight = SelectCard.step_highlight(highlight, 1, 0)
		tad_picker_slot = -1
		refresh_view()
	elif key.keycode == KEY_UP or Settings.pressed_event(event, "menu_up"):
		highlight = SelectCard.step_highlight(highlight, 0, -1)
		tad_picker_slot = -1
		refresh_view()
	elif key.keycode == KEY_DOWN or Settings.pressed_event(event, "menu_down"):
		highlight = SelectCard.step_highlight(highlight, 0, 1)
		tad_picker_slot = -1
		refresh_view()
	elif key.keycode == KEY_BRACKETLEFT:
		_step_tad(-1)
	elif key.keycode == KEY_BRACKETRIGHT:
		_step_tad(1)
	elif key.keycode == KEY_U and key.shift_pressed:
		_debug_tad(true)
	elif key.keycode == KEY_U:
		_debug_tad(false)
	elif Settings.pressed_event(event, "confirm"):
		_confirm_select()


func _press_select_slot(slot: int) -> void:
	if highlight != slot:
		highlight = slot
		tad_picker_slot = -1
		refresh_view()
		return
	_confirm_select()


func _click_select_card(slot: int) -> void:
	if slot < 0:
		return
	var previous := highlight
	highlight = slot
	var id := Kickers.id_for_slot(slot)
	if id == "" or not Kickers.is_unlocked(id):
		tad_picker_slot = -1
		confirm_kicker()
		return
	if front.run_mode != "standard" or SaveData.tad_unlocked(id) < 1:
		tad_picker_slot = -1
		if previous == slot:
			confirm_kicker()
		else:
			refresh_view()
		return
	if tad_picker_slot == slot and previous == slot:
		confirm_kicker()
		return
	tad_picker_slot = slot
	refresh_view()


func _confirm_select() -> void:
	var id := Kickers.id_for_slot(highlight)
	if id == "" or not Kickers.is_unlocked(id):
		tad_picker_slot = -1
		confirm_kicker()
		return
	if front.run_mode != "standard" or SaveData.tad_unlocked(id) < 1:
		tad_picker_slot = -1
		confirm_kicker()
		return
	if tad_picker_slot == highlight:
		confirm_kicker()
		return
	tad_picker_slot = highlight
	refresh_view()


func _step_tad(delta: int) -> void:
	if front.run_mode != "standard" or highlight < 0 or tad_picker_slot != highlight:
		return
	var id := Kickers.id_for_slot(highlight)
	if id == "" or not Kickers.is_unlocked(id):
		return
	SaveData.set_tad_selected(id, SaveData.tad_selected(id) + delta)
	refresh_view()


func _debug_tad(clear: bool) -> void:
	if highlight < 0:
		return
	var id := Kickers.id_for_slot(highlight)
	if id == "" or not Kickers.is_unlocked(id):
		return
	if clear:
		SaveData.debug_clear_tad(id)
		save_note = "TAD 0 DEBUG"
	else:
		var cap := SaveData.debug_raise_tad(id)
		if cap < 0:
			return
		save_note = "TAD %d DEBUG" % cap
	_note_time = 0.0
	refresh_view()


func _tint_ball() -> void:
	var info := Kickers.get_def(run.kicker_id)
	var ink := Color(0.45, 0.24, 0.1)
	if not info.is_empty():
		ink = info["color"]
	if _ball != null:
		_ball.modulate = ink.lerp(Color(0.72, 0.42, 0.18), 0.45)


func _apply_ball_sprite() -> void:
	if _ball == null:
		return
	var place := "tee"
	if logic.phase == KickLogic.Phase.FLIGHT or logic.phase == KickLogic.Phase.RESULT:
		place = "air"
	var path := Kickers.ball_sprite(run.kicker_id, place)
	var custom := path != ""
	if path == "":
		path = "res://art/field/football.png"
	if str(_ball.get_meta("art_path", "")) != path:
		_fit_sprite(_ball, path)
		_ball.set_meta("art_path", path)
	if custom:
		_ball.modulate = Color(1, 1, 1, 1)
	else:
		_tint_ball()
	_sync_ball_edge()


func advance_run() -> bool:
	if not run.go_to_next_kick():
		return false
	load_current_kick()
	return true


func restart_run() -> void:
	_preview_step = 0
	var id := run.kicker_id
	if id == "":
		open_select()
		return
	run.start_with_kicker(id)
	_tint_ball()
	load_current_kick()


func force_spot_side(side: int) -> void:
	run.set_next_side(side)


func force_weather(name: String) -> void:
	run.force_weather(name)
	_apply_conditions()
	logic.hold_result = run.posts_move() and not run.practicing
	_arm_boss_twist()
	consider_too_weak()
	refresh_view()


func _too_weak_blocked() -> bool:
	return paused or selecting or showing_records or _preview_step > 0


func consider_too_weak() -> void:
	if too_weak_age >= 0.0 or run.phase != RunLogic.Phase.PLAYING:
		return
	var report := run.too_weak_report(logic, _too_weak_blocked())
	if not bool(report["too_weak"]):
		return
	too_weak_age = 0.0
	too_weak_debug = ""
	too_weak_flavor = run.too_weak_flavor()
	too_weak_numbers = RunLogic.too_weak_numbers(float(report["best_case"]), float(report["required"]))
	_too_weak_sounded = false
	# Hold KICK CLOCK. The countdown must not start the meter under the stamp.
	_twist_armed = false
	_clock_done = false


func _finish_too_weak() -> void:
	if run.end_reason == "too_weak" and run.phase != RunLogic.Phase.PLAYING:
		too_weak_age = -1.0
		return
	too_weak_age = -1.0
	run.end_too_weak()
	refresh_view()


func _debug_too_weak_text(report: Dictionary) -> String:
	var zinc := "yes" if bool(report["zinc_block"]) else "no"
	var clearance := "yes" if bool(report["clearance"]) else "no"
	var weak := "yes" if bool(report["too_weak"]) else "no"
	return "base %s  overpower %s  shakes %s  vitamin d %s  walk-on %s\nzinc %s  clearance %s  required %s  too weak %s" % [
		KickLogic.format_number(float(report["base"])),
		KickLogic.format_number(float(report["overpower"])),
		KickLogic.format_number(float(report["shakes"])),
		KickLogic.format_number(float(report["vitamin_d"])),
		KickLogic.format_number(float(report["walk_on"])),
		zinc,
		clearance,
		KickLogic.format_number(float(report["required"])),
		weak,
	]


func debug_too_weak(shift: bool) -> void:
	if run.phase != RunLogic.Phase.PLAYING or logic.phase != KickLogic.Phase.AIMING or run.practicing or _preview_step > 0:
		return
	if shift:
		var report := run.too_weak_report(logic, _too_weak_blocked())
		too_weak_debug = _debug_too_weak_text(report)
		print("TW1 ", too_weak_debug.replace("\n", " | "))
		refresh_view()
		return
	var before := run.too_weak_report(logic, false)
	logic.kick_distance = float(before["best_case"]) + 10.0
	logic.sync_tee()
	consider_too_weak()
	refresh_view()


func cycle_spot() -> void:
	run.cycle_debug_spot()
	logic.start_lateral_yards = run.spot_yards
	logic.sync_tee()
	refresh_view()


func preview_step() -> int:
	return _preview_step


func shown_distance() -> float:
	if _preview_step <= 0:
		return run.distance_yards()
	return _PREVIEW_DISTANCES[_preview_step - 1]


func hash_row_half() -> float:
	# Same x as a normal upright. Squeeze and Narrow Posts do not move the hashes.
	return KickConstants.POST_SEPARATION_YARDS * 0.5


func cycle_debug_distance() -> void:
	# J previews a distance. It does not spend an attempt or rewrite the kick.
	var attempts := run.attempts
	var kick_number := run.kick_number
	var saved := run.distance_yards()
	_preview_step = (_preview_step + 1) % 5
	if logic.phase != KickLogic.Phase.AIMING:
		logic.reset_kick()
	logic.kick_distance = saved if _preview_step == 0 else shown_distance()
	logic.start_lateral_yards = run.spot_yards
	logic.sync_tee()
	if run.attempts != attempts or run.kick_number != kick_number or not is_equal_approx(run.distance_yards(), saved):
		run.attempts = attempts
		run.kick_number = kick_number
	consider_too_weak()
	refresh_view()


func camera_rig(distance: float, spot: float) -> Dictionary:
	# Up through 75 yards this is the pull-back the game already used, so a
	# Standard kick still frames the kicker and the posts the same way.
	# Farther kicks keep a real tee-to-posts gap. The camera eases its extra
	# step-back and narrows a little so 200, 500, and 1000 each look farther
	# than the last, and the uprights stay thick enough to see.
	# The look point stays on the tee's line. The posts are not pulled to center.
	var dist := KickLogic.visual_span(distance)
	var extra := 0.0
	if dist > 48.0:
		extra = (dist - 48.0) * 0.11
	if dist > 75.0:
		var at_75 := (75.0 - 48.0) * 0.11
		extra = at_75 + (dist - 75.0) * 0.035
	var back := 6.4 + extra
	var height := 3.05 + extra * 0.22
	var fov := 58.0
	var pole := 0.16
	var look_y := 1.05
	var look_z := maxf(dist - 14.0, 0.0)
	if dist > 75.0:
		# Ease the zoom so the uprights stay a goal, and keep looking near the
		# tee so the kicker does not fall out of the bottom of a long kick.
		var dist_to_posts := dist + back
		fov = clampf(58.0 - (dist - 75.0) * 0.028, 32.0, 58.0)
		var h_fov := 2.0 * atan(tan(deg_to_rad(fov) * 0.5) * KickConstants.WINDOW_WIDTH / KickConstants.WINDOW_HEIGHT)
		pole = maxf(0.16, 4.0 * h_fov * dist_to_posts / KickConstants.WINDOW_WIDTH)
		pole = minf(pole, KickConstants.POST_SEPARATION_YARDS * 0.28)
	return {
		"position": Vector3(spot - 0.05, height, dist + back),
		"look": Vector3(spot, look_y, look_z),
		"span": dist,
		"fov": fov,
		"pole": pole,
	}


func _sync_debug_loadout() -> void:
	var aim := logic.aim_degrees
	var phase = logic.phase
	run.prepare_kick_stats()
	logic.stats = run.stats
	logic.wind_speed = run.wind_speed
	logic.wind_direction = run.wind_direction
	logic.howling_wind = run.has_curse(Loadout.HOWLING)
	logic.heavy_ball = run.has_curse(Loadout.HEAVY)
	logic.shaky = run.has_curse(Loadout.SHAKY)
	logic.angle_scale = run.stats.angle_scale
	logic.practice_swing = run.practicing
	logic.aim_degrees = aim
	logic.phase = phase
	_copy_weather_onto_kick()
	logic.post_half_gap = run.post_half_gap()
	consider_too_weak()
	refresh_view()


func apply_live_vitamins() -> void:
	var aim := logic.aim_degrees
	var phase = logic.phase
	run.prepare_kick_stats()
	logic.stats = run.stats
	logic.wind_speed = run.wind_speed
	logic.wind_direction = run.wind_direction
	_copy_weather_onto_kick()
	logic.aim_degrees = aim
	logic.phase = phase
	logic.post_half_gap = run.post_half_gap()
	consider_too_weak()
	refresh_view()


func _copy_weather_onto_kick() -> void:
	var flags: Dictionary = run.weather_flags_now()
	logic.rain_faster = bool(flags["rain_faster"])
	logic.rain_scale = float(flags["rain_scale"])
	logic.snow_range = bool(flags["snow_range"])
	logic.snow_penalty = float(flags["snow_penalty"])
	logic.mud_power = bool(flags["mud_power"])
	logic.mud_span = float(flags["mud_span"])
	logic.thin_air_weather = run.weather == RunLogic.THIN_AIR


func _apply_conditions() -> void:
	run.prepare_kick_stats()
	logic.stats = run.stats
	_copy_weather_onto_kick()
	logic.post_half_gap = run.post_half_gap()
	logic.hold_result = run.posts_move() and not run.practicing
	logic.heavy_ball = run.has_curse(Loadout.HEAVY)
	logic.howling_wind = run.has_curse(Loadout.HOWLING)
	logic.shaky = run.has_curse(Loadout.SHAKY)
	logic.angle_scale = run.stats.angle_scale
	logic.practice_swing = run.practicing


func set_wind(speed: float, direction: float) -> void:
	run.set_wind(speed, direction)
	logic.wind_speed = run.wind_speed
	logic.wind_direction = run.wind_direction


func play_locked_kick(power_value: float) -> void:
	logic.press_space()
	if logic.windup_left > 0.0:
		logic.advance(logic.windup_left)
	if power_value >= KickConstants.METER_MAX - 0.001:
		logic.take_power_press(logic.seconds_to_power(power_value))
	else:
		logic.advance(logic.seconds_to_power(power_value))
		if logic.phase == KickLogic.Phase.POWER:
			logic.press_space()
	if logic.phase == KickLogic.Phase.ACCURACY:
		var wait := logic.seconds_until_error(0.0)
		if wait > 0.0:
			logic.advance(wait)
		if logic.phase == KickLogic.Phase.ACCURACY:
			logic.press_space()
	if logic.phase == KickLogic.Phase.FLIGHT:
		logic.advance(logic.flight_duration)


func script_good_kick() -> void:
	run.resolve_kick("GOOD", 0.0, false)
	_cash_time = 0.0


func refresh_view() -> void:
	_place_world()
	if _hud != null:
		if selecting:
			_hud.layout_select_chrome()
		else:
			_hud.clear_tad_picker()
		_hud.queue_redraw()


func _process(delta: float) -> void:
	Sfx.tick(delta)
	if not _taking_pictures:
		if save_note != "":
			_note_time += delta
			if _note_time >= 2.0:
				save_note = ""
				_note_time = 0.0
		if run.trophy_name != "":
			_trophy_time += delta
			if _trophy_time >= 2.0:
				run.trophy_name = ""
				_trophy_time = 0.0
		elif _trophy_time != 0.0:
			_trophy_time = 0.0
		if run.cash_popup != "":
			_cash_time += delta
			if _cash_time >= 1.6:
				run.cash_popup = ""
				_cash_time = 0.0
		if run.vitamin_note != "":
			_vitamin_time += delta
			if _vitamin_time >= 1.6:
				run.vitamin_note = ""
				_vitamin_time = 0.0
		if run.unlock_toast != _unlock_seen:
			_unlock_seen = run.unlock_toast
			_unlock_time = 0.0
		if run.unlock_toast != "" and not paused and not run.awaiting_shop:
			_unlock_time += delta
			if _unlock_time >= 4.0:
				run.unlock_toast = ""
				_unlock_seen = ""
				_unlock_time = 0.0
	if OS.is_debug_build() and OS.get_environment("FX1_FRAMES") == "1" and _frame_watch > 0.0:
		_frame_peak = maxf(_frame_peak, delta)
		_frame_watch -= delta
		if _frame_watch <= 0.0:
			print("FX1 kick frame peak_ms ", snappedf(_frame_peak * 1000.0, 0.1), " weather ", run.weather)
	if _taking_pictures:
		return
	front.tick(delta)
	if front.screen == FrontEnd.Screen.TITLE or front.screen == FrontEnd.Screen.MAIN or front.screen == FrontEnd.Screen.OPTIONS or front.screen == FrontEnd.Screen.RECORDS or selecting:
		refresh_view()
		return
	if paused:
		refresh_view()
		return
	if logic.phase == KickLogic.Phase.RESULT:
		result_age += delta
	else:
		result_age = 0.0
	if too_weak_age >= 0.0:
		too_weak_age += delta
		if too_weak_age >= RunLogic.TOO_WEAK_BEAT and not _too_weak_sounded:
			_too_weak_sounded = true
			Sfx.play_pool("shank")
		if too_weak_age >= RunLogic.TOO_WEAK_BEAT + RunLogic.TOO_WEAK_HOLD:
			_finish_too_weak()
			return
		refresh_view()
		return
	if logic.phase != KickLogic.Phase.AIMING:
		meter_time += delta
	_sway_time += delta
	_ribbon_time += delta
	logic.sway(_sway_time)
	_place_ribbons()
	if lights_show():
		glare_time += delta
	_pulse_floodlights()
	_tick_ring(delta)
	_step_kick_pose(delta)
	if _pose == "run":
		Sfx.approach()
	var phase_before := logic.phase
	var forward_before := logic.ball_forward_yards
	if logic.bank_shot and logic.phase == KickLogic.Phase.RESULT and _bank_time < 0.3:
		_bank_time += delta
	if run.phase == RunLogic.Phase.PLAYING and logic.phase != KickLogic.Phase.RESULT:
		var direction := 0.0
		if Settings.held("aim_left"):
			direction -= 1.0
		if Settings.held("aim_right"):
			direction += 1.0
		if direction != 0.0:
			logic.aim(direction, delta)
		tick_kick_clock(delta)
		if _power_press_queued and logic.phase == KickLogic.Phase.POWER and logic.windup_left <= 0.0000001:
			_power_press_queued = false
			logic.take_power_press(delta)
		else:
			_power_press_queued = false
			var forward_at := logic.ball_forward_yards
			logic.advance(delta)
			tick_moving_posts(forward_at, logic.ball_forward_yards, delta)
		_sync_kick_audio(phase_before, forward_before)
		if logic.insured:
			run.consume_insurance()
		if phase_before != KickLogic.Phase.RESULT and logic.phase == KickLogic.Phase.RESULT:
			_step_kick_pose(0.0)
		settle_kick()
		if logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY:
			_approach_time += delta
	tick_trail(delta)
	refresh_view()


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	if _active_run() and not _taking_pictures:
		_write_quit_slot()
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if _taking_pictures:
		return
	if paused:
		_pause_input(event)
		return
	if _active_run() and _is_back(event):
		_open_pause()
		return
	if too_weak_age >= 0.0:
		var skip := _is_confirm(event)
		if event is InputEventMouseButton:
			var click := event as InputEventMouseButton
			skip = click.pressed and click.button_index == MOUSE_BUTTON_LEFT
		if skip:
			_finish_too_weak()
		return
	if _front_input(event):
		return
	if selecting:
		_select_input(event)
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			if run.awaiting_shop:
				_shop_click(mouse.position)
			elif run.awaiting_offer:
				_choose_card(_hud.card_index_at(mouse.position))
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if Settings.pressed_event(event, "back") and showing_records:
		showing_records = false
		refresh_view()
		return
	if Settings.pressed_event(event, "trophy") and (run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN):
		showing_records = true
		front.records_return = FrontEnd.Screen.PLAY
		_cue("records")
		refresh_view()
		return
	if Settings.pressed_event(event, "back") and (run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN or run.phase == RunLogic.Phase.FAR) and not showing_records:
		_cue("menu")
		_return_to_main_menu()
		return
	if Settings.pressed_event(event, "confirm") and run.phase == RunLogic.Phase.FAR:
		_cue("menu")
		_return_to_main_menu()
		return
	# R still returns to character select. It is not the offer-reroll action.
	if key.keycode == KEY_R and run.accepts_restart() and not run.awaiting_offer and not run.awaiting_mulligan and not showing_records:
		_cue("select")
		open_select()
		return
	if key.keycode == KEY_M and run.awaiting_mulligan:
		retake_with_mulligan()
		return
	if run.curse_prompt:
		if Settings.pressed_event(event, "back"):
			run.cancel_curse_prompt()
			_cue("curse")
			refresh_view()
		elif Settings.pressed_event(event, "choose_1"):
			if run.pick_curse_removal(0):
				_cue("curse")
				apply_live_vitamins()
		elif Settings.pressed_event(event, "choose_2"):
			if run.pick_curse_removal(1):
				_cue("curse")
				apply_live_vitamins()
		return
	if run.awaiting_shop:
		_shop_input(event)
		return
	if run.awaiting_offer and Settings.pressed_event(event, "choose_1"):
		_choose_card(0)
		return
	if run.awaiting_offer and Settings.pressed_event(event, "choose_2"):
		_choose_card(1)
		return
	if run.awaiting_offer and Settings.pressed_event(event, "choose_3"):
		_choose_card(2)
		return
	if run.awaiting_offer and Settings.pressed_event(event, "skip"):
		if run.skip_offer():
			_cue("offer")
			_after_cards()
		return
	if run.awaiting_offer and Settings.pressed_event(event, "offer_reroll"):
		if run.reroll_offer():
			_cue("offer")
		refresh_view()
		return
	if key.shift_pressed and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan:
		var forced := _shift_weather(key.keycode)
		if forced != "":
			force_weather(forced)
			return
	if not key.shift_pressed and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan and not run.awaiting_shop:
		var boss := _boss_force_key(key.keycode)
		if boss != "":
			force_weather(boss)
			return
	if key.keycode == KEY_Y and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan and logic.phase == KickLogic.Phase.AIMING and not run.practicing:
		debug_too_weak(key.shift_pressed)
		return
	if key.keycode == KEY_V and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan and logic.phase == KickLogic.Phase.AIMING and not run.practicing:
		var note := run.debug_pk2(key.shift_pressed)
		if note != "":
			run.vitamin_note = note
			_vitamin_time = 0.0
		_sync_debug_loadout()
		return
	if key.keycode == KEY_B and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan and logic.phase == KickLogic.Phase.AIMING and not run.practicing:
		if run.arm_debug_ring():
			refresh_view()
		return
	if key.keycode == KEY_H and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan:
		cycle_spot()
		return
	if key.keycode == KEY_J and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan and logic.phase == KickLogic.Phase.AIMING:
		cycle_debug_distance()
		return
	if key.keycode == KEY_K and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan:
		run.cycle_range_fixture()
		_sync_debug_loadout()
		return
	if key.keycode == KEY_L and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan:
		if key.shift_pressed:
			run.bump_style_fixture()
		else:
			run.cycle_style_fixture()
		_sync_debug_loadout()
		return
	if key.keycode == KEY_W and run.phase == RunLogic.Phase.PLAYING and not run.awaiting_offer and not run.awaiting_mulligan:
		run.apply_debug_wind()
		logic.wind_speed = run.wind_speed
		logic.wind_direction = run.wind_direction
		consider_too_weak()
		refresh_view()
		return
	if Settings.pressed_event(event, "practice") and logic.phase == KickLogic.Phase.AIMING and not run.awaiting_offer and not run.awaiting_mulligan:
		if run.start_practice():
			_apply_conditions()
			refresh_view()
		return
	if logic.phase == KickLogic.Phase.AIMING and not run.practicing and not run.awaiting_offer and not run.awaiting_mulligan:
		if Settings.pressed_event(event, "belt_z") and run.use_belt(0):
			_vitamin_time = 0.0
			_cue("belt")
			apply_live_vitamins()
			return
		if Settings.pressed_event(event, "belt_x") and run.use_belt(1):
			_vitamin_time = 0.0
			_cue("belt")
			apply_live_vitamins()
			return
		if key.keycode == KEY_C:
			run.add_debug_cash()
			_cash_time = 0.0
			consider_too_weak()
			refresh_view()
			return
	if not Settings.pressed_event(event, "confirm"):
		return
	_confirm_kick()


func _confirm_kick() -> void:
	if too_weak_age >= 0.0:
		return
	if run.awaiting_mulligan:
		run.accept_pending_miss()
		_cue("mulligan")
		_finish_resolved_kick()
		refresh_view()
		return
	if run.awaiting_offer:
		return
	if run.phase != RunLogic.Phase.PLAYING:
		return
	if logic.phase == KickLogic.Phase.RESULT:
		settle_kick()
		refresh_view()
		return
	if logic.phase == KickLogic.Phase.POWER and logic.windup_left <= 0.0000001:
		# Resolved in _process with this frame's delta, so a press on the
		# step that reaches MAX locks P=100 instead of shanking.
		_power_press_queued = true
		refresh_view()
		return
	# Input runs before _process. A Space #3 lock (and a practice swing) is
	# already FLIGHT by the time the frame samples the phase, so the contact
	# and airborne cues have to be read from the phase before the press.
	var phase_before := logic.phase
	var forward_before := logic.ball_forward_yards
	if phase_before == KickLogic.Phase.AIMING:
		_clock_done = true
	logic.press_space()
	_sync_kick_audio(phase_before, forward_before)
	if logic.insured:
		run.consume_insurance()
	refresh_view()


func _boss_force_key(code: Key) -> String:
	if code == KEY_N:
		return RunLogic.CLOCK
	if code == KEY_G:
		return RunLogic.MOVING
	return ""


func _twist_blocked() -> bool:
	if paused or selecting or showing_records:
		return true
	if run.awaiting_offer or run.awaiting_shop or run.awaiting_mulligan or run.curse_prompt:
		return true
	if front.screen != FrontEnd.Screen.PLAY:
		return true
	if run.phase != RunLogic.Phase.PLAYING:
		return true
	return false


func _arm_boss_twist() -> void:
	_twist_time = 0.0
	_clock_done = false
	_posts_judged = false
	var clock := run.clock_seconds() > 0.0 and not run.practicing
	# Practice used to hold the posts still. TAD 10 keeps the sine through that swing.
	var moving := run.posts_move() and (not run.practicing or run.tad_active(10))
	_twist_armed = (clock or moving) and logic.phase == KickLogic.Phase.AIMING
	_apply_post_slide()


func clock_digit() -> int:
	if too_weak_age >= 0.0:
		return 0
	var seconds := run.clock_seconds()
	if seconds <= 0.0 or run.practicing or not _twist_armed or _clock_done:
		return 0
	if logic.phase != KickLogic.Phase.AIMING:
		return 0
	var left := seconds - _twist_time
	if left <= 0.001:
		return 0
	return ceili(left)


func tick_kick_clock(delta: float) -> void:
	# TOO WEAK holds whichever clock is up, Kick Clock or No Huddle.
	if too_weak_age >= 0.0:
		return
	if _twist_blocked() or run.practicing or not _twist_armed or _clock_done:
		return
	var seconds := run.clock_seconds()
	if seconds <= 0.0 or logic.phase != KickLogic.Phase.AIMING:
		return
	var remain := seconds - _twist_time
	if delta + 0.0000001 >= remain:
		_twist_time = seconds
		_clock_done = true
		_confirm_kick()
		return
	_twist_time += delta


func tick_moving_posts(before: float, after: float, delta: float) -> void:
	if run.practicing and not run.tad_active(10):
		_apply_post_slide()
		return
	if _twist_blocked() or not run.posts_move() or not _twist_armed:
		return
	var live := logic.phase == KickLogic.Phase.AIMING or logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY or logic.phase == KickLogic.Phase.FLIGHT or logic.phase == KickLogic.Phase.RESULT
	if not live:
		return
	# Sample before a result snaps the uprights home. The crossing can land
	# in the same frame that ends the flight.
	note_goal_line(before, after, delta)
	if logic.phase == KickLogic.Phase.RESULT:
		_twist_armed = false
		_apply_post_slide()
		return
	_twist_time += delta
	_apply_post_slide()


func note_goal_line(before: float, after: float, frame_delta: float) -> void:
	if _posts_judged or not run.posts_move() or run.practicing:
		return
	if logic.kick_distance <= 0.0 or before >= logic.kick_distance or after < logic.kick_distance:
		return
	var frac := 0.0
	if after > before:
		frac = clampf((logic.kick_distance - before) / (after - before), 0.0, 1.0)
	var saved := _twist_time
	_twist_time = saved + frame_delta * frac
	_place_posts(RunLogic.post_slide(_twist_time))
	score_posts_now()
	_posts_judged = true
	_twist_time = saved


func score_posts_now() -> void:
	if _post_l == null or _post_r == null:
		return
	var center := (_post_l.position.x + _post_r.position.x) * 0.5
	var half := absf(_post_r.position.x - _post_l.position.x) * 0.5
	logic.score_at_posts(center, half)


func _posts_sliding() -> bool:
	if not run.posts_move() or not _twist_armed:
		return false
	if run.practicing and not run.tad_active(10):
		return false
	return logic.phase == KickLogic.Phase.AIMING or logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY or logic.phase == KickLogic.Phase.FLIGHT


func _apply_post_slide() -> void:
	var slide := RunLogic.post_slide(_twist_time) if _posts_sliding() else 0.0
	_place_posts(slide)


func _place_posts(slide: float) -> void:
	var half := run.post_width() * 0.5
	if _post_l != null:
		_post_l.position.x = -half + slide
	if _post_r != null:
		_post_r.position.x = half + slide
	if _crossbar != null:
		_crossbar.position.x = slide
	if _goal_stem != null:
		_goal_stem.position.x = slide


func _active_run() -> bool:
	if paused or selecting or showing_records:
		return false
	if front.screen != FrontEnd.Screen.PLAY:
		return false
	return run.phase == RunLogic.Phase.PLAYING


func _is_back(event: InputEvent) -> bool:
	return event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and Settings.pressed_event(event, "back")


func _is_confirm(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return false
	return Settings.pressed_event(event, "confirm") or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER


func _open_pause() -> void:
	paused = true
	pause_index = 0
	refresh_view()


func _resume_pause() -> void:
	paused = false
	refresh_view()


func _remember_run() -> void:
	if run.kicker_id == "" or run.phase != RunLogic.Phase.PLAYING:
		return
	_checkpoint = run.export_resume()
	if _taking_pictures:
		return
	SaveData.write_run_slot(run.run_mode, _checkpoint)


func _resume_payload() -> Dictionary:
	if run.awaiting_shop or run.awaiting_offer or run.kick_resolved:
		return run.export_resume()
	if logic.phase != KickLogic.Phase.AIMING and not _checkpoint.is_empty():
		return _checkpoint.duplicate(true)
	return run.export_resume()


func _write_quit_slot() -> void:
	if run.kicker_id == "" or (run.run_mode != "standard" and run.run_mode != "endless"):
		return
	SaveData.write_run_slot(run.run_mode, _resume_payload())


func _save_and_quit() -> void:
	_write_quit_slot()
	_return_to_main_menu()


func _continue_mode(mode: String) -> void:
	var data := SaveData.run_slot(mode)
	if str(data.get("kicker_id", "")) == "":
		return
	run.import_resume(data)
	paused = false
	selecting = false
	showing_records = false
	front.gate = ""
	front.came_from_gate = false
	front.screen = FrontEnd.Screen.PLAY
	front.run_mode = run.run_mode
	_preview_step = 0
	_tint_ball()
	load_current_kick()


func _leave_character_select() -> void:
	selecting = false
	if front.came_from_gate:
		front.came_from_gate = false
		front.screen = FrontEnd.Screen.MAIN
		front.gate = "choose"
		front.gate_index = 0
	else:
		front.back_select()
	_cue("select")
	refresh_view()


func _start_new_run() -> void:
	front.gate = ""
	front.came_from_gate = true
	selecting = true
	highlight = 1
	showing_records = false
	front.screen = FrontEnd.Screen.SELECT
	refresh_view()


func _keep_saved_run() -> void:
	front.gate = "choose"
	front.gate_index = 0
	refresh_view()


func _pause_input(event: InputEvent) -> void:
	if _is_back(event):
		_resume_pause()
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var hit: int = _hud.pause_hit(mouse.position)
			if hit >= 0:
				pause_index = hit
				_activate_pause()
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if Settings.pressed_event(event, "menu_up") or Settings.pressed_event(event, "menu_left"):
		pause_index = 0
	elif Settings.pressed_event(event, "menu_down") or Settings.pressed_event(event, "menu_right"):
		pause_index = 1
	elif _is_confirm(event):
		_activate_pause()
	refresh_view()


func _activate_pause() -> void:
	if pause_index == 0:
		_resume_pause()
	else:
		_save_and_quit()


func _gate_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var hit: int = _hud.gate_hit(mouse.position, front.gate)
			if hit >= 0:
				front.gate_index = hit
				_activate_gate()
		return
	if not _is_key(event):
		return
	if _is_back(event):
		if front.gate == "confirm":
			_keep_saved_run()
		else:
			front.gate = ""
			refresh_view()
		return
	if Settings.pressed_event(event, "menu_up") or Settings.pressed_event(event, "menu_left"):
		front.gate_index = 0
	elif Settings.pressed_event(event, "menu_down") or Settings.pressed_event(event, "menu_right"):
		front.gate_index = 1
	elif _is_confirm(event):
		_activate_gate()
		return
	refresh_view()


func _activate_gate() -> void:
	if front.gate == "choose":
		if front.gate_index == 0:
			_continue_mode(front.run_mode)
		else:
			front.gate = "confirm"
			front.gate_index = 0
			refresh_view()
		return
	if front.gate_index == 0:
		_start_new_run()
	else:
		_keep_saved_run()


func _is_key(event: InputEvent) -> bool:
	return event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo


func _return_to_main_menu() -> void:
	selecting = false
	showing_records = false
	paused = false
	front.screen = FrontEnd.Screen.MAIN
	front.menu_index = 0
	front.gate = ""
	front.came_from_gate = false
	front.lock_message = ""
	refresh_view()


func _front_input(event: InputEvent) -> bool:
	var mode := front.screen
	if mode != FrontEnd.Screen.TITLE and mode != FrontEnd.Screen.MAIN and mode != FrontEnd.Screen.OPTIONS and mode != FrontEnd.Screen.RECORDS:
		return false
	if mode == FrontEnd.Screen.MAIN and front.gate != "":
		_gate_input(event)
		return true
	if event is InputEventMouseMotion and mode == FrontEnd.Screen.MAIN:
		var tile := MenuLayout.tile_at(event.position, _hud._menu_window())
		if tile >= 0:
			front.hover_menu(tile)
			refresh_view()
		return true
	if event is InputEventMouseMotion and mode == FrontEnd.Screen.OPTIONS:
		_options_hover(event.position)
		if front.dragging != "":
			_drag_slider(event.position)
		return true
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return true
		if mode == FrontEnd.Screen.TITLE and mouse.pressed:
			front.confirm_title()
			_cue("menu")
			refresh_view()
		elif mode == FrontEnd.Screen.MAIN and mouse.pressed:
			var tile := MenuLayout.tile_at(mouse.position, _hud._menu_window())
			if tile == front.menu_index and tile >= 0:
				_apply_menu_choice(front.confirm_menu())
				_cue("menu")
			elif tile >= 0:
				front.hover_menu(tile)
			refresh_view()
		elif mode == FrontEnd.Screen.OPTIONS:
			if mouse.pressed:
				_options_click(mouse.position)
			elif front.dragging != "":
				Settings.play_preview(front.dragging)
				front.dragging = ""
				_cue("options")
			refresh_view()
		return true
	if not event is InputEventKey:
		return true
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return true
	if mode == FrontEnd.Screen.TITLE:
		if Settings.pressed_event(event, "confirm") or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
			front.confirm_title()
			_cue("menu")
			refresh_view()
		return true
	if mode == FrontEnd.Screen.MAIN:
		if Settings.pressed_event(event, "menu_left") or Settings.pressed_event(event, "menu_up"):
			front.move_menu(-1)
		elif Settings.pressed_event(event, "menu_right") or Settings.pressed_event(event, "menu_down"):
			front.move_menu(1)
		elif Settings.pressed_event(event, "back"):
			front.back_main()
			_cue("menu")
		elif Settings.pressed_event(event, "confirm") or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
			_apply_menu_choice(front.confirm_menu())
			_cue("menu")
		refresh_view()
		return true
	if mode == FrontEnd.Screen.RECORDS:
		if Settings.pressed_event(event, "back"):
			front.back_records()
			selecting = front.screen == FrontEnd.Screen.SELECT
			_cue("records")
			refresh_view()
		return true
	return _options_key(event, key)


func _apply_menu_choice(choice: String) -> void:
	if choice == "select":
		if SaveData.has_run_slot(front.run_mode):
			front.screen = FrontEnd.Screen.MAIN
			front.gate = "choose"
			front.gate_index = 0
			selecting = false
			showing_records = false
			return
		front.screen = FrontEnd.Screen.SELECT
		selecting = true
		highlight = 1
		showing_records = false


func _options_key(event: InputEvent, key: InputEventKey) -> bool:
	if front.rebinding != "":
		if key.keycode == KEY_ESCAPE:
			front.cancel_rebind()
		else:
			front.finish_rebind(int(key.keycode))
		_cue("options")
		refresh_view()
		return true
	if front.focus_kind(front.focus) == "slider" and (Settings.pressed_event(event, "menu_left") or Settings.pressed_event(event, "menu_right")):
		var step := -1 if Settings.pressed_event(event, "menu_left") else 1
		if front.nudge_slider(step):
			Settings.play_preview(front.slider_id(front.focus))
			_cue("options")
		refresh_view()
		return true
	if Settings.pressed_event(event, "menu_left"):
		front.move_focus(Vector2(-1, 0))
	elif Settings.pressed_event(event, "menu_right"):
		front.move_focus(Vector2(1, 0))
	elif Settings.pressed_event(event, "menu_up"):
		front.move_focus(Vector2(0, -1))
	elif Settings.pressed_event(event, "menu_down"):
		front.move_focus(Vector2(0, 1))
	elif Settings.pressed_event(event, "back"):
		front.back_options()
		_cue("options")
	elif Settings.pressed_event(event, "confirm") or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		var result := front.activate_focus()
		if result == "rebind" or result == "reset" or result == "back":
			_cue("options")
	refresh_view()
	return true


func _options_hover(point: Vector2) -> void:
	var index := _options_index_at(point)
	if index >= 0 and front.rebinding == "":
		front.focus = index


func _options_click(point: Vector2) -> void:
	var index := _options_index_at(point)
	if index < 0:
		return
	front.focus = index
	var kind := front.focus_kind(index)
	if kind == "slider":
		front.dragging = front.slider_id(index)
		_drag_slider(point)
	elif kind == "bind":
		front.begin_rebind()
		_cue("options")
	elif kind == "reset":
		Settings.reset_controls()
		_cue("options")
	elif kind == "back":
		front.back_options()
		_cue("options")


func _drag_slider(point: Vector2) -> void:
	var which := front.dragging
	var index := 0
	if which == "crowd":
		index = 1
	elif which == "sfx":
		index = 2
	var norm: Vector2 = MenuLayout.screen_to_norm(point, _hud._menu_window())
	Settings.set_volume(which, MenuLayout.slider_value_at(index, norm))


func _options_index_at(point: Vector2) -> int:
	var window: Vector2 = _hud._menu_window()
	var norm: Vector2 = MenuLayout.screen_to_norm(point, window)
	for index in 3:
		if MenuLayout.contains_norm(MenuLayout.SLIDERS[index], norm):
			return index
	for index in Settings.ACTION_ROWS.size():
		var row: Dictionary = Settings.ACTION_ROWS[index]
		if MenuLayout.contains_norm(MenuLayout.bind_rect(int(row["column"]), int(row["row"])), norm):
			return 3 + index
	if MenuLayout.contains_norm(MenuLayout.RESET_BUTTON, norm):
		return front.focus_count() - 2
	if MenuLayout.contains_norm(MenuLayout.BACK_BUTTON, norm):
		return front.focus_count() - 1
	return -1


func _shop_click(point: Vector2) -> void:
	if paused or _hud == null:
		return
	var hit := str(_hud.shop_hit(point))
	var bought := false
	if hit == "shelf0":
		bought = run.buy_shelf(0)
	elif hit == "shelf1":
		bought = run.buy_shelf(1)
	elif hit == "shelf2":
		bought = run.buy_shelf(2)
	elif hit == "b12":
		bought = run.buy_b12()
	elif hit == "belt0":
		bought = run.sell_belt(0)
	elif hit == "belt1":
		bought = run.sell_belt(1)
	elif hit == "reroll":
		bought = run.reroll_shop()
	else:
		return
	if bought:
		_cue("shop")
	refresh_view()


func _shop_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if Settings.pressed_event(event, "choose_1"):
		if run.buy_shelf(0):
			_cue("shop")
	elif Settings.pressed_event(event, "choose_2"):
		if run.buy_shelf(1):
			_cue("shop")
	elif Settings.pressed_event(event, "choose_3"):
		if run.buy_shelf(2):
			_cue("shop")
	elif Settings.pressed_event(event, "buy_b12"):
		if run.buy_b12():
			_cue("shop")
	elif Settings.pressed_event(event, "belt_z"):
		if run.sell_belt(0):
			_cue("shop")
	elif Settings.pressed_event(event, "belt_x"):
		if run.sell_belt(1):
			_cue("shop")
	elif Settings.pressed_event(event, "shop_reroll"):
		if run.reroll_shop():
			_cue("shop")
	elif key != null and key.keycode == KEY_C:
		run.add_debug_cash()
		_cash_time = 0.0
	elif Settings.pressed_event(event, "confirm") or (key != null and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER)):
		_cue("shop")
		_leave_shop()
		return
	else:
		return
	refresh_view()


func _shift_weather(code: Key) -> String:
	if code == KEY_0 or code == KEY_KP_0:
		return RunLogic.CLEAR
	if code == KEY_1 or code == KEY_KP_1:
		return RunLogic.RAIN
	if code == KEY_2 or code == KEY_KP_2:
		return RunLogic.SNOW
	if code == KEY_3 or code == KEY_KP_3:
		return RunLogic.MUD
	if code == KEY_4 or code == KEY_KP_4:
		return RunLogic.THIN_AIR
	if code == KEY_5 or code == KEY_KP_5:
		return RunLogic.ICED
	if code == KEY_6 or code == KEY_KP_6:
		return RunLogic.SQUEEZE
	if code == KEY_7 or code == KEY_KP_7:
		return RunLogic.MONSOON
	if code == KEY_8 or code == KEY_KP_8:
		return RunLogic.BIG_GAME
	if code == KEY_9 or code == KEY_KP_9:
		return RunLogic.LIGHTS
	return ""


func _style_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.64, 0.8, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.8, 0.9)
	env.ambient_light_energy = AMBIENT_ENERGY
	$WorldEnvironment.environment = env
	var sun := $Sun as DirectionalLight3D
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = SUN_ENERGY
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	_camera.fov = 58.0


func _build_field() -> void:
	_build_stadium()
	_build_sky()
	_build_weather()
	_ensure_field(35.0)
	_apply_lights_look()


func field_span_yards() -> float:
	return _field_distance


func _ensure_field(distance: float) -> void:
	var span := maxf(KickLogic.visual_span(distance), 1.0)
	if _marks != null and is_equal_approx(_field_distance, span):
		return
	_field_distance = span
	if _marks != null:
		_world.remove_child(_marks)
		_marks.free()
	_marks = Node3D.new()
	_marks.name = "Markings"
	_world.add_child(_marks)
	var cover := ground_cover(span)
	var far_z: float = cover["max_z"]
	var near_z := PLAY_Z
	var length := far_z - near_z
	var mid_z := (far_z + near_z) * 0.5
	_paint_box(_marks, Vector3(54, 0.4, length), Vector3(0, -0.2, mid_z), Color(0.18, 0.32, 0.16))
	_paint_grass(PLAY_HALF, near_z, far_z)
	_paint_ground_skirt(cover)
	var paint := SurfaceTool.new()
	paint.begin(Mesh.PRIMITIVE_TRIANGLES)
	var white := Color(0.93, 0.95, 0.92)
	var yard := 0.0
	while yard <= span + 0.01:
		var rank := yard_line_rank(span, yard)
		if rank > 0:
			var thick := _yard_line_thickness(span, yard, rank)
			var ink := white
			ink.a = _yard_line_alpha(span, yard, rank)
			_add_flat(paint, 25.0, yard - thick * 0.5, thick, 0.05, ink)
		yard += 5.0
	_add_flat_at(paint, -25.0, near_z, 0.16, far_z - near_z, 0.05, white)
	_add_flat_at(paint, 25.0, near_z, 0.16, far_z - near_z, 0.05, white)
	var half := hash_row_half()
	var tick := 0.0
	while tick <= span + 0.01:
		var spacing := hash_tick_spacing(span, tick)
		if spacing > 0:
			var tick_length := 0.9 if spacing <= 5 else 1.15
			var thick := _hash_thickness(span, tick)
			_add_dash_sized(paint, -half, tick, tick_length, thick, white)
			_add_dash_sized(paint, half, tick, tick_length, thick, white)
			if _center_tick(span, tick, spacing):
				var dim := white
				dim.a = 0.55
				_add_dash_sized(paint, 0.0, tick, 0.42, thick * 0.7, dim)
		tick += 1.0
	_mesh_node(_marks, "Lines", paint.commit(), _vertex_mat())
	_layout_stands(span)
	var hash_left := MeshInstance3D.new()
	hash_left.name = "HashLeft"
	hash_left.position = Vector3(-half, 0.0, 0.0)
	_marks.add_child(hash_left)
	var hash_right := MeshInstance3D.new()
	hash_right.name = "HashRight"
	hash_right.position = Vector3(half, 0.0, 0.0)
	_marks.add_child(hash_right)
	for item in _yard_plan(span):
		var number := int(item["yard"])
		var scale := float(item["scale"])
		_yard_sign(-YARD_NUMBER_X, float(number), str(number), scale)
		_yard_sign(YARD_NUMBER_X, float(number), str(number), scale)


func _mesh_node(parent: Node3D, node_name: String, mesh: Mesh, material: Material) -> void:
	var body := MeshInstance3D.new()
	body.name = node_name
	body.mesh = mesh
	body.material_override = material
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(body)


func _vertex_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _add_flat(tool: SurfaceTool, half_width: float, z: float, depth: float, y: float, color: Color) -> void:
	_add_quad(tool, Vector3(0.0, y, z + depth * 0.5), half_width, depth * 0.5, color)


func _add_flat_at(tool: SurfaceTool, x: float, z0: float, width: float, depth: float, y: float, color: Color) -> void:
	_add_quad(tool, Vector3(x, y, z0 + depth * 0.5), width * 0.5, depth * 0.5, color)


func _add_dash(tool: SurfaceTool, x: float, z: float, length: float, color: Color) -> void:
	_add_dash_sized(tool, x, z, length, 0.08, color)


func _add_dash_sized(tool: SurfaceTool, x: float, z: float, length: float, thick: float, color: Color) -> void:
	_add_quad(tool, Vector3(x, 0.07, z), length * 0.5, thick * 0.5, color)


func _add_quad(tool: SurfaceTool, center: Vector3, half_x: float, half_z: float, color: Color) -> void:
	var corners := [
		center + Vector3(-half_x, 0.0, -half_z),
		center + Vector3(half_x, 0.0, -half_z),
		center + Vector3(half_x, 0.0, half_z),
		center + Vector3(-half_x, 0.0, half_z),
	]
	var order := [0, 1, 2, 0, 2, 3]
	for index in order:
		tool.set_normal(Vector3.UP)
		tool.set_color(color)
		tool.add_vertex(corners[index])


func _paint_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.position = pos
	body.material_override = _mat(color, 0.92)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(body)


func _paint_grass(half_x: float, z0: float, z1: float) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := 0.03
	var corners := [
		Vector3(-half_x, y, z0),
		Vector3(half_x, y, z0),
		Vector3(half_x, y, z1),
		Vector3(-half_x, y, z1),
	]
	var uvs := [
		Vector2(-half_x / GRASS_TILE_YARDS, z0 / GRASS_TILE_YARDS),
		Vector2(half_x / GRASS_TILE_YARDS, z0 / GRASS_TILE_YARDS),
		Vector2(half_x / GRASS_TILE_YARDS, z1 / GRASS_TILE_YARDS),
		Vector2(-half_x / GRASS_TILE_YARDS, z1 / GRASS_TILE_YARDS),
	]
	for index in [0, 1, 2, 0, 2, 3]:
		tool.set_normal(Vector3.UP)
		tool.set_uv(uvs[index])
		tool.add_vertex(corners[index])
	var body := MeshInstance3D.new()
	body.name = "Grass"
	body.mesh = tool.commit()
	body.material_override = _grass_material()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marks.add_child(body)
	grass_bounds = {"min_z": z0, "max_z": z1, "half_x": half_x, "tile": GRASS_TILE_YARDS}


func _grass_material() -> StandardMaterial3D:
	var paint := _mat(Color.WHITE, 1.0)
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	paint.texture_repeat = true
	var texture := load(GRASS_PATH) as Texture2D
	if texture != null:
		paint.albedo_texture = texture
	return paint


func ground_cover(span: float) -> Dictionary:
	# The playable strip is 54 yards wide and stops 8 yards past the posts.
	# Past 75 yards the camera's view is much wider than that, and it sees
	# ground behind the posts, so the cover has to reach the frustum and then fade.
	var rig := camera_rig(span, 0.0)
	var cam: Vector3 = rig["position"]
	var fov := float(rig["fov"])
	var aspect := KickConstants.WINDOW_WIDTH / KickConstants.WINDOW_HEIGHT
	var h_half := atan(tan(deg_to_rad(fov) * 0.5) * aspect)
	var past := maxf(80.0, span * 0.25)
	var min_z := PLAY_Z - past
	var dist := cam.z - min_z
	var half := dist * tan(h_half) * 1.25 + 16.0
	return {
		"half_x": maxf(half, PLAY_HALF + 40.0),
		"min_z": min_z,
		"max_z": cam.z + 8.0,
		"play_half": PLAY_HALF,
		"play_z": PLAY_Z,
	}


func ground_fade(x: float, z: float, span: float) -> float:
	var cover := ground_cover(span)
	var half: float = cover["half_x"]
	var min_z: float = cover["min_z"]
	var fade_x := 0.0
	if half > PLAY_HALF + 0.01:
		fade_x = smoothstep(PLAY_HALF, half, absf(x))
	var fade_z := 0.0
	if z < PLAY_Z and min_z < PLAY_Z - 0.01:
		var t := clampf((PLAY_Z - z) / (PLAY_Z - min_z), 0.0, 1.0)
		fade_z = t * t * (3.0 - 2.0 * t)
	return clampf(maxf(fade_x, fade_z), 0.0, 1.0)


func ground_luma(x: float, z: float, span: float, dusk: bool) -> float:
	var fade := ground_fade(x, z, span)
	var edge := DUSK_SKY if dusk else CLEAR_EDGE
	var edge_l := edge.r * 0.2126 + edge.g * 0.7152 + edge.b * 0.0722
	return lerpf(0.36, edge_l, fade)


func _paint_ground_skirt(cover: Dictionary) -> void:
	var half: float = cover["half_x"]
	var min_z: float = cover["min_z"]
	var max_z: float = cover["max_z"]
	var y := 0.025
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_skirt_quad(tool, PLAY_HALF, half, min_z, max_z, y)
	_add_skirt_quad(tool, -half, -PLAY_HALF, min_z, max_z, y)
	_add_skirt_quad(tool, -PLAY_HALF, PLAY_HALF, min_z, PLAY_Z, y)
	var body := MeshInstance3D.new()
	body.name = "GrassSkirt"
	body.mesh = tool.commit()
	_ensure_skirt_material(cover)
	body.material_override = _skirt_mat
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marks.add_child(body)
	grass_bounds["min_z"] = min_z
	grass_bounds["half_x"] = half
	grass_bounds["max_z"] = max_z


func _add_skirt_quad(tool: SurfaceTool, x0: float, x1: float, z0: float, z1: float, y: float) -> void:
	var corners := [
		Vector3(x0, y, z0),
		Vector3(x1, y, z0),
		Vector3(x1, y, z1),
		Vector3(x0, y, z1),
	]
	for index in [0, 1, 2, 0, 2, 3]:
		tool.set_normal(Vector3.UP)
		tool.add_vertex(corners[index])


func _ensure_skirt_material(cover: Dictionary) -> void:
	if _skirt_mat == null:
		var shader := Shader.new()
		shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled;\nuniform sampler2D grass_tex : source_color, filter_nearest, repeat_enable;\nuniform vec3 edge_color = vec3(0.64, 0.80, 0.95);\nuniform float play_half = 27.0;\nuniform float cover_half = 80.0;\nuniform float play_z = -8.0;\nuniform float cover_z = -80.0;\nuniform float tile = 12.0;\nvarying vec3 world_pos;\nvoid vertex() {\n\tworld_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;\n}\nvoid fragment() {\n\tvec3 grass = texture(grass_tex, world_pos.xz / tile).rgb;\n\tfloat fade_x = smoothstep(play_half, cover_half, abs(world_pos.x));\n\tfloat fade_z = 0.0;\n\tif (world_pos.z < play_z) {\n\t\tfloat t = clamp((play_z - world_pos.z) / max(play_z - cover_z, 0.001), 0.0, 1.0);\n\t\tfade_z = t * t * (3.0 - 2.0 * t);\n\t}\n\tfloat fade = max(fade_x, fade_z);\n\tALBEDO = mix(grass, edge_color, fade);\n}\n"
		_skirt_mat = ShaderMaterial.new()
		_skirt_mat.shader = shader
		var texture := load(GRASS_PATH) as Texture2D
		if texture != null:
			_skirt_mat.set_shader_parameter("grass_tex", texture)
		_skirt_mat.set_shader_parameter("tile", GRASS_TILE_YARDS)
		_skirt_mat.set_shader_parameter("edge_color", Vector3(CLEAR_EDGE.r, CLEAR_EDGE.g, CLEAR_EDGE.b))
	_skirt_mat.set_shader_parameter("play_half", PLAY_HALF)
	_skirt_mat.set_shader_parameter("cover_half", float(cover["half_x"]))
	_skirt_mat.set_shader_parameter("play_z", PLAY_Z)
	_skirt_mat.set_shader_parameter("cover_z", float(cover["min_z"]))


func sky_path_for(weather: String) -> String:
	if weather == RunLogic.RAIN or weather == RunLogic.SNOW or weather == RunLogic.MONSOON or weather == RunLogic.ICED:
		return SKY_OVERCAST_PATH
	return SKY_CLEAR_PATH


func _build_sky() -> void:
	# The paintings wrap the horizon. A sky shader samples them by direction,
	# so the view stays inside the painting at 35 yards and at 1000.
	var shader := Shader.new()
	shader.code = "shader_type sky;\nuniform sampler2D sky_tex : source_color, filter_nearest, repeat_enable;\nuniform vec3 dusk_tint = vec3(1.0);\nuniform float horizon_elev = 0.05;\nuniform float zenith_elev = 0.45;\nvoid sky() {\n\tvec3 dir = EYEDIR;\n\tfloat u = atan(dir.x, dir.z) / 6.28318530718 + 0.5;\n\tfloat elev = asin(clamp(dir.y, -1.0, 1.0));\n\tfloat t = clamp((elev - horizon_elev) / max(zenith_elev - horizon_elev, 0.001), 0.0, 1.0);\n\tCOLOR = texture(sky_tex, vec2(u, 1.0 - t)).rgb * dusk_tint;\n}\n"
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = shader
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	var env := $WorldEnvironment.environment as Environment
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	_apply_sky("")


func _apply_sky(weather: String) -> void:
	var path := sky_path_for(weather)
	sky_texture_path = path
	if _sky_mat == null:
		return
	var texture := load(path) as Texture2D
	if texture != null:
		_sky_mat.set_shader_parameter("sky_tex", texture)


func _frame_sky(rig: Dictionary) -> void:
	if _sky_mat == null:
		return
	var cam: Vector3 = rig["position"]
	var look: Vector3 = rig["look"]
	var ahead := look - cam
	var look_elev := atan2(ahead.y, Vector2(ahead.x, ahead.z).length())
	var top_elev := look_elev + deg_to_rad(float(rig["fov"])) * 0.5
	var roof := Vector3(0.0, STAND_HEIGHT, STAND_BOWL_Z) - cam
	var roof_elev := atan2(roof.y, Vector2(roof.x, roof.z).length())
	# Pale horizon just above the far stand roof. Deep blue at the top of the frame.
	var horizon := roof_elev - 0.015
	var zenith := maxf(top_elev + 0.02, horizon + 0.12)
	_sky_mat.set_shader_parameter("horizon_elev", horizon)
	_sky_mat.set_shader_parameter("zenith_elev", zenith)


func _build_weather() -> void:
	# One volume in front of the camera. It is not a field of drops.
	_weather_anchor = Node3D.new()
	_weather_anchor.name = "Weather"
	_world.add_child(_weather_anchor)
	_rain = _make_precip("Rain", _streak_texture(), Vector2(0.1, 0.86), true, MONSOON_PARTICLES, 0.85)
	_snow = _make_precip("Snow", _flake_texture(), Vector2(0.32, 0.32), false, SNOW_PARTICLES, 3.6)
	_weather_anchor.add_child(_rain)
	_weather_anchor.add_child(_snow)
	_apply_weather("")
	_prime_precip()


func _make_precip(node_name: String, texture: Texture2D, size: Vector2, align_fall: bool, amount: int, life: float) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = node_name
	particles.emitting = false
	particles.visible = false
	# Allocate the final buffer once. Later weather only changes amount_ratio.
	particles.amount = amount
	particles.lifetime = life
	particles.amount_ratio = 1.0
	# 1.5s fills the first frame without simulating the old 4s burst.
	particles.preprocess = 1.5
	particles.explosiveness = 0.0
	particles.local_coords = true
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-16, -12, -12), Vector3(32, 24, 24))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(12.0, 7.5, 6.5)
	process.direction = Vector3.DOWN
	process.spread = 8.0
	process.gravity = Vector3(0, -RAIN_FALL, 0)
	process.initial_velocity_min = RAIN_FALL
	process.initial_velocity_max = RAIN_FALL
	process.set_particle_flag(ParticleProcessMaterial.PARTICLE_FLAG_ALIGN_Y_TO_VELOCITY, align_fall)
	if not align_fall:
		process.turbulence_enabled = true
		process.turbulence_noise_strength = 0.4
		process.turbulence_noise_scale = 1.6
		process.turbulence_influence_min = 0.04
		process.turbulence_influence_max = 0.12
		process.scale_min = 0.75
		process.scale_max = 1.25
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = size
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	paint.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES if align_fall else BaseMaterial3D.BILLBOARD_ENABLED
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	paint.albedo_texture = texture
	paint.vertex_color_use_as_albedo = true
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = paint
	particles.draw_pass_1 = quad
	return particles


func _streak_texture() -> Texture2D:
	var image := Image.create(3, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in 12:
		var alpha := 0.0
		if y >= 2 and y <= 9:
			alpha = 0.9
		elif y == 1 or y == 10:
			alpha = 0.45
		image.set_pixel(1, y, Color(0.86, 0.92, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _flake_texture() -> Texture2D:
	var image := Image.create(7, 7, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var mid := 3.0
	for y in 7:
		for x in 7:
			var dist := Vector2(float(x) - mid, float(y) - mid).length()
			var alpha := 0.0
			if dist <= 1.2:
				alpha = 0.82
			elif dist <= 2.15:
				alpha = 0.5
			elif dist <= 2.8:
				alpha = 0.22
			if alpha > 0.0:
				image.set_pixel(x, y, Color(0.96, 0.97, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _weather_kind(weather: String) -> String:
	if weather == RunLogic.RAIN or weather == RunLogic.MONSOON:
		return "rain"
	if weather == RunLogic.SNOW or weather == RunLogic.ICED:
		return "snow"
	return "none"


func _apply_weather(weather: String) -> void:
	var kind := _weather_kind(weather)
	var amount := 0
	var fall := 0.0
	if weather == RunLogic.MONSOON:
		amount = MONSOON_PARTICLES
		fall = MONSOON_FALL
	elif weather == RunLogic.RAIN:
		amount = RAIN_PARTICLES
		fall = RAIN_FALL
	elif kind == "snow":
		amount = SNOW_PARTICLES
		fall = SNOW_FALL
	var dim := OVERCAST_DIM if kind != "none" else 1.0
	weather_state = {"kind": kind, "amount": amount, "fall": fall, "dim": dim}
	var rain_life := 0.55 if weather == RunLogic.MONSOON else 0.85
	var rain_ratio := 1.0
	if weather == RunLogic.RAIN and MONSOON_PARTICLES > 0:
		rain_ratio = float(RAIN_PARTICLES) / float(MONSOON_PARTICLES)
	_tune_precip(_rain, kind == "rain", fall, rain_life, rain_ratio)
	_tune_precip(_snow, kind == "snow", fall, 3.6, 1.0)
	var env := $WorldEnvironment.environment as Environment
	if env != null:
		env.ambient_light_energy = AMBIENT_ENERGY * dim
	var sun := $Sun as DirectionalLight3D
	if sun != null:
		sun.light_energy = SUN_ENERGY * dim


func _tune_precip(particles: GPUParticles3D, active: bool, fall: float, life: float, ratio: float) -> void:
	if particles == null:
		return
	particles.visible = active
	particles.emitting = active
	if not active:
		return
	if not is_equal_approx(particles.lifetime, life):
		particles.lifetime = life
	particles.amount_ratio = ratio
	var process := particles.process_material as ParticleProcessMaterial
	if process == null:
		return
	process.initial_velocity_min = fall * 0.85
	process.initial_velocity_max = fall * 1.15
	process.gravity = Vector3(0, -fall, 0)
	process.color = Color(1, 1, 1, 0.84 if particles == _snow else 0.72)


func _prime_precip() -> void:
	if DisplayServer.get_name() == "headless" or _camera == null or _weather_anchor == null:
		return
	var forward := -_camera.global_transform.basis.z
	if forward.length_squared() < 0.0001:
		forward = Vector3(0, 0, -1)
	_weather_anchor.global_position = _camera.global_position + forward.normalized() * 9.0
	for particles in [_rain, _snow]:
		if particles == null:
			continue
		particles.visible = true
		particles.emitting = true
		var process := particles.process_material as ParticleProcessMaterial
		if process != null:
			process.color = Color(1, 1, 1, 0)
	RenderingServer.force_draw()
	RenderingServer.force_draw()
	for particles in [_rain, _snow]:
		if particles == null:
			continue
		particles.visible = false
		particles.emitting = false
		var process := particles.process_material as ParticleProcessMaterial
		if process != null:
			process.color = Color(1, 1, 1, 0.84 if particles == _snow else 0.72)


func _place_weather() -> void:
	if _weather_anchor == null or _camera == null:
		return
	if str(weather_state["kind"]) == "none":
		return
	var forward := -_camera.global_transform.basis.z
	if forward.length_squared() < 0.0001:
		return
	forward = forward.normalized()
	var origin := _camera.global_position + forward * 9.0
	_weather_anchor.global_position = origin
	if forward.cross(Vector3.UP).length_squared() > 0.0001:
		_weather_anchor.look_at(origin + forward, Vector3.UP)
	var info := ribbon_state()
	var blow: Vector3 = info["blow"]
	var lean := float(info["lean"])
	var fall := float(weather_state["fall"])
	var world_grav := Vector3.DOWN * fall
	if lean > 0.5 and blow.length_squared() > 0.0001:
		var axis := Vector3.DOWN.cross(blow.normalized())
		if axis.length_squared() > 0.0001:
			world_grav = Vector3.DOWN.rotated(axis.normalized(), deg_to_rad(lean)) * fall
	var local_grav := _weather_anchor.global_transform.basis.transposed() * world_grav
	for particles in [_rain, _snow]:
		if particles == null or not particles.emitting:
			continue
		var process := particles.process_material as ParticleProcessMaterial
		if process == null:
			continue
		if not process.gravity.is_equal_approx(local_grav):
			process.gravity = local_grav
		var aim := local_grav.normalized()
		if not process.direction.is_equal_approx(aim):
			process.direction = aim


func floodlight_plan(span: float) -> Dictionary:
	# Short walls get two towers a side, like the lock. Longer walls step by 90 yards.
	# Right is staggered half a bay and starts on the 6-lamp tower, so the sides do not match.
	var left_z := PackedFloat32Array()
	var right_z := PackedFloat32Array()
	var left_kind := PackedInt32Array()
	var right_kind := PackedInt32Array()
	if span < 50.0:
		# The close camera only frames the far corner of each sideline.
		left_z.append(2.4)
		left_z.append(6.0)
		right_z.append(3.6)
		right_z.append(7.4)
	elif span < 120.0:
		left_z.append(10.0)
		left_z.append(32.0)
		right_z.append(18.0)
		right_z.append(42.0)
	else:
		var z := 40.0
		while z < span - 18.0:
			left_z.append(z)
			z += LIGHT_SPACING
		z = 40.0 + LIGHT_SPACING * 0.5
		while z < span - 18.0:
			right_z.append(z)
			z += LIGHT_SPACING
	for i in left_z.size():
		left_kind.append(0 if i % 2 == 0 else 1)
	for i in right_z.size():
		right_kind.append(1 if i % 2 == 0 else 0)
	return {
		"left_z": left_z,
		"right_z": right_z,
		"left_kind": left_kind,
		"right_kind": right_kind,
		"end_z": STAND_BOWL_Z - LIGHT_END_BACK,
		"side_x": STAND_X + LIGHT_SIDE_OUT,
		"count": left_z.size() + right_z.size() + 1,
	}


func _layout_floodlights(span: float) -> void:
	if _floods == null:
		_floods = Node3D.new()
		_floods.name = "Floodlights"
		_world.add_child(_floods)
	for child in _floods.get_children():
		_floods.remove_child(child)
		child.free()
	var plan := floodlight_plan(span)
	var left_z: PackedFloat32Array = plan["left_z"]
	var right_z: PackedFloat32Array = plan["right_z"]
	var left_kind: PackedInt32Array = plan["left_kind"]
	var right_kind: PackedInt32Array = plan["right_kind"]
	var side_x := float(plan["side_x"])
	for i in left_z.size():
		_add_floodlight(-side_x, left_z[i], left_kind[i], false)
	for i in right_z.size():
		_add_floodlight(side_x, right_z[i], right_kind[i], false)
	_add_floodlight(0.0, float(plan["end_z"]), 2, true)


func _add_floodlight(x: float, z: float, kind: int, end_zone: bool) -> void:
	var path := LIGHT_END_PATH if end_zone else (LIGHT_SIDE_PATH if kind == 0 else LIGHT_SIDE_B_PATH)
	var tex := load(path) as Texture2D
	var sprite := Sprite3D.new()
	sprite.name = "EndBank" if end_zone else ("Tower8" if kind == 0 else "Tower6")
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = LIGHT_END_PIXEL if end_zone else LIGHT_SIDE_PIXEL
	sprite.centered = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	paint.alpha_scissor_threshold = 0.45
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.albedo_texture = tex
	sprite.material_override = paint
	var canvas_h := 640.0 if end_zone else 1024.0
	var foot_row := 624.0 if end_zone else 1008.0
	var lift := (foot_row - canvas_h * 0.5) * sprite.pixel_size
	if not end_zone:
		lift += LIGHT_SIDE_LIFT
	sprite.position = Vector3(x, lift, z)
	_floods.add_child(sprite)


func _build_stadium() -> void:
	# One node per wall. Each wall is a single mesh with up to three surfaces.
	_stands = Node3D.new()
	_stands.name = "Stands"
	_world.add_child(_stands)
	for node_name in ["Left", "Right", "Bowl"]:
		var wall := MeshInstance3D.new()
		wall.name = node_name
		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stands.add_child(wall)


func _layout_stands(span: float) -> void:
	if _stands == null:
		return
	_stand_mats.clear()
	var rig := camera_rig(span, 0.0)
	var near_z: float = float(rig["position"].z) + 18.0
	var far_z := STAND_BOWL_Z
	stand_bounds = {
		"min_z": far_z,
		"max_z": near_z,
		"x": STAND_X,
		"height": STAND_HEIGHT,
		"nodes": _stands.get_child_count(),
		"variants": _STAND_PATHS.size(),
	}
	_paint_stand(_stands.get_node("Left"), -STAND_X, far_z, near_z, _STAND_LEFT, true)
	_paint_stand(_stands.get_node("Right"), STAND_X, far_z, near_z, _STAND_RIGHT, true)
	_paint_stand(_stands.get_node("Bowl"), 0.0, -STAND_X, STAND_X, _STAND_BOWL, false)
	_layout_floodlights(span)
	_pulse_floodlights()


func _paint_stand(wall: MeshInstance3D, fixed: float, start: float, finish: float, pattern: Array[int], along_z: bool) -> void:
	var buckets: Array = [[], [], []]
	var cursor := start
	var index := 0
	var span := finish - start
	if span < 0.0:
		cursor = finish
		span = -span
	var origin := cursor
	while cursor < origin + span - 0.01:
		var nxt := minf(cursor + STAND_TILE, origin + span)
		var piece := nxt - cursor
		var which: int = pattern[index % pattern.size()]
		buckets[which].append({"at": cursor, "length": piece, "u": piece / STAND_TILE})
		cursor = nxt
		index += 1
	var mesh := ArrayMesh.new()
	var surface := 0
	for variant in 3:
		var tiles: Array = buckets[variant]
		if tiles.is_empty():
			continue
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for tile in tiles:
			var at: float = float(tile["at"])
			var length: float = float(tile["length"])
			var u: float = float(tile["u"])
			if along_z:
				var inward := 1.0 if fixed < 0.0 else -1.0
				_add_stand_quad(tool, Vector3(fixed, 0.0, at), Vector3(0, 0, 1), Vector3(inward, 0, 0), length, u)
			else:
				_add_stand_quad(tool, Vector3(at, 0.0, STAND_BOWL_Z), Vector3(1, 0, 0), Vector3(0, 0, 1), length, u)
		tool.commit(mesh)
		mesh.surface_set_material(surface, _stand_material(variant))
		surface += 1
	wall.mesh = mesh


func _add_stand_quad(tool: SurfaceTool, origin: Vector3, axis: Vector3, normal: Vector3, length: float, u_span: float) -> void:
	var end := origin + axis * length
	var top := Vector3.UP * STAND_HEIGHT
	var points := [origin, end, end + top, origin + top]
	var uvs := [Vector2(0, 1), Vector2(u_span, 1), Vector2(u_span, 0), Vector2(0, 0)]
	for index in [0, 1, 2, 0, 2, 3]:
		tool.set_normal(normal)
		tool.set_uv(uvs[index])
		tool.add_vertex(points[index])


func _stand_material(variant: int) -> StandardMaterial3D:
	var paint := _mat(Color.WHITE, 1.0)
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var path := _STAND_PATHS[variant]
	var texture := load(path) as Texture2D
	if texture != null:
		paint.albedo_texture = texture
	_stand_mats.append(paint)
	return paint


func _build_uprights() -> void:
	var yellow := Color(0.95, 0.82, 0.16)
	var crossbar_y := 3.33
	var upright_h := 10.0
	_post_l = _pole(Vector3(0.16, upright_h, 0.16), Vector3(0, crossbar_y + upright_h * 0.5, 0), yellow)
	_post_r = _pole(Vector3(0.16, upright_h, 0.16), Vector3(0, crossbar_y + upright_h * 0.5, 0), yellow)
	_crossbar = _pole(Vector3(1.0, 0.16, 0.16), Vector3(0, crossbar_y, 0), yellow)
	_goal_stem = _pole(Vector3(0.2, crossbar_y, 0.2), Vector3(0, crossbar_y * 0.5, 0), yellow)
	_fit_posts(KickConstants.POST_SEPARATION_YARDS)
	_build_ribbons()
	_build_ring()


func _build_ring() -> void:
	_ring = Sprite3D.new()
	_ring.name = "BonusRing"
	var tex := load(RING_PATH) as Texture2D
	_ring.texture = tex
	_ring.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_ring.transparent = true
	_ring.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	_ring.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_ring.pixel_size = RING_PIXEL
	_ring.centered = true
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_OFF
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.albedo_texture = tex
	_ring.material_override = paint
	_world.add_child(_ring)


func _place_ring() -> void:
	if _ring == null:
		return
	if logic.phase == KickLogic.Phase.AIMING:
		_ring_pop = -1.0
		_ring.scale = Vector3.ONE
		_ring.modulate = Color.WHITE
		if not run.ring_showing():
			_ring.visible = false
			logic.ring_active = false
			return
		var place: Dictionary = run.ring_place(logic.kick_distance, logic.start_lateral_yards, run.post_half_gap(), logic.aim_cap_degrees())
		logic.ring_active = true
		logic.ring_center = float(place["x"])
		# The painted hoop sits 4 px left and 4 px above the canvas center.
		var nudge := 4.0 * RING_PIXEL
		_ring.position = Vector3(logic.ring_center + nudge, RING_CENTER_Y - nudge, 0.0)
		_ring.visible = true
		return
	if not logic.ring_active or _ring_pop >= RING_POP_SEC:
		_ring.visible = false
		return
	var arrived := logic.reached_uprights and logic.ball_forward_yards + 0.05 >= logic.kick_distance
	if logic.result_text == "BONUS RING" and arrived and _ring_pop < 0.0:
		_ring_pop = 0.0
	_ring.visible = true


func lights_roof_y() -> float:
	if _camera == null:
		return 150.0
	var roof := Vector3(0.0, STAND_HEIGHT, STAND_BOWL_Z)
	if _camera.is_position_behind(roof):
		return 150.0
	return _camera.unproject_position(roof).y


func lights_show() -> bool:
	# On for the whole Under the Lights kick, including the result stamp.
	# Off on the offer, the shop, practice, and every other kick.
	if not run.lights_active():
		return false
	if run.awaiting_offer or run.awaiting_shop:
		return false
	if run.phase != RunLogic.Phase.PLAYING:
		return false
	return true


func beam_breath(time: float) -> float:
	return 1.0 + BEAM_BREATH * sin(time * TAU / BEAM_BREATH_SEC)


func beam_alpha_at(height_ratio: float, breath: float = 1.0) -> float:
	var along := clampf(height_ratio, 0.0, 1.0)
	return BEAM_PEAK * breath * pow(along, BEAM_FADE_POW)


func _pulse_floodlights() -> void:
	if _floods == null:
		return
	var hot := lights_show()
	var wave := 0.5 + 0.5 * sin(glare_time * TAU / BEAM_BREATH_SEC)
	for child in _floods.get_children():
		var sprite := child as Sprite3D
		if sprite == null:
			continue
		if not hot:
			sprite.modulate = Color.WHITE
			continue
		var glow := lerpf(1.05, 1.75, wave)
		sprite.modulate = Color(1.0, 0.94, 0.78) * glow
	_pulse_beams()


func _apply_lights_look() -> void:
	var on := lights_show()
	var span := _field_distance if _field_distance > 0.0 else logic.kick_distance
	_layout_light_beams(span)
	if _beams != null:
		_beams.visible = on
	var sky := Color.WHITE
	var stands := Color.WHITE
	if on:
		sky = DUSK_SKY
		stands = DUSK_STAND
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("dusk_tint", Vector3(sky.r, sky.g, sky.b))
	for paint in _stand_mats:
		paint.albedo_color = stands
	if _skirt_mat != null:
		var edge := DUSK_SKY if on else CLEAR_EDGE
		_skirt_mat.set_shader_parameter("edge_color", Vector3(edge.r, edge.g, edge.b))
	var shown := 0
	if on and _beams != null:
		for child in _beams.get_children():
			if str(child.name).begins_with("Beam"):
				shown += 1
	lights_look = {
		"on": on,
		"beams": shown,
		"sky": sky,
		"stands": stands,
		"breath_sec": BEAM_BREATH_SEC,
		"peak": BEAM_PEAK,
		"pool": BEAM_POOL,
	}
	_pulse_floodlights()


func _ensure_beam_materials() -> void:
	if _beam_mat != null and _pool_mat != null:
		return
	var beam_shader := Shader.new()
	beam_shader.code = "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;\nuniform float peak = 0.30;\nuniform float breath = 1.0;\nuniform float fade_pow = 1.35;\nuniform vec3 warm = vec3(1.0, 0.95, 0.82);\nvoid fragment() {\n\tfloat along = pow(clamp(UV.y, 0.0, 1.0), fade_pow);\n\tfloat span = abs(UV.x * 2.0 - 1.0);\n\tfloat edge = 1.0 - smoothstep(0.08, 1.0, span);\n\tALBEDO = warm;\n\tALPHA = peak * breath * along * edge;\n}\n"
	_beam_mat = ShaderMaterial.new()
	_beam_mat.shader = beam_shader
	_beam_mat.render_priority = -8
	_beam_mat.set_shader_parameter("peak", BEAM_PEAK)
	# The mesh fades along the shaft (1 at the lamp, 0 at the grass). A gentler
	# power keeps the middle of that cone readable. beam_alpha_at still uses
	# BEAM_FADE_POW for the height cap.
	_beam_mat.set_shader_parameter("fade_pow", 0.8)
	_beam_mat.set_shader_parameter("breath", 1.0)
	var pool_shader := Shader.new()
	pool_shader.code = "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;\nuniform float peak = 0.15;\nuniform float breath = 1.0;\nuniform vec3 warm = vec3(1.0, 0.95, 0.82);\nvoid fragment() {\n\tvec2 p = UV * 2.0 - 1.0;\n\tfloat soft = smoothstep(1.0, 0.15, dot(p, p));\n\tALBEDO = warm;\n\tALPHA = peak * breath * soft;\n}\n"
	_pool_mat = ShaderMaterial.new()
	_pool_mat.shader = pool_shader
	_pool_mat.render_priority = -6
	_pool_mat.set_shader_parameter("peak", BEAM_POOL)
	_pool_mat.set_shader_parameter("breath", 1.0)
	var glare_shader := Shader.new()
	glare_shader.code = "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;\nuniform float peak = 0.40;\nuniform float breath = 1.0;\nuniform vec3 warm = vec3(1.0, 0.96, 0.86);\nvoid fragment() {\n\tvec2 p = UV * 2.0 - 1.0;\n\tfloat soft = smoothstep(1.0, 0.2, dot(p, p));\n\tALBEDO = warm;\n\tALPHA = peak * breath * soft;\n}\n"
	_glare_mat = ShaderMaterial.new()
	_glare_mat.shader = glare_shader
	_glare_mat.render_priority = -7
	_glare_mat.set_shader_parameter("peak", GLARE_PEAK)
	_glare_mat.set_shader_parameter("breath", 1.0)


func _pulse_beams() -> void:
	if _beam_mat == null or _pool_mat == null:
		return
	var scale := 1.0
	if lights_show():
		scale = beam_breath(glare_time)
	_beam_mat.set_shader_parameter("breath", scale)
	_pool_mat.set_shader_parameter("breath", scale)
	if _glare_mat != null:
		_glare_mat.set_shader_parameter("breath", scale)


func light_beam_plan(span: float, tee: Vector3) -> Array:
	var chosen := _choose_beam_towers(_beam_tower_list(span), tee.z)
	var beams: Array = []
	for index in chosen.size():
		beams.append(_beam_from_tower(chosen[index], span, tee, index))
	return beams


func _beam_tower_list(span: float) -> Array:
	var plan := floodlight_plan(span)
	var towers: Array = []
	var side_x := float(plan["side_x"])
	var left_z: PackedFloat32Array = plan["left_z"]
	var right_z: PackedFloat32Array = plan["right_z"]
	for z in left_z:
		towers.append({"x": -side_x, "z": float(z), "end": false})
	for z in right_z:
		towers.append({"x": side_x, "z": float(z), "end": false})
	towers.append({"x": 0.0, "z": float(plan["end_z"]), "end": true})
	return towers


func _choose_beam_towers(towers: Array, tee_z: float) -> Array:
	# Closest banks to the kicker first. The end-zone bank always stays, so a
	# long kick still gets a shaft from behind the posts even when that lamp
	# is a speck at the far end of the frame.
	var sides: Array = []
	var ends: Array = []
	for tower in towers:
		if bool(tower["end"]):
			ends.append(tower)
		else:
			sides.append(tower)
	var ranked: Array = []
	for tower in sides:
		var placed := false
		var gap := absf(float(tower["z"]) - tee_z)
		for index in ranked.size():
			var other := absf(float(ranked[index]["z"]) - tee_z)
			var closer := gap < other - 0.001
			var tied_nearer := absf(gap - other) <= 0.001 and float(tower["z"]) > float(ranked[index]["z"])
			if closer or tied_nearer:
				ranked.insert(index, tower)
				placed = true
				break
		if not placed:
			ranked.append(tower)
	# Four nearest banks plus the end-zone bank. More than that stacks into a white disc.
	var budget := mini(4, BEAM_MAX - ends.size())
	if budget < 1:
		budget = 1
	var picked: Array = []
	for i in mini(budget, ranked.size()):
		picked.append(ranked[i])
	return picked + ends


func _lamp_position(x: float, z: float, end_zone: bool) -> Vector3:
	if end_zone:
		var pixel := LIGHT_END_PIXEL
		var center_y := (LAMP_END_FOOT - LAMP_END_CANVAS * 0.5) * pixel
		var lamp_y := center_y + (LAMP_END_CANVAS * 0.5 - LAMP_END_ROW) * pixel
		return Vector3(x, lamp_y, z)
	var pixel := LIGHT_SIDE_PIXEL
	var center_y := (LAMP_SIDE_FOOT - LAMP_SIDE_CANVAS * 0.5) * pixel + LIGHT_SIDE_LIFT
	var lamp_y := center_y + (LAMP_SIDE_CANVAS * 0.5 - LAMP_SIDE_ROW) * pixel
	return Vector3(x, lamp_y, z)


func _aim_landing(tower: Dictionary, tee: Vector3, slot: int) -> Vector3:
	# Every landing stays inside a few yards of the tee. The offsets keep the
	# pools from stacking on one pixel, and they follow the hash.
	if bool(tower["end"]):
		return Vector3(tee.x, 0.0, tee.z + 1.8)
	var side := signf(float(tower["x"]))
	if side == 0.0:
		side = 1.0
	var dx := side * (1.05 + float(slot % 2) * 0.7)
	var dz := 0.9 + float(slot % 3) * 0.45
	var offset := Vector2(dx, dz)
	if offset.length() > 2.9:
		offset = offset.normalized() * 2.9
	return Vector3(tee.x + offset.x, 0.0, tee.z + offset.y)


func _lamp_faces_camera(origin: Vector3, end_zone: bool, cam: Vector3) -> bool:
	var forward := Vector3(0.0, -0.15, 1.0)
	if not end_zone:
		var side := signf(origin.x)
		if side == 0.0:
			side = 1.0
		forward = Vector3(-side, -0.2, 0.45)
	forward = forward.normalized()
	var to_cam := cam - origin
	if to_cam.length_squared() < 0.01:
		return false
	return forward.dot(to_cam.normalized()) > 0.25


func glare_alpha_at(dist: float, breath: float = 1.0) -> float:
	var t := clampf(dist / GLARE_RADIUS, 0.0, 1.0)
	var soft := 1.0 - smoothstep(0.2, 1.0, t)
	return GLARE_PEAK * breath * soft


func _beam_from_tower(tower: Dictionary, span: float, tee: Vector3, slot: int) -> Dictionary:
	var x := float(tower["x"])
	var z := float(tower["z"])
	var end := bool(tower["end"])
	var origin := _lamp_position(x, z, end)
	var landing := _aim_landing(tower, tee, slot)
	landing.z = clampf(landing.z, 0.5, maxf(span + 3.0, 4.0))
	var grass := Vector3(landing.x, 0.12, landing.z)
	# Eight short rings. One long ribbon lets the near grass vertex own every
	# pixel, so the bright lamp end never shows. B5D's wide bright hold sat up
	# by the camera and read as a searchlight; this cone opens as it drops.
	var count := 8
	var points := PackedVector3Array()
	var widths := PackedFloat32Array()
	var fades := PackedFloat32Array()
	for i in count:
		var t := float(i) / float(count - 1)
		var at := origin.lerp(grass, t)
		at.y = lerpf(origin.y, grass.y, pow(t, 0.55))
		if i > 0 and at.y > points[i - 1].y - 0.12:
			at.y = points[i - 1].y - 0.2
		points.append(at)
		widths.append(lerpf(1.45, 6.4, t))
		fades.append(1.0 - t)
	var cam: Vector3 = camera_rig(span, tee.x)["position"]
	return {
		"end": end,
		"tower_x": x,
		"tower_z": z,
		"origin": origin,
		"landing": landing,
		"glare": _lamp_faces_camera(origin, end, cam),
		"points": points,
		"widths": widths,
		"fades": fades,
	}


func _layout_light_beams(span: float) -> void:
	if span <= 0.0:
		return
	var tee := _tee_position()
	# Same distance with a new hash, or a retry, still has to re-aim.
	if _beams != null and is_equal_approx(_beam_span, span) and is_equal_approx(_beam_tee_x, tee.x) and is_equal_approx(_beam_tee_z, tee.z) and _beams.get_child_count() > 0:
		return
	_beam_span = span
	_beam_tee_x = tee.x
	_beam_tee_z = tee.z
	if _beams == null:
		_beams = Node3D.new()
		_beams.name = "LightBeams"
		_world.add_child(_beams)
	for child in _beams.get_children():
		_beams.remove_child(child)
		child.free()
	_ensure_beam_materials()
	var cam: Vector3 = camera_rig(span, tee.x)["position"]
	var index := 0
	for item in light_beam_plan(span, tee):
		var beam := MeshInstance3D.new()
		beam.name = "BeamEnd%d" % index if bool(item["end"]) else "BeamSide%d" % index
		var points: PackedVector3Array = item["points"]
		var widths: PackedFloat32Array = item["widths"]
		var fades: PackedFloat32Array = item["fades"]
		beam.mesh = _beam_mesh(points, widths, fades, cam)
		beam.material_override = _beam_mat
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		_beams.add_child(beam)
		var landing: Vector3 = item["landing"]
		var pool := MeshInstance3D.new()
		pool.name = "Pool%d" % index
		index += 1
		# The pool is the wide end of this shaft.
		var foot := float(widths[widths.size() - 1])
		pool.mesh = _pool_mesh(foot * 0.5, foot * 0.42)
		pool.material_override = _pool_mat
		pool.position = Vector3(landing.x, 0.04, landing.z)
		pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pool.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		_beams.add_child(pool)
		if bool(item["glare"]):
			var origin: Vector3 = item["origin"]
			var glare := MeshInstance3D.new()
			glare.name = "Glare%d" % (index - 1)
			glare.mesh = _glare_mesh(cam, origin, GLARE_RADIUS)
			glare.material_override = _glare_mat
			glare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			glare.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			_beams.add_child(glare)


func _beam_mesh(points: PackedVector3Array, widths: PackedFloat32Array, fades: PackedFloat32Array, cam: Vector3) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# One ribbon faces the camera so the cone has area. The other crosses it for thickness.
	_beam_ribbon(tool, points, widths, fades, cam, false)
	_beam_ribbon(tool, points, widths, fades, cam, true)
	return tool.commit()


func _beam_ribbon(tool: SurfaceTool, points: PackedVector3Array, widths: PackedFloat32Array, fades: PackedFloat32Array, cam: Vector3, crossed: bool) -> void:
	var rings: Array = []
	for i in points.size():
		var forward := Vector3.DOWN
		if i < points.size() - 1:
			forward = points[i + 1] - points[i]
		else:
			forward = points[i] - points[i - 1]
		if forward.length_squared() < 0.0001:
			forward = Vector3.DOWN
		forward = forward.normalized()
		var to_cam := cam - points[i]
		# Spread the shaft sideways. A tilted width dumps the cone into the ground
		# and the beam vanishes into a line.
		var axis := forward.cross(to_cam)
		axis.y = 0.0
		if axis.length_squared() < 0.0004:
			var flat := Vector3(forward.x, 0.0, forward.z)
			if flat.length_squared() < 0.0004:
				flat = Vector3.FORWARD
			axis = Vector3(-flat.z, 0.0, flat.x)
		axis = axis.normalized()
		if crossed:
			axis = forward.cross(axis).normalized()
		var along := clampf(fades[mini(i, fades.size() - 1)], 0.0, 1.0)
		var half := float(widths[mini(i, widths.size() - 1)]) * 0.5
		var row: Array = []
		for column in 5:
			var u := float(column) / 4.0
			row.append({"at": points[i] + axis * lerpf(-half, half, u), "uv": Vector2(u, along)})
		rings.append(row)
	for i in rings.size() - 1:
		var above: Array = rings[i]
		var below: Array = rings[i + 1]
		for column in 4:
			_beam_vertex(tool, above[column])
			_beam_vertex(tool, above[column + 1])
			_beam_vertex(tool, below[column + 1])
			_beam_vertex(tool, above[column])
			_beam_vertex(tool, below[column + 1])
			_beam_vertex(tool, below[column])


func _beam_vertex(tool: SurfaceTool, corner: Dictionary) -> void:
	tool.set_uv(corner["uv"])
	tool.add_vertex(corner["at"])


func _glare_mesh(cam: Vector3, origin: Vector3, radius: float) -> ArrayMesh:
	# A small star on the lamp head. Four thin rays, not a disc the size of the field.
	var to_cam := cam - origin
	if to_cam.length_squared() < 0.01:
		to_cam = Vector3(0.0, 0.0, 1.0)
	var normal := to_cam.normalized()
	var up := Vector3.UP
	if absf(normal.dot(up)) > 0.92:
		up = Vector3.RIGHT
	var right := up.cross(normal).normalized()
	var cam_up := normal.cross(right).normalized()
	var center := origin + normal * 0.2
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var thick := radius * 0.16
	for ray in 8:
		var ang := float(ray) * TAU / 8.0
		var tip := right * cos(ang) + cam_up * sin(ang)
		var side := (right * -sin(ang) + cam_up * cos(ang)) * thick
		var corners := [
			{"at": center, "uv": Vector2(0.5, 0.5)},
			{"at": center + side, "uv": Vector2(0.5, 0.72)},
			{"at": center + tip * radius, "uv": Vector2(0.5, 1.0)},
			{"at": center - side, "uv": Vector2(0.5, 0.72)},
		]
		for index in [0, 1, 2, 0, 2, 3]:
			_beam_vertex(tool, corners[index])
	return tool.commit()


func _pool_mesh(half_x: float, half_z: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [
		{"at": Vector3(-half_x, 0.0, -half_z), "uv": Vector2(0, 0)},
		{"at": Vector3(half_x, 0.0, -half_z), "uv": Vector2(1, 0)},
		{"at": Vector3(half_x, 0.0, half_z), "uv": Vector2(1, 1)},
		{"at": Vector3(-half_x, 0.0, half_z), "uv": Vector2(0, 1)},
	]
	for index in [0, 1, 2, 0, 2, 3]:
		_beam_vertex(tool, corners[index])
	return tool.commit()


func _tick_ring(delta: float) -> void:
	if _ring == null or _ring_pop < 0.0 or _ring_pop >= RING_POP_SEC:
		return
	_ring_pop += delta
	var t := clampf(_ring_pop / RING_POP_SEC, 0.0, 1.0)
	var grown := lerpf(1.0, 1.2, t)
	_ring.scale = Vector3(grown, grown, 1.0)
	_ring.modulate.a = 1.0 - t
	if t >= 1.0:
		_ring.visible = false


func _build_ribbons() -> void:
	_ribbon_l = _make_ribbon("RibbonLeft")
	_ribbon_r = _make_ribbon("RibbonRight")


func _make_ribbon(node_name: String) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.11, 1.17, 0.02)
	body.mesh = mesh
	var paint := _mat(Color(1.0, 0.08, 0.06), 0.55)
	paint.emission_enabled = true
	paint.emission = Color(0.9, 0.04, 0.03)
	body.material_override = paint
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(body)
	return body


func ribbon_state() -> Dictionary:
	var mph := logic.effective_wind_mph()
	var band := KickLogic.ribbon_band(mph)
	return {
		"mph": mph,
		"band": band,
		"lean": KickLogic.ribbon_lean_degrees(band),
		"blow": KickLogic.ribbon_blow(logic.wind_direction),
	}


func _place_ribbons() -> void:
	if _ribbon_l == null or _ribbon_r == null or _post_l == null or _post_r == null:
		return
	var info := ribbon_state()
	var lean := float(info["lean"])
	if lean > 0.0:
		lean += sin(_ribbon_time * 2.4) * 3.0
	var blow: Vector3 = info["blow"]
	var rig := camera_rig(logic.kick_distance, logic.start_lateral_yards)
	var pole := float(rig["pole"])
	# True ribbons are 4 by 42 inches. Past a normal kick that width is a pixel,
	# so they thicken with the posts and stay a streamer on the upright.
	var width := maxf(0.42, pole * 0.9)
	var length := maxf(1.17, pole * 2.4)
	var thick := maxf(0.06, pole * 0.22)
	_pose_ribbon(_ribbon_l, _post_l.position.x, lean, blow, width, length, thick)
	_pose_ribbon(_ribbon_r, _post_r.position.x, lean, blow, width, length, thick)


func _pose_ribbon(body: MeshInstance3D, x: float, lean: float, blow: Vector3, width: float, length: float, thick: float) -> void:
	var mesh := body.mesh as BoxMesh
	if mesh != null:
		mesh.size = Vector3(width, length, thick)
	var hang := Vector3.DOWN
	if lean > 0.5 and blow.length_squared() > 0.0001:
		var axis := Vector3.DOWN.cross(blow.normalized())
		if axis.length_squared() > 0.0001:
			hang = Vector3.DOWN.rotated(axis.normalized(), deg_to_rad(lean))
	var y_axis := hang.normalized()
	var x_axis := y_axis.cross(Vector3.FORWARD)
	if x_axis.length_squared() < 0.0001:
		x_axis = Vector3.RIGHT
	x_axis = x_axis.normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	body.basis = Basis(x_axis, y_axis, z_axis)
	var outward := -1.0 if x < 0.0 else 1.0
	body.position = Vector3(x + outward * width * 0.45, _POST_TOP_Y, 0.2) + y_axis * (length * 0.5)


func _pole(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.position = pos
	body.material_override = _mat(color, 0.55)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(body)
	return body


func _fit_posts(width: float) -> void:
	var half := width * 0.5
	var rig := camera_rig(logic.kick_distance, logic.start_lateral_yards)
	var thick := float(rig["pole"])
	if _post_l != null:
		_post_l.position.x = -half
		var mesh := _post_l.mesh as BoxMesh
		if mesh != null:
			mesh.size.x = thick
			mesh.size.z = thick
	if _post_r != null:
		_post_r.position.x = half
		var mesh := _post_r.mesh as BoxMesh
		if mesh != null:
			mesh.size.x = thick
			mesh.size.z = thick
	if _crossbar != null:
		var mesh := _crossbar.mesh as BoxMesh
		if mesh != null:
			mesh.size.x = width
			mesh.size.y = maxf(0.16, thick * 0.45)
			mesh.size.z = thick


func _build_ball() -> void:
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.28
	shadow_mesh.bottom_radius = 0.28
	shadow_mesh.height = 0.02
	_shadow = MeshInstance3D.new()
	_shadow.mesh = shadow_mesh
	_shadow_mat = _mat(Color(0.02, 0.05, 0.02), 1.0)
	_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_mat.albedo_color.a = BALL_SHADOW_TEE_ALPHA
	_shadow.material_override = _shadow_mat
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(_shadow)
	_ball_edge = Sprite3D.new()
	_style_sprite(_ball_edge, BALL_TEE_HEIGHT_YD)
	_ball_edge.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_ball_edge.visible = false
	_world.add_child(_ball_edge)
	_ball = Sprite3D.new()
	_style_sprite(_ball, BALL_TEE_HEIGHT_YD)
	_ball.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_fit_sprite(_ball, "res://art/field/football.png")
	_world.add_child(_ball)
	var tee_mesh := CylinderMesh.new()
	tee_mesh.top_radius = 0.02
	tee_mesh.bottom_radius = 0.09
	tee_mesh.height = 0.16
	_tee = MeshInstance3D.new()
	_tee.mesh = tee_mesh
	_tee.material_override = _mat(Color(0.95, 0.42, 0.12), 0.7)
	_world.add_child(_tee)
	_arrow = MeshInstance3D.new()
	_arrow.name = "AimCone"
	var gel := StandardMaterial3D.new()
	gel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gel.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gel.vertex_color_use_as_albedo = true
	gel.albedo_color = Color.WHITE
	gel.cull_mode = BaseMaterial3D.CULL_DISABLED
	gel.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	gel.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_arrow.material_override = gel
	_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(_arrow)
	_trail = MeshInstance3D.new()
	_trail.name = "BallTrail"
	var ribbon := StandardMaterial3D.new()
	ribbon.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ribbon.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ribbon.vertex_color_use_as_albedo = true
	ribbon.albedo_color = Color.WHITE
	ribbon.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbon.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	ribbon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_trail.material_override = ribbon
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_trail.visible = false
	_world.add_child(_trail)
	var mud_mesh := BoxMesh.new()
	mud_mesh.size = Vector3(1.8, 0.04, 1.35)
	_mud = MeshInstance3D.new()
	_mud.mesh = mud_mesh
	_mud.material_override = _mat(Color(0.38, 0.24, 0.12), 0.95)
	_mud.visible = false
	_world.add_child(_mud)


func _build_kicker_sprite() -> void:
	_kicker_sprite = Sprite3D.new()
	_style_sprite(_kicker_sprite, 2.7)
	_kicker_sprite.visible = false
	_world.add_child(_kicker_sprite)


func _style_sprite(sprite: Sprite3D, height_yards: float) -> void:
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.01
	sprite.set_meta("height_yards", height_yards)


func _fit_sprite(sprite: Sprite3D, path: String) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		sprite.visible = false
		return
	sprite.texture = tex
	sprite.visible = true
	var image := tex.get_image()
	if image != null:
		var used := image.get_used_rect()
		if used.size.y > 1.0:
			sprite.region_enabled = true
			sprite.region_rect = used
			var height_yards := float(sprite.get_meta("height_yards", 2.0))
			sprite.pixel_size = height_yards / used.size.y
	sprite.centered = true


func _place_world() -> void:
	_ensure_field(logic.kick_distance)
	_apply_sky(run.weather)
	_apply_weather(run.weather)
	_apply_ball_sprite()
	# The cone and the kicker read the spot directly. The ball reads ball_lateral_yards,
	# which stays on the previous mark until sync_tee(). A teed ball has to follow the spot.
	if logic.phase != KickLogic.Phase.FLIGHT and logic.phase != KickLogic.Phase.RESULT:
		logic.sync_tee()
	var tee := _tee_position()
	var spot := _ball_position()
	_ball.position = spot
	_tee.position = tee + Vector3(0, 0.08, 0)
	_tee.visible = logic.ball_forward_yards < 0.2
	_shadow.position = Vector3(spot.x, 0.05, spot.z)
	if _mud != null:
		_mud.visible = run.has_mud()
		_mud.position = tee + Vector3(0.0, 0.06, 0.15)
	_fit_posts(run.post_width())
	_apply_post_slide()
	_place_ribbons()
	_place_ring()
	_place_kicker(tee)
	_place_arrow(tee)
	_sample_trail()
	_apply_lights_look()
	_place_camera()
	_pose_ball()


func _reset_kick_pose() -> void:
	_pose = "idle"
	_run_time = 0.0
	_swing_time = 0.0
	_swing_from = KickLogic.PLANT_Z + KickLogic.START_BEHIND
	_early_swing = false
	_swinging = false


func _step_kick_pose(delta: float) -> void:
	var phase := logic.phase
	if phase == KickLogic.Phase.AIMING or phase == KickLogic.Phase.POWER:
		_pose = "idle"
		_run_time = 0.0
		_swinging = false
		_swing_time = 0.0
		return
	if phase == KickLogic.Phase.ACCURACY:
		_swinging = false
		_swing_time = 0.0
		if logic.needle <= KickLogic.APPROACH_AT:
			_pose = "run"
			_run_time += delta
		else:
			_pose = "idle"
			_run_time = 0.0
		return
	if phase != KickLogic.Phase.FLIGHT and phase != KickLogic.Phase.RESULT:
		return
	if phase == KickLogic.Phase.RESULT and not run.practicing:
		var celebrate := Kickers.is_make_result(logic.shanked, logic.result_text) or logic.result_text == "BONUS RING"
		_pose = Kickers.reaction_pose(result_age, celebrate)
		return
	if not _swinging:
		_swinging = true
		_swing_time = 0.0
		_swing_from = _kicker_behind()
		# Still above the run threshold, or not yet waiting at the gather: squeeze the rest.
		var gathered := _pose == "run" and _run_time >= KickLogic.RUN_TO_GATHER_SEC - 0.001
		_early_swing = not gathered
	_swing_time += delta
	if _early_swing:
		if _swing_time < KickLogic.EARLY_RUN_SEC:
			_pose = "run"
		elif _swing_time < KickLogic.EARLY_RUSH_SEC:
			_pose = "plant"
		else:
			_pose = "follow"
	elif _swing_time < KickLogic.PLANT_BEAT:
		_pose = "plant"
	else:
		_pose = "follow"


func pose_for_shot(mode: String) -> void:
	_reset_kick_pose()
	if mode == "idle" or mode == "power":
		_pose = "idle"
		logic.phase = KickLogic.Phase.AIMING if mode == "idle" else KickLogic.Phase.POWER
		logic.needle = 55.0
		logic.needle_angle = 90.0 if mode == "idle" else MeterGauge.power_angle(55.0)
		logic.fill_power = 0.0 if mode == "idle" else 55.0
		logic.windup_left = 0.0
	elif mode == "high":
		_pose = "idle"
		logic.phase = KickLogic.Phase.ACCURACY
		logic.power = 80.0
		logic.fill_power = 80.0
		logic.needle = 70.0
		logic.needle_angle = MeterGauge.power_angle(70.0)
	elif mode == "run":
		_pose = "run"
		_run_time = 0.18
		logic.phase = KickLogic.Phase.ACCURACY
		logic.power = 80.0
		logic.fill_power = 80.0
		logic.needle = 30.0
		logic.needle_angle = MeterGauge.angle_from_error(0.0)
	elif mode == "plant":
		_pose = "plant"
		_swinging = true
		_run_time = KickLogic.RUN_TO_GATHER_SEC
		_swing_time = KickLogic.PLANT_BEAT
		_early_swing = false
		logic.phase = KickLogic.Phase.FLIGHT
		logic.flight_elapsed = 0.04
		logic.flight_duration = 2.0
		logic.travel_yards = 50.0
		logic.reached_uprights = true
	elif mode == "follow":
		_pose = "follow"
		_swinging = true
		_run_time = KickLogic.RUN_TO_GATHER_SEC
		_swing_time = 0.2
		_early_swing = false
		logic.phase = KickLogic.Phase.FLIGHT
		logic.flight_elapsed = 0.16
		logic.flight_duration = 2.0
		logic.travel_yards = 50.0
		logic.reached_uprights = true
	elif mode == "early":
		_pose = "run"
		_early_swing = true
		_swinging = true
		_swing_from = KickLogic.PLANT_Z + KickLogic.START_BEHIND
		_swing_time = 0.1
		logic.phase = KickLogic.Phase.FLIGHT
		logic.flight_elapsed = 0.1
		logic.flight_duration = 2.0
		logic.travel_yards = 50.0
		logic.reached_uprights = true
	refresh_view()


func _kicker_art_path() -> String:
	if run.kicker_id == "":
		return ""
	if _pose.begins_with("react_"):
		return Kickers.field_frame(run.kicker_id, _pose)
	var pose := "idle"
	if _pose == "run":
		pose = "run"
	elif _pose == "plant":
		pose = "plant"
	elif _pose == "follow":
		pose = "follow"
	return Kickers.field_frame(run.kicker_id, pose)


func _kicker_behind() -> float:
	return KickLogic.approach_z(_pose, _run_time, _swing_time, _early_swing, _swing_from)


func _place_kicker(tee: Vector3) -> void:
	if _kicker_sprite == null:
		return
	var path := _kicker_art_path()
	if path == "":
		_kicker_sprite.visible = false
		return
	var reacting := _pose.begins_with("react_")
	if str(_kicker_sprite.get_meta("art", "")) != path:
		if reacting:
			_apply_reaction_frame(path)
		else:
			_fit_sprite(_kicker_sprite, path)
		_kicker_sprite.set_meta("art", path)
	if reacting:
		# Same pixels-per-yard as this kicker's follow-through. Feet stay on row 565.
		var px := _kick_pixel_size(run.kicker_id)
		_kicker_sprite.pixel_size = px
		_kicker_sprite.region_enabled = false
		_kicker_sprite.centered = true
		var foot := (565.0 - 360.0) * px
		_kicker_sprite.position = tee + Vector3(-1.45, foot, KickLogic.PLANT_Z)
		return
	var height := _kicker_sprite.pixel_size * _kicker_sprite.region_rect.size.y
	var bob := 0.0
	if _pose == "run":
		bob = sin((_run_time + _swing_time) * 16.0) * 0.05
	_kicker_sprite.position = tee + Vector3(-1.45, height * 0.5 + bob, _kicker_behind())


var _kick_pixels := {}


func _kick_pixel_size(id: String) -> float:
	if _kick_pixels.has(id):
		return float(_kick_pixels[id])
	var height := 2.7
	var follow := Kickers.field_frame(id, "follow")
	var tex := load(follow) as Texture2D
	if tex != null:
		var image := tex.get_image()
		if image != null:
			var used := image.get_used_rect()
			if used.size.y > 1.0:
				height = 2.7 / float(used.size.y)
			else:
				height = 2.7 / 360.0
		else:
			height = 2.7 / 360.0
	else:
		height = 2.7 / 360.0
	_kick_pixels[id] = height
	return height


func _apply_reaction_frame(path: String) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		_kicker_sprite.visible = false
		return
	_kicker_sprite.texture = tex
	_kicker_sprite.visible = true
	_kicker_sprite.region_enabled = false
	_kicker_sprite.centered = true
	_kicker_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_kicker_sprite.pixel_size = _kick_pixel_size(run.kicker_id)


func _tee_position() -> Vector3:
	return Vector3(logic.start_lateral_yards, 0.0, KickLogic.visual_span(logic.kick_distance))


func _ball_position() -> Vector3:
	var forward := logic.ball_forward_yards
	var lateral := logic.ball_lateral_yards
	var height := _arc_height(forward)
	if logic.bank_shot and logic.phase == KickLogic.Phase.RESULT:
		var bounce := clampf(_bank_time / 0.3, 0.0, 1.0)
		lateral = lerpf(logic.offset_yards, 0.0, bounce)
		height = sin(bounce * PI) * 1.6
		forward = logic.kick_distance
	elif logic.result_text == "DOINK" and (logic.phase == KickLogic.Phase.FLIGHT or logic.phase == KickLogic.Phase.RESULT):
		# The hop is off the post, even when the ball still had range past it.
		var posts := logic.kick_distance
		var start_bounce := posts - 4.0
		if forward >= start_bounce:
			var along := clampf((minf(forward, posts) - start_bounce) / 4.0, 0.0, 1.0)
			forward = minf(forward, posts) - along * 4.5
			var side := -1.0 if logic.offset_yards < 0.0 else 1.0
			lateral += side * along * 2.2
			height = _arc_height(forward) * (1.0 - along) + sin(along * PI) * 2.4
	var y := height
	if y < 0.2:
		y = 0.22
	var real := maxf(logic.kick_distance, 0.001)
	var span := KickLogic.visual_span(real)
	return Vector3(lateral, y, span - forward * (span / real))


func _arc_height(forward: float) -> float:
	# Visual only. A ball that reaches the posts is still above the crossbar there.
	# A short kick is back on the ground before that plane. Scoring does not use this.
	if logic.phase != KickLogic.Phase.FLIGHT and logic.phase != KickLogic.Phase.RESULT:
		return 0.0
	var travel := maxf(logic.travel_yards, 0.001)
	var dist := maxf(logic.kick_distance, 0.001)
	var peak := dist if logic.reached_uprights else travel
	if forward <= peak:
		return sin(clampf(forward / peak, 0.0, 1.0) * PI * 0.5) * ARC_YARDS
	var rest := maxf(travel - peak, 0.001)
	return (1.0 - clampf((forward - peak) / rest, 0.0, 1.0)) * ARC_YARDS


func world_to_screen(point: Vector3) -> Vector2:
	return _camera.unproject_position(point)


func project_flight_point(forward: float, lateral: float, travel: float, reached: bool) -> Variant:
	var point := KickLogic.flight_visual_point(forward, lateral, logic.kick_distance, travel, reached)
	if _camera == null or _camera.is_position_behind(point):
		return null
	return _camera.unproject_position(point)


func _place_arrow(tee: Vector3) -> void:
	var show := logic.phase == KickLogic.Phase.AIMING or logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY
	_arrow.visible = show
	if not show:
		aim_corridor["visible"] = false
		return
	var aim := deg_to_rad(logic.aim_degrees)
	var dir := Vector3(sin(aim), 0.0, -cos(aim))
	var side := Vector3(cos(aim), 0.0, sin(aim))
	var full_reach := tee.z / maxf(cos(aim), 0.25)
	var post_half := run.post_width() * 0.5
	var origin := Vector3(tee.x, 0.09, tee.z)
	var crop := _cone_crop(origin, dir, side, full_reach, post_half)
	var far: Vector3 = crop["far"]
	var left: Vector3 = crop["left"]
	var right: Vector3 = crop["right"]
	aim_corridor = {
		"visible": true,
		"origin": origin,
		"far": far,
		"width": float(crop["width"]),
		"length": float(crop["shown"]),
		"left": left,
		"right": right,
	}
	var boost := 1.0
	if logic.kick_distance >= 500.0:
		boost = 1.28
	elif logic.kick_distance >= 200.0:
		boost = 1.12
	var fade := 1.0
	if too_weak_age >= 0.0:
		fade = 0.0 if too_weak_age >= RunLogic.TOO_WEAK_BEAT else 1.0 - too_weak_age / RunLogic.TOO_WEAK_BEAT
	if fade <= 0.01:
		_arrow.visible = false
		aim_corridor["visible"] = false
		return
	_arrow.position = Vector3.ZERO
	_arrow.rotation = Vector3.ZERO
	_arrow.mesh = _aim_cone_mesh(origin, dir, side, crop, boost, fade)


func _cone_crop(origin: Vector3, dir: Vector3, side: Vector3, full_reach: float, post_half: float) -> Dictionary:
	# The imaginary corridor still runs tee-to-posts and opens to the inside post width.
	# The drawn gel stops at 5 yards, or at the goal line when that is closer.
	var shown := minf(CONE_LENGTH_YARDS, maxf(full_reach, 0.0))
	var span := maxf(full_reach - CONE_MOUTH_YARDS, 0.001)
	var along := 0.0
	if shown > CONE_MOUTH_YARDS:
		along = clampf((shown - CONE_MOUTH_YARDS) / span, 0.0, 1.0)
	var near_c := origin + dir * CONE_MOUTH_YARDS
	var far_full := origin + dir * full_reach
	var goal := Vector3(1.0, 0.0, 0.0)
	var near_l := near_c - side * CONE_NEAR_HALF
	var near_r := near_c + side * CONE_NEAR_HALF
	var far_l := far_full - goal * post_half
	var far_r := far_full + goal * post_half
	var left := near_l.lerp(far_l, along)
	var right := near_r.lerp(far_r, along)
	var far := near_c.lerp(far_full, along)
	left.y = origin.y
	right.y = origin.y
	far.y = origin.y
	var axis := goal
	if left.distance_to(right) > 0.001:
		axis = (right - left).normalized()
	return {
		"shown": shown,
		"far": far,
		"left": left,
		"right": right,
		"width": left.distance_to(right),
		"half": left.distance_to(right) * 0.5,
		"axis": axis,
	}


func _aim_cone_mesh(origin: Vector3, dir: Vector3, side: Vector3, crop: Dictionary, boost: float, fade: float = 1.0) -> ArrayMesh:
	var near_c := origin + dir * CONE_MOUTH_YARDS
	var far_c: Vector3 = crop["far"]
	near_c.y = origin.y
	far_c.y = origin.y
	var far_half := float(crop["half"])
	var far_axis: Vector3 = crop["axis"]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gel_near := Color(1.0, 0.07, 0.05, minf(0.72, 0.58 * boost) * fade)
	var gel_far := Color(1.0, 0.08, 0.04, minf(0.55, 0.36 * boost) * fade)
	_cone_layer(tool, near_c, far_c, side, far_axis, CONE_NEAR_HALF, far_half, 0.09, gel_near, gel_far)
	var rim_near := Color(0.95, 0.1, 0.03, minf(0.95, 0.88 * boost) * fade)
	var rim_far := Color(0.86, 0.07, 0.03, minf(0.78, 0.55 * boost) * fade)
	_cone_edges(tool, near_c, far_c, side, far_axis, CONE_NEAR_HALF, far_half, CONE_NEAR_HALF + 0.045, far_half + 0.045, 0.094, rim_near, rim_far)
	var line_near := Color(0.22, 0.02, 0.02, 0.9 * fade)
	var line_far := Color(0.16, 0.02, 0.02, 0.55 * fade)
	_cone_edges(tool, near_c, far_c, side, far_axis, CONE_NEAR_HALF + 0.045, far_half + 0.045, CONE_NEAR_HALF + 0.08, far_half + 0.08, 0.086, line_near, line_far)
	return tool.commit()


func _cone_layer(tool: SurfaceTool, near_c: Vector3, far_c: Vector3, near_axis: Vector3, far_axis: Vector3, near_half: float, far_half: float, y: float, near_color: Color, far_color: Color) -> void:
	var a := near_c - near_axis * near_half
	var b := near_c + near_axis * near_half
	var c := far_c + far_axis * far_half
	var d := far_c - far_axis * far_half
	a.y = y
	b.y = y
	c.y = y
	d.y = y
	var corners := [a, b, c, d]
	var colors := [near_color, near_color, far_color, far_color]
	for index in [0, 1, 2, 0, 2, 3]:
		tool.set_color(colors[index])
		tool.add_vertex(corners[index])


func _cone_edges(tool: SurfaceTool, near_c: Vector3, far_c: Vector3, near_axis: Vector3, far_axis: Vector3, inner_near: float, inner_far: float, outer_near: float, outer_far: float, y: float, near_color: Color, far_color: Color) -> void:
	for sign_value in [-1.0, 1.0]:
		var sign := float(sign_value)
		var a := near_c + near_axis * (sign * inner_near)
		var b := near_c + near_axis * (sign * outer_near)
		var c := far_c + far_axis * (sign * outer_far)
		var d := far_c + far_axis * (sign * inner_far)
		a.y = y
		b.y = y
		c.y = y
		d.y = y
		var corners := [a, b, c, d]
		var colors := [near_color, near_color, far_color, far_color]
		for index in [0, 1, 2, 0, 2, 3]:
			tool.set_color(colors[index])
			tool.add_vertex(corners[index])


func trail_count() -> int:
	return _trail_points.size()


func trail_visible() -> bool:
	return _trail != null and _trail.visible


func trail_head() -> Vector3:
	if _trail_points.is_empty():
		return Vector3.ZERO
	return _trail_points[_trail_points.size() - 1]


func trail_point(index: int) -> Vector3:
	return _trail_points[index]


func trail_alpha() -> float:
	return _trail_alpha


func trail_head_color() -> Color:
	return _trail_vertex_color(1.0)


func lock_shown_flight(power_value: float) -> void:
	# Stops when the ball leaves the tee. The flight itself is sampled later.
	_clear_trail()
	logic.press_space()
	if logic.windup_left > 0.0:
		logic.advance(logic.windup_left)
	if power_value >= KickConstants.METER_MAX - 0.001:
		logic.take_power_press(logic.seconds_to_power(power_value))
	else:
		logic.advance(logic.seconds_to_power(power_value))
		if logic.phase == KickLogic.Phase.POWER:
			logic.press_space()
	if logic.phase == KickLogic.Phase.ACCURACY:
		var wait := logic.seconds_until_error(0.0)
		if wait > 0.0:
			logic.advance(wait)
		if logic.phase == KickLogic.Phase.ACCURACY:
			logic.press_space()


func fly_and_sample(fraction: float) -> void:
	if logic.phase != KickLogic.Phase.FLIGHT and logic.phase != KickLogic.Phase.RESULT:
		return
	var end := clampf(fraction, 0.0, 1.0) * maxf(logic.flight_duration, 0.0)
	var guard := 0
	while logic.flight_elapsed < end - 0.00001 and logic.phase == KickLogic.Phase.FLIGHT and guard < 500:
		var step_dt := minf(0.04, end - logic.flight_elapsed)
		if step_dt <= 0.0:
			break
		logic.advance(step_dt)
		_sample_trail()
		guard += 1
	_sample_trail()
	refresh_view()


func tick_trail(delta: float) -> void:
	if logic.phase != KickLogic.Phase.FLIGHT and logic.phase != KickLogic.Phase.RESULT:
		return
	var fading := run.awaiting_offer or run.awaiting_shop
	if run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN or run.phase == RunLogic.Phase.FAR:
		fading = true
	if not fading:
		return
	_trail_fade += delta
	_trail_alpha = clampf(1.0 - _trail_fade / TRAIL_FADE_SEC, 0.0, 1.0)


static func ball_tumble_sy(theta: float) -> float:
	var c := cos(theta)
	var mag := maxf(absf(c), BALL_TUMBLE_MIN)
	var sgn := -1.0 if c < 0.0 else 1.0
	return sgn * mag


static func ball_spin_rps(power: float, overpower: bool, shank: bool) -> float:
	var rate := lerpf(BALL_SPIN_MIN_RPS, BALL_SPIN_MAX_RPS, clampf(power / 100.0, 0.0, 1.0))
	if overpower:
		rate = BALL_SPIN_OVERPOWER_RPS
	if shank:
		rate *= BALL_SHANK_SPIN
	return rate


static func ball_shadow_factor(height: float) -> float:
	return 1.0 / (1.0 + maxf(height, 0.0) / BALL_SHADOW_FALLOFF_YD)


static func ball_shadow_alpha_at(height: float) -> float:
	var along := clampf(maxf(height, 0.0) / BALL_SHADOW_PEAK_YD, 0.0, 1.0)
	return lerpf(BALL_SHADOW_TEE_ALPHA, BALL_SHADOW_MIN_ALPHA, along)


static func ball_pop_at(height: float) -> float:
	return 1.0 + BALL_POP * clampf(maxf(height, 0.0) / BALL_POP_PEAK_YD, 0.0, 1.0)


static func ball_size_boost(measured_px: float, view_h: float) -> float:
	if measured_px <= 0.01 or view_h <= 1.0:
		return 1.0
	var min_px := BALL_MIN_PIXELS * (view_h / BALL_MIN_REF_HEIGHT)
	return maxf(1.0, min_px / measured_px)


func ball_in_flight() -> bool:
	return logic.phase == KickLogic.Phase.FLIGHT or logic.phase == KickLogic.Phase.RESULT


func ball_tumble_live() -> bool:
	return ball_in_flight() and logic.ball_forward_yards >= BALL_TRAIL_START_YD


func _sync_ball_edge() -> void:
	if _ball_edge == null or _ball == null:
		return
	_ball_edge.texture = _ball.texture
	_ball_edge.region_enabled = _ball.region_enabled
	_ball_edge.region_rect = _ball.region_rect
	_ball_edge.pixel_size = _ball.pixel_size
	_ball_edge.centered = true
	_ball_edge.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_ball.billboard = BaseMaterial3D.BILLBOARD_DISABLED


func _note_ball_doink() -> void:
	if _ball_doinked or not ball_in_flight():
		return
	var hit := logic.result_text == "DOINK" or logic.bank_shot
	if not hit:
		return
	if logic.ball_forward_yards >= logic.kick_distance - 4.0 or logic.phase == KickLogic.Phase.RESULT:
		_ball_doinked = true
		_ball_doink_time = logic.flight_elapsed


func _ball_theta() -> float:
	var rate := ball_spin_rps(logic.power, logic.overpower_paid, logic.shanked)
	var t := logic.flight_elapsed
	if _ball_doinked:
		var t0 := _ball_doink_time
		return rate * TAU * t0 - rate * TAU * maxf(t - t0, 0.0)
	return rate * TAU * t


func _ball_roll_sx(t: float) -> Dictionary:
	if logic.shanked:
		var mixed := 0.5 * (sin(TAU * BALL_SHANK_HZ_A * t) + sin(TAU * BALL_SHANK_HZ_B * t))
		var roll := deg_to_rad(BALL_SHANK_ROLL_DEG) * mixed
		var sx := lerpf(BALL_SHANK_SX_MIN, 1.0, 0.5 + 0.5 * sin(TAU * BALL_SHANK_HZ_A * t))
		return {"roll": roll, "sx": sx}
	var roll := deg_to_rad(BALL_ROLL_DEG) * sin(TAU * BALL_ROLL_HZ * t)
	return {"roll": roll, "sx": 1.0}


func _face_sprite(sprite: Sprite3D, roll: float, sx: float, sy: float) -> void:
	if _camera == null or sprite == null:
		return
	var to_cam := _camera.global_position - sprite.global_position
	if to_cam.length_squared() < 0.0001:
		return
	var normal := to_cam.normalized()
	var up := _camera.global_transform.basis.y
	var right := up.cross(normal)
	if right.length_squared() < 0.0001:
		right = _camera.global_transform.basis.x
	right = right.normalized()
	up = normal.cross(right).normalized()
	var c := cos(roll)
	var s := sin(roll)
	var rolled_right := right * c + up * s
	var rolled_up := -right * s + up * c
	sprite.global_basis = Basis(rolled_right, rolled_up, normal)
	sprite.scale = Vector3(sx, sy, 1.0)


func sprite_screen_height(sprite: Sprite3D) -> float:
	if sprite == null or _camera == null or not sprite.visible:
		return 0.0
	var tex_h := 0.0
	if sprite.region_enabled:
		tex_h = sprite.region_rect.size.y
	elif sprite.texture != null:
		tex_h = float(sprite.texture.get_height())
	var world_h := sprite.pixel_size * tex_h * absf(sprite.scale.y)
	if world_h <= 0.001:
		return 0.0
	var up := sprite.global_transform.basis.y
	if up.length_squared() < 0.0001:
		up = Vector3.UP
	up = up.normalized()
	var top := sprite.global_position + up * world_h * 0.5
	var bottom := sprite.global_position - up * world_h * 0.5
	if _camera.is_position_behind(top) or _camera.is_position_behind(bottom):
		return 0.0
	return _camera.unproject_position(top).distance_to(_camera.unproject_position(bottom))


func _long_axis_pixels(world_h: float, at: Vector3) -> float:
	if _camera == null or world_h <= 0.0 or _camera.is_position_behind(at):
		return 0.0
	var up := _camera.global_transform.basis.y
	var a := _camera.unproject_position(at)
	var b := _camera.unproject_position(at + up * world_h)
	return a.distance_to(b)


func _pose_ball() -> void:
	if _ball == null or _shadow == null:
		return
	var spot := _ball.position
	var flying := ball_in_flight()
	var tumbling := ball_tumble_live()
	_note_ball_doink()
	var height := spot.y
	var pop := ball_pop_at(height) if flying else 1.0
	var view_h := 720.0
	if get_viewport() != null:
		view_h = get_viewport().get_visible_rect().size.y
	var long_world := BALL_TEE_HEIGHT_YD * pop
	var boost := 1.0
	if flying:
		boost = ball_size_boost(_long_axis_pixels(long_world, spot), view_h)
	var sx := 1.0
	var sy := 1.0
	var roll := 0.0
	if tumbling:
		var pose := _ball_roll_sx(logic.flight_elapsed)
		sx = float(pose["sx"])
		roll = float(pose["roll"])
		sy = ball_tumble_sy(_ball_theta())
		if _ball_doinked:
			var age := logic.flight_elapsed - _ball_doink_time
			if age >= 0.0 and age <= BALL_DOINK_ROLL_SEC:
				roll += deg_to_rad(BALL_DOINK_ROLL_DEG) * sin(PI * age / BALL_DOINK_ROLL_SEC)
	if logic.phase == KickLogic.Phase.RESULT and tumbling:
		if not _ball_held:
			_ball_held = true
			_ball_hold_sy = sy
			_ball_hold_sx = sx
			_ball_hold_roll = roll
		var u := clampf(result_age / BALL_SETTLE_SEC, 0.0, 1.0)
		sy = lerpf(_ball_hold_sy, 1.0, u)
		sx = lerpf(_ball_hold_sx, 1.0, u)
		roll = lerpf(_ball_hold_roll, 0.0, u)
	else:
		_ball_held = false
	var scale_x := sx * pop * boost
	var scale_y := sy * pop * boost
	_face_sprite(_ball, roll, scale_x, scale_y)
	if _ball_edge != null:
		_sync_ball_edge()
		var show_edge := BALL_EDGE_ON and _ball.visible
		_ball_edge.visible = show_edge
		if show_edge and _camera != null:
			var art := (BALL_TEE_HEIGHT_YD * pop * boost) / BALL_ART_LONG_PX
			var right := _camera.global_transform.basis.x
			var down := -_camera.global_transform.basis.y
			var away := _ball.global_position - _camera.global_position
			if away.length_squared() > 0.0001:
				away = away.normalized()
			_ball_edge.global_position = _ball.global_position + right * art + down * art + away * 0.05
			_face_sprite(_ball_edge, roll, scale_x, scale_y)
			var ink := _ball.modulate
			_ball_edge.modulate = Color(ink.r * BALL_EDGE_BRIGHTNESS, ink.g * BALL_EDGE_BRIGHTNESS, ink.b * BALL_EDGE_BRIGHTNESS, ink.a)
	var shadow_scale := 1.0
	var shadow_alpha := BALL_SHADOW_TEE_ALPHA
	var oval := 1.0
	if flying:
		shadow_scale = ball_shadow_factor(height)
		shadow_alpha = ball_shadow_alpha_at(height)
		oval = BALL_SHADOW_OVAL
	_shadow.scale = Vector3(shadow_scale, 1.0, shadow_scale * oval)
	if _shadow_mat != null:
		_shadow_mat.albedo_color.a = shadow_alpha


func _clear_trail() -> void:
	_trail_points = PackedVector3Array()
	_trail_alpha = 1.0
	_trail_fade = 0.0
	_ball_doinked = false
	_ball_doink_time = 0.0
	_ball_held = false
	_ball_hold_sy = 1.0
	_ball_hold_sx = 1.0
	_ball_hold_roll = 0.0
	if _trail != null:
		_trail.visible = false


func _sample_trail() -> void:
	if _trail == null:
		return
	if logic.phase != KickLogic.Phase.FLIGHT and logic.phase != KickLogic.Phase.RESULT:
		if not _trail_points.is_empty():
			_clear_trail()
		else:
			_trail.visible = false
		return
	if logic.ball_forward_yards < 0.12:
		return
	var spot := _ball_position()
	var step := maxf(0.22, logic.travel_yards / float(TRAIL_POINT_CAP - 2))
	if _trail_points.is_empty():
		_trail_points.append(spot)
		_trail_points.append(spot)
	else:
		var anchor: Vector3 = _trail_points[_trail_points.size() - 2]
		if anchor.distance_to(spot) >= step:
			_trail_points.append(spot)
			if _trail_points.size() > TRAIL_POINT_CAP:
				_thin_trail()
		else:
			_trail_points[_trail_points.size() - 1] = spot
	_rebuild_trail()


func _thin_trail() -> void:
	var kept := PackedVector3Array()
	var last := _trail_points.size() - 1
	for index in _trail_points.size():
		if index == 0 or index == last or index % 2 == 0:
			kept.append(_trail_points[index])
	_trail_points = kept


func _trail_half_width(point: Vector3) -> float:
	var half := TRAIL_WORLD_HALF
	if _camera == null or _camera.is_position_behind(point):
		return half
	var origin := _camera.unproject_position(point)
	var nudged := _camera.unproject_position(point + _camera.global_transform.basis.x)
	var pixels := origin.distance_to(nudged)
	if pixels < 0.25:
		return half
	return maxf(half, TRAIL_MIN_PIXELS / pixels * 0.5)


func _rebuild_trail() -> void:
	if _trail == null:
		return
	if _trail_points.size() < 2 or _trail_alpha <= 0.02:
		_trail.visible = false
		return
	var last: Vector3 = _trail_points[_trail_points.size() - 1]
	var first: Vector3 = _trail_points[0]
	if first.distance_to(last) < 0.08:
		_trail.visible = false
		return
	var drawn := PackedVector3Array()
	for index in _trail_points.size():
		drawn.append(_trail_points[index])
	var before: Vector3 = drawn[drawn.size() - 2]
	var toward := last - before
	if toward.length() > 0.36:
		drawn[drawn.size() - 1] = last - toward.normalized() * 0.28
	var count := drawn.size()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in count - 1:
		var a: Vector3 = drawn[index]
		var b: Vector3 = drawn[index + 1]
		var span := b - a
		var width_a := _trail_half_width(a)
		var width_b := _trail_half_width(b)
		var side := _trail_side(span)
		var t0 := float(index) / float(count - 1)
		var t1 := float(index + 1) / float(count - 1)
		var c0 := _trail_vertex_color(t0)
		var c1 := _trail_vertex_color(t1)
		var a_l := a - side * width_a
		var a_r := a + side * width_a
		var b_l := b - side * width_b
		var b_r := b + side * width_b
		_trail_tri(tool, a_l, b_l, b_r, c0, c1, c1)
		_trail_tri(tool, a_l, b_r, a_r, c0, c1, c0)
	_trail.mesh = tool.commit()
	_trail.visible = true


func _trail_side(span: Vector3) -> Vector3:
	var right := Vector3(1.0, 0.0, 0.0)
	var up := Vector3(0.0, 1.0, 0.0)
	if _camera != null:
		right = _camera.global_transform.basis.x
		up = _camera.global_transform.basis.y
	var side := right
	if span.length_squared() > 0.0001 and absf(span.normalized().dot(right.normalized())) > 0.82:
		side = up
	if side.length_squared() < 0.0001:
		side = Vector3(1.0, 0.0, 0.0)
	return side.normalized()


func _trail_vertex_color(along: float) -> Color:
	var fade := lerpf(0.62, 0.96, along)
	var color := TRAIL_COLOR
	color.a = fade * _trail_alpha
	return color


func _trail_tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	tool.set_color(ca)
	tool.add_vertex(a)
	tool.set_color(cb)
	tool.add_vertex(b)
	tool.set_color(cc)
	tool.add_vertex(c)


func _place_camera() -> void:
	# The camera rides with the tee. It looks along the tee's line, not at the posts,
	# so a left spot leaves the posts on the right of the screen and a right spot does the opposite.
	var rig := camera_rig(logic.kick_distance, logic.start_lateral_yards)
	var at: Vector3 = rig["position"]
	_camera.position = at
	_camera.fov = float(rig["fov"])
	_camera.look_at(rig["look"], Vector3.UP)
	_camera.far = maxf(400.0, at.z + 80.0)
	_frame_sky(rig)
	_place_weather()
	var sun := $Sun as DirectionalLight3D
	if sun != null:
		sun.directional_shadow_max_distance = maxf(160.0, at.z + 40.0)


const YARD_PIXEL_SIZE := 0.0105
const YARD_WORLD_H := 0.756
const YARD_MIN_PX := 7.0
const YARD_TARGET_PX := 13.0
const YARD_MAX_SCALE := 12.0
const YARD_NEAR_YARDS := 80.0
const YARD_GAP_RATIO := 0.46
# Sidelines are the white lines at ±25 (the grass is 54 yards wide). The old
# columns sat at ±5.6, between the hash and the wide spot, so a 62 sat on the cone.
# 15 yards off center is 10 yards inside that sideline, clear of every kick spot.
const FIELD_SIDELINE_X := 25.0
const YARD_NUMBER_X := 15.0
# Cull still measures at the old column so the C3B set of numbers does not change.
const YARD_MEASURE_X := 5.6


func yard_line_rank(span: float, yard: float) -> int:
	# 5 and 10 stay on a 35 or 75. Farther fields drop a line before it becomes a grill.
	var y := int(round(yard))
	if y < 0 or float(y) > span + 0.01:
		return 0
	if span <= YARD_NEAR_YARDS:
		if y % 5 != 0:
			return 0
		return 10 if y % 10 == 0 else 5
	var gap5 := _pixels_per_yard(span, float(y)) * 5.0
	if y % 5 == 0 and gap5 >= 5.2:
		return 10 if y % 10 == 0 else 5
	if y % 10 == 0 and gap5 * 2.0 >= 4.2:
		return 10
	if y % 50 == 0 and gap5 * 10.0 >= 3.8:
		return 50
	if y % 100 == 0 and gap5 * 20.0 >= 3.0:
		return 100
	return 0


func hash_tick_spacing(span: float, yard: float) -> int:
	# 1 means every yard. 0 means no tick here. The two rows stay at the post x.
	var y := int(round(yard))
	if y < 0 or float(y) > span + 0.01:
		return 0
	if span <= YARD_NEAR_YARDS:
		return 1
	var ppy := _pixels_per_yard(span, float(y))
	if ppy >= 3.2:
		return 1
	if y % 5 == 0 and ppy * 5.0 >= 5.0:
		return 5
	if y % 10 == 0 and ppy * 10.0 >= 4.0:
		return 10
	if y % 50 == 0 and ppy * 50.0 >= 4.0:
		return 50
	if y % 100 == 0 and ppy * 100.0 >= 2.5:
		return 100
	return 0


func yard_numbers_for(span: float) -> PackedInt32Array:
	var result := PackedInt32Array()
	for item in _yard_plan(span):
		result.append(int(item["yard"]))
	return result


func yard_number_scale(span: float, yard: int) -> float:
	for item in _yard_plan(span):
		if int(item["yard"]) == yard:
			return float(item["scale"])
	return 1.0


func yard_numbers_overlap(span: float) -> bool:
	var plan := _yard_plan(span)
	if plan.size() < 2:
		return false
	for index in plan.size() - 1:
		var a: Dictionary = plan[index]
		var b: Dictionary = plan[index + 1]
		var az := float(a["yard"])
		var bz := float(b["yard"])
		var gap := _number_gap(span, az, bz)
		var height := _shown_px(span, az, float(a["scale"])) + _shown_px(span, bz, float(b["scale"]))
		if gap <= height * _gap_ratio(span):
			return true
	return false


# Closest ~80 yards stay on every 10 while a 7px digit still clears the next one.
# After that, every 50. A 50 that would overlap or sit under 7px is skipped, and the
# next mark is a 100. Far marks grow toward 13px when the gap allows it, and they stop
# before they stack on the posts. A 35 or a 75 keeps every 10 all the way, shrinking a
# far digit instead of dropping it.
func _yard_plan(span: float) -> Array:
	var plan: Array = []
	var marks := _ten_yard_marks(span)
	if span <= YARD_NEAR_YARDS + 0.01:
		return _pack_required(span, marks)
	var near_floor := span - YARD_NEAR_YARDS
	for yard in marks:
		if yard != int(round(span)) and float(yard) < near_floor - 0.5:
			break
		if not _fits_fixed(span, float(yard), plan, 1.0):
			break
		var full: Dictionary = {"yard": yard, "scale": 1.0}
		plan.append(full)
	# Every 50 from here to the posts. Skip a mark that would overlap or sit under 7px.
	# What remains is every 50 where it fits, and every 100 (or wider) where it does not.
	var cursor := _next_below(_plan_last(plan), 50, span)
	var guard := 0
	while cursor >= 50 and guard < 40:
		guard += 1
		var scale := _best_far_scale(span, float(cursor), plan, float(cursor - 50))
		if scale > 0.0:
			var kept: Dictionary = {"yard": cursor, "scale": scale}
			plan.append(kept)
		cursor -= 50
	return plan


func _ten_yard_marks(span: float) -> PackedInt32Array:
	var result := PackedInt32Array()
	var tee := int(round(span))
	if tee >= 10:
		result.append(tee)
	var z := int(floor(span / 10.0)) * 10
	if z >= tee:
		z -= 10
	while z >= 10:
		result.append(z)
		z -= 10
	return result


func _pack_required(span: float, marks: PackedInt32Array) -> Array:
	# Every mark stays. Far digits shrink until each pair clears the gap.
	var heights: Array = []
	for yard in marks:
		heights.append(_number_px(span, float(yard)))
	for _pass in 24:
		var dirty := false
		for index in range(1, marks.size()):
			var gap := _number_gap(span, float(marks[index - 1]), float(marks[index]))
			var limit := (gap - 0.15) / _gap_ratio(span)
			var prev_h: float = float(heights[index - 1])
			var here_h: float = float(heights[index])
			if prev_h + here_h <= limit:
				continue
			dirty = true
			var overflow := prev_h + here_h - limit
			var far_floor := 1.6
			var cut := minf(overflow, maxf(0.0, here_h - far_floor))
			heights[index] = here_h - cut
			overflow -= cut
			if overflow > 0.01:
				heights[index - 1] = prev_h - overflow
		if not dirty:
			break
	var plan: Array = []
	for index in marks.size():
		var natural := _number_px(span, float(marks[index]))
		var scale := 1.0
		if natural > 0.01:
			scale = minf(1.0, float(heights[index]) / natural)
		var entry: Dictionary = {"yard": int(marks[index]), "scale": maxf(scale, 0.05)}
		plan.append(entry)
	return plan


func _fits_fixed(span: float, z: float, plan: Array, scale: float) -> bool:
	var height := _shown_px(span, z, scale)
	if height < YARD_MIN_PX:
		return false
	if plan.is_empty():
		return true
	var prev: Dictionary = plan[plan.size() - 1]
	var prev_px := _shown_px(span, float(prev["yard"]), float(prev["scale"]))
	var gap := _number_gap(span, float(prev["yard"]), z)
	return gap > (height + prev_px) * YARD_GAP_RATIO


func _best_far_scale(span: float, z: float, plan: Array, next_z: float) -> float:
	var natural := _number_px(span, z)
	if natural < 0.05:
		return 0.0
	var room := YARD_TARGET_PX
	if not plan.is_empty():
		var prev: Dictionary = plan[plan.size() - 1]
		var prev_px := _shown_px(span, float(prev["yard"]), float(prev["scale"]))
		var gap := _number_gap(span, float(prev["yard"]), z)
		room = gap / YARD_GAP_RATIO - prev_px - 0.45
	var own := minf(YARD_TARGET_PX, minf(natural * YARD_MAX_SCALE, room))
	# Leave a 7px slot for the next mark when the gap can actually hold two.
	if next_z >= 50.0:
		var ahead := _number_gap(span, z, next_z)
		var pair := ahead / YARD_GAP_RATIO - 0.45
		if pair >= YARD_MIN_PX * 2.0 + 1.6:
			own = minf(own, pair - YARD_MIN_PX - 0.8)
	if own < YARD_MIN_PX:
		return 0.0
	return own / natural


func _plan_last(plan: Array) -> int:
	if plan.is_empty():
		return -1
	var last: Dictionary = plan[plan.size() - 1]
	return int(last["yard"])


func _next_below(yard: int, step: int, span: float) -> int:
	if yard < 0:
		return int(floor(span / float(step))) * step
	return int(floor(float(yard - 1) / float(step))) * step


func _gap_ratio(span: float) -> float:
	# A 35 or 75 has to keep every 10. The ink is shorter than the em box, so those
	# required digits may sit closer than a long-field mark.
	if span <= YARD_NEAR_YARDS + 0.01:
		return 0.22
	return YARD_GAP_RATIO


func _shown_px(span: float, z: float, scale: float) -> float:
	return _number_px(span, z) * scale


func _number_gap(span: float, a: float, b: float) -> float:
	var ya := _screen_y(span, Vector3(YARD_MEASURE_X, 1.1, a))
	var yb := _screen_y(span, Vector3(YARD_MEASURE_X, 1.1, b))
	if ya < 0.0 or yb < 0.0:
		return 0.0
	return absf(ya - yb)


func _yard_line_thickness(span: float, yard: float, rank: int) -> float:
	if span <= YARD_NEAR_YARDS:
		return 0.16 if rank >= 10 else 0.10
	var ppy := maxf(_pixels_per_yard(span, yard), 0.05)
	var target := 2.05 if rank >= 10 else 1.55
	return clampf(target / ppy, 0.08, 0.2)


func _yard_line_alpha(span: float, yard: float, rank: int) -> float:
	if span <= YARD_NEAR_YARDS:
		return 1.0 if rank >= 10 else 0.82
	var gap := _pixels_per_yard(span, yard) * float(rank)
	var floor_gap := 3.0
	if rank == 5:
		floor_gap = 5.2
	elif rank == 10:
		floor_gap = 4.2
	elif rank == 50:
		floor_gap = 3.8
	var fade := clampf((gap - floor_gap) / 3.5, 0.0, 1.0)
	var base := 0.78 if rank == 5 else 1.0
	return base * lerpf(0.4, 1.0, fade)


func _hash_thickness(span: float, yard: float) -> float:
	if span <= YARD_NEAR_YARDS:
		return 0.08
	var ppy := maxf(_pixels_per_yard(span, yard), 0.05)
	return clampf(1.7 / ppy, 0.06, 0.22)


func _center_tick(span: float, yard: float, spacing: int) -> bool:
	if spacing != 1 or int(round(yard)) % 5 == 0:
		return false
	if span <= YARD_NEAR_YARDS:
		return true
	return _pixels_per_yard(span, yard) >= 4.0


func _pixels_per_yard(span: float, z: float) -> float:
	var a := _screen_y(span, Vector3(0.0, 0.05, z))
	var b := _screen_y(span, Vector3(0.0, 0.05, z + 1.0))
	if a < 0.0 or b < 0.0:
		return 0.0
	return absf(a - b)


func _number_px(span: float, z: float) -> float:
	var a := _screen_y(span, Vector3(YARD_MEASURE_X, 1.1, z))
	var b := _screen_y(span, Vector3(YARD_MEASURE_X, 1.1 + YARD_WORLD_H, z))
	if a < 0.0 or b < 0.0:
		return 0.0
	return absf(a - b)


func _screen_y(span: float, point: Vector3) -> float:
	var rig := camera_rig(span, 0.0)
	var cam: Vector3 = rig["position"]
	var look: Vector3 = rig["look"]
	var back := cam - look
	if back.length_squared() < 0.001:
		return -1.0
	back = back.normalized()
	var right := Vector3.UP.cross(back)
	if right.length_squared() < 0.0001:
		right = Vector3(1.0, 0.0, 0.0)
	right = right.normalized()
	var up := back.cross(right).normalized()
	var rel := point - cam
	var depth := rel.dot(-back)
	if depth <= 0.2:
		return -1.0
	var ndc := (rel.dot(up) / depth) / tan(deg_to_rad(float(rig["fov"]) * 0.5))
	return (0.5 - ndc * 0.5) * KickConstants.WINDOW_HEIGHT


func _yard_sign(x: float, z: float, label: String, scale: float = 1.0) -> void:
	var sign := Label3D.new()
	sign.text = label
	sign.font_size = 72
	sign.pixel_size = YARD_PIXEL_SIZE * scale
	sign.modulate = Color(0.95, 0.96, 0.92)
	sign.outline_size = 8
	sign.outline_modulate = Color(0.05, 0.12, 0.05)
	var world_h := YARD_WORLD_H * maxf(scale, 0.05)
	var center_y := 1.1
	var bottom := center_y - world_h * 0.5
	if bottom < 0.2:
		center_y += 0.2 - bottom
	sign.position = Vector3(x, center_y, z)
	# Face the kicker so the number is not backwards.
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var parent: Node3D = _marks if _marks != null else _world
	parent.add_child(sign)


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
