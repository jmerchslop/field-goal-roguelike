extends Node

# Saves pictures of this same game. main.gd only adds this node when FG_SHOTS=1.

var board
var shot_dir := "/opt/cursor/artifacts"


func _ready() -> void:
	var made := DirAccess.make_dir_recursive_absolute(shot_dir)
	if made != OK and made != ERR_ALREADY_EXISTS:
		print("Could not create ", shot_dir)
		get_tree().quit(1)
		return
	board.highlight = 0
	if not await _capture("kicker_select.png"):
		get_tree().quit(1)
		return
	board.highlight = 1
	board.confirm_kicker()
	if not await _capture("view_rest.png"):
		get_tree().quit(1)
		return
	board.logic.press_space()
	board.logic.advance(0.42)
	board._approach_time = 0.42
	if not await _capture("view_runup.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(0.8)
	board.logic.press_space()
	board.logic.advance(0.8 / KickConstants.ACCURACY_FALL_PER_SEC * KickConstants.POWER_RISE_PER_SEC)
	board.logic.press_space()
	board.logic.advance(board.logic.flight_duration * 0.58)
	board._approach_time = 0.8
	if not await _capture("view_flight.png"):
		get_tree().quit(1)
		return
	board.logic.advance(board.logic.flight_duration)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("view_result.png"):
		get_tree().quit(1)
		return
	while board.run.kick_number < 10:
		board.advance_run()
		board.script_good_kick()
	board.force_spot_side(1)
	board.advance_run()
	if not await _capture("view_wide.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	board.run.resolve_kick("GOOD", 0.0, true)
	board.run.force_offer(["deep_bench", "big_leg", "steady_plant"])
	board.run.roll_offer()
	if not await _capture("walk_on_reroll.png"):
		get_tree().quit(1)
		return
	if not await _capture("offer_cards.png"):
		get_tree().quit(1)
		return
	board.run.pick_card(0)
	board.advance_run()
	if not await _capture("hud_upgrades.png"):
		get_tree().quit(1)
		return
	board.run.give(Loadout.PINPOINT, 1)
	if not await _capture("sweet_spot_meter.png"):
		get_tree().quit(1)
		return
	board.highlight = 0
	board.confirm_kicker()
	if not await _capture("big_bruce_play.png"):
		get_tree().quit(1)
		return
	board.run.attempts = 2
	_finish_centered_power(4.0)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("short_result.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	board.logic.aim_degrees = rad_to_deg(atan(3.08 / 35.0))
	_finish_centered_power(80.0)
	board._bank_time = 0.15
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("bank_shot.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	board.run.attempts = 2
	board.script_good_kick()
	board.advance_run()
	board.run.resolve_kick("SHORT", 0.0, false)
	if not await _capture("miss_same_kick.png"):
		get_tree().quit(1)
		return
	board.highlight = 1
	board.confirm_kicker()
	board.run.attempts = 2
	_finish_centered_power(20.0)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("power_20_short.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	_finish_centered_power(50.0)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("power_50_good.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	_lock_full_power_straight()
	# In the air, past the posts and past where a P=50 kick lands.
	var flight: float = board.logic.flight_duration
	board.logic.advance(flight * (58.0 / board.logic.travel_yards))
	if not await _capture("power_100_long.png"):
		get_tree().quit(1)
		return
	board.highlight = 1
	board.confirm_kicker()
	board.run.resolve_kick("GOOD", 0.0, false)
	board.run.roll_offer()
	if not await _capture("upgrade_after_make.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	board.run.attempts = 2
	var same_spot: float = board.run.spot_yards
	var same_wind: int = board.run.wind_speed
	board.run.resolve_kick("SHORT", 0.0, false)
	board.run.begin_retry()
	board.load_current_kick()
	if not await _capture("miss_no_upgrade.png"):
		get_tree().quit(1)
		return
	if board.run.kick_number != 1 or board.run.awaiting_offer or absf(board.run.spot_yards - same_spot) > 0.01 or board.run.wind_speed != same_wind:
		print("miss retry drifted")
		get_tree().quit(1)
		return
	board.run.give(Loadout.CANNON, 3)
	if not await _capture("big_leg_stacks.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	if not await _capture("calm_kick.png"):
		get_tree().quit(1)
		return
	board.set_wind(10.0, 90.0)
	var stats: KickerStats = board.logic.stats
	board.logic.press_space()
	board.logic.advance(55.0 / stats.power_speed)
	board.logic.press_space()
	board.logic.advance(board.logic.power / stats.accuracy_speed)
	board.logic.press_space()
	var to_posts: float = board.logic.flight_duration * (34.0 / board.logic.travel_yards)
	board.logic.advance(to_posts)
	if not await _capture("wind_curve.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	board.set_wind(10.0, 90.0)
	board.run.give(Loadout.WIND_VISOR, 2)
	board.logic.aim_degrees = 4.0
	if not await _capture("flag_laser.png"):
		get_tree().quit(1)
		return
	board.run.give(Loadout.STORM_CHASER, 1)
	board.load_current_kick()
	board.set_wind(10.0, 90.0)
	_finish_centered_power(50.0)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("storm_score.png"):
		get_tree().quit(1)
		return
	board.open_select()
	board.highlight = 0
	if not await _capture("select_headshots.png"):
		get_tree().quit(1)
		return
	board.highlight = 1
	board.confirm_kicker()
	_log_posts("center")
	if not await _capture("stadium_center.png"):
		get_tree().quit(1)
		return
	board.cycle_spot()
	_log_posts("right_hash")
	if not await _capture("spot_right_hash.png"):
		get_tree().quit(1)
		return
	board.cycle_spot()
	_log_posts("right_wide")
	if not await _capture("spot_right_wide.png"):
		get_tree().quit(1)
		return
	board.cycle_spot()
	_log_posts("left_wide")
	if not await _capture("spot_left_wide.png"):
		get_tree().quit(1)
		return
	board.cycle_spot()
	_log_posts("left_hash")
	if not await _capture("spot_left_hash.png"):
		get_tree().quit(1)
		return
	board.cycle_spot()
	board.run.attempts = 2
	_finish_centered_power(20.0)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("kick_short.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	_finish_centered_power(55.0)
	print("GOOD? ", board.logic.result_text, " range ", board.logic.max_range)
	if not await _capture("kick_good.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	board.set_wind(12.0, 90.0)
	var curve_stats: KickerStats = board.logic.stats
	board.logic.press_space()
	board.logic.advance(60.0 / curve_stats.power_speed)
	board.logic.press_space()
	board.logic.advance(board.logic.power / curve_stats.accuracy_speed)
	board.logic.press_space()
	board.logic.advance(board.logic.flight_duration * (32.0 / board.logic.travel_yards))
	if not await _capture("windy_curve.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	board.run.spot_yards = 6.0
	board.logic.kick_distance = 72.0
	board.logic.start_lateral_yards = 6.0
	board.refresh_view()
	_log_posts("long_right")
	if not await _capture("long_kick.png"):
		get_tree().quit(1)
		return
	board.run.spot_yards = 0.0
	board.load_current_kick()
	board.force_weather(RunLogic.RAIN)
	if not await _capture("weather_rain.png"):
		get_tree().quit(1)
		return
	board.force_weather(RunLogic.SNOW)
	if not await _capture("weather_snow.png"):
		get_tree().quit(1)
		return
	board.force_weather(RunLogic.MUD)
	if not await _capture("weather_mud.png"):
		get_tree().quit(1)
		return
	board.force_weather(RunLogic.THIN_AIR)
	if not await _capture("weather_thin_air.png"):
		get_tree().quit(1)
		return
	board.force_weather(RunLogic.ICED)
	_set_accuracy_needle(70.0, 0.12)
	if not await _capture("iced_needle_fade.png"):
		get_tree().quit(1)
		return
	_set_accuracy_needle(70.0, 0.55)
	if not await _capture("iced_needle_back.png"):
		get_tree().quit(1)
		return
	board.force_weather(RunLogic.CLEAR)
	_set_accuracy_needle(70.0, 0.35)
	if not await _capture("needle_always_visible.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	board.pose_for_shot("idle")
	if not await _capture("anim_walk_idle.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("power")
	if not await _capture("anim_walk_power.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("high")
	if not await _capture("anim_walk_high.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("run")
	if not await _capture("anim_walk_run.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("plant")
	if not await _capture("anim_walk_plant.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("follow")
	if not await _capture("anim_walk_follow.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	board.pose_for_shot("idle")
	if not await _capture("anim_walk_next.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("early")
	if not await _capture("anim_walk_early.png"):
		get_tree().quit(1)
		return
	board.highlight = 0
	board.confirm_kicker()
	board.pose_for_shot("idle")
	if not await _capture("anim_bruce_idle.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("run")
	if not await _capture("anim_bruce_run.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("plant")
	if not await _capture("anim_bruce_plant.png"):
		get_tree().quit(1)
		return
	board.pose_for_shot("follow")
	if not await _capture("anim_bruce_follow.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	board.pose_for_shot("idle")
	if not await _capture("anim_bruce_next.png"):
		get_tree().quit(1)
		return
	board.logic.phase = KickLogic.Phase.AIMING
	board.meter_time = 0.0
	board.force_weather(RunLogic.SQUEEZE)
	_log_posts("squeeze")
	if not await _capture("weather_squeeze.png"):
		get_tree().quit(1)
		return
	board.force_weather(RunLogic.MONSOON)
	if not await _capture("weather_monsoon.png"):
		get_tree().quit(1)
		return
	board.run.give(Loadout.CANNON, 1)
	board.force_weather(RunLogic.BIG_GAME)
	if not await _capture("weather_big_game.png"):
		get_tree().quit(1)
		return
	if not await _capture_records_story():
		get_tree().quit(1)
		return
	get_tree().quit()


func _capture_records_story() -> bool:
	SaveData.reset_save()
	board.open_select()
	board.showing_records = true
	board.save_note = ""
	if not await _capture("records_empty.png"):
		return false
	board.showing_records = false
	board.highlight = 1
	board.confirm_kicker()
	_finish_centered_power(50.0)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("trophy_extra_point.png"):
		return false
	board.run.roll_offer()
	if not await _capture("loadout_offer.png"):
		return false
	board.run.force_offer([
		{"id": Loadout.CANNON, "slot": Loadout.CLEATS, "kind": Loadout.EQUIPMENT, "rank": 1},
		{"id": Loadout.DEEP_BENCH, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 1},
		{"id": Loadout.ICED, "slot": Loadout.CURSE, "kind": Loadout.CURSE, "rank": 1},
	])
	board.run.roll_offer()
	board.run.pick_card(0)
	board.load_current_kick()
	if not await _capture("cannon_cleats_hud.png"):
		return false
	board.run.force_offer([
		{"id": Loadout.CANNON, "slot": Loadout.CLEATS, "kind": Loadout.EQUIPMENT, "rank": 2},
		{"id": Loadout.HOT_STREAK, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 1},
		{"id": Loadout.SHAKY, "slot": Loadout.CURSE, "kind": Loadout.CURSE, "rank": 1},
	])
	board.run.roll_offer()
	if not await _capture("cannon_rankup_offer.png"):
		return false
	board.run.skip_offer()
	board.advance_run()
	if not await _capture("skip_no_curse.png"):
		return false
	board.run.give(Loadout.ICED)
	board.load_current_kick()
	board.logic.press_space()
	board.meter_time = 0.5
	if not await _capture("iced_hidden_meter.png"):
		return false
	board.run.resolve_kick("GOOD", 2.0, false)
	board.logic.result_text = "GOOD"
	board.logic.power = 50.0
	board.logic.max_range = 49.5
	board.logic.kick_distance = board.run.distance_yards()
	board.logic.phase = KickLogic.Phase.RESULT
	if not await _capture("iced_mult.png"):
		return false
	board.run.give(Loadout.DEEP_BENCH, 1)
	board.run.give(Loadout.HOT_STREAK, 1)
	board.run.force_offer([
		{"id": Loadout.CANNON, "slot": Loadout.CLEATS, "kind": Loadout.EQUIPMENT, "rank": 2},
		{"id": Loadout.DEEP_BENCH, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 2},
		{"id": Loadout.NARROW, "slot": Loadout.CURSE, "kind": Loadout.CURSE, "rank": 1},
	])
	board.run.roll_offer()
	if not await _capture("two_perk_lock.png"):
		return false
	board.run.skip_offer()
	board.load_current_kick()
	if not await _capture("loadout_hud_slots.png"):
		return false
	board.run.attempts = 1
	board.run.kick_resolved = false
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.resolve_kick("SHORT", 0.0, false)
	board.open_select()
	board.showing_records = true
	if not await _capture("records_after_run.png"):
		return false
	SaveData.load_file()
	if not await _capture("persist_reload.png"):
		return false
	board.showing_records = false
	board.highlight = 1
	board.confirm_kicker()
	board.run.resolve_kick("GOOD", 0.0, true)
	board.advance_run()
	board.run.resolve_kick("GOOD", 0.0, true)
	board.run.attempts = 1
	board.run.kick_resolved = false
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.resolve_kick("SHORT", 0.0, false)
	if not await _capture("new_record.png"):
		return false
	board.open_select()
	board.showing_records = true
	board.tap_f9()
	if not await _capture("f9_warning.png"):
		return false
	board.tap_f9()
	if not await _capture("f9_reset.png"):
		return false
	return true


func _set_accuracy_needle(power_value: float, along: float) -> void:
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = power_value
	var span := power_value - KickConstants.METER_MIN
	board.logic.needle = power_value - along * span


func _log_posts(tag: String) -> void:
	var tee: Vector2 = board.world_to_screen(board._tee_position())
	var left: Vector2 = board.world_to_screen(Vector3(-board.run.post_half_gap(), 5.0, 0.0))
	var right: Vector2 = board.world_to_screen(Vector3(board.run.post_half_gap(), 5.0, 0.0))
	print(tag, " spot ", board.logic.start_lateral_yards, " tee_x ", tee.x, " post_x ", left.x, " ", right.x, " label ", RunLogic.spot_label(board.run.spot_yards))


func _lock_full_power_straight() -> void:
	var stats: KickerStats = board.logic.stats
	for seed_value in 40:
		board.load_current_kick()
		board.logic.set_seed(seed_value)
		board.logic.press_space()
		# Stay under 100 so the rise does not lock itself before the accuracy press.
		board.logic.advance(99.0 / stats.power_speed)
		board.logic.press_space()
		if board.logic.phase == KickLogic.Phase.ACCURACY:
			board.logic.advance(board.logic.power / stats.accuracy_speed)
			board.logic.press_space()
		if board.logic.result_text == "GOOD" and absf(board.logic.offset_yards) < 1.5:
			return


func _finish_centered_power(power_value: float) -> void:
	var stats: KickerStats = board.logic.stats
	board.logic.press_space()
	board.logic.advance(power_value / stats.power_speed)
	board.logic.press_space()
	board.logic.advance(board.logic.power / stats.accuracy_speed)
	board.logic.press_space()
	board.logic.advance(board.logic.flight_duration)


func _capture(file_name: String) -> bool:
	var phase = board.logic.phase
	if phase == KickLogic.Phase.ACCURACY:
		board._step_kick_pose(0.0)
	elif (phase == KickLogic.Phase.FLIGHT or phase == KickLogic.Phase.RESULT) and not board._swinging:
		board._step_kick_pose(0.3)
	board.refresh_view()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = board.get_viewport().get_texture().get_image()
	var path := shot_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		print("FAILED to save ", path, " error ", err)
		return false
	print("Saved ", path, " ", image.get_width(), "x", image.get_height())
	return true
