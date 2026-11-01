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
	check(near(kick.flight_duration, 1.9), "flight time for 35 yd is 1.9s, got %s" % kick.flight_duration)
	check(kick.result_text == "GOOD", "centered P=40 is GOOD")
	kick.advance(kick.flight_duration * 0.5)
	check(near(kick.ball_height, 1.0), "mid-flight height is 1, got %s" % kick.ball_height)
	check(near(kick.ball_forward_yards, 17.5), "mid-flight is halfway to the posts, got %s" % kick.ball_forward_yards)
	check(near(kick.ball_lateral_yards, 0.0), "a straight kick stays centered")
	kick.advance(kick.flight_duration)
	check(kick.phase == KickLogic.Phase.RESULT, "the flight ends on the result")
	check(near(kick.ball_height, 0.0, 0.001), "the ball is back on the ground at the end")
	check(near(kick.ball_forward_yards, 35.0), "the ball reached the uprights' line")
	var full := KickLogic.range_yards(100.0)
	check(absf(full - 83.0) < 0.001, "full power range is about 83 yd, got %s" % full)
	var short_kick := _kick_power_accuracy(20.0, 0.0)
	check(near(short_kick.flight_duration, KickLogic.flight_time_seconds(35.0)), "flight time uses the kick distance even when the ball is short")
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
