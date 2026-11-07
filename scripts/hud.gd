extends Control

# The 2D scoreboard drawn on top of the 3D field.
# Meter, attempts, result words. No field drawing in here.

var game


func _draw() -> void:
	if game == null:
		return
	if game.selecting:
		_draw_kicker_select()
		return
	var logic: KickLogic = game.logic
	var run: RunLogic = game.run
	_draw_weather_tint(run)
	_draw_meter(logic, run)
	_draw_hud(logic, run)
	_draw_wind(logic, run)
	_draw_laser(logic, run)
	if run.awaiting_mulligan:
		_draw_mulligan()
	elif run.awaiting_offer:
		_draw_offer(run)
	elif run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN:
		_draw_end_screen(run)
	elif logic.phase == KickLogic.Phase.RESULT:
		_draw_result(logic, run)


func _draw_meter(logic: KickLogic, run: RunLogic) -> void:
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
	var stats: KickerStats = logic.stats
	_draw_band(-stats.good_band, stats.good_band, KickConstants.COLOR_INNER_BAND)
	_draw_band(-stats.perfect_band, stats.perfect_band, KickConstants.COLOR_PERFECT_BAND)
	_draw_band(stats.red_tip_start, KickConstants.METER_MAX, KickConstants.COLOR_RED_TIP)
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
	if logic.phase == KickLogic.Phase.POWER and logic.needle >= logic.stats.red_tip_start:
		needle_color = KickConstants.COLOR_RED_TIP
	elif logic.phase == KickLogic.Phase.ACCURACY and absf(logic.needle) <= KickConstants.PERFECT_BAND:
		needle_color = KickConstants.COLOR_ZERO
	var fade := RunLogic.iced_needle_alpha(run.needle_fades(), logic.phase == KickLogic.Phase.ACCURACY, logic.power, logic.needle)
	needle_color.a = fade
	if fade > 0.02:
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


func _draw_weather_tint(run: RunLogic) -> void:
	var tint := Color(0, 0, 0, 0)
	if run.has_rain():
		tint = Color(0.25, 0.45, 0.9, 0.22)
	elif run.weather == RunLogic.SNOW:
		tint = Color(0.93, 0.95, 1.0, 0.28)
	if tint.a > 0.0:
		draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), tint)


func _draw_condition(run: RunLogic) -> void:
	var name := run.weather
	var color := KickConstants.COLOR_TEXT
	if run.weather == RunLogic.THIN_AIR:
		var badge := Rect2(470, 132, 220, 36)
		draw_rect(badge, Color(0.92, 0.78, 0.12, 0.92))
		_text_centered(name, 158.0, 22, Color(0.15, 0.1, 0.02))
		return
	if run.weather == RunLogic.BIG_GAME or run.weather == RunLogic.ICED or run.weather == RunLogic.SQUEEZE or run.weather == RunLogic.MONSOON:
		color = KickConstants.COLOR_BOSS
	_text_centered(name, 158.0, 22, color)
	if run.weather == RunLogic.BIG_GAME:
		_text_centered("Meter upgrades off", 184.0, 16, KickConstants.COLOR_TEXT)


func _draw_band(low: float, high: float, color: Color) -> void:
	var top := KickConstants.meter_y(high)
	var bottom := KickConstants.meter_y(low)
	draw_rect(
		Rect2(KickConstants.METER_BAR_LEFT, top, KickConstants.METER_BAR_RIGHT - KickConstants.METER_BAR_LEFT, bottom - top),
		color
	)


func _draw_hud(logic: KickLogic, run: RunLogic) -> void:
	var list_h := 22.0 * float(run.owned_ids().size())
	draw_rect(Rect2(12, 8, 360, 232.0 + list_h), Color(0.02, 0.05, 0.08, 0.42))
	var x := 24.0
	var y := 28.0
	_text(Vector2(x, y), "Kick %d of %d" % [run.kick_number, RunTable.count()], 22, KickConstants.COLOR_TEXT)
	y += 26.0
	_text(Vector2(x, y), "%s yd" % KickLogic.format_number(run.distance_yards()), 20, KickConstants.COLOR_TEXT)
	y += 22.0
	_text(Vector2(x, y), RunLogic.spot_label(run.spot_yards), 16, KickConstants.COLOR_ATTEMPT)
	y += 22.0
	_text(Vector2(x, y), "Score %d    Streak %d" % [run.score, run.streak], 20, KickConstants.COLOR_TEXT)
	y += 24.0
	_text(Vector2(x, y), "Mult %s" % RunLogic._two_decimals(run.current_mult()), 20, KickConstants.COLOR_TEXT)
	y += 26.0
	_text(Vector2(x, y), "ATTEMPTS", 18, KickConstants.COLOR_TEXT)
	_draw_attempt_pips(run, x + 110.0, y - 5.0)
	var pip_end := x + 110.0 + float(run.attempt_cap) * KickConstants.ATTEMPT_PIP_GAP + 6.0
	_text(Vector2(pip_end, y), "%d / cap %d" % [run.attempts, run.attempt_cap], 16, KickConstants.COLOR_TEXT)
	y += 22.0
	if run.kicker_id != "":
		var who := Kickers.get_def(run.kicker_id)
		_text(Vector2(x, y), str(who["name"]), 16, KickConstants.COLOR_TEXT)
		y += 18.0
		_text(Vector2(x, y), str(who["ball_name"]), 16, KickConstants.COLOR_ATTEMPT)
		y += 22.0
	else:
		y += 24.0
	_text(Vector2(x, y), "Aim %s°   negative is left" % KickLogic.format_angle(logic.aim_degrees), 16, KickConstants.COLOR_TEXT)
	y += 22.0
	for id in run.owned_ids():
		_text(Vector2(x, y), Upgrades.stack_label(str(id), int(run.stacks[id])), 16, KickConstants.COLOR_ATTEMPT)
		y += 20.0
	if run.is_boss() and run.phase == RunLogic.Phase.PLAYING:
		_text_centered("BOSS KICK", 118.0, 28, KickConstants.COLOR_BOSS)
	_draw_condition(run)
	if run.curse != "":
		_text_centered("%s   ends after kick %d" % [run.curse_label(), run.curse_end_kick], 286.0, 18, Color(0.72, 0.4, 0.95))
		if run.curse == RunLogic.CURSE_HOWLING:
			_text_centered("Wind pulls 1.5× harder", 310.0, 16, KickConstants.COLOR_ATTEMPT)
	var hint := ""
	if run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN or run.accepts_restart():
		hint = "R: choose a kicker"
	elif logic.phase == KickLogic.Phase.AIMING:
		hint = "Hold Left or Right to aim.   Space starts the meter."
		if run.can_practice():
			hint += "   P: practice."
		elif run.practicing:
			hint += "   Practice swing."
	elif logic.phase == KickLogic.Phase.POWER:
		hint = "Space locks power."
	elif logic.phase == KickLogic.Phase.ACCURACY:
		hint = "Space locks accuracy."
	elif logic.phase == KickLogic.Phase.RESULT:
		hint = "Space: continue."
	if hint != "" and not run.awaiting_offer and not run.awaiting_mulligan:
		_text_centered(hint, 708.0, 18, KickConstants.COLOR_TEXT)


var card_rects: Array = []
var kicker_rects: Array = []


func kicker_slot_at(point: Vector2) -> int:
	for i in kicker_rects.size():
		var rect: Rect2 = kicker_rects[i]
		if rect.has_point(point):
			return i
	return -1


func _draw_kicker_select() -> void:
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0.05, 0.08, 0.12, 0.72))
	_text_centered("Choose your kicker", 64.0, 36, KickConstants.COLOR_TEXT)
	kicker_rects = []
	var width := 460.0
	var gap := 40.0
	var left := (KickConstants.WINDOW_WIDTH - (width * 2.0 + gap)) * 0.5
	for i in Kickers.ALL.size():
		var info: Dictionary = Kickers.ALL[i]
		var rect := Rect2(left + float(i) * (width + gap), 96.0, width, 560.0)
		kicker_rects.append(rect)
		var picked := int(game.highlight) == i
		draw_rect(rect, Color(0.06, 0.08, 0.1, 0.94))
		draw_rect(rect, KickConstants.COLOR_ATTEMPT if picked else Color(0.7, 0.75, 0.7), false, 4.0 if picked else 2.0)
		_draw_portrait(info, Rect2(rect.position + Vector2(20, 16), Vector2(width - 40, 200)))
		var y := rect.position.y + 240.0
		_text(Vector2(rect.position.x + 18, y), str(info["name"]), 28, KickConstants.COLOR_ATTEMPT)
		y += 28.0
		y = _draw_wrapped_at(str(info["lore"]), rect.position.x + 18, y, width - 36, 16)
		y += 8.0
		_text(Vector2(rect.position.x + 18, y), "Excels: %s" % str(info["excels"]), 16, KickConstants.COLOR_GOOD)
		y += 22.0
		_text(Vector2(rect.position.x + 18, y), "Downside: %s" % str(info["downside"]), 16, KickConstants.COLOR_MISS)
		y += 26.0
		_text(Vector2(rect.position.x + 18, y), "Ball: %s" % str(info["ball_name"]), 18, KickConstants.COLOR_TEXT)
		y += 22.0
		_draw_wrapped_at(str(info["ball_description"]), rect.position.x + 18, y, width - 36, 15)
	_text_centered("1 or 2 to highlight.  Space or click again to start.", 690.0, 20, KickConstants.COLOR_TEXT)


var _portraits := {}


func _portrait_texture(path: String) -> Texture2D:
	if _portraits.has(path):
		return _portraits[path]
	var imported := load(path) as Texture2D
	if imported == null:
		return null
	var image := imported.get_image()
	if image == null:
		return null
	var picture := ImageTexture.create_from_image(image)
	_portraits[path] = picture
	return picture


func _fit_rect(area: Rect2, texture_size: Vector2) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return area
	var scale := minf(area.size.x / texture_size.x, area.size.y / texture_size.y)
	var size := texture_size * scale
	return Rect2(area.position + (area.size - size) * 0.5, size)


func _draw_portrait(info: Dictionary, area: Rect2) -> void:
	var id := str(info["id"])
	if Kickers.has_portrait(id):
		var picture := _portrait_texture(str(info["portrait_path"]))
		if picture != null:
			var fitted := _fit_rect(area, picture.get_size())
			draw_texture_rect(picture, fitted, false)
			return
	var ink: Color = info["color"]
	if str(info["shape"]) == "square":
		var side := minf(area.size.x, area.size.y) * 0.7
		draw_rect(Rect2(area.position + (area.size - Vector2(side, side)) * 0.5, Vector2(side, side)), ink)
	else:
		var radius := minf(area.size.x, area.size.y) * 0.32
		draw_circle(area.position + area.size * 0.5, radius, ink)


func _draw_wrapped_at(text: String, x: float, y: float, width: float, size: int) -> float:
	var font := ThemeDB.fallback_font
	if font == null:
		return y
	var line := ""
	for word in text.split(" "):
		var trial := (line + word).strip_edges()
		if line != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			_text(Vector2(x, y), line.strip_edges(), size, KickConstants.COLOR_TEXT)
			y += float(size) + 4.0
			line = word + " "
		else:
			line = trial + " "
	if line.strip_edges() != "":
		_text(Vector2(x, y), line.strip_edges(), size, KickConstants.COLOR_TEXT)
		y += float(size) + 4.0
	return y


func card_index_at(point: Vector2) -> int:
	for i in card_rects.size():
		var rect: Rect2 = card_rects[i]
		if rect.has_point(point):
			return i
	return -1


func _draw_wind(logic: KickLogic, run: RunLogic) -> void:
	var anchor: Vector2 = game.world_to_screen(Vector3(8.2, 6.2, 0.4))
	var name := RunLogic.wind_name(run.wind_speed)
	_text(anchor + Vector2(-8, -8), name, 20, KickConstants.COLOR_TEXT)
	var kind := RunLogic.wind_flag_kind(run.wind_speed)
	if kind != "none":
		var reach := 2.2
		if kind == "medium":
			reach = 4.0
		elif kind == "long":
			reach = 6.5
		var radians := deg_to_rad(run.wind_direction)
		var tip_world := Vector3(8.2, 6.2, 0.4) + Vector3(sin(radians), 0.0, -cos(radians)) * reach
		var tip: Vector2 = game.world_to_screen(tip_world)
		draw_line(anchor, tip, Color(0.95, 0.95, 0.9), 4.0)
		draw_circle(tip, 5.0, Color(0.95, 0.82, 0.16))
	if not logic.stats.flag_reader:
		return
	_text(anchor + Vector2(-8, 18), RunLogic.wind_readout(run.wind_speed, run.wind_direction), 16, KickConstants.COLOR_ATTEMPT)


func _draw_laser(logic: KickLogic, run: RunLogic) -> void:
	if not logic.stats.laser_line or logic.phase != KickLogic.Phase.AIMING:
		return
	var drift := KickLogic.drift_at_uprights(float(logic.wind_speed), logic.wind_direction, logic.kick_distance, logic.stats.low_drive_stacks, logic.stats.wind_breaker_stacks, logic.stats.ball_type)
	if run.curse == RunLogic.CURSE_HOWLING:
		drift *= 1.5
	var far := KickLogic.preview_forward(logic.kick_distance)
	var previous := Vector2.ZERO
	var started := false
	for step in 9:
		var forward := far * float(step) / 8.0
		var lateral := KickLogic.path_lateral(logic.start_lateral_yards, forward, logic.aim_degrees, logic.kick_distance, drift)
		var point: Vector2 = game.world_to_screen(Vector3(lateral, 0.35, logic.kick_distance - forward))
		if started and step % 2 == 0:
			draw_line(previous, point, Color(0.95, 0.82, 0.16), 3.0)
		previous = point
		started = true


func _draw_mulligan() -> void:
	var box := Rect2(180, 250, 740, 220)
	draw_rect(box, KickConstants.COLOR_RESULT_SCRIM)
	_text_centered("Use Mulligan? (M)", box.position.y + 80.0, 42, KickConstants.COLOR_ATTEMPT)
	_text_centered("M retakes this kick.  Space accepts the miss.", box.position.y + 140.0, 22, KickConstants.COLOR_TEXT)


func _draw_offer(run: RunLogic) -> void:
	card_rects = []
	var count := run.offer.size()
	if count == 0:
		_text_centered("No upgrades left.  S continues.", 460.0, 28, KickConstants.COLOR_TEXT)
	var width := 230.0
	var gap := 16.0
	var total := float(count) * width + float(maxi(count - 1, 0)) * gap
	var left := (KickConstants.METER_PANEL_LEFT - total) * 0.5
	for i in count:
		var rect := Rect2(left + float(i) * (width + gap), 390.0, width, 250.0)
		card_rects.append(rect)
		draw_rect(rect, Color(0.05, 0.08, 0.1, 0.92))
		var card: Dictionary = run._as_card(run.offer[i])
		var id := str(card["id"])
		var cursed := bool(card.get("cursed", false))
		draw_rect(rect, Upgrades.border_color(id, cursed), false, 4.0)
		var info := Upgrades.get_def(id)
		var stacks := int(run.stacks.get(id, 0)) + 1
		var title := "%d  %s" % [i + 1, str(info["name"])]
		if cursed:
			title = "%d  CURSED  %s" % [i + 1, str(info["name"])]
		_text(rect.position + Vector2(14, 36), title, 20, KickConstants.COLOR_ATTEMPT)
		var label := Upgrades.stack_label(id, stacks)
		if cursed:
			label = Upgrades.doubled_line(id)
		_text(rect.position + Vector2(14, 64), label, 16, KickConstants.COLOR_TEXT)
		var blurb := str(info["description"])
		if cursed:
			blurb = "Curse: %s. Lasts until the end of this quarter." % RunLogic.curse_name(str(card.get("curse", "")))
		_draw_wrapped(blurb, Rect2(rect.position + Vector2(14, 96), Vector2(width - 28, 110)), 16)
	var reroll_y := 660.0
	_text_centered("Reroll: %d left    F rerolls    S skips (+10)" % run.rerolls_left, reroll_y, 18, KickConstants.COLOR_TEXT)


func _draw_wrapped(text: String, area: Rect2, size: int) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var line := ""
	var y := area.position.y
	for word in text.split(" "):
		var trial := (line + word).strip_edges()
		if line != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > area.size.x:
			_text(Vector2(area.position.x, y), line.strip_edges(), size, KickConstants.COLOR_TEXT)
			y += float(size) + 4.0
			line = word + " "
		else:
			line = trial + " "
	if line.strip_edges() != "":
		_text(Vector2(area.position.x, y), line.strip_edges(), size, KickConstants.COLOR_TEXT)


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
	if logic.bank_shot:
		_text_centered("BANK SHOT!", y, 36, KickConstants.COLOR_ATTEMPT)
		y += 40.0
	if logic.insured:
		_text_centered("INSURED!", y, 36, KickConstants.COLOR_ATTEMPT)
		y += 40.0
	if logic.perfect:
		_text_centered("PERFECT!", y, 28, KickConstants.COLOR_PERFECT_TEXT)
		y += 32.0
	if run.down_the_middle and logic.result_text == "GOOD":
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
	var box := Rect2(KickConstants.RESULT_LEFT, KickConstants.RESULT_TOP, KickConstants.RESULT_WIDTH, KickConstants.RESULT_HEIGHT + 56.0)
	draw_rect(box, KickConstants.COLOR_RESULT_SCRIM)
	var title := "WIN" if run.phase == RunLogic.Phase.WIN else "GAME OVER"
	var title_color := KickConstants.COLOR_GOOD if run.phase == RunLogic.Phase.WIN else KickConstants.COLOR_MISS
	_text_centered(title, box.position.y + 70.0, 64, title_color)
	_text_centered("Score %d" % run.score, box.position.y + 130.0, 32, KickConstants.COLOR_TEXT)
	_text_centered("Kicks made %d" % run.kicks_made, box.position.y + 172.0, 28, KickConstants.COLOR_TEXT)
	_text_centered("Longest make %s yd" % KickLogic.format_number(run.longest_make), box.position.y + 210.0, 28, KickConstants.COLOR_TEXT)
	if run.kicker_id != "":
		_text_centered("Kicker: %s" % str(Kickers.get_def(run.kicker_id)["name"]), box.position.y + 248.0, 22, KickConstants.COLOR_TEXT)
	var owned := ""
	for id in run.owned_ids():
		if owned != "":
			owned += ", "
		owned += str(Upgrades.get_def(str(id))["name"])
	if owned == "":
		owned = "none"
	_text_centered("Upgrades: %s" % owned, box.position.y + 276.0, 16, KickConstants.COLOR_TEXT)
	var cursed_names := ""
	for name in run.curses_taken:
		if cursed_names != "":
			cursed_names += ", "
		cursed_names += str(name)
	if cursed_names == "":
		cursed_names = "none"
	_text_centered("Curses: %s" % cursed_names, box.position.y + 298.0, 16, Color(0.78, 0.5, 0.95))


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
