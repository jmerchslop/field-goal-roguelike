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
var pause_index := 0
var _checkpoint: Dictionary = {}
var save_note := ""
var _note_time := 0.0
var _trophy_time := 0.0
var _cash_time := 0.0
var _vitamin_time := 0.0
var highlight := -1
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
var _kicker_sprite: Sprite3D
var _post_l: MeshInstance3D
var _post_r: MeshInstance3D
var _crossbar: MeshInstance3D
var _mud: MeshInstance3D
var _marks: Node3D
var _stands: Node3D
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
var result_age := 0.0
const _PREVIEW_DISTANCES: Array[float] = [75.0, 200.0, 500.0, 1000.0]
var _ribbon_l: MeshInstance3D
var _ribbon_r: MeshInstance3D
var _ribbon_time := 0.0
const _POST_TOP_Y := 13.33
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
	logic.reset_kick()
	_copy_run_onto_kick()
	if _preview_step > 0:
		logic.kick_distance = shown_distance()
	logic.sync_tee()
	_approach_time = 0.0
	_bank_time = 0.0
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
	logic.heavy_ball = run.has_curse(Loadout.HEAVY)
	logic.howling_wind = run.has_curse(Loadout.HOWLING)
	logic.shaky = run.has_curse(Loadout.SHAKY)
	logic.angle_scale = run.stats.angle_scale
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
	selecting = false
	front.came_from_gate = false
	var mode := front.run_mode
	_cue("select")
	run.start_with_kicker(id)
	run.run_mode = mode
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
	front.screen = FrontEnd.Screen.SELECT
	highlight = -1
	_show_fresh_unlocks()
	refresh_view()


func _show_fresh_unlocks() -> void:
	if SaveData.fresh_unlocks.is_empty():
		return
	save_note = ", ".join(SaveData.fresh_unlocks)
	_note_time = 0.0


func _select_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var slot: int = _hud.kicker_slot_at(mouse.position)
			var step: Dictionary = Kickers.click_slot(highlight, slot)
			highlight = int(step["highlight"])
			if bool(step["confirm"]):
				confirm_kicker()
			else:
				refresh_view()
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
		_leave_character_select()
		return
	if showing_records:
		return
	if Settings.pressed_event(event, "choose_1"):
		highlight = 0
		refresh_view()
	elif Settings.pressed_event(event, "choose_2"):
		highlight = 1
		refresh_view()
	elif Settings.pressed_event(event, "choose_3"):
		highlight = 2
		refresh_view()
	elif key.keycode == KEY_4 or key.keycode == KEY_KP_4:
		highlight = 3
		refresh_view()
	elif key.keycode == KEY_5 or key.keycode == KEY_KP_5:
		highlight = 4
		refresh_view()
	elif key.keycode == KEY_6 or key.keycode == KEY_KP_6:
		highlight = 5
		refresh_view()
	elif key.keycode == KEY_7 or key.keycode == KEY_KP_7:
		highlight = 6
		refresh_view()
	elif key.keycode == KEY_8 or key.keycode == KEY_KP_8:
		highlight = 7
		refresh_view()
	elif Settings.pressed_event(event, "confirm"):
		confirm_kicker()


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
	logic.aim_degrees = aim
	logic.phase = phase
	_copy_weather_onto_kick()
	logic.post_half_gap = run.post_half_gap()
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
	logic.heavy_ball = run.has_curse(Loadout.HEAVY)
	logic.howling_wind = run.has_curse(Loadout.HOWLING)
	logic.shaky = run.has_curse(Loadout.SHAKY)
	logic.angle_scale = run.stats.angle_scale


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
	if logic.phase != KickLogic.Phase.AIMING:
		meter_time += delta
	_sway_time += delta
	_ribbon_time += delta
	logic.sway(_sway_time)
	_place_ribbons()
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
		if _power_press_queued and logic.phase == KickLogic.Phase.POWER and logic.windup_left <= 0.0000001:
			_power_press_queued = false
			logic.take_power_press(delta)
		else:
			_power_press_queued = false
			logic.advance(delta)
		_sync_kick_audio(phase_before, forward_before)
		if logic.insured:
			run.consume_insurance()
		settle_kick()
		if logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY:
			_approach_time += delta
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
	if _front_input(event):
		return
	if selecting:
		_select_input(event)
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and run.awaiting_offer:
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
		refresh_view()
		return
	if Settings.pressed_event(event, "practice") and logic.phase == KickLogic.Phase.AIMING and not run.awaiting_offer and not run.awaiting_mulligan:
		if run.start_practice():
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
			refresh_view()
			return
	if not Settings.pressed_event(event, "confirm"):
		return
	if run.awaiting_mulligan:
		run.accept_pending_miss()
		_cue("mulligan")
		if run.phase == RunLogic.Phase.PLAYING:
			run.begin_retry()
			load_current_kick()
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
	logic.press_space()
	_sync_kick_audio(phase_before, forward_before)
	if logic.insured:
		run.consume_insurance()
	refresh_view()


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
	highlight = -1
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
		highlight = -1
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
	elif key.keycode == KEY_C:
		run.add_debug_cash()
		_cash_time = 0.0
	elif Settings.pressed_event(event, "confirm") or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
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
	var rig := camera_rig(span, 0.0)
	var back := float(rig["position"].z) - span
	var far_z := span + back + 8.0
	var near_z := -8.0
	var length := far_z - near_z
	var mid_z := (far_z + near_z) * 0.5
	_paint_box(_marks, Vector3(54, 0.4, length), Vector3(0, -0.2, mid_z), Color(0.18, 0.32, 0.16))
	_paint_grass(27.0, near_z, far_z)
	var paint := SurfaceTool.new()
	paint.begin(Mesh.PRIMITIVE_TRIANGLES)
	var white := Color(0.93, 0.95, 0.92)
	var yard := 0.0
	while yard <= span + 0.01:
		_add_flat(paint, 25.0, yard - 0.07, 0.14, 0.05, white)
		yard += 5.0
	_add_flat_at(paint, -25.0, near_z, 0.16, far_z - near_z, 0.05, white)
	_add_flat_at(paint, 25.0, near_z, 0.16, far_z - near_z, 0.05, white)
	var half := hash_row_half()
	var tick := 0.0
	while tick <= span + 0.01:
		_add_dash(paint, -half, tick, 0.9, white)
		_add_dash(paint, half, tick, 0.9, white)
		if int(round(tick)) % 5 != 0:
			_add_dash(paint, 0.0, tick, 0.42, white)
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
	var number := 10
	while number <= int(floor(span + 0.01)):
		if number <= 200 or number % 50 == 0:
			_yard_sign(-20.0, float(number), str(number))
			_yard_sign(20.0, float(number), str(number))
		number += 10


func _mesh_node(parent: Node3D, node_name: String, mesh: Mesh, material: Material) -> void:
	var body := MeshInstance3D.new()
	body.name = node_name
	body.mesh = mesh
	body.material_override = material
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(body)


func _vertex_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	return mat


func _add_flat(tool: SurfaceTool, half_width: float, z: float, depth: float, y: float, color: Color) -> void:
	_add_quad(tool, Vector3(0.0, y, z + depth * 0.5), half_width, depth * 0.5, color)


func _add_flat_at(tool: SurfaceTool, x: float, z0: float, width: float, depth: float, y: float, color: Color) -> void:
	_add_quad(tool, Vector3(x, y, z0 + depth * 0.5), width * 0.5, depth * 0.5, color)


func _add_dash(tool: SurfaceTool, x: float, z: float, length: float, color: Color) -> void:
	_add_quad(tool, Vector3(x, 0.07, z), length * 0.5, 0.04, color)


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
	grass_bounds = {"min_z": z0, "max_z": z1, "tile": GRASS_TILE_YARDS}


func _grass_material() -> StandardMaterial3D:
	var paint := _mat(Color.WHITE, 1.0)
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	paint.texture_repeat = true
	var texture := load(GRASS_PATH) as Texture2D
	if texture != null:
		paint.albedo_texture = texture
	return paint


func sky_path_for(weather: String) -> String:
	if weather == RunLogic.RAIN or weather == RunLogic.SNOW or weather == RunLogic.MONSOON or weather == RunLogic.ICED:
		return SKY_OVERCAST_PATH
	return SKY_CLEAR_PATH


func _build_sky() -> void:
	# The paintings wrap the horizon. A sky shader samples them by direction,
	# so the view stays inside the painting at 35 yards and at 1000.
	var shader := Shader.new()
	shader.code = "shader_type sky;\nuniform sampler2D sky_tex : source_color, filter_nearest, repeat_enable;\nuniform float horizon_elev = 0.05;\nuniform float zenith_elev = 0.45;\nvoid sky() {\n\tvec3 dir = EYEDIR;\n\tfloat u = atan(dir.x, dir.z) / 6.28318530718 + 0.5;\n\tfloat elev = asin(clamp(dir.y, -1.0, 1.0));\n\tfloat t = clamp((elev - horizon_elev) / max(zenith_elev - horizon_elev, 0.001), 0.0, 1.0);\n\tCOLOR = texture(sky_tex, vec2(u, 1.0 - t)).rgb;\n}\n"
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
	_rain = _make_precip("Rain", _streak_texture(), Vector2(0.1, 0.86), true)
	_snow = _make_precip("Snow", _flake_texture(), Vector2(0.32, 0.32), false)
	_weather_anchor.add_child(_rain)
	_weather_anchor.add_child(_snow)
	_apply_weather("")


func _make_precip(node_name: String, texture: Texture2D, size: Vector2, align_fall: bool) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = node_name
	particles.emitting = false
	particles.visible = false
	particles.amount = 1
	particles.lifetime = 1.2
	particles.preprocess = 4.0
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
	_tune_precip(_rain, kind == "rain", amount, fall, 0.55 if weather == RunLogic.MONSOON else 0.85)
	_tune_precip(_snow, kind == "snow", amount, fall, 3.6)
	var env := $WorldEnvironment.environment as Environment
	if env != null:
		env.ambient_light_energy = AMBIENT_ENERGY * dim
	var sun := $Sun as DirectionalLight3D
	if sun != null:
		sun.light_energy = SUN_ENERGY * dim


func _tune_precip(particles: GPUParticles3D, active: bool, amount: int, fall: float, life: float) -> void:
	if particles == null:
		return
	particles.visible = active
	particles.emitting = active
	if not active:
		return
	particles.amount = amount
	particles.lifetime = life
	var process := particles.process_material as ParticleProcessMaterial
	if process == null:
		return
	process.initial_velocity_min = fall * 0.85
	process.initial_velocity_max = fall * 1.15
	process.gravity = Vector3(0, -fall, 0)
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
		process.gravity = local_grav
		process.direction = local_grav.normalized()


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
	return paint


func _build_uprights() -> void:
	var yellow := Color(0.95, 0.82, 0.16)
	var crossbar_y := 3.33
	var upright_h := 10.0
	_post_l = _pole(Vector3(0.16, upright_h, 0.16), Vector3(0, crossbar_y + upright_h * 0.5, 0), yellow)
	_post_r = _pole(Vector3(0.16, upright_h, 0.16), Vector3(0, crossbar_y + upright_h * 0.5, 0), yellow)
	_crossbar = _pole(Vector3(1.0, 0.16, 0.16), Vector3(0, crossbar_y, 0), yellow)
	_pole(Vector3(0.2, crossbar_y, 0.2), Vector3(0, crossbar_y * 0.5, 0), yellow)
	_fit_posts(KickConstants.POST_SEPARATION_YARDS)
	_build_ribbons()


func _build_ribbons() -> void:
	_ribbon_l = _make_ribbon("RibbonLeft")
	_ribbon_r = _make_ribbon("RibbonRight")


func _make_ribbon(node_name: String) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.11, 1.17, 0.02)
	body.mesh = mesh
	var paint := _mat(Color(1.0, 0.42, 0.05), 0.55)
	paint.emission_enabled = true
	paint.emission = Color(0.85, 0.28, 0.02)
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
	_ball = Sprite3D.new()
	_style_sprite(_ball, 0.55)
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
	_place_ribbons()
	_place_kicker(tee)
	_place_arrow(tee)
	_place_camera()


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
	if str(_kicker_sprite.get_meta("art", "")) != path:
		_fit_sprite(_kicker_sprite, path)
		_kicker_sprite.set_meta("art", path)
	var height := _kicker_sprite.pixel_size * _kicker_sprite.region_rect.size.y
	var bob := 0.0
	if _pose == "run":
		bob = sin((_run_time + _swing_time) * 16.0) * 0.05
	_kicker_sprite.position = tee + Vector3(-1.45, height * 0.5 + bob, _kicker_behind())


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
	var reach := tee.z / maxf(cos(aim), 0.25)
	var width := run.post_width()
	var origin := Vector3(tee.x, 0.09, tee.z)
	var far := origin + dir * reach
	far.y = 0.09
	far.z = 0.0
	var half := width * 0.5
	var goal := Vector3(1.0, 0.0, 0.0)
	aim_corridor = {
		"visible": true,
		"origin": origin,
		"far": far,
		"width": width,
		"left": far - goal * half,
		"right": far + goal * half,
	}
	var boost := 1.0
	if logic.kick_distance >= 500.0:
		boost = 1.28
	elif logic.kick_distance >= 200.0:
		boost = 1.12
	_arrow.position = Vector3.ZERO
	_arrow.rotation = Vector3.ZERO
	_arrow.mesh = _aim_cone_mesh(origin, dir, side, reach, 0.16, half, boost)


func _aim_cone_mesh(origin: Vector3, dir: Vector3, side: Vector3, reach: float, near_half: float, far_half: float, boost: float) -> ArrayMesh:
	var near_c := origin + dir * 0.12
	var far_c := origin + dir * reach
	near_c.y = 0.09
	far_c.y = 0.09
	far_c.z = 0.0
	var goal := Vector3(1.0, 0.0, 0.0)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gel_near := Color(1.0, 0.07, 0.05, minf(0.72, 0.58 * boost))
	var gel_far := Color(1.0, 0.08, 0.04, minf(0.55, 0.36 * boost))
	_cone_layer(tool, near_c, far_c, side, goal, near_half, far_half, 0.09, gel_near, gel_far)
	var rim_near := Color(0.95, 0.1, 0.03, minf(0.95, 0.88 * boost))
	var rim_far := Color(0.86, 0.07, 0.03, minf(0.78, 0.55 * boost))
	_cone_edges(tool, near_c, far_c, side, goal, near_half, far_half, near_half + 0.045, far_half + 0.045, 0.094, rim_near, rim_far)
	var line_near := Color(0.22, 0.02, 0.02, 0.9)
	var line_far := Color(0.16, 0.02, 0.02, 0.55)
	_cone_edges(tool, near_c, far_c, side, goal, near_half + 0.045, far_half + 0.045, near_half + 0.08, far_half + 0.08, 0.086, line_near, line_far)
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
	c.z = 0.0
	d.z = 0.0
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
		c.z = 0.0
		d.z = 0.0
		var corners := [a, b, c, d]
		var colors := [near_color, near_color, far_color, far_color]
		for index in [0, 1, 2, 0, 2, 3]:
			tool.set_color(colors[index])
			tool.add_vertex(corners[index])


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
