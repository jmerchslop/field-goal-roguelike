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
	if OS.get_environment("FG_SHOT_PART") == "drive":
		if not await _capture_drive_lid():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	if OS.get_environment("FG_SHOT_PART") == "visor":
		if not await _capture_wind_visor():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	if OS.get_environment("FG_SHOT_PART") == "precip":
		if not await _capture_precip():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	if OS.get_environment("FG_SHOT_PART") == "sky":
		if not await _capture_sky():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	if OS.get_environment("FG_SHOT_PART") == "stands":
		if not await _capture_stands():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	if OS.get_environment("FG_SHOT_PART") == "gear":
		if not await _capture_gear():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	if OS.get_environment("FG_SHOT_PART") == "broadcast":
		if not await _capture_broadcast():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	if OS.get_environment("FG_SHOT_PART") == "stamps":
		if not await _capture_stamps():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	if OS.get_environment("FG_SHOT_PART") == "menu":
		if not await _capture_menu_and_rerolls():
			get_tree().quit(1)
			return
		get_tree().quit(0)
		return
	board.front.screen = FrontEnd.Screen.SELECT
	board.selecting = true
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
	_swing_meter(70.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
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
	var guard := 0
	while board.run.kick_number < 10 and guard < 40:
		if not board.run.last_result_made:
			board.run.phase = RunLogic.Phase.PLAYING
			board.run.kick_resolved = false
			board.script_good_kick()
		if not board.advance_run():
			break
		board.script_good_kick()
		guard += 1
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
	if not await _capture_range_hotfix():
		get_tree().quit(1)
		return
	if not await _capture_vitamin_shop():
		get_tree().quit(1)
		return
	if not await _capture_meter_row():
		get_tree().quit(1)
		return
	if not await _capture_needle():
		get_tree().quit(1)
		return
	if not await _capture_menus():
		get_tree().quit(1)
		return
	if not await _capture_modes():
		get_tree().quit(1)
		return
	if not await _capture_imported_art():
		get_tree().quit(1)
		return
	if not await _capture_clean_meter():
		get_tree().quit(1)
		return
	if not await _capture_roster():
		get_tree().quit(1)
		return
	if not await _capture_shank_meter():
		get_tree().quit(1)
		return
	if not await _capture_m2_kickers():
		get_tree().quit(1)
		return
	if not await _capture_ball_sprites():
		get_tree().quit(1)
		return
	if not await _capture_menu_and_rerolls():
		get_tree().quit(1)
		return
	if not await _capture_wind_visor():
		get_tree().quit(1)
		return
	if not await _capture_drive_lid():
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
	if not await _capture("slots_empty.png"):
		return false
	_finish_centered_power(50.0)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("trophy_extra_point.png"):
		return false
	board.run.force_offer([
		{"id": Loadout.SCOUT_LID, "slot": Loadout.HELMET, "kind": Loadout.EQUIPMENT, "rank": 1},
		{"id": Loadout.HERO_BALL, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 1},
		{"id": Loadout.ICED, "slot": Loadout.CURSE, "kind": Loadout.CURSE, "rank": 1},
	])
	board.run.roll_offer()
	if not await _capture("loadout_offer.png"):
		return false
	if not await _capture("offer_sprite.png"):
		return false
	board.run.pick_card(0)
	if not await _capture("hud_scout.png"):
		return false
	board._hud.pinned_slot = 1
	board.refresh_view()
	if not await _capture("hud_tooltip.png"):
		return false
	board._hud.pinned_slot = -1
	board.run.force_offer([
		{"id": Loadout.SCOUT_LID, "slot": Loadout.HELMET, "kind": Loadout.EQUIPMENT, "rank": 2},
		{"id": Loadout.HERO_BALL, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 1},
		{"id": Loadout.HEAVY, "slot": Loadout.CURSE, "kind": Loadout.CURSE, "rank": 1},
	])
	board.run.roll_offer()
	board.run.pick_card(0)
	if not await _capture("hud_scout_ii.png"):
		return false
	board.run.force_offer([
		{"id": Loadout.DOINK_CAP, "slot": Loadout.HELMET, "kind": Loadout.EQUIPMENT, "rank": 1},
		{"id": Loadout.HERO_BALL, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 1},
		{"id": Loadout.ICED, "slot": Loadout.CURSE, "kind": Loadout.CURSE, "rank": 1},
	])
	board.run.roll_offer()
	var before_helmet: String = str(board.run.helmet_id)
	var before_rank: int = int(board.run.helmet_rank)
	board.run.skip_offer()
	if board.run.helmet_id != before_helmet or board.run.helmet_rank != before_rank or board.run.perks.size() != 0:
		print("skip changed a slot")
		return false
	if not await _capture("skip_slots.png"):
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
	if not await _capture("slots_empty_again.png"):
		return false
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


func _capture_range_hotfix() -> bool:
	board.showing_records = false
	board.save_note = ""
	board._note_time = 0.0
	board.highlight = 0
	board.confirm_kicker()
	if not await _shoot_power_result(18, "bruce_p100_kick18_short.png", "SHORT", 65.0):
		return false
	board.highlight = 1
	board.confirm_kicker()
	if not await _shoot_power_result(14, "walkon_p100_kick14_short.png", "SHORT", 60.0):
		return false
	board.highlight = 0
	board.confirm_kicker()
	board.run.give(Loadout.CANNON, 1)
	if not await _shoot_power_result(18, "bruce_cannon_kick18_good.png", "GOOD", 71.0):
		return false
	if not await _shoot_power_result(19, "bruce_cannon_kick19_short.png", "SHORT", 71.0):
		return false
	board.run.give(Loadout.CANNON, 5)
	board.load_current_kick()
	if not await _capture("cannon_rank_v.png"):
		return false
	board.run.give(Loadout.CANNON, 6)
	board.load_current_kick()
	if not await _capture("cannon_rank_vi.png"):
		return false
	board.run.give(Loadout.HOT_STREAK, 3)
	board.load_current_kick()
	if not await _capture("perk_rank_iii.png"):
		return false
	board.run.kick_number = 19
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.kick_resolved = true
	board.run.last_result_made = true
	board.run.force_offer([
		{"id": Loadout.TWO_MINUTE, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 1},
		{"id": Loadout.STORM_CHASER, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 1},
		{"id": Loadout.SHAKY, "slot": Loadout.CURSE, "kind": Loadout.CURSE, "rank": 1},
	])
	board.run.roll_offer()
	if board.run.offer.size() != 3:
		print("two minute offer missing")
		return false
	if not await _capture("two_minute_offer.png"):
		return false
	board.run.skip_offer()
	board.run.helmet_id = Loadout.WIND_VISOR
	board.run.helmet_rank = 6
	board.run.gloves_id = Loadout.IRON_GRIP
	board.run.gloves_rank = 6
	board.run.perks = [{"id": Loadout.HOT_STREAK, "rank": 3}, {"id": Loadout.TWO_MINUTE, "rank": 3}]
	board.run.curse_ids = [Loadout.HEAVY, Loadout.SHANKY]
	board.run.rebuild_stats()
	board.run.kick_number = 19
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.kick_resolved = true
	board.run.last_result_made = true
	board.run.roll_offer()
	if not board.run.awaiting_offer or board.run.offer.size() != 0:
		print("empty offer did not stay open, cards ", board.run.offer.size())
		return false
	if not await _capture("offer_empty_skip.png"):
		return false
	if board.run.pick_card(0) or board.run.pick_card(1) or board.run.pick_card(2):
		print("empty offer accepted a number key")
		return false
	if not board.run.skip_offer():
		print("empty offer did not skip")
		return false
	return true


func _capture_meter_row() -> bool:
	board.showing_records = false
	board.save_note = ""
	board.run.trophy_name = ""
	board.highlight = 1
	board.confirm_kicker()
	board.run.cash_popup = ""
	board.run.vitamin_note = ""
	if not await _capture("meter_row_fresh.png"):
		return false
	board.logic.phase = KickLogic.Phase.POWER
	board.logic.needle = 48.0
	board.logic.power = 48.0
	board.logic.fill_power = 48.0
	board.logic.windup_left = 0.0
	board.logic.needle_angle = MeterGauge.power_angle(48.0)
	board.meter_time = 0.2
	if not await _capture("meter_power_mid.png"):
		return false
	board.logic.needle = 97.0
	board.logic.power = 97.0
	board.logic.fill_power = 97.0
	board.logic.needle_angle = MeterGauge.power_angle(97.0)
	if not await _capture("meter_power_redtip.png"):
		return false
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 80.0
	board.logic.fill_power = 80.0
	board.logic.needle = 6.0
	board.logic.needle_angle = MeterGauge.angle_from_error(6.0)
	if not await _capture("meter_accuracy_good.png"):
		return false
	board.logic.needle = 0.0
	board.logic.needle_angle = MeterGauge.angle_from_error(0.0)
	if not await _capture("meter_accuracy_perfect.png"):
		return false
	board.run.give(Loadout.PINPOINT, 4)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 80.0
	board.logic.fill_power = 80.0
	board.logic.needle = 0.0
	board.logic.needle_angle = MeterGauge.angle_from_error(0.0)
	if not await _capture("meter_pinpoint_wide.png"):
		return false
	board.run.give(Loadout.TIGHT)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 80.0
	board.logic.fill_power = 80.0
	board.logic.needle = 0.0
	board.logic.needle_angle = MeterGauge.angle_from_error(0.0)
	if not await _capture("meter_tight_window.png"):
		return false
	board.run.force_offer([
		{"id": Loadout.SCOUT_LID, "slot": Loadout.HELMET, "kind": Loadout.EQUIPMENT, "rank": 1},
		{"id": Loadout.HERO_BALL, "slot": Loadout.PERK, "kind": Loadout.PERK, "rank": 1},
		{"id": Loadout.SHANKY, "slot": Loadout.CURSE, "kind": Loadout.CURSE, "rank": 1},
	])
	board.run.roll_offer()
	if not await _capture("meter_offer_sprites.png"):
		return false
	board.run.skip_offer()
	board.run.give(Loadout.CANNON, 1)
	board.run.give(Loadout.SCOUT_LID, 1)
	board.run.give(Loadout.HERO_BALL, 1)
	board.run.give(Loadout.SHANKY)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	if not await _capture("meter_row_filled.png"):
		return false
	board.run.give(Loadout.SCOUT_LID, 2)
	board.load_current_kick()
	if not await _capture("meter_rank_badge.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.run.give(Loadout.ICED)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.POWER
	board.logic.needle = 40.0
	board.logic.power = 40.0
	board.meter_time = 0.5
	if not await _capture("meter_iced_curse_hidden.png"):
		return false
	board.highlight = 0
	board.confirm_kicker()
	var step_guard := 0
	while board.run.kick_number < 5 and step_guard < 20:
		board.run.phase = RunLogic.Phase.PLAYING
		board.run.kick_resolved = false
		board.run.resolve_kick("GOOD", 2.0, false)
		board.run.leave_shop()
		if not board.advance_run():
			break
		step_guard += 1
	board.force_weather(RunLogic.ICED)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 80.0
	board.logic.fill_power = 80.0
	board.logic.needle = 11.4
	board.logic.needle_angle = MeterGauge.angle_from_error(11.4)
	board.meter_time = 0.3
	if not await _capture("meter_iced_boss_needle.png"):
		return false
	return true


func _capture_vitamin_shop() -> bool:
	board.showing_records = false
	board.save_note = ""
	board.highlight = 1
	board.confirm_kicker()
	board.run.cash_popup = ""
	if not await _capture("shop_hud_zero.png"):
		return false
	board.script_good_kick()
	board.logic.result_text = "GOOD"
	board.logic.phase = KickLogic.Phase.RESULT
	if board.run.cash < 3 or board.run.cash_popup == "":
		print("cash popup missing ", board.run.cash, " ", board.run.cash_popup)
		return false
	if not await _capture("shop_cash_popup.png"):
		return false
	board.run.kick_number = 5
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.kick_resolved = true
	board.run.last_result_made = true
	board.run.cash = 18
	board.run.set_seed(3)
	board.run.open_shop()
	board.run.shop_stock = [Vitamins.PROTEIN, Vitamins.LUTEIN, Vitamins.TART]
	if board.run.next_boss_line() != "Next boss: The Squeeze":
		print("missing squeeze line")
		return false
	if not await _capture("shop_kick5.png"):
		return false
	board.run.buy_shelf(0)
	if str(board.run.belt[0]) != Vitamins.PROTEIN or str(board.run.shop_stock[0]) != "":
		print("buy did not fill Z")
		return false
	if not await _capture("shop_bought.png"):
		return false
	board.run.buy_shelf(1)
	board.run.buy_shelf(2)
	if board.run.shop_note != "Belt full: sell first":
		print("belt full note missing ", board.run.shop_note)
		return false
	if not await _capture("shop_belt_full.png"):
		return false
	board.run.sell_belt(0)
	if not await _capture("shop_after_sell.png"):
		return false
	board.run.leave_shop()
	board.run.kick_number = 10
	board.run.last_result_made = true
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.open_shop()
	if not await _capture("shop_kick10.png"):
		return false
	board.run.leave_shop()
	board.run.kick_number = 15
	board.run.last_result_made = true
	board.run.open_shop()
	if not await _capture("shop_kick15.png"):
		return false
	board.run.leave_shop()
	board.run.kick_number = 1
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.kick_resolved = false
	board.run.last_result_made = false
	board.run.trophy_name = ""
	board.run.cash_popup = ""
	board.run.belt = [Vitamins.PROTEIN, ""]
	board.run.cash_popup = ""
	board.run.vitamin_note = ""
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	if not board.run.use_belt(0):
		print("protein was not used")
		return false
	board.apply_live_vitamins()
	if not await _capture("shop_protein_used.png"):
		return false
	board.run.belt = [Vitamins.LUTEIN, ""]
	board.run.vitamin_note = ""
	board.set_wind(10.0, 90.0)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.logic.aim_degrees = 4.0
	if not board.run.use_belt(0):
		print("lutein was not used")
		return false
	board.apply_live_vitamins()
	if board.logic.stats.path_percent < 100.0 or not board.logic.stats.flag_reader:
		print("lutein path flags missing")
		return false
	if not await _capture("shop_lutein_path.png"):
		return false
	board.run._clear_ball_vitamins()
	board.run.give(Loadout.ICED)
	board.run.give(Loadout.SHANKY)
	board.run.belt = [Vitamins.TART, ""]
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	if not board.run.use_belt(0) or not board.run.curse_prompt:
		print("tart prompt missing")
		return false
	if not await _capture("shop_tart_prompt.png"):
		return false
	return true


func _shoot_power_result(kick_number: int, file_name: String, expect: String, expect_range: float) -> bool:
	board.run.kick_number = kick_number
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.kick_resolved = false
	board.run.last_result_made = false
	board.run.awaiting_offer = false
	board.run.spot_yards = 0.0
	board.run.attempts = 3
	board.set_wind(0.0, 0.0)
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.set_seed(3)
	_finish_full_power()
	if board.logic.result_text != expect or absf(board.logic.max_range - expect_range) > 0.05:
		print(file_name, " got ", board.logic.result_text, " range ", board.logic.max_range, " power ", board.logic.power)
		return false
	return await _capture(file_name)


func _finish_full_power() -> void:
	_swing_meter(100.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)


func _set_accuracy_needle(power_value: float, along: float) -> void:
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = power_value
	board.logic.fill_power = power_value
	var error := 15.0 - clampf(along, 0.0, 1.0) * 30.0
	board.logic.needle = error
	board.logic.needle_angle = MeterGauge.angle_from_error(error)


func _log_posts(tag: String) -> void:
	var tee: Vector2 = board.world_to_screen(board._tee_position())
	var left: Vector2 = board.world_to_screen(Vector3(-board.run.post_half_gap(), 5.0, 0.0))
	var right: Vector2 = board.world_to_screen(Vector3(board.run.post_half_gap(), 5.0, 0.0))
	print(tag, " spot ", board.logic.start_lateral_yards, " tee_x ", tee.x, " post_x ", left.x, " ", right.x, " label ", RunLogic.spot_label(board.run.spot_yards))


func _lock_full_power_straight() -> void:
	for seed_value in 40:
		board.load_current_kick()
		board.logic.set_seed(seed_value)
		_swing_meter(99.0, 0.0)
		if board.logic.result_text == "GOOD" and absf(board.logic.offset_yards) < 1.5:
			return


func _finish_centered_power(power_value: float) -> void:
	_swing_meter(power_value, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)


func _swing_meter(power_value: float, error_value: float) -> void:
	board.logic.press_space()
	if board.logic.windup_left > 0.0:
		board.logic.advance(board.logic.windup_left)
	if power_value >= KickConstants.METER_MAX - 0.001:
		board.logic.take_power_press(board.logic.seconds_to_power(power_value))
	elif power_value > 0.0:
		board.logic.advance(board.logic.seconds_to_power(power_value))
		if board.logic.phase == KickLogic.Phase.POWER:
			board.logic.press_space()
	if board.logic.phase == KickLogic.Phase.ACCURACY:
		var wait: float = board.logic.seconds_until_error(error_value)
		if wait > 0.0:
			board.logic.advance(wait)
		if board.logic.phase == KickLogic.Phase.ACCURACY:
			board.logic.press_space()


func _capture_needle() -> bool:
	board.highlight = 1
	board.confirm_kicker()
	board.showing_records = false
	board.save_note = ""
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.logic.needle_angle = MeterGauge.MAX_ANGLE
	board.meter_time = 0.0
	if not await _capture("needle_rest.png"):
		return false
	board.logic.press_space()
	board.logic.advance(MeterGauge.WINDUP_SEC)
	board.meter_time = MeterGauge.WINDUP_SEC
	print("NEEDLE windup angle ", board.logic.needle_angle, " P ", board.logic.power_true)
	if not await _capture("needle_windup.png"):
		return false
	board.logic.advance(0.5)
	board.meter_time = MeterGauge.WINDUP_SEC + 0.5
	print("NEEDLE power mid t=0.50s after POWER P=", board.logic.power_true, " angle ", board.logic.needle_angle)
	if not await _capture("needle_power_mid.png"):
		return false
	var locked: float = board.logic.needle_angle
	board.logic.press_space()
	board.logic.advance(0.15)
	print("NEEDLE lock continue fill ", board.logic.fill_power, " from angle ", locked, " to ", board.logic.needle_angle)
	if not await _capture("needle_power_lock_continue.png"):
		return false
	board.logic.advance(board.logic.seconds_until_error(6.0))
	print("NEEDLE good wedge e ", board.logic.needle, " angle ", board.logic.needle_angle)
	if not await _capture("needle_accuracy_good.png"):
		return false
	board.logic.advance(board.logic.seconds_until_error(0.0))
	board.logic.press_space()
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	print("NEEDLE perfect result ", board.logic.result_text, " perfect ", board.logic.perfect, " e ", board.logic.accuracy_error)
	if not await _capture("needle_accuracy_perfect.png"):
		return false
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.45)
	board.logic.press_space()
	board.logic.advance(board.logic.seconds_until_error(-15.0) + 0.02)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("NEEDLE timeout e ", board.logic.accuracy_error, " result ", board.logic.result_text, " angle ", board.logic.needle_angle)
	if not await _capture("needle_accuracy_timeout.png"):
		return false
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.take_power_press(board.logic.seconds_to_power(100.0))
	print("NEEDLE p100 P ", board.logic.power, " fill ", board.logic.fill_power, " angle ", board.logic.needle_angle, " phase ", board.logic.phase)
	if not await _capture("needle_p100_redtip.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.run.give(Loadout.HERO_BALL, 1)
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.5)
	print("NEEDLE hero t=0.50s P=", board.logic.power_true, " speed ", board.logic.stats.power_speed, " (plain would be 50)")
	if not await _capture("needle_hero_slow.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.run.give(Loadout.STONE)
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.5)
	print("NEEDLE stone toe t=0.50s P=", board.logic.power_true, " speed ", board.logic.stats.power_speed, " (plain would be 50)")
	if not await _capture("needle_stone_toe_fast.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.force_weather(RunLogic.RAIN)
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.55)
	board.logic.press_space()
	board.logic.advance(board.logic.seconds_until_error(15.0))
	board.logic.advance(0.75)
	print("NEEDLE rain t=0.75s after MAX e=", board.logic.needle, " (clear would be about -7.5) angle ", board.logic.needle_angle)
	if not await _capture("needle_rain_acc_fast.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.run.give(Loadout.ICED)
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.2)
	board.meter_time = 0.5
	print("NEEDLE iced curse hidden ", board.run.meter_hidden(true, board.meter_time))
	if not await _capture("needle_iced_curse.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	var step_guard := 0
	while board.run.kick_number < 5 and step_guard < 20:
		board.run.phase = RunLogic.Phase.PLAYING
		board.run.kick_resolved = false
		board.run.resolve_kick("GOOD", 2.0, false)
		board.run.leave_shop()
		if not board.advance_run():
			break
		step_guard += 1
	board.force_weather(RunLogic.ICED)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 80.0
	board.logic.fill_power = 80.0
	board.logic.needle = 11.4
	board.logic.needle_angle = MeterGauge.angle_from_error(11.4)
	board.meter_time = 0.3
	print("NEEDLE iced boss fade ", RunLogic.iced_needle_alpha(board.run.needle_fades(), true, 80.0, 11.4))
	if not await _capture("needle_iced_boss.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.force_weather(RunLogic.CLEAR)
	board.run.give(Loadout.PINPOINT, 4)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 70.0
	board.logic.fill_power = 70.0
	board.logic.needle = 0.0
	board.logic.needle_angle = MeterGauge.angle_from_error(0.0)
	print("NEEDLE pinpoint perfect band ", board.logic.stats.perfect_band, " good ", board.logic.stats.good_band)
	if not await _capture("needle_pinpoint_wide.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.run.give(Loadout.TIGHT)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 70.0
	board.logic.fill_power = 70.0
	board.logic.needle = 0.0
	board.logic.needle_angle = MeterGauge.angle_from_error(0.0)
	print("NEEDLE tight window perfect band ", board.logic.stats.perfect_band, " good ", board.logic.stats.good_band)
	if not await _capture("needle_tight_window.png"):
		return false
	return true


func _capture_menus() -> bool:
	board.showing_records = false
	board.selecting = false
	board.front.screen = FrontEnd.Screen.TITLE
	board.front.menu_index = 0
	board.front.lock_message = ""
	board.front.notice = ""
	board.front.rebinding = ""
	if not await _capture("title_press_start.png"):
		return false
	board.front.confirm_title()
	board.front.menu_index = 0
	if not await _capture("menu_standard_highlight.png"):
		return false
	var saved_wins := SaveData.wins
	var saved_trophy := SaveData.has_trophy("season_complete")
	SaveData.wins = 0
	SaveData.trophies["season_complete"] = false
	board.front.menu_index = 1
	board.front.confirm_menu()
	print("MENU endless locked ", board.front.lock_message, " screen ", board.front.screen)
	if not await _capture("menu_endless_locked.png"):
		return false
	board.front.lock_message = ""
	board.front.menu_index = 2
	if not await _capture("menu_trophy_highlight.png"):
		return false
	board.front.menu_index = 3
	if not await _capture("menu_options_highlight.png"):
		return false
	board.front.menu_index = 0
	board.front.confirm_menu()
	board.selecting = true
	board.highlight = 0
	if not await _capture("select_from_standard.png"):
		return false
	board.selecting = false
	board.front.open_records(FrontEnd.Screen.MAIN)
	if not await _capture("trophy_room.png"):
		return false
	board.front.back_records()
	board.front.screen = FrontEnd.Screen.OPTIONS
	board.front.focus = 3
	board.front.notice = ""
	board.front.rebinding = ""
	Settings.reset_controls()
	Settings.set_volume("music", 100, false)
	Settings.set_volume("crowd", 100, false)
	Settings.set_volume("sfx", 100, false)
	if not await _capture("options_default.png"):
		return false
	Settings.set_volume("music", 40)
	board.front.focus = 0
	if not await _capture("options_music_40.png"):
		return false
	Settings.try_rebind("aim_left", KEY_A)
	board.front.focus = 4
	if not await _capture("options_rebind_aim.png"):
		return false
	board.front.focus = 3
	board.front.notice = FrontEnd.USED_TEXT
	board.front.notice_left = 2.0
	if not await _capture("options_already_used.png"):
		return false
	Settings.reset_controls()
	board.front.notice = ""
	board.front.focus = 4
	if not await _capture("options_reset.png"):
		return false
	SaveData.wins = 1
	board.front.screen = FrontEnd.Screen.MAIN
	board.front.menu_index = 1
	board.front.lock_message = ""
	board.selecting = false
	print("MENU endless unlocked ", board.front.endless_unlocked())
	if not await _capture("menu_endless_unlocked.png"):
		return false
	SaveData.wins = saved_wins
	SaveData.trophies["season_complete"] = saved_trophy
	board.front.screen = FrontEnd.Screen.PLAY
	board.selecting = false
	board.showing_records = false
	board.run.phase = RunLogic.Phase.GAME_OVER
	board.run.score = 42
	board.run.kicks_made = 3
	if not await _capture("game_over_main_menu.png"):
		return false
	return true


func _capture_modes() -> bool:
	board.showing_records = false
	board.front.screen = FrontEnd.Screen.PLAY
	board.selecting = false
	board.highlight = 0
	board.front.run_mode = "endless"
	board.confirm_kicker()
	board.run.run_mode = "endless"
	board.run.set_wind(0.0, 0.0)
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	print("ENDLESS kick 1 ", board.run.distance_yards(), " boss ", board.run.is_boss())
	if not await _capture("endless_kick1_20.png"):
		return false
	board.run.kick_number = 2
	board.load_current_kick()
	print("ENDLESS kick 2 ", board.run.distance_yards())
	if not await _capture("endless_kick2_25.png"):
		return false
	board.run.kick_number = 5
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	print("ENDLESS kick 5 boss ", board.run.is_boss(), " dist ", board.run.distance_yards())
	if not await _capture("endless_kick5_not_boss.png"):
		return false
	board.run.kick_number = 10
	board.run.weather_forced = false
	board.run.endless_bosses = {}
	board.run._weather_rng.seed = 4
	board.run._roll_weather()
	board.load_current_kick()
	print("ENDLESS kick 10 ", board.run.weather, " dist ", board.run.distance_yards())
	if not await _capture("endless_kick10_boss.png"):
		return false
	board.run.kick_number = 15
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	print("ENDLESS kick 15 boss ", board.run.is_boss())
	if not await _capture("endless_kick15_not_boss.png"):
		return false
	board.run.kick_number = 20
	board.run.weather_forced = false
	board.run._weather_rng.seed = 9
	board.run._roll_weather()
	board.load_current_kick()
	print("ENDLESS kick 20 ", board.run.weather, " phase ", board.run.phase)
	if not await _capture("endless_kick20_boss.png"):
		return false
	board.run.kick_number = 5
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.last_result_made = true
	board.run.kick_resolved = true
	board.run.endless_bosses = {}
	board.run._weather_rng.seed = 4
	board.run.open_shop()
	print("ENDLESS shop preview ", board.run.next_boss_line())
	if not await _capture("endless_shop5_preview.png"):
		return false
	board.run.leave_shop()
	board.run.force_weather(RunLogic.CLEAR)
	board.run.set_wind(0.0, 0.0)
	board.run.give(Loadout.CANNON, 7)
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.awaiting_shop = false
	board.load_current_kick()
	print("ENDLESS cannon rank ", board.run.cleats_rank)
	if not await _capture("endless_rank_vii.png"):
		return false
	board.run.give(Loadout.HOT_STREAK, 4)
	board.load_current_kick()
	print("ENDLESS hot streak ", board.run._perk_rank(Loadout.HOT_STREAK))
	if not await _capture("endless_perk_iv.png"):
		return false
	board.front.run_mode = "standard"
	board.highlight = 1
	board.confirm_kicker()
	board.run.kick_resolved = true
	board.run.last_result_made = true
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.roll_offer()
	var high := false
	for card in board.run.offer:
		var rank := int(card.get("rank", 1))
		var id := str(card.get("id", ""))
		if Loadout.kind_of(id) == Loadout.PERK and rank > 3:
			high = true
		if Loadout.kind_of(id) == Loadout.EQUIPMENT and rank > 6:
			high = true
	print("STANDARD offer high ranks ", high, " cards ", board.run.offer.size())
	if high:
		return false
	if not await _capture("standard_no_high_ranks.png"):
		return false
	board.run.skip_offer()
	board.highlight = 0
	board.confirm_kicker()
	board.run.kick_number = 11
	board.run.run_mode = "endless"
	board.run.set_wind(0.0, 0.0)
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	_swing_meter(100.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	print("ENDLESS 70yd ", board.logic.result_text, " range ", board.logic.max_range, " dist ", board.run.distance_yards())
	if board.logic.result_text != "SHORT":
		return false
	if not await _capture("endless_bruce_70_short.png"):
		return false
	board.run.kick_number = 37
	board.run.kick_resolved = false
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.run_mode = "endless"
	board.run.give(Loadout.CANNON, 12)
	board.run.give(Loadout.HIGH_AIR, 12)
	board.run.give(Loadout.GLASS_LEG, 6)
	board.run.give(Loadout.STONE)
	board.run.give(Loadout.SHAKY)
	board.run.set_wind(0.0, 0.0)
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	_swing_meter(100.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("ENDLESS 200 ", board.logic.result_text, " range ", board.logic.max_range)
	if board.logic.result_text != "GOOD":
		return false
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("endless_200_good.png"):
		return false
	SaveData.trophies["season_complete"] = false
	board.run.kick_number = 20
	board.run.kick_resolved = false
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.run_mode = "endless"
	board.run.attempts = 3
	board.run.resolve_kick("GOOD", 0.0, true)
	print("ENDLESS kick 20 phase ", board.run.phase, " season ", SaveData.has_trophy("season_complete"))
	board.showing_records = true
	board.front.screen = FrontEnd.Screen.RECORDS
	if not await _capture("endless_no_season_complete.png"):
		return false
	board.showing_records = false
	board.front.screen = FrontEnd.Screen.PLAY
	board.run.kick_number = 197
	board.run.kick_resolved = false
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.run_mode = "endless"
	board.run.resolve_kick("GOOD", 0.0, false)
	print("ENDLESS far phase ", board.run.phase, " dist ", board.run.distance_yards())
	if not await _capture("endless_thats_far_enough.png"):
		return false
	board.front.screen = FrontEnd.Screen.SELECT
	board.selecting = true
	board.showing_records = false
	board.highlight = 0
	if not await _capture("bruce_select_kit.png"):
		return false
	board.confirm_kicker()
	board.run.kick_number = 5
	board.run.set_wind(0.0, 0.0)
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	_swing_meter(20.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("BRUCE floor 48 ", board.logic.power, " range ", board.logic.max_range, " ", board.logic.result_text)
	if not await _capture("bruce_floor_low_p.png"):
		return false
	board.load_current_kick()
	board.run.kick_number = 16
	board.run.set_wind(0.0, 0.0)
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	_swing_meter(20.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("BRUCE floor 60 ", board.run.distance_yards(), " ", board.logic.result_text, " range ", board.logic.max_range)
	if not await _capture("bruce_floor_60_short.png"):
		return false
	board.run.kick_number = 1
	board.load_current_kick()
	_swing_meter(90.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("BRUCE p90 ", board.logic.power, " range ", board.logic.max_range)
	if not await _capture("bruce_p90.png"):
		return false
	board.run.kick_number = 17
	board.run.set_wind(0.0, 0.0)
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	_swing_meter(100.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("BRUCE p100 ", board.logic.max_range, " dist ", board.run.distance_yards(), " ", board.logic.result_text)
	if not await _capture("bruce_p100_65.png"):
		return false
	board.run.set_wind(10.0, 90.0)
	board.load_current_kick()
	_swing_meter(80.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration * 0.7)
	print("BRUCE wind drift ", board.logic.drift_yards)
	if not await _capture("bruce_farm_ball_wind.png"):
		return false
	board.run.kick_number = 1
	board.run.set_wind(0.0, 0.0)
	board.run.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.aim_degrees = rad_to_deg(atan(3.08 / 35.0))
	_swing_meter(94.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("BRUCE doink ", board.logic.result_text, " range ", board.logic.max_range, " offset ", board.logic.offset_yards)
	if board.logic.result_text != "DOINK":
		return false
	if not await _capture("bruce_doink_no_bank.png"):
		return false
	board.front.screen = FrontEnd.Screen.SELECT
	board.selecting = true
	board.highlight = 1
	if not await _capture("walkon_unchanged.png"):
		return false
	return true


func _capture_imported_art() -> bool:
	board.showing_records = false
	board.selecting = false
	board.front.screen = FrontEnd.Screen.PLAY
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.awaiting_shop = false
	board.run.awaiting_offer = false
	board.run.awaiting_mulligan = false
	board.run.curse_prompt = false
	board.run.cash_popup = ""
	board.run.vitamin_note = ""
	board.run.shop_note = ""
	var rows: Array = [
		[Loadout.CANNON, Loadout.WIND_VISOR, Loadout.IRON_GRIP, "art_hud_cannon_visor_grip.png"],
		[Loadout.PINPOINT, Loadout.ICE_CAGE, Loadout.REPLAY_GLOVES, "art_hud_pinpoint_cage_replay.png"],
		[Loadout.ANCHOR, Loadout.SCOUT_LID, Loadout.HIGH_AIR, "art_hud_anchor_scout_high_air.png"],
		[Loadout.STICKER, Loadout.DOINK_CAP, Loadout.WEATHER_WRAPS, "art_hud_sticker_doink_wraps.png"],
	]
	for row in rows:
		board.run.cleats_id = str(row[0])
		board.run.cleats_rank = 1
		board.run.helmet_id = str(row[1])
		board.run.helmet_rank = 1
		board.run.gloves_id = str(row[2])
		board.run.gloves_rank = 1
		board.run.perks = [{"id": Loadout.HERO_BALL, "rank": 1}]
		board.run.curse_ids = [Loadout.SHANKY]
		board.run.belt = ["", ""]
		board.force_weather(RunLogic.CLEAR)
		board.load_current_kick()
		board.logic.phase = KickLogic.Phase.AIMING
		board.pose_for_shot("idle")
		if not await _capture(str(row[3])):
			return false
	board.run.perks = []
	board.run.curse_ids = []
	board.run.cleats_id = ""
	board.run.helmet_id = ""
	board.run.gloves_id = ""
	board.run.force_offer([
		{"id": Loadout.CANNON, "rank": 1},
		{"id": Loadout.WIND_VISOR, "rank": 1},
		{"id": Loadout.REPLAY_GLOVES, "rank": 1},
	])
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.roll_offer()
	if board.run.offer.size() != 3:
		print("offer art cards missing ", board.run.offer)
		return false
	if not await _capture("art_offer_new_sprites.png"):
		return false
	board.run.skip_offer()
	board.run.kick_number = 5
	board.run.last_result_made = true
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.cash = 40
	board.run.attempts = 2
	board.run.open_shop()
	board.run.shop_stock = [Vitamins.PICKLE, Vitamins.OMEGA, Vitamins.MAGNESIUM]
	board.run.belt = [Vitamins.VITAMIN_D, Vitamins.LUTEIN]
	board.run.shop_b12_bought = false
	if not await _capture("art_shop_bottles.png"):
		return false
	board.run.leave_shop()
	board.run.kick_number = 6
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.awaiting_offer = false
	board.run.awaiting_shop = false
	board.run.cleats_id = Loadout.STICKER
	board.run.cleats_rank = 2
	board.run.helmet_id = Loadout.SCOUT_LID
	board.run.helmet_rank = 1
	board.run.gloves_id = Loadout.WEATHER_WRAPS
	board.run.gloves_rank = 1
	board.run.perks = [{"id": Loadout.TWO_MINUTE, "rank": 1}]
	board.run.curse_ids = [Loadout.HEAVY]
	board.run.belt = [Vitamins.B12, Vitamins.PROTEIN]
	board.run.cash = 12
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.pose_for_shot("idle")
	if not await _capture("art_belt_filled.png"):
		return false
	return true


func _capture_clean_meter() -> bool:
	board.showing_records = false
	board.selecting = false
	board.front.screen = FrontEnd.Screen.PLAY
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.awaiting_shop = false
	board.run.awaiting_offer = false
	board.run.awaiting_mulligan = false
	board.run.curse_prompt = false
	board.front.run_mode = "standard"
	board.highlight = 0
	board.confirm_kicker()
	board.run.set_wind(0.0, 0.0)
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.logic.needle_angle = MeterGauge.MAX_ANGLE
	board._pose = "idle"
	var bruce := KickLogic.new()
	Kickers.apply_to(bruce.stats, Kickers.BIG_BRUCE)
	bruce.press_space()
	bruce.advance(bruce.windup_left)
	var bruce_time := 0.0
	while bruce.phase == KickLogic.Phase.POWER and bruce_time < 3.0:
		bruce.advance(0.0002)
		bruce_time += 0.0002
	var walk := KickLogic.new()
	Kickers.apply_to(walk.stats, Kickers.WALK_ON)
	walk.press_space()
	walk.advance(walk.windup_left)
	var walk_time := 0.0
	while walk.phase == KickLogic.Phase.POWER and walk_time < 3.0:
		walk.advance(0.0002)
		walk_time += 0.0002
	print("CLEAN METER POWER to MAX Bruce ", bruce_time, " Walk-On ", walk_time)
	if not await _capture("meter_clean_idle.png"):
		return false
	if not await _capture_gauge_crop("meter_clean_idle_close.png"):
		return false
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(board.logic.seconds_to_power(55.0))
	board._pose = "run"
	if not await _capture("meter_clean_power_mid.png"):
		return false
	board.logic.press_space()
	board.logic.advance(board.logic.seconds_until_error(4.0))
	board._pose = "run"
	if not await _capture("meter_clean_accuracy.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.logic.needle_angle = MeterGauge.MAX_ANGLE
	board._pose = "idle"
	if not await _capture("meter_clean_walkon_idle.png"):
		return false
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.35)
	board._pose = "run"
	if not await _capture("meter_clean_walkon_sweep.png"):
		return false
	board.highlight = 0
	board.confirm_kicker()
	board.run.belt = [Vitamins.MAGNESIUM, ""]
	if not board.run.use_belt(0):
		print("clean meter magnesium was not used")
		return false
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.5)
	print("CLEAN METER magnesium P ", board.logic.power_true, " speed ", board.logic.stats.power_speed)
	board._pose = "run"
	if not await _capture("meter_clean_magnesium.png"):
		return false
	return true


func _capture_roster() -> bool:
	SaveData.reset_save()
	board.showing_records = false
	board.selecting = true
	board.front.screen = FrontEnd.Screen.SELECT
	board.highlight = 2
	if not await _capture("select_locked.png"):
		return false
	SaveData.try_unlock(Kickers.PHIL)
	SaveData.try_unlock(Kickers.GARY)
	SaveData.try_unlock(Kickers.VEX)
	board.highlight = 4
	if not await _capture("select_unlocked.png"):
		return false
	board.showing_records = true
	board.front.screen = FrontEnd.Screen.RECORDS
	if not await _capture("records_five_kickers.png"):
		return false
	board.showing_records = false
	var roster: Array = [
		[0, "bruce"],
		[1, "walkon"],
		[2, "phil"],
		[3, "gary"],
		[4, "vex"],
	]
	for entry in roster:
		board.highlight = int(entry[0])
		board.confirm_kicker()
		board.force_weather(RunLogic.CLEAR)
		board.run.set_wind(0.0, 0.0)
		board.load_current_kick()
		board.logic.phase = KickLogic.Phase.AIMING
		board.logic.needle_angle = MeterGauge.MAX_ANGLE
		board._pose = "idle"
		if not await _capture("field_%s_idle.png" % str(entry[1])):
			return false
		board._pose = "run"
		board._run_time = 0.2
		if not await _capture("field_%s_run.png" % str(entry[1])):
			return false
		board._pose = "plant"
		if not await _capture("field_%s_plant.png" % str(entry[1])):
			return false
		board._pose = "follow"
		if not await _capture("field_%s_follow.png" % str(entry[1])):
			return false
		board.logic.phase = KickLogic.Phase.ACCURACY
		board.logic.power = 50.0
		board.logic.fill_power = 50.0
		board.logic.needle = 0.0
		board.logic.needle_angle = MeterGauge.angle_from_error(0.0)
		board._pose = "idle"
		if not await _capture("meter_band_%s.png" % str(entry[1])):
			return false
		if not await _capture_gauge_crop("meter_band_%s_close.png" % str(entry[1])):
			return false
	board.highlight = 2
	board.confirm_kicker()
	board.run.cash = 12
	board.run.kick_number = 5
	board.run.last_result_made = true
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.open_shop()
	board.run.shop_stock = [Vitamins.PROTEIN, Vitamins.OMEGA, Vitamins.MAGNESIUM]
	board.run.shop_b12_bought = false
	board.run.attempts = 2
	if not await _capture("phil_shop_free.png"):
		return false
	board.run.leave_shop()
	board.highlight = 3
	board.confirm_kicker()
	board.force_weather(RunLogic.CLEAR)
	board.run.set_wind(0.0, 0.0)
	board.load_current_kick()
	_swing_meter(50.0, 4.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("GARY result ", board.logic.result_text, " perfect ", board.logic.perfect, " e ", board.logic.accuracy_error)
	if not await _capture("gary_good_as_gold.png"):
		return false
	board.highlight = 4
	board.confirm_kicker()
	board.run.kick_number = 1
	board.force_weather(RunLogic.CLEAR)
	board.run.set_wind(0.0, 0.0)
	board.load_current_kick()
	_swing_meter(90.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration * 0.55)
	print("VEX curve drift ", board.logic.drift_yards, " range ", board.logic.max_range)
	if not await _capture("vex_curve_left.png"):
		return false
	board.load_current_kick()
	_swing_meter(88.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("VEX 88 range ", board.logic.max_range, " ", board.logic.result_text)
	if not await _capture("vex_clear_88.png"):
		return false
	board.load_current_kick()
	_swing_meter(100.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("VEX 100 range ", board.logic.max_range, " ", board.logic.result_text)
	if not await _capture("vex_clear_100.png"):
		return false
	board.load_current_kick()
	_swing_meter(80.0, 0.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("VEX 80 range ", board.logic.max_range, " ", board.logic.result_text)
	if not await _capture("vex_short_80.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.run.belt = [Vitamins.MAGNESIUM, ""]
	if not board.run.use_belt(0):
		print("roster magnesium was not used")
		return false
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.35)
	board._pose = "run"
	print("ROSTER magnesium P ", board.logic.power_true, " speed ", board.logic.stats.power_speed)
	if not await _capture("meter_magnesium_0_35s.png"):
		return false
	return true


func _capture_shank_meter() -> bool:
	board.highlight = 1
	board.confirm_kicker()
	board.force_weather(RunLogic.CLEAR)
	board.run.set_wind(0.0, 0.0)
	board.load_current_kick()
	board.logic.set_seed(4)
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(board.logic.seconds_to_power(100.0) + 0.02)
	print("SHANK phase ", board.logic.phase, " result ", board.logic.result_text, " offset ", board.logic.offset_yards, " power ", board.logic.power, " shanked ", board.logic.shanked)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration * 0.45)
	board.run.unlock_toast = "SHANK  %s" % board.logic.result_text
	board._pose = "follow"
	if not await _capture("meter_shank_flight.png"):
		return false
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration - board.logic.flight_elapsed)
	board._pose = "follow"
	if not await _capture("meter_shank_result.png"):
		return false
	board.run.unlock_toast = ""
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.take_power_press(board.logic.seconds_to_power(100.0))
	board.logic.advance(0.12)
	print("LOCK MAX phase ", board.logic.phase, " P ", board.logic.power, " angle ", board.logic.needle_angle, " shanked ", board.logic.shanked)
	board.run.unlock_toast = "P=100 lock"
	if not await _capture("meter_lock_at_max.png"):
		return false
	board.run.unlock_toast = ""
	board.load_current_kick()
	board.run.stats.practice_per_quarter = 1
	board.run.practice_left = 1
	if not board.run.start_practice():
		print("practice swing did not start")
		return false
	board.logic.set_seed(7)
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(board.logic.seconds_to_power(100.0) + 0.02)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("PRACTICE SHANK ", board.logic.result_text, " phase ", board.logic.phase, " practicing ", board.run.practicing)
	board.run.unlock_toast = "Practice swing  %s" % board.logic.result_text
	if not await _capture("meter_practice_shank.png"):
		return false
	board.run.unlock_toast = ""
	board.run.end_practice()
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 50.0
	board.logic.fill_power = 50.0
	board.logic.needle = 0.0
	board.logic.needle_angle = 45.0
	board._pose = "idle"
	board.run.unlock_toast = "POWER to MAX  0.700s"
	if not await _capture("meter_well_field.png"):
		return false
	if not await _capture_gauge_crop("meter_well_close.png"):
		return false
	board.run.unlock_toast = ""
	board.run.give(Loadout.PINPOINT, 1)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 50.0
	board.logic.fill_power = 50.0
	board.logic.needle_angle = 45.0
	board.logic.needle = 0.0
	print("PINPOINT bands ", board.logic.stats.perfect_band, board.logic.stats.good_band)
	if not await _capture_gauge_crop("meter_pinpoint_walkon_close.png"):
		return false
	board.highlight = 1
	board.confirm_kicker()
	board.run.give(Loadout.TIGHT)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.ACCURACY
	board.logic.power = 50.0
	board.logic.fill_power = 50.0
	board.logic.needle_angle = 45.0
	board.logic.needle = 0.0
	print("TIGHT bands ", board.logic.stats.perfect_band, board.logic.stats.good_band)
	if not await _capture_gauge_crop("meter_tight_walkon_close.png"):
		return false
	board.highlight = 0
	board.confirm_kicker()
	board.force_weather(RunLogic.CLEAR)
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.35)
	board.run.unlock_toast = "0.35s of 0.700s POWER to MAX"
	board._pose = "run"
	print("TIMING P ", board.logic.power_true, " expected about 50")
	if not await _capture("meter_power_timing_0_35s.png"):
		return false
	board.run.unlock_toast = ""
	return true


func _capture_m2_kickers() -> bool:
	SaveData.reset_save()
	board.showing_records = false
	board.selecting = true
	board.front.screen = FrontEnd.Screen.SELECT
	board.highlight = 5
	if not await _capture("select_eight_locked.png"):
		return false
	SaveData.try_unlock(Kickers.COLE)
	SaveData.try_unlock(Kickers.WILLOW)
	SaveData.try_unlock(Kickers.CARLOS)
	var cards: Array = [
		[5, "cole"],
		[6, "willow"],
		[7, "carlos"],
	]
	for card in cards:
		board.highlight = int(card[0])
		if not await _capture("select_%s_unlocked.png" % str(card[1])):
			return false
	var poses: Array = ["idle", "run", "plant", "follow"]
	for card in cards:
		board.highlight = int(card[0])
		board.confirm_kicker()
		board.force_weather(RunLogic.CLEAR)
		board.run.set_wind(0.0, 0.0)
		board.load_current_kick()
		for pose in poses:
			board.pose_for_shot(str(pose))
			if not await _capture("field_%s_%s.png" % [str(card[1]), str(pose)]):
				return false
	board.highlight = 5
	board.confirm_kicker()
	board.run.kick_number = 5
	board.run.last_result_made = true
	board.run.kick_resolved = true
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.roll_offer()
	board.run.unlock_toast = "Loadout, then no shop"
	if not await _capture("cole_kick5_loadout.png"):
		return false
	board.run.skip_offer()
	board.run.unlock_toast = "No vitamin shop"
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	if not await _capture("cole_kick5_no_shop.png"):
		return false
	board.run.unlock_toast = ""
	board.highlight = 6
	board.confirm_kicker()
	board.run.kick_number = 5
	board.run.last_result_made = true
	board.run.kick_resolved = true
	board.run.phase = RunLogic.Phase.PLAYING
	if board.run.follow_offer() != "shop":
		print("Willow shop did not open")
		return false
	print("WILLOW STOCK ", board.run.shop_stock)
	if not await _capture("willow_first_shop.png"):
		return false
	board.run.leave_shop()
	board.highlight = 7
	board.confirm_kicker()
	board.force_weather(RunLogic.CLEAR)
	board.run.set_wind(0.0, 0.0)
	board.load_current_kick()
	_swing_meter(100.0, 12.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration)
	print("CARLOS PERFECT ", board.logic.perfect, " e ", board.logic.accuracy_error, " ", board.logic.result_text)
	if not await _capture("carlos_numero_dos_perfect.png"):
		return false
	return true


func _ready_visor(slot: int, rank: int, wind: float, direction: float, endless_kick: int) -> void:
	board.highlight = slot
	board.confirm_kicker()
	board.showing_records = false
	board.selecting = false
	board.front.screen = FrontEnd.Screen.PLAY
	board.force_weather(RunLogic.CLEAR)
	board.run.run_mode = "standard"
	if endless_kick > 0:
		board.run.run_mode = "endless"
		board.run.kick_number = endless_kick
	if rank > 6:
		board.run.run_mode = "endless"
	board.run.give(Loadout.WIND_VISOR, rank)
	board.set_wind(wind, direction)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.logic.aim_base = 0.0
	board.logic.aim_degrees = 0.0
	board._pose = "idle"
	print("VISOR ", Kickers.id_for_slot(slot), " rank ", rank, " path ", board.logic.stats.path_percent, " wind ", board.logic.wind_speed, " travel ", board.logic.preview_plan()["travel"])


func _lock_preview_power(power_value: float) -> void:
	board.logic.phase = KickLogic.Phase.AIMING
	board.logic.press_space()
	if board.logic.windup_left > 0.0:
		board.logic.advance(board.logic.windup_left)
	board.logic.advance(board.logic.seconds_to_power(power_value))
	if board.logic.phase == KickLogic.Phase.POWER:
		board.logic.press_space()
	board._pose = "idle"


func _capture_drive_lid() -> bool:
	board.highlight = 1
	board.confirm_kicker()
	board.showing_records = false
	board.selecting = false
	board.front.screen = FrontEnd.Screen.PLAY
	board.force_weather(RunLogic.CLEAR)
	board.run.run_mode = "standard"
	board.run.kick_number = 1
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.force_offer([{"id": Loadout.DRIVE_LID, "rank": 1, "kind": Loadout.EQUIPMENT, "slot": Loadout.HELMET}])
	board.run.roll_offer()
	print("DRIVE CARD ", board.run.offer, " sprite ", Loadout.sprite_path(Loadout.DRIVE_LID))
	if not await _capture("drive_lid_card.png"):
		return false
	board.run.skip_offer()
	board.run.give(Loadout.DRIVE_LID, 1)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.run.awaiting_offer = false
	if not await _capture("drive_lid_hud.png"):
		return false
	board.run.force_offer([{"id": Loadout.DRIVE_LID, "rank": 2, "kind": Loadout.EQUIPMENT, "slot": Loadout.HELMET}, {"id": Loadout.HOT_STREAK, "rank": 1}, {"id": Loadout.ICED, "rank": 1}])
	board.run.roll_offer()
	print("DRIVE II ", board.run.offer)
	if not await _capture("drive_lid_rank2_offer.png"):
		return false
	board.run.skip_offer()
	board.highlight = 0
	board.confirm_kicker()
	board.run.give(Loadout.DRIVE_LID, 1)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.run.awaiting_offer = false
	var yards: float = board.run.stats.range_base + board.run.stats.range_per_power * 100.0 + board.run.stats.range_bonus
	board.save_note = "Full power %s yd" % KickLogic.format_number(yards)
	print("BRUCE DRIVE YARDS ", yards)
	if not await _capture("drive_lid_bruce_69.png"):
		return false
	board.save_note = ""
	board.highlight = 1
	board.confirm_kicker()
	board.run.run_mode = "endless"
	board.run.kick_number = 6
	board.run.power_item_seen = false
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.offer = [
		{"id": Loadout.WIND_VISOR, "rank": 1, "kind": Loadout.EQUIPMENT, "slot": Loadout.HELMET},
		{"id": Loadout.HOT_STREAK, "rank": 1, "kind": Loadout.PERK, "slot": Loadout.PERK},
		{"id": Loadout.ICED, "rank": 1, "kind": Loadout.CURSE, "slot": Loadout.CURSE},
	]
	board.run._consider_power_safety()
	board.run.awaiting_offer = true
	print("ENDLESS FORCE ", board.run.offer, " seen ", board.run.power_item_seen)
	if not Loadout.offer_has_power(board.run.offer):
		print("Endless safety net did not add a power item")
		return false
	if not await _capture("endless_power_safety_50.png"):
		return false
	board.run.run_mode = "standard"
	board.run.power_item_seen = false
	board.run.offer = [
		{"id": Loadout.WIND_VISOR, "rank": 1, "kind": Loadout.EQUIPMENT, "slot": Loadout.HELMET},
		{"id": Loadout.HOT_STREAK, "rank": 1, "kind": Loadout.PERK, "slot": Loadout.PERK},
		{"id": Loadout.ICED, "rank": 1, "kind": Loadout.CURSE, "slot": Loadout.CURSE},
	]
	board.run._consider_power_safety()
	board.run.awaiting_offer = true
	print("STANDARD NO FORCE ", board.run.offer)
	if Loadout.offer_has_power(board.run.offer):
		print("Standard offer was forced")
		return false
	if not await _capture("standard_no_power_safety.png"):
		return false
	board.run.skip_offer()
	board.run.run_mode = "endless"
	board.run.give(Loadout.DRIVE_LID, 7)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.run.awaiting_offer = false
	print("DRIVE VII ", board.run.helmet_rank, " ", board.run.stats.range_bonus)
	if not await _capture("drive_lid_endless_vii.png"):
		return false
	return true


func _capture_wind_visor() -> bool:
	SaveData.try_unlock(Kickers.VEX)
	_ready_visor(1, 1, 12.0, 90.0, 0)
	if board.logic.stats.path_percent > 0.0:
		print("Rank I drew a path percent")
		return false
	if not await _capture("visor_1_readout.png"):
		return false
	_ready_visor(1, 2, 12.0, 90.0, 0)
	if not await _capture("visor_2_path_40.png"):
		return false
	_ready_visor(1, 3, 12.0, 90.0, 0)
	if not await _capture("visor_3_path_55.png"):
		return false
	_ready_visor(1, 5, 12.0, 90.0, 0)
	if not await _capture("visor_5_path_85.png"):
		return false
	_ready_visor(1, 6, 12.0, 90.0, 0)
	if not await _capture("visor_6_full_path.png"):
		return false
	_ready_visor(1, 8, 18.0, 80.0, 21)
	if board.run.upcoming_winds().size() > 0:
		print("Endless visor listed future winds")
		return false
	if not await _capture("visor_endless_rank8_full.png"):
		return false
	_ready_visor(0, 6, 14.0, 70.0, 0)
	if not await _capture("visor_bruce_farm_drift.png"):
		return false
	_ready_visor(1, 6, 14.0, 70.0, 0)
	if not await _capture("visor_walkon_same_wind.png"):
		return false
	_ready_visor(4, 6, 0.0, 0.0, 0)
	if not await _capture("visor_vex_zero_wind.png"):
		return false
	_ready_visor(1, 6, 0.0, 0.0, 0)
	if not await _capture("visor_walkon_no_cleats.png"):
		return false
	board.run.give(Loadout.CANNON, 1)
	board.load_current_kick()
	board.logic.phase = KickLogic.Phase.AIMING
	board.logic.aim_base = 0.0
	board.logic.aim_degrees = 0.0
	print("VISOR cannon travel ", board.logic.preview_plan()["travel"])
	if not await _capture("visor_walkon_cannon.png"):
		return false
	_ready_visor(1, 6, 0.0, 0.0, 0)
	_lock_preview_power(60.0)
	print("VISOR locked 60 phase ", board.logic.phase, " P ", board.logic.power, " travel ", board.logic.preview_plan()["travel"])
	if not await _capture("visor_locked_power_60.png"):
		return false
	_ready_visor(0, 6, 0.0, 0.0, 0)
	_lock_preview_power(50.0)
	print("VISOR bruce locked 50 P ", board.logic.power, " floor travel ", board.logic.preview_plan()["travel"])
	if not await _capture("visor_bruce_farm_strength.png"):
		return false
	_ready_visor(1, 6, 28.0, 100.0, 25)
	if not await _capture("visor_endless_long_wind.png"):
		return false
	_ready_visor(1, 2, 10.0, 60.0, 0)
	board.run.belt[0] = Vitamins.LUTEIN
	if not board.run.use_belt(0):
		print("lutein was not used on the visor")
		return false
	board.apply_live_vitamins()
	board.logic.phase = KickLogic.Phase.AIMING
	print("VISOR lutein path ", board.logic.stats.path_percent)
	if board.logic.stats.path_percent < 100.0:
		return false
	if not await _capture("visor_lutein_one_line.png"):
		return false
	return true


func _capture_menu_and_rerolls() -> bool:
	board.showing_records = false
	board.selecting = false
	board.front.screen = FrontEnd.Screen.MAIN
	board.front.lock_message = ""
	board.front.notice = ""
	var saved_wins := SaveData.wins
	SaveData.wins = 0
	SaveData.trophies["season_complete"] = false
	var tiles: Array = [
		[0, "menu_tile_standard.png"],
		[1, "menu_tile_endless.png"],
		[2, "menu_tile_trophy.png"],
		[3, "menu_tile_options.png"],
	]
	for tile in tiles:
		board.front.menu_index = int(tile[0])
		board.front.lock_message = ""
		if not await _capture(str(tile[1])):
			return false
	board.front.screen = FrontEnd.Screen.OPTIONS
	board.front.focus = 3
	board.front.notice = ""
	board.front.rebinding = ""
	Settings.set_volume("music", 100, false)
	Settings.set_volume("crowd", 100, false)
	Settings.set_volume("sfx", 100, false)
	if not await _capture("options_selected_plate.png"):
		return false
	SaveData.wins = saved_wins
	board.highlight = 1
	board.confirm_kicker()
	board.force_weather(RunLogic.CLEAR)
	board.run.set_wind(0.0, 0.0)
	board.run.kick_number = 1
	board.run.phase = RunLogic.Phase.PLAYING
	board.run.kick_resolved = true
	board.run.last_result_made = true
	board.run.roll_offer()
	if board.run.offer.size() != 3:
		print("Offer did not draw 3 cards")
		return false
	var before: Array = board.run.offer.duplicate(true)
	var charges: int = board.run.rerolls_left
	print("OFFER BEFORE ", before, " rerolls ", charges)
	if not await _capture("offer_before_reroll.png"):
		return false
	if not board.run.reroll_offer():
		print("Offer reroll did not spend")
		return false
	print("OFFER AFTER ", board.run.offer, " rerolls ", board.run.rerolls_left)
	if board.run.rerolls_left != charges - 1:
		print("Reroll charge did not drop by 1")
		return false
	var shared := 0
	for card in board.run.offer:
		for old in before:
			if Loadout.card_key(card) == Loadout.card_key(old):
				shared += 1
	if shared > 0:
		print("Reroll kept ", shared, " previous cards")
		return false
	if not await _capture("offer_after_reroll.png"):
		return false
	board.run.cash = 40
	board.run.belt[0] = Vitamins.ZINC
	board.run.belt[1] = ""
	board.run.open_shop()
	var stock_before: Array = board.run.shop_stock.duplicate()
	var belt_before: Array = board.run.belt.duplicate()
	print("SHOP BEFORE ", stock_before, " belt ", belt_before, " b12 ", board.run.shop_b12_bought)
	if not await _capture("shop_before_reroll.png"):
		return false
	if not board.run.reroll_shop():
		print("Shop reroll failed")
		return false
	print("SHOP AFTER ", board.run.shop_stock, " belt ", board.run.belt, " b12 ", board.run.shop_b12_bought, " price ", board.run.shop_reroll_price)
	if board.run.belt != belt_before or board.run.shop_b12_bought:
		print("Shop reroll touched the belt or B12")
		return false
	for id in board.run.shop_stock:
		if stock_before.has(str(id)):
			print("Shop reroll kept ", id)
			return false
	if not await _capture("shop_after_reroll.png"):
		return false
	return true


func _capture_ball_sprites() -> bool:
	SaveData.try_unlock(Kickers.PHIL)
	SaveData.try_unlock(Kickers.GARY)
	SaveData.try_unlock(Kickers.VEX)
	SaveData.try_unlock(Kickers.COLE)
	SaveData.try_unlock(Kickers.WILLOW)
	SaveData.try_unlock(Kickers.CARLOS)
	var roster: Array = [
		[0, "bruce", "farm_ball"],
		[1, "walkon", "team_issue"],
		[2, "phil", "gelcap"],
		[3, "gary", "lucky_ball"],
		[4, "vex", "flying_saucer"],
		[5, "cole", "showtime"],
		[6, "willow", "chill_ball"],
		[7, "carlos", "secret_weapon"],
	]
	for entry in roster:
		board.highlight = int(entry[0])
		board.confirm_kicker()
		board.force_weather(RunLogic.CLEAR)
		board.run.set_wind(0.0, 0.0)
		board.load_current_kick()
		board.logic.phase = KickLogic.Phase.AIMING
		board.logic.needle_angle = MeterGauge.MAX_ANGLE
		board._pose = "idle"
		var art := Kickers.ball_sprite(board.run.kicker_id)
		print("BALL ", entry[1], " ", art)
		if art == "":
			print("Missing ball sprite for ", entry[1])
			return false
		if not await _capture("tee_%s_%s.png" % [str(entry[1]), str(entry[2])]):
			return false
		if not await _capture_ball_zoom("tee_%s_%s_close.png" % [str(entry[1]), str(entry[2])], true):
			return false
	var flights: Array = [
		[0, "bruce", "farm_ball"],
		[6, "willow", "chill_ball"],
	]
	for entry in flights:
		board.highlight = int(entry[0])
		board.confirm_kicker()
		board.force_weather(RunLogic.CLEAR)
		board.run.set_wind(0.0, 0.0)
		board.load_current_kick()
		_swing_meter(70.0, 0.0)
		if board.logic.phase == KickLogic.Phase.FLIGHT:
			board.logic.advance(board.logic.flight_duration * 0.42)
		board._step_kick_pose(0.3)
		if not await _capture("flight_%s_%s.png" % [str(entry[1]), str(entry[2])]):
			return false
		if not await _capture_ball_zoom("flight_%s_%s_close.png" % [str(entry[1]), str(entry[2])], false):
			return false
	board.highlight = 3
	board.confirm_kicker()
	board.force_weather(RunLogic.CLEAR)
	board.run.set_wind(0.0, 0.0)
	board.load_current_kick()
	board.logic.press_space()
	if board.logic.windup_left > 0.0:
		board.logic.advance(board.logic.windup_left)
	board.logic.advance(board.logic.seconds_to_power(100.0))
	if not board.logic.shanked:
		print("Expected a shank for the ball shot")
		return false
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(minf(0.28, board.logic.flight_duration * 0.2))
	board._step_kick_pose(0.2)
	if not await _capture("shank_gary_lucky_ball.png"):
		return false
	if not await _capture_ball_zoom("shank_gary_lucky_ball_close.png", false):
		return false
	return true


func _capture_ball_zoom(file_name: String, with_kicker: bool) -> bool:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = board.get_viewport().get_texture().get_image()
	if image == null or board._ball == null:
		return false
	var screen: Vector2 = board.world_to_screen(board._ball.position)
	var width := 280
	var height := 320
	var x := int(screen.x) - 120
	var y := int(screen.y) - 160
	if with_kicker:
		x -= 90
		width = 380
	x = clampi(x, 0, maxi(image.get_width() - width, 0))
	y = clampi(y, 0, maxi(image.get_height() - height, 0))
	var crop := image.get_region(Rect2i(x, y, width, height))
	crop.resize(width * 3, height * 3, Image.INTERPOLATE_NEAREST)
	var path := shot_dir.path_join(file_name)
	var err: Error = crop.save_png(path)
	if err != OK:
		print("FAILED to save ", path, " error ", err)
		return false
	print("Saved ", path, " ", crop.get_width(), "x", crop.get_height())
	return true


func _capture_gauge_crop(file_name: String) -> bool:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = board.get_viewport().get_texture().get_image()
	var gauge_w := 360
	var gauge_h := 250
	var x := KickConstants.WINDOW_WIDTH - 8 - gauge_w
	var y := KickConstants.WINDOW_HEIGHT - 8 - gauge_h
	var crop := image.get_region(Rect2i(x, y, gauge_w, gauge_h))
	crop.resize(gauge_w * 2, gauge_h * 2, Image.INTERPOLATE_NEAREST)
	var path := shot_dir.path_join(file_name)
	var err: Error = crop.save_png(path)
	if err != OK:
		print("FAILED to save ", path, " error ", err)
		return false
	print("Saved ", path, " ", crop.get_width(), "x", crop.get_height())
	return true


func _settle_weather() -> void:
	for _i in 3:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw


func _capture_precip() -> bool:
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.logic.phase = KickLogic.Phase.AIMING
	board.force_weather(RunLogic.CLEAR)
	await _settle_weather()
	if not await _capture("precip_35_clear.png"):
		return false
	board.force_weather(RunLogic.RAIN)
	await _settle_weather()
	if not await _capture("precip_35_rain.png"):
		return false
	board.cycle_debug_distance()
	board.cycle_debug_distance()
	await _settle_weather()
	if not await _capture("precip_200_rain.png"):
		return false
	board.cycle_debug_distance()
	await _settle_weather()
	if not await _capture("precip_500_rain.png"):
		return false
	board.cycle_debug_distance()
	await _settle_weather()
	if not await _capture("precip_1000_rain.png"):
		return false
	board.cycle_debug_distance()
	var attempts: int = board.run.attempts
	var kick_number: int = board.run.kick_number
	if board.preview_step() != 0:
		print("preview did not restore the real kick")
		return false
	board.force_weather(RunLogic.MONSOON)
	await _settle_weather()
	if not await _capture("precip_monsoon.png"):
		return false
	board.force_weather(RunLogic.SNOW)
	await _settle_weather()
	if not await _capture("precip_snow.png"):
		return false
	board.force_weather(RunLogic.ICED)
	await _settle_weather()
	if not await _capture("precip_iced.png"):
		return false
	board.force_weather(RunLogic.MUD)
	await _settle_weather()
	if not await _capture("precip_mud.png"):
		return false
	board.force_weather(RunLogic.THIN_AIR)
	await _settle_weather()
	if not await _capture("precip_thin_air.png"):
		return false
	board.force_weather(RunLogic.RAIN)
	board.set_wind(12.0, 90.0)
	board.refresh_view()
	await _settle_weather()
	if not await _capture("precip_rain_wind.png"):
		return false
	board.set_wind(0.0, 0.0)
	board.force_weather(RunLogic.CLEAR)
	print("PRECIP back kick ", board.run.kick_number, " attempts ", board.run.attempts, " preview ", board.preview_step(), " kind ", board.weather_state["kind"])
	if board.run.attempts != attempts or board.run.kick_number != kick_number or board.preview_step() != 0:
		print("weather preview changed the kick")
		return false
	return await _capture("precip_back_clear.png")


func _capture_sky() -> bool:
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.logic.phase = KickLogic.Phase.AIMING
	board.force_weather(RunLogic.CLEAR)
	if not await _capture("sky_35_clear.png"):
		return false
	board.cycle_debug_distance()
	board.cycle_debug_distance()
	if not await _capture("sky_200_clear.png"):
		return false
	board.cycle_debug_distance()
	if not await _capture("sky_500_clear.png"):
		return false
	board.cycle_debug_distance()
	if not await _capture("sky_1000_clear.png"):
		return false
	board.cycle_debug_distance()
	var attempts: int = board.run.attempts
	var kick_number: int = board.run.kick_number
	print("SKY real kick ", kick_number, " attempts ", attempts, " preview ", board.preview_step(), " dist ", board.logic.kick_distance)
	if board.preview_step() != 0:
		print("preview did not restore the real kick")
		return false
	for shot in [
		[RunLogic.RAIN, "sky_rain.png"],
		[RunLogic.SNOW, "sky_snow.png"],
		[RunLogic.MONSOON, "sky_monsoon.png"],
		[RunLogic.ICED, "sky_iced.png"],
		[RunLogic.MUD, "sky_mud.png"],
		[RunLogic.THIN_AIR, "sky_thin_air.png"],
		[RunLogic.CLEAR, "sky_back_clear.png"],
	]:
		board.force_weather(str(shot[0]))
		if not await _capture(str(shot[1])):
			return false
	if board.run.attempts != attempts or board.run.kick_number != kick_number or board.preview_step() != 0:
		print("weather force changed the kick")
		return false
	print("SKY back on kick ", board.run.kick_number, " attempts ", board.run.attempts, " sky ", board.sky_texture_path)
	return true


func _capture_stands() -> bool:
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.logic.phase = KickLogic.Phase.AIMING
	if not await _capture("stands_35_center.png"):
		return false
	board.cycle_debug_distance()
	board.cycle_debug_distance()
	if not await _capture("stands_200.png"):
		return false
	board.cycle_debug_distance()
	if not await _capture("stands_500.png"):
		return false
	board.cycle_debug_distance()
	if not await _capture("stands_1000.png"):
		return false
	board.cycle_debug_distance()
	board.cycle_debug_distance()
	board.cycle_debug_distance()
	board.cycle_spot()
	if not await _capture("stands_200_hash.png"):
		return false
	board.cycle_spot()
	if not await _capture("stands_200_wide.png"):
		return false
	if not await _capture_corner("stands_bowl_corner.png"):
		return false
	var attempts: int = board.run.attempts
	var kick_number: int = board.run.kick_number
	board.cycle_debug_distance()
	board.cycle_debug_distance()
	board.cycle_debug_distance()
	print("BACK real kick ", board.run.kick_number, " attempts ", board.run.attempts, " preview ", board.preview_step(), " dist ", board.logic.kick_distance)
	if board.run.attempts != attempts or board.run.kick_number != kick_number or board.preview_step() != 0:
		print("preview did not restore the real kick")
		return false
	return await _capture("stands_back_on_real_kick.png")


func _capture_corner(file_name: String) -> bool:
	board.refresh_view()
	board._camera.position = Vector3(-16.0, 6.0, 10.0)
	board._camera.look_at(Vector3(-27.4, 6.0, -2.0), Vector3.UP)
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


func _capture_gear() -> bool:
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.run.run_mode = "endless"
	var styles := [
		[Loadout.TRUE_LID, "gear_card_true_lid.png"],
		[Loadout.SHELTER_LID, "gear_card_shelter_lid.png"],
		[Loadout.GUIDE_GLOVES, "gear_card_guide_gloves.png"],
		[Loadout.PATIENT_GLOVES, "gear_card_patient_gloves.png"],
		[Loadout.HUSH_GLOVES, "gear_card_hush_gloves.png"],
	]
	for style in styles:
		board.run.force_offer([{"id": style[0], "rank": 1, "kind": Loadout.EQUIPMENT, "slot": Loadout.slot_of(str(style[0]))}])
		board.run.roll_offer()
		if not await _capture(str(style[1])):
			return false
	board.run.awaiting_offer = false
	board.run.helmet_id = Loadout.TRUE_LID
	board.run.helmet_rank = 1
	board.run.gloves_id = Loadout.GUIDE_GLOVES
	board.run.gloves_rank = 1
	board._sync_debug_loadout()
	if not await _capture("gear_hud_true_and_guide.png"):
		return false
	board.run.force_offer([{"id": Loadout.TRUE_LID, "rank": 2, "kind": Loadout.EQUIPMENT, "slot": Loadout.HELMET}, {"id": Loadout.HOT_STREAK, "rank": 1}, {"id": Loadout.ICED, "rank": 1}])
	board.run.roll_offer()
	if not await _capture("gear_offer_true_lid_ii.png"):
		return false
	board.run.skip_offer()
	board.run.helmet_id = ""
	board.run.helmet_rank = 0
	board.run.gloves_id = ""
	board.run.gloves_rank = 0
	board.run.cleats_id = Loadout.CANNON
	for rank in [12, 13, 24]:
		board.run.cleats_rank = rank
		board._sync_debug_loadout()
		if not await _capture("gear_badge_%s.png" % Loadout.rank_label(rank).to_lower()):
			return false
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.run.give(Loadout.CANNON, 6)
	board._sync_debug_loadout()
	if not await _capture("gear_standard_cap_vi.png"):
		return false
	if not await _shoot_range(Kickers.WILLOW, Loadout.CANNON, 24, Loadout.DRIVE_LID, 24, "gear_willow_1004.png"):
		return false
	if not await _shoot_range(Kickers.COLE, Loadout.CANNON, 24, Loadout.DRIVE_LID, 24, "gear_cole_1024.png"):
		return false
	if not await _shoot_range(Kickers.COLE, Loadout.CANNON, 24, "", 0, "gear_cole_640.png"):
		return false
	if not await _shoot_range(Kickers.BIG_BRUCE, Loadout.CANNON, 12, "", 0, "gear_bruce_cannon_137.png"):
		return false
	if not await _shoot_range(Kickers.BIG_BRUCE, "", 0, Loadout.DRIVE_LID, 12, "gear_bruce_drive_113.png"):
		return false
	if not await _shoot_hook(false, "gear_hook_plain.png"):
		return false
	if not await _shoot_hook(true, "gear_hook_true_lid.png"):
		return false
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.load_current_kick()
	_swing_meter(80.0, 4.0)
	if not await _capture("gear_guide_plain_good.png"):
		return false
	board.load_current_kick()
	board.run.gloves_id = Loadout.GUIDE_GLOVES
	board.run.gloves_rank = 1
	board._sync_debug_loadout()
	_swing_meter(80.0, 4.0)
	if not await _capture("gear_guide_good.png"):
		return false
	if not await _shoot_patient(false, false, "gear_patient_off.png"):
		return false
	if not await _shoot_patient(true, false, "gear_patient_on.png"):
		return false
	if not await _shoot_patient(true, true, "gear_patient_big_game.png"):
		return false
	if not await _shoot_wind(10.0, 180.0, false, "gear_shelter_headwind_off.png"):
		return false
	if not await _shoot_wind(10.0, 180.0, true, "gear_shelter_headwind_on.png"):
		return false
	if not await _shoot_wind(10.0, 0.0, false, "gear_shelter_tailwind_off.png"):
		return false
	if not await _shoot_wind(10.0, 0.0, true, "gear_shelter_tailwind_on.png"):
		return false
	if not await _shoot_hush(false, "gear_hush_off.png"):
		return false
	if not await _shoot_hush(true, "gear_hush_on.png"):
		return false
	return true


func _shoot_range(kicker_id: String, cleats: String, cleat_rank: int, helmet: String, helmet_rank: int, file_name: String) -> bool:
	var slot := 0
	for i in Kickers.ALL.size():
		if str(Kickers.ALL[i]["id"]) == kicker_id:
			slot = i
	if kicker_id != Kickers.WALK_ON and kicker_id != Kickers.BIG_BRUCE:
		SaveData.unlocks[kicker_id] = true
	board.highlight = slot
	board.selecting = true
	board.confirm_kicker()
	board.run.cleats_id = cleats
	board.run.cleats_rank = cleat_rank
	board.run.helmet_id = helmet
	board.run.helmet_rank = helmet_rank
	board.run.wind_speed = 0
	board.run.wind_direction = 0.0
	board._sync_debug_loadout()
	print(file_name, " max ", board.logic.max_range_at_full_power())
	return await _capture(file_name)


func _shoot_hook(true_lid: bool, file_name: String) -> bool:
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.run.helmet_id = Loadout.TRUE_LID if true_lid else ""
	board.run.helmet_rank = 1 if true_lid else 0
	board.load_current_kick()
	board._sync_debug_loadout()
	_swing_meter(80.0, 8.0)
	if board.logic.phase == KickLogic.Phase.FLIGHT:
		board.logic.advance(board.logic.flight_duration * 0.72)
	print(file_name, " angle ", board.logic.final_angle_degrees)
	return await _capture(file_name)


func _shoot_patient(gloves: bool, big_game: bool, file_name: String) -> bool:
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.run.gloves_id = Loadout.PATIENT_GLOVES if gloves else ""
	board.run.gloves_rank = 1 if gloves else 0
	if big_game:
		board.force_weather(RunLogic.BIG_GAME)
	board.load_current_kick()
	board.logic.press_space()
	if board.logic.windup_left > 0.0:
		board.logic.advance(board.logic.windup_left)
	board.logic.advance(0.22)
	print(file_name, " power ", board.logic.power_true, " speed ", board.run.stats.power_speed)
	return await _capture(file_name)


func _shoot_wind(speed: float, direction: float, shelter: bool, file_name: String) -> bool:
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.run.helmet_id = Loadout.SHELTER_LID if shelter else ""
	board.run.helmet_rank = 1 if shelter else 0
	board.run.wind_speed = int(speed)
	board.run.wind_direction = direction
	board._sync_debug_loadout()
	print(file_name, " max ", board.logic.max_range_at_full_power())
	return await _capture(file_name)


func _shoot_hush(gloves: bool, file_name: String) -> bool:
	board.highlight = 1
	board.selecting = true
	board.confirm_kicker()
	board.run.gloves_id = Loadout.HUSH_GLOVES if gloves else ""
	board.run.gloves_rank = 1 if gloves else 0
	board.run.wind_speed = 1
	board.run.wind_direction = 180.0
	board._sync_debug_loadout()
	print(file_name, " max ", board.logic.max_range_at_full_power(), " drift ", board.logic.carry_plan(100.0, 0.0)["drift"])
	return await _capture(file_name)


func _capture_broadcast() -> bool:
	board.front.screen = FrontEnd.Screen.SELECT
	board.selecting = true
	board.highlight = 1
	board.confirm_kicker()
	board.logic.phase = KickLogic.Phase.AIMING
	if not await _capture("hud_walkon_kick1.png"):
		return false
	board._preview_step = 2
	board.logic.kick_distance = 200.0
	if not await _capture("hud_walkon_200.png"):
		return false
	board._preview_step = 0
	board.logic.kick_distance = board.run.distance_yards()
	board.run.streak = 4
	board.run.attempts = 2
	if not await _capture("hud_score_mult.png"):
		return false
	board.run.streak = 0
	board.run.attempts = board.run.attempt_cap
	var before: float = board.logic.max_range_at_full_power()
	board.run.give(Loadout.CANNON, 1)
	board.run.prepare_kick_stats()
	board.logic.stats = board.run.stats
	print("MAX before ", before, " after cannon ", board.logic.max_range_at_full_power())
	if not await _capture("hud_max_after_cannon.png"):
		return false
	board.logic.kick_distance = 75.0
	if not await _capture("hud_max_short.png"):
		return false
	board.logic.kick_distance = board.run.distance_yards()
	board.logic.aim_degrees = -4.2
	if not await _capture("hud_aim_left.png"):
		return false
	board.logic.aim_degrees = 0.0
	board.run.wind_speed = 12
	board.run.wind_direction = 90.0
	board.logic.wind_speed = 12
	board.logic.wind_direction = 90.0
	board.logic.stats.flag_reader = false
	if not await _capture("hud_wind_band.png"):
		return false
	board.logic.stats.flag_reader = true
	if not await _capture("hud_wind_visor.png"):
		return false
	board.logic.stats.flag_reader = false
	board.run.wind_speed = 0
	board.logic.wind_speed = 0
	board.run.kick_number = 5
	board.run.weather = RunLogic.ICED
	board.logic.kick_distance = board.run.distance_yards()
	if not await _capture("hud_boss.png"):
		return false
	board.highlight = 0
	board.selecting = true
	board.confirm_kicker()
	board.logic.phase = KickLogic.Phase.AIMING
	if not await _capture("hud_bruce.png"):
		return false
	var vex_was_open := SaveData.has_unlock(Kickers.VEX)
	SaveData.unlocks[Kickers.VEX] = true
	board.highlight = 4
	board.selecting = true
	board.confirm_kicker()
	board.logic.phase = KickLogic.Phase.AIMING
	if not await _capture("hud_vex.png"):
		return false
	board.run.run_mode = "endless"
	board.run.kick_number = 8
	board.logic.kick_distance = board.run.distance_yards()
	if not await _capture("hud_endless.png"):
		return false
	board.run.cash = 12
	board.run.cash_popup = "+$4"
	if not await _capture("hud_cash_popup.png"):
		return false
	board.run.cash_popup = ""
	board.run.run_mode = "standard"
	board.logic.phase = KickLogic.Phase.RESULT
	board.logic.result_text = "GOOD"
	board.logic.shanked = false
	board.logic.perfect = false
	board.logic.offset_yards = 2.4
	board.logic.power = 80.0
	board.logic.accuracy_error = 4.0
	board.result_age = 0.4
	if not await _capture("hud_stamp_over.png"):
		return false
	board.run.resolve_kick("GOOD", 2.4, false)
	board.run.roll_offer()
	if not await _capture("hud_stamp_offer.png"):
		return false
	if not vex_was_open:
		SaveData.unlocks[Kickers.VEX] = false
	return true


func _capture_stamps() -> bool:
	board.front.screen = FrontEnd.Screen.SELECT
	board.selecting = true
	board.highlight = 0
	board.confirm_kicker()
	board.logic.phase = KickLogic.Phase.POWER
	board.result_age = 0.0
	if not await _capture("stamp_hud_still_default.png"):
		return false
	board.logic.phase = KickLogic.Phase.RESULT
	_stamp("GOOD", false, false, false, 4.0, 90.0, 2.4)
	board.result_age = 0.0
	if not await _capture("stamp_good_slam.png"):
		return false
	board.result_age = 0.4
	if not await _capture("stamp_good_power.png"):
		return false
	_stamp("SHORT", false, false, false, 14.0, 40.0, 0.0)
	if not await _capture("stamp_short.png"):
		return false
	_stamp("WIDE LEFT", false, false, false, 14.0, 80.0, -8.0)
	if not await _capture("stamp_wide_left.png"):
		return false
	_stamp("WIDE RIGHT", false, false, false, 14.0, 80.0, 8.0)
	if not await _capture("stamp_wide_right.png"):
		return false
	_stamp("DOINK", false, false, false, 12.0, 80.0, 3.2)
	if not await _capture("stamp_doink.png"):
		return false
	board.logic.shanked = true
	board.logic.result_text = "SHORT"
	board.logic.perfect = false
	board.logic.power = 0.0
	board.logic.accuracy_error = 15.0
	if not await _capture("stamp_shank.png"):
		return false
	_stamp("GOOD", false, false, true, 4.0, 90.0, 0.0)
	if not await _capture("stamp_down_the_middle.png"):
		return false
	_stamp("GOOD", false, false, true, 0.2, 90.0, 0.0)
	board.logic.perfect = true
	if not await _capture("stamp_middle_perfect.png"):
		return false
	_stamp("GOOD", false, false, false, 0.2, 90.0, 4.0)
	board.logic.perfect = true
	if not await _capture("stamp_perfect.png"):
		return false
	_stamp("GOOD", false, true, false, 0.4, 80.0, 3.1)
	board.logic.perfect = false
	if not await _capture("stamp_insured.png"):
		return false
	_stamp("SHORT", false, false, false, 14.0, 55.0, 0.0)
	board.logic.kick_distance = 35.0
	if not await _capture("stamp_short_35.png"):
		return false
	board.logic.kick_distance = 1000.0
	board._preview_step = 4
	if not await _capture("stamp_short_1000.png"):
		return false
	board._preview_step = 0
	board.logic.kick_distance = 35.0
	_stamp("GOOD", false, false, false, 4.0, 70.0, 2.4)
	board.result_age = 0.9
	board.run.resolve_kick("GOOD", 0.0, false)
	board.run.roll_offer()
	if not await _capture("stamp_then_offer.png"):
		return false
	board.run.awaiting_offer = false
	board.front.screen = FrontEnd.Screen.MAIN
	if not await _capture("stamp_menu_unchanged.png"):
		return false
	return true


func _stamp(result: String, shanked: bool, insured: bool, middle: bool, error: float, power: float, offset: float) -> void:
	board.logic.phase = KickLogic.Phase.RESULT
	board.logic.shanked = shanked
	board.logic.result_text = result
	board.logic.insured = insured
	board.logic.bank_shot = false
	board.logic.perfect = false
	board.logic.accuracy_error = error
	board.logic.power = power
	board.logic.offset_yards = 0.0 if middle else offset
	board.logic.stats = board.run.stats
	board.result_age = 0.4
	board.run.awaiting_offer = false
	board.run.phase = RunLogic.Phase.PLAYING


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
