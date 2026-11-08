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

var _world: Node3D
var _camera: Camera3D
var _ball: Sprite3D
var _tee: MeshInstance3D
var _arrow: MeshInstance3D
var _shadow: MeshInstance3D
var _kicker_sprite: Sprite3D
var _post_l: MeshInstance3D
var _post_r: MeshInstance3D
var _crossbar: MeshInstance3D
var _mud: MeshInstance3D
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


func settle_kick() -> void:
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
	elif run.phase == RunLogic.Phase.PLAYING:
		run.begin_retry()
		load_current_kick()


func retake_with_mulligan() -> void:
	if not run.use_mulligan():
		return
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


func _choose_card(index: int) -> void:
	if not run.pick_card(index):
		return
	_after_cards()


func _after_cards() -> void:
	if run.last_result_made:
		if run.follow_offer() == "shop":
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
	var id := Kickers.id_for_slot(highlight)
	if id == "":
		return
	selecting = false
	var mode := front.run_mode
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
	refresh_view()


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
		refresh_view()
		return
	if Settings.pressed_event(event, "back") and showing_records:
		showing_records = false
		refresh_view()
		return
	if Settings.pressed_event(event, "back") and not showing_records:
		selecting = false
		front.back_select()
		refresh_view()
		return
	if showing_records:
		return
	if Settings.pressed_event(event, "choose_1"):
		highlight = 0
		refresh_view()
	elif Settings.pressed_event(event, "choose_2"):
		highlight = 1
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


func advance_run() -> bool:
	if not run.go_to_next_kick():
		return false
	load_current_kick()
	return true


func restart_run() -> void:
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
	logic.advance(power_value / logic.stats.power_speed)
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
	if logic.phase != KickLogic.Phase.AIMING:
		meter_time += delta
	_sway_time += delta
	logic.sway(_sway_time)
	_step_kick_pose(delta)
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
		logic.advance(delta)
		if logic.insured:
			run.consume_insurance()
		settle_kick()
		if logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY:
			_approach_time += delta
	refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if _taking_pictures:
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
		refresh_view()
		return
	if Settings.pressed_event(event, "back") and (run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN) and not showing_records:
		_return_to_main_menu()
		return
	# R still returns to character select. It is not the offer-reroll action.
	if key.keycode == KEY_R and run.accepts_restart() and not run.awaiting_offer and not run.awaiting_mulligan and not showing_records:
		open_select()
		return
	if key.keycode == KEY_M and run.awaiting_mulligan:
		retake_with_mulligan()
		return
	if run.curse_prompt:
		if Settings.pressed_event(event, "back"):
			run.cancel_curse_prompt()
			refresh_view()
		elif Settings.pressed_event(event, "choose_1"):
			if run.pick_curse_removal(0):
				apply_live_vitamins()
		elif Settings.pressed_event(event, "choose_2"):
			if run.pick_curse_removal(1):
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
			_after_cards()
		return
	if run.awaiting_offer and Settings.pressed_event(event, "offer_reroll"):
		run.reroll_offer()
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
			apply_live_vitamins()
			return
		if Settings.pressed_event(event, "belt_x") and run.use_belt(1):
			_vitamin_time = 0.0
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
	logic.press_space()
	if logic.insured:
		run.consume_insurance()
	refresh_view()


func _return_to_main_menu() -> void:
	selecting = false
	showing_records = false
	front.screen = FrontEnd.Screen.MAIN
	front.menu_index = 0
	front.lock_message = ""
	refresh_view()


func _front_input(event: InputEvent) -> bool:
	var mode := front.screen
	if mode != FrontEnd.Screen.TITLE and mode != FrontEnd.Screen.MAIN and mode != FrontEnd.Screen.OPTIONS and mode != FrontEnd.Screen.RECORDS:
		return false
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
			refresh_view()
		elif mode == FrontEnd.Screen.MAIN and mouse.pressed:
			var tile := MenuLayout.tile_at(mouse.position, _hud._menu_window())
			if tile == front.menu_index and tile >= 0:
				_apply_menu_choice(front.confirm_menu())
			elif tile >= 0:
				front.hover_menu(tile)
			refresh_view()
		elif mode == FrontEnd.Screen.OPTIONS:
			if mouse.pressed:
				_options_click(mouse.position)
			elif front.dragging != "":
				Settings.play_preview(front.dragging)
				front.dragging = ""
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
			refresh_view()
		return true
	if mode == FrontEnd.Screen.MAIN:
		if Settings.pressed_event(event, "menu_left") or Settings.pressed_event(event, "menu_up"):
			front.move_menu(-1)
		elif Settings.pressed_event(event, "menu_right") or Settings.pressed_event(event, "menu_down"):
			front.move_menu(1)
		elif Settings.pressed_event(event, "back"):
			front.back_main()
		elif Settings.pressed_event(event, "confirm") or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
			_apply_menu_choice(front.confirm_menu())
		refresh_view()
		return true
	if mode == FrontEnd.Screen.RECORDS:
		if Settings.pressed_event(event, "back"):
			front.back_records()
			selecting = front.screen == FrontEnd.Screen.SELECT
			refresh_view()
		return true
	return _options_key(event, key)


func _apply_menu_choice(choice: String) -> void:
	if choice == "select":
		selecting = true
		highlight = -1
		showing_records = false


func _options_key(event: InputEvent, key: InputEventKey) -> bool:
	if front.rebinding != "":
		if key.keycode == KEY_ESCAPE:
			front.cancel_rebind()
		else:
			front.finish_rebind(int(key.keycode))
		refresh_view()
		return true
	if front.focus_kind(front.focus) == "slider" and (Settings.pressed_event(event, "menu_left") or Settings.pressed_event(event, "menu_right")):
		var step := -1 if Settings.pressed_event(event, "menu_left") else 1
		if front.nudge_slider(step):
			Settings.play_preview(front.slider_id(front.focus))
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
	elif Settings.pressed_event(event, "confirm") or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		var result := front.activate_focus()
		if result == "back":
			pass
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
	elif kind == "reset":
		Settings.reset_controls()
	elif kind == "back":
		front.back_options()


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
		run.buy_shelf(0)
	elif Settings.pressed_event(event, "choose_2"):
		run.buy_shelf(1)
	elif Settings.pressed_event(event, "choose_3"):
		run.buy_shelf(2)
	elif Settings.pressed_event(event, "buy_b12"):
		run.buy_b12()
	elif Settings.pressed_event(event, "belt_z"):
		run.sell_belt(0)
	elif Settings.pressed_event(event, "belt_x"):
		run.sell_belt(1)
	elif Settings.pressed_event(event, "shop_reroll"):
		run.reroll_shop()
	elif key.keycode == KEY_C:
		run.add_debug_cash()
		_cash_time = 0.0
	elif Settings.pressed_event(event, "confirm") or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
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
	env.ambient_light_energy = 0.7
	$WorldEnvironment.environment = env
	var sun := $Sun as DirectionalLight3D
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	_camera.fov = 58.0


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
		_yard_sign(-20.0, float(mark), str(mark))
		_yard_sign(20.0, float(mark), str(mark))
		mark += 10
	_box(Vector3(0.16, 0.04, 86.0), Vector3(-25.0, 0.05, 40.0), Color(0.93, 0.95, 0.92))
	_box(Vector3(0.16, 0.04, 86.0), Vector3(25.0, 0.05, 40.0), Color(0.93, 0.95, 0.92))
	var tick := 0.0
	while tick <= 78.0:
		_box(Vector3(0.9, 0.03, 0.08), Vector3(-10.2, 0.07, tick), Color(0.93, 0.95, 0.92))
		_box(Vector3(0.9, 0.03, 0.08), Vector3(10.2, 0.07, tick), Color(0.93, 0.95, 0.92))
		if int(tick) % 5 != 0:
			_box(Vector3(0.42, 0.03, 0.08), Vector3(0.0, 0.07, tick), Color(0.93, 0.95, 0.92))
		tick += 1.0
	_build_stadium()


func _build_stadium() -> void:
	# Flat walls of seats, not a cylinder. A cylinder's UVs turn the crowd into a smear.
	_stand(Vector3(96.0, 14.0, 1.2), Vector3(0.0, 8.0, -3.0), Vector3(8.0, 3.0, 1.0))
	_stand(Vector3(1.2, 12.0, 96.0), Vector3(-32.0, 7.0, 40.0), Vector3(8.0, 2.5, 1.0))
	_stand(Vector3(1.2, 12.0, 96.0), Vector3(32.0, 7.0, 40.0), Vector3(8.0, 2.5, 1.0))
	_box(Vector3(100.0, 2.2, 1.4), Vector3(0.0, 16.2, -3.2), Color(0.62, 0.78, 0.9))


func _stand(size: Vector3, pos: Vector3, tiles: Vector3) -> void:
	var wall := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	wall.mesh = mesh
	wall.position = pos
	var paint := _mat(Color.WHITE, 1.0)
	var crowd := load("res://art/field/crowd.png") as Texture2D
	if crowd != null:
		paint.albedo_texture = crowd
		paint.uv1_scale = tiles
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	wall.material_override = paint
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(wall)


func _build_uprights() -> void:
	var yellow := Color(0.95, 0.82, 0.16)
	var crossbar_y := 3.33
	var upright_h := 10.0
	_post_l = _pole(Vector3(0.16, upright_h, 0.16), Vector3(0, crossbar_y + upright_h * 0.5, 0), yellow)
	_post_r = _pole(Vector3(0.16, upright_h, 0.16), Vector3(0, crossbar_y + upright_h * 0.5, 0), yellow)
	_crossbar = _pole(Vector3(1.0, 0.16, 0.16), Vector3(0, crossbar_y, 0), yellow)
	_pole(Vector3(0.2, crossbar_y, 0.2), Vector3(0, crossbar_y * 0.5, 0), yellow)
	_fit_posts(KickConstants.POST_SEPARATION_YARDS)


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
	if _post_l != null:
		_post_l.position.x = -half
	if _post_r != null:
		_post_r.position.x = half
	if _crossbar != null:
		var mesh := _crossbar.mesh as BoxMesh
		if mesh != null:
			mesh.size.x = width


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
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.08, 0.025, 18.0)
	_arrow = MeshInstance3D.new()
	_arrow.mesh = shaft
	_arrow.material_override = _mat(Color(0.95, 0.86, 0.2), 0.45)
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
	var who := ""
	if run.kicker_id == Kickers.WALK_ON:
		who = "walk_on"
	elif run.kicker_id == Kickers.BIG_BRUCE:
		who = "big_bruce"
	if who == "":
		return ""
	if _pose == "run":
		return "res://art/kickers/%s_run.png" % who
	if _pose == "plant":
		return "res://art/kickers/%s_plant.png" % who
	if _pose == "follow":
		return "res://art/kickers/%s_follow_through.png" % who
	return "res://art/kickers/%s_back.png" % who


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
	return Vector3(logic.start_lateral_yards, 0.0, logic.kick_distance)


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
	return Vector3(lateral, y, logic.kick_distance - forward)


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


func _place_arrow(tee: Vector3) -> void:
	var show := logic.phase == KickLogic.Phase.AIMING or logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY
	_arrow.visible = show
	if not show:
		return
	var aim := deg_to_rad(logic.aim_degrees)
	var dir := Vector3(sin(aim), 0.0, -cos(aim))
	_arrow.position = tee + dir * 10.0 + Vector3(0, 0.06, 0)
	if dir.length_squared() > 0.001:
		_arrow.look_at(_arrow.position + dir, Vector3.UP)


func _place_camera() -> void:
	# The camera rides with the tee. It looks along the tee's line, not at the posts,
	# so a left spot leaves the posts on the right of the screen and a right spot does the opposite.
	var spot := logic.start_lateral_yards
	var dist := logic.kick_distance
	var extra := 0.0
	if dist > 48.0:
		extra = (dist - 48.0) * 0.11
	var back := 6.4 + extra
	var height := 3.05 + extra * 0.22
	_camera.position = Vector3(spot - 0.05, height, dist + back)
	var look := Vector3(spot, 1.05, maxf(dist - 14.0, 0.0))
	_camera.look_at(look, Vector3.UP)


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
