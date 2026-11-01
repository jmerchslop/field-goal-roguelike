extends Node2D

# Draws the field and reads the keyboard.
# Kick rules live in KickLogic. The run lives in RunLogic.

const ScreenshotDriverScript := preload("res://scripts/ScreenshotDriver.gd")

var logic := KickLogic.new()
var run := RunLogic.new()
var _taking_pictures := false


func _ready() -> void:
	run.new_run()
	load_current_kick()
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
	logic.kick_distance = run.distance_yards()
	logic.start_lateral_yards = run.spot_yards
	logic.sync_tee()
	queue_redraw()


func settle_kick() -> void:
	if logic.phase == KickLogic.Phase.RESULT:
		run.resolve_kick(logic.result_text, logic.offset_yards, logic.perfect)


func advance_run() -> bool:
	if not run.go_to_next_kick():
		return false
	load_current_kick()
	return true


func restart_run() -> void:
	run.new_run()
	load_current_kick()


func force_spot_side(side: int) -> void:
	run.set_next_side(side)


func play_locked_kick(power_value: float) -> void:
	# Used by the picture taker. It is the same three Space presses as a player.
	logic.press_space()
	logic.advance(power_value / KickConstants.POWER_RISE_PER_SEC)
	logic.press_space()
	logic.advance(power_value / KickConstants.ACCURACY_FALL_PER_SEC)
	logic.press_space()
	logic.advance(logic.flight_duration)


func script_good_kick() -> void:
	# Counts a centered make without flying the ball. Pictures use this to reach a later kick.
	run.resolve_kick("GOOD", 0.0, false)


func _process(delta: float) -> void:
	if _taking_pictures:
		return
	if run.phase == RunLogic.Phase.PLAYING and logic.phase != KickLogic.Phase.RESULT:
		var direction := 0.0
		if Input.is_key_pressed(KEY_LEFT):
			direction -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			direction += 1.0
		if direction != 0.0:
			logic.aim(direction, delta)
		logic.advance(delta)
		settle_kick()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _taking_pictures:
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_R and run.accepts_restart():
		restart_run()
		return
	if key.keycode != KEY_SPACE:
		return
	if run.phase != RunLogic.Phase.PLAYING:
		return
	if logic.phase == KickLogic.Phase.RESULT:
		settle_kick()
		advance_run()
		return
	logic.press_space()
	queue_redraw()


func _draw() -> void:
	_draw_field()
	_draw_uprights()
	if logic.phase == KickLogic.Phase.AIMING or logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY:
		_draw_arrow()
	_draw_ball()
	_draw_meter()
	_draw_hud()
	if run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN:
		_draw_end_screen()
	elif logic.phase == KickLogic.Phase.RESULT:
		_draw_result()


func _draw_field() -> void:
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), KickConstants.COLOR_FIELD)
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.UPRIGHT_Y_PX), KickConstants.COLOR_ENDZONE)
	draw_line(
		Vector2(0, KickConstants.UPRIGHT_Y_PX),
		Vector2(KickConstants.METER_PANEL_LEFT, KickConstants.UPRIGHT_Y_PX),
		KickConstants.COLOR_GOAL_LINE,
		2.0,
		true
	)


func _draw_uprights() -> void:
	var center_x := KickConstants.WINDOW_WIDTH * 0.5
	var half := KickConstants.POST_SEPARATION_YARDS * 0.5 * KickConstants.PIXELS_PER_YARD
	var y := KickConstants.UPRIGHT_Y_PX
	var post_size := Vector2(KickConstants.POST_WIDTH_PX, KickConstants.POST_HEIGHT_PX)
	draw_line(
		Vector2(center_x - half, y),
		Vector2(center_x + half, y),
		KickConstants.COLOR_POST,
		KickConstants.CROSSBAR_WIDTH_PX,
		true
	)
	draw_rect(Rect2(Vector2(center_x - half - post_size.x * 0.5, y - post_size.y * 0.5), post_size), KickConstants.COLOR_POST)
	draw_rect(Rect2(Vector2(center_x + half - post_size.x * 0.5, y - post_size.y * 0.5), post_size), KickConstants.COLOR_POST)


func _draw_arrow() -> void:
	# The arrow starts on the ball and points straight up the field when aim is 0.
	# It does not turn itself toward the posts.
	var tee := KickConstants.screen_pos(logic.kick_distance, 0.0, logic.start_lateral_yards)
	var aim := deg_to_rad(logic.aim_degrees)
	var direction := Vector2(sin(aim), -cos(aim))
	var start := tee + direction * (KickConstants.BALL_RADIUS_PX + 6.0)
	var tip := tee + direction * (KickConstants.AIM_ARROW_YARDS * KickConstants.PIXELS_PER_YARD)
	draw_line(start, tip, KickConstants.COLOR_ARROW_EDGE, KickConstants.ARROW_WIDTH_PX + 3.0, true)
	draw_line(start, tip, KickConstants.COLOR_ARROW, KickConstants.ARROW_WIDTH_PX, true)
	var back := tip - direction * KickConstants.ARROW_HEAD_PX
	var side := Vector2(direction.y, -direction.x) * (KickConstants.ARROW_HEAD_PX * 0.55)
	draw_line(tip, back + side, KickConstants.COLOR_ARROW, KickConstants.ARROW_WIDTH_PX, true)
	draw_line(tip, back - side, KickConstants.COLOR_ARROW, KickConstants.ARROW_WIDTH_PX, true)


func _draw_ball() -> void:
	var ground := KickConstants.screen_pos(logic.kick_distance, logic.ball_forward_yards, logic.ball_lateral_yards)
	var lift := KickConstants.BALL_LIFT_PX * logic.ball_height
	var ball_center := ground + Vector2(0.0, -lift)
	var radius := KickConstants.BALL_RADIUS_PX * (1.0 + logic.ball_height)
	draw_circle(ground, KickConstants.SHADOW_RADIUS_PX, KickConstants.COLOR_SHADOW)
	draw_circle(ball_center, radius + 2.0, KickConstants.COLOR_BALL_EDGE)
	draw_circle(ball_center, radius, KickConstants.COLOR_BALL)


func _draw_meter() -> void:
	var panel := Rect2(
		KickConstants.METER_PANEL_LEFT,
		KickConstants.METER_PANEL_TOP,
		KickConstants.METER_PANEL_RIGHT - KickConstants.METER_PANEL_LEFT,
		KickConstants.METER_PANEL_BOTTOM - KickConstants.METER_PANEL_TOP
	)
	draw_rect(panel, KickConstants.COLOR_METER_PANEL)
	var bar := Rect2(
		KickConstants.METER_BAR_LEFT,
		KickConstants.METER_BAR_TOP,
		KickConstants.METER_BAR_RIGHT - KickConstants.METER_BAR_LEFT,
		KickConstants.METER_BAR_BOTTOM - KickConstants.METER_BAR_TOP
	)
	draw_rect(bar, KickConstants.COLOR_METER_TRACK)
	_draw_band(-KickConstants.METER_INNER_BAND, KickConstants.METER_INNER_BAND, KickConstants.COLOR_INNER_BAND)
	_draw_band(-KickConstants.PERFECT_BAND, KickConstants.PERFECT_BAND, KickConstants.COLOR_PERFECT_BAND)
	_draw_band(KickConstants.RED_TIP_START, KickConstants.METER_MAX, KickConstants.COLOR_RED_TIP)
	var zero_y := KickConstants.meter_y(0.0)
	draw_line(
		Vector2(KickConstants.METER_BAR_LEFT, zero_y),
		Vector2(KickConstants.METER_BAR_RIGHT, zero_y),
		KickConstants.COLOR_ZERO,
		3.0,
		true
	)
	var needle_y := KickConstants.meter_y(logic.needle)
	var needle_color := KickConstants.COLOR_NEEDLE
	if logic.phase == KickLogic.Phase.POWER and logic.needle >= KickConstants.RED_TIP_START:
		needle_color = KickConstants.COLOR_RED_TIP
	elif logic.phase == KickLogic.Phase.ACCURACY and absf(logic.needle) <= KickConstants.PERFECT_BAND:
		needle_color = KickConstants.COLOR_ZERO
	draw_line(
		Vector2(KickConstants.METER_BAR_LEFT - 10.0, needle_y),
		Vector2(KickConstants.METER_BAR_RIGHT + 8.0, needle_y),
		needle_color,
		3.0,
		true
	)
	var title := "METER"
	if logic.phase == KickLogic.Phase.POWER:
		title = "POWER"
	elif logic.phase == KickLogic.Phase.ACCURACY:
		title = "ACCURACY"
	_text(Vector2(panel.position.x + 16.0, panel.position.y + 28.0), title, 18, KickConstants.COLOR_TEXT)
	_text(Vector2(panel.position.x + 12.0, zero_y - 8.0), "PERFECT", 14, KickConstants.COLOR_PERFECT_TEXT)
	_text(Vector2(KickConstants.METER_BAR_RIGHT + 8.0, KickConstants.meter_y(100.0) + 5.0), "100", 14, KickConstants.COLOR_TEXT)
	_text(Vector2(KickConstants.METER_BAR_RIGHT + 8.0, zero_y + 5.0), "0", 14, KickConstants.COLOR_TEXT)
	_text(Vector2(KickConstants.METER_BAR_RIGHT + 8.0, KickConstants.meter_y(-15.0) + 5.0), "-15", 14, KickConstants.COLOR_TEXT)


func _draw_band(low: float, high: float, color: Color) -> void:
	var top := KickConstants.meter_y(high)
	var bottom := KickConstants.meter_y(low)
	draw_rect(
		Rect2(KickConstants.METER_BAR_LEFT, top, KickConstants.METER_BAR_RIGHT - KickConstants.METER_BAR_LEFT, bottom - top),
		color
	)


func _draw_hud() -> void:
	var x := 24.0
	var y := 28.0
	_text(Vector2(x, y), "Kick %d of %d" % [run.kick_number, RunTable.count()], 22, KickConstants.COLOR_TEXT)
	y += 26.0
	_text(Vector2(x, y), "%s yd" % KickLogic.format_number(run.distance_yards()), 20, KickConstants.COLOR_TEXT)
	y += 24.0
	_text(Vector2(x, y), "Score %d    Streak %d" % [run.score, run.streak], 20, KickConstants.COLOR_TEXT)
	y += 24.0
	_text(Vector2(x, y), "Mult %s" % RunLogic._two_decimals(run.current_mult()), 20, KickConstants.COLOR_TEXT)
	y += 26.0
	_text(Vector2(x, y), "ATTEMPTS", 18, KickConstants.COLOR_TEXT)
	_draw_attempt_pips(x + 110.0, y - 5.0)
	y += 24.0
	_text(Vector2(x, y), "Aim %s°   negative is left" % KickLogic.format_angle(logic.aim_degrees), 16, KickConstants.COLOR_TEXT)
	if run.is_boss() and run.phase == RunLogic.Phase.PLAYING:
		# Sit this under the posts so the uprights stay visible.
		_text_centered("BOSS KICK", 118.0, 28, KickConstants.COLOR_BOSS)
	var hint := ""
	if run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN or run.accepts_restart():
		hint = "R: new run"
	elif logic.phase == KickLogic.Phase.AIMING:
		hint = "Hold Left or Right to aim.   Space starts the meter."
	elif logic.phase == KickLogic.Phase.POWER:
		hint = "Space locks power."
	elif logic.phase == KickLogic.Phase.ACCURACY:
		hint = "Space locks accuracy."
	elif logic.phase == KickLogic.Phase.RESULT:
		hint = "Space: next kick."
	if hint != "":
		_text_centered(hint, 708.0, 18, KickConstants.COLOR_TEXT)


func _draw_attempt_pips(origin_x: float, origin_y: float) -> void:
	for i in run.attempt_cap:
		var center := Vector2(origin_x + float(i) * KickConstants.ATTEMPT_PIP_GAP, origin_y)
		if i < run.attempts:
			draw_circle(center, KickConstants.ATTEMPT_PIP_RADIUS, KickConstants.COLOR_ATTEMPT)
		else:
			draw_circle(center, KickConstants.ATTEMPT_PIP_RADIUS, KickConstants.COLOR_TEXT, false, 2.0, true)


func _draw_result() -> void:
	var box := Rect2(KickConstants.RESULT_LEFT, KickConstants.RESULT_TOP, KickConstants.RESULT_WIDTH, KickConstants.RESULT_HEIGHT)
	draw_rect(box, KickConstants.COLOR_RESULT_SCRIM)
	var y := box.position.y + 42.0
	if logic.perfect:
		_text_centered("PERFECT!", y, 28, KickConstants.COLOR_PERFECT_TEXT)
		y += 32.0
	if run.down_the_middle:
		_text_centered("DOWN THE MIDDLE!", y, 26, KickConstants.COLOR_PERFECT_TEXT)
		y += 32.0
	var word_color := KickConstants.COLOR_GOOD if logic.result_text == "GOOD" else KickConstants.COLOR_MISS
	_text_centered(logic.result_text, y + 20.0, 60, word_color)
	y += 78.0
	if run.score_line != "":
		_text_centered(run.score_line, y, 22, KickConstants.COLOR_TEXT)
		y += 30.0
	if run.attempt_note != "":
		var note_color := KickConstants.COLOR_ATTEMPT if run.attempt_note == RunLogic.NOTE_EARNED else KickConstants.COLOR_TEXT
		_text_centered(run.attempt_note, y, 26, note_color)
		y += 32.0
	_text_centered(logic.detail_line(), y, 20, KickConstants.COLOR_TEXT)


func _draw_end_screen() -> void:
	var box := Rect2(KickConstants.RESULT_LEFT, KickConstants.RESULT_TOP, KickConstants.RESULT_WIDTH, KickConstants.RESULT_HEIGHT)
	draw_rect(box, KickConstants.COLOR_RESULT_SCRIM)
	var title := "WIN" if run.phase == RunLogic.Phase.WIN else "GAME OVER"
	var title_color := KickConstants.COLOR_GOOD if run.phase == RunLogic.Phase.WIN else KickConstants.COLOR_MISS
	_text_centered(title, box.position.y + 70.0, 64, title_color)
	_text_centered("Score %d" % run.score, box.position.y + 130.0, 32, KickConstants.COLOR_TEXT)
	_text_centered("Kicks made %d" % run.kicks_made, box.position.y + 172.0, 28, KickConstants.COLOR_TEXT)
	_text_centered("Longest make %s yd" % KickLogic.format_number(run.longest_make), box.position.y + 210.0, 28, KickConstants.COLOR_TEXT)


func _text(at: Vector2, text: String, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null or text == "":
		return
	var edge := Color(0, 0, 0, 0.85)
	draw_string(font, at + Vector2(-1, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, edge)
	draw_string(font, at + Vector2(1, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, edge)
	draw_string(font, at + Vector2(0, -1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, edge)
	draw_string(font, at + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, edge)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_centered(text: String, baseline_y: float, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null or text == "":
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var field_width := KickConstants.METER_PANEL_LEFT
	var x := (field_width - width) * 0.5
	_text(Vector2(x, baseline_y), text, size, color)
