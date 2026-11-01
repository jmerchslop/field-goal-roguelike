extends Control

# The 2D scoreboard drawn on top of the 3D field.
# Meter, attempts, result words. No field drawing in here.

var game


func _draw() -> void:
	if game == null:
		return
	var logic: KickLogic = game.logic
	var run: RunLogic = game.run
	_draw_meter(logic)
	_draw_hud(logic, run)
	if run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN:
		_draw_end_screen(run)
	elif logic.phase == KickLogic.Phase.RESULT:
		_draw_result(logic, run)


func _draw_meter(logic: KickLogic) -> void:
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


func _draw_hud(logic: KickLogic, run: RunLogic) -> void:
	draw_rect(Rect2(12, 8, 300, 168), Color(0.02, 0.05, 0.08, 0.42))
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
	_draw_attempt_pips(run, x + 110.0, y - 5.0)
	y += 24.0
	_text(Vector2(x, y), "Aim %s°   negative is left" % KickLogic.format_angle(logic.aim_degrees), 16, KickConstants.COLOR_TEXT)
	if run.is_boss() and run.phase == RunLogic.Phase.PLAYING:
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


func _draw_attempt_pips(run: RunLogic, origin_x: float, origin_y: float) -> void:
	for i in run.attempt_cap:
		var center := Vector2(origin_x + float(i) * KickConstants.ATTEMPT_PIP_GAP, origin_y)
		if i < run.attempts:
			draw_circle(center, KickConstants.ATTEMPT_PIP_RADIUS, KickConstants.COLOR_ATTEMPT)
		else:
			draw_circle(center, KickConstants.ATTEMPT_PIP_RADIUS, KickConstants.COLOR_TEXT, false, 2.0, true)


func _draw_result(logic: KickLogic, run: RunLogic) -> void:
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


func _draw_end_screen(run: RunLogic) -> void:
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
	var edge := Color(0, 0, 0, 0.88)
	draw_string(font, at + Vector2(-2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, edge)
	draw_string(font, at + Vector2(2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, edge)
	draw_string(font, at + Vector2(0, -2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, edge)
	draw_string(font, at + Vector2(0, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, edge)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_centered(text: String, baseline_y: float, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null or text == "":
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var field_width := KickConstants.METER_PANEL_LEFT
	var x := (field_width - width) * 0.5
	_text(Vector2(x, baseline_y), text, size, color)
