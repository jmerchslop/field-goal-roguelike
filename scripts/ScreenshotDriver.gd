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
	board.run.grant("sweet_spot")
	if not await _capture("sweet_spot_meter.png"):
		get_tree().quit(1)
		return
	board.run.grant("mulligan")
	board.run.begin_mulligan("WIDE LEFT", -4.0, false)
	if not await _capture("mulligan_prompt.png"):
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
	board.run.grant(Upgrades.BIG_LEG)
	board.run.grant(Upgrades.BIG_LEG)
	board.run.grant(Upgrades.BIG_LEG)
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
	board.run.grant(Upgrades.FLAG_READER)
	board.run.grant(Upgrades.LASER_LINE)
	board.logic.aim_degrees = 4.0
	if not await _capture("flag_laser.png"):
		get_tree().quit(1)
		return
	board.run.grant(Upgrades.STORM_CHASER)
	board.load_current_kick()
	board.set_wind(10.0, 90.0)
	_finish_centered_power(50.0)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("storm_score.png"):
		get_tree().quit(1)
		return
	get_tree().quit()


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
