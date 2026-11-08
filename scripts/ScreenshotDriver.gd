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
	while board.run.kick_number < 5:
		board.run.resolve_kick("GOOD", 2.0, false)
		board.run.leave_shop()
		board.advance_run()
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
	if not board.logic.stats.laser_full or not board.logic.stats.flag_reader:
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
	if power_value > 0.0:
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
	board.logic.advance(1.0)
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
	while board.run.kick_number < 5:
		board.run.resolve_kick("GOOD", 2.0, false)
		board.run.leave_shop()
		board.advance_run()
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
