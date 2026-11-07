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
	kick.press_space()
	check(kick.phase == KickLogic.Phase.POWER and near(kick.needle, 0.0), "space starts the needle at 0")
	kick.advance(0.25)
	check(near(kick.needle, 25.0), "needle rises at 100 per second, got %s" % kick.needle)
	var locked_aim := kick.aim_degrees
	kick.aim(-1.0, 3.0)
	check(near(kick.aim_degrees, locked_aim), "aim locks once the meter starts")
	kick.advance(1.0)
	check(kick.phase == KickLogic.Phase.ACCURACY, "reaching 100 starts the accuracy swing")
	check(near(kick.power, 100.0) and near(kick.needle, 100.0), "power locks itself at 100")
	kick.advance(0.5)
	check(near(kick.needle, 40.0), "after 100 the needle falls, got %s" % kick.needle)
	var during_flight := _kick_power_accuracy(40.0, 0.0)
	var power_before := during_flight.power
	during_flight.press_space()
	check(during_flight.phase == KickLogic.Phase.FLIGHT and near(during_flight.power, power_before), "space during flight does nothing")


func _check_perfect_band() -> void:
	check(KickLogic.is_perfect(0.0) and KickLogic.is_perfect(2.0) and KickLogic.is_perfect(-2.0), "e inside -2..+2 is PERFECT")
	check(not KickLogic.is_perfect(2.01) and not KickLogic.is_perfect(-2.01), "e just outside 2 is not PERFECT")
	check(KickLogic.hook_degrees(2.0) == 0.0 and KickLogic.hook_degrees(-2.0) == 0.0, "a perfect e adds 0 degrees")
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
	check(near(made.power, 100.0), "check 2 power reached 100 without a second press")
	check(near(made.needle, 0.0), "check 2 the press is on the green line, needle=%s" % made.needle)
	check(made.accuracy_error == expected_error, "check 2 the state machine uses the seeded wobble")
	check(made.perfect and made.result_text == "GOOD", "check 2 seed %s -> PERFECT and GOOD (e=%s)" % [perfect_seed, made.accuracy_error])
	var bumped := _drive_check2(bumped_seed)
	check(not bumped.perfect, "check 2 seed %s red tip removes PERFECT (e=%s)" % [bumped_seed, bumped.accuracy_error])
	check(bumped.result_text == "GOOD", "check 2 a centered red-tip kick is still GOOD at 35 yd, got %s" % bumped.result_text)
	print("INFO  check 2 kept PERFECT with seed %s, e=%s, result=%s" % [perfect_seed, made.accuracy_error, made.result_text])
	print("INFO  check 2 lost PERFECT with seed %s, e=%s, result=%s" % [bumped_seed, bumped.accuracy_error, bumped.result_text])
	print("INFO  check 2: P=100 is in the red tip, so a press on 0 stays PERFECT only when the random add is inside -2..+2. At 35 yd a centered kick is still GOOD.")


func _drive_check2(seed_value: int) -> KickLogic:
	var kick := KickLogic.new()
	kick.set_seed(seed_value)
	kick.press_space()
	var guard := 0
	while kick.phase == KickLogic.Phase.POWER and guard < 600:
		kick.advance(1.0 / 60.0)
		guard += 1
	check(kick.phase == KickLogic.Phase.ACCURACY and near(kick.power, 100.0), "check 2 needle climbed to 100 on its own")
	guard = 0
	while kick.phase == KickLogic.Phase.ACCURACY and kick.needle > 0.0 and guard < 600:
		kick.advance(1.0 / 60.0)
		guard += 1
	check(guard < 600 and near(kick.needle, 0.0), "check 2 needle fell through 0")
	if kick.phase == KickLogic.Phase.ACCURACY:
		kick.press_space()
	return kick


func _check_3_full_left() -> void:
	var kick := KickLogic.new()
	kick.aim(-1.0, 5.0)
	check(near(kick.aim_degrees, -12.0), "check 3 holding Left reaches -12, got %s" % kick.aim_degrees)
	kick.press_space()
	kick.advance(0.8)
	kick.press_space()
	kick.advance(80.0 / 120.0)
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
	var at_28 := KickLogic.range_yards(28.0)
	var at_29 := KickLogic.range_yards(29.0)
	check(KickLogic.classify(at_28, 35.0, 0.0) == "SHORT", "P=28 range %s is SHORT" % at_28)
	check(KickLogic.classify(at_29, 35.0, 0.0) == "GOOD", "P=29 range %s reaches and is GOOD when centered" % at_29)
	print("INFO  check 4 boundary P=%s (range equals 35). P=28 range=%s. P=20 range=%s." % [boundary, at_28, kick.max_range])


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
	kick.advance(0.8)
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
	var kick := _kick_power_accuracy(40.0, 0.0)
	var expected_range := KickLogic.range_yards(40.0)
	check(near(kick.travel_yards, expected_range), "P=40 flies its max range %s, got %s" % [expected_range, kick.travel_yards])
	check(near(kick.flight_duration, KickLogic.flight_time_seconds(expected_range)), "flight time follows the yards flown, got %s" % kick.flight_duration)
	check(kick.result_text == "GOOD", "centered P=40 is GOOD")
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
	check(absf(full - 83.0) < 0.001, "full power range is about 83 yd, got %s" % full)
	var short_kick := _kick_power_accuracy(20.0, 0.0)
	check(near(short_kick.flight_duration, KickLogic.flight_time_seconds(short_kick.max_range)), "a short kick's flight time uses the yards it actually flies")
	short_kick.advance(short_kick.flight_duration)
	check(near(short_kick.ball_forward_yards, short_kick.max_range), "a short ball drops at max range %s" % short_kick.ball_forward_yards)
	check(short_kick.ball_forward_yards < short_kick.kick_distance, "a short ball does not reach the posts")
	var again := KickLogic.new()
	again.kick_distance = 42.0
	again.aim(-1.0, 0.4)
	again.press_space()
	again.advance(0.5)
	again.press_space()
	again.advance(0.4)
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
	hash_kick.advance(0.8)
	hash_kick.press_space()
	hash_kick.advance(80.0 / 120.0)
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
	var eligible := Upgrades.eligible_ids({})
	check(eligible.size() == 6, "all six upgrades start eligible")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var offer: Array = Upgrades.draw_offer(eligible, rng)
	check(offer.size() == 3, "check 1 an offer has 3 cards")
	check(offer[0] != offer[1] and offer[0] != offer[2] and offer[1] != offer[2], "check 1 the three cards are different")
	var again := RandomNumberGenerator.new()
	again.seed = 4
	var replay: Array = Upgrades.draw_offer(eligible, again)
	check(offer == replay, "the same offer seed draws the same cards")
	var capped := {"big_leg": 3, "steady_plant": 3, "sweet_spot": 2, "hot_streak": 1}
	var left := Upgrades.eligible_ids(capped)
	check(left.find("big_leg") == -1 and left.find("sweet_spot") == -1, "maxed upgrades are not offered")
	check(left.find("deep_bench") != -1 and left.find("mulligan") != -1, "upgrades under the cap stay eligible")
	var short := Upgrades.draw_offer(["big_leg", "mulligan"], rng)
	check(short.size() == 2 and short[0] != short[1], "fewer than 3 eligible cards shows only those")
	check(str(Upgrades.get_def(Upgrades.BIG_LEG)["rarity"]) == "common", "rarity is stored on the upgrade")
	var run := RunLogic.new()
	run.new_run()
	run.force_offer(["big_leg", "steady_plant", "sweet_spot"])
	run.roll_offer()
	check(run.pick_card(0), "check 1 pressing 1 picks the first card")
	check(run.owned_ids().has("big_leg") and int(run.stacks["big_leg"]) == 1, "check 1 Big Leg shows in the owned list")
	check(not run.awaiting_offer, "picking closes the offer")


func _check_upgrade_effects() -> void:
	var kick := KickLogic.new()
	kick.kick_distance = 35.0
	_lock_power_at(kick, 25.0)
	check(kick.result_text == "SHORT", "check 2 power 25 from 35 yd is SHORT before Big Leg, range %s" % kick.max_range)
	kick.stats.range_bonus = 6.0
	_lock_power_at(kick, 25.0)
	check(kick.result_text == "GOOD" and kick.max_range >= 35.0, "check 2 Big Leg makes power 25 reach, range %s" % kick.max_range)
	var slow := KickLogic.new()
	Upgrades.apply(Upgrades.STEADY_PLANT, slow.stats)
	check(near(slow.stats.power_speed, 85.0), "check 3 one Steady Plant sets power speed to 85, got %s" % slow.stats.power_speed)
	slow.press_space()
	slow.advance(1.0)
	check(near(slow.needle, 85.0) and slow.phase == KickLogic.Phase.POWER, "check 3 after one second the slower needle is at 85, got %s" % slow.needle)
	Upgrades.apply(Upgrades.STEADY_PLANT, slow.stats)
	Upgrades.apply(Upgrades.STEADY_PLANT, slow.stats)
	check(near(slow.stats.power_speed, 100.0 * 0.85 * 0.85 * 0.85), "three Steady Plants stack by multiplying")
	var sweet := KickerStats.new()
	Upgrades.apply(Upgrades.SWEET_SPOT, sweet)
	check(near(sweet.perfect_band, 4.0) and near(sweet.good_band, 11.0), "check 4 Sweet Spot widens the bands to 4 and 11")
	Upgrades.apply(Upgrades.SWEET_SPOT, sweet)
	check(near(sweet.perfect_band, 6.0) and near(sweet.good_band, 14.0), "Sweet Spot stacks a second time")
	var wide := KickLogic.new()
	wide.stats.perfect_band = 4.0
	_lock_power_at(wide, 10.0)
	# Fall from 10 to 3, which is outside the old perfect band and inside the new one.
	wide.advance(7.0 / wide.stats.accuracy_speed)
	if wide.phase == KickLogic.Phase.ACCURACY:
		wide.press_space()
	check(wide.perfect and near(wide.final_angle_degrees, 0.0), "a wider perfect band treats e=3 as perfect")
	var bench := RunLogic.new()
	bench.new_run()
	bench.attempts = 2
	bench.grant(Upgrades.DEEP_BENCH)
	check(bench.attempt_cap == 4 and bench.attempts == 3, "check 5 Deep Bench makes 4 circles and fills one more")
	bench.grant(Upgrades.DEEP_BENCH)
	check(bench.attempt_cap == 5 and bench.attempts == 4, "a second Deep Bench reaches the hard max of 5")
	var before_cap := bench.attempt_cap
	var before_attempts := bench.attempts
	bench.grant(Upgrades.DEEP_BENCH)
	check(bench.attempt_cap == before_cap and bench.attempts == before_attempts, "Deep Bench does not stack past 2 or past 5")
	check(Upgrades.eligible_ids(bench.stacks).find(Upgrades.DEEP_BENCH) == -1, "Deep Bench at max is not offered")
	var hot := RunLogic.new()
	hot.new_run()
	hot.grant(Upgrades.HOT_STREAK)
	check(near(hot.stats.streak_step, 0.5), "Hot Streak sets the streak step to 0.5")
	hot.resolve_kick("GOOD", 2.0, false)
	check(near(hot.current_mult(), 1.5), "after one make the Hot Streak mult is 1.5, got %s" % hot.current_mult())
	hot.grant(Upgrades.HOT_STREAK)
	check(near(hot.stats.streak_step, 0.5) and int(hot.stacks[Upgrades.HOT_STREAK]) == 1, "Hot Streak does not stack")


func _check_mulligan_reroll_and_skip() -> void:
	var run := RunLogic.new()
	run.new_run()
	var attempts := run.attempts
	var streak := run.streak
	var score := run.score
	run.grant(Upgrades.MULLIGAN)
	check(run.mulligans_left == 1 and run.can_mulligan("WIDE LEFT"), "check 6 a mulligan is ready after picking it")
	run.begin_mulligan("WIDE LEFT", -5.0, false)
	check(run.awaiting_mulligan, "check 6 the miss asks Use Mulligan?")
	check(run.use_mulligan(), "check 6 M retakes")
	check(run.attempts == attempts and run.streak == streak and run.score == score, "check 6 the miss is erased")
	check(not run.is_first_ball and run.mulligans_left == 0, "check 6 the retake is not a first ball and spends the mulligan")
	check(not run.awaiting_offer, "a mulligan retake does not open the card offer")
	run.resolve_kick("GOOD", 0.0, false)
	check(run.score == 70 and run.attempts == attempts and run.attempt_note == "", "check 6 the made retake scores and earns no attempt")
	check(run.go_to_next_kick(), "move on after the retake")
	check(not run.can_mulligan("SHORT"), "check 6 the next miss in the quarter has no mulligan")
	run.resolve_kick("SHORT", 0.0, false)
	check(run.attempts == attempts - 1, "check 6 that miss costs an attempt")
	var same := RunLogic.new()
	same.new_run()
	same.grant(Upgrades.MULLIGAN)
	same.grant(Upgrades.MULLIGAN)
	check(same.mulligans_left == 2, "two Mulligan stacks give two charges")
	same.begin_mulligan("DOINK", 3.1, false)
	same.use_mulligan()
	check(same.mulligans_left == 1 and not same.can_mulligan("SHORT"), "the same kick does not get a second mulligan")
	var quarter := RunLogic.new()
	quarter.new_run()
	quarter.grant(Upgrades.MULLIGAN)
	quarter.mulligans_left = 0
	quarter.kick_number = 5
	quarter.kick_resolved = true
	quarter.last_result_made = true
	check(quarter.go_to_next_kick() and quarter.kick_number == 6, "kick 6 starts the next quarter")
	check(quarter.mulligans_left == 1, "the quarter refills the mulligan")
	var doomed := RunLogic.new()
	doomed.new_run()
	doomed.grant(Upgrades.MULLIGAN)
	doomed.begin_mulligan("SHORT", 0.0, false)
	doomed.accept_pending_miss()
	check(doomed.phase == RunLogic.Phase.GAME_OVER and not doomed.awaiting_offer, "accepting the last miss is game over, with no cards")
	var cards := RunLogic.new()
	cards.new_run()
	cards.set_offer_seed(2)
	cards.roll_offer()
	var first: Array = cards.offer.duplicate()
	check(cards.rerolls_left == 1 and cards.reroll_offer(), "check 7 F rerolls once")
	check(cards.rerolls_left == 0 and cards.offer.size() == 3, "check 7 the new offer is still 3 cards, Reroll: 0 left")
	var held: Array = cards.offer.duplicate()
	check(not cards.reroll_offer() and cards.offer == held, "check 7 a second F does nothing")
	check(first.size() == 3, "the first offer was full")
	var skipped := RunLogic.new()
	skipped.new_run()
	skipped.resolve_kick("GOOD", 2.0, false)
	var scored := skipped.score
	skipped.roll_offer()
	check(skipped.skip_offer() and skipped.score == scored + 10, "check 8 S adds 10 points")
	check(skipped.go_to_next_kick() and skipped.kick_number == 2, "check 8 skip starts the next kick")
	var fresh := RunLogic.new()
	fresh.new_run()
	fresh.grant(Upgrades.BIG_LEG)
	fresh.grant(Upgrades.SWEET_SPOT)
	check(fresh.stats.range_bonus == 6.0, "the run kept the upgrade")
	fresh.new_run()
	check(fresh.stats.range_bonus == 0.0 and fresh.stats.perfect_band == 2.0, "a new run resets KickerStats")
	check(fresh.owned_ids().is_empty() and fresh.rerolls_left == 1 and fresh.mulligans_left == 0, "a new run clears cards, rerolls, and mulligans")


func _lock_power_at(kick: KickLogic, power_value: float) -> void:
	kick.reset_kick()
	kick.kick_distance = 35.0
	kick.start_lateral_yards = 0.0
	kick.press_space()
	kick.advance(power_value / kick.stats.power_speed)
	kick.press_space()
	kick.advance(kick.power / kick.stats.accuracy_speed)
	if kick.phase == KickLogic.Phase.ACCURACY:
		kick.press_space()


func _kick_power_accuracy(power_value: float, needle_at_lock: float) -> KickLogic:
	var kick := KickLogic.new()
	kick.press_space()
	kick.advance(power_value / KickConstants.POWER_RISE_PER_SEC)
	kick.press_space()
	var drop := power_value - needle_at_lock
	kick.advance(drop / KickConstants.ACCURACY_FALL_PER_SEC)
	if kick.phase == KickLogic.Phase.ACCURACY:
		kick.press_space()
	return kick


func _check_kickers_and_fixes() -> void:
	var first := Kickers.click_slot(-1, 0)
	check(int(first["highlight"]) == 0 and not bool(first["confirm"]), "check 1 the first click highlights Big Bruce")
	var again := Kickers.click_slot(0, 0)
	check(bool(again["confirm"]), "check 1 clicking the highlighted card confirms")
	check(Kickers.id_for_slot(0) == Kickers.BIG_BRUCE and Kickers.id_for_slot(1) == Kickers.WALK_ON, "the two slots are Big Bruce and The Walk-On")
	var bruce := KickerStats.new()
	Kickers.apply_to(bruce, Kickers.BIG_BRUCE)
	check(near(bruce.range_per_power, 0.75), "check 1 Big Bruce range per power is 0.75")
	check(near(bruce.red_tip_start, 90.0) and near(bruce.red_tip_noise, 7.0), "check 2 Big Bruce red tip starts at 90 with noise 7")
	check(near(bruce.accuracy_speed, KickConstants.ACCURACY_FALL_PER_SEC * 1.1), "Big Bruce accuracy needle is 1.1 times as fast")
	check(bruce.ball_type == "barn_burner", "Big Bruce kicks a Barn Burner")
	var quiet := RandomNumberGenerator.new()
	quiet.seed = 3
	var calm := KickLogic.accuracy_with_red_tip(89.0, 0.0, quiet, bruce.red_tip_start, bruce.red_tip_noise)
	check(calm == 0.0, "power 89 is under Big Bruce's red tip")
	var shaky := RandomNumberGenerator.new()
	shaky.seed = 3
	var wild := KickLogic.accuracy_with_red_tip(92.0, 0.0, shaky, bruce.red_tip_start, bruce.red_tip_noise)
	check(wild != 0.0 and absf(wild) <= 7.0, "check 2 power 92 adds a wobble of at most 7, got %s" % wild)
	var posts := KickLogic.judge(76.0, 35.0, 3.08, "barn_burner")
	check(bool(posts["bank"]) and str(posts["text"]) == "GOOD", "check 3 a post hit with range to spare is a BANK SHOT and GOOD")
	var barely := KickLogic.judge(36.0, 35.0, 3.08, "barn_burner")
	check(not bool(barely["bank"]) and str(barely["text"]) == "DOINK", "check 3 a post hit with barely enough range stays a DOINK")
	check(str(KickLogic.judge(20.0, 35.0, 0.0, "barn_burner")["text"]) == "SHORT", "Barn Burner does not save a short kick")
	var walk := KickerStats.new()
	Kickers.apply_to(walk, Kickers.WALK_ON)
	check(near(walk.red_tip_start, 95.0) and near(walk.range_per_power, 0.67) and walk.ball_type == "standard", "check 4 The Walk-On keeps the normal meter and ball")
	check(walk.rerolls_per_run == 2, "check 4 The Walk-On gets 2 rerolls")
	var walked := RunLogic.new()
	walked.start_with_kicker(Kickers.WALK_ON)
	check(walked.rerolls_left == 2 and walked.kicker_id == Kickers.WALK_ON, "starting as The Walk-On shows Reroll: 2 left")
	check(not Kickers.has_portrait(Kickers.BIG_BRUCE), "check 5 a missing portrait file falls back to the shape")
	check(ResourceLoader.exists("res://scripts/Kickers.gd"), "a file that is really there would be drawn")
	check(str(Kickers.get_def(Kickers.BIG_BRUCE)["portrait_path"]) == "res://art/kickers/big_bruce.png", "Big Bruce looks for res://art/kickers/big_bruce.png")
	var carried := RunLogic.new()
	carried.start_with_kicker(Kickers.BIG_BRUCE)
	carried.grant(Upgrades.BIG_LEG)
	check(near(carried.stats.range_per_power, 0.75) and carried.stats.range_bonus == 6.0, "Big Bruce kept his leg and an upgrade")
	carried.start_with_kicker(Kickers.WALK_ON)
	check(near(carried.stats.range_per_power, 0.67) and carried.stats.range_bonus == 0.0, "check 6 the next kicker does not keep the last stats")
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
	check(near(walk.range_per_power, 0.67) and walk.range_bonus == 0.0, "Walk-On kick 1 has no range bonus")
	var low := KickLogic.new()
	low.stats = walk
	_lock_power_at(low, 20.0)
	check(near(low.power, 20.0) and near(low.max_range, 29.4), "check 1 P=20 max range is 29.4, got %s" % low.max_range)
	check(near(low.travel_yards, 29.4), "check 1 the ball travels 29.4 yards, not a fixed length")
	check(low.result_text == "SHORT" and low.perfect and not low.reached_uprights, "check 1 and 4 a dead-center low kick is SHORT, never GOOD")
	check(near(low.flight_duration, KickLogic.flight_time_seconds(29.4)), "check 1 flight time uses the yards this ball flies")
	low.advance(low.flight_duration)
	check(near(low.ball_forward_yards, 29.4) and low.ball_forward_yards < 35.0, "check 1 the ball stops several yards short of the posts")
	check(low.detail_line() == "P = 20, max range = 29.4 yd, kick = 35 yd, result = SHORT", "check 1 numbers read '%s'" % low.detail_line())
	var mid := KickLogic.new()
	mid.stats = walk
	_lock_power_at(mid, 50.0)
	check(near(mid.max_range, 49.5) and near(mid.travel_yards, 49.5), "check 2 P=50 flies 49.5 yards, got %s" % mid.travel_yards)
	check(mid.result_text == "GOOD" and mid.reached_uprights, "check 2 centered P=50 is GOOD")
	var at_posts := mid.flight_duration * (35.0 / mid.travel_yards)
	mid.advance(at_posts)
	check(near(mid.ball_forward_yards, 35.0, 0.02), "check 2 the moving ball reaches the uprights, got %s" % mid.ball_forward_yards)
	check(near(mid.ball_lateral_yards, mid.offset_yards, 0.02), "the result offset is the ball's sideways spot at the posts")
	mid.advance(mid.flight_duration)
	check(near(mid.ball_forward_yards, 49.5), "check 2 the ball finishes past the posts, at max range")
	check(mid.ball_forward_yards > low.ball_forward_yards, "check 2 P=50 travels farther than P=20")
	check(mid.detail_line() == "P = 50, max range = 49.5 yd, kick = 35 yd, result = GOOD", "check 2 numbers read '%s'" % mid.detail_line())
	var full := KickLogic.new()
	full.stats = walk
	full.set_seed(1)
	_lock_power_at(full, 100.0)
	check(near(full.max_range, 83.0) and near(full.travel_yards, 83.0), "check 3 P=100 flies 83 yards, got %s" % full.travel_yards)
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
	check(near(earlier.travel_yards, 83.0), "the previous lock flew 83 yards")
	_lock_power_at(earlier, 20.0)
	check(earlier.result_text == "SHORT" and near(earlier.travel_yards, 29.4), "the new lock throws away the old range")
	run.resolve_kick(earlier.result_text, earlier.offset_yards, earlier.perfect)
	check(run.kick_number == 1 and near(run.distance_yards(), 35.0) and run.attempts == 1 and run.phase == RunLogic.Phase.PLAYING, "check 5 a short miss with an attempt left stays on kick 1")
	check(run.begin_retry() and not run.is_first_ball, "check 5 the retry is still kick 1")
	var again := KickLogic.new()
	again.stats = run.stats
	again.kick_distance = run.distance_yards()
	_lock_power_at(again, 20.0)
	check(run.kick_number == 1 and near(again.kick_distance, 35.0), "check 5 the retry is still 35 yards")
	check(near(again.max_range, 29.4) and near(again.travel_yards, 29.4) and again.result_text == "SHORT", "check 5 the retry flies on the new P, not the earlier 83")
	again.advance(again.flight_duration)
	check(near(again.ball_forward_yards, 29.4), "check 5 the retry ball stops at 29.4 yards")
