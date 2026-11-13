extends Control

# The 2D scoreboard drawn on top of the 3D field.
# Meter, attempts, result words. No field drawing in here.

var game
var _padlock_cover: Texture2D


func _draw() -> void:
	if game == null:
		return
	var front: FrontEnd = game.front
	if front != null and front.screen == FrontEnd.Screen.TITLE:
		_draw_title(front)
		return
	if front != null and front.screen == FrontEnd.Screen.MAIN:
		_draw_main_menu(front)
		if front.gate != "":
			_draw_gate(front)
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
		if game.paused:
			_draw_pause_panel()
		return
	var logic: KickLogic = game.logic
	var run: RunLogic = game.run
	_draw_weather_tint(run)
	var on_meter := logic.phase == KickLogic.Phase.POWER or logic.phase == KickLogic.Phase.ACCURACY or logic.phase == KickLogic.Phase.FLIGHT or logic.phase == KickLogic.Phase.RESULT
	if not run.meter_hidden(on_meter, game.meter_time):
		_draw_meter(logic, run)
	_draw_hud(logic, run)
	_draw_loadout_rail(run)
	_draw_laser(logic, run)
	if logic.phase == KickLogic.Phase.RESULT and run.phase == RunLogic.Phase.PLAYING:
		_draw_result(logic, run)
	if run.awaiting_mulligan:
		_draw_mulligan()
	elif run.awaiting_offer:
		_draw_offer(run)
	elif run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN or run.phase == RunLogic.Phase.FAR:
		_draw_end_screen(run)
	_draw_trophy(run)
	_draw_cash_belt(run)
	if run.curse_prompt:
		_draw_curse_prompt(run)
	_draw_save_note()
	if game.run != null and game.run.unlock_toast != "":
		_text_centered(game.run.unlock_toast, 96.0, 22, Color(1.0, 0.92, 0.45))
	_draw_slot_tooltip()
	if game.paused:
		_draw_pause_panel()


func pause_hit(point: Vector2) -> int:
	var buttons := _pause_buttons()
	for index in buttons.size():
		if (buttons[index] as Rect2).has_point(point):
			return index
	return -1


func gate_hit(point: Vector2, which: String) -> int:
	var buttons := _gate_buttons(which)
	for index in buttons.size():
		if (buttons[index] as Rect2).has_point(point):
			return index
	return -1


func _pause_buttons() -> Array:
	return [Rect2(390, 318, 500, 58), Rect2(390, 392, 500, 58)]


func _gate_buttons(which: String) -> Array:
	if which == "confirm":
		return [Rect2(250, 360, 780, 52), Rect2(250, 428, 780, 52)]
	return [Rect2(390, 340, 500, 58), Rect2(390, 414, 500, 58)]


func _draw_pause_panel() -> void:
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0, 0, 0, 0.38))
	var plate := Rect2(330, 168, 620, 320)
	_metal_plate(plate)
	_pg_center(FrontEnd.PAUSE_WORD, 196, 42, Color(0.96, 0.94, 0.88), "callout")
	var labels := [FrontEnd.RESUME_WORD, FrontEnd.SAVE_QUIT_WORD]
	var buttons := _pause_buttons()
	for index in buttons.size():
		_menu_button(buttons[index], str(labels[index]), index == game.pause_index)


func _draw_gate(front: FrontEnd) -> void:
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0, 0, 0, 0.55))
	var plate := Rect2(180, 150, 920, 380)
	_metal_plate(plate)
	if front.gate == "confirm":
		var line := FrontEnd.GATE_REPLACE_ENDLESS if front.run_mode == "endless" else FrontEnd.GATE_REPLACE_STANDARD
		_pg_center(line, 196, 16, Color(0.95, 0.93, 0.86))
		var labels := [FrontEnd.GATE_START, FrontEnd.GATE_KEEP]
		var buttons := _gate_buttons("confirm")
		for index in buttons.size():
			_menu_button(buttons[index], str(labels[index]), index == front.gate_index)
		return
	var lines := SaveData.run_status_lines(front.run_mode)
	if lines.size() > 0:
		_pg_center(lines[0], 188, 22, Color(0.96, 0.94, 0.88))
	if lines.size() > 1:
		_pg_center(lines[1], 230, 18, Color(0.82, 0.84, 0.8))
	var choose := [FrontEnd.GATE_CONTINUE, FrontEnd.GATE_NEW]
	var choose_buttons := _gate_buttons("choose")
	for index in choose_buttons.size():
		_menu_button(choose_buttons[index], str(choose[index]), index == front.gate_index)


func _metal_plate(rect: Rect2) -> void:
	draw_rect(rect, Color(0.07, 0.075, 0.08, 0.94))
	draw_rect(rect, Color(0.92, 0.93, 0.95), false, 3.0)
	draw_rect(rect.grow(-6), Color(0.28, 0.3, 0.33), false, 1.0)


func _menu_button(rect: Rect2, text: String, selected: bool) -> void:
	draw_rect(rect, Color(0.14, 0.15, 0.17) if selected else Color(0.1, 0.11, 0.12))
	draw_rect(rect, Color(0.97, 0.98, 1.0) if selected else Color(0.45, 0.47, 0.5), false, 3.0 if selected else 2.0)
	var width := BitmapFonts.measure_px("ui", text, 16)
	var at := Vector2(rect.position.x + (rect.size.x - float(width)) * 0.5, rect.position.y + 16)
	_pg(text, at, 16, Color(0.97, 0.96, 0.92))


func _pg_center(text: String, y: float, size: int, color: Color, font_key: String = "ui") -> void:
	var width := BitmapFonts.measure_px(font_key, text, size)
	BitmapFonts.paint_px(self, font_key, text, Vector2((KickConstants.WINDOW_WIDTH - float(width)) * 0.5, y), size, color)


func _draw_meter(logic: KickLogic, run: RunLogic) -> void:
	# Small enough that the frame stays off the uprights, the kicker, and the corner text.
	var gauge_w := 332.0
	var gauge_h := gauge_w * 625.0 / 1003.0
	var origin := Vector2(KickConstants.WINDOW_WIDTH - 18.0 - gauge_w, KickConstants.WINDOW_HEIGHT - 14.0 - gauge_h)
	var scale := gauge_w / 1003.0
	var hub := origin + Vector2(504.0, 510.0) * scale
	# Inset so the live color covers the painted band and leaves the metal bezel alone.
	var inner := 308.0 * scale
	var outer := 386.0 * scale
	var stats: KickerStats = logic.stats
	var layout := MeterGauge.accuracy_layout(stats.perfect_band, stats.good_band)
	var art := _meter_art()
	if art != null:
		draw_texture_rect(art, Rect2(origin, Vector2(gauge_w, gauge_h)), false)
	# One opaque well. The disk stays inside the painted arc so the field still shows around the gear.
	_draw_well(hub, 276.0 * scale)
	# Opaque live wedges and the orange fill sit on the painted band. One copy, not a stacked PNG.
	_draw_annulus(hub, inner, outer, 90.0, float(layout["band_top"]), Color(0.78, 0.1, 0.08, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["band_top"]), float(layout["perfect_top"]), Color(0.93, 0.74, 0.12, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["perfect_top"]), float(layout["perfect_bottom"]), Color(0.2, 0.78, 0.28, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["perfect_bottom"]), float(layout["band_bottom"]), Color(0.93, 0.74, 0.12, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["band_bottom"]), 0.0, Color(0.78, 0.1, 0.08, 1.0))
	var shown := logic.fill_power
	if shown > 0.5:
		var tip := stats.red_tip_start
		var orange_to := minf(shown, tip)
		_draw_annulus(hub, inner, outer, 180.0, MeterGauge.power_angle(orange_to), Color(1.0, 0.48, 0.05, 1.0))
		if shown > tip:
			var pulse := 0.72 + 0.28 * sin(float(Time.get_ticks_msec()) * 0.012)
			var danger_from := MeterGauge.power_angle(tip)
			var danger_to := MeterGauge.power_angle(shown)
			if danger_from - danger_to < 10.0:
				danger_from = danger_to + 10.0
			_draw_annulus(hub, inner, outer, danger_from, danger_to, Color(0.95, 0.05, 0.04, pulse))
	var label_r := (inner + outer) * 0.5
	var good_high := (float(layout["band_top"]) + float(layout["perfect_top"])) * 0.5
	var good_low := (float(layout["perfect_bottom"]) + float(layout["band_bottom"])) * 0.5
	_draw_wedge_label(hub, label_r, good_high, "GOOD")
	_draw_wedge_label(hub, label_r, 45.0, "PERFECT")
	_draw_wedge_label(hub, label_r, good_low, "GOOD")
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
		tint = Color(0.25, 0.45, 0.9, 0.14)
	elif run.weather == RunLogic.SNOW:
		tint = Color(0.93, 0.95, 1.0, 0.12)
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


func _draw_well(hub: Vector2, radius: float) -> void:
	var steps := 36
	var points := PackedVector2Array()
	points.append(hub)
	for i in steps + 1:
		var t := float(i) / float(steps)
		points.append(_gauge_point(hub, radius, lerpf(180.0, 0.0, t)))
	draw_colored_polygon(points, Color(18.0 / 255.0, 20.0 / 255.0, 24.0 / 255.0, 1.0))


func _draw_hud(logic: KickLogic, run: RunLogic) -> void:
	var saved := texture_filter
	texture_filter = TEXTURE_FILTER_NEAREST
	_draw_kick_bug(logic, run)
	_draw_score_bug(run)
	_draw_kicker_plate(logic, run)
	texture_filter = saved


func _draw_kick_bug(logic: KickLogic, run: RunLogic) -> void:
	var show_mph := logic.stats.flag_reader
	var speed := run.shown_wind_speed()
	var big_game := run.is_boss() and run.weather == RunLogic.BIG_GAME
	var extra := 0
	if show_mph:
		extra += 16
	if big_game:
		extra += 16
	var bug := Rect2(868, 10, 398, 74 + extra)
	_steel_panel(bug)
	var cream := Color(0.93, 0.91, 0.84)
	var left := Rect2(bug.position.x + 6, bug.position.y + 6, 118, 36)
	draw_rect(left, Color(0.12, 0.62, 0.78))
	var title := BroadcastHud.kick_title(run.kick_number, run.run_mode == "endless")
	_pg(title, left.position + Vector2(6, 4), 13, Color(0.05, 0.08, 0.1))
	var yards := BroadcastHud.yards_text(logic.kick_distance)
	var yard_box := Rect2(left.position.x + left.size.x + 6, left.position.y, 128, 36)
	_pg(yards, yard_box.position + Vector2(4, 4), 26, cream)
	var spot := RunLogic.spot_label(run.spot_yards)
	var aim := BroadcastHud.aim_text(logic.aim_degrees)
	var right_x := yard_box.position.x + yard_box.size.x + 8
	_pg(spot, Vector2(right_x, bug.position.y + 8), 13, cream)
	_aim_pip(Vector2(right_x, bug.position.y + 28), logic.aim_degrees)
	_pg(aim, Vector2(right_x + 12, bug.position.y + 24), 12, cream)
	var row_y := bug.position.y + 48
	var weather := run.weather
	if run.is_boss():
		_pg("BOSS", Vector2(bug.position.x + 8, row_y), 12, Color(0.95, 0.55, 0.2))
		_pg(weather, Vector2(bug.position.x + 52, row_y), 13, cream)
	else:
		_pg(weather, Vector2(bug.position.x + 8, row_y), 13, cream)
	var wind := BroadcastHud.wind_band(speed, show_mph)
	_pg(wind, Vector2(bug.position.x + 168, row_y), 13, cream)
	_wind_pip(Vector2(bug.position.x + 156, row_y + 8), speed, run.wind_direction)
	row_y += 16
	if show_mph:
		_pg(BroadcastHud.wind_detail(speed, run.wind_direction), Vector2(bug.position.x + 8, row_y), 12, Color(0.55, 0.9, 0.95))
		row_y += 16
	if big_game:
		_pg("METER UPGRADES OFF", Vector2(bug.position.x + 8, row_y), 12, cream)


func _draw_score_bug(run: RunLogic) -> void:
	var show_mph := false
	if game != null:
		show_mph = game.logic.stats.flag_reader
	var big_game := run.is_boss() and run.weather == RunLogic.BIG_GAME
	var extra := 0
	if show_mph:
		extra += 16
	if big_game:
		extra += 16
	var bug := Rect2(868, 18 + 74 + extra, 398, 70)
	_steel_panel(bug)
	var cells := [
		{"label": "SCORE", "value": str(run.score), "w": 86.0},
		{"label": "STREAK", "value": str(run.streak), "w": 86.0},
		{"label": "MULT", "value": RunLogic._two_decimals(run.current_mult()), "w": 90.0},
		{"label": "ATTEMPTS", "value": "", "w": 112.0},
	]
	var x := bug.position.x + 6.0
	var cream := Color(0.93, 0.91, 0.84)
	for cell in cells:
		var rect := Rect2(x, bug.position.y + 6, float(cell["w"]), 58)
		draw_rect(rect, Color(0.05, 0.06, 0.07))
		_pg(str(cell["label"]), rect.position + Vector2(6, 4), 11, Color(0.7, 0.72, 0.75))
		if str(cell["label"]) == "ATTEMPTS":
			_draw_compact_pips(run, rect.position.x + 8.0, rect.position.y + 32.0)
			_pg("CAP %d" % run.attempt_cap, rect.position + Vector2(8.0 + float(run.attempt_cap) * 8.0 + 4.0, 24), 12, cream)
		else:
			_pg(str(cell["value"]), rect.position + Vector2(6, 22), 22, cream)
		x += float(cell["w"]) + 4.0


func _draw_kicker_plate(logic: KickLogic, run: RunLogic) -> void:
	var required := logic.kick_distance
	var max_range := logic.max_range_at_full_power()
	var warn := BroadcastHud.max_warning(required, max_range)
	var kit := BroadcastHud.kit_text(run.kicker_id)
	var ball := BroadcastHud.ball_text(run.kicker_id)
	var kit_lines := _pg_wrap(kit, 250, 12)
	var ball_lines := _pg_wrap(ball, 250, 12)
	var body := 18 + 16 + 14 * kit_lines.size() + 14 * ball_lines.size()
	var plate_h := maxi(78, 8 + body)
	var plate := Rect2(12, 708 - plate_h, 430, plate_h)
	_steel_panel(plate)
	var head := Rect2(plate.position.x + 6, plate.position.y + 6, plate_h - 12, plate_h - 12)
	_draw_head(run.kicker_id, head)
	var text_x := head.position.x + head.size.x + 8
	var y := plate.position.y + 6
	var name := BroadcastHud.plate_name(run.kicker_id)
	var name_w := BitmapFonts.measure_px("ui", name, 13)
	var number := BroadcastHud.plate_number(run.kicker_id)
	var bar_w := name_w + 10
	if number != "":
		bar_w += 8 + BitmapFonts.measure_px("ui", number, 12)
	draw_rect(Rect2(text_x, y, maxf(160, bar_w), 16), Color(0.42, 0.24, 0.68))
	_pg(name, Vector2(text_x + 4, y + 1), 13, Color(0.95, 0.93, 0.98))
	if number != "":
		_pg(number, Vector2(text_x + 8 + name_w, y + 2), 12, Color(0.95, 0.93, 0.98))
	y += 20
	_pg("MAX", Vector2(text_x, y), 12, Color(0.7, 0.72, 0.75))
	var bar := Rect2(text_x + 36, y + 2, 120, 8)
	draw_rect(bar, Color(0.05, 0.06, 0.07))
	var fill := BroadcastHud.max_fill(required, max_range)
	var fill_color := Color(0.95, 0.35, 0.18) if warn else Color(0.2, 0.78, 0.86)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), fill_color)
	var yards_color := Color(0.95, 0.4, 0.22) if warn else Color(0.93, 0.91, 0.84)
	_pg(BroadcastHud.yards_text(max_range), Vector2(text_x + 164, y - 2), 13, yards_color)
	y += 16
	for line in kit_lines:
		_pg(line, Vector2(text_x, y), 12, Color(0.55, 0.95, 0.62))
		y += 14
	for line in ball_lines:
		_pg(line, Vector2(text_x, y), 12, Color(0.95, 0.82, 0.28))
		y += 14
	_draw_chips(run, plate.position.y - 28)
	var hint := ""
	if run.phase != RunLogic.Phase.GAME_OVER and run.phase != RunLogic.Phase.WIN and run.phase != RunLogic.Phase.FAR:
		if not run.awaiting_offer and not run.awaiting_mulligan and not run.curse_prompt:
			hint = BroadcastHud.hint_text(logic.phase, run.accepts_restart(), run.can_practice(), run.practicing, Settings.key_label("aim_left"), Settings.key_label("aim_right"), Settings.key_label("confirm"))
	if hint != "":
		var hint_x := plate.position.x + plate.size.x + 8.0
		var hint_lines := _pg_wrap(hint, 470, 12)
		var widest := 0
		for line in hint_lines:
			widest = maxi(widest, BitmapFonts.measure_px("ui", line, 12))
		var bar_h := hint_lines.size() * 14 + 8
		var hint_bar := Rect2(hint_x - 6.0, plate.position.y + plate.size.y - float(bar_h), float(widest) + 12.0, float(bar_h))
		_steel_panel(hint_bar)
		for i in hint_lines.size():
			_pg(hint_lines[i], Vector2(hint_x, hint_bar.position.y + 4.0 + float(i) * 14.0), 12, Color(0.9, 0.91, 0.92))


func _draw_chips(run: RunLogic, y: float) -> void:
	var cash := Rect2(12, y, 72, 24)
	_steel_panel(cash)
	draw_circle(Vector2(cash.position.x + 12, cash.position.y + 12), 6, Color(0.95, 0.78, 0.22))
	draw_circle(Vector2(cash.position.x + 12, cash.position.y + 12), 6, Color(0.55, 0.38, 0.08), false, 1.0)
	_pg(str(run.cash), cash.position + Vector2(22, 5), 13, Color(0.95, 0.9, 0.55))
	var popup := BroadcastHud.payout_text(run.cash_popup)
	if popup != "":
		_pg(popup, cash.position + Vector2(78, 5), 13, Color(1.0, 0.92, 0.4))
	for i in 2:
		var key := "Z" if i == 0 else "X"
		var chip := Rect2(168 + float(i) * 52, y, 46, 24)
		_steel_panel(chip)
		_pg(key, chip.position + Vector2(4, 5), 13, Color(0.93, 0.91, 0.84))
		var id := str(run.belt[i]) if i < run.belt.size() else ""
		if id != "":
			var icon := _icon(Vitamins.sprite_path(id))
			if icon != null:
				draw_texture_rect(icon, Rect2(chip.position + Vector2(22, 3), Vector2(18, 18)), false)
	var note := BroadcastHud.belt_note(run.vitamin_note)
	if note != "":
		_pg(note, Vector2(276, y + 5), 12, Color(1.0, 0.92, 0.45))


func _steel_panel(rect: Rect2) -> void:
	draw_rect(rect, Color(0.04, 0.045, 0.05))
	draw_rect(rect, Color(0.62, 0.64, 0.68), false, 2.0)
	draw_rect(rect.grow(-3), Color(0.22, 0.24, 0.27), false, 1.0)


func _pg(text: String, at: Vector2, size: int, color: Color) -> void:
	if text == "":
		return
	BitmapFonts.paint_px(self, "ui", text, at, size, color)


func _pg_wrap(text: String, max_w: int, size: int) -> PackedStringArray:
	var lines := PackedStringArray()
	if text == "":
		return lines
	var line := ""
	for word in text.split(" "):
		var trial := word if line == "" else line + " " + word
		if line != "" and BitmapFonts.measure_px("ui", trial, size) > max_w:
			lines.append(line)
			line = word
		else:
			line = trial
	if line != "":
		lines.append(line)
	return lines


func _draw_head(kicker_id: String, area: Rect2) -> void:
	draw_rect(area, Color(0.08, 0.09, 0.1))
	var path := BroadcastHud.head_path(kicker_id)
	var picture := _portrait_texture(path)
	if picture != null:
		var fitted := _fit_rect(area.grow(-2), picture.get_size())
		draw_texture_rect(picture, fitted, false)


func _aim_pip(at: Vector2, degrees: float) -> void:
	var color := Color(0.2, 0.85, 0.95)
	if degrees < -0.05:
		draw_colored_polygon(PackedVector2Array([at + Vector2(8, -4), at + Vector2(8, 4), at]), color)
	elif degrees > 0.05:
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -4), at + Vector2(0, 4), at + Vector2(8, 0)]), color)
	else:
		draw_colored_polygon(PackedVector2Array([at + Vector2(4, -6), at, at + Vector2(8, 0)]), color)


func _wind_pip(at: Vector2, speed: int, direction: float) -> void:
	var color := Color(0.55, 0.9, 0.95)
	if speed <= 0:
		draw_circle(at, 3, color)
		return
	var cross := KickLogic.crosswind_mph(float(speed), direction)
	var along := KickLogic.head_tail_mph(float(speed), direction)
	var dir := Vector2(cross, -along)
	if dir.length() < 0.001:
		draw_circle(at, 3, color)
		return
	dir = dir.normalized() * 7.0
	draw_line(at, at + dir, color, 2.0)
	draw_circle(at + dir, 2.5, color)


var card_rects: Array = []
var kicker_rects: Array = []


func kicker_slot_at(point: Vector2) -> int:
	for i in kicker_rects.size():
		var rect: Rect2 = kicker_rects[i]
		if rect.has_point(point):
			return i
	return -1


var _card_frames := {}
var _card_busts := {}


func _draw_kicker_select() -> void:
	# The stadium stays behind a dark gutter. The lock JPEG is not drawn.
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0.02, 0.025, 0.03, 0.78))
	_pg_centered("CHOOSE YOUR KICKER", 16.0, 18, Color(0.95, 0.92, 0.84))
	kicker_rects = SelectCard.grid_rects()
	var picked := int(game.highlight)
	for i in kicker_rects.size():
		var info: Dictionary = Kickers.ALL[i]
		_draw_playing_card(kicker_rects[i], str(info["id"]), Kickers.is_unlocked(str(info["id"])), i == picked)
	_pg_centered("1 TO 8 HIGHLIGHT. SPACE OR CLICK AGAIN TO START.", 694.0, 14, Color(0.95, 0.92, 0.84))


func _draw_playing_card(rect: Rect2, id: String, unlocked: bool, picked: bool) -> void:
	var shadow := rect.position + Vector2(7, 8)
	_fill_round(Rect2(shadow, rect.size), rect.size.y * (9.0 / 134.0), Color(0.0, 0.0, 0.0, 0.72))
	var window := _card_slice(rect, SelectCard.WIN_X, SelectCard.WIN_Y, SelectCard.WIN_W, SelectCard.WIN_H)
	draw_rect(window, Color(0.03, 0.03, 0.035))
	_draw_card_bust(id, window, unlocked)
	var frame := _card_frame(Vector2i(int(rect.size.x), int(rect.size.y)))
	if frame != null:
		draw_texture_rect(frame, rect, false)
	var cream := Color(0.95, 0.92, 0.84)
	var orange := Color(0.95, 0.58, 0.18)
	var ink := cream if unlocked else orange
	var rank := SelectCard.corner_text(id, unlocked)
	var rank_px := maxi(9, int(rect.size.y * 0.048))
	if unlocked:
		_pg(rank, rect.position + Vector2(rect.size.x * 0.045, rect.size.y * 0.012), rank_px, ink)
		var rank_w := BitmapFonts.measure_px("ui", rank, rank_px)
		_pg(rank, rect.position + Vector2(rect.size.x * 0.955 - float(rank_w), rect.size.y * 0.905), rank_px, ink)
	else:
		# A painted dash. Pixel Gothic has no hyphen, and a period pair is too small to read here.
		var dash := Vector2(rect.size.x * 0.09, maxf(3.0, rect.size.y * 0.012))
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.055, rect.size.y * 0.028), dash), ink)
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.855, rect.size.y * 0.925), dash), ink)
	var band := _card_slice(rect, 0.1, SelectCard.BAND_Y, 0.8, SelectCard.BAND_H)
	_pg_block(SelectCard.card_name(id), band, maxi(8, int(rect.size.y * 0.04)), ink)
	var well := _card_slice(rect, 0.08, SelectCard.WELL_Y, 0.84, SelectCard.WELL_H)
	var body := maxi(7, int(rect.size.y * 0.03))
	if unlocked:
		var kits := SelectCard.kit_lines(id)
		var ball := SelectCard.ball_line(id)
		if kits.size() > 1 and not _well_fits(kits, ball, well, body):
			kits = PackedStringArray([kits[kits.size() - 1]])
		var lines: PackedStringArray = kits.duplicate()
		lines.append(ball)
		_pg_stack(lines, well, body, cream, lines.size() - 1, Color(0.42, 0.82, 0.4))
	else:
		var locked := PackedStringArray(["LOCKED"])
		for line in _pg_wrap(SelectCard.unlock_line(id), int(well.size.x), body):
			locked.append(line)
		_pg_stack(locked, well, body, orange, -1, orange)
	if picked:
		_stroke_round(rect.grow(3.0), rect.size.y * (10.0 / 134.0), Color(0.96, 0.78, 0.28), 3.0)


func _card_slice(rect: Rect2, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(rect.position + Vector2(rect.size.x * x, rect.size.y * y), Vector2(rect.size.x * w, rect.size.y * h))


func _well_fits(kits: PackedStringArray, ball: String, well: Rect2, size: int) -> bool:
	var lines := kits.size() + 1
	if ball == "":
		lines = kits.size()
	var height := lines * (size + 2)
	if height > int(well.size.y):
		return false
	var widest := BitmapFonts.measure_px("ui", ball, size)
	for line in kits:
		widest = maxi(widest, BitmapFonts.measure_px("ui", line, size))
	return widest <= int(well.size.x)


func _pg_centered(text: String, y: float, size: int, color: Color) -> void:
	var width := BitmapFonts.measure_px("ui", text, size)
	_pg(text, Vector2((KickConstants.WINDOW_WIDTH - float(width)) * 0.5, y), size, color)


func _pg_block(text: String, area: Rect2, size: int, color: Color) -> void:
	var lines := _pg_wrap(text, int(area.size.x), size)
	if lines.is_empty():
		return
	var step := size + 1
	var block_h := lines.size() * step
	var y := area.position.y + maxf(0.0, (area.size.y - float(block_h)) * 0.5)
	for line in lines:
		var width := BitmapFonts.measure_px("ui", line, size)
		_pg(line, Vector2(area.position.x + (area.size.x - float(width)) * 0.5, y), size, color)
		y += float(step)


func _pg_stack(lines: PackedStringArray, area: Rect2, size: int, color: Color, green_at: int, green: Color) -> void:
	if lines.is_empty():
		return
	var step := size + 2
	var block_h := lines.size() * step
	var y := area.position.y + maxf(0.0, (area.size.y - float(block_h)) * 0.5)
	for i in lines.size():
		var ink := green if i == green_at else color
		var width := BitmapFonts.measure_px("ui", lines[i], size)
		_pg(lines[i], Vector2(area.position.x + (area.size.x - float(width)) * 0.5, y), size, ink)
		y += float(step)


func _card_frame(size: Vector2i) -> Texture2D:
	var key := "%d,%d" % [size.x, size.y]
	if _card_frames.has(key):
		return _card_frames[key]
	var source := load(SelectCard.FRAME_PATH) as Texture2D
	if source == null:
		return null
	var image := source.get_image()
	if image == null:
		return null
	image = image.duplicate()
	image.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	var picture := ImageTexture.create_from_image(image)
	_card_frames[key] = picture
	return picture


func _draw_card_bust(id: String, window: Rect2, unlocked: bool) -> void:
	var path := BroadcastHud.head_path(id)
	var source := _portrait_texture(path)
	if source == null:
		return
	var image := source.get_image()
	if image == null:
		return
	var used := image.get_used_rect()
	if used.size.x < 2.0 or used.size.y < 2.0:
		used = Rect2i(0, 0, image.get_width(), image.get_height())
	var dest := Vector2i(maxi(1, int(window.size.x)), maxi(1, int(window.size.y)))
	var scale := maxf(float(dest.x) / float(used.size.x), float(dest.y) / float(used.size.y))
	var crop_w := int(round(float(dest.x) / scale))
	var crop_h := int(round(float(dest.y) / scale))
	crop_w = mini(crop_w, int(used.size.x))
	crop_h = mini(crop_h, int(used.size.y))
	var crop_x := int(used.position.x) + int((int(used.size.x) - crop_w) / 2)
	# Keep the head. Extra height is trimmed off the chest, not the helmet.
	var crop_y := int(used.position.y)
	var key := "%s:%d,%d:%s" % [id, dest.x, dest.y, "on" if unlocked else "dim"]
	var picture: Texture2D = _card_busts.get(key)
	if picture == null:
		var crop := image.get_region(Rect2i(crop_x, crop_y, crop_w, crop_h))
		crop.resize(dest.x, dest.y, Image.INTERPOLATE_NEAREST)
		picture = ImageTexture.create_from_image(crop)
		_card_busts[key] = picture
	draw_texture_rect(picture, Rect2(window.position, Vector2(dest)), false)
	if not unlocked:
		draw_rect(Rect2(window.position, Vector2(dest)), Color(0.02, 0.025, 0.04, 0.42))


func _fill_round(rect: Rect2, radius: float, color: Color) -> void:
	draw_colored_polygon(_round_points(rect, radius), color)


func _stroke_round(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var points := _round_points(rect, radius)
	if points.is_empty():
		return
	points.append(points[0])
	draw_polyline(points, color, width, false)


func _round_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := clampf(radius, 2.0, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var centers := [
		rect.position + Vector2(r, r),
		rect.position + Vector2(rect.size.x - r, r),
		rect.position + Vector2(rect.size.x - r, rect.size.y - r),
		rect.position + Vector2(r, rect.size.y - r),
	]
	var sweeps := [PI, PI * 1.5, 0.0, PI * 0.5]
	for corner in 4:
		var center: Vector2 = centers[corner]
		var start: float = sweeps[corner]
		for step in 5:
			var angle := start + float(step) * (PI * 0.5) / 4.0
			points.append(center + Vector2(cos(angle), sin(angle)) * r)
	return points


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


func _draw_laser(logic: KickLogic, _run: RunLogic) -> void:
	if logic.stats.path_percent <= 0.0:
		return
	if logic.phase != KickLogic.Phase.AIMING and logic.phase != KickLogic.Phase.POWER and logic.phase != KickLogic.Phase.ACCURACY:
		return
	var plan := logic.preview_plan()
	var travel := float(plan["travel"])
	if travel <= 0.05:
		return
	var limit := travel * float(logic.stats.path_percent) / 100.0
	if logic.kick_distance > 0.0:
		limit = minf(limit, logic.kick_distance)
	var drift := float(plan["drift"])
	var angle := float(plan["angle"])
	var reached := bool(plan["reached"])
	var previous: Variant = null
	var dash := false
	var forward := 0.0
	while true:
		var at := minf(forward, limit)
		var lateral := KickLogic.path_lateral(logic.start_lateral_yards, at, angle, logic.kick_distance, drift)
		var screen: Variant = game.project_flight_point(at, lateral, travel, reached)
		if previous != null and screen != null and dash:
			var start: Vector2 = previous
			var finish: Vector2 = screen
			if start.distance_to(finish) <= 220.0:
				draw_line(start, finish, Color(0.02, 0.04, 0.08), 7.0)
				draw_line(start, finish, Color(0.15, 0.95, 1.0), 3.5)
		if screen == null:
			previous = null
			dash = false
		else:
			previous = screen
			dash = not dash
		if at >= limit - 0.001:
			break
		forward += 0.5


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
		_draw_wrapped(Loadout.effect_line(id, rank), Rect2(rect.position + Vector2(12, 112), Vector2(width - 24, 90)), 15)
	_text_centered("Reroll: %d left    %s rerolls    %s skips" % [run.rerolls_left, Settings.key_label("offer_reroll"), Settings.key_label("skip")], 640.0, 18, KickConstants.COLOR_TEXT)
	_text_centered("Skip takes nothing.", 666.0, 16, KickConstants.COLOR_TEXT)


func _wrap_lines(text: String, width: float, size: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var font := ThemeDB.fallback_font
	if font == null or text == "":
		if text != "":
			lines.append(text)
		return lines
	var line := ""
	for word in text.split(" "):
		var trial := (line + word).strip_edges()
		if line != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			lines.append(line.strip_edges())
			line = word + " "
		else:
			line = trial + " "
	if line.strip_edges() != "":
		lines.append(line.strip_edges())
	return lines


func _draw_wrapped(text: String, area: Rect2, size: int) -> void:
	var y := area.position.y
	for line in _wrap_lines(text, area.size.x, size):
		_text(Vector2(area.position.x, y), line, size, KickConstants.COLOR_TEXT)
		y += float(size) + 4.0


func _draw_compact_pips(run: RunLogic, origin_x: float, origin_y: float) -> void:
	for i in run.attempt_cap:
		var center := Vector2(origin_x + float(i) * 8.0, origin_y)
		if i < run.attempts:
			draw_circle(center, 3.5, Color(0.95, 0.78, 0.22))
		else:
			draw_circle(center, 3.5, Color(0.75, 0.77, 0.8), false, 1.0)


func _draw_attempt_pips(run: RunLogic, origin_x: float, origin_y: float) -> void:
	for i in run.attempt_cap:
		var center := Vector2(origin_x + float(i) * KickConstants.ATTEMPT_PIP_GAP, origin_y)
		if i < run.attempts:
			draw_circle(center, KickConstants.ATTEMPT_PIP_RADIUS, KickConstants.COLOR_ATTEMPT)
		else:
			draw_circle(center, KickConstants.ATTEMPT_PIP_RADIUS, KickConstants.COLOR_TEXT, false, 2.0, true)


func _draw_result(logic: KickLogic, run: RunLogic) -> void:
	# Screen-space stamp. The field distance does not change its size.
	var middle := logic.result_text == "GOOD" and absf(logic.offset_yards) <= KickConstants.MIDDLE_YARDS
	var lines := ResultStamp.words(logic.shanked, logic.result_text, logic.bank_shot, logic.insured, logic.perfect, middle)
	var main_lines: PackedStringArray = ResultStamp.primary_lines(lines[0])
	var accuracy := ResultStamp.accuracy_line(logic.shanked, logic.perfect, logic.accuracy_error, logic.stats.perfect_band, logic.stats.good_band)
	var ui_lines := 1 if accuracy == "" else 2
	var stacked := lines.size() > 1
	var scale := 1
	var slam := 1
	var punch := 0.0
	if run.awaiting_offer:
		scale = 1
		slam = 1
	else:
		var fitted := _stamp_scale(main_lines, stacked, ui_lines, 1280, 680)
		# Leave a size step for the slam when a bigger whole-pixel size still fits.
		if fitted >= 3 and _stamp_fits(main_lines, stacked, ui_lines, fitted, 1280, 680):
			scale = fitted - 1
			slam = fitted
		else:
			scale = fitted
			slam = fitted
			punch = 16.0
	if game == null or game.result_age >= ResultStamp.SLAM_SEC:
		slam = scale
		punch = 0.0
	var shake := Vector2.ZERO
	if game != null and ResultStamp.shakes(lines[0]) and game.result_age < 0.22:
		var amp := int(ceil((0.22 - game.result_age) / 0.22 * 3.0))
		var flip := 1 if int(game.result_age * 40.0) % 2 == 0 else -1
		shake = Vector2(flip * amp, 0)
	var second := maxi(slam - 1, 1) if lines.size() > 1 else 0
	var block := BitmapFonts.line_height("callout", slam) * main_lines.size()
	if second > 0:
		block += 8 + BitmapFonts.line_height("callout", second)
	if not run.awaiting_offer:
		block += 16 + BitmapFonts.line_height("ui", 1) * ui_lines
	var top := 24.0 if run.awaiting_offer else (KickConstants.WINDOW_HEIGHT - float(block)) * 0.38 + punch
	draw_rect(Rect2(0, top - 16.0, KickConstants.WINDOW_WIDTH, float(block) + 32.0), Color(0, 0, 0, 0.55))
	var saved_filter := texture_filter
	texture_filter = TEXTURE_FILTER_NEAREST
	var y := top
	for line in main_lines:
		_paint_centered("callout", line, y, slam, shake)
		y += float(BitmapFonts.line_height("callout", slam))
	if lines.size() > 1:
		y += 8.0
		_paint_centered("callout", lines[1], y, second, shake)
		y += float(BitmapFonts.line_height("callout", second))
	if not run.awaiting_offer:
		y += 16.0
		_paint_centered("ui", ResultStamp.power_line(logic.shanked, logic.power, logic.stats.power_floor), y, 1, shake)
		y += float(BitmapFonts.line_height("ui", 1))
		if accuracy != "":
			_paint_centered("ui", accuracy, y, 1, shake)
			y += float(BitmapFonts.line_height("ui", 1))
	texture_filter = saved_filter
	# Score math still uses × ( ) = which Pixel Gothic does not have.
	if run.awaiting_offer:
		return
	if run.score_line != "":
		y += 28.0
		_text_centered(run.score_line, y, 22, KickConstants.COLOR_TEXT)
	if run.attempt_note != "":
		y += 8.0
		texture_filter = TEXTURE_FILTER_NEAREST
		_paint_centered("ui", run.attempt_note, y, 1, Vector2.ZERO)
		texture_filter = saved_filter


func _stamp_scale(lines: PackedStringArray, stacked: bool, ui_lines: int, max_width: int, max_height: int) -> int:
	var scale := 4
	while scale > 1:
		if _stamp_fits(lines, stacked, ui_lines, scale, max_width, max_height):
			return scale
		scale -= 1
	return 1


func _stamp_fits(lines: PackedStringArray, stacked: bool, ui_lines: int, scale: int, max_width: int, max_height: int) -> bool:
	var widest := 0
	for line in lines:
		widest = maxi(widest, BitmapFonts.line_width("callout", line, scale))
	var height := BitmapFonts.line_height("callout", scale) * lines.size()
	if stacked:
		height += 8 + BitmapFonts.line_height("callout", maxi(scale - 1, 1))
	height += 16 + BitmapFonts.line_height("ui", 1) * ui_lines
	return widest <= max_width and height <= max_height


func _paint_centered(key: String, text: String, top: float, scale: int, shake: Vector2) -> void:
	if text == "":
		return
	var width := BitmapFonts.line_width(key, text, scale)
	var x := (KickConstants.WINDOW_WIDTH - float(width)) * 0.5 + shake.x
	BitmapFonts.paint(self, key, text, Vector2(x, top + shake.y), scale, Color.WHITE)


func _draw_end_screen(run: RunLogic) -> void:
	var box := Rect2(KickConstants.RESULT_LEFT, KickConstants.RESULT_TOP, KickConstants.RESULT_WIDTH, KickConstants.RESULT_HEIGHT + 56.0)
	draw_rect(box, KickConstants.COLOR_RESULT_SCRIM)
	var title := "GAME OVER"
	var title_color := KickConstants.COLOR_MISS
	if run.phase == RunLogic.Phase.WIN:
		title = "WIN"
		title_color = KickConstants.COLOR_GOOD
	elif run.phase == RunLogic.Phase.FAR:
		title = "THAT'S FAR ENOUGH"
		title_color = KickConstants.COLOR_GOOD
	_text_centered(title, box.position.y + 70.0, 40 if run.phase == RunLogic.Phase.FAR else 64, title_color)
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
		lines.append_array(_wrap_lines(Loadout.effect_line(id, rank if rank > 0 else 1), 248.0, 14))
	var anchor: Rect2 = hit["rect"]
	var box := Rect2(anchor.position + Vector2(0, anchor.size.y + 8.0), Vector2(264, 16.0 + float(lines.size()) * 18.0))
	if box.position.x + box.size.x > KickConstants.WINDOW_WIDTH - 8.0:
		box.position.x = KickConstants.WINDOW_WIDTH - 8.0 - box.size.x
	if box.position.y + box.size.y > KickConstants.WINDOW_HEIGHT - 8.0:
		box.position.y = maxf(8.0, anchor.position.y - box.size.y - 8.0)
	draw_rect(box, Color(0.05, 0.08, 0.1, 0.94))
	draw_rect(box, KickConstants.COLOR_ATTEMPT, false, 2.0)
	var y := box.position.y + 18.0
	for line in lines:
		_text(Vector2(box.position.x + 8, y), str(line), 14, KickConstants.COLOR_TEXT)
		y += 18.0


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
	y += 24.0
	_text(Vector2(48, y), "FG%% %s" % SaveData.fg_text(SaveData.makes, SaveData.attempts), 18, KickConstants.COLOR_TEXT)
	var columns: Array = []
	var col_count := 4
	var col_w := 300.0
	var col_gap := 12.0
	var col_left := 28.0
	for i in Kickers.ALL.size():
		var col := i % col_count
		var row_n := int(i / col_count)
		columns.append([str(Kickers.ALL[i]["id"]), col_left + float(col) * (col_w + col_gap), 236.0 + float(row_n) * 118.0])
	for column in columns:
		var id := str(column[0])
		var left := float(column[1])
		var info := Kickers.get_def(id)
		var tint: Color = info["color"]
		var box := Rect2(left - 8.0, float(column[2]), col_w - 4.0, 110.0)
		draw_rect(box, Color(tint.r, tint.g, tint.b, 0.28))
		draw_rect(box, tint, false, 3.0)
		var row: Dictionary = SaveData.kicker_row(id)
		var line_y := float(column[2]) + 22.0
		_text(Vector2(left, line_y), str(info["name"]), 14, tint.lightened(0.35))
		line_y += 20.0
		_text(Vector2(left, line_y), "Runs %d    Wins %d" % [int(row["runs"]), int(row["wins"])], 14, KickConstants.COLOR_TEXT)
		line_y += 18.0
		_text(Vector2(left, line_y), "Best %d    Long %s" % [int(row["best_score"]), _yd_or_dash(int(row["longest_make"]))], 14, KickConstants.COLOR_TEXT)
		line_y += 18.0
		_text(Vector2(left, line_y), "FG%% %s" % SaveData.fg_text(int(row["makes"]), int(row["attempts"])), 14, KickConstants.COLOR_TEXT)
	_text(Vector2(48, 480), "Trophies", 22, KickConstants.COLOR_TEXT)
	var index := 0
	for id in SaveData.TROPHY_IDS:
		var col := index % 4
		var row_i := int(index / 4.0)
		var box := Rect2(48.0 + float(col) * 300.0, 504.0 + float(row_i) * 100.0, 280.0, 92.0)
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


func _draw_cash_belt(_run: RunLogic) -> void:
	# Cash and the Z / X chips are drawn with the kicker plate.
	return


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
		# Shelf and B12 plates are large enough to show the painting. Belt rows stay a small icon beside the name.
		if minf(rect.size.x, rect.size.y) >= 64.0:
			bottle = rect.grow(-8)
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
			var plate := Rect2(frame.position.x + frame.size.x * 0.5 - 107.0, 604.0, 214.0, 74.0)
			draw_rect(plate, Color(0.05, 0.04, 0.03, 0.88))
			var price_color := Color(1.0, 0.3, 0.25) if run.shop_flash == str(i) else KickConstants.COLOR_ATTEMPT
			_text(plate.position + Vector2(8, 16), "%d  $%d  %s" % [i + 1, run.item_price(id), Vitamins.piece_name(id)], 12, price_color)
			_draw_wrapped(Vitamins.effect_line(id), Rect2(plate.position + Vector2(8, 30), Vector2(plate.size.x - 16, 40)), 10)
	var b12 := Rect2(980, 250, 250, 150)
	var grey := run.b12_grey()
	draw_rect(b12, Color(0.08, 0.08, 0.08, 0.9) if grey else Color(0.16, 0.12, 0.05, 0.92))
	draw_rect(b12, Color(0.45, 0.45, 0.45) if grey else Color(0.95, 0.82, 0.28), false, 3.0)
	var b12_price := Color(1.0, 0.3, 0.25) if run.shop_flash == "b12" else (Color(0.7, 0.7, 0.7) if grey else KickConstants.COLOR_ATTEMPT)
	_text(b12.position + Vector2(16, 32), "%s  B12 Shot" % Settings.key_label("buy_b12"), 20, Color(0.75, 0.75, 0.75) if grey else KickConstants.COLOR_TEXT)
	_text(b12.position + Vector2(16, 64), "$%d" % run.item_price(Vitamins.B12), 20, b12_price)
	_text(b12.position + Vector2(16, 96), Vitamins.effect_line(Vitamins.B12), 16, KickConstants.COLOR_TEXT)
	_draw_bottle(Vitamins.B12, Rect2(b12.position + Vector2(158, 16), Vector2(78, 118)), false)
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
		_draw_selected_menu_tile(MenuLayout.TILES[index], window, image)
	if front.endless_unlocked() and _menu_texture("endless") == null and art != null:
		_draw_padlock_cover(art, window, image)
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
		_draw_selected_option_plate(front, window, image)
	if front.notice != "":
		var banner := MenuLayout.screen_rect(Rect2(760, 150, 280, 36), window, image)
		draw_rect(banner, Color(0.35, 0.08, 0.08, 0.92))
		_text_in_rect(front.notice, banner, 18, Color(1.0, 0.85, 0.4))


func _draw_selected_menu_tile(tile: Rect2, window: Vector2, image: Vector2) -> void:
	# White rounded outline only. The engraved letters stay as painted.
	_draw_round_outline(tile, window, image)


func _draw_padlock_cover(art: Texture2D, window: Vector2, image: Vector2) -> void:
	# Metal copied from beside the padlock, including its dark outline, not the word.
	var cover := _endless_padlock_cover(art)
	if cover == null:
		return
	draw_texture_rect(cover, MenuLayout.screen_rect(Rect2(436, 502, 116, 100), window, image), false)


func _endless_padlock_cover(art: Texture2D) -> Texture2D:
	if _padlock_cover != null:
		return _padlock_cover
	var source := art.get_image()
	if source == null:
		return null
	source = source.duplicate()
	source.convert(Image.FORMAT_RGBA8)
	var width := 116
	var height := 100
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var half := width / 2
	for y in height:
		for x in width:
			var from_x := 368 + x if x < half else 552 + (x - half)
			image.set_pixel(x, y, source.get_pixel(from_x, 502 + y))
	_padlock_cover = ImageTexture.create_from_image(image)
	return _padlock_cover


func _menu_label_rect(index: int) -> Rect2:
	# Painted letter bounds. Trophy Room is the two-line word.
	if index == 1:
		return Rect2(394, 590, 193, 64)
	if index == 2:
		return Rect2(704, 568, 161, 106)
	if index == 3:
		return Rect2(1000, 590, 179, 67)
	return Rect2(88, 590, 215, 64)


func _draw_selected_option_plate(front: FrontEnd, window: Vector2, image: Vector2) -> void:
	# The selected Options plate gets the same white outline and no extra fill.
	_draw_round_outline(_focus_pixel_rect(front), window, image)


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
