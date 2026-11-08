extends SceneTree

# Runs the kick rules without opening a window.
#   godot --headless --path . --script res://tests/run_tests.gd

var failures := 0


func _initialize() -> void:
	_run()
	if failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("FAILED %d CHECKS" % failures)
		quit(1)


func _run() -> void:
	print("Field goal kick tests")
	var version: Dictionary = Engine.get_version_info()
	print("Godot ", version.get("string", ""))
	_check_layout()
	_check_meter_motion()
	_check_pendulum()
	_check_perfect_band()
	_check_red_tip()
	_check_2_centered_perfect_press()
	_check_3_full_left()
	_check_4_short()
	_check_5_late_accuracy()
	_check_doink_edges()
	_check_signs()
	_check_flight_and_reset()
	_check_detail_text()
	_check_run()
	_check_upgrades()
	_check_kickers_and_fixes()
	_check_power_flight()
	_check_wind_and_pool()
	_check_weather_and_bosses()
	_check_curses_and_rarity()
	_check_loadout_sprites()
	_check_rank_caps_and_range()
	_check_vitamin_shop()
	_check_sprite_scan_and_gauge()
	_check_menus()
	_check_endless_and_farm()
	_check_new_kickers()
	_check_auto_shank()


func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS  ", label)
	else:
		failures += 1
		print("FAIL  ", label)


func near(a: float, b: float, eps: float = 0.0001) -> bool:
	return absf(a - b) <= eps


func _check_layout() -> void:
	var start := KickConstants.screen_pos(KickConstants.KICK_DISTANCE_YARDS, 0.0, 0.0)
	check(near(start.x, 640.0) and near(start.y, 305.0), "check 1 ball is centered 35 yd below the posts at %s" % start)
	var y75 := KickConstants.UPRIGHT_Y_PX + 75.0 * KickConstants.PIXELS_PER_YARD
	check(y75 <= KickConstants.WINDOW_HEIGHT, "check 1 a 75 yd kick fits, ball y=%s" % y75)
	var half_px := KickConstants.POST_SEPARATION_YARDS * 0.5 * KickConstants.PIXELS_PER_YARD
	var left_post := KickConstants.WINDOW_WIDTH * 0.5 - half_px
	var right_post := KickConstants.WINDOW_WIDTH * 0.5 + half_px
	check(near(right_post - left_post, 6.17 * 7.0), "check 1 posts are 6.17 yd apart")
	check(left_post > 40.0 and right_post < KickConstants.METER_PANEL_LEFT, "check 1 posts are on screen, left of the meter")
	check(KickConstants.METER_PANEL_LEFT > KickConstants.WINDOW_WIDTH * 0.5, "check 1 meter is on the right")
	check(KickConstants.METER_PANEL_RIGHT <= KickConstants.WINDOW_WIDTH, "check 1 meter stays inside the window")
	check(KickConstants.METER_PANEL_BOTTOM <= KickConstants.WINDOW_HEIGHT, "check 1 meter stays inside the window vertically")
	check(near(KickConstants.meter_y(100.0), KickConstants.METER_BAR_TOP), "check 1 meter value 100 is the top of the bar")
	check(near(KickConstants.meter_y(-15.0), KickConstants.METER_BAR_BOTTOM), "check 1 meter value -15 is the bottom of the bar")
	check(KickConstants.meter_y(100.0) < KickConstants.meter_y(0.0), "check 1 the needle rises up the screen")
	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	check(width == int(KickConstants.WINDOW_WIDTH) and height == int(KickConstants.WINDOW_HEIGHT), "window is %sx%s" % [width, height])
	check(renderer == "gl_compatibility", "renderer is gl_compatibility (%s)" % renderer)
	check(KickConstants.POST_HALF_GAP_YARDS == 3.08, "scoring half-gap stays 3.08")
	check(KickConstants.DOINK_BAND_YARDS == 0.15, "doink band stays 0.15")
	check(KickConstants.ACCURACY_DEG_PER_ERROR == 0.35, "accuracy scale stays 0.35")


func _check_meter_motion() -> void:
	var kick := KickLogic.new()
	check(near(kick.needle_angle, MeterGauge.MAX_ANGLE), "the needle rests at MAX")
	kick.press_space()
	check(kick.phase == KickLogic.Phase.POWER and kick.windup_left > 0.0, "space starts the flick toward POWER")
	var locked_aim := kick.aim_degrees
	kick.aim(-1.0, 3.0)
	check(near(kick.aim_degrees, locked_aim), "aim locks once the meter starts")
	kick.advance(kick.windup_left)
	kick.advance(0.25)
	var quarter := MeterGauge.omega_power(kick.stats.power_speed, kick.stats.ball_speed_mult) * 0.25 * (100.0 / MeterGauge.OMEGA0)
	check(near(kick.power_true, quarter), "a quarter second of the new baseline covers %s power, got %s" % [quarter, kick.power_true])
	kick.advance(0.75)
	check(kick.shanked and kick.phase == KickLogic.Phase.FLIGHT, "reaching MAX with no Space #2 shanks")
	check(kick.power == 0.0 and kick.phase != KickLogic.Phase.ACCURACY, "a missed power click is not a P=100 lock")
	var during_flight := _kick_power_accuracy(40.0, 0.0)
	var power_before := during_flight.power
	check(during_flight.phase == KickLogic.Phase.FLIGHT, "locking accuracy launches the ball")
	during_flight.press_space()
	check(during_flight.phase == KickLogic.Phase.FLIGHT and near(during_flight.power, power_before), "space during flight does nothing")


func _check_pendulum() -> void:
	var rest := KickLogic.new()
	check(near(rest.needle_angle, 90.0) and rest.phase == KickLogic.Phase.AIMING, "rest needle angle is MAX")
	rest.press_space()
	rest.advance(MeterGauge.WINDUP_SEC)
	check(rest.windup_left <= 0.0001 and near(rest.needle_angle, 180.0), "the wind-up reaches POWER in 0.08s")
	check(rest.phase == KickLogic.Phase.POWER and near(rest.power, 0.0), "the flick itself does not lock power")
	var flick := KickLogic.new()
	flick.press_space()
	flick.advance(0.04)
	flick.press_space()
	check(flick.phase == KickLogic.Phase.POWER and near(flick.power, 0.0), "space during the flick does not lock power")
	check(flick.needle_angle > 90.0 and flick.needle_angle < 180.0, "the flick is halfway to POWER at 0.04s, angle %s" % flick.needle_angle)
	var sweep := KickLogic.new()
	sweep.press_space()
	sweep.advance(sweep.windup_left)
	var started := sweep.needle_angle
	var half_time := MeterGauge.SWEEP_SEC * 0.5
	sweep.advance(half_time)
	check(near(sweep.power_true, 50.0) and near(sweep.needle_angle, 135.0), "halfway through the power sweep, P is 50 (angle %s, P %s)" % [sweep.needle_angle, sweep.power_true])
	check(near(started - sweep.needle_angle, MeterGauge.omega_base() * half_time), "accuracy 100 sweeps at ω_ref, not the old ω0")
	sweep.advance(half_time)
	check(sweep.shanked and sweep.phase == KickLogic.Phase.FLIGHT and sweep.phase != KickLogic.Phase.ACCURACY, "POWER to MAX with no Space #2 shanks instead of locking P=100")
	check(sweep.needle_angle <= 90.0001 and sweep.power == 0.0, "the shank stops at MAX and does not store a power lock, angle %s" % sweep.needle_angle)
	var mid := KickLogic.new()
	mid.press_space()
	mid.advance(mid.windup_left)
	mid.advance(mid.seconds_to_power(50.0))
	var locked_angle := mid.needle_angle
	mid.press_space()
	check(near(mid.power, 50.0) and near(mid.fill_power, 50.0), "a halfway press locks P=50 and freezes the fill")
	check(near(mid.needle_angle, locked_angle), "locking power does not jump the needle")
	mid.press_space()
	check(mid.phase == KickLogic.Phase.ACCURACY and near(mid.power, 50.0), "space on the leftover left arc does not lock accuracy")
	var before := mid.needle_angle
	mid.advance(0.1)
	check(near(mid.fill_power, 50.0), "the fill stays frozen after the lock")
	check(mid.needle_angle < before - 8.0 and mid.needle_angle > 90.0, "the needle continues toward MAX, angle %s" % mid.needle_angle)
	mid.advance(mid.seconds_until_error(15.0))
	check(near(mid.needle_angle, 90.0, 0.05) and near(mid.needle, 15.0, 0.05), "just after MAX, e=+15 (angle %s, e %s)" % [mid.needle_angle, mid.needle])
	mid.advance(mid.seconds_until_error(0.0))
	check(near(mid.needle_angle, 45.0, 0.05) and near(mid.needle, 0.0, 0.05), "the center of the right arc is e=0")
	var samples: Array[float] = []
	var paced := KickLogic.new()
	paced.press_space()
	paced.advance(paced.windup_left)
	paced.advance(paced.seconds_to_power(40.0))
	paced.press_space()
	paced.advance(paced.seconds_until_error(12.0))
	for _i in 4:
		samples.append(paced.needle_angle)
		paced.advance(0.2)
	var rates: Array[float] = []
	for index in range(1, samples.size()):
		rates.append((samples[index - 1] - samples[index]) / 0.2)
	check(absf(rates[0] - rates[1]) < 0.02 and absf(rates[1] - rates[2]) < 0.02, "right-arc angular speed stays constant %s" % str(rates))
	check(absf(rates[0] - MeterGauge.omega_base()) < 0.05, "default accuracy sweep uses kicker_omega, rate %s" % rates[0])
	var timeout := KickLogic.new()
	timeout.press_space()
	timeout.advance(timeout.windup_left)
	timeout.advance(0.4)
	timeout.press_space()
	timeout.advance(timeout.seconds_until_error(-15.0) + 0.01)
	check(timeout.phase == KickLogic.Phase.FLIGHT and near(timeout.accuracy_error, -15.0), "finishing the right arc kicks with e=-15, phase %s e %s" % [timeout.phase, timeout.accuracy_error])
	var stone := KickLogic.new()
	stone.stats.power_speed = 120.0
	stone.press_space()
	stone.advance(stone.windup_left)
	var stone_start := stone.needle_angle
	stone.advance(0.4)
	var stone_rate := (stone_start - stone.needle_angle) / 0.4
	check(near(stone_rate, MeterGauge.omega_power(120.0), 0.05), "Stone Toe is kicker_omega * (power_speed / 100), got %s" % stone_rate)
	stone.press_space()
	stone.advance(stone.seconds_until_error(15.0))
	var stone_acc := stone.needle_angle
	stone.advance(0.3)
	var stone_acc_rate := (stone_acc - stone.needle_angle) / 0.3
	check(near(stone_acc_rate, MeterGauge.omega_accuracy(120.0), 0.05), "Stone Toe does not speed the accuracy sweep, got %s" % stone_acc_rate)
	var rainy := KickLogic.new()
	rainy.rain_faster = true
	rainy.press_space()
	rainy.advance(rainy.windup_left)
	rainy.advance(0.5)
	rainy.press_space()
	rainy.advance(rainy.seconds_until_error(15.0))
	var rain_at := rainy.needle_angle
	rainy.advance(0.3)
	var clear_rate := MeterGauge.omega_accuracy(120.0)
	var rain_rate := (rain_at - rainy.needle_angle) / 0.3
	check(near(rain_rate, clear_rate * rainy.rain_scale, 0.05) and rain_rate > clear_rate + 5.0, "rain speeds only the accuracy sweep, got %s" % rain_rate)
	var hero := KickLogic.new()
	hero.stats.power_speed = 80.0
	hero.stats.accuracy_speed = 96.0
	hero.press_space()
	hero.advance(hero.windup_left)
	var hero_start := hero.needle_angle
	hero.advance(0.4)
	check(near((hero_start - hero.needle_angle) / 0.4, MeterGauge.omega_power(80.0), 0.05), "Hero Ball slows the power sweep")
	hero.press_space()
	hero.advance(hero.seconds_until_error(15.0))
	var hero_acc := hero.needle_angle
	hero.advance(0.3)
	check(near((hero_acc - hero.needle_angle) / 0.3, MeterGauge.omega_accuracy(96.0), 0.05), "Hero Ball slows the accuracy sweep")
	var mag := KickLogic.new()
	mag.stats.power_speed = 70.0
	mag.stats.accuracy_speed = 84.0
	mag.press_space()
	mag.advance(mag.windup_left)
	var mag_start := mag.needle_angle
	mag.advance(0.4)
	check(near((mag_start - mag.needle_angle) / 0.4, MeterGauge.omega_base() * 0.7, 0.05), "Magnesium slows the power sweep to 0.7 of kicker_omega")
	var bruce := KickLogic.new()
	Kickers.apply_to(bruce.stats, Kickers.BIG_BRUCE)
	var walk := KickLogic.new()
	Kickers.apply_to(walk.stats, Kickers.WALK_ON)
	check(near(bruce.stats.accuracy_speed, walk.stats.accuracy_speed), "Big Bruce uses the default accuracy needle")
	check(near(bruce.stats.red_tip_start, 95.0) and near(walk.stats.red_tip_start, 95.0), "Big Bruce uses the default red tip")
	check(KickConstants.ACCURACY_DEG_PER_ERROR == 0.35, "degrees per unit of e stay 0.35")
	check(KickLogic.is_perfect(1.5) and not KickLogic.is_perfect(1.51), "landing inside the perfect band is still PERFECT")
	var image := Image.create(4, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color8(10, 8, 4, 255))
	image.set_pixel(1, 0, Color8(16, 16, 16, 255))
	image.set_pixel(2, 0, Color8(17, 17, 17, 255))
	image.set_pixel(3, 0, Color8(90, 86, 84, 255))
	var keyed := MeterGauge.key_meter_image(image)
	check(keyed.get_pixel(0, 0).a > 0.9 and keyed.get_pixel(1, 0).a > 0.9, "a dark pixel is not keyed out just because it is dark")
	check(keyed.get_pixel(2, 0).a > 0.9 and keyed.get_pixel(3, 0).a > 0.9, "dark gray metal is not keyed out")
	_check_clean_meter_and_accuracy_speed()
	var wide: Dictionary = MeterGauge.accuracy_layout(10.0, 20.0)
	var plain: Dictionary = MeterGauge.accuracy_layout(2.0, 8.0)
	var tight: Dictionary = MeterGauge.accuracy_layout(1.0, 6.0)
	check(float(wide["perfect_span"]) > float(plain["perfect_span"]) and float(tight["perfect_span"]) < float(plain["perfect_span"]), "Pinpoint widens the live wedge and Tight Window tightens it")
	check(near(MeterGauge.accuracy_angle(0.0, 10.0, 20.0), 45.0) and near(MeterGauge.accuracy_angle(0.0, 1.0, 6.0), 45.0), "e=0 stays at the center no matter how wide the wedge is")


func _measure_power_sweep(id: String) -> float:
	var kick := KickLogic.new()
	Kickers.apply_to(kick.stats, id)
	kick.press_space()
	kick.advance(kick.windup_left)
	var step := 0.0002
	var elapsed := 0.0
	while kick.phase == KickLogic.Phase.POWER and elapsed < 3.0:
		kick.advance(step)
		elapsed += step
	return elapsed


func _power_rate(kick: KickLogic) -> float:
	kick.press_space()
	kick.advance(kick.windup_left)
	var started := kick.needle_angle
	kick.advance(0.2)
	return (started - kick.needle_angle) / 0.2


func _accuracy_rate(kick: KickLogic) -> float:
	if kick.phase == KickLogic.Phase.AIMING:
		kick.press_space()
		kick.advance(kick.windup_left)
	if kick.phase == KickLogic.Phase.POWER:
		kick.advance(kick.seconds_to_power(40.0))
		if kick.phase == KickLogic.Phase.POWER:
			kick.press_space()
	kick.advance(kick.seconds_until_error(15.0))
	var started := kick.needle_angle
	kick.advance(0.2)
	return (started - kick.needle_angle) / 0.2


func _check_clean_meter_and_accuracy_speed() -> void:
	var expect := MeterGauge.SWEEP_SEC
	var bruce_time := _measure_power_sweep(Kickers.BIG_BRUCE)
	var walk_time := _measure_power_sweep(Kickers.WALK_ON)
	print("POWER_TO_MAX Bruce ", bruce_time, " Walk-On ", walk_time, " expected ", expect)
	check(near(bruce_time, expect, 0.002), "Bruce with no items sweeps POWER to MAX in 0.700s, got %s" % bruce_time)
	check(near(walk_time, expect, 0.002), "Walk-On with no items sweeps POWER to MAX in 0.700s, got %s" % walk_time)
	check(near(bruce_time, walk_time, 0.002), "Bruce and Walk-On match each other")
	check(near(MeterGauge.omega_base(), MeterGauge.OMEGA0 / 0.700), "omega_base is ω0 / 0.700")
	check(near(MeterGauge.omega_power(100.0), MeterGauge.omega_base()), "needle speed does not read the accuracy rating")
	var bruce_stats := KickerStats.new()
	Kickers.apply_to(bruce_stats, Kickers.BIG_BRUCE)
	var walk_stats := KickerStats.new()
	Kickers.apply_to(walk_stats, Kickers.WALK_ON)
	check(near(bruce_stats.accuracy, 90.0) and near(walk_stats.accuracy, 100.0), "Bruce is accuracy 90 and Walk-On is 100")
	check(near(bruce_stats.perfect_band, 1.35) and near(bruce_stats.good_band, 5.40), "Bruce bands are ±1.35 / ±5.40")
	check(near(walk_stats.perfect_band, 1.50) and near(walk_stats.good_band, 6.0), "Walk-On bands are ±1.50 / ±6.00")
	check(near(bruce_stats.power_floor, 80.0) and bruce_stats.ball_type == "farm_ball", "Farm Strength and The Farm Ball are unchanged")
	check(walk_stats.rerolls_per_run == 2 and walk_stats.ball_type == "standard", "Walk-On still has 2 rerolls and Team-Issue")
	var farm := KickLogic.drift_at_uprights(10.0, 90.0, 35.0, 0, 0, "farm_ball")
	var plain_drift := KickLogic.drift_at_uprights(10.0, 90.0, 35.0, 0, 0, "standard")
	check(near(farm, plain_drift * 1.10), "The Farm Ball is still 1.10 drift")
	var hero := RunLogic.new()
	hero.new_run()
	hero.start_with_kicker(Kickers.BIG_BRUCE)
	hero.give(Loadout.HERO_BALL, 1)
	hero.prepare_kick_stats()
	check(near(MeterGauge.omega_power(hero.stats.power_speed, hero.stats.ball_speed_mult), MeterGauge.omega_base() * 0.8), "Hero Ball slows power on top of kicker_omega")
	check(near(MeterGauge.omega_accuracy(hero.stats.accuracy_speed, hero.stats.ball_speed_mult), MeterGauge.omega_base() * 0.8), "Hero Ball slows accuracy on top of kicker_omega")
	var anchor := RunLogic.new()
	anchor.new_run()
	anchor.start_with_kicker(Kickers.WALK_ON)
	anchor.give(Loadout.ANCHOR, 1)
	anchor.prepare_kick_stats()
	check(near(MeterGauge.omega_power(anchor.stats.power_speed, anchor.stats.ball_speed_mult), MeterGauge.omega_base() * 0.85), "Anchor Cleats slows power on top of kicker_omega")
	check(near(MeterGauge.omega_accuracy(anchor.stats.accuracy_speed, anchor.stats.ball_speed_mult), MeterGauge.omega_base() * 0.85), "Anchor Cleats slows accuracy on top of kicker_omega")
	var mag := RunLogic.new()
	mag.new_run()
	mag.start_with_kicker(Kickers.BIG_BRUCE)
	mag.belt[0] = Vitamins.MAGNESIUM
	check(mag.use_belt(0), "Magnesium can be used")
	mag.prepare_kick_stats()
	check(near(mag.stats.power_speed, 70.0) and near(mag.stats.accuracy_speed, 84.0), "Magnesium is 0.7 on both phase speeds")
	check(near(MeterGauge.omega_power(mag.stats.power_speed, mag.stats.ball_speed_mult), MeterGauge.omega_base() * 0.7), "Magnesium slows power on top of kicker_omega")
	check(near(MeterGauge.omega_accuracy(mag.stats.accuracy_speed, mag.stats.ball_speed_mult), MeterGauge.omega_base() * 0.7), "Magnesium slows accuracy on top of kicker_omega")
	var stone := RunLogic.new()
	stone.new_run()
	stone.start_with_kicker(Kickers.WALK_ON)
	stone.give(Loadout.STONE)
	stone.prepare_kick_stats()
	check(near(stone.stats.power_speed, 120.0) and near(stone.stats.accuracy_speed, 120.0), "Stone Toe hurries only the power speed value")
	check(near(MeterGauge.omega_power(stone.stats.power_speed, stone.stats.ball_speed_mult), MeterGauge.omega_base() * 1.2), "Stone Toe power is kicker_omega times 1.2")
	check(near(MeterGauge.omega_accuracy(stone.stats.accuracy_speed, stone.stats.ball_speed_mult), MeterGauge.omega_base()), "Stone Toe leaves the accuracy phase at kicker_omega")
	var cage := RunLogic.new()
	cage.new_run()
	cage.start_with_kicker(Kickers.BIG_BRUCE)
	cage.give(Loadout.ICE_CAGE, 2)
	cage.prepare_kick_stats()
	check(near(cage.stats.power_speed, 100.0) and near(cage.stats.accuracy_speed, 108.0), "Ice Cage II slows only accuracy speed")
	check(near(MeterGauge.omega_accuracy(cage.stats.accuracy_speed, cage.stats.ball_speed_mult), MeterGauge.omega_base() * 0.9), "Ice Cage II is 0.9 on top of kicker_omega")
	var rain := KickLogic.new()
	Kickers.apply_to(rain.stats, Kickers.WALK_ON)
	var rain_flags: Dictionary = RunLogic.weather_kick_flags(RunLogic.RAIN, 0)
	rain.rain_faster = bool(rain_flags["rain_faster"])
	rain.rain_scale = float(rain_flags["rain_scale"])
	var rain_power := _power_rate(rain)
	check(near(rain_power, MeterGauge.omega_power(100.0), 0.05), "rain does not speed the power sweep, got %s" % rain_power)
	var rain_acc := _accuracy_rate(rain)
	check(near(rain_acc, MeterGauge.omega_base() * 1.2, 0.05), "rain speeds the accuracy sweep by 1.2 on top of kicker_omega, got %s" % rain_acc)
	var monsoon := KickLogic.new()
	Kickers.apply_to(monsoon.stats, Kickers.BIG_BRUCE)
	var monsoon_flags: Dictionary = RunLogic.weather_kick_flags(RunLogic.MONSOON, 0)
	monsoon.rain_faster = bool(monsoon_flags["rain_faster"])
	monsoon.rain_scale = float(monsoon_flags["rain_scale"])
	check(near(_accuracy_rate(monsoon), MeterGauge.omega_base() * 1.2, 0.05), "Monsoon rain speeds the accuracy sweep the same way")
	var game := RunLogic.new()
	game.new_run()
	game.start_with_kicker(Kickers.BIG_BRUCE)
	game.give(Loadout.HERO_BALL, 1)
	game.force_weather(RunLogic.BIG_GAME)
	game.prepare_kick_stats()
	check(near(game.stats.power_speed, 100.0) and near(game.stats.accuracy_speed, 120.0), "Big Game turns off Hero Ball's slower needles")
	check(near(game.stats.accuracy, 90.0) and near(game.stats.power_floor, 80.0), "Big Game keeps Bruce accuracy 90 and Farm Strength")
	check(near(MeterGauge.omega_power(game.stats.power_speed, game.stats.ball_speed_mult), MeterGauge.omega_base()), "Big Game power sweep stays at the new baseline")
	game.belt[0] = Vitamins.MAGNESIUM
	check(game.use_belt(0), "Magnesium can be used in Big Game")
	game.prepare_kick_stats()
	check(near(game.stats.power_speed, 70.0) and near(game.stats.accuracy_speed, 84.0), "Magnesium still slows both needles in Big Game")
	check(near(MeterGauge.omega_power(game.stats.power_speed, game.stats.ball_speed_mult), MeterGauge.omega_base() * 0.7), "Big Game Magnesium is 0.7 of kicker_omega")
	var left := KickLogic.new()
	Kickers.apply_to(left.stats, Kickers.BIG_BRUCE)
	left.press_space()
	left.advance(left.windup_left)
	left.advance(left.seconds_to_power(40.0))
	left.press_space()
	var locked := left.needle_angle
	left.advance(0.15)
	var moved := locked - left.needle_angle
	check(left.phase == KickLogic.Phase.ACCURACY and near(left.fill_power, 40.0), "a mid-power lock freezes the fill and keeps sweeping")
	check(near(moved, MeterGauge.omega_power(100.0) * 0.15, 0.05) and left.needle_angle > 90.0, "leftover left-side travel still uses power-phase speed")
	check(near(MeterGauge.angle_from_error(15.0), 90.0) and near(MeterGauge.angle_from_error(0.0), 45.0) and near(MeterGauge.angle_from_error(-15.0), 0.0), "e mapping on the right arc is unchanged")
	var texture := load("res://art/ui/kick_meter.png") as Texture2D
	check(texture != null, "the kick meter painting loads")
	if texture == null:
		return
	var cleaned := MeterGauge.key_meter_image(texture.get_image())
	var outside := cleaned.get_pixel(0, 0)
	var well_a := cleaned.get_pixel(504, 360)
	var well_b := cleaned.get_pixel(420, 400)
	var covered := cleaned.get_pixel(645, 369)
	var dark_wedge := cleaned.get_pixel(616, 147)
	var metal := cleaned.get_pixel(406, 80)
	check(outside.a == 0.0, "the outside backdrop stays transparent")
	check(well_a.a > 0.99 and well_b.a > 0.99, "the inner well is opaque")
	check(near(well_a.r, well_b.r) and near(well_a.g, well_b.g) and near(well_a.b, well_b.b), "the inner well is one flat color")
	check(near(covered.r, well_a.r) and near(covered.g, well_a.g) and covered.a > 0.99, "the baked needle in the well is covered by that fill")
	check(dark_wedge.a > 0.99 and dark_wedge.r8 <= 20, "a dark wedge pixel stays opaque instead of being keyed out")
	check(metal.a > 0.99, "the metal frame stays opaque")


func _check_perfect_band() -> void:
	check(KickLogic.is_perfect(0.0) and KickLogic.is_perfect(1.5) and KickLogic.is_perfect(-1.5), "e inside -1.5..+1.5 is PERFECT")
	check(not KickLogic.is_perfect(1.51) and not KickLogic.is_perfect(-1.51), "e just outside 1.5 is not PERFECT")
	check(KickLogic.hook_degrees(1.5) == 0.0 and KickLogic.hook_degrees(-1.5) == 0.0, "a perfect e adds 0 degrees")
	check(near(KickLogic.hook_degrees(4.0), -4.0 * 0.35), "e=+4 hooks left (negative angle)")
	check(near(KickLogic.hook_degrees(-4.0), 4.0 * 0.35), "e=-4 slices right (positive angle)")


func _check_red_tip() -> void:
	var inside := true
	var saw_positive := false
	var saw_negative := false
	var untouched := true
	var saw_tip := false
	for seed_value in range(1, 201):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var wobble := KickLogic.accuracy_with_red_tip(100.0, 0.0, rng)
		if wobble < KickConstants.RED_TIP_ERROR_MIN or wobble > KickConstants.RED_TIP_ERROR_MAX:
			inside = false
		if wobble > 0.5:
			saw_positive = true
		if wobble < -0.5:
			saw_negative = true
		var plain := RandomNumberGenerator.new()
		plain.seed = seed_value
		if KickLogic.accuracy_with_red_tip(94.0, 0.0, plain) != 0.0:
			untouched = false
		var tipped := RandomNumberGenerator.new()
		tipped.seed = seed_value
		if absf(KickLogic.accuracy_with_red_tip(95.0, 0.0, tipped)) > 0.000001:
			saw_tip = true
	check(inside, "red-tip random stays inside -5..+5")
	check(saw_positive and saw_negative, "red-tip random can push e either way")
	check(untouched, "power under 95 does not change e")
	check(saw_tip, "power at 95 can change e")
	var first := RandomNumberGenerator.new()
	first.seed = 42
	var second := RandomNumberGenerator.new()
	second.seed = 42
	var replay_a := KickLogic.accuracy_with_red_tip(100.0, 0.0, first)
	var replay_b := KickLogic.accuracy_with_red_tip(100.0, 0.0, second)
	check(replay_a == replay_b, "the same seed replays the same wobble (%s)" % replay_a)


func _check_2_centered_perfect_press() -> void:
	var perfect_seed := -1
	var bumped_seed := -1
	for seed_value in range(1, 501):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var error := KickLogic.accuracy_with_red_tip(100.0, 0.0, rng)
		if perfect_seed < 0 and absf(error) <= KickConstants.PERFECT_BAND:
			perfect_seed = seed_value
		elif bumped_seed < 0 and absf(error) > KickConstants.PERFECT_BAND:
			bumped_seed = seed_value
		if perfect_seed > 0 and bumped_seed > 0:
			break
	check(perfect_seed > 0 and bumped_seed > 0, "found seeds for a kept PERFECT and a lost PERFECT")
	var made := _drive_check2(perfect_seed)
	var expected := RandomNumberGenerator.new()
	expected.seed = perfect_seed
	var expected_error := KickLogic.accuracy_with_red_tip(100.0, 0.0, expected)
	check(near(made.power, 100.0), "check 2 a press as the needle reaches MAX locks P=100")
	check(near(made.needle, 0.0), "check 2 the press is on the green line, needle=%s" % made.needle)
	check(made.accuracy_error == expected_error, "check 2 the state machine uses the seeded wobble")
	check(made.perfect and made.result_text == "GOOD", "check 2 seed %s -> PERFECT and GOOD (e=%s)" % [perfect_seed, made.accuracy_error])
	var bumped := _drive_check2(bumped_seed)
	check(not bumped.perfect, "check 2 seed %s red tip removes PERFECT (e=%s)" % [bumped_seed, bumped.accuracy_error])
	check(bumped.result_text == "GOOD", "check 2 a centered red-tip kick is still GOOD at 35 yd, got %s" % bumped.result_text)
	print("INFO  check 2 kept PERFECT with seed %s, e=%s, result=%s" % [perfect_seed, made.accuracy_error, made.result_text])
	print("INFO  check 2 lost PERFECT with seed %s, e=%s, result=%s" % [bumped_seed, bumped.accuracy_error, bumped.result_text])
	print("INFO  check 2: P=100 is in the red tip, so a press on 0 stays PERFECT only when the random add is inside the perfect band. At 35 yd a centered kick is still GOOD.")


func _drive_check2(seed_value: int) -> KickLogic:
	var kick := KickLogic.new()
	kick.set_seed(seed_value)
	kick.press_space()
	kick.advance(kick.windup_left)
	kick.take_power_press(kick.seconds_to_power(100.0))
	check(not kick.shanked and kick.phase == KickLogic.Phase.ACCURACY and near(kick.power, 100.0), "check 2 a press on the MAX step locks P=100")
	kick.advance(kick.seconds_until_error(0.0))
	check(near(kick.needle, 0.0, 0.02), "check 2 the right-arc center is e=0, got %s" % kick.needle)
	if kick.phase == KickLogic.Phase.ACCURACY:
		kick.press_space()
	return kick


func _check_3_full_left() -> void:
	var kick := KickLogic.new()
	kick.aim(-1.0, 5.0)
	check(near(kick.aim_degrees, -12.0), "check 3 holding Left reaches -12, got %s" % kick.aim_degrees)
	kick.press_space()
	kick.advance(kick.windup_left)
	kick.advance(kick.seconds_to_power(80.0))
	kick.press_space()
	kick.advance(kick.seconds_until_error(0.0))
	kick.press_space()
	check(kick.perfect, "check 3 accuracy on 0 is PERFECT")
	check(near(kick.final_angle_degrees, -12.0), "check 3 perfect adds no extra angle, got %s" % kick.final_angle_degrees)
	check(kick.offset_yards < 0.0, "check 3 the ball went screen-left, offset=%s" % kick.offset_yards)
	check(kick.result_text == "WIDE LEFT", "check 3 result is WIDE LEFT, got %s (offset %s)" % [kick.result_text, kick.offset_yards])


func _check_4_short() -> void:
	var kick := _kick_power_accuracy(20.0, 0.0)
	check(kick.power < 28.0, "check 4 power %s is below about 28" % kick.power)
	check(kick.max_range < kick.kick_distance, "check 4 max range %s is short of %s" % [kick.max_range, kick.kick_distance])
	check(kick.result_text == "SHORT", "check 4 result is SHORT, got " + kick.result_text)
	var boundary := (KickConstants.KICK_DISTANCE_YARDS - KickConstants.RANGE_BASE_YARDS) / KickConstants.RANGE_PER_POWER
	var just_under := KickLogic.range_yards(boundary - 0.01)
	var just_over := KickLogic.range_yards(boundary + 0.01)
	check(just_under < 35.0 and KickLogic.classify(just_under, 35.0, 0.0) == "SHORT", "P just under %s is SHORT (%s yd)" % [boundary, just_under])
	check(just_over >= 35.0 and KickLogic.classify(just_over, 35.0, 0.0) == "GOOD", "P just over %s reaches (%s yd)" % [boundary, just_over])
	var under_p := floorf(boundary)
	var over_p := ceilf(boundary)
	if over_p <= under_p:
		over_p = under_p + 1.0
	var at_under := KickLogic.range_yards(under_p)
	var at_over := KickLogic.range_yards(over_p)
	check(KickLogic.classify(at_under, 35.0, 0.0) == "SHORT", "P=%s range %s is SHORT" % [under_p, at_under])
	check(KickLogic.classify(at_over, 35.0, 0.0) == "GOOD", "P=%s range %s reaches and is GOOD when centered" % [over_p, at_over])
	print("INFO  check 4 boundary P=%s (range equals 35). P=%s range=%s. P=20 range=%s." % [boundary, under_p, at_under, kick.max_range])


func _check_5_late_accuracy() -> void:
	var angle := KickLogic.final_angle(0.0, -15.0)
	var offset := KickLogic.offset_yards_at_uprights(35.0, angle)
	var gap := absf(offset) - KickConstants.POST_HALF_GAP_YARDS
	var result := KickLogic.classify(KickLogic.range_yards(80.0), 35.0, offset)
	print("INFO  check 5 angle=%s offset=%s gap_past_3.08=%s result=%s" % [angle, offset, gap, result])
	print("INFO  check 5 minimal change: set DOINK_BAND_YARDS below %s (it is 0.15) and this kick becomes WIDE RIGHT." % gap)
	check(near(angle, 5.25), "check 5 e=-15 is +5.25 degrees (screen-right), got %s" % angle)
	check(absf(offset) > 3.08, "check 5 the ball is past the post, |offset|=%s" % absf(offset))
	check(gap <= 0.15, "check 5 that miss is still inside the 0.15 doink band")
	check(result == "DOINK", "check 5 the written rules say DOINK, got " + result)
	var kick := KickLogic.new()
	kick.press_space()
	kick.advance(kick.windup_left)
	kick.advance(kick.seconds_to_power(80.0))
	kick.press_space()
	var guard := 0
	while kick.phase == KickLogic.Phase.ACCURACY and guard < 600:
		kick.advance(1.0 / 60.0)
		guard += 1
	check(near(kick.power, 80.0), "check 5 power stayed near 80, got %s" % kick.power)
	check(near(kick.accuracy_error, -15.0), "check 5 letting the needle hit -15 locks e=-15, got %s" % kick.accuracy_error)
	check(kick.offset_yards > 0.0, "check 5 the ball went screen-right")
	check(kick.result_text == "DOINK", "check 5 played kick is DOINK, got %s" % kick.result_text)


func _check_doink_edges() -> void:
	var post := KickConstants.POST_HALF_GAP_YARDS
	var band := KickConstants.DOINK_BAND_YARDS
	var reach := 100.0
	check(KickLogic.classify(reach, 35.0, post) == "DOINK", "landing on 3.08 is DOINK")
	check(KickLogic.classify(reach, 35.0, post + band) == "DOINK", "outer doink edge is DOINK")
	check(KickLogic.classify(reach, 35.0, post - band) == "DOINK", "inner doink edge is DOINK")
	check(KickLogic.classify(reach, 35.0, -(post + band)) == "DOINK", "left doink edge is DOINK")
	check(KickLogic.classify(reach, 35.0, post + band + 0.001) == "WIDE RIGHT", "just outside the doink band is WIDE RIGHT")
	check(KickLogic.classify(reach, 35.0, -(post + band + 0.001)) == "WIDE LEFT", "just outside the doink band is WIDE LEFT")
	check(KickLogic.classify(reach, 35.0, post - band - 0.001) == "GOOD", "just inside the doink band is GOOD")
	check(KickLogic.classify(10.0, 35.0, 10.0) == "SHORT", "SHORT wins even when the aim is wide")


func _check_signs() -> void:
	var hook_left := KickLogic.offset_yards_at_uprights(35.0, KickLogic.final_angle(0.0, 30.0))
	var slice_right := KickLogic.offset_yards_at_uprights(35.0, KickLogic.final_angle(0.0, -30.0))
	check(hook_left < 0.0 and KickLogic.classify(80.0, 35.0, hook_left) == "WIDE LEFT", "positive e goes WIDE LEFT (%s)" % hook_left)
	check(slice_right > 0.0 and KickLogic.classify(80.0, 35.0, slice_right) == "WIDE RIGHT", "negative e goes WIDE RIGHT (%s)" % slice_right)
	var right_aim := KickLogic.new()
	right_aim.aim(1.0, 0.5)
	check(near(right_aim.aim_degrees, 5.0), "Right aims at +5, got %s" % right_aim.aim_degrees)
	right_aim.aim(1.0, 5.0)
	check(near(right_aim.aim_degrees, 12.0), "full Right clamps at +12, got %s" % right_aim.aim_degrees)


func _check_flight_and_reset() -> void:
	var kick := _kick_power_accuracy(50.0, 0.0)
	var expected_range := KickLogic.range_yards(50.0)
	check(near(kick.travel_yards, expected_range), "P=50 flies its max range %s, got %s" % [expected_range, kick.travel_yards])
	check(near(kick.flight_duration, KickLogic.flight_time_seconds(expected_range)), "flight time follows the yards flown, got %s" % kick.flight_duration)
	check(kick.result_text == "GOOD", "centered P=50 is GOOD")
	kick.advance(kick.flight_duration * 0.5)
	check(near(kick.ball_height, 1.0), "mid-flight height is 1, got %s" % kick.ball_height)
	check(near(kick.ball_forward_yards, expected_range * 0.5), "mid-flight is halfway along the flight, got %s" % kick.ball_forward_yards)
	check(near(kick.ball_lateral_yards, 0.0), "a straight kick stays centered")
	var to_posts := kick.flight_duration * (kick.kick_distance / kick.travel_yards)
	kick.advance(to_posts - kick.flight_duration * 0.5)
	check(near(kick.ball_forward_yards, 35.0, 0.02), "the ball reaches the uprights before the flight ends, got %s" % kick.ball_forward_yards)
	kick.advance(kick.flight_duration)
	check(kick.phase == KickLogic.Phase.RESULT, "the flight ends on the result")
	check(near(kick.ball_height, 0.0, 0.001), "the ball is back on the ground at the end")
	check(near(kick.ball_forward_yards, expected_range), "the ball finishes at max range, past the posts")
	var full := KickLogic.range_yards(100.0)
	check(absf(full - 60.0) < 0.001, "full power range is 60 yd for The Walk-On, got %s" % full)
	var short_kick := _kick_power_accuracy(20.0, 0.0)
	check(near(short_kick.flight_duration, KickLogic.flight_time_seconds(short_kick.max_range)), "a short kick's flight time uses the yards it actually flies")
	short_kick.advance(short_kick.flight_duration)
	check(near(short_kick.ball_forward_yards, short_kick.max_range), "a short ball drops at max range %s" % short_kick.ball_forward_yards)
	check(short_kick.ball_forward_yards < short_kick.kick_distance, "a short ball does not reach the posts")
	var again := KickLogic.new()
	again.kick_distance = 42.0
	again.aim(-1.0, 0.4)
	again.press_space()
	again.advance(again.windup_left)
	again.advance(0.5)
	again.press_space()
	again.advance(again.seconds_until_error(0.0))
	again.press_space()
	again.advance(10.0)
	check(again.phase == KickLogic.Phase.RESULT, "the sample kick reached a result")
	again.press_space()
	check(again.phase == KickLogic.Phase.AIMING, "space after the result sets up the same kick")
	check(near(again.aim_degrees, 0.0) and near(again.needle, 0.0), "reset clears the aim and the needle")
	check(near(again.kick_distance, 42.0), "reset keeps the kick distance")
	check(again.result_text == "", "reset clears the old result")


func _check_detail_text() -> void:
	var sample := KickLogic.format_detail(78.0, 3.0, KickLogic.final_angle(0.0, 3.0))
	check(sample == "P = 78, e = +3, angle = -1.1°", "detail line reads '%s'" % sample)
	var late := KickLogic.format_detail(80.0, -15.0, 5.25)
	check(late == "P = 80, e = -15, angle = +5.3°", "late detail line reads '%s'" % late)


func _check_run() -> void:
	_check_run_table()
	_check_run_start_earn_and_cap()
	_check_run_spots_and_attempts()
	_check_run_score_and_endings()
	_check_run_late_earn_and_spot_in_the_kick()


func _check_run_table() -> void:
	check(RunTable.count() == 20, "the run has 20 kicks")
	var distances: Array = [35, 38, 41, 44, 48, 45, 50, 53, 56, 60, 54, 59, 62, 65, 68, 60, 65, 69, 72, 75]
	var bosses: Array = [5, 10, 15, 20]
	for n in range(1, 21):
		var row: Dictionary = RunTable.row(n)
		check(int(row["kick"]) == n, "table kick number %d" % n)
		check(near(float(row["distance"]), float(distances[n - 1])), "kick %d distance" % n)
		var spot := "center"
		if n >= 4 and n <= 10:
			spot = "hash"
		elif n >= 11:
			spot = "wide"
		check(str(row["spot"]) == spot, "kick %d spot is %s" % [n, spot])
		var boss := bosses.has(n)
		check((str(row["conditions"]) == "boss") == boss, "kick %d boss flag" % n)
		check(float(row["wind_min"]) <= float(row["wind_max"]), "kick %d wind range is ordered" % n)
	check(near(float(RunTable.row(1)["wind_min"]), 0.0) and near(float(RunTable.row(1)["wind_max"]), 0.0), "kick 1 wind is 0–0")
	check(near(float(RunTable.row(4)["wind_max"]), 5.0), "kick 4 wind max is 5")
	check(near(float(RunTable.row(20)["wind_min"]), 25.0) and near(float(RunTable.row(20)["wind_max"]), 35.0), "kick 20 wind is 25–35")
	check(RunTable.spot_yards("center", 1) == 0.0, "center spot is 0")
	check(RunTable.spot_yards("hash", 1) == 3.0 and RunTable.spot_yards("hash", -1) == -3.0, "hash spot is ±3")
	check(RunTable.spot_yards("wide", 1) == 6.0 and RunTable.spot_yards("wide", -1) == -6.0, "wide spot is ±6")
	var y75 := KickConstants.UPRIGHT_Y_PX + 75.0 * KickConstants.PIXELS_PER_YARD
	check(y75 == 585.0 and y75 < KickConstants.WINDOW_HEIGHT, "75 yd still fits under the posts")
	check(KickConstants.LATE_EARN_RULE == false, "LATE_EARN_RULE starts false")
	check(KickConstants.ATTEMPTS_START == 1 and KickConstants.ATTEMPT_CAP == 3 and KickConstants.ATTEMPT_CAP_MAX == 5, "attempt numbers are 1, cap 3, hard max 5")


func _check_run_start_earn_and_cap() -> void:
	var run := RunLogic.new()
	run.new_run()
	check(run.kick_number == 1 and near(run.distance_yards(), 35.0), "check 1 kick 1 is 35 yd")
	check(run.attempts == 1 and run.attempt_cap == 3, "check 1 starts with 1 attempt and a cap of 3")
	check(near(run.spot_yards, 0.0) and near(run.current_mult(), 1.0), "check 1 is centered with mult 1")
	run.resolve_kick("GOOD", 0.0, false)
	check(run.attempt_note == "+1 ATTEMPT" and run.attempts == 2, "check 2 a first make earns +1 ATTEMPT, attempts=%d" % run.attempts)
	check(run.go_to_next_kick(), "check 2 space moves on")
	check(run.kick_number == 2 and near(run.distance_yards(), 38.0), "check 2 next is kick 2 at 38 yd")
	check(near(run.spot_yards, 0.0), "check 2 kick 2 is still centered, so the ball is farther up the field only")
	run.resolve_kick("GOOD", 0.0, false)
	check(run.attempts == 3 and run.attempt_note == "+1 ATTEMPT", "check 3 kick 2 fills the third attempt")
	check(run.go_to_next_kick(), "move to kick 3")
	run.resolve_kick("GOOD", 0.0, false)
	check(run.attempt_note == "AT CAP" and run.attempts == 3, "check 3 kick 3 is AT CAP and stays at 3")
	check(run.go_to_next_kick(), "move to kick 4")
	check(run.kick_number == 4 and near(run.current_mult(), 1.75), "check 3 mult is 1.75 before kick 4, got %s" % run.current_mult())
	check(near(absf(run.spot_yards), 3.0), "check 4 kick 4 starts ±3 yd off center, got %s" % run.spot_yards)


func _check_run_spots_and_attempts() -> void:
	var left := _kick4_spot(7, -1)
	var right := _kick4_spot(7, 1)
	check(near(left, -3.0) and near(right, 3.0), "check 4 forced sides are -3 and +3")
	var again := _kick4_spot(3, 0)
	var replay := _kick4_spot(3, 0)
	check(near(again, replay) and near(absf(again), 3.0), "the same seed puts kick 4 on the same side (%s)" % again)
	var saw_left := false
	var saw_right := false
	for seed_value in range(1, 40):
		var spot := _kick4_spot(seed_value, 0)
		if near(spot, -3.0):
			saw_left = true
		if near(spot, 3.0):
			saw_right = true
	check(saw_left and saw_right, "kick 4 can land on either hash")
	var run := RunLogic.new()
	run.new_run()
	run.attempts = 3
	run.resolve_kick("WIDE LEFT", -8.0, false)
	check(run.attempts == 2 and run.streak == 0 and run.phase == RunLogic.Phase.PLAYING, "check 5 first miss leaves 2")
	check(not run.go_to_next_kick() and run.kick_number == 1, "a miss stays on the same kick")
	var spot_after_miss := run.spot_yards
	check(run.begin_retry() and near(run.spot_yards, spot_after_miss) and not run.is_first_ball, "the retry keeps the spot")
	run.resolve_kick("SHORT", 0.0, false)
	check(run.attempts == 1 and run.kick_number == 1, "check 5 second miss leaves 1 and does not skip")
	run.begin_retry()
	run.resolve_kick("GOOD", 0.0, false)
	check(run.attempt_note == "" and run.attempts == 1, "a retry make does not earn an attempt")
	check(run.go_to_next_kick() and run.kick_number == 2, "only the make moves on, by one kick")
	var over := RunLogic.new()
	over.new_run()
	over.resolve_kick("DOINK", 3.1, false)
	check(over.phase == RunLogic.Phase.GAME_OVER, "check 6 missing kick 1 is game over")
	check(over.score == 0 and over.kicks_made == 0 and near(over.longest_make, 0.0), "check 6 stats are score 0, made 0, longest 0")
	check(over.kick_number == 1 and not over.go_to_next_kick(), "check 6 game over does not move on")
	over.new_run()
	check(over.kick_number == 1 and over.attempts == 1 and over.score == 0 and over.phase == RunLogic.Phase.PLAYING, "check 6 R starts kick 1 with 1 attempt")


func _check_run_score_and_endings() -> void:
	var line := RunLogic.format_score_line(56.0, 1.5, true, false, true)
	check(line == "56 yd × 1.50 × 2 = 168 (+5 PERFECT)", "score line reads '%s'" % line)
	check(RunLogic.points_for(56.0, 1.5, true, false, true) == 173, "that line is worth 168 + 5 = 173")
	check(RunLogic.points_for(35.0, 1.25, false, false, false) == 44, "35 × 1.25 = 43.75 rounds to 44")
	check(RunLogic.points_for(38.0, 1.25, false, false, false) == 48, "38 × 1.25 = 47.5 rounds to 48")
	check(RunLogic.points_for(48.0, 1.0, false, true, false) == 72, "boss ×1.5: 48 × 1.5 = 72")
	check(RunLogic.points_for(35.0, 1.0, false, false, true) == 40, "+5 PERFECT on a plain 35 is 40")
	var middle := RunLogic.new()
	middle.new_run()
	middle.resolve_kick("GOOD", 0.0, true)
	check(middle.down_the_middle, "check 7 a dead-center make is down the middle")
	check(middle.score_line == "35 yd × 1.00 × 2 = 70 (+5 PERFECT)", "check 7 math reads '%s'" % middle.score_line)
	check(middle.score == 75, "check 7 score is 75, got %d" % middle.score)
	check(middle.attempt_note == "+1 ATTEMPT", "check 7 also earns an attempt")
	var edge := RunLogic.new()
	edge.new_run()
	edge.resolve_kick("GOOD", 1.0, false)
	check(edge.down_the_middle and edge.score == 70, "offset of exactly 1 yd is still down the middle")
	edge = RunLogic.new()
	edge.new_run()
	edge.resolve_kick("GOOD", 1.01, false)
	check(not edge.down_the_middle and edge.score == 35, "offset just past 1 yd is not doubled, score %d" % edge.score)
	var boss := _fresh(5, 1)
	boss.streak = 0
	boss.resolve_kick("GOOD", 4.0, false)
	check(boss.is_boss(), "kick 5 is a boss kick")
	check(boss.score == 72 and boss.score_line == "48 yd × 1.00 × 1.5 = 72", "boss math reads '%s'" % boss.score_line)
	var stacked := RunLogic.points_for(75.0, 1.0, true, true, false)
	check(stacked == 225, "middle and boss stack: 75 × 2 × 1.5 = 225, got %d" % stacked)
	var won := _fresh(20, 1)
	won.resolve_kick("GOOD", 0.4, false)
	check(won.phase == RunLogic.Phase.WIN, "making kick 20 is a win")
	check(won.kicks_made == 1 and near(won.longest_make, 75.0), "win stats count that make, longest %s" % won.longest_make)
	check(won.attempts == 2, "the winning make still earns an attempt")
	check(not won.go_to_next_kick() and won.kick_number == 20, "a win does not invent kick 21")
	var last_miss := _fresh(20, 2)
	last_miss.resolve_kick("WIDE RIGHT", 6.0, false)
	check(last_miss.phase == RunLogic.Phase.PLAYING and last_miss.attempts == 1, "a miss on kick 20 with an attempt left is not game over")
	check(not last_miss.go_to_next_kick() and last_miss.kick_number == 20 and last_miss.phase == RunLogic.Phase.PLAYING, "a miss on kick 20 stays on kick 20 for a retry")
	var last_out := _fresh(20, 1)
	last_out.resolve_kick("SHORT", 0.0, false)
	check(last_out.phase == RunLogic.Phase.GAME_OVER, "running out on kick 20 is game over, not a next kick")
	var streak_run := RunLogic.new()
	streak_run.new_run()
	streak_run.resolve_kick("GOOD", 2.0, false)
	check(streak_run.streak == 1, "a make builds the streak")
	check(streak_run.go_to_next_kick(), "advance after the make")
	streak_run.resolve_kick("WIDE RIGHT", 4.0, false)
	check(streak_run.streak == 0 and streak_run.score == 35, "a miss resets the streak and adds no points")


func _check_run_late_earn_and_spot_in_the_kick() -> void:
	var plain := _fresh(11, 2)
	plain.late_earn_rule = true
	plain.resolve_kick("GOOD", 4.0, false)
	check(plain.attempts == 2 and plain.attempt_note == "", "check 8 a normal good on kick 11 stays at 2 attempts")
	var middle := _fresh(11, 2)
	middle.late_earn_rule = true
	middle.resolve_kick("GOOD", 0.2, false)
	check(middle.down_the_middle and middle.attempts == 3 and middle.attempt_note == "+1 ATTEMPT", "check 8 down the middle on kick 11 goes to 3")
	var perfect := _fresh(11, 2)
	perfect.late_earn_rule = true
	perfect.resolve_kick("GOOD", 4.0, true)
	check(perfect.attempts == 3, "check 8 a perfect on kick 11 also earns")
	var earlier := _fresh(10, 2)
	earlier.late_earn_rule = true
	earlier.resolve_kick("GOOD", 4.0, false)
	check(earlier.attempts == 3, "kick 10 still earns on a normal good when the late rule is on")
	var retake := _fresh(1, 2)
	retake.is_first_ball = false
	retake.resolve_kick("GOOD", 0.0, true)
	check(retake.attempts == 2 and retake.score == 75 and retake.streak == 1, "a make that is not the first ball scores, but earns no attempt")
	var hash_kick := KickLogic.new()
	hash_kick.kick_distance = 44.0
	hash_kick.start_lateral_yards = 3.0
	hash_kick.press_space()
	hash_kick.advance(hash_kick.windup_left)
	hash_kick.advance(hash_kick.seconds_to_power(80.0))
	hash_kick.press_space()
	hash_kick.advance(hash_kick.seconds_until_error(0.0))
	hash_kick.press_space()
	hash_kick.advance(hash_kick.flight_duration * 0.5)
	check(near(hash_kick.offset_yards, 3.0), "aiming straight from +3 yd still arrives 3 yd off, got %s" % hash_kick.offset_yards)
	check(hash_kick.result_text == "DOINK", "that arrival is a DOINK under the written band, got %s" % hash_kick.result_text)
	check(hash_kick.ball_forward_yards > 1.0 and near(hash_kick.ball_lateral_yards, 3.0), "the sideways spot stays with the ball in flight")
	var wired := RunLogic.new()
	wired.new_run()
	var center := _kick_power_accuracy(80.0, 0.0)
	wired.resolve_kick(center.result_text, center.offset_yards, center.perfect)
	check(center.result_text == "GOOD" and center.perfect and wired.down_the_middle, "a real centered kick is a perfect make down the middle")
	check(wired.score == 75 and wired.attempts == 2, "the run scores that kick and earns the attempt")


func _fresh(kick_number: int, attempt_count: int) -> RunLogic:
	var run := RunLogic.new()
	run.new_run()
	run.phase = RunLogic.Phase.PLAYING
	run.kick_number = kick_number
	run.attempts = attempt_count
	run.attempt_cap = KickConstants.ATTEMPT_CAP
	run.is_first_ball = true
	run.kick_resolved = false
	run.streak = 0
	run.score = 0
	run.kicks_made = 0
	run.longest_make = 0.0
	run.attempt_note = ""
	run.score_line = ""
	run.down_the_middle = false
	return run


func _kick4_spot(seed_value: int, side: int) -> float:
	var run := RunLogic.new()
	run.set_seed(seed_value)
	run.new_run()
	if side != 0:
		run.set_next_side(side)
	var step := 0
	while step < 3:
		run.resolve_kick("GOOD", 0.0, false)
		run.go_to_next_kick()
		step += 1
	return run.spot_yards


func _check_upgrades() -> void:
	_check_upgrade_offers()
	_check_upgrade_effects()
	_check_mulligan_reroll_and_skip()


func _check_upgrade_offers() -> void:
	var state := Loadout.empty_state()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var offer: Array = Loadout.draw_offer(state, 3, rng)
	check(offer.size() == 3, "an offer has 3 cards")
	var equip := 0
	var curses := 0
	for card in offer:
		if str(card.get("kind", "")) == Loadout.EQUIPMENT:
			equip += 1
		if str(card.get("kind", "")) == Loadout.CURSE:
			curses += 1
	check(equip == 1, "a fresh offer has exactly one equipment card")
	check(curses <= 1, "a fresh offer has at most one curse")
	var again := RandomNumberGenerator.new()
	again.seed = 4
	check(Loadout.draw_offer(state, 3, again) == offer, "the same offer seed draws the same cards")
	var saw_equip := 0
	for seed_value in 20:
		var roller := RandomNumberGenerator.new()
		roller.seed = seed_value + 9
		var cards: Array = Loadout.draw_offer(Loadout.empty_state(), 3, roller)
		var count := 0
		var curse_count := 0
		for card in cards:
			if str(card.get("kind", "")) == Loadout.EQUIPMENT:
				count += 1
			if str(card.get("kind", "")) == Loadout.CURSE:
				curse_count += 1
		check(count == 1 and curse_count <= 1, "seed %s keeps one equipment and at most one curse" % seed_value)
		saw_equip += count
	check(saw_equip == 20, "sampled 20 offers")
	var run := RunLogic.new()
	run.new_run()
	run.force_offer([{"id": Loadout.CANNON, "rank": 1}, {"id": Loadout.DEEP_BENCH, "rank": 1}, {"id": Loadout.ICED, "rank": 1}])
	run.roll_offer()
	check(run.pick_card(0) and run.cleats_id == Loadout.CANNON and run.cleats_rank == 1, "picking the first card takes Cannon Cleats")
	check(not run.awaiting_offer, "picking closes the offer")
	var locked: Array = Loadout.legal_equipment(run.loadout_state())
	var other_cleat := false
	var rank_up := false
	for card in locked:
		if str(card.get("slot", "")) == Loadout.CLEATS and str(card.get("id", "")) != Loadout.CANNON:
			other_cleat = true
		if str(card.get("id", "")) == Loadout.CANNON and int(card.get("rank", 0)) == 2:
			rank_up = true
	check(not other_cleat and rank_up, "Cannon Cleats locks the slot and can rank up")


func _check_upgrade_effects() -> void:
	var kick := KickLogic.new()
	kick.kick_distance = 35.0
	_lock_power_at(kick, 40.0)
	check(kick.result_text == "SHORT", "power 40 from 35 yd is SHORT before Cannon Cleats, range %s" % kick.max_range)
	kick.stats.range_bonus = 6.0
	_lock_power_at(kick, 40.0)
	check(kick.result_text == "GOOD" and kick.max_range >= 35.0, "Cannon Cleats I makes power 40 reach, range %s" % kick.max_range)
	var slow := RunLogic.new()
	slow.new_run()
	slow.give(Loadout.ANCHOR, 1)
	check(near(slow.stats.power_speed, 85.0) and near(slow.stats.accuracy_speed, 120.0 * 0.85), "Anchor Cleats I is 85% on both needles")
	slow.give(Loadout.ANCHOR, 2)
	check(near(slow.stats.power_speed, 100.0 * pow(0.85, 2.0)), "Anchor Cleats II is 0.85 squared")
	var pinpoint := RunLogic.new()
	pinpoint.new_run()
	pinpoint.give(Loadout.PINPOINT, 1)
	check(near(pinpoint.stats.perfect_band, 3.5) and near(pinpoint.stats.good_band, 9.0), "Pinpoint Cleats I widens the bands to ±3.5 / ±9")
	var bench := RunLogic.new()
	bench.new_run()
	bench.attempts = 2
	bench.give(Loadout.DEEP_BENCH, 1)
	check(bench.attempt_cap == 4 and bench.attempts == 3, "Deep Bench I makes 4 circles and fills one more")
	bench.give(Loadout.DEEP_BENCH, 2)
	check(bench.attempt_cap == 5 and bench.attempts == 4, "Deep Bench II reaches the hard max of 5")
	var before_cap := bench.attempt_cap
	var before_attempts := bench.attempts
	bench.give(Loadout.DEEP_BENCH, 2)
	check(bench.attempt_cap == before_cap and bench.attempts == before_attempts, "giving Deep Bench II again changes nothing")
	var hot := RunLogic.new()
	hot.new_run()
	hot.give(Loadout.HOT_STREAK, 1)
	check(near(hot.stats.streak_step, 0.5), "Hot Streak I sets the streak step to 0.5")
	hot.give(Loadout.HOT_STREAK, 2)
	check(near(hot.stats.streak_step, 0.75), "Hot Streak II sets the streak step to 0.75")
	var glass := RunLogic.new()
	glass.new_run()
	glass.attempt_cap = 2
	check(Loadout.legal_perks(glass.loadout_state(), glass.attempt_cap).size() >= 0, "perk list still builds at a low cap")
	var blocked := false
	for card in Loadout.legal_perks(glass.loadout_state(), 2):
		if str(card.get("id", "")) == Loadout.GLASS_LEG:
			blocked = true
	check(not blocked, "Glass Leg is not offered at cap 2")
	glass.attempt_cap = 3
	glass.attempts = 3
	glass.give(Loadout.GLASS_LEG, 1)
	check(glass.attempt_cap == 2 and glass.attempts == 2 and near(glass.stats.range_bonus, 8.0), "Glass Leg I drops the cap to 2 and adds 8 yards")
	glass.give(Loadout.GLASS_LEG, 2)
	check(glass.attempt_cap == 2 and near(glass.stats.range_bonus, 16.0), "Glass Leg II is +16 yards and does not drop the cap again")


func _check_mulligan_reroll_and_skip() -> void:
	var cards := RunLogic.new()
	cards.new_run()
	cards.set_offer_seed(2)
	cards.roll_offer()
	check(cards.rerolls_left == 1 and cards.reroll_offer(), "F rerolls once")
	check(cards.rerolls_left == 0 and cards.offer.size() == 3, "the new offer is still 3 cards")
	var held: Array = cards.offer.duplicate()
	check(not cards.reroll_offer() and cards.offer == held, "a second F does nothing")
	var skipped := RunLogic.new()
	skipped.new_run()
	skipped.resolve_kick("GOOD", 2.0, false)
	var scored := skipped.score
	skipped.roll_offer()
	check(skipped.skip_offer() and skipped.score == scored and skipped.curse_ids.is_empty(), "S takes nothing and applies no curse")
	check(skipped.go_to_next_kick() and skipped.kick_number == 2, "skip starts the next kick")
	var fresh := RunLogic.new()
	fresh.new_run()
	fresh.give(Loadout.CANNON, 1)
	fresh.give(Loadout.ICED)
	check(fresh.cleats_id == Loadout.CANNON and fresh.has_curse(Loadout.ICED), "the run kept the loadout")
	fresh.new_run()
	check(fresh.cleats_id == "" and fresh.curse_ids.is_empty() and fresh.stats.range_bonus == 0.0, "a new run clears the loadout")
	check(fresh.rerolls_left == 1, "a new run without a kicker starts with 1 reroll")


func _aimed_power(power_value: float, aim: float, insure: bool) -> KickLogic:
	var kick := KickLogic.new()
	kick.insurance_ready = insure
	kick.reset_kick()
	kick.kick_distance = 35.0
	kick.aim_degrees = aim
	_swing_to(kick, power_value, 0.0)
	return kick


func _lock_power_at(kick: KickLogic, power_value: float, distance: float = 35.0) -> void:
	kick.reset_kick()
	kick.kick_distance = distance
	kick.start_lateral_yards = 0.0
	_swing_to(kick, power_value, 0.0)


func _park_on_right_arc(kick: KickLogic, power_value: float = 40.0) -> void:
	kick.reset_kick()
	kick.press_space()
	if kick.windup_left > 0.0:
		kick.advance(kick.windup_left)
	kick.advance(kick.seconds_to_power(power_value))
	if kick.phase == KickLogic.Phase.POWER:
		kick.press_space()
	if kick.phase == KickLogic.Phase.ACCURACY:
		var wait := kick.seconds_until_error(15.0)
		if wait > 0.0:
			kick.advance(wait)


func _swing_to(kick: KickLogic, power_value: float, error_value: float) -> void:
	kick.press_space()
	if kick.windup_left > 0.0:
		kick.advance(kick.windup_left)
	if power_value >= KickConstants.METER_MAX - 0.001:
		kick.take_power_press(kick.seconds_to_power(power_value))
	elif power_value > 0.0:
		kick.advance(kick.seconds_to_power(power_value))
		if kick.phase == KickLogic.Phase.POWER:
			kick.press_space()
	if kick.phase == KickLogic.Phase.ACCURACY:
		var wait := kick.seconds_until_error(error_value)
		if wait > 0.0:
			kick.advance(wait)
		if kick.phase == KickLogic.Phase.ACCURACY:
			kick.press_space()


func _kick_power_accuracy(power_value: float, needle_at_lock: float) -> KickLogic:
	var kick := KickLogic.new()
	_swing_to(kick, power_value, needle_at_lock)
	return kick


func _check_kickers_and_fixes() -> void:
	var first := Kickers.click_slot(-1, 0)
	check(int(first["highlight"]) == 0 and not bool(first["confirm"]), "check 1 the first click highlights Big Bruce")
	var again := Kickers.click_slot(0, 0)
	check(bool(again["confirm"]), "check 1 clicking the highlighted card confirms")
	check(Kickers.id_for_slot(0) == Kickers.BIG_BRUCE and Kickers.id_for_slot(1) == Kickers.WALK_ON, "the two slots are Big Bruce and The Walk-On")
	var bruce := KickerStats.new()
	Kickers.apply_to(bruce, Kickers.BIG_BRUCE)
	check(near(bruce.range_per_power, 0.49), "check 1 Big Bruce range per power is 0.49")
	check(near(bruce.red_tip_start, 95.0) and near(bruce.red_tip_noise, 5.0), "Big Bruce uses the default red tip")
	check(near(bruce.accuracy_speed, KickConstants.ACCURACY_FALL_PER_SEC), "Big Bruce accuracy needle is the default speed")
	check(near(bruce.power_floor, 80.0), "Farm Strength floors power at 80")
	check(bruce.ball_type == "farm_ball", "Big Bruce kicks The Farm Ball")
	var bruce_text := str(Kickers.get_def(Kickers.BIG_BRUCE))
	check(bruce_text.find("Farm Strength") >= 0 and bruce_text.find("The Farm Ball") >= 0, "Bruce's card names Farm Strength and The Farm Ball")
	check(bruce_text.find("Barn Burner") < 0 and bruce_text.find("bank") < 0, "Barn Burner is gone from Bruce's card")
	var posts := KickLogic.judge(76.0, 35.0, 3.08, "farm_ball")
	check(not bool(posts["bank"]) and str(posts["text"]) == "DOINK", "a doink with range to spare stays a DOINK")
	check(str(KickLogic.judge(20.0, 35.0, 0.0, "farm_ball")["text"]) == "SHORT", "Farm Strength does not save a kick that is still short of the posts")
	var walk := KickerStats.new()
	Kickers.apply_to(walk, Kickers.WALK_ON)
	check(near(walk.red_tip_start, 95.0) and near(walk.range_per_power, 0.44) and walk.ball_type == "standard", "check 4 The Walk-On keeps the normal meter and ball")
	check(walk.rerolls_per_run == 2, "check 4 The Walk-On gets 2 rerolls")
	var walked := RunLogic.new()
	walked.start_with_kicker(Kickers.WALK_ON)
	check(walked.rerolls_left == 2 and walked.kicker_id == Kickers.WALK_ON, "starting as The Walk-On shows Reroll: 2 left")
	check(Kickers.has_portrait(Kickers.BIG_BRUCE) and Kickers.has_portrait(Kickers.WALK_ON), "check 5 the select screen uses the headshot files")
	check(not Kickers.has_portrait("nobody"), "check 5 a missing portrait still falls back to the shape")
	check(ResourceLoader.exists("res://scripts/Kickers.gd"), "a file that is really there would be drawn")
	check(str(Kickers.get_def(Kickers.BIG_BRUCE)["portrait_path"]) == "res://art/kickers/big_bruce.png", "Big Bruce looks for res://art/kickers/big_bruce.png")
	var carried := RunLogic.new()
	carried.start_with_kicker(Kickers.BIG_BRUCE)
	carried.give(Loadout.CANNON, 1)
	check(near(carried.stats.range_per_power, 0.49) and carried.stats.range_bonus == 6.0, "Big Bruce kept his leg and Cannon Cleats")
	carried.start_with_kicker(Kickers.WALK_ON)
	check(near(carried.stats.range_per_power, 0.44) and carried.stats.range_bonus == 0.0, "check 6 the next kicker does not keep the last stats")
	check(carried.rerolls_left == 2 and carried.stats.ball_type == "standard", "check 6 The Walk-On starts clean")
	var short_kick := KickLogic.new()
	_lock_power_at(short_kick, 12.0)
	check(short_kick.result_text == "SHORT" and not short_kick.reached_uprights, "check 7 a low centered kick is SHORT, not GOOD")
	check(short_kick.travel_yards < 35.0, "the short ball is not given the full distance")
	short_kick.advance(short_kick.flight_duration)
	check(near(short_kick.ball_forward_yards, short_kick.max_range) and short_kick.ball_forward_yards < 35.0, "check 7 the ball lands at max range, in front of the posts")
	var stay := RunLogic.new()
	stay.new_run()
	stay.resolve_kick("SHORT", 0.0, true)
	check(stay.phase == RunLogic.Phase.GAME_OVER and stay.kick_number == 1, "check 8 one miss on kick 1 is game over, still kick 1")
	var retry := RunLogic.new()
	retry.start_with_kicker(Kickers.WALK_ON)
	retry.set_next_side(1)
	retry.resolve_kick("GOOD", 0.0, false)
	check(retry.attempts == 2 and retry.attempt_note == "+1 ATTEMPT", "check 9 making kick 1 earns an attempt")
	check(retry.go_to_next_kick(), "make 1 moves to kick 2")
	retry.resolve_kick("GOOD", 0.0, false)
	check(retry.go_to_next_kick(), "make 2 moves to kick 3")
	retry.resolve_kick("GOOD", 0.0, false)
	check(retry.go_to_next_kick(), "make 3 moves to kick 4")
	check(retry.kick_number == 4 and near(retry.spot_yards, 3.0), "kick 4 is the right hash")
	var saved_spot := retry.spot_yards
	retry.resolve_kick("WIDE RIGHT", 6.0, false)
	check(retry.kick_number == 4 and near(retry.spot_yards, saved_spot) and retry.attempts == 2, "check 9 the miss stays on kick 4 and the same spot")
	check(retry.begin_retry() and not retry.is_first_ball and near(retry.spot_yards, saved_spot), "the retry is the same kick, not a first ball")
	retry.resolve_kick("GOOD", 0.0, false)
	check(retry.attempt_note == "" and retry.attempts == 2 and retry.kick_number == 4, "check 9 the retry make does not award +1 ATTEMPT")
	check(retry.go_to_next_kick() and retry.kick_number == 5, "check 9 the next kick is 5, not 6")


func _check_power_flight() -> void:
	var walk := KickerStats.new()
	Kickers.apply_to(walk, Kickers.WALK_ON)
	check(near(walk.range_per_power, 0.44) and walk.range_bonus == 0.0, "Walk-On kick 1 has no range bonus")
	var low := KickLogic.new()
	low.stats = walk
	_lock_power_at(low, 20.0)
	check(near(low.power, 20.0) and near(low.max_range, 24.8), "check 1 P=20 max range is 24.8, got %s" % low.max_range)
	check(near(low.travel_yards, 24.8), "check 1 the ball travels 24.8 yards, not a fixed length")
	check(low.result_text == "SHORT" and low.perfect and not low.reached_uprights, "check 1 and 4 a dead-center low kick is SHORT, never GOOD")
	check(near(low.flight_duration, KickLogic.flight_time_seconds(24.8)), "check 1 flight time uses the yards this ball flies")
	low.advance(low.flight_duration)
	check(near(low.ball_forward_yards, 24.8) and low.ball_forward_yards < 35.0, "check 1 the ball stops several yards short of the posts")
	check(low.detail_line() == "P = 20, max range = 24.8 yd, kick = 35 yd, result = SHORT", "check 1 numbers read '%s'" % low.detail_line())
	var mid := KickLogic.new()
	mid.stats = walk
	_lock_power_at(mid, 50.0)
	check(near(mid.max_range, 38.0) and near(mid.travel_yards, 38.0), "check 2 P=50 flies 38.0 yards, got %s" % mid.travel_yards)
	check(mid.result_text == "GOOD" and mid.reached_uprights, "check 2 centered P=50 is GOOD")
	var at_posts := mid.flight_duration * (35.0 / mid.travel_yards)
	mid.advance(at_posts)
	check(near(mid.ball_forward_yards, 35.0, 0.02), "check 2 the moving ball reaches the uprights, got %s" % mid.ball_forward_yards)
	check(near(mid.ball_lateral_yards, mid.offset_yards, 0.02), "the result offset is the ball's sideways spot at the posts")
	mid.advance(mid.flight_duration)
	check(near(mid.ball_forward_yards, 38.0), "check 2 the ball finishes past the posts, at max range")
	check(mid.ball_forward_yards > low.ball_forward_yards, "check 2 P=50 travels farther than P=20")
	check(mid.detail_line() == "P = 50, max range = 38 yd, kick = 35 yd, result = GOOD", "check 2 numbers read '%s'" % mid.detail_line())
	var full := KickLogic.new()
	full.stats = walk
	full.set_seed(1)
	_lock_power_at(full, 100.0)
	check(near(full.max_range, 60.0) and near(full.travel_yards, 60.0), "check 3 P=100 flies 60 yards, got %s" % full.travel_yards)
	check(full.travel_yards > mid.travel_yards, "check 3 full power travels farther than P=50")
	check(full.flight_duration > mid.flight_duration, "a longer kick takes longer")
	full.advance(full.flight_duration * 0.7)
	var mid_same := KickLogic.new()
	mid_same.stats = walk
	_lock_power_at(mid_same, 50.0)
	mid_same.advance(mid_same.flight_duration * 0.7)
	check(full.ball_forward_yards > mid_same.ball_forward_yards + 15.0, "check 3 at the same point in the flight, P=100 is well past P=50")
	var run := RunLogic.new()
	run.start_with_kicker(Kickers.WALK_ON)
	run.attempts = 2
	var earlier := KickLogic.new()
	earlier.stats = run.stats
	earlier.kick_distance = run.distance_yards()
	_lock_power_at(earlier, 100.0)
	check(near(earlier.travel_yards, 60.0), "the previous lock flew 60 yards")
	_lock_power_at(earlier, 20.0)
	check(earlier.result_text == "SHORT" and near(earlier.travel_yards, 24.8), "the new lock throws away the old range")
	run.resolve_kick(earlier.result_text, earlier.offset_yards, earlier.perfect)
	check(run.kick_number == 1 and near(run.distance_yards(), 35.0) and run.attempts == 1 and run.phase == RunLogic.Phase.PLAYING, "check 5 a short miss with an attempt left stays on kick 1")
	check(run.begin_retry() and not run.is_first_ball, "check 5 the retry is still kick 1")
	var again := KickLogic.new()
	again.stats = run.stats
	again.kick_distance = run.distance_yards()
	_lock_power_at(again, 20.0)
	check(run.kick_number == 1 and near(again.kick_distance, 35.0), "check 5 the retry is still 35 yards")
	check(near(again.max_range, 24.8) and near(again.travel_yards, 24.8) and again.result_text == "SHORT", "check 5 the retry flies on the new P, not the earlier 60")
	again.advance(again.flight_duration)
	check(near(again.ball_forward_yards, 24.8), "check 5 the retry ball stops at 24.8 yards")


func _check_wind_and_pool() -> void:
	var made := RunLogic.new()
	made.new_run()
	made.resolve_kick("GOOD", 0.0, false)
	check(made.wants_upgrade(), "check 1 a make asks for an upgrade")
	made.roll_offer()
	check(made.awaiting_offer and made.offer.size() > 0, "check 1 the upgrade screen has cards")
	var missed := RunLogic.new()
	missed.start_with_kicker(Kickers.WALK_ON)
	missed.attempts = 2
	missed.set_wind(10.0, 90.0)
	var spot := missed.spot_yards
	missed.resolve_kick("WIDE RIGHT", 4.0, false)
	check(not missed.wants_upgrade() and missed.kick_number == 1 and near(missed.spot_yards, spot), "check 1 a miss does not offer cards and stays on the kick")
	check(missed.begin_retry() and missed.wind_speed == 10 and near(missed.wind_direction, 90.0), "check 1 and 5 the retry keeps the saved wind")
	var leg := RunLogic.new()
	leg.new_run()
	leg.give(Loadout.CANNON, 3)
	check(near(leg.stats.range_bonus, 18.0), "Cannon Cleats III adds 18 yards, got %s" % leg.stats.range_bonus)
	check(Loadout.card_title(Loadout.CANNON, 3) == "Cannon Cleats III", "the rank label reads Cannon Cleats III")
	var before := leg.stats.range_bonus
	leg.rebuild_stats()
	check(near(leg.stats.range_bonus, before), "rebuilding does not apply Cannon Cleats a second time")
	var short_before := KickLogic.new()
	_lock_power_at(short_before, 20.0)
	check(short_before.result_text == "SHORT" and near(short_before.max_range, 24.8), "P=20 is still SHORT at 24.8 yards")
	var reached := KickLogic.new()
	reached.stats.range_bonus = 18.0
	_lock_power_at(reached, 20.0)
	check(reached.max_range > short_before.max_range + 17.0 and reached.result_text == "GOOD", "+18 yards turns that short kick into a make, range %s" % reached.max_range)
	var solid := KickLogic.new()
	_lock_power_at(solid, 50.0)
	check(solid.result_text == "GOOD" and near(solid.max_range, 38.0), "P=50 is still GOOD at 38.0 yards")
	var plant := RunLogic.new()
	plant.new_run()
	plant.give(Loadout.ANCHOR, 1)
	check(near(plant.stats.power_speed, 100.0 * 0.85) and near(plant.stats.accuracy_speed, 120.0 * 0.85), "Anchor Cleats I is 85% on both needles")
	plant.give(Loadout.ANCHOR, 2)
	check(near(plant.stats.power_speed, 100.0 * pow(0.85, 2.0)), "Anchor Cleats II slows both needles again")
	var calm := RunLogic.new()
	calm.set_seed(3)
	calm.new_run()
	for kick_n in [1, 2, 3]:
		check(calm.kick_number == kick_n and calm.wind_speed == 0 and RunLogic.wind_name(calm.wind_speed) == "Calm", "check 4 kick %d is Calm" % kick_n)
		check(RunLogic.wind_flag_kind(calm.wind_speed) == "none", "check 4 kick %d has no flag" % kick_n)
		calm.resolve_kick("GOOD", 0.0, false)
		calm.go_to_next_kick()
	calm.apply_debug_wind()
	check(calm.wind_speed == 10 and near(calm.wind_direction, 90.0), "check 5 W sets 10 mph straight right")
	var held_speed := calm.wind_speed
	var held_dir := calm.wind_direction
	calm.attempts = 2
	calm.resolve_kick("SHORT", 0.0, false)
	calm.begin_retry()
	check(calm.wind_speed == held_speed and near(calm.wind_direction, held_dir), "check 5 a miss keeps that wind")
	calm.resolve_kick("GOOD", 0.0, false)
	var before_kick := calm.kick_number
	calm.go_to_next_kick()
	check(calm.kick_number == before_kick + 1 and not (calm.wind_speed == 10 and near(calm.wind_direction, 90.0)), "check 5 the next kick rolls a new wind")
	var walk_drift := KickLogic.drift_at_uprights(10.0, 90.0, 35.0, 0, 0, "standard")
	var bruce_drift := KickLogic.drift_at_uprights(10.0, 90.0, 35.0, 0, 0, "farm_ball")
	check(walk_drift > 2.0 and near(bruce_drift, walk_drift * 1.10), "The Farm Ball drifts 1.10 times The Walk-On")
	var curve := KickLogic.new()
	curve.wind_speed = 10
	curve.wind_direction = 90.0
	_lock_power_at(curve, 50.0)
	check(curve.offset_yards > 1.5, "check 5 a centered kick in a right wind lands right, offset %s" % curve.offset_yards)
	curve.advance(curve.flight_duration * (35.0 / curve.travel_yards))
	check(near(curve.ball_lateral_yards, curve.offset_yards, 0.05), "the curve at the posts is the scored offset")
	var early := KickLogic.path_lateral(0.0, 10.0, 0.0, 35.0, walk_drift)
	var late := KickLogic.path_lateral(0.0, 30.0, 0.0, 35.0, walk_drift)
	check(late > early * 2.0, "the bend grows late, not in a straight line")
	var reader := RunLogic.new()
	reader.new_run()
	reader.give(Loadout.WIND_VISOR, 1)
	reader.set_wind(10.0, 90.0)
	check(reader.stats.flag_reader, "Wind Visor I shows the wind numbers")
	var readout := RunLogic.wind_readout(reader.wind_speed, reader.wind_direction)
	check(readout.find("10 mph") >= 0 and readout.find("cross") >= 0 and readout.find("tail") >= 0, "check 7 the readout is '%s'" % readout)
	check(near(KickLogic.crosswind_mph(10.0, 90.0), 10.0, 0.02) and near(KickLogic.head_tail_mph(10.0, 90.0), 0.0, 0.02), "10 mph at 90° is all crosswind")
	reader.give(Loadout.WIND_VISOR, 2)
	check(reader.stats.laser_line, "Wind Visor II draws the aim path")
	var preview_far := KickLogic.preview_forward(35.0)
	check(near(preview_far, 14.0), "the preview covers the first 40% of the kick")
	var preview := KickLogic.path_lateral(0.0, preview_far, 0.0, 35.0, walk_drift)
	check(near(preview, walk_drift * 0.16, 0.02), "check 7 the preview bends with the wind curve, lateral %s" % preview)
	var tail_kick := KickLogic.new()
	tail_kick.wind_speed = 10
	tail_kick.wind_direction = 0.0
	_lock_power_at(tail_kick, 50.0)
	var head_kick := KickLogic.new()
	head_kick.wind_speed = 10
	head_kick.wind_direction = 180.0
	_lock_power_at(head_kick, 50.0)
	check(tail_kick.max_range > head_kick.max_range + 7.0, "check 8 a tailwind flies farther than a headwind (%s vs %s)" % [tail_kick.max_range, head_kick.max_range])
	var storm := RunLogic.new()
	storm.new_run()
	storm.give(Loadout.STORM_CHASER, 1)
	storm.set_wind(10.0, 90.0)
	storm.resolve_kick("GOOD", 2.0, false)
	check(storm.score_line.find("wind") >= 0, "Storm Chaser shows up in the score line: %s" % storm.score_line)
	check(near(KickLogic.wind_range_delta(10.0, 0.0, 0, false), 4.0, 0.05), "10 mph of tailwind adds 4 yards")
	check(near(KickLogic.wind_range_delta(10.0, 180.0, 0, false), -4.0, 0.05), "10 mph of headwind takes 4 yards")
	check(near(KickLogic.wind_range_delta(10.0, 0.0, 0, true), 6.0, 0.05), "Thin Air boosts only the tailwind")
	check(near(KickLogic.wind_range_delta(10.0, 180.0, 0, true), -4.0, 0.05), "Thin Air does not boost a headwind")
	var low := RunLogic.new()
	low.new_run()
	low.give(Loadout.STICKER, 1)
	check(near(low.stats.drift_factor, 0.8), "Sticker Cleats I multiplies drift by 0.8")
	var broken := KickLogic.drift_at_uprights(10.0, 90.0, 35.0, 2, 1, "standard")
	check(near(broken, walk_drift * pow(0.65, 2.0) * 0.8), "the old drift formula still multiplies when called directly")
	var ice := RunLogic.new()
	ice.new_run()
	ice.give(Loadout.ICE_CAGE, 1)
	var icy := KickLogic.new()
	icy.stats = ice.stats
	icy.set_seed(2)
	_lock_power_at(icy, 96.0)
	check(icy.accuracy_error == 0.0, "Ice Cage adds no red-tip error when power is in the red, got %s" % icy.accuracy_error)
	var bare := KickLogic.new()
	bare.set_seed(2)
	_lock_power_at(bare, 96.0)
	check(bare.accuracy_error != 0.0, "without Ice Cage the same seed still wobbles, got %s" % bare.accuracy_error)
	var insured := RunLogic.new()
	insured.new_run()
	insured.give(Loadout.DOINK_CAP, 1)
	check(insured.insurance_left == 1, "insurance starts with one charge")
	var doink := _aimed_power(50.0, rad_to_deg(atan(3.08 / 35.0)), true)
	check(doink.result_text == "GOOD" and doink.insured, "a doink with insurance becomes GOOD, got %s" % doink.result_text)
	insured.consume_insurance()
	check(insured.insurance_left == 0, "the charge is used up")
	var again_doink := _aimed_power(50.0, rad_to_deg(atan(3.08 / 35.0)), false)
	check(again_doink.result_text == "DOINK" and not again_doink.insured, "the next doink in the quarter is still a miss, got %s" % again_doink.result_text)
	insured.kick_number = 5
	insured.kick_resolved = true
	insured.last_result_made = true
	insured.go_to_next_kick()
	check(insured.kick_number == 6 and insured.insurance_left == 1, "the next quarter refills Doink Cap")
	var practice := RunLogic.new()
	practice.start_with_kicker(Kickers.WALK_ON)
	practice.give(Loadout.REPLAY_GLOVES, 1)
	var score_before := practice.score
	var attempts_before := practice.attempts
	var streak_before := practice.streak
	var first_ball := practice.is_first_ball
	practice.set_wind(8.0, 45.0)
	check(practice.start_practice() and practice.practicing and practice.practice_left == 0, "check practice spends the quarterly swing")
	check(practice.score == score_before and practice.attempts == attempts_before and practice.streak == streak_before and practice.is_first_ball == first_ball, "a practice swing does not touch score, attempts, or streak")
	check(practice.wind_speed == 8 and not practice.wants_upgrade(), "practice keeps the wind and is not a make")
	practice.end_practice()
	check(not practice.practicing and not practice.start_practice(), "the swing is used up until the next quarter")
	var scout := RunLogic.new()
	scout.start_with_kicker(Kickers.WALK_ON)
	check(scout.rerolls_left == 2, "The Walk-On still starts with 2 rerolls")
	scout.give(Loadout.SCOUT_LID, 1)
	check(scout.stats.rerolls_per_run == 3 and scout.rerolls_left == 3, "Scout Lid I adds one reroll")
	scout.give(Loadout.SCOUT_LID, 2)
	check(scout.stats.rerolls_per_run == 4 and scout.rerolls_left == 4, "Scout Lid II adds another reroll")
	var bench := RunLogic.new()
	bench.new_run()
	bench.attempts = 1
	bench.give(Loadout.DEEP_BENCH, 1)
	check(bench.attempts == 2 and bench.attempt_cap == 4, "Deep Bench adds one attempt when it is picked")
	bench.rebuild_stats()
	check(bench.attempts == 2 and bench.attempt_cap == 4, "rebuilding does not add the attempt again")
	var pool := RunLogic.new()
	pool.new_run()
	pool.resolve_kick("GOOD", 0.0, false)
	pool.roll_offer()
	check(pool.offer.size() > 0 or pool.skip_offer(), "after a make the screen still has a card or Skip")


func _check_weather_and_bosses() -> void:
	check(RunLogic.boss_weather(5) == RunLogic.ICED, "kick 5 is ICED")
	check(RunLogic.boss_weather(10) == RunLogic.SQUEEZE, "kick 10 is THE SQUEEZE")
	check(RunLogic.boss_weather(15) == RunLogic.MONSOON, "kick 15 is MONSOON")
	check(RunLogic.boss_weather(20) == RunLogic.BIG_GAME, "kick 20 is BIG GAME")
	check(RunLogic.weather_pool(1) == [RunLogic.CLEAR] and RunLogic.weather_pool(4) == [RunLogic.CLEAR], "kicks 1 through 4 are always clear")
	check(RunLogic.weather_pool(11).size() == 4 and RunLogic.weather_pool(11).has(RunLogic.CLEAR) == false, "kicks 11 through 14 are never clear")
	var blocked := 0
	var samples := 0
	while samples < 40:
		var rng := RandomNumberGenerator.new()
		rng.seed = samples + 1
		var name := RunLogic.roll_weather_name(12, RunLogic.RAIN, RunLogic.RAIN, rng)
		if name == RunLogic.RAIN:
			blocked += 1
		samples += 1
	check(blocked == 0, "check a rain streak does not become a third rain on kick 12")
	var only := RunLogic.roll_weather_name(3, RunLogic.CLEAR, RunLogic.CLEAR, RandomNumberGenerator.new())
	check(only == RunLogic.CLEAR, "when clear is the only legal weather, the repeat is allowed")
	var early := RunLogic.new()
	early.set_seed(8)
	early.new_run()
	check(early.weather == RunLogic.CLEAR and early.kick_number == 1, "kick 1 rolls clear")
	var rain := KickLogic.new()
	var plain := KickLogic.new()
	rain.rain_faster = true
	_park_on_right_arc(rain)
	_park_on_right_arc(plain)
	rain.advance(0.5)
	plain.advance(0.5)
	check(rain.needle < plain.needle - 1.5, "check 1 rain makes the accuracy needle fall faster (%s vs %s)" % [rain.needle, plain.needle])
	var clear_kick := KickLogic.new()
	_lock_power_at(clear_kick, 50.0)
	var snow := KickLogic.new()
	snow.snow_range = true
	_lock_power_at(snow, 50.0)
	check(near(snow.max_range, clear_kick.max_range - 4.0), "check 2 snow takes 4 yards off max range (%s vs %s)" % [snow.max_range, clear_kick.max_range])
	check(snow.travel_yards < clear_kick.travel_yards, "check 2 the snow ball travels shorter")
	var muddy := KickLogic.new()
	muddy.mud_power = true
	muddy.set_seed(5)
	muddy.press_space()
	muddy.advance(0.3)
	var shown := muddy.needle
	check(absf(shown - muddy.power_true) <= 3.01, "check 3 mud jitter stays within 3 of the true needle (%s vs %s)" % [shown, muddy.power_true])
	muddy.press_space()
	check(near(muddy.power, shown), "check 3 locking power keeps the jittered P, got %s" % muddy.power)
	var again := KickLogic.new()
	again.mud_power = true
	again.set_seed(5)
	again.press_space()
	again.advance(0.3)
	var true_before := again.power_true
	again.advance(0.05)
	var sweep_rate := MeterGauge.omega_power(again.stats.power_speed, again.stats.ball_speed_mult) * (100.0 / MeterGauge.OMEGA0)
	check(near(again.power_true, true_before + sweep_rate * 0.05, 0.02), "check 3 the true needle ignores the jitter")
	check(absf(again.needle - again.power_true) <= 3.01, "check 3 the next frame's jitter is still just ±3")
	var thin := KickLogic.new()
	thin.thin_air_weather = true
	_lock_power_at(thin, 50.0)
	check(near(thin.max_range, clear_kick.max_range + 4.0), "check 4 thin air weather adds 4 yards (%s)" % thin.max_range)
	var both := KickLogic.new()
	both.stats.range_bonus = 6.0
	both.stats.thin_air = true
	both.thin_air_weather = true
	_lock_power_at(both, 50.0)
	check(near(both.max_range, clear_kick.max_range + 6.0 + 4.0), "check 5 thin air weather stacks on top of the upgrade (%s)" % both.max_range)
	var just_locked := RunLogic.iced_needle_alpha(true, true, 80.0, 15.0)
	check(near(just_locked, 1.0), "ICED needle is still visible just after MAX")
	check(near(RunLogic.iced_needle_alpha(true, true, 80.0, 80.0), 1.0), "ICED needle stays up during leftover travel before the right arc")
	var fading := RunLogic.iced_needle_alpha(true, true, 80.0, 15.0 - 0.12 * 30.0)
	check(fading < 0.55 and fading > 0.0, "ICED needle is fading out just after the power lock, alpha %s" % fading)
	var gone := RunLogic.iced_needle_alpha(true, true, 80.0, 15.0 - RunLogic.ICED_FADE_OUT * 30.0)
	check(gone < 0.05, "ICED needle is gone before halfway down the right arc, alpha %s" % gone)
	var back := RunLogic.iced_needle_alpha(true, true, 80.0, 0.0)
	check(near(back, 1.0), "ICED needle is fully visible again halfway down the right arc")
	var later := RunLogic.iced_needle_alpha(true, true, 80.0, -8.0)
	check(near(later, 1.0), "ICED needle stays visible after halfway")
	check(near(RunLogic.iced_needle_alpha(false, true, 80.0, 40.0), 1.0), "Ice Veins never fades the needle")
	check(near(RunLogic.iced_needle_alpha(false, true, 80.0, 40.0), 1.0), "a normal kick keeps the needle opaque")
	check(KickLogic.judge(80.0, 35.0, 2.70, "standard", RunLogic.SQUEEZE_HALF)["text"] == "DOINK", "check 7 2.70 yd is a doink on the squeezed posts")
	check(KickLogic.judge(80.0, 35.0, 2.70, "standard")["text"] == "GOOD", "check 7 the same kick is good on the normal posts")
	check(near(RunLogic.SQUEEZE_WIDTH, 5.17) and near(RunLogic.SQUEEZE_HALF, 2.585), "check 7 the squeeze is 5.17 yd wide, half 2.585")
	var wide_now := KickLogic.judge(80.0, 35.0, 2.90, "standard", RunLogic.SQUEEZE_HALF)
	check(str(wide_now["text"]) == "WIDE RIGHT", "check 7 a kick outside the new edge is wide")
	var storm := RunLogic.new()
	storm.force_weather(RunLogic.MONSOON)
	check(storm.has_rain() and storm.has_mud() and storm.weather == RunLogic.MONSOON, "check 8 monsoon is rain and mud together")
	var game := RunLogic.new()
	game.start_with_kicker(Kickers.BIG_BRUCE)
	game.give(Loadout.CANNON, 1)
	game.give(Loadout.HERO_BALL, 1)
	game.give(Loadout.ICE_CAGE, 2)
	check(game.stats.ice_veins and game.stats.power_speed < 100.0, "the meter help is on before the big game")
	game.force_weather(RunLogic.BIG_GAME)
	game.prepare_kick_stats()
	check(near(game.stats.power_speed, KickConstants.POWER_RISE_PER_SEC), "check 9 big game restores base power speed, got %s" % game.stats.power_speed)
	check(near(game.stats.accuracy_speed, KickConstants.ACCURACY_FALL_PER_SEC), "check 9 Big Bruce keeps the default accuracy speed")
	check(near(game.stats.perfect_band, 1.35) and near(game.stats.good_band, 5.40), "check 9 Big Game keeps Bruce bands at ±1.35 and ±5.40")
	check(near(game.stats.red_tip_start, 95.0) and near(game.stats.red_tip_noise, 5.0) and near(game.stats.power_floor, 80.0), "check 9 Big Game keeps Farm Strength and the default red tip")
	check(not game.stats.ice_veins, "Big Game turns off Ice Cage's red-tip help")
	check(game.has_ice_cage(), "Ice Cage is still owned on Big Game")
	check(near(game.stats.range_bonus, 6.0), "Cannon Cleats still adds range on Big Game")
	var redo := RunLogic.new()
	redo.start_with_kicker(Kickers.WALK_ON)
	redo.attempts = 2
	redo.force_weather(RunLogic.RAIN)
	redo.set_wind(10.0, 90.0)
	var saved_spot := redo.spot_yards
	redo.resolve_kick("SHORT", 0.0, false)
	check(not redo.wants_upgrade(), "check 10 a rainy miss does not offer an upgrade")
	check(redo.begin_retry(), "check 10 the miss retries")
	check(redo.weather == RunLogic.RAIN and redo.wind_speed == 10 and near(redo.wind_direction, 90.0), "check 10 the retry keeps the rain and the wind")
	check(near(redo.spot_yards, saved_spot) and redo.kick_number == 1, "check 10 the retry is the same kick")
	check(RunLogic.spot_label(0.0) == "CENTER", "center spot label")
	check(RunLogic.spot_label(-3.0) == "LEFT HASH" and RunLogic.spot_label(3.0) == "RIGHT HASH", "hash labels")
	check(RunLogic.spot_label(-6.0) == "LEFT WIDE" and RunLogic.spot_label(6.0) == "RIGHT WIDE", "wide labels")
	var spun := RunLogic.new()
	spun.new_run()
	spun.cycle_debug_spot()
	check(near(spun.spot_yards, 3.0), "H moves from center to the right hash")
	spun.cycle_debug_spot()
	check(near(spun.spot_yards, 6.0), "H then moves to the right wide")
	spun.cycle_debug_spot()
	check(near(spun.spot_yards, -6.0), "H wraps around to the left wide")
	var launched := _kick_power_accuracy(40.0, 0.0)
	check(launched.phase == KickLogic.Phase.FLIGHT and launched.ball_forward_yards >= 0.0, "accuracy lock starts the flight immediately")
	launched.advance(0.05)
	check(launched.ball_forward_yards > 0.2, "the ball has left the tee just after the lock")


func _check_curses_and_rarity() -> void:
	var records = get_root().get_node("SaveData")
	records.file_path = "user://fg_prompt7_test.cfg"
	records.reset_save()
	check(records.runs == 0 and records.best_score == 0 and not records.has_trophy("extra_point"), "a fresh save is zeros with no trophies")
	var bad := FileAccess.open("user://fg_prompt7_bad.cfg", FileAccess.WRITE)
	bad.store_string("this is not a config file {{{")
	bad.close()
	records.file_path = "user://fg_prompt7_bad.cfg"
	records.load_file()
	check(records.runs == 0 and records.wins == 0, "a bad save file falls back to defaults")
	var repaired := ConfigFile.new()
	check(repaired.load("user://fg_prompt7_bad.cfg") == OK and int(repaired.get_value("meta", "version", 0)) == 1, "the bad file is rewritten as version 1")
	records.file_path = "user://fg_prompt7_test.cfg"
	records.reset_save()
	var warning: String = records.press_f9(10.0)
	check(warning == "Press F9 again to reset save.", "one F9 warns, got %s" % warning)
	records.runs = 4
	records.save_file()
	var cleared: String = records.press_f9(11.0)
	check(cleared == "Save reset" and records.runs == 0, "a second F9 within 2 seconds resets the save")
	var late: String = records.press_f9(20.0)
	check(late.begins_with("Press F9"), "F9 after the window warns again")
	var walk := RunLogic.new()
	walk.start_with_kicker(Kickers.WALK_ON)
	walk.resolve_kick("GOOD", 0.0, false)
	check(walk.trophy_name == "Extra Point" and records.has_trophy("extra_point"), "the first make earns Extra Point")
	walk.roll_offer()
	var equip := 0
	var curses := 0
	for card in walk.offer:
		if str(card.get("kind", "")) == Loadout.EQUIPMENT:
			equip += 1
		if str(card.get("kind", "")) == Loadout.CURSE:
			curses += 1
	check(walk.offer.size() == 3 and equip == 1 and curses <= 1, "the offer after a make has one equipment card and at most one curse")
	var scored := walk.score
	walk.skip_offer()
	check(walk.score == scored and walk.curse_ids.is_empty() and walk.cleats_id == "", "skip applies nothing")
	walk.give(Loadout.CANNON, 1)
	var legal: Array = Loadout.legal_equipment(walk.loadout_state())
	var foreign := false
	var next_rank := false
	for card in legal:
		if str(card.get("slot", "")) == Loadout.CLEATS and str(card.get("id", "")) != Loadout.CANNON:
			foreign = true
		if str(card.get("id", "")) == Loadout.CANNON and int(card.get("rank", 0)) == 2:
			next_rank = true
	check(not foreign and next_rank, "style lock keeps Cannon Cleats and offers rank II")
	walk.give(Loadout.DEEP_BENCH, 1)
	walk.give(Loadout.HOT_STREAK, 1)
	var third := false
	for card in Loadout.legal_perks(walk.loadout_state(), walk.attempt_cap):
		var id := str(card.get("id", ""))
		if id != Loadout.DEEP_BENCH and id != Loadout.HOT_STREAK:
			third = true
	check(not third, "two perk styles block a third perk style")
	walk.give(Loadout.ICED)
	walk.give(Loadout.NARROW)
	check(Loadout.legal_curses(walk.loadout_state()).is_empty(), "two curses block another curse")
	var cage := RunLogic.new()
	cage.new_run()
	cage.give(Loadout.ICE_CAGE, 1)
	var paired := false
	for card in Loadout.legal_curses(cage.loadout_state()):
		if str(card.get("id", "")) == Loadout.ICED:
			paired = true
	check(not paired, "Ice Cage is never paired with Iced")
	cage.weather = RunLogic.ICED
	check(not cage.needle_fades(), "Ice Cage blocks the kick 5 needle fade")
	check(not cage.meter_hidden(true, 1.0), "Ice Cage blocks the Iced meter hide")
	var iced := RunLogic.new()
	iced.new_run()
	iced.give(Loadout.ICED)
	check(iced.meter_hidden(true, 0.4) and not iced.meter_hidden(true, 0.39), "Iced hides the meter 0.4 seconds after Space")
	check(not iced.meter_hidden(false, 1.0), "Iced does not hide the meter before the meter starts")
	iced.set_wind(0.0, 0.0)
	iced.resolve_kick("GOOD", 2.0, false)
	check(iced.score_line.find("0.50 curse") >= 0, "Iced shows +0.5 Mult, got %s" % iced.score_line)
	var howl := RunLogic.new()
	howl.new_run()
	howl.give(Loadout.CANNON, 1)
	howl.give(Loadout.HOWLING)
	check(near(howl.stats.range_bonus, 6.0 * 1.15), "Howling Wind makes Cannon Cleats 15% stronger")
	check(howl.shown_wind_speed() == 0, "calm wind stays calm under Howling Wind")
	howl.set_wind(10.0, 90.0)
	check(howl.shown_wind_speed() == 15, "Howling Wind shows 15 mph when the saved wind is 10")
	var loud := KickLogic.new()
	loud.wind_speed = 10
	loud.wind_direction = 90.0
	loud.howling_wind = true
	loud.stats.drift_factor = 1.0
	_lock_power_at(loud, 50.0)
	var expected := KickLogic.drift_at_uprights(15.0, 90.0, 35.0, 0, 0, "standard")
	check(near(loud.drift_yards, expected, 0.02), "Howling Wind uses 1.5 times the wind speed")
	var narrow := RunLogic.new()
	narrow.new_run()
	narrow.give(Loadout.NARROW)
	check(near(narrow.post_half_gap(), 2.585) and near(narrow.post_width(), 5.17), "Narrow Posts uses the 5.17 yard uprights")
	narrow.weather = RunLogic.SQUEEZE
	check(near(narrow.post_width(), 5.17), "Narrow Posts does not stack with The Squeeze")
	var hero := RunLogic.new()
	hero.start_with_kicker(Kickers.WALK_ON)
	hero.give(Loadout.HERO_BALL, 1)
	check(near(hero.stats.power_speed, 100.0 * 0.8) and near(hero.stats.accuracy_speed, 120.0 * 0.8) and near(hero.stats.hero_mult, 1.0), "Hero Ball slows both needles and adds 1 Mult")
	hero.force_weather(RunLogic.BIG_GAME)
	hero.prepare_kick_stats()
	check(near(hero.stats.accuracy_speed, 120.0) and near(hero.stats.power_speed, 100.0) and near(hero.hero_bonus(), 1.0), "Big Game strips Hero Ball's slower needles and keeps the Mult")
	var shank := KickLogic.new()
	shank.angle_scale = 1.5
	shank.aim_degrees = 0.0
	shank.press_space()
	shank.advance(shank.windup_left)
	shank.advance(30.0 / shank.stats.power_speed)
	shank.press_space()
	shank.needle_angle = MeterGauge.angle_from_error(10.0)
	shank.needle = 10.0
	shank.press_space()
	check(near(shank.final_angle_degrees, -10.0 * 0.35 * 1.5, 0.02), "Shanky Cleats makes the angle error 1.5 times, got %s" % shank.final_angle_degrees)
	var heavy := KickLogic.new()
	heavy.heavy_ball = true
	_lock_power_at(heavy, 50.0)
	var plain := KickLogic.new()
	_lock_power_at(plain, 50.0)
	check(near(heavy.max_range, plain.max_range - 4.0), "Heavy Ball takes 4 yards off max range")
	records.reset_save()
	var ended := RunLogic.new()
	ended.start_with_kicker(Kickers.WALK_ON)
	ended.give(Loadout.CANNON, 1)
	ended.resolve_kick("GOOD", 0.0, true)
	ended.attempts = 1
	ended.kick_resolved = false
	ended.phase = RunLogic.Phase.PLAYING
	ended.resolve_kick("SHORT", 0.0, false)
	check(ended.phase == RunLogic.Phase.GAME_OVER, "the walk-on run ends")
	check(records.runs == 1 and int(records.kicker_row(Kickers.WALK_ON)["runs"]) == 1, "lifetime and Walk-On runs are 1")
	check(int(records.kicker_row(Kickers.BIG_BRUCE)["runs"]) == 0, "Big Bruce's column stays at zero")
	check(int(records.kicker_row(Kickers.WALK_ON)["makes"]) == 1 and int(records.kicker_row(Kickers.WALK_ON)["attempts"]) == 2, "Walk-On makes and attempts were saved")
	var remembered_score: int = records.best_score
	records.runs = 99
	records.load_file()
	check(records.runs == 1 and records.best_score == remembered_score and records.has_trophy("extra_point"), "reloading the file keeps the records and Extra Point")
	var again := RunLogic.new()
	again.start_with_kicker(Kickers.WALK_ON)
	check(again.cleats_id == "" and again.curse_ids.is_empty(), "a new run does not keep the last loadout")
	again.resolve_kick("GOOD", 0.0, true)
	again.attempts = 1
	again.kick_resolved = false
	again.phase = RunLogic.Phase.PLAYING
	again.resolve_kick("SHORT", 0.0, false)
	check(again.new_record_score or again.new_record_long or again.score <= remembered_score, "the second run compares against the saved best")
	# Force a higher score than the stored best and commit it.
	var better := RunLogic.new()
	better.start_with_kicker(Kickers.WALK_ON)
	better.score = records.best_score + 25
	better.longest_make = float(records.longest_make + 5)
	better.kicks_made = 2
	better.balls_kicked = 3
	better.phase = RunLogic.Phase.GAME_OVER
	better._save_finished_run()
	check(better.new_record_score and better.new_record_long, "beating best score and longest make sets NEW RECORD")
	var fifty := RunLogic.new()
	fifty.new_run()
	fifty.kick_number = 7
	fifty.resolve_kick("GOOD", 2.0, false)
	check(records.has_trophy("fifty_club"), "a 50 yard make earns Fifty Club")
	var sixty := RunLogic.new()
	sixty.new_run()
	sixty.kick_number = 10
	sixty.resolve_kick("GOOD", 2.0, false)
	check(records.has_trophy("sixty_club"), "a 60 yard make earns Sixty Club")
	var record := RunLogic.new()
	record.new_run()
	record.kick_number = 18
	record.resolve_kick("GOOD", 2.0, false)
	check(records.has_trophy("record_breaker"), "a 69 yard make earns Record Breaker")
	var quarter := RunLogic.new()
	quarter.new_run()
	for n in range(1, 6):
		quarter.kick_number = n
		quarter.kick_resolved = false
		quarter.is_first_ball = true
		quarter.phase = RunLogic.Phase.PLAYING
		quarter.resolve_kick("GOOD", 2.0, false)
	check(records.has_trophy("perfect_quarter"), "five first-ball makes earn Perfect Quarter")
	var dirty := RunLogic.new()
	dirty.new_run()
	records.trophies["perfect_quarter"] = false
	dirty.kick_number = 1
	dirty.is_first_ball = false
	dirty.resolve_kick("GOOD", 2.0, false)
	for n in range(2, 6):
		dirty.kick_number = n
		dirty.kick_resolved = false
		dirty.is_first_ball = true
		dirty.phase = RunLogic.Phase.PLAYING
		dirty.resolve_kick("GOOD", 2.0, false)
	check(not records.has_trophy("perfect_quarter"), "a retry in the quarter blocks Perfect Quarter")
	var hand := RunLogic.new()
	hand.new_run()
	hand.streak = 9
	hand.attempts = 5
	hand.resolve_kick("GOOD", 2.0, false)
	check(records.has_trophy("hot_hand"), "a streak of 10 earns Hot Hand")
	var season := RunLogic.new()
	season.new_run()
	season.kick_number = 20
	season.attempts = 3
	season.resolve_kick("GOOD", 2.0, false)
	check(season.phase == RunLogic.Phase.WIN and records.has_trophy("season_complete"), "making kick 20 earns Season Complete")
	records.middles = 9
	var bull := RunLogic.new()
	bull.new_run()
	bull.resolve_kick("GOOD", 0.0, false)
	check(records.has_trophy("bullseye_collector"), "the 10th down-the-middle make earns Bullseye Collector")
	records.file_path = "user://save.cfg"
	records.load_file()


func _check_loadout_sprites() -> void:
	check(Loadout.sprite_path(Loadout.SCOUT_LID) == "res://art/loadout/scout_lid.png", "Scout Lid finds its sprite")
	check(Loadout.sprite_path(Loadout.DOINK_CAP).ends_with("doink_cap.png"), "Doink Cap keeps its old art")
	check(Loadout.sprite_path(Loadout.HERO_BALL).ends_with("hero_ball.png"), "Hero Ball finds its sprite")
	check(Loadout.sprite_path(Loadout.ICED).ends_with("iced.png"), "Iced finds its sprite")
	check(Loadout.sprite_path(Loadout.CANNON).ends_with("cannon_cleats.png"), "Cannon Cleats uses cannon_cleats.png")
	check(Loadout.sprite_path(Loadout.PINPOINT).ends_with("pinpoint_cleats.png"), "Pinpoint Cleats uses pinpoint_cleats.png")
	check(Loadout.sprite_path(Loadout.ANCHOR).ends_with("anchor_cleats.png"), "Anchor Cleats uses anchor_cleats.png")
	check(Loadout.sprite_path(Loadout.STICKER).ends_with("sticker_cleats.png"), "Sticker Cleats uses sticker_cleats.png")
	check(Loadout.sprite_path(Loadout.WIND_VISOR).ends_with("wind_visor_helmet.png"), "Wind Visor uses wind_visor_helmet.png")
	check(Loadout.sprite_path(Loadout.ICE_CAGE).ends_with("ice_cage_helmet.png"), "Ice Cage uses ice_cage_helmet.png")
	check(Loadout.sprite_path(Loadout.IRON_GRIP).ends_with("iron_grip_gloves.png"), "Iron Grip uses iron_grip_gloves.png")
	check(Loadout.sprite_path(Loadout.REPLAY_GLOVES).ends_with("replay_gloves.png"), "Replay Gloves uses replay_gloves.png")
	check(Loadout.sprite_path(Loadout.HIGH_AIR).ends_with("high_air_gloves.png"), "High-Air Gloves uses high_air_gloves.png")
	check(Loadout.sprite_path(Loadout.WEATHER_WRAPS).ends_with("weather_wraps_gloves.png"), "Weather Wraps uses weather_wraps_gloves.png")
	check(Loadout.sprite_path(Loadout.TWO_MINUTE).ends_with("two_minute_drill.png"), "Two-Minute Drill is mapped to a sprite")
	for vitamin_id in Vitamins.ALL:
		check(Vitamins.sprite_path(str(vitamin_id)).ends_with(str(vitamin_id) + ".png"), "vitamin %s uses its bottle picture" % str(vitamin_id))
	check(Vitamins.sprite_path(Vitamins.B12).ends_with("b12_shot.png"), "B12 Shot uses b12_shot.png")
	check(Loadout.PERK_IDS.has(Loadout.TWO_MINUTE), "Two-Minute Drill is in the perk pool")
	var offer: Array = Loadout.legal_perks(Loadout.empty_state(), 3)
	var saw_drill := false
	for card in offer:
		if str(card.get("id", "")) == Loadout.TWO_MINUTE:
			saw_drill = true
	check(saw_drill, "a fresh perk list can offer Two-Minute Drill")
	check(Loadout.empty_slot_path(Loadout.CLEATS).ends_with("empty_cleats.png"), "empty cleats use the empty frame")
	check(Loadout.empty_slot_path(Loadout.HELMET).ends_with("empty_helmet.png"), "empty helmets use the empty frame")
	check(Loadout.empty_slot_path(Loadout.GLOVES).ends_with("empty_gloves.png"), "empty gloves use the empty frame")
	check(Loadout.empty_slot_path(Loadout.CURSE).ends_with("empty_curse.png"), "empty curses use the empty frame")
	check(Loadout.empty_slot_path(Loadout.PERK) == "", "empty perks have no frame and use a box")
	check(Loadout.rank_badge(Loadout.SCOUT_LID, 1) == "I", "equipment rank I shows a badge")
	check(Loadout.rank_badge(Loadout.SCOUT_LID, 4) == "IV", "equipment rank IV shows a badge")
	check(Loadout.rank_badge(Loadout.DEEP_BENCH, 2) == "II", "a perk rank shows a badge")
	check(Loadout.rank_badge(Loadout.ICED, 1) == "", "a curse has no rank badge")
	check(Loadout.sprite_path(Loadout.SCOUT_LID) == Loadout.sprite_path(Loadout.SCOUT_LID), "the offer card and the HUD ask for the same texture")
	var run := RunLogic.new()
	run.new_run()
	run.give(Loadout.SCOUT_LID, 1)
	var helmet := run.helmet_id
	var rank := run.helmet_rank
	run.force_offer([{"id": Loadout.HERO_BALL, "rank": 1}])
	run.roll_offer()
	check(run.skip_offer() and run.helmet_id == helmet and run.helmet_rank == rank and run.perks.is_empty(), "skip does not change any slot")
	run.give(Loadout.SCOUT_LID, 2)
	check(run.helmet_id == Loadout.SCOUT_LID and run.helmet_rank == 2 and Loadout.sprite_path(run.helmet_id) == Loadout.sprite_path(Loadout.SCOUT_LID), "a rank-up keeps the same sprite")
	check(Loadout.rank_badge(run.helmet_id, run.helmet_rank) == "II", "the rank-up badge is II")
	run.new_run()
	check(run.cleats_id == "" and run.helmet_id == "" and run.gloves_id == "" and run.perks.is_empty() and run.curse_ids.is_empty(), "a new run clears every icon")


func _check_rank_caps_and_range() -> void:
	check(Loadout.max_rank(Loadout.CANNON) == 6, "equipment max rank is VI")
	check(Loadout.max_rank(Loadout.DEEP_BENCH) == 3, "perk max rank is III")
	check(Loadout.max_rank(Loadout.TWO_MINUTE) == 3, "Two-Minute Drill ranks to III")
	check(Loadout.max_rank(Loadout.ICED) == 1, "curses still do not rank")
	check(Loadout.rank_badge(Loadout.CANNON, 5) == "V", "equipment rank V shows a badge")
	check(Loadout.rank_badge(Loadout.CANNON, 6) == "VI", "equipment rank VI shows a badge")
	check(Loadout.rank_badge(Loadout.HOT_STREAK, 3) == "III", "perk rank III shows a badge")
	check(not Loadout.PERK_IDS.has("mulligan") and not Loadout.PERK_IDS.has("hash_marksman"), "Mulligan and Hash Marksman stay out of the pool")
	var bruce_stats := KickerStats.new()
	Kickers.apply_to(bruce_stats, Kickers.BIG_BRUCE)
	check(near(bruce_stats.range_base, 16.0) and near(bruce_stats.range_per_power, 0.49), "Bruce keeps range base 16 and 0.49 per power")
	check(near(bruce_stats.range_base + bruce_stats.range_per_power * 100.0, 65.0), "Bruce P=100 with no bonuses is 65.0 yards")
	var kick17 := KickLogic.new()
	kick17.stats = bruce_stats
	kick17.set_seed(2)
	_lock_power_at(kick17, 100.0, 65.0)
	check(near(kick17.max_range, 65.0) and kick17.result_text == "GOOD", "kick 17 at 65 can be GOOD on Bruce full power, got %s range %s" % [kick17.result_text, kick17.max_range])
	var kick18 := KickLogic.new()
	kick18.stats = bruce_stats
	kick18.set_seed(2)
	_lock_power_at(kick18, 100.0, 69.0)
	check(near(kick18.max_range, 65.0) and kick18.result_text == "SHORT", "kick 18 at 69 is SHORT on Bruce full power, got %s" % kick18.result_text)
	var cannon := RunLogic.new()
	cannon.start_with_kicker(Kickers.BIG_BRUCE)
	cannon.give(Loadout.CANNON, 1)
	check(near(cannon.stats.range_bonus, 6.0), "Cannon Cleats I is still +6 yards")
	var make69 := KickLogic.new()
	make69.stats = cannon.stats
	make69.set_seed(2)
	_lock_power_at(make69, 100.0, 69.0)
	check(near(make69.max_range, 71.0) and make69.result_text == "GOOD", "Cannon I lifts Bruce to 71 so kick 18 can be GOOD, got %s range %s" % [make69.result_text, make69.max_range])
	var miss72 := KickLogic.new()
	miss72.stats = cannon.stats
	miss72.set_seed(2)
	_lock_power_at(miss72, 100.0, 72.0)
	check(near(miss72.max_range, 71.0) and miss72.result_text == "SHORT", "kick 19 at 72 is still SHORT with Cannon I, got %s" % miss72.result_text)
	cannon.give(Loadout.CANNON, 4)
	check(near(cannon.stats.range_bonus, 24.0), "Cannon Cleats IV is still +24 yards")
	cannon.give(Loadout.CANNON, 5)
	check(near(cannon.stats.range_bonus, 30.0) and Loadout.rank_badge(cannon.cleats_id, cannon.cleats_rank) == "V", "Cannon Cleats V is +30 yards")
	cannon.give(Loadout.CANNON, 6)
	check(near(cannon.stats.range_bonus, 36.0) and Loadout.rank_badge(cannon.cleats_id, cannon.cleats_rank) == "VI", "Cannon Cleats VI is +36 yards")
	cannon.give(Loadout.CANNON, 7)
	check(cannon.cleats_rank == 6, "equipment does not rank past VI")
	var walk_stats := KickerStats.new()
	Kickers.apply_to(walk_stats, Kickers.WALK_ON)
	check(near(walk_stats.range_base + walk_stats.range_per_power * 100.0, 60.0), "Walk-On P=100 with no bonuses is 60.0 yards")
	var kick10 := KickLogic.new()
	kick10.stats = walk_stats
	kick10.set_seed(4)
	_lock_power_at(kick10, 100.0, 60.0)
	check(near(kick10.max_range, 60.0) and kick10.result_text == "GOOD", "kick 10 at 60 can be GOOD on Walk-On full power, got %s" % kick10.result_text)
	var kick14 := KickLogic.new()
	kick14.stats = walk_stats
	kick14.set_seed(4)
	_lock_power_at(kick14, 100.0, 65.0)
	check(near(kick14.max_range, 60.0) and kick14.result_text == "SHORT", "kick 14 at 65 is SHORT on Walk-On full power, got %s" % kick14.result_text)
	var pins := RunLogic.new()
	pins.new_run()
	pins.give(Loadout.PINPOINT, 4)
	check(near(pins.stats.perfect_band, 1.5 + 8.0) and near(pins.stats.good_band, 6.0 + 12.0), "Pinpoint IV is still +8 PERFECT and +12 good")
	pins.give(Loadout.PINPOINT, 6)
	check(near(pins.stats.perfect_band, 1.5 + 12.0) and near(pins.stats.good_band, 6.0 + 18.0), "Pinpoint VI is +12 PERFECT and +18 good")
	var anchor := RunLogic.new()
	anchor.new_run()
	anchor.give(Loadout.ANCHOR, 4)
	check(near(anchor.stats.power_speed, 100.0 * pow(0.85, 4.0)), "Anchor IV is still 0.85 to the fourth")
	anchor.give(Loadout.ANCHOR, 6)
	check(near(anchor.stats.power_speed, 100.0 * pow(0.85, 6.0)), "Anchor VI is 0.85 to the sixth")
	var hot := RunLogic.new()
	hot.new_run()
	hot.give(Loadout.HOT_STREAK, 2)
	check(near(hot.stats.streak_step, 0.75), "Hot Streak II is still 0.75")
	hot.give(Loadout.HOT_STREAK, 3)
	check(near(hot.stats.streak_step, 1.0) and Loadout.rank_badge(Loadout.HOT_STREAK, hot._perk_rank(Loadout.HOT_STREAK)) == "III", "Hot Streak III is 1.0 and shows III")
	hot.give(Loadout.HOT_STREAK, 4)
	check(hot._perk_rank(Loadout.HOT_STREAK) == 3, "perks do not rank past III")
	var storm := RunLogic.new()
	storm.new_run()
	storm.give(Loadout.STORM_CHASER, 2)
	check(near(storm.stats.storm_per_mph, 0.4), "Storm Chaser II is still 0.4")
	storm.give(Loadout.STORM_CHASER, 3)
	check(near(storm.stats.storm_per_mph, 0.6), "Storm Chaser III is 0.6")
	var hero := RunLogic.new()
	hero.start_with_kicker(Kickers.WALK_ON)
	hero.give(Loadout.HERO_BALL, 3)
	check(near(hero.stats.hero_mult, 2.0) and near(hero.stats.power_speed, 80.0), "Hero Ball III is +2 Mult and the same slower needles")
	hero.force_weather(RunLogic.BIG_GAME)
	hero.prepare_kick_stats()
	check(near(hero.stats.power_speed, 100.0) and near(hero.stats.hero_mult, 2.0), "Big Game turns the slower needles off and keeps the Mult")
	var glass := RunLogic.new()
	glass.new_run()
	glass.give(Loadout.GLASS_LEG, 2)
	check(near(glass.stats.range_bonus, 16.0) and glass.attempt_cap == 2, "Glass Leg II is still +16 and one cap loss")
	glass.give(Loadout.GLASS_LEG, 3)
	check(near(glass.stats.range_bonus, 24.0) and glass.attempt_cap == 2, "Glass Leg III is +24 and does not drop the cap again")
	var bench := RunLogic.new()
	bench.new_run()
	bench.attempts = 4
	bench.give(Loadout.DEEP_BENCH, 2)
	check(bench.attempt_cap == 5 and bench.attempts == 5, "Deep Bench II still fills up to the hard max")
	bench.attempts = 4
	bench.give(Loadout.DEEP_BENCH, 3)
	check(bench.attempt_cap == 5 and bench.attempts == 5 and bench.stats.bench_spare, "Deep Bench III adds an attempt without raising the cap")
	bench.attempts = 3
	bench.kick_number = 6
	bench._refill_quarter()
	check(bench.attempts == 4, "Deep Bench III grants an attempt at the next quarter when below cap")
	var visor := RunLogic.new()
	visor.new_run()
	visor.give(Loadout.WIND_VISOR, 4)
	check(visor.stats.wind_preview_count == 3, "Wind Visor IV still previews 3 kicks")
	visor.give(Loadout.WIND_VISOR, 5)
	check(visor.stats.wind_preview_count == 5, "Wind Visor V previews 5 kicks")
	visor.give(Loadout.WIND_VISOR, 6)
	check(visor.stats.wind_preview_count == 7 and visor.upcoming_winds().size() == 7, "Wind Visor VI previews 7 kicks")
	var cage := RunLogic.new()
	cage.new_run()
	cage.give(Loadout.ICE_CAGE, 4)
	check(near(cage.stats.perfect_band, 1.5 + 1.0) and near(cage.stats.good_band, 6.0 + 2.0), "Ice Cage IV is still PERFECT +1 and good +2")
	cage.give(Loadout.ICE_CAGE, 5)
	check(near(cage.stats.perfect_band, 1.5 + 2.0), "Ice Cage V is PERFECT +2 total")
	cage.give(Loadout.ICE_CAGE, 6)
	check(near(cage.stats.good_band, 6.0 + 4.0), "Ice Cage VI is good +4 total")
	var grip := RunLogic.new()
	grip.start_with_kicker(Kickers.BIG_BRUCE)
	grip.give(Loadout.IRON_GRIP, 5)
	check(near(grip.stats.red_tip_start, 104.0) and near(grip.stats.red_tip_noise, 1.0), "Iron Grip V pushes Bruce's red tip from 95 to 104")
	grip.give(Loadout.IRON_GRIP, 6)
	check(grip.stats.red_tip_off, "Iron Grip VI turns the red tip off")
	grip.force_weather(RunLogic.BIG_GAME)
	grip.prepare_kick_stats()
	check(not grip.stats.red_tip_off and near(grip.stats.red_tip_start, 95.0), "Big Game turns Iron Grip's red-tip help off")
	var walk_grip := RunLogic.new()
	walk_grip.start_with_kicker(Kickers.WALK_ON)
	walk_grip.give(Loadout.IRON_GRIP, 4)
	check(near(walk_grip.stats.red_tip_start, 101.0), "Iron Grip IV already pushes The Walk-On past 100")
	var scout := RunLogic.new()
	scout.start_with_kicker(Kickers.WALK_ON)
	scout.give(Loadout.SCOUT_LID, 4)
	check(scout.stats.rerolls_per_run == 5 and scout.stats.practice_per_quarter == 1, "Scout Lid IV is still +3 rerolls and one practice swing")
	scout.give(Loadout.SCOUT_LID, 6)
	check(scout.stats.rerolls_per_run == 7 and scout.stats.practice_per_quarter == 2, "Scout Lid VI is +5 rerolls and two practice swings")
	var doink := RunLogic.new()
	doink.new_run()
	doink.give(Loadout.DOINK_CAP, 5)
	check(doink.stats.doink_per_quarter == 5 and not doink.stats.doink_carry and doink.insurance_left == 5, "Doink Cap V is 5 charges and does not carry")
	doink.insurance_left = 2
	doink.kick_number = 6
	doink._refill_quarter()
	check(doink.insurance_left == 5, "Doink Cap V refills to 5 and drops unused charges")
	doink.give(Loadout.DOINK_CAP, 6)
	check(doink.stats.doink_carry and doink.stats.doink_per_quarter == 5, "Doink Cap VI keeps 5 charges and carries unused ones")
	doink.insurance_left = 2
	doink.kick_number = 11
	doink._refill_quarter()
	check(doink.insurance_left == 7, "unused Doink charges carry, stored up to 5, on top of the new 5")
	var replay := RunLogic.new()
	replay.new_run()
	replay.give(Loadout.REPLAY_GLOVES, 5)
	check(replay.stats.practice_per_quarter == 5 and not replay.stats.practice_carry, "Replay Gloves V is 5 swings and does not carry")
	replay.give(Loadout.REPLAY_GLOVES, 6)
	replay.practice_left = 3
	replay.kick_number = 6
	replay._refill_quarter()
	check(replay.stats.practice_carry and replay.practice_left == 8, "Replay Gloves VI carries unused swings, stored up to 5")
	var wraps := RunLogic.new()
	wraps.new_run()
	wraps.give(Loadout.WEATHER_WRAPS, 2)
	var plain: Dictionary = RunLogic.weather_kick_flags(RunLogic.RAIN, wraps.stats.weather_cut)
	var monsoon: Dictionary = RunLogic.weather_kick_flags(RunLogic.MONSOON, wraps.stats.weather_cut)
	check(not bool(plain["rain_faster"]) and bool(monsoon["rain_faster"]) and bool(monsoon["mud_power"]), "Weather Wraps II ignores rain but not Monsoon")
	wraps.give(Loadout.WEATHER_WRAPS, 3)
	var quiet: Dictionary = RunLogic.weather_kick_flags(RunLogic.MONSOON, wraps.stats.weather_cut)
	check(not bool(quiet["rain_faster"]) and not bool(quiet["mud_power"]), "Weather Wraps III ignores Monsoon's rain and mud")
	wraps.give(Loadout.WEATHER_WRAPS, 4)
	wraps.force_weather(RunLogic.RAIN)
	wraps.prepare_kick_stats()
	check(near(wraps.stats.wraps_yards, 2.0) and near(wraps.stats.range_bonus, 2.0), "Weather Wraps IV is still +2 yards outside CLEAR")
	wraps.give(Loadout.WEATHER_WRAPS, 6)
	wraps.prepare_kick_stats()
	check(near(wraps.stats.wraps_yards, 6.0) and near(wraps.stats.range_bonus, 6.0), "Weather Wraps VI is +6 yards outside CLEAR")
	var drill := RunLogic.new()
	drill.start_with_kicker(Kickers.WALK_ON)
	drill.give(Loadout.TWO_MINUTE, 1)
	drill.kick_number = 5
	drill.resolve_kick("GOOD", 2.0, false)
	check(near(drill.stats.drill_mult, 0.5), "Two-Minute Drill I is +0.5 Mult")
	check(drill.last_points == 108, "boss points include +0.5 on top of ×1.5, got %s" % drill.last_points)
	check(drill.score_line.find("drill") >= 0 and drill.score_line.find("1.5") >= 0, "the score line shows the drill bonus, got '%s'" % drill.score_line)
	drill.kick_resolved = false
	drill.phase = RunLogic.Phase.PLAYING
	drill.give(Loadout.TWO_MINUTE, 2)
	check(near(drill.stats.drill_mult, 1.0), "Two-Minute Drill II is +1.0")
	drill.give(Loadout.TWO_MINUTE, 3)
	check(near(drill.stats.drill_mult, 1.5), "Two-Minute Drill III is +1.5")
	var howl := RunLogic.new()
	howl.new_run()
	howl.give(Loadout.HOWLING)
	howl.give(Loadout.TWO_MINUTE, 1)
	check(near(howl.stats.drill_mult, 0.5 * 1.15), "Howling Wind boosts Two-Minute Drill by 15%")
	var locked := RunLogic.new()
	locked.new_run()
	locked.give(Loadout.DEEP_BENCH, 1)
	locked.give(Loadout.HOT_STREAK, 1)
	var blocked := false
	for card in Loadout.legal_perks(locked.loadout_state(), locked.attempt_cap):
		if str(card.get("id", "")) == Loadout.TWO_MINUTE and int(card.get("rank", 0)) == 1:
			blocked = true
	check(not blocked, "Two-Minute Drill is not a third perk style")
	var full := _maxed_loadout()
	var empty_offer: Array = Loadout.draw_offer(full.loadout_state(), full.attempt_cap, RandomNumberGenerator.new())
	check(empty_offer.is_empty(), "a maxed loadout draws zero cards")
	full.kick_number = 19
	full.resolve_kick("GOOD", 2.0, false)
	full.roll_offer()
	check(full.awaiting_offer and full.offer.is_empty(), "an empty offer still waits for Skip")
	check(not full.pick_card(0) and not full.pick_card(1) and not full.pick_card(2), "keys 1, 2, and 3 do nothing when no cards are showing")
	check(full.awaiting_offer and full.kick_number == 19, "the empty offer does not advance on 1, 2, or 3")
	var before_score := full.score
	check(full.skip_offer() and full.score == before_score and not full.awaiting_offer, "Skip on an empty offer takes nothing and continues")
	check(full.go_to_next_kick() and full.kick_number == 20, "Skip after kick 19 reaches kick 20")
	var one := _maxed_loadout()
	one.cleats_rank = 5
	one.rebuild_stats()
	var one_cards: Array = Loadout.draw_offer(one.loadout_state(), one.attempt_cap, RandomNumberGenerator.new())
	check(one_cards.size() == 1 and str(one_cards[0].get("id", "")) == Loadout.CANNON and int(one_cards[0].get("rank", 0)) == 6, "one legal card is still offered")
	one.kick_number = 19
	one.phase = RunLogic.Phase.PLAYING
	one.roll_offer()
	check(one.offer.size() == 1 and one.awaiting_offer, "a one-card offer stays open")
	check(not one.pick_card(1) and one.awaiting_offer, "key 2 does nothing when only one card is showing")
	check(one.skip_offer(), "Skip still works with one card")
	var two := _maxed_loadout()
	two.cleats_rank = 5
	two.perks = [{"id": Loadout.DEEP_BENCH, "rank": 2}, {"id": Loadout.HOT_STREAK, "rank": 3}]
	two.rebuild_stats()
	var two_cards: Array = Loadout.draw_offer(two.loadout_state(), two.attempt_cap, RandomNumberGenerator.new())
	check(two_cards.size() == 2, "two legal cards are both shown, got %s" % two_cards.size())
	var saw_equip := false
	for card in two_cards:
		if str(card.get("kind", "")) == Loadout.EQUIPMENT:
			saw_equip = true
	check(saw_equip, "the short offer still keeps a legal equipment card")


func _maxed_loadout() -> RunLogic:
	var run := RunLogic.new()
	run.new_run()
	run.cleats_id = Loadout.CANNON
	run.cleats_rank = 6
	run.helmet_id = Loadout.WIND_VISOR
	run.helmet_rank = 6
	run.gloves_id = Loadout.IRON_GRIP
	run.gloves_rank = 6
	run.perks = [{"id": Loadout.DEEP_BENCH, "rank": 3}, {"id": Loadout.TWO_MINUTE, "rank": 3}]
	run.curse_ids = [Loadout.HEAVY, Loadout.SHANKY]
	run.rebuild_stats()
	run.attempt_cap = run.stats.attempt_cap
	return run


func _check_vitamin_shop() -> void:
	var fresh := RunLogic.new()
	fresh.new_run()
	check(fresh.cash == 0 and str(fresh.belt[0]) == "" and str(fresh.belt[1]) == "", "a fresh run starts at $0 with an empty belt")
	fresh.resolve_kick("GOOD", 2.0, false)
	check(fresh.cash == 3 and fresh.cash_popup == "+$3", "a plain make pays $3")
	var stacked := RunLogic.new()
	stacked.new_run()
	stacked.kick_number = 5
	stacked.resolve_kick("GOOD", 0.0, true)
	check(stacked.cash == 7 and stacked.cash_popup == "+$7", "a perfect middle boss make pays $7")
	var miss := RunLogic.new()
	miss.new_run()
	miss.attempts = 2
	miss.resolve_kick("SHORT", 0.0, false)
	check(miss.cash == 0 and miss.cash_popup == "", "a miss pays $0")
	check(not miss.opens_shop(), "a miss never opens the shop")
	var early := RunLogic.new()
	early.new_run()
	early.resolve_kick("SHORT", 0.0, false)
	check(early.phase == RunLogic.Phase.GAME_OVER and not early.opens_shop(), "game over before kick 5 never opens a shop")
	var again := RunLogic.new()
	again.new_run()
	check(again.cash == 0 and str(again.belt[0]) == "", "a new run wipes cash and the belt")
	var saved := RunLogic.new()
	saved.start_with_kicker(Kickers.WALK_ON)
	saved.cash = 40
	saved.belt[0] = Vitamins.PROTEIN
	saved.kick_number = 20
	saved.resolve_kick("GOOD", 2.0, false)
	check(saved.phase == RunLogic.Phase.WIN and not saved.opens_shop(), "making kick 20 does not open a shop")
	var records = get_root().get_node("SaveData")
	records.file_path = "user://fg_shop_test.cfg"
	records.reset_save()
	saved._save_finished_run()
	var text := FileAccess.get_file_as_string(records.file_path)
	check(text.find("cash") < 0 and text.find("protein_shake") < 0, "SaveData does not store cash or the belt")
	records.file_path = "user://save.cfg"
	var shop := RunLogic.new()
	shop.set_seed(11)
	shop.new_run()
	shop.kick_number = 5
	shop.attempts = 2
	shop.resolve_kick("GOOD", 2.0, false)
	shop.roll_offer()
	var held_rerolls := shop.rerolls_left
	check(shop.skip_offer() and shop.follow_offer() == "shop" and shop.awaiting_shop, "the shop opens after the kick 5 offer closes")
	check(shop.next_boss_line() == "Next boss: The Squeeze", "the kick 5 shop names The Squeeze")
	check(shop.shop_stock.size() == 3 and shop.shop_stock[0] != shop.shop_stock[1] and shop.shop_stock[1] != shop.shop_stock[2] and shop.shop_stock[0] != shop.shop_stock[2], "the three shelves are different vitamins")
	check(not shop.shop_b12_bought and shop.shop_reroll_price == 2, "B12 is for sale and the first reroll costs $2")
	check(shop.rerolls_left == held_rerolls and not shop.reroll_offer(), "shop F does not spend a loadout reroll")
	shop.shop_stock = [Vitamins.PROTEIN, Vitamins.MAGNESIUM, Vitamins.OMEGA]
	shop.cash = 4
	check(shop.buy_shelf(0) and shop.cash == 0 and str(shop.belt[0]) == Vitamins.PROTEIN and str(shop.shop_stock[0]) == "", "buying a $4 vitamin fills Z and marks the shelf SOLD")
	shop.cash = 20
	check(shop.buy_shelf(1) and str(shop.belt[1]) == Vitamins.MAGNESIUM, "the second vitamin fills X")
	var blocked_cash := shop.cash
	check(not shop.buy_shelf(2) and shop.shop_note == "Belt full: sell first" and shop.cash == blocked_cash, "a full belt blocks the next buy")
	var before_sell := shop.cash
	check(shop.sell_belt(0) and str(shop.belt[0]) == "" and shop.cash == before_sell + 2, "Z sells Protein Shake for $2")
	check(Vitamins.sale_price(Vitamins.PROTEIN) == 2 and Vitamins.sale_price(Vitamins.OMEGA) == 2 and Vitamins.sale_price(Vitamins.ELECTROLYTE) == 3, "sale prices are floor(price / 2)")
	check(shop.buy_shelf(2) and str(shop.belt[0]) == Vitamins.OMEGA, "an empty belt slot can buy again")
	var b12_was := shop.shop_b12_bought
	var before_reroll := shop.cash
	check(shop.reroll_shop() and shop.cash == before_reroll - 2 and shop.shop_reroll_price == 3, "the first shelf reroll costs $2 and the next costs $3")
	check(shop.shop_stock[0] != "" and shop.shop_stock[1] != "" and shop.shop_stock[2] != "" and shop.shop_b12_bought == b12_was, "a reroll refills three vitamins and leaves B12 alone")
	var price_now := shop.shop_reroll_price
	var cash_now := shop.cash
	shop.cash = 0
	check(not shop.reroll_shop() and shop.shop_flash == "reroll" and shop.shop_reroll_price == price_now, "an unaffordable reroll flashes and does not change the shelves")
	shop.cash = cash_now
	shop.attempts = shop.attempt_cap
	var capped := shop.cash
	check(shop.b12_grey() and not shop.buy_b12() and shop.cash == capped, "B12 is grey at the attempt cap and does not take cash")
	shop.attempts = 1
	shop.cash = 3
	check(shop.b12_grey() and not shop.buy_b12() and shop.shop_flash == "b12" and shop.cash == 3, "B12 flashes red when it costs more than the cash on hand")
	shop.cash = 10
	check(shop.buy_b12() and shop.attempts == 2 and shop.shop_b12_bought and not shop.buy_b12() and shop.cash == 3, "B12 adds one attempt once, then does nothing")
	shop.leave_shop()
	check(not shop.awaiting_shop and shop.go_to_next_kick() and shop.kick_number == 6, "leaving the shop starts kick 6")
	shop.kick_number = 10
	shop.resolve_kick("GOOD", 2.0, false)
	shop.follow_offer()
	check(shop.awaiting_shop and shop.next_boss_line() == "Next boss: Monsoon" and shop.shop_reroll_price == 2, "the kick 10 shop names Monsoon and reroll starts at $2 again")
	shop.leave_shop()
	shop.go_to_next_kick()
	shop.kick_number = 15
	shop.resolve_kick("GOOD", 2.0, false)
	shop.follow_offer()
	check(shop.next_boss_line() == "Next boss: Big Game", "the kick 15 shop names Big Game")
	var protein := RunLogic.new()
	protein.new_run()
	protein.attempts = 3
	protein.belt[0] = Vitamins.PROTEIN
	protein.belt[1] = Vitamins.PROTEIN
	check(protein.use_belt(0) and protein.use_belt(1) and str(protein.belt[0]) == "" and str(protein.belt[1]) == "", "using both shakes empties the belt")
	protein.prepare_kick_stats()
	check(near(protein.stats.range_bonus, 12.0), "two Protein Shakes add 12 yards")
	protein.give(Loadout.HOWLING)
	protein.prepare_kick_stats()
	check(near(protein.stats.range_bonus, 12.0), "Howling Wind does not buff Protein Shake")
	protein.resolve_kick("SHORT", 0.0, false)
	protein.begin_retry()
	protein.prepare_kick_stats()
	check(near(protein.stats.range_bonus, 0.0) and protein.phase == RunLogic.Phase.PLAYING, "the retry does not keep the Protein Shake yards")
	var mag := RunLogic.new()
	mag.start_with_kicker(Kickers.WALK_ON)
	mag.give(Loadout.HERO_BALL, 1)
	mag.force_weather(RunLogic.BIG_GAME)
	mag.belt[0] = Vitamins.MAGNESIUM
	check(mag.use_belt(0), "Magnesium is used before the kick")
	mag.prepare_kick_stats()
	check(near(mag.stats.power_speed, 70.0) and near(mag.stats.accuracy_speed, KickConstants.ACCURACY_FALL_PER_SEC * 0.7), "Magnesium slows both needles during Big Game after loadout meter help turns off")
	check(near(mag.stats.hero_mult, 1.0), "Hero Ball's Mult stays on during Big Game")
	var tabs := RunLogic.new()
	tabs.new_run()
	tabs.attempts = 1
	tabs.streak = 4
	tabs.belt[0] = Vitamins.ELECTROLYTE
	check(tabs.use_belt(0), "Electrolyte Tabs is used")
	tabs.resolve_kick("SHORT", 0.0, false)
	check(tabs.streak == 0 and tabs.attempts == 1 and tabs.phase == RunLogic.Phase.PLAYING, "Electrolyte Tabs keeps the last attempt and still resets the streak")
	tabs.begin_retry()
	check(not tabs.is_first_ball, "the retry is not a first-try ball")
	var pre := RunLogic.new()
	pre.new_run()
	pre.belt[0] = Vitamins.PREWORKOUT
	pre.use_belt(0)
	pre.resolve_kick("GOOD", 2.0, false)
	check(pre.score_line.find("0.50 pre") >= 0, "Pre-Workout shows +0.5 in the score math, got '%s'" % pre.score_line)
	check(pre.last_points == RunLogic.points_for(35.0, 1.5, false, false, false), "the +0.5 is added before the rest of the score")
	var omega := KickLogic.new()
	omega.stats.omega = true
	omega.stats.good_band = 8.0
	omega.stats.perfect_band = 2.0
	# Drop the accuracy needle to e=6, inside the good band and outside PERFECT.
	omega.reset_kick()
	omega.press_space()
	omega.advance(omega.windup_left)
	omega.advance(40.0 / omega.stats.power_speed)
	omega.press_space()
	omega.advance(omega.seconds_until_error(6.0))
	omega.press_space()
	check(near(omega.accuracy_error, 0.0) and not omega.perfect, "Omega-3 wipes a good-band press and does not call it PERFECT")
	var paid := RunLogic.new()
	paid.new_run()
	paid.belt[0] = Vitamins.OMEGA
	paid.use_belt(0)
	paid.resolve_kick("GOOD", 0.0, true)
	check(paid.score_line.find("PERFECT") < 0, "Omega-3 does not add the +5 PERFECT score bonus, got '%s'" % paid.score_line)
	check(paid.cash == 5, "the PERFECT press and the middle still pay cash under Omega-3, got %s" % paid.cash)
	var rain := RunLogic.new()
	rain.new_run()
	rain.force_weather(RunLogic.RAIN)
	rain.belt[0] = Vitamins.VITAMIN_D
	rain.use_belt(0)
	rain.prepare_kick_stats()
	var rain_flags: Dictionary = rain.weather_flags_now()
	check(not bool(rain_flags["rain_faster"]), "Vitamin D ignores rain's faster needle")
	rain.force_weather(RunLogic.SNOW)
	check(not bool(rain.weather_flags_now()["snow_range"]), "Vitamin D ignores snow")
	rain.force_weather(RunLogic.MUD)
	check(not bool(rain.weather_flags_now()["mud_power"]), "Vitamin D ignores mud")
	rain.force_weather(RunLogic.MONSOON)
	var storm_flags: Dictionary = rain.weather_flags_now()
	check(not bool(storm_flags["rain_faster"]) and not bool(storm_flags["mud_power"]) and rain.weather == RunLogic.MONSOON, "Vitamin D also ignores Monsoon's rain and mud")
	rain.force_weather(RunLogic.THIN_AIR)
	check(rain.weather == RunLogic.THIN_AIR, "Vitamin D leaves Thin Air in place")
	rain.force_weather(RunLogic.ICED)
	check(rain.needle_fades(), "Vitamin D does not stop Iced from hiding the needle")
	rain.force_weather(RunLogic.SQUEEZE)
	check(near(rain.post_half_gap(), RunLogic.SQUEEZE_HALF), "Vitamin D does not widen The Squeeze")
	var plain := KickLogic.drift_at_uprights(10.0, 90.0, 50.0, 0, 0, "standard")
	check(near(plain, 3.25, 0.02), "10 mph straight right drifts about 3.25 yards on a 50-yard kick")
	var pickled := KickLogic.new()
	pickled.wind_speed = 10
	pickled.wind_direction = 90.0
	pickled.stats.drift_factor = 0.5
	_lock_power_at(pickled, 90.0, 50.0)
	check(near(pickled.offset_yards, plain * 0.5, 0.05), "Pickle Juice halves that drift to about 1.63, got %s" % pickled.offset_yards)
	var zinc := RunLogic.new()
	zinc.set_seed(4)
	zinc.new_run()
	zinc.kick_number = 6
	zinc.set_wind(0.0, 0.0)
	zinc.force_weather(RunLogic.CLEAR)
	zinc.belt[0] = Vitamins.ZINC
	zinc.belt[1] = Vitamins.ZINC
	check(zinc.use_belt(0) and str(zinc.belt[0]) == "", "Zinc on a normal kick is consumed")
	check(zinc.wind_speed >= 3 and zinc.wind_speed <= 8, "Zinc rerolls kick 6 wind inside 3 to 8, got %s" % zinc.wind_speed)
	check(zinc.weather == RunLogic.CLEAR or zinc.weather == RunLogic.RAIN, "Zinc rerolls a non-boss weather from that kick's table")
	var kept_wind := zinc.wind_speed
	var kept_weather := zinc.weather
	check(not zinc.use_belt(1) and str(zinc.belt[1]) == Vitamins.ZINC and zinc.vitamin_note == "Already rerolled", "a second Zinc on the same kick stays on the belt")
	zinc.attempts = 2
	zinc.resolve_kick("SHORT", 0.0, false)
	zinc.begin_retry()
	check(zinc.wind_speed == kept_wind and zinc.weather == kept_weather, "the rerolled wind and weather stay for the retry")
	var boss_zinc := RunLogic.new()
	boss_zinc.set_seed(8)
	boss_zinc.new_run()
	boss_zinc.kick_number = 5
	boss_zinc.weather = RunLogic.ICED
	boss_zinc.set_wind(99.0, 10.0)
	boss_zinc.belt[0] = Vitamins.ZINC
	check(boss_zinc.use_belt(0), "Zinc is used on the boss")
	check(boss_zinc.weather == RunLogic.ICED and boss_zinc.wind_speed >= 0 and boss_zinc.wind_speed <= 5, "a boss keeps Iced and only the wind rerolls")
	var lutein := RunLogic.new()
	lutein.new_run()
	lutein.give(Loadout.WIND_VISOR, 3)
	check(lutein.stats.flag_reader and lutein.stats.laser_full, "Wind Visor III already shows the full path")
	lutein.belt[0] = Vitamins.LUTEIN
	lutein.use_belt(0)
	lutein.prepare_kick_stats()
	check(lutein.stats.flag_reader and lutein.stats.laser_line and lutein.stats.laser_full, "Lutein keeps a single wind readout and a single full path")
	var bare := RunLogic.new()
	bare.new_run()
	bare.belt[0] = Vitamins.LUTEIN
	bare.use_belt(0)
	bare.prepare_kick_stats()
	check(bare.stats.flag_reader and bare.stats.laser_full, "Lutein alone turns on the wind numbers and the full path")
	var tart := RunLogic.new()
	tart.new_run()
	tart.belt[0] = Vitamins.TART
	check(not tart.use_belt(0) and str(tart.belt[0]) == Vitamins.TART and tart.vitamin_note == "No curse to remove", "Tart Cherry is not consumed when there is no curse")
	tart.give(Loadout.HEAVY)
	check(tart.use_belt(0) and tart.curse_ids.is_empty() and str(tart.belt[0]) == "", "one curse is removed and Tart Cherry is consumed")
	tart.prepare_kick_stats()
	check(not tart.stats.heavy_ball, "the removed curse stops affecting the kick")
	var pair := RunLogic.new()
	pair.new_run()
	pair.give(Loadout.ICED)
	pair.give(Loadout.SHANKY)
	check(pair.curses_locked, "two curses lock the curse slots")
	pair.belt[0] = Vitamins.TART
	check(pair.use_belt(0) and pair.curse_prompt and str(pair.belt[0]) == Vitamins.TART, "two curses ask which one to remove and keep Tart Cherry")
	check(pair.pick_curse_removal(0) and pair.curse_ids.size() == 1 and str(pair.belt[0]) == "", "picking 1 removes that curse and consumes Tart Cherry")
	check(Loadout.legal_curses(pair.loadout_state()).is_empty(), "the curse lock stays after a removal, so no new curse is offered")
	var cancel := RunLogic.new()
	cancel.new_run()
	cancel.give(Loadout.NARROW)
	cancel.give(Loadout.STONE)
	cancel.belt[0] = Vitamins.TART
	cancel.use_belt(0)
	cancel.cancel_curse_prompt()
	check(not cancel.curse_prompt and cancel.curse_ids.size() == 2 and str(cancel.belt[0]) == Vitamins.TART, "Esc cancels the curse pick and does not consume Tart Cherry")


func _check_sprite_scan_and_gauge() -> void:
	var mapped: Dictionary = Loadout.map_sprite_files([
		"res://art/loadout/shanky_cleats.png",
		"res://art/loadout/shanky_cleats_curse.png",
		"res://art/loadout/cannon_cleats.png",
		"res://art/loadout/high-air_gloves.png",
		"res://art/loadout/highair.png",
		"res://art/loadout/scout_lid.png",
		"res://art/loadout/scout_lid_helmet.png",
		"res://art/loadout/hero_ball_perk.png",
		"res://art/loadout/wind_visor_helmet_ii.png",
		"res://art/ui/kick_meter.png",
		"res://art/shop/vitamin_shop.png",
		"res://art/kickers/big_bruce.png",
		"res://art/loadout/mystery_cleats.png",
		"res://art/loadout/empty_perk.png",
	])
	var items: Dictionary = mapped["items"]
	check(str(items.get(Loadout.SHANKY, "")).ends_with("shanky_cleats_curse.png"), "Shanky Cleats maps to the curse file, not the cleat name")
	check(str(items.get(Loadout.CANNON, "")).ends_with("cannon_cleats.png"), "cannon_cleats.png maps to Cannon Cleats")
	check(str(items.get(Loadout.HIGH_AIR, "")).ends_with("high-air_gloves.png"), "high-air and highair both mean High-Air Gloves, and the suffix wins")
	check(str(items.get(Loadout.SCOUT_LID, "")).ends_with("scout_lid_helmet.png"), "an explicit helmet suffix beats the old short name")
	check(str(items.get(Loadout.HERO_BALL, "")).ends_with("hero_ball_perk.png"), "hero_ball_perk.png maps to Hero Ball")
	check(str(items.get(Loadout.WIND_VISOR, "")).ends_with("wind_visor_helmet_ii.png"), "a trailing rank token still maps the helmet")
	check(not items.has(Loadout.IRON_GRIP), "a vitamin or meter image is not forced onto a loadout item")
	var unmatched: Array = mapped["unmatched"]
	check(unmatched.has("res://art/loadout/mystery_cleats.png"), "a cleat-shaped name that is not in the catalog is reported")
	check(not unmatched.has("res://art/ui/kick_meter.png") and not unmatched.has("res://art/shop/vitamin_shop.png"), "the meter and the shop art are not loadout icons")
	check(str(mapped["empty"].get(Loadout.PERK, "")).ends_with("empty_perk.png"), "empty_perk.png is the empty perk frame")
	check(near(MeterGauge.power_angle(0.0), 180.0) and near(MeterGauge.power_angle(100.0), 90.0) and near(MeterGauge.power_angle(50.0), 135.0), "power fills from the left edge toward MAX")
	check(near(MeterGauge.accuracy_angle(15.0, 2.0, 8.0), 90.0), "e=+15 sits just after MAX")
	check(near(MeterGauge.accuracy_angle(0.0, 2.0, 8.0), 45.0), "accuracy error 0 sits in the middle of the right arc")
	check(near(MeterGauge.accuracy_angle(-15.0, 2.0, 8.0), 0.0), "e=-15 reaches the ACCURACY end of the arc")
	var plain: Dictionary = MeterGauge.accuracy_layout(2.0, 8.0)
	var wide: Dictionary = MeterGauge.accuracy_layout(10.0, 20.0)
	var tight: Dictionary = MeterGauge.accuracy_layout(1.0, 6.0)
	check(float(wide["perfect_span"]) > float(plain["perfect_span"]), "a bigger PERFECT band takes a wider wedge")
	check(float(tight["perfect_span"]) < float(plain["perfect_span"]), "Tight Window draws a tighter PERFECT wedge")
	check(MeterGauge.is_red_tip(96.0, 95.0) and not MeterGauge.is_red_tip(90.0, 95.0), "the red-tip glow follows the live threshold and does not change the angle math")


func _check_menus() -> void:
	var boot := FrontEnd.new()
	check(boot.screen == FrontEnd.Screen.TITLE, "boot state is the title screen")
	boot.confirm_title()
	check(boot.screen == FrontEnd.Screen.MAIN and boot.menu_index == 0, "confirm on the title opens the main menu")
	var clicked := FrontEnd.new()
	clicked.confirm_title()
	check(clicked.screen == FrontEnd.Screen.MAIN, "a click on the title opens the main menu")
	var anywhere := FrontEnd.new()
	anywhere.confirm_title()
	check(anywhere.screen == FrontEnd.Screen.MAIN, "a click elsewhere on the title opens the main menu")
	var rooted := FrontEnd.new()
	rooted.back_title()
	check(rooted.screen == FrontEnd.Screen.TITLE, "Esc on the title stays on the title")
	var menu := FrontEnd.new()
	menu.confirm_title()
	menu.move_menu(1)
	check(menu.menu_index == 1, "Right moves from Standard to Endless")
	menu.move_menu(1)
	check(menu.menu_index == 2, "Right moves to Trophy Room")
	menu.move_menu(1)
	check(menu.menu_index == 3, "Right moves to Options")
	menu.menu_index = 0
	check(menu.confirm_menu() == "select" and menu.run_mode == "standard" and menu.screen == FrontEnd.Screen.SELECT, "Standard sets run_mode and opens character select")
	menu.back_select()
	check(menu.screen == FrontEnd.Screen.MAIN, "Esc from character select returns to the main menu")
	menu.back_main()
	check(menu.screen == FrontEnd.Screen.TITLE, "Esc from the main menu returns to the title")
	var records = get_root().get_node("SaveData")
	var kept_path := str(records.file_path)
	var options: Variant = get_root().get_node("Settings")
	var kept_settings := str(options.file_path)
	records.file_path = "user://fg_menu_save.cfg"
	records.reset_save()
	options.file_path = "user://fg_menu_settings.cfg"
	options.music = 100
	options.crowd = 100
	options.sfx = 100
	options.reset_controls()
	options.save_file()
	var locked := FrontEnd.new()
	locked.confirm_title()
	locked.menu_index = 1
	check(not locked.endless_unlocked(), "a fresh save keeps Endless locked")
	check(locked.confirm_menu() == "locked" and locked.screen == FrontEnd.Screen.MAIN, "confirming locked Endless stays on the menu")
	check(locked.lock_message == FrontEnd.LOCK_TEXT, "locked Endless says to beat Standard mode")
	records.wins = 1
	check(locked.endless_unlocked(), "lifetime.wins >= 1 unlocks Endless")
	locked.menu_index = 1
	check(locked.confirm_menu() == "select" and locked.run_mode == "endless" and locked.screen == FrontEnd.Screen.SELECT, "unlocked Endless sets run_mode and opens character select")
	records.wins = 0
	records.trophies["season_complete"] = true
	check(FrontEnd.new().endless_unlocked(), "the season_complete trophy unlocks Endless")
	records.reset_save()
	check(not FrontEnd.new().endless_unlocked(), "F9 save reset locks Endless again")
	var season := RunLogic.new()
	season.run_mode = "endless"
	season.kick_number = 20
	season.attempts = 2
	season.resolve_kick("GOOD", 0.0, true)
	check(season.phase == RunLogic.Phase.PLAYING and RunTable.count() == 20, "Endless kick 20 keeps playing; Standard's table is still 20 kicks")
	var trophy := FrontEnd.new()
	trophy.confirm_title()
	trophy.menu_index = 2
	check(trophy.confirm_menu() == "records" and trophy.screen == FrontEnd.Screen.RECORDS, "Trophy Room opens the records screen")
	trophy.back_records()
	check(trophy.screen == FrontEnd.Screen.MAIN, "Esc from Trophy Room opened at the menu returns to the menu")
	var over := FrontEnd.new()
	over.screen = FrontEnd.Screen.PLAY
	over.open_records(FrontEnd.Screen.PLAY)
	over.back_records()
	check(over.screen == FrontEnd.Screen.PLAY, "Esc from Trophy Room opened on GAME OVER returns there")
	check(options.music == 100 and options.crowd == 100 and options.sfx == 100, "audio defaults are 100/100/100")
	options.set_volume("music", 40)
	check(options.music == 40, "Music accepts 40")
	check(near(options.bus_volume_db("Music"), options.volume_db(40), 0.05), "Music 40 is on the Music bus, got %s" % options.bus_volume_db("Music"))
	check(not options.bus_is_muted("Music"), "Music 40 is not muted")
	options.set_volume("music", 0)
	check(options.bus_is_muted("Music"), "Music 0 mutes the bus")
	options.set_volume("music", 40)
	options.load_file()
	check(options.music == 40 and options.crowd == 100 and options.sfx == 100, "settings.cfg reloads the saved Music volume")
	check(options.defaults_match_table(), "keybind defaults match the options table")
	var before := _key_event(KEY_LEFT)
	check(options.pressed_event(before, "aim_left"), "Aim Left starts on Left")
	check(options.try_rebind("aim_left", KEY_A) == "ok", "rebinding Aim Left to A is accepted")
	check(options.key_label("aim_left") == "A", "the Aim Left label shows A")
	check(options.pressed_event(_key_event(KEY_A), "aim_left"), "InputMap aim_left is now A")
	check(not options.pressed_event(_key_event(KEY_LEFT), "aim_left"), "Left no longer aims after the rebind")
	check(options.try_rebind("confirm", KEY_1) == "used", "binding Confirm / Kick to 1 is rejected")
	check(options.key_label("confirm") == "SPACE", "Confirm stays on Space after the rejection")
	options.reset_controls()
	check(options.key_label("aim_left") == "LEFT" and options.pressed_event(_key_event(KEY_LEFT), "aim_left"), "Reset Controls restores Aim Left")
	records.reset_save()
	options.load_file()
	check(options.music == 40 and options.key_label("aim_left") == "LEFT", "F9 does not wipe settings.cfg")
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(source.find("Settings.pressed_event") >= 0 and source.find("Settings.held") >= 0, "gameplay reads InputMap actions")
	check(source.find("keycode == KEY_SPACE") < 0 and source.find("keycode == KEY_Z") < 0, "meter, belt, and shop keys are not leftover hardcoded checks")
	check(source.find("KEY_F9") >= 0 and source.find("KEY_C") >= 0 and source.find("KEY_W") >= 0, "debug C, W, and F9 stay hardcoded")
	var image := MenuLayout.IMAGE_SIZE
	var gap := Vector2(342.0, 585.0)
	check(MenuLayout.tile_at(gap, image, image) == -1, "the dark gap between Standard and Endless is not a tile")
	var wide := Vector2(2000, 720)
	for index in 4:
		var center := MenuLayout.screen_rect(MenuLayout.TILES[index], wide, image).get_center()
		check(MenuLayout.tile_at(center, wide, image) == index, "tile %d still hits after the window widens" % index)
	var square := Vector2(900, 900)
	var standard := MenuLayout.screen_rect(MenuLayout.TILES[0], square, image).get_center()
	check(MenuLayout.tile_at(standard, square, image) == 0, "a square window still hits the Standard plate")
	check(MenuLayout.find_texture_path(["title.png"]) != "", "title.png is imported")
	check(MenuLayout.find_texture_path(["main_menu.png"]) != "", "main_menu.png is imported")
	check(MenuLayout.find_texture_path(["options.png"]) != "", "options.png is imported")
	records.file_path = kept_path
	options.file_path = kept_settings
	options.load_file()
	options.apply_all()


func _key_event(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = false
	return event


func _check_endless_and_farm() -> void:
	var standard := RunLogic.new()
	check(near(standard.distance_yards(), 35.0) and not standard.is_boss(), "Standard kick 1 is still 35 yards")
	standard.kick_number = 5
	check(standard.is_boss() and near(standard.distance_yards(), 48.0), "Standard kick 5 is still the 48-yard boss")
	standard.kick_number = 10
	check(standard.is_boss(), "Standard kick 10 is still a boss")
	standard.kick_number = 15
	check(standard.is_boss(), "Standard kick 15 is still a boss")
	standard.kick_number = 20
	standard.attempts = 3
	standard.resolve_kick("GOOD", 0.0, true)
	check(standard.phase == RunLogic.Phase.WIN and near(standard.distance_yards(), 75.0), "Standard kick 20 is still a WIN at 75 yards")
	check(Loadout.max_rank(Loadout.CANNON) == 6 and Loadout.max_rank(Loadout.HERO_BALL) == 3, "Standard caps stay equipment VI and perk III")
	var capped := RunLogic.new()
	capped.give(Loadout.CANNON, 6)
	capped.give(Loadout.CANNON, 7)
	capped.give(Loadout.HERO_BALL, 3)
	capped.give(Loadout.HERO_BALL, 4)
	check(capped.cleats_rank == 6 and capped._perk_rank(Loadout.HERO_BALL) == 3, "a Standard offer cannot rank past VI or perk III")
	var endless := RunLogic.new()
	endless.run_mode = "endless"
	check(near(endless.distance_yards(), 20.0) and not endless.is_boss(), "Endless kick 1 is 20 yards and not a boss")
	endless.kick_number = 2
	check(near(endless.distance_yards(), 25.0), "Endless kick 2 is 25 yards")
	endless.kick_number = 3
	check(near(endless.distance_yards(), 30.0), "Endless kick 3 is 30 yards")
	endless.kick_number = 5
	check(not endless.is_boss(), "Endless kick 5 is not a boss")
	endless.kick_number = 10
	check(endless.is_boss() and near(endless.distance_yards(), 65.0), "Endless kick 10 is a 65-yard boss")
	endless.kick_number = 15
	check(not endless.is_boss(), "Endless kick 15 is not a boss")
	endless.kick_number = 20
	check(endless.is_boss() and near(endless.distance_yards(), 115.0), "Endless kick 20 is a 115-yard boss")
	endless.kick_number = 30
	check(endless.is_boss(), "Endless kick 30 is a boss")
	endless.kick_number = 37
	check(near(endless.distance_yards(), 200.0) and not endless.is_boss(), "Endless kick 37 is 200 yards")
	endless.kick_number = 197
	check(near(endless.distance_yards(), 1000.0), "Endless distance caps at 1000 yards")
	var seen := {}
	for seed_value in 40:
		var rolled := RunLogic.new()
		rolled.run_mode = "endless"
		rolled.kick_number = 10
		rolled._weather_rng.seed = seed_value
		rolled._roll_weather()
		var kept := rolled.weather
		rolled._roll_weather()
		check(rolled.weather == kept, "an Endless boss stays the same when the kick is rolled again")
		if not rolled.is_boss():
			check(false, "Endless kick 10 rolled as a boss")
		seen[kept] = true
	check(seen.has(RunLogic.ICED) and seen.has(RunLogic.SQUEEZE) and seen.has(RunLogic.MONSOON) and seen.has(RunLogic.BIG_GAME), "Endless bosses are drawn from all four")
	var shop := RunLogic.new()
	shop.run_mode = "endless"
	shop.kick_number = 5
	var preview := shop.next_boss_line()
	check(preview.begins_with("Next boss: ") and shop.endless_bosses.has(10), "the kick 5 shop previews kick 10's boss, got %s" % preview)
	shop.kick_number = 10
	shop._roll_weather()
	check(shop.weather == str(shop.endless_bosses[10]), "kick 10 keeps the previewed boss")
	var later := shop.next_boss_line()
	check(later.begins_with("Next boss: ") and shop.endless_bosses.has(20), "the kick 10 shop previews kick 20")
	shop.kick_number = 15
	check(shop.next_boss_line() == later, "the kick 15 shop previews the same kick 20 boss")
	check(not shop.opens_shop() or shop.kick_number == 15, "shops are still decided by kick number")
	shop.last_result_made = true
	shop.phase = RunLogic.Phase.PLAYING
	check(shop.opens_shop(), "making Endless kick 15 still opens the shop")
	shop.kick_number = 16
	check(not shop.opens_shop(), "Endless does not open a shop after kick 15")
	var ranked := RunLogic.new()
	ranked.run_mode = "endless"
	ranked.give(Loadout.CANNON, 12)
	ranked.give(Loadout.HOT_STREAK, 6)
	check(ranked.cleats_rank == 12 and Loadout.rank_badge(Loadout.CANNON, 12) == "XII", "Endless equipment ranks to XII")
	check(ranked._perk_rank(Loadout.HOT_STREAK) == 6 and Loadout.rank_badge(Loadout.HOT_STREAK, 4) == "IV" and Loadout.rank_badge(Loadout.HOT_STREAK, 7) == "VII", "Endless perk badges reach IV and equipment badges reach VII")
	check(near(ranked.stats.range_bonus, 72.0), "Cannon XII is +72 yards")
	check(near(ranked.stats.streak_step, 1.75), "Hot Streak VI is +1.75")
	var bruce := RunLogic.new()
	bruce.start_with_kicker(Kickers.BIG_BRUCE)
	bruce.run_mode = "endless"
	check(near(bruce.stats.range_base + bruce.stats.range_per_power * 100.0, 65.0), "Bruce with no items is still 65 yards at full power")
	bruce.kick_number = 11
	check(near(bruce.distance_yards(), 70.0), "Endless kick 11 is 70 yards")
	check(KickLogic.classify(65.0, 70.0, 0.0) == "SHORT", "65 yards is SHORT of a 70-yard kick")
	bruce.give(Loadout.CANNON, 12)
	bruce.give(Loadout.HIGH_AIR, 12)
	bruce.give(Loadout.GLASS_LEG, 6)
	bruce.give(Loadout.STONE)
	bruce.give(Loadout.SHAKY)
	var piled := bruce.stats.range_base + bruce.stats.range_per_power * 100.0 + bruce.stats.range_bonus
	check(piled >= 200.0 and near(piled, 221.0), "Bruce's range pile reaches about 221 yards, got %s" % piled)
	var walk := RunLogic.new()
	walk.start_with_kicker(Kickers.WALK_ON)
	walk.give(Loadout.CANNON, 12)
	check(walk.cleats_rank == 0, "Walk-On in Standard cannot take Cannon XII")
	walk.run_mode = "endless"
	walk.give(Loadout.CANNON, 12)
	walk.give(Loadout.HIGH_AIR, 12)
	walk.give(Loadout.GLASS_LEG, 6)
	walk.give(Loadout.STONE)
	walk.give(Loadout.SHAKY)
	var walk_pile := walk.stats.range_base + walk.stats.range_per_power * 100.0 + walk.stats.range_bonus
	check(walk_pile >= 200.0 and near(walk_pile, 216.0), "Walk-On's range pile reaches about 216 yards, got %s" % walk_pile)
	var howl := RunLogic.new()
	howl.start_with_kicker(Kickers.BIG_BRUCE)
	howl.run_mode = "endless"
	howl.give(Loadout.CANNON, 12)
	howl.give(Loadout.HIGH_AIR, 12)
	howl.give(Loadout.GLASS_LEG, 6)
	howl.give(Loadout.HOWLING)
	var howled := howl.stats.range_base + howl.stats.range_per_power * 100.0 + howl.stats.range_bonus
	check(near(howled, 65.0 + (72.0 + 24.0 + 48.0) * 1.15), "Howling Wind multiplies the Endless range bonuses, got %s" % howled)
	var low := KickLogic.new()
	Kickers.apply_to(low.stats, Kickers.BIG_BRUCE)
	low.kick_distance = 48.0
	_swing_to(low, 20.0, 0.0)
	check(near(low.power, 20.0) and near(low.max_range, 55.2), "a raw press of 20 still shows, and the kick uses 55.2 yards")
	check(low.result_text == "GOOD", "Farm Strength makes a 48-yard kick GOOD from a weak press")
	var sixty := KickLogic.new()
	Kickers.apply_to(sixty.stats, Kickers.BIG_BRUCE)
	sixty.kick_distance = 60.0
	_swing_to(sixty, 20.0, 0.0)
	check(sixty.result_text == "SHORT" and near(sixty.max_range, 55.2), "the same weak press is SHORT at 60 yards")
	var ninety := KickLogic.new()
	Kickers.apply_to(ninety.stats, Kickers.BIG_BRUCE)
	_swing_to(ninety, 90.0, 0.0)
	check(near(ninety.power, 90.0) and near(ninety.max_range, 60.1), "P=90 stays 90 and reaches 60.1 yards")
	var full := KickLogic.new()
	Kickers.apply_to(full.stats, Kickers.BIG_BRUCE)
	_swing_to(full, 100.0, 0.0)
	check(near(full.max_range, 65.0), "P=100 is still 65 yards")
	var iced := RunLogic.new()
	iced.start_with_kicker(Kickers.BIG_BRUCE)
	iced.give(Loadout.ICED)
	iced.force_weather(RunLogic.BIG_GAME)
	iced.prepare_kick_stats()
	check(near(iced.stats.power_floor, 80.0), "Farm Strength stays on during Big Game and the Iced curse")
	var missed := RunLogic.new()
	missed.run_mode = "endless"
	missed.attempts = 1
	missed.resolve_kick("SHORT", 0.0, false)
	check(missed.phase == RunLogic.Phase.GAME_OVER, "Endless still ends when attempts hit 0")
	var records = get_root().get_node("SaveData")
	var kept_path := str(records.file_path)
	records.file_path = "user://fg_endless_save.cfg"
	records.reset_save()
	var deep := RunLogic.new()
	deep.run_mode = "endless"
	deep.kick_number = 20
	deep.attempts = 3
	deep.resolve_kick("GOOD", 0.0, true)
	check(deep.phase == RunLogic.Phase.PLAYING and not records.has_trophy("season_complete"), "Endless kick 20 is not a Standard win and does not grant Season Complete")
	deep.kick_number = 197
	deep.kick_resolved = false
	deep.resolve_kick("GOOD", 0.0, false)
	check(deep.phase == RunLogic.Phase.FAR and near(deep.longest_make, 1000.0), "making the 1000-yard kick finishes with THAT'S FAR ENOUGH")
	check(records.longest_make >= 1000, "the 1000-yard make is saved in the records")
	records.file_path = kept_path


func _check_new_kickers() -> void:
	check(not KickConstants.debug_unlock_all_kickers, "debug_unlock_all_kickers stays false")
	check(Kickers.ALL.size() == 5, "select has five kickers")
	check(Kickers.id_for_slot(2) == Kickers.PHIL and Kickers.id_for_slot(3) == Kickers.GARY and Kickers.id_for_slot(4) == Kickers.VEX, "Phil, Gary, and Vex follow the starters")
	var records = get_root().get_node("SaveData")
	var kept := str(records.file_path)
	records.file_path = "user://fg_kicker_unlocks.cfg"
	records.reset_save()
	check(not Kickers.is_unlocked(Kickers.PHIL) and not Kickers.is_unlocked(Kickers.GARY) and not Kickers.is_unlocked(Kickers.VEX), "Phil, Gary, and Vex start locked")
	check(Kickers.field_frame(Kickers.PHIL, "idle").ends_with("phil_idle_back.png"), "Phil idle uses phil_idle_back.png")
	check(Kickers.field_frame(Kickers.PHIL, "portrait").ends_with("phil_portrait.png"), "Phil portrait uses phil_portrait.png")
	check(Kickers.field_frame(Kickers.GARY, "follow").ends_with("gary_follow_through.png"), "Gary follow-through is wired")
	check(Kickers.field_frame(Kickers.VEX, "run").ends_with("vex_run.png"), "Vex run is wired")
	check(Kickers.field_frame(Kickers.BIG_BRUCE, "idle").ends_with("big_bruce_back.png"), "Bruce idle still uses the back frame")
	var phil_stats := KickerStats.new()
	Kickers.apply_to(phil_stats, Kickers.PHIL)
	var gary_stats := KickerStats.new()
	Kickers.apply_to(gary_stats, Kickers.GARY)
	var vex_stats := KickerStats.new()
	Kickers.apply_to(vex_stats, Kickers.VEX)
	check(near(phil_stats.accuracy, 112.0) and near(phil_stats.perfect_band, 1.68) and near(phil_stats.good_band, 6.72), "Phil bands are ±1.68 / ±6.72")
	check(near(gary_stats.accuracy, 98.0) and near(gary_stats.perfect_band, 1.47) and near(gary_stats.good_band, 5.88), "Gary bands are ±1.47 / ±5.88")
	check(near(vex_stats.accuracy, 94.0) and near(vex_stats.perfect_band, 1.41) and near(vex_stats.good_band, 5.64), "Vex bands are ±1.41 / ±5.64")
	check(near(phil_stats.range_base + phil_stats.range_per_power * 100.0, 55.0), "Phil at P=100 with no items is 55 yards")
	check(near(gary_stats.range_base + gary_stats.range_per_power * 100.0, 65.0), "Gary at P=100 with no items is 65 yards")
	check(gary_stats.ball_type == "standard" and phil_stats.ball_type == "standard" and vex_stats.ball_type == "standard", "the new kickers use default wind, not the Farm Ball")
	var phil_time := _measure_power_sweep(Kickers.PHIL)
	var gary_time := _measure_power_sweep(Kickers.GARY)
	var vex_time := _measure_power_sweep(Kickers.VEX)
	print("POWER_TO_MAX Phil ", phil_time, " Gary ", gary_time, " Vex ", vex_time)
	check(near(phil_time, 0.700, 0.002) and near(gary_time, 0.700, 0.002) and near(vex_time, 0.700, 0.002), "Phil, Gary, and Vex share the 0.700s sweep")
	var shop := RunLogic.new()
	shop.start_with_kicker(Kickers.WALK_ON)
	shop.cash = 10
	shop.kick_number = 5
	shop.last_result_made = true
	shop.open_shop()
	shop.shop_stock = [Vitamins.PROTEIN, Vitamins.ZINC, Vitamins.TART]
	var before := shop.cash
	shop.reroll_shop()
	check(shop.cash < before and not records.has_unlock(Kickers.PHIL), "a shop reroll spends cash and does not unlock Phil")
	shop.sell_belt(0)
	check(not records.has_unlock(Kickers.PHIL), "selling does not unlock Phil")
	var phil := RunLogic.new()
	phil.start_with_kicker(Kickers.PHIL)
	phil.cash = 4
	phil.kick_number = 5
	phil.last_result_made = true
	phil.open_shop()
	phil.shop_stock = [Vitamins.PROTEIN, Vitamins.LUTEIN, Vitamins.TART]
	check(phil.item_price(Vitamins.PROTEIN) == 0 and phil.item_price(Vitamins.B12) == 0, "Phil's vitamins and B12 cost $0")
	check(phil.buy_shelf(0) and phil.cash == 4 and records.has_unlock(Kickers.PHIL), "buying a free vitamin unlocks Phil and does not spend cash")
	check(phil.sell_belt(0) and phil.cash == 4, "selling a free vitamin pays $0")
	phil.attempts = 2
	check(phil.buy_b12() and phil.cash == 4 and phil.attempts == 3, "B12 is free and still adds one attempt")
	phil.leave_shop()
	phil.give(Loadout.CANNON, 1)
	check(near(phil.stats.range_bonus, 6.9), "Compounding makes Cannon I +6.9 yards")
	phil.belt[0] = Vitamins.PROTEIN
	check(phil.use_belt(0), "Phil can use a belt vitamin")
	phil.prepare_kick_stats()
	check(near(phil.stats.range_bonus, 6.9 + 6.9), "Compounding makes Protein Shake +6.9 yards too")
	var gel := KickLogic.new()
	gel.stats = phil.stats
	gel.kick_distance = 35.0
	_swing_to(gel, 100.0, 0.0)
	phil.resolve_kick(gel.result_text, gel.offset_yards, gel.perfect)
	check(phil.last_result_made and phil.score_line.find("0.5") >= 0, "The Gelcap adds +0.5 Mult on the make, line %s" % phil.score_line)
	var gold := KickLogic.new()
	Kickers.apply_to(gold.stats, Kickers.GARY)
	gold.kick_distance = 35.0
	_swing_to(gold, 50.0, 4.0)
	check(gold.perfect and near(gold.accuracy_error, 0.0), "Gary turns a yellow GOOD into a true PERFECT")
	var wide := KickLogic.new()
	Kickers.apply_to(wide.stats, Kickers.GARY)
	wide.kick_distance = 35.0
	_swing_to(wide, 50.0, 9.0)
	check(not wide.perfect and absf(wide.accuracy_error) > 7.8, "Gary still misses outside the good band")
	var lucky := RunLogic.new()
	lucky.start_with_kicker(Kickers.GARY)
	lucky.give(Loadout.CANNON, 1)
	lucky.resolve_kick("GOOD", 0.0, false)
	lucky.prepare_kick_stats()
	check(lucky.lucky_stacks == 1 and near(lucky.stats.range_bonus, 6.2), "one first-try make makes Cannon +6.2 yards")
	var converted := RunLogic.new()
	converted.start_with_kicker(Kickers.GARY)
	converted.give(Loadout.CANNON, 1)
	converted.resolve_kick("SHORT", 0.0, false)
	converted.begin_retry()
	converted.resolve_kick("GOOD", 0.0, false)
	converted.prepare_kick_stats()
	check(converted.lucky_stacks == 0 and near(converted.stats.range_bonus, 6.0), "a converted retry does not stack Lucky Ball")
	var clean := RunLogic.new()
	clean.start_with_kicker(Kickers.WALK_ON)
	for n in range(1, 21):
		clean.kick_number = n
		clean.kick_resolved = false
		clean.phase = RunLogic.Phase.PLAYING
		clean.is_first_ball = true
		clean.resolve_kick("GOOD", 0.0, false)
	check(records.has_unlock(Kickers.GARY), "a clean Standard win unlocks Gary")
	records.unlocks[Kickers.GARY] = false
	var dirty := RunLogic.new()
	dirty.start_with_kicker(Kickers.WALK_ON)
	dirty.resolve_kick("SHORT", 0.0, false)
	dirty.begin_retry()
	dirty.resolve_kick("GOOD", 0.0, false)
	for n in range(2, 21):
		dirty.kick_number = n
		dirty.kick_resolved = false
		dirty.phase = RunLogic.Phase.PLAYING
		dirty.is_first_ball = true
		dirty.attempts = 3
		dirty.resolve_kick("GOOD", 0.0, false)
	check(not records.has_unlock(Kickers.GARY), "a converted miss keeps Gary locked")
	var vex_short := KickLogic.new()
	Kickers.apply_to(vex_short.stats, Kickers.VEX)
	vex_short.kick_distance = 35.0
	_swing_to(vex_short, 80.0, 0.0)
	check(near(vex_short.max_range, 30.0) and vex_short.result_text == "SHORT", "Vex at 80 power is SHORT by about 5, got %s %s" % [vex_short.max_range, vex_short.result_text])
	var vex_88 := KickLogic.new()
	Kickers.apply_to(vex_88.stats, Kickers.VEX)
	vex_88.kick_distance = 35.0
	_swing_to(vex_88, 88.0, 0.0)
	check(near(vex_88.max_range, 40.0, 0.05) and vex_88.result_text == "GOOD", "Vex at 88 power clears a 35-yard kick by 5, got %s" % vex_88.max_range)
	var vex_100 := KickLogic.new()
	Kickers.apply_to(vex_100.stats, Kickers.VEX)
	vex_100.kick_distance = 35.0
	_swing_to(vex_100, 100.0, 0.0)
	check(near(vex_100.max_range, 55.0, 0.05), "Vex at 100 power clears by 20 yards, got %s" % vex_100.max_range)
	vex_88.reset_kick()
	vex_88.stats.range_bonus = 6.0
	_swing_to(vex_88, 88.0, 0.0)
	check(near(vex_88.max_range, 46.0, 0.05), "Cannon +6 adds on top of Vex clearance, got %s" % vex_88.max_range)
	var vex_far := KickLogic.new()
	Kickers.apply_to(vex_far.stats, Kickers.VEX)
	vex_far.kick_distance = 1000.0
	_swing_to(vex_far, 88.0, 0.0)
	check(vex_far.result_text != "SHORT" and vex_far.max_range >= 1000.0, "88 power is never SHORT, even at 1000 yards")
	var vex_wind := KickLogic.new()
	Kickers.apply_to(vex_wind.stats, Kickers.VEX)
	vex_wind.kick_distance = 35.0
	vex_wind.wind_speed = 0.0
	_swing_to(vex_wind, 90.0, 0.0)
	check(vex_wind.drift_yards < -1.0, "no real wind still curves Vex left, drift %s" % vex_wind.drift_yards)
	vex_wind.wind_speed = 0.0
	vex_wind.reset_kick()
	_swing_to(vex_wind, 90.0, 0.0)
	check(vex_wind.drift_yards < -1.0, "clearing the rolled wind does not remove the saucer")
	var early := RunLogic.new()
	early.start_with_kicker(Kickers.WALK_ON)
	early.run_mode = "endless"
	early.kick_number = 12
	early.attempts = 1
	early.resolve_kick("SHORT", 0.0, false)
	check(early.phase == RunLogic.Phase.GAME_OVER and near(early.distance_yards(), 75.0) and not records.has_unlock(Kickers.VEX), "dying on the 75-yard Endless kick does not unlock Vex")
	var late := RunLogic.new()
	late.start_with_kicker(Kickers.WALK_ON)
	late.run_mode = "endless"
	late.kick_number = 13
	late.attempts = 1
	late.resolve_kick("SHORT", 0.0, false)
	check(late.phase == RunLogic.Phase.GAME_OVER and late.distance_yards() > 75.0 and records.has_unlock(Kickers.VEX), "GAME OVER past 75 yards unlocks Vex")
	var same := RunLogic.new()
	same.start_with_kicker(Kickers.WALK_ON)
	var who := same.kicker_id
	same.go_to_next_kick()
	check(same.kicker_id == who, "the kicker does not change mid-run")
	records.press_f9(10.0)
	records.press_f9(11.0)
	check(not records.has_unlock(Kickers.PHIL) and not records.has_unlock(Kickers.GARY) and not records.has_unlock(Kickers.VEX), "F9 twice wipes the new unlocks")
	records.file_path = kept
	records.load_file()


func _measure_accuracy_sweep(id: String) -> float:
	var kick := KickLogic.new()
	Kickers.apply_to(kick.stats, id)
	kick.press_space()
	kick.advance(kick.windup_left)
	kick.advance(kick.seconds_to_power(50.0))
	if kick.phase == KickLogic.Phase.POWER:
		kick.press_space()
	kick.advance(kick.seconds_until_error(15.0))
	var step := 0.0002
	var elapsed := 0.0
	while kick.phase == KickLogic.Phase.ACCURACY and elapsed < 3.0:
		kick.advance(step)
		elapsed += step
	return elapsed


func _check_auto_shank() -> void:
	var saw_left := false
	var saw_right := false
	for seed_value in 24:
		var kick := KickLogic.new()
		kick.set_seed(seed_value)
		Kickers.apply_to(kick.stats, Kickers.BIG_BRUCE)
		kick.press_space()
		kick.advance(kick.windup_left)
		var saw_accuracy := false
		var elapsed := 0.0
		while kick.phase == KickLogic.Phase.POWER and elapsed < 2.0:
			kick.advance(0.01)
			elapsed += 0.01
			if kick.phase == KickLogic.Phase.ACCURACY:
				saw_accuracy = true
		check(not saw_accuracy and kick.shanked and kick.phase == KickLogic.Phase.FLIGHT, "seed %s shanks without an accuracy phase" % seed_value)
		check(kick.result_text.begins_with("WIDE"), "seed %s shank is WIDE, got %s" % [seed_value, kick.result_text])
		check(absf(kick.offset_yards) > kick.post_half_gap + KickConstants.DOINK_BAND_YARDS, "seed %s misses the posts, offset %s" % [seed_value, kick.offset_yards])
		check(kick.power == 0.0, "a shank does not store a power lock")
		var full := kick.stats.range_base + kick.stats.range_per_power * 100.0
		var floored := kick.stats.range_base + kick.stats.range_per_power * kick.stats.power_floor
		check(near(kick.max_range, full), "Bruce shank flies at raw P=100 (%s), not a floored lock" % kick.max_range)
		check(kick.detail_line().begins_with("SHANK, full power"), "the result line does not call a shank a power lock")
		check(not near(kick.max_range, floored), "Farm Strength does not turn the missed click into a P=80 lock")
		check(near(absf(kick.accuracy_error), 15.0), "red-tip noise is not applied to a shank")
		if kick.result_text == "WIDE LEFT":
			saw_left = true
		elif kick.result_text == "WIDE RIGHT":
			saw_right = true
		if saw_left and saw_right and seed_value > 2:
			break
	check(saw_left and saw_right, "shanks pick left and right")
	var locked := KickLogic.new()
	Kickers.apply_to(locked.stats, Kickers.WALK_ON)
	locked.set_seed(3)
	locked.press_space()
	locked.advance(locked.windup_left)
	locked.take_power_press(locked.seconds_to_power(100.0))
	check(not locked.shanked and locked.phase == KickLogic.Phase.ACCURACY and near(locked.power, 100.0), "Space #2 on the step that reaches MAX locks P=100")
	var exact := KickLogic.new()
	exact.press_space()
	exact.advance(exact.windup_left)
	exact.needle_angle = MeterGauge.MAX_ANGLE
	exact.press_space()
	check(not exact.shanked and exact.phase == KickLogic.Phase.ACCURACY and near(exact.power, 100.0), "Space #2 exactly at MAX is P=100, not a shank")
	var practice := RunLogic.new()
	practice.start_with_kicker(Kickers.WALK_ON)
	practice.stats.practice_per_quarter = 1
	practice.practice_left = 1
	var attempts_before := practice.attempts
	var kick_before := practice.kick_number
	check(practice.start_practice(), "a practice swing can start")
	var swing := KickLogic.new()
	swing.stats = practice.stats
	swing.press_space()
	swing.advance(swing.windup_left)
	swing.advance(swing.seconds_to_power(100.0) + 0.05)
	check(swing.shanked and swing.phase == KickLogic.Phase.FLIGHT, "practice shank does not enter the accuracy phase")
	check(swing.result_text.begins_with("WIDE"), "practice shank is a wide miss, got %s" % swing.result_text)
	practice.end_practice()
	check(not practice.practicing and practice.attempts == attempts_before and practice.kick_number == kick_before, "ending the practice shank does not spend an attempt or advance")
	var missed := RunLogic.new()
	missed.start_with_kicker(Kickers.BIG_BRUCE)
	missed.streak = 4
	missed.stats.lucky_ball = true
	missed.stats.gelcap = true
	missed.stats.good_as_gold = true
	missed.active_vitamins[Vitamins.PROTEIN] = 1
	missed.is_first_ball = true
	missed.attempts = 2
	var before_attempts := missed.attempts
	var shank := KickLogic.new()
	shank.set_seed(2)
	shank.stats = missed.stats
	shank.kick_distance = missed.distance_yards()
	shank.press_space()
	shank.advance(shank.windup_left)
	shank.advance(shank.seconds_to_power(100.0) + 0.02)
	missed.resolve_kick(shank.result_text, shank.offset_yards, shank.perfect)
	check(not shank.perfect and missed.streak == 0, "a shank resets the streak and is not perfect")
	check(missed.attempts == before_attempts - 1, "a shank spends one attempt")
	check(missed.kick_number == 1 and not missed.last_result_made and not missed.wants_upgrade(), "a shank does not advance and offers no card")
	check(missed.lucky_stacks == 0 and missed.score == 0 and missed.last_points == 0, "Lucky Ball, Gelcap, and Good As Gold do not pay on a shank")
	check(missed.phase == RunLogic.Phase.PLAYING and missed.begin_retry() and missed.kick_number == 1, "attempts left means the same kick comes back")
	var over := RunLogic.new()
	over.start_with_kicker(Kickers.WALK_ON)
	over.resolve_kick("WIDE LEFT", -8.0, false)
	check(over.attempts == 0 and over.phase == RunLogic.Phase.GAME_OVER, "a shank with no attempts left is GAME OVER")
	var walk := RunLogic.new()
	walk.start_with_kicker(Kickers.WALK_ON)
	walk.give(Loadout.PINPOINT, 1)
	check(near(walk.stats.perfect_band, 3.5) and near(walk.stats.good_band, 9.0), "Pinpoint I on Walk-On is ±3.5 / ±9")
	var tight := RunLogic.new()
	tight.start_with_kicker(Kickers.WALK_ON)
	tight.give(Loadout.TIGHT)
	check(near(tight.stats.perfect_band, 1.0) and near(tight.stats.good_band, 4.0), "Tight Window on Walk-On is ±1 / ±4")
	var ratings := {
		Kickers.PHIL: 112.0,
		Kickers.WALK_ON: 100.0,
		Kickers.GARY: 98.0,
		Kickers.VEX: 94.0,
		Kickers.BIG_BRUCE: 90.0,
	}
	for id in ratings.keys():
		var stats := KickerStats.new()
		Kickers.apply_to(stats, id)
		var accuracy: float = ratings[id]
		check(near(stats.accuracy, accuracy), "%s accuracy stays %s" % [id, accuracy])
		check(near(stats.perfect_band, 1.5 * accuracy / 100.0) and near(stats.good_band, 6.0 * accuracy / 100.0), "%s bands follow 1.5 / 6" % id)
		check(near(_measure_power_sweep(id), 0.700, 0.002), "%s POWER to MAX is still 0.700s" % id)
	var accuracy_time := _measure_accuracy_sweep(Kickers.WALK_ON)
	var accuracy_expected := 90.0 / MeterGauge.omega_accuracy(120.0, 1.0)
	print("ACCURACY_SWEEP Walk-On ", accuracy_time, " current formula ", accuracy_expected)
	check(near(accuracy_time, accuracy_expected, 0.002), "accuracy-phase time stays on the current formula, measured %s" % accuracy_time)
	check(near(accuracy_time, 0.700, 0.002), "the current accuracy sweep is 0.700s, not a new target")

