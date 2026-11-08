extends Control

# The 2D scoreboard drawn on top of the 3D field.
# Meter, attempts, result words. No field drawing in here.

var game


func _draw() -> void:
	if game == null:
		return
	var front: FrontEnd = game.front
	if front != null and front.screen == FrontEnd.Screen.TITLE:
		_draw_title(front)
		return
	if front != null and front.screen == FrontEnd.Screen.MAIN:
		_draw_main_menu(front)
		return
	if front != null and front.screen == FrontEnd.Screen.OPTIONS:
		_draw_options(front)
		return
	if game.showing_records or (front != null and front.screen == FrontEnd.Screen.RECORDS):
		_draw_records()
		_draw_save_note()
		return
	if game.selecting:
		_draw_kicker_select()
		_draw_save_note()
		return
	if game.run.awaiting_shop:
		_draw_shop(game.run)
		return
	var logic: KickLogic = game.logic
	var run: RunLogic = game.run
	_draw_weather_tint(run)
	var on_meter := logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY or logic.phase == KickLogic.Phase.FLIGHT or logic.phase == KickLogic.Phase.RESULT
	if not run.meter_hidden(on_meter, game.meter_time):
		_draw_meter(logic, run)
	_draw_hud(logic, run)
	_draw_loadout_rail(run)
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
	_draw_trophy(run)
	_draw_cash_belt(run)
	if run.curse_prompt:
		_draw_curse_prompt(run)
	_draw_save_note()
	_draw_slot_tooltip()


func _draw_meter(logic: KickLogic, run: RunLogic) -> void:
	# Small enough that the frame stays off the uprights, the kicker, and the corner text.
	var gauge_w := 332.0
	var gauge_h := gauge_w * 625.0 / 1003.0
	var origin := Vector2(KickConstants.WINDOW_WIDTH - 18.0 - gauge_w, KickConstants.WINDOW_HEIGHT - 14.0 - gauge_h)
	var scale := gauge_w / 1003.0
	var hub := origin + Vector2(504.0, 510.0) * scale
	var inner := 300.0 * scale
	var outer := 392.0 * scale
	var stats: KickerStats = logic.stats
	var layout := MeterGauge.accuracy_layout(stats.perfect_band, stats.good_band)
	# Live wedges and the orange fill sit under the keyed frame so the labels stay on top.
	_draw_annulus(hub, inner, outer, 90.0, float(layout["band_top"]), Color(0.78, 0.1, 0.08, 0.94))
	_draw_annulus(hub, inner, outer, float(layout["band_top"]), float(layout["perfect_top"]), Color(0.93, 0.74, 0.12, 0.94))
	_draw_annulus(hub, inner, outer, float(layout["perfect_top"]), float(layout["perfect_bottom"]), Color(0.2, 0.78, 0.28, 0.96))
	_draw_annulus(hub, inner, outer, float(layout["perfect_bottom"]), float(layout["band_bottom"]), Color(0.93, 0.74, 0.12, 0.94))
	_draw_annulus(hub, inner, outer, float(layout["band_bottom"]), 0.0, Color(0.78, 0.1, 0.08, 0.94))
	var shown := logic.fill_power
	if shown > 0.5:
		var tip := stats.red_tip_start
		var orange_to := minf(shown, tip)
		_draw_annulus(hub, inner, outer, 180.0, MeterGauge.power_angle(orange_to), Color(1.0, 0.48, 0.05, 0.94))
		if shown > tip:
			var pulse := 0.72 + 0.28 * sin(float(Time.get_ticks_msec()) * 0.012)
			var danger_from := MeterGauge.power_angle(tip)
			var danger_to := MeterGauge.power_angle(shown)
			if danger_from - danger_to < 10.0:
				danger_from = danger_to + 10.0
			_draw_annulus(hub, inner, outer, danger_from, danger_to, Color(0.95, 0.05, 0.04, pulse))
	var art := _meter_art()
	if art != null:
		draw_texture_rect(art, Rect2(origin, Vector2(gauge_w, gauge_h)), false)
	# The baked needle crossed the painted PERFECT word. Draw it again so the label stays whole.
	_draw_wedge_label(hub, (inner + outer) * 0.5, 45.0, "PERFECT")
	var fade_sample := logic.needle
	if logic.needle_angle > MeterGauge.MAX_ANGLE:
		fade_sample = 100.0
	var fade := RunLogic.iced_needle_alpha(run.needle_fades(), logic.phase == KickLogic.Phase.ACCURACY, logic.power, fade_sample)
	if fade > 0.02:
		_draw_gauge_needle(hub, outer - 8.0 * scale, logic.needle_angle, fade)
	draw_circle(hub, 16.0 * scale, Color(0.42, 0.4, 0.44, 1.0))
	draw_circle(hub, 7.0 * scale, Color(0.72, 0.7, 0.68, 1.0))


func _gauge_point(hub: Vector2, radius: float, degrees: float) -> Vector2:
	var rad := deg_to_rad(degrees)
	return hub + Vector2(cos(rad), -sin(rad)) * radius


func _draw_annulus(hub: Vector2, inner: float, outer: float, from_deg: float, to_deg: float, color: Color) -> void:
	if absf(from_deg - to_deg) < 0.2:
		return
	var steps := maxi(int(absf(from_deg - to_deg) / 4.0), 2)
	var points := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / float(steps)
		points.append(_gauge_point(hub, outer, lerpf(from_deg, to_deg, t)))
	for i in steps + 1:
		var t := float(steps - i) / float(steps)
		points.append(_gauge_point(hub, inner, lerpf(from_deg, to_deg, t)))
	draw_colored_polygon(points, color)


func _draw_gauge_needle(hub: Vector2, length: float, degrees: float, alpha: float) -> void:
	var rad := deg_to_rad(degrees)
	var dir := Vector2(cos(rad), -sin(rad))
	var side := Vector2(-dir.y, dir.x)
	var color := Color(0.86, 0.88, 0.9, alpha)
	var points := PackedVector2Array([
		hub + side * 5.0,
		hub - side * 5.0,
		hub + dir * length,
	])
	draw_colored_polygon(points, color)


func _draw_wedge_label(hub: Vector2, radius: float, degrees: float, text: String) -> void:
	var at := _gauge_point(hub, radius, degrees)
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, at + Vector2(-width * 0.5, 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.97, 0.98, 0.95, 0.95))


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
	draw_rect(Rect2(12, 64, 390, 248), Color(0.02, 0.05, 0.08, 0.42))
	var x := 24.0
	var y := 86.0
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
	if run.is_boss() and run.phase == RunLogic.Phase.PLAYING:
		_text_centered("BOSS KICK", 118.0, 28, KickConstants.COLOR_BOSS)
	_draw_condition(run)
	if run.has_curse(Loadout.HOWLING):
		_text_centered("Howling Wind   wind ×1.5   items ×1.15", 286.0, 18, Color(0.72, 0.4, 0.95))
	elif run.curse_ids.size() > 0:
		var names := ""
		for id in run.curse_ids:
			if names != "":
				names += ", "
			names += Loadout.piece_name(str(id))
		_text_centered(names, 286.0, 18, Color(0.72, 0.4, 0.95))
	var hint := ""
	if run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN:
		hint = ""
	elif run.accepts_restart():
		hint = "R: choose a kicker    Esc: main menu"
	elif logic.phase == KickLogic.Phase.AIMING:
		hint = "Hold %s or %s to aim.   %s starts the meter." % [Settings.key_label("aim_left"), Settings.key_label("aim_right"), Settings.key_label("confirm")]
		if run.can_practice():
			hint += "   P: practice."
		elif run.practicing:
			hint += "   Practice swing."
	elif logic.phase == KickLogic.Phase.POWER:
		hint = "%s locks power." % Settings.key_label("confirm")
	elif logic.phase == KickLogic.Phase.ACCURACY:
		hint = "%s locks accuracy." % Settings.key_label("confirm")
	elif logic.phase == KickLogic.Phase.RESULT:
		hint = "%s: continue." % Settings.key_label("confirm")
	if hint != "" and not run.awaiting_offer and not run.awaiting_mulligan and not run.curse_prompt:
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
	var shown_speed := run.shown_wind_speed()
	var name := RunLogic.wind_name(shown_speed)
	_text(anchor + Vector2(-8, -8), name, 20, KickConstants.COLOR_TEXT)
	var kind := RunLogic.wind_flag_kind(shown_speed)
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
	_text(anchor + Vector2(-8, 18), RunLogic.wind_readout(shown_speed, run.wind_direction), 16, KickConstants.COLOR_ATTEMPT)
	var preview_y := 40.0
	for line in run.upcoming_winds():
		_text(anchor + Vector2(-8, preview_y), str(line), 14, KickConstants.COLOR_TEXT)
		preview_y += 16.0


func _draw_laser(logic: KickLogic, run: RunLogic) -> void:
	if not logic.stats.laser_line or logic.phase != KickLogic.Phase.AIMING:
		return
	var blown := float(logic.wind_speed)
	if logic.howling_wind:
		blown *= 1.5
	var drift := KickLogic.drift_at_uprights(blown, logic.wind_direction, logic.kick_distance, 0, 0, logic.stats.ball_type) * logic.stats.drift_factor
	var far := logic.kick_distance if logic.stats.laser_full else KickLogic.preview_forward(logic.kick_distance)
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
		_text_centered("Nothing left to pick — press S to continue.", 430.0, 28, KickConstants.COLOR_TEXT)
	var width := 220.0
	var gap := 12.0
	var total := float(count) * width + float(maxi(count - 1, 0)) * gap
	var meter_left := KickConstants.WINDOW_WIDTH - 16.0 - 420.0
	var left := 260.0
	if count > 0 and left + total > meter_left - 16.0:
		left = maxf(16.0, meter_left - 16.0 - total)
	for i in count:
		var rect := Rect2(left + float(i) * (width + gap), 318.0, width, 210.0)
		card_rects.append(rect)
		var card: Dictionary = run.offer[i]
		var id := str(card.get("id", ""))
		var rank := int(card.get("rank", 1))
		var slot := str(card.get("slot", ""))
		draw_rect(rect, Color(0.05, 0.08, 0.1, 0.94))
		draw_rect(rect, _slot_color(slot), false, 4.0)
		_text(rect.position + Vector2(96, 32), "%d  %s" % [i + 1, Loadout.type_label(slot)], 16, _slot_color(slot))
		_draw_slot_icon(id, rank, slot, Rect2(rect.position + Vector2(14, 28), Vector2(72, 72)), true)
		_text(rect.position + Vector2(96, 62), Loadout.card_title(id, rank), 18, KickConstants.COLOR_ATTEMPT)
		_draw_wrapped(Loadout.effect_line(id, rank), Rect2(rect.position + Vector2(96, 84), Vector2(width - 110, 150)), 16)
	_text_centered("Reroll: %d left    %s rerolls    %s skips" % [run.rerolls_left, Settings.key_label("offer_reroll"), Settings.key_label("skip")], 640.0, 18, KickConstants.COLOR_TEXT)
	_text_centered("Skip takes nothing.", 666.0, 16, KickConstants.COLOR_TEXT)


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
	for label in run.owned_labels():
		if owned != "":
			owned += ", "
		owned += str(label)
	if owned == "":
		owned = "none"
	_text_centered("Loadout: %s" % owned, box.position.y + 276.0, 16, KickConstants.COLOR_TEXT)
	if run.new_record_score:
		_text_centered("NEW RECORD!", box.position.y + 150.0, 22, KickConstants.COLOR_ATTEMPT)
	if run.new_record_long:
		_text_centered("NEW RECORD!", box.position.y + 230.0, 22, KickConstants.COLOR_ATTEMPT)
	var back_line := "%s: trophy room    %s: main menu    R: choose a kicker" % [Settings.key_label("trophy"), Settings.key_label("back")]
	var back_font := ThemeDB.fallback_font
	if back_font != null:
		var back_width := back_font.get_string_size(back_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		_text(Vector2(box.position.x + (box.size.x - back_width) * 0.5, box.position.y + 320.0), back_line, 16, KickConstants.COLOR_TEXT)


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
	var field_width := KickConstants.WINDOW_WIDTH - 500.0
	var x := (field_width - width) * 0.5
	_text(Vector2(x, baseline_y), text, size, color)


var slot_hits: Array = []
var hover_slot := -1
var pinned_slot := -1
var _icons := {}
var _keyed_meter: Texture2D


func _process(_delta: float) -> void:
	if game == null or game._taking_pictures:
		return
	var mouse := get_viewport().get_mouse_position()
	var next := -1
	for i in slot_hits.size():
		var rect: Rect2 = slot_hits[i]["rect"]
		if rect.has_point(mouse):
			next = i
	if next != hover_slot:
		hover_slot = next
		queue_redraw()


func _draw_loadout_rail(run: RunLogic) -> void:
	slot_hits = []
	var entries: Array = [
		{"name": "Cleats", "id": run.cleats_id, "rank": run.cleats_rank, "slot": Loadout.CLEATS},
		{"name": "Helmet", "id": run.helmet_id, "rank": run.helmet_rank, "slot": Loadout.HELMET},
		{"name": "Gloves", "id": run.gloves_id, "rank": run.gloves_rank, "slot": Loadout.GLOVES},
	]
	for i in 2:
		var perk_id := ""
		var perk_rank := 0
		if i < run.perks.size():
			perk_id = str(run.perks[i].get("id", ""))
			perk_rank = int(run.perks[i].get("rank", 1))
		entries.append({"name": "Perk", "id": perk_id, "rank": perk_rank, "slot": Loadout.PERK})
	for i in 2:
		var curse_id := ""
		if i < run.curse_ids.size():
			curse_id = str(run.curse_ids[i])
		entries.append({"name": "Curse", "id": curse_id, "rank": 0, "slot": Loadout.CURSE})
	# One row at the top: equipment, then perks, then curses, with a gap between groups.
	var slot_w := 48.0
	var inner_gap := 8.0
	var group_gap := 22.0
	var equip_w := slot_w * 3.0 + inner_gap * 2.0
	var pair_w := slot_w * 2.0 + inner_gap
	var total := equip_w + group_gap + pair_w + group_gap + pair_w
	var cursor := (KickConstants.WINDOW_WIDTH - total) * 0.5
	var row_y := 8.0
	var xs: Array = []
	for i in 3:
		xs.append(cursor)
		cursor += slot_w + inner_gap
	cursor += group_gap - inner_gap
	for i in 2:
		xs.append(cursor)
		cursor += slot_w + inner_gap
	cursor += group_gap - inner_gap
	for i in 2:
		xs.append(cursor)
		cursor += slot_w + inner_gap
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var rect := Rect2(float(xs[i]), row_y, slot_w, slot_w)
		slot_hits.append({
			"rect": rect,
			"id": str(entry["id"]),
			"rank": int(entry["rank"]),
			"slot": str(entry["slot"]),
			"name": str(entry["name"]),
		})
		_draw_slot_icon(str(entry["id"]), int(entry["rank"]), str(entry["slot"]), rect, true)


func _draw_slot_icon(id: String, rank: int, slot: String, rect: Rect2, show_badge: bool) -> void:
	draw_rect(rect, Color(0.05, 0.08, 0.1, 0.9))
	draw_rect(rect, _slot_color(slot), false, 2.0)
	var path := Loadout.sprite_path(id) if id != "" else Loadout.empty_slot_path(slot)
	var texture := _icon(path)
	if texture != null:
		_draw_fit(texture, rect.grow(-4))
	elif id != "":
		var words := Loadout.piece_name(id).split(" ")
		_text(rect.position + Vector2(4, 22), str(words[0]), 12, KickConstants.COLOR_TEXT)
	elif slot == Loadout.PERK:
		draw_rect(rect.grow(-8), Color(0.2, 0.24, 0.3, 0.9), false, 2.0)
	var badge := Loadout.rank_badge(id, rank) if show_badge else ""
	if badge != "":
		var font := ThemeDB.fallback_font
		var text_width := 18.0
		if font != null:
			text_width = font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var box_w := maxf(28.0, text_width + 8.0)
		var badge_box := Rect2(rect.position.x + rect.size.x - box_w, rect.position.y + rect.size.y - 20, box_w, 20)
		draw_rect(badge_box, Color(0.95, 0.78, 0.16, 0.96))
		if font != null:
			var at := badge_box.position + Vector2((badge_box.size.x - text_width) * 0.5, 15)
			draw_string(font, at, badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.12, 0.08, 0.02))


func _draw_fit(texture: Texture2D, rect: Rect2) -> void:
	var size := texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var drawn := size * scale
	var at := rect.position + (rect.size - drawn) * 0.5
	draw_texture_rect(texture, Rect2(at, drawn), false)


func _meter_art() -> Texture2D:
	if _keyed_meter != null:
		return _keyed_meter
	var raw := load("res://art/ui/kick_meter.png") as Texture2D
	if raw == null:
		return null
	var image := raw.get_image()
	if image == null:
		_keyed_meter = raw
		return _keyed_meter
	_keyed_meter = ImageTexture.create_from_image(MeterGauge.key_meter_image(image))
	return _keyed_meter


func _icon(path: String) -> Texture2D:
	if path == "":
		return null
	if _icons.has(path):
		return _icons[path]
	var texture := load(path) as Texture2D
	_icons[path] = texture
	return texture


func _draw_slot_tooltip() -> void:
	var index := pinned_slot if pinned_slot >= 0 else hover_slot
	if index < 0 or index >= slot_hits.size():
		return
	var hit: Dictionary = slot_hits[index]
	var id := str(hit["id"])
	var rank := int(hit["rank"])
	var lines: Array = []
	if id == "":
		lines.append(str(hit["name"]))
	else:
		var title := Loadout.piece_name(id)
		var badge := Loadout.rank_badge(id, rank)
		if badge != "":
			title += " " + badge
		lines.append(title)
		lines.append(Loadout.effect_line(id, rank if rank > 0 else 1))
	var anchor: Rect2 = hit["rect"]
	var box := Rect2(anchor.position + Vector2(0, anchor.size.y + 8.0), Vector2(240, 18.0 + float(lines.size()) * 20.0))
	if box.position.x + box.size.x > KickConstants.WINDOW_WIDTH - 8.0:
		box.position.x = KickConstants.WINDOW_WIDTH - 8.0 - box.size.x
	draw_rect(box, Color(0.05, 0.08, 0.1, 0.94))
	draw_rect(box, KickConstants.COLOR_ATTEMPT, false, 2.0)
	var y := box.position.y + 18.0
	for line in lines:
		_text(Vector2(box.position.x + 8, y), str(line), 14, KickConstants.COLOR_TEXT)
		y += 20.0


func _slot_color(slot: String) -> Color:
	if slot == Loadout.CLEATS:
		return Color(0.95, 0.55, 0.2)
	if slot == Loadout.HELMET:
		return Color(0.45, 0.75, 0.95)
	if slot == Loadout.GLOVES:
		return Color(0.45, 0.8, 0.45)
	if slot == Loadout.PERK:
		return Color(0.45, 0.6, 0.95)
	if slot == Loadout.CURSE:
		return Color(0.72, 0.4, 0.95)
	return KickConstants.COLOR_TEXT


func _draw_trophy(run: RunLogic) -> void:
	if run.trophy_name == "":
		return
	var box := Rect2(280, 78, 520, 54)
	draw_rect(box, Color(0.45, 0.32, 0.05, 0.94))
	draw_rect(box, Color(0.95, 0.78, 0.2), false, 3.0)
	_text_centered("TROPHY: %s" % run.trophy_name, 112.0, 26, Color(1.0, 0.9, 0.45))


func _draw_save_note() -> void:
	if game.save_note == "":
		return
	var box := Rect2(340, 620, 600, 48)
	draw_rect(box, Color(0.05, 0.08, 0.1, 0.92))
	_text_centered(str(game.save_note), 650.0, 22, KickConstants.COLOR_ATTEMPT)


func _draw_records() -> void:
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0.04, 0.07, 0.1, 0.96))
	_text(Vector2(48, 42), "TROPHY ROOM", 32, KickConstants.COLOR_ATTEMPT)
	_text(Vector2(48, 78), "Esc: back", 16, KickConstants.COLOR_TEXT)
	var y := 120.0
	_text(Vector2(48, y), "Lifetime", 22, KickConstants.COLOR_TEXT)
	y += 28.0
	_text(Vector2(48, y), "Runs %d    Wins %d" % [SaveData.runs, SaveData.wins], 18, KickConstants.COLOR_TEXT)
	y += 24.0
	_text(Vector2(48, y), "Best score %d" % SaveData.best_score, 18, KickConstants.COLOR_TEXT)
	y += 24.0
	_text(Vector2(48, y), "Longest make %s" % _yd_or_dash(SaveData.longest_make), 18, KickConstants.COLOR_TEXT)
	y += 22.0
	_text(Vector2(48, y), "NFL record: 68 yd (Cam Little, 2025)", 15, Color(0.65, 0.68, 0.7))
	y += 24.0
	_text(Vector2(48, y), "FG%% %s" % SaveData.fg_text(SaveData.makes, SaveData.attempts), 18, KickConstants.COLOR_TEXT)
	var columns := [
		[Kickers.BIG_BRUCE, 460.0],
		[Kickers.WALK_ON, 860.0],
	]
	for column in columns:
		var id := str(column[0])
		var left := float(column[1])
		var info := Kickers.get_def(id)
		var tint: Color = info["color"]
		var box := Rect2(left - 20.0, 100.0, 360.0, 230.0)
		draw_rect(box, Color(tint.r, tint.g, tint.b, 0.28))
		draw_rect(box, tint, false, 3.0)
		var row: Dictionary = SaveData.kicker_row(id)
		var line_y := 132.0
		_text(Vector2(left, line_y), str(info["name"]), 22, tint.lightened(0.35))
		line_y += 32.0
		_text(Vector2(left, line_y), "Runs %d    Wins %d" % [int(row["runs"]), int(row["wins"])], 16, KickConstants.COLOR_TEXT)
		line_y += 24.0
		_text(Vector2(left, line_y), "Best score %d" % int(row["best_score"]), 16, KickConstants.COLOR_TEXT)
		line_y += 24.0
		_text(Vector2(left, line_y), "Longest %s" % _yd_or_dash(int(row["longest_make"])), 16, KickConstants.COLOR_TEXT)
		line_y += 24.0
		_text(Vector2(left, line_y), "FG%% %s" % SaveData.fg_text(int(row["makes"]), int(row["attempts"])), 16, KickConstants.COLOR_TEXT)
	_text(Vector2(48, 380), "Trophies", 22, KickConstants.COLOR_TEXT)
	var index := 0
	for id in SaveData.TROPHY_IDS:
		var col := index % 4
		var row_i := int(index / 4.0)
		var box := Rect2(48.0 + float(col) * 300.0, 400.0 + float(row_i) * 140.0, 280.0, 120.0)
		var earned := SaveData.has_trophy(str(id))
		if earned:
			draw_rect(box, Color(0.45, 0.32, 0.05, 0.95))
			draw_rect(box, Color(0.95, 0.78, 0.2), false, 3.0)
			_text(box.position + Vector2(16, 36), SaveData.trophy_name(str(id)), 18, Color(1.0, 0.9, 0.45))
			_draw_wrapped(SaveData.trophy_condition(str(id)), Rect2(box.position + Vector2(16, 56), Vector2(248, 50)), 14)
		else:
			draw_rect(box, Color(0.12, 0.13, 0.15, 0.95))
			draw_rect(box, Color(0.45, 0.47, 0.5), false, 3.0)
			_text(box.position + Vector2(16, 36), "?", 22, Color(0.6, 0.62, 0.66))
			_draw_wrapped(SaveData.trophy_condition(str(id)), Rect2(box.position + Vector2(16, 56), Vector2(248, 50)), 14)
		index += 1


func _yd_or_dash(yards: int) -> String:
	if yards <= 0:
		return "—"
	return "%d yd" % yards


func _draw_cash_belt(run: RunLogic) -> void:
	# Under the score panel, on a plate so yard numbers do not cover Z and X.
	var plate := Rect2(16, 500, 230, 210)
	draw_rect(plate, Color(0.02, 0.05, 0.08, 0.9))
	var origin := plate.position + Vector2(10, 24)
	_text(origin, "$%d" % run.cash, 22, KickConstants.COLOR_ATTEMPT)
	if run.cash_popup != "":
		_text(origin + Vector2(78, 0), run.cash_popup, 22, Color(1.0, 0.92, 0.4))
	for i in 2:
		var key := "Z" if i == 0 else "X"
		var rect := Rect2(plate.position.x + 10.0, plate.position.y + 36.0 + float(i) * 54.0, 208.0, 48.0)
		var id := str(run.belt[i]) if i < run.belt.size() else ""
		_draw_bottle(id, rect, id == "")
		_text(rect.position + Vector2(8, 30), key, 16, KickConstants.COLOR_ATTEMPT)
		if id != "":
			_text(rect.position + Vector2(36, 30), Vitamins.piece_name(id), 14, KickConstants.COLOR_TEXT)
	if run.vitamin_note != "":
		_text(plate.position + Vector2(10, 192), run.vitamin_note, 16, Color(1.0, 0.92, 0.45))


func _draw_bottle(id: String, rect: Rect2, empty: bool) -> void:
	draw_rect(rect, Color(0.05, 0.07, 0.08, 0.92))
	draw_rect(rect, Color(0.75, 0.78, 0.82), false, 2.0)
	if empty:
		draw_rect(rect.grow(-10), Color(0.75, 0.78, 0.82, 0.35), false, 2.0)
		return
	var path := Vitamins.sprite_path(id)
	var texture := _icon(path)
	var bottle := Rect2(rect.position + Vector2(6, 6), Vector2(36, 38))
	if texture != null:
		_draw_fit(texture, bottle)
	else:
		draw_rect(bottle, Vitamins.bottle_color(id))
		draw_rect(Rect2(bottle.position + Vector2(10, -2), Vector2(16, 8)), Vitamins.bottle_color(id).darkened(0.25))


func _draw_curse_prompt(run: RunLogic) -> void:
	var box := Rect2(240, 250, 620, 220)
	draw_rect(box, KickConstants.COLOR_RESULT_SCRIM)
	_text_centered("Remove which curse?", box.position.y + 48.0, 32, KickConstants.COLOR_ATTEMPT)
	var names := ""
	for i in run.curse_ids.size():
		if names != "":
			names += "    "
		names += "%d %s" % [i + 1, Loadout.piece_name(str(run.curse_ids[i]))]
	_text_centered(names, box.position.y + 110.0, 22, KickConstants.COLOR_TEXT)
	_text_centered("Esc cancels. Tart Cherry stays on the belt.", box.position.y + 160.0, 18, KickConstants.COLOR_TEXT)


func _draw_shop(run: RunLogic) -> void:
	var backdrop := _icon("res://art/shop/vitamin_shop.png")
	if backdrop != null:
		draw_texture_rect(backdrop, Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), false)
	else:
		draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0.12, 0.08, 0.05))
	_text(Vector2(36, 32), "VITAMIN SHOP", 28, Color(1.0, 0.95, 0.8))
	var info := Rect2(132, 250, 190, 210)
	draw_rect(info, Color(0.05, 0.04, 0.03, 0.82))
	_text(info.position + Vector2(12, 28), "$%d" % run.cash, 22, KickConstants.COLOR_ATTEMPT)
	if run.cash_popup != "":
		_text(info.position + Vector2(90, 28), run.cash_popup, 18, Color(1.0, 0.92, 0.4))
	_text(info.position + Vector2(12, 58), run.next_boss_line(), 14, KickConstants.COLOR_TEXT)
	for i in 2:
		var id := str(run.belt[i]) if i < run.belt.size() else ""
		var label := "Z" if i == 0 else "X"
		var slot := Rect2(info.position + Vector2(12, 74 + float(i) * 58), Vector2(166, 50))
		_draw_bottle(id, slot, id == "")
		_text(slot.position + Vector2(4, 16), label, 12, KickConstants.COLOR_TEXT)
		if id != "":
			_text(slot.position + Vector2(42, 30), Vitamins.piece_name(id), 12, KickConstants.COLOR_TEXT)
	var frames := [Rect2(344, 488, 132, 132), Rect2(572, 488, 128, 132), Rect2(796, 488, 128, 132)]
	for i in 3:
		var id := str(run.shop_stock[i]) if i < run.shop_stock.size() else ""
		var frame: Rect2 = frames[i]
		if id == "":
			_text(frame.position + Vector2(28, 78), "SOLD", 22, Color(0.85, 0.85, 0.88))
		else:
			_draw_bottle(id, frame.grow(-18), false)
			var plate := Rect2(frame.position.x - 8, frame.position.y + frame.size.y + 4, frame.size.x + 16, 52)
			draw_rect(plate, Color(0.05, 0.04, 0.03, 0.88))
			var price_color := Color(1.0, 0.3, 0.25) if run.shop_flash == str(i) else KickConstants.COLOR_ATTEMPT
			_text(plate.position + Vector2(6, 16), "%d  $%d" % [i + 1, Vitamins.price(id)], 14, price_color)
			_text(plate.position + Vector2(6, 34), Vitamins.piece_name(id), 12, KickConstants.COLOR_TEXT)
			_text(plate.position + Vector2(6, 48), Vitamins.effect_line(id), 11, KickConstants.COLOR_TEXT)
	var b12 := Rect2(980, 250, 250, 150)
	var grey := run.b12_grey()
	draw_rect(b12, Color(0.08, 0.08, 0.08, 0.9) if grey else Color(0.16, 0.12, 0.05, 0.92))
	draw_rect(b12, Color(0.45, 0.45, 0.45) if grey else Color(0.95, 0.82, 0.28), false, 3.0)
	var b12_price := Color(1.0, 0.3, 0.25) if run.shop_flash == "b12" else (Color(0.7, 0.7, 0.7) if grey else KickConstants.COLOR_ATTEMPT)
	_text(b12.position + Vector2(16, 32), "%s  B12 Shot" % Settings.key_label("buy_b12"), 20, Color(0.75, 0.75, 0.75) if grey else KickConstants.COLOR_TEXT)
	_text(b12.position + Vector2(16, 64), "$%d" % Vitamins.B12_PRICE, 20, b12_price)
	_text(b12.position + Vector2(16, 96), Vitamins.effect_line(Vitamins.B12), 16, KickConstants.COLOR_TEXT)
	if run.shop_b12_bought:
		_text(b12.position + Vector2(16, 126), "SOLD", 16, Color(0.8, 0.8, 0.8))
	elif run.attempts >= run.attempt_cap:
		_text(b12.position + Vector2(16, 126), "At cap", 16, Color(0.8, 0.8, 0.8))
	var reroll_color := Color(1.0, 0.3, 0.25) if run.shop_flash == "reroll" else KickConstants.COLOR_TEXT
	_text(Vector2(36, 64), "Reroll (%s): $%d" % [Settings.key_label("shop_reroll"), run.shop_reroll_price], 16, reroll_color)
	if run.shop_note != "":
		_text(Vector2(36, 92), run.shop_note, 18, Color(1.0, 0.45, 0.35))
	_text_centered("%s/%s/%s buy  %s B12  %s/%s sell  %s reroll  %s leave" % [
		Settings.key_label("choose_1"), Settings.key_label("choose_2"), Settings.key_label("choose_3"),
		Settings.key_label("buy_b12"), Settings.key_label("belt_z"), Settings.key_label("belt_x"),
		Settings.key_label("shop_reroll"), Settings.key_label("confirm"),
	], 704.0, 18, KickConstants.COLOR_TEXT)


var _menu_textures := {}


func _menu_window() -> Vector2:
	if size.x > 2.0 and size.y > 2.0:
		return size
	return Vector2(KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT)


func _menu_texture(which: String) -> Texture2D:
	if _menu_textures.has(which):
		return _menu_textures[which]
	var names: Array = ["title.png", "title_screen.png", "press_start.png", "overtime_2000_title.png"]
	if which == "main":
		names = ["main_menu.png", "menu.png", "menu_background.png"]
	elif which == "options":
		names = ["options.png", "options_menu.png"]
	elif which == "endless":
		names = ["endless_unlocked.png"]
	var path := MenuLayout.find_texture_path(names)
	if path == "":
		_menu_textures[which] = null
		return null
	var loaded := load(path) as Texture2D
	if which == "options" and loaded != null:
		var image := loaded.get_image()
		if image != null:
			_strip_confirm_outline(image)
			loaded = ImageTexture.create_from_image(image)
	_menu_textures[which] = loaded
	return loaded


func _strip_confirm_outline(image: Image) -> void:
	# The painting bakes a white selection ring on CONFIRM / KICK. Drop only that ring.
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var width := image.get_width()
	var height := image.get_height()
	for y in range(180, 220):
		if y < 0 or y >= height:
			continue
		for x in range(486, 872):
			if x < 0 or x >= width:
				continue
			if x >= 508 and x <= 846 and y >= 194 and y <= 210:
				continue
			var offset := (y * width + x) * 4
			var red := int(bytes[offset])
			var green := int(bytes[offset + 1])
			var blue := int(bytes[offset + 2])
			if red > 210 and green > 210 and blue > 210:
				bytes[offset] = 42
				bytes[offset + 1] = 42
				bytes[offset + 2] = 46
	image.set_data(width, height, false, Image.FORMAT_RGBA8, bytes)


func _draw_cover(texture: Texture2D) -> void:
	var window := _menu_window()
	if texture == null:
		draw_rect(Rect2(Vector2.ZERO, window), Color(0.03, 0.03, 0.04))
		return
	draw_texture_rect(texture, MenuLayout.cover_rect(window, texture.get_size()), false)


func _draw_round_outline(pixel_rect: Rect2, window: Vector2, image: Vector2) -> void:
	var rect := MenuLayout.screen_rect(pixel_rect, window, image)
	var radius := clampf(minf(rect.size.x, rect.size.y) * 0.08, 6.0, 18.0)
	var points := PackedVector2Array()
	var centers := [
		rect.position + Vector2(radius, radius),
		rect.position + Vector2(rect.size.x - radius, radius),
		rect.position + Vector2(rect.size.x - radius, rect.size.y - radius),
		rect.position + Vector2(radius, rect.size.y - radius),
	]
	var starts := [PI, PI * 1.5, 0.0, PI * 0.5]
	for corner in 4:
		for step in 7:
			var angle: float = float(starts[corner]) + (PI * 0.5) * float(step) / 6.0
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)
	points.append(points[0])
	draw_polyline(points, Color(0.97, 0.98, 1.0), 3.0, true)


func _draw_title(_front: FrontEnd) -> void:
	var window := _menu_window()
	var art := _menu_texture("title")
	_draw_cover(art)
	var image := MenuLayout.IMAGE_SIZE if art == null else art.get_size()
	if art == null:
		_text_centered("OVERTIME 2000", window.y * 0.42, 64, Color(0.9, 0.9, 0.92))
	# Brighten and dim the painted letters. Do not draw a second copy of the words.
	var wave := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.005)
	var letters := MenuLayout.screen_rect(Rect2(518, 648, 242, 34), window, image)
	if wave < 0.5:
		draw_rect(letters, Color(0, 0, 0, (0.5 - wave) * 1.1))
	else:
		draw_rect(letters, Color(1, 1, 1, (wave - 0.5) * 0.55))
	if art == null:
		_text_in_rect("PRESS START", MenuLayout.screen_rect(MenuLayout.PRESS_START, window, image), 28, Color.WHITE)


func _draw_main_menu(front: FrontEnd) -> void:
	var window := _menu_window()
	var art := _menu_texture("main")
	if front.endless_unlocked():
		var unlocked := _menu_texture("endless")
		if unlocked != null:
			art = unlocked
	_draw_cover(art)
	var image := MenuLayout.IMAGE_SIZE if art == null else art.get_size()
	if art == null:
		_text_centered("OVERTIME 2000", 180, 48, Color(0.9, 0.9, 0.92))
	for index in MenuLayout.TILES.size():
		if index != front.menu_index:
			continue
		var tile: Rect2 = MenuLayout.TILES[index]
		_draw_round_outline(tile, window, image)
		var band := Rect2(tile.position.x + 14.0, 612.0, tile.size.x - 28.0, 42.0)
		if index == 2:
			band = Rect2(tile.position.x + 18.0, 548.0, tile.size.x - 36.0, 124.0)
		var label_box := MenuLayout.screen_rect(band, window, image)
		draw_rect(label_box, Color(0.23, 0.23, 0.25))
		if index == 2:
			_text_in_rect("TROPHY", Rect2(label_box.position, Vector2(label_box.size.x, label_box.size.y * 0.5)), 18, Color.WHITE)
			_text_in_rect("ROOM", Rect2(label_box.position + Vector2(0, label_box.size.y * 0.5), Vector2(label_box.size.x, label_box.size.y * 0.5)), 18, Color.WHITE)
		else:
			var word := "STANDARD"
			if index == 1:
				word = "ENDLESS"
			elif index == 3:
				word = "OPTIONS"
			_text_in_rect(word, label_box, 18, Color.WHITE)
	if front.endless_unlocked() and _menu_texture("endless") == null and art != null:
		var tile: Rect2 = MenuLayout.TILES[1]
		var patch := Rect2(tile.position.x + tile.size.x * 0.28, tile.position.y + 18.0, tile.size.x * 0.44, 96.0)
		var screen_patch := MenuLayout.screen_rect(patch, window, image)
		draw_rect(screen_patch, Color(0.27, 0.27, 0.29))
		_text_in_rect("∞", screen_patch, 40, Color(0.95, 0.78, 0.2))
	if front.lock_message != "":
		var banner := MenuLayout.screen_rect(Rect2(360, 430, 560, 40), window, image)
		draw_rect(banner, Color(0.05, 0.05, 0.06, 0.88))
		_text_in_rect(front.lock_message, banner, 18, Color(1.0, 0.92, 0.45))


func _draw_options(front: FrontEnd) -> void:
	var window := _menu_window()
	var art := _menu_texture("options")
	_draw_cover(art)
	var image := MenuLayout.IMAGE_SIZE if art == null else art.get_size()
	if art == null:
		_text_centered("OPTIONS", 48, 32, Color.WHITE)
	var panel := Color(0.16, 0.16, 0.18, 1.0)
	for index in 3:
		var track: Rect2 = MenuLayout.SLIDERS[index]
		draw_rect(MenuLayout.screen_rect(track, window, image), panel)
		var which := front.slider_id(index)
		var value := Settings.volume_of(which)
		draw_rect(MenuLayout.screen_rect(MenuLayout.slider_fill(index, float(value)), window, image), Color(0.93, 0.72, 0.18))
		draw_rect(MenuLayout.screen_rect(MenuLayout.slider_handle(index, float(value)), window, image), Color(0.78, 0.78, 0.82))
		var number: Rect2 = MenuLayout.SLIDER_NUMBERS[index]
		var number_screen := MenuLayout.screen_rect(number, window, image)
		draw_rect(number_screen, panel)
		_text_in_rect(str(value), number_screen, 18, Color(0.98, 0.84, 0.22))
	for row_index in Settings.ACTION_ROWS.size():
		var row: Dictionary = Settings.ACTION_ROWS[row_index]
		var plate := MenuLayout.bind_rect(int(row["column"]), int(row["row"]))
		var key_box := MenuLayout.key_plate(plate)
		var key_screen := MenuLayout.screen_rect(key_box, window, image)
		draw_rect(key_screen, Color(0.22, 0.22, 0.24))
		var action_id := str(row["id"])
		var label := "Press a key..." if front.rebinding == action_id else Settings.key_label(action_id)
		_text_in_rect(label, key_screen, 14, Color(0.94, 0.94, 0.96))
	if front.focus >= 0 and front.focus < front.focus_count():
		_draw_round_outline(_focus_pixel_rect(front), window, image)
	if front.notice != "":
		var banner := MenuLayout.screen_rect(Rect2(760, 150, 280, 36), window, image)
		draw_rect(banner, Color(0.35, 0.08, 0.08, 0.92))
		_text_in_rect(front.notice, banner, 18, Color(1.0, 0.85, 0.4))


func _focus_pixel_rect(front: FrontEnd) -> Rect2:
	var index := front.focus
	if index < 3:
		return MenuLayout.SLIDERS[index]
	if index < 3 + Settings.ACTION_ROWS.size():
		var row: Dictionary = Settings.ACTION_ROWS[index - 3]
		return MenuLayout.bind_rect(int(row["column"]), int(row["row"]))
	if index == front.focus_count() - 2:
		return MenuLayout.RESET_BUTTON
	return MenuLayout.BACK_BUTTON


func _text_in_rect(text: String, rect: Rect2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null or text == "":
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := rect.position + Vector2((rect.size.x - width) * 0.5, rect.size.y * 0.72)
	_text(at, text, size, color)
