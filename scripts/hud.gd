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
			if game.help_open:
				_draw_help_book()
			else:
				_draw_pause_panel()
		return
	var logic: KickLogic = game.logic
	var run: RunLogic = game.run
	_draw_cam_dip()
	_draw_weather_tint(run)
	if not run.awaiting_offer and not run.awaiting_rung:
		_draw_meter(logic, run)
	_draw_hud(logic, run)
	_draw_tad_card(run)
	_draw_special_banner(run)
	_draw_kick_clock()
	_draw_loadout_rail(run)
	_draw_laser(logic, run)
	if logic.phase == KickLogic.Phase.RESULT and run.phase == RunLogic.Phase.PLAYING:
		_draw_result(logic, run)
	if run.awaiting_mulligan:
		_draw_mulligan()
	elif run.awaiting_rung:
		_draw_rung_choice(run)
	elif run.awaiting_offer:
		_draw_offer(run)
	elif run.phase == RunLogic.Phase.GAME_OVER or run.phase == RunLogic.Phase.WIN or run.phase == RunLogic.Phase.FAR:
		_draw_end_screen(run)
	_draw_trophy(run)
	_draw_cash_belt(run)
	if run.curse_prompt:
		_draw_curse_prompt(run)
	_draw_save_note()
	_draw_too_weak()
	_draw_too_weak_debug()
	if game.run != null and game.run.unlock_toast != "":
		_text_centered(game.run.unlock_toast, 96.0, 22, Color(1.0, 0.92, 0.45))
	_draw_slot_tooltip()
	if game.paused:
		if game.help_open:
			_draw_help_book()
		else:
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


func _tad_list_px(plate_width: float) -> int:
	var limit := int(plate_width) - 32
	var size := 13
	if game == null or game.run == null:
		return size
	var widest := 0
	for level in range(1, game.run.tad_level + 1):
		widest = maxi(widest, BitmapFonts.measure_px("ui", RunLogic.tad_line(level), size))
	if widest > limit:
		return 12
	return size


func _pause_drop() -> float:
	if game == null or game.run == null or not game.run.tad_active(1):
		return 0.0
	return 28.0 + 16.0 * float(game.run.tad_level)


func _pause_plate() -> Rect2:
	var drop := _pause_drop()
	var height := (318.0 + drop + 128.0 + 52.0 + 24.0) - 148.0
	return Rect2(330, 148, 620, height)


func _pause_buttons() -> Array:
	var drop := _pause_drop()
	var buttons: Array = []
	for i in 3:
		buttons.append(Rect2(390, 318.0 + drop + 64.0 * float(i), 500, 52))
	return buttons


func _gate_buttons(which: String) -> Array:
	if which == "confirm":
		return [Rect2(250, 360, 780, 52), Rect2(250, 428, 780, 52)]
	return [Rect2(390, 340, 500, 58), Rect2(390, 414, 500, 58)]


func _draw_pause_panel() -> void:
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0, 0, 0, 0.38))
	var plate := _pause_plate()
	_metal_plate(plate)
	_pg_center(FrontEnd.PAUSE_WORD, 168, 42, Color(0.96, 0.94, 0.88), "callout")
	if game.run != null and game.run.tad_active(1):
		var y := 214.0
		_pg_center("TWO A DAYS %d" % game.run.tad_level, y, 16, Color(0.95, 0.78, 0.28))
		y += 22.0
		var line_px := _tad_list_px(plate.size.x)
		for level in range(1, game.run.tad_level + 1):
			_pg_center(RunLogic.tad_line(level), y, line_px, Color(0.93, 0.91, 0.84))
			y += 16.0
	var labels := [FrontEnd.RESUME_WORD, FrontEnd.HOW_TO_PLAY_WORD, FrontEnd.SAVE_QUIT_WORD]
	var buttons := _pause_buttons()
	for index in buttons.size():
		_menu_button(buttons[index], str(labels[index]), index == game.pause_index)


func help_book_rects() -> Dictionary:
	return {
		"plate": Rect2(80, 40, 1120, 640),
		"content": Rect2(112, 136, 1056, 424),
		"prev": Rect2(112, 600, 200, 48),
		"back": Rect2(540, 600, 200, 48),
		"next": Rect2(968, 600, 200, 48),
	}


func help_hit(point: Vector2) -> int:
	var rects: Dictionary = help_book_rects()
	if (rects["prev"] as Rect2).has_point(point):
		return 0
	if (rects["back"] as Rect2).has_point(point):
		return 1
	if (rects["next"] as Rect2).has_point(point):
		return 2
	return -1


func help_demo_meter_rect() -> Rect2:
	var width := 400.0
	var height := width * MeterGauge.FRAME_H / MeterGauge.FRAME_W
	return Rect2(720, 200, width, height)


static func help_ribbon_end(origin: Vector2, band: String) -> Vector2:
	var lean := deg_to_rad(KickLogic.ribbon_lean_degrees(band))
	return origin + Vector2(sin(lean), cos(lean)) * 40.0


func help_lowest_y(page_id: String) -> float:
	if page_id == "wind":
		return 476.0 + 24.0 * float(HowToPlay.WIND_LINES.size() - 1) + 16.0
	var y := 144.0
	for step in HowToPlay.KICK_STEPS:
		var lines := _wrap_lines(_help_fill(str(step["body"])), 520.0, 16)
		y += 40.0 + float(lines.size()) * 20.0 + 8.0
	y -= 8.0
	var footer := _wrap_lines(HowToPlay.KICK_FOOTER, 520.0, 16)
	y += 16.0 + float(footer.size()) * 20.0
	var caption := help_demo_meter_rect().end.y + 28.0
	return maxf(y, caption)


func _draw_help_book() -> void:
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0, 0, 0, 0.55))
	var rects: Dictionary = help_book_rects()
	_metal_plate(rects["plate"])
	_pg_center("HOW TO PLAY", 56, 34, Color(0.96, 0.94, 0.88), "callout")
	var page := 0
	if game != null:
		page = clampi(int(game.help_page), 0, HowToPlay.page_count() - 1)
	var page_id := HowToPlay.page_id(page)
	_pg_center(HowToPlay.title(page_id), 104, 20, Color(0.95, 0.78, 0.28))
	if page_id == "wind":
		_draw_help_wind()
	else:
		_draw_help_kick()
	_pg_center("PAGE %d OF %d" % [page + 1, HowToPlay.page_count()], 570, 14, Color(0.82, 0.84, 0.8))
	var last := page >= HowToPlay.page_count() - 1
	_menu_button(rects["prev"], "PREV", false, page == 0)
	_menu_button(rects["back"], "BACK", false, false)
	_menu_button(rects["next"], "NEXT", false, last)


func _draw_help_kick() -> void:
	var cream := Color(0.93, 0.91, 0.84)
	var y := 144.0
	for step in HowToPlay.KICK_STEPS:
		_pg(str(step["label"]), Vector2(128, y), 18, cream)
		y = _draw_wrapped_at(_help_fill(str(step["body"])), 128.0, y + 40.0, 520.0, 16)
		y += 8.0
	y -= 8.0
	_draw_wrapped_at(HowToPlay.KICK_FOOTER, 128.0, y + 16.0, 520.0, 16, Color(0.82, 0.84, 0.8))
	var meter := help_demo_meter_rect()
	_draw_demo_meter(meter, 45.0)
	var caption := HowToPlay.KICK_CAPTION
	var font := ThemeDB.fallback_font
	if font != null:
		var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		_text(Vector2(meter.position.x + (meter.size.x - width) * 0.5, meter.position.y + meter.size.y + 28.0), caption, 15, Color(0.82, 0.84, 0.8))


func _draw_demo_meter(rect: Rect2, needle_angle: float) -> void:
	var scale := rect.size.x / MeterGauge.FRAME_W
	var hub := rect.position + Vector2(MeterGauge.HUB_X, MeterGauge.HUB_Y) * scale
	var inner := MeterGauge.GROOVE_INNER * scale
	var outer := MeterGauge.GROOVE_OUTER * scale
	var base := KickerStats.new()
	var layout := MeterGauge.accuracy_layout(base.perfect_band, base.good_band)
	var saved_filter := texture_filter
	texture_filter = TEXTURE_FILTER_NEAREST
	var art := _meter_art()
	if art != null:
		draw_texture_rect(art, rect, false)
	_draw_annulus(hub, inner, outer, 90.0, float(layout["band_top"]), Color(0.78, 0.1, 0.08, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["band_top"]), float(layout["perfect_top"]), Color(0.93, 0.74, 0.12, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["perfect_top"]), float(layout["perfect_bottom"]), Color(0.2, 0.78, 0.28, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["perfect_bottom"]), float(layout["band_bottom"]), Color(0.93, 0.74, 0.12, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["band_bottom"]), 0.0, Color(0.78, 0.1, 0.08, 1.0))
	var label_r := (inner + outer) * 0.5
	var good_high := (float(layout["band_top"]) + float(layout["perfect_top"])) * 0.5
	var good_low := (float(layout["perfect_bottom"]) + float(layout["band_bottom"])) * 0.5
	_draw_wedge_label(hub, label_r, good_high, "GOOD")
	_draw_wedge_label(hub, label_r, 45.0, "PERFECT")
	_draw_wedge_label(hub, label_r, good_low, "GOOD")
	var needle_tex := _needle_art()
	if needle_tex != null:
		draw_set_transform(hub, deg_to_rad(90.0 - needle_angle), Vector2(scale, scale))
		draw_texture(needle_tex, -MeterGauge.NEEDLE_PIVOT, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	texture_filter = saved_filter
	var cream := Color(0.93, 0.91, 0.84)
	_help_arc_label(hub, outer, 180.0, "POWER", cream)
	_help_arc_label(hub, outer, 0.0, "ACCURACY", cream)


func _help_fill(text: String) -> String:
	var filled := text
	filled = filled.replace("{aim_left}", Settings.sentence_key(Settings.key_label("aim_left")))
	filled = filled.replace("{aim_right}", Settings.sentence_key(Settings.key_label("aim_right")))
	filled = filled.replace("{confirm}", Settings.sentence_key(Settings.key_label("confirm")))
	return filled


func _help_arc_label(hub: Vector2, radius: float, degrees: float, text: String, color: Color) -> void:
	var at := _gauge_point(hub, radius, degrees)
	var width := BitmapFonts.measure_px("ui", text, 14)
	# The frame already paints its own plate on the arc end. Sit this label below that plate.
	var plate_drop := (572.0 - MeterGauge.HUB_Y) * (radius / MeterGauge.GROOVE_OUTER)
	_pg(text, Vector2(at.x - float(width) * 0.5, at.y + plate_drop + 18.0), 14, color)


func _draw_help_wind() -> void:
	var cream := Color(0.93, 0.91, 0.84)
	var grey := Color(0.82, 0.84, 0.8)
	var yellow := Color(0.98, 0.85, 0.2)
	var ribbon := Color(0.9, 0.12, 0.1)
	var centers: Array[float] = [244.0, 508.0, 772.0, 1036.0]
	for i in centers.size():
		var cx: float = centers[i]
		draw_line(Vector2(cx - 60.0, 330.0), Vector2(cx + 60.0, 330.0), yellow, 6.0)
		draw_line(Vector2(cx - 60.0, 330.0), Vector2(cx - 60.0, 190.0), yellow, 6.0)
		draw_line(Vector2(cx + 60.0, 330.0), Vector2(cx + 60.0, 190.0), yellow, 6.0)
		draw_line(Vector2(cx, 330.0), Vector2(cx, 392.0), yellow, 6.0)
		var mph := int(HowToPlay.WIND_MPH[i])
		var band := KickLogic.ribbon_band(mph)
		for side in [-60.0, 60.0]:
			var origin := Vector2(cx + side, 190.0)
			draw_line(origin, help_ribbon_end(origin, band), ribbon, 6.0)
		var name := "WIND " + RunLogic.wind_name(mph).to_upper()
		var name_w := BitmapFonts.measure_px("ui", name, 16)
		_pg(name, Vector2(cx - float(name_w) * 0.5, 410.0), 16, cream)
		var range_text := str(HowToPlay.WIND_RANGES[i])
		var range_w := BitmapFonts.measure_px("ui", range_text, 14)
		_pg(range_text, Vector2(cx - float(range_w) * 0.5, 434.0), 14, grey)
	var y := 476.0
	var content: Rect2 = help_book_rects()["content"]
	var font := ThemeDB.fallback_font
	for line in HowToPlay.WIND_LINES:
		if font != null:
			var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			_text(Vector2(content.position.x + (content.size.x - width) * 0.5, y), line, 16, KickConstants.COLOR_TEXT)
		y += 24.0


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


func _menu_button(rect: Rect2, text: String, selected: bool, dimmed: bool = false) -> void:
	draw_rect(rect, Color(0.14, 0.15, 0.17) if selected else Color(0.1, 0.11, 0.12))
	var border := Color(0.97, 0.98, 1.0) if selected else Color(0.45, 0.47, 0.5)
	var ink := Color(0.97, 0.96, 0.92)
	if dimmed:
		border.a = 0.4
		ink.a = 0.4
	draw_rect(rect, border, false, 3.0 if selected else 2.0)
	var width := BitmapFonts.measure_px("ui", text, 16)
	var at := Vector2(rect.position.x + (rect.size.x - float(width)) * 0.5, rect.position.y + 16)
	_pg(text, at, 16, ink)


func _pg_center(text: String, y: float, size: int, color: Color, font_key: String = "ui") -> void:
	var width := BitmapFonts.measure_px(font_key, text, size)
	BitmapFonts.paint_px(self, font_key, text, Vector2((KickConstants.WINDOW_WIDTH - float(width)) * 0.5, y), size, color)


func _meter_rect() -> Rect2:
	var gauge_w := 332.0
	var gauge_h := gauge_w * 625.0 / 1003.0
	return Rect2(Vector2(KickConstants.WINDOW_WIDTH - 18.0 - gauge_w, KickConstants.WINDOW_HEIGHT - 14.0 - gauge_h), Vector2(gauge_w, gauge_h))


func clock_layout(digit_text: String) -> Dictionary:
	var meter := _meter_rect()
	var label_px := 20
	var digit_px := 90
	var label_w := BitmapFonts.measure_px("ui", "KICK CLOCK", label_px)
	var digit_w := BitmapFonts.measure_px("callout", digit_text, digit_px)
	var center := meter.position.x + meter.size.x * 0.5
	var digit_top := meter.position.y - 12.0 - float(digit_px)
	var label_top := digit_top - 32.0
	return {
		"meter": meter,
		"label": Rect2(center - float(label_w) * 0.5, label_top, float(label_w), float(label_px)),
		"digit": Rect2(center - float(digit_w) * 0.5, digit_top, float(digit_w), float(digit_px)),
	}


func _draw_meter(logic: KickLogic, run: RunLogic) -> void:
	# Small enough that the frame stays off the uprights, the kicker, and the corner text.
	var meter := _meter_rect()
	var gauge_w := meter.size.x
	var gauge_h := meter.size.y
	var origin := meter.position
	var scale := gauge_w / MeterGauge.FRAME_W
	var hub := origin + Vector2(MeterGauge.HUB_X, MeterGauge.HUB_Y) * scale
	var inner := MeterGauge.GROOVE_INNER * scale
	var outer := MeterGauge.GROOVE_OUTER * scale
	var stats: KickerStats = logic.stats
	var layout := MeterGauge.accuracy_layout(logic.shown_perfect_band(), logic.shown_good_band())
	var saved_filter := texture_filter
	texture_filter = TEXTURE_FILTER_NEAREST
	var art := _meter_art()
	if art != null:
		meter_frame_draws += 1
		draw_texture_rect(art, Rect2(origin, Vector2(gauge_w, gauge_h)), false)
	# The frame groove is empty. One set of live wedges fills it.
	_draw_annulus(hub, inner, outer, 90.0, float(layout["band_top"]), Color(0.78, 0.1, 0.08, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["band_top"]), float(layout["perfect_top"]), Color(0.93, 0.74, 0.12, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["perfect_top"]), float(layout["perfect_bottom"]), Color(0.2, 0.78, 0.28, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["perfect_bottom"]), float(layout["band_bottom"]), Color(0.93, 0.74, 0.12, 1.0))
	_draw_annulus(hub, inner, outer, float(layout["band_bottom"]), 0.0, Color(0.78, 0.1, 0.08, 1.0))
	var band_end := MeterGauge.power_angle_raw(KickConstants.METER_MAX + maxf(stats.overpower_width, 0.0))
	_draw_annulus(hub, inner, outer, MeterGauge.MAX_ANGLE, band_end, Color(0.72, 0.08, 0.06, 0.95))
	var shown := logic.fill_power
	if shown > 0.5:
		var orange_to := minf(shown, KickConstants.METER_MAX)
		_draw_annulus(hub, inner, outer, 180.0, MeterGauge.power_angle(orange_to), Color(1.0, 0.48, 0.05, 1.0))
		if shown > KickConstants.METER_MAX + 0.05:
			_draw_annulus(hub, inner, outer, MeterGauge.MAX_ANGLE, MeterGauge.power_angle_raw(shown), Color(0.95, 0.08, 0.05, 1.0))
	if logic.overpower_paid:
		var flash := 0.35 + 0.25 * sin(float(Time.get_ticks_msec()) * 0.02)
		_draw_annulus(hub, inner, outer, MeterGauge.MAX_ANGLE, band_end, Color(1.0, 0.05, 0.04, flash))
	_draw_meter_popup(logic, hub, outer)
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
		var needle_tex := _needle_art()
		if needle_tex != null:
			meter_needle_draws += 1
			draw_set_transform(hub, deg_to_rad(90.0 - logic.needle_angle), Vector2(scale, scale))
			draw_texture(needle_tex, -MeterGauge.NEEDLE_PIVOT, Color(1, 1, 1, fade))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	texture_filter = saved_filter


func _draw_meter_popup(logic: KickLogic, hub: Vector2, outer: float) -> void:
	if logic.meter_popup == "":
		return
	var age := logic.meter_popup_age
	var alpha := 1.0
	var scale := 1.0
	var rise := 0.0
	if age < 0.15:
		var intro := clampf(age / 0.15, 0.0, 1.0)
		alpha = intro
		scale = lerpf(0.72, 1.0, intro)
	else:
		var outro := clampf((age - 0.15) / 0.60, 0.0, 1.0)
		alpha = 1.0 - outro
		rise = outro * 34.0
	var size := maxi(int(round(22.0 * scale)), 12)
	var width := BitmapFonts.measure_px("callout", logic.meter_popup, size)
	var at := Vector2(hub.x - float(width) * 0.5, hub.y - outer - 42.0 - rise)
	BitmapFonts.paint_px(self, "callout", logic.meter_popup, at, size, Color(1.0, 0.9, 0.82, alpha))


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
	if run.weather == RunLogic.BIG_GAME or run.weather == RunLogic.ICED or run.weather == RunLogic.SQUEEZE or run.weather == RunLogic.MONSOON or run.weather == RunLogic.LIGHTS:
		color = KickConstants.COLOR_BOSS
	_text_centered(name, 158.0, 22, color)
	if run.weather == RunLogic.BIG_GAME:
		_text_centered("Meter upgrades off", 184.0, 16, KickConstants.COLOR_TEXT)


func _draw_special_banner(run: RunLogic) -> void:
	if game == null or not game.special_banner_on():
		return
	var lines := SpecialKicks.banner_lines(run.special_for_kick())
	if lines.size() < 2:
		return
	var top_w := BitmapFonts.measure_px("ui", lines[0], 16)
	var bot_w := BitmapFonts.measure_px("ui", lines[1], 28)
	var width := float(maxi(top_w, bot_w) + 48)
	var panel := Rect2((KickConstants.WINDOW_WIDTH - width) * 0.5, 196.0, width, 78.0)
	var saved := texture_filter
	texture_filter = TEXTURE_FILTER_NEAREST
	_steel_panel(panel)
	_pg(lines[0], Vector2(panel.position.x + (width - float(top_w)) * 0.5, panel.position.y + 12.0), 16, Color(0.93, 0.91, 0.84))
	_pg(lines[1], Vector2(panel.position.x + (width - float(bot_w)) * 0.5, panel.position.y + 36.0), 28, Color(1.0, 0.55, 0.1))
	texture_filter = saved


func _draw_tad_card(run: RunLogic) -> void:
	if game == null:
		return
	var alpha := float(game.tad_card_alpha())
	if alpha <= 0.001 or not run.tad_active(1):
		return
	var count := run.tad_level
	var header := "TWO A DAYS %d" % count
	var size := 13
	var widest := BitmapFonts.measure_px("ui", header, 16)
	for level in range(1, count + 1):
		widest = maxi(widest, BitmapFonts.measure_px("ui", RunLogic.tad_line(level), size))
	var plate := Rect2(20, 60, float(widest) + 32.0, 28.0 + float(count) * float(size + 3))
	if plate.end.x > 850.0 or plate.end.y > 600.0:
		size = 12
		widest = BitmapFonts.measure_px("ui", header, 16)
		for level in range(1, count + 1):
			widest = maxi(widest, BitmapFonts.measure_px("ui", RunLogic.tad_line(level), size))
		plate = Rect2(20, 60, float(widest) + 32.0, 28.0 + float(count) * float(size + 3))
	draw_rect(plate, Color(0.07, 0.075, 0.08, 0.94 * alpha))
	draw_rect(plate, Color(0.92, 0.93, 0.95, alpha), false, 3.0)
	draw_rect(plate.grow(-6), Color(0.28, 0.3, 0.33, alpha), false, 1.0)
	var head_w := BitmapFonts.measure_px("ui", header, 16)
	_pg(header, Vector2(plate.position.x + (plate.size.x - float(head_w)) * 0.5, plate.position.y + 8.0), 16, Color(0.95, 0.78, 0.28, alpha))
	var y := plate.position.y + 28.0
	for level in range(1, count + 1):
		var line := RunLogic.tad_line(level)
		var line_w := BitmapFonts.measure_px("ui", line, size)
		_pg(line, Vector2(plate.position.x + (plate.size.x - float(line_w)) * 0.5, y), size, Color(0.93, 0.91, 0.84, alpha))
		y += float(size + 3)


func _draw_kick_clock() -> void:
	if game == null:
		return
	var digit := int(game.clock_digit())
	if digit < 1:
		return
	var text := str(digit)
	var layout := clock_layout(text)
	var label: Rect2 = layout["label"]
	var block: Rect2 = layout["digit"]
	_pg("KICK CLOCK", label.position, 20, Color(0.95, 0.86, 0.45))
	BitmapFonts.paint_px(self, "callout", text, block.position, 90, Color(1.0, 0.96, 0.78))


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
	if run.post_shift_yards() != 0:
		extra += 16
	if run.on_fire():
		extra += 16
	if run.rung_tag() != "":
		extra += 16
	var bug := Rect2(868, 10, 398, 74 + extra)
	_steel_panel(bug)
	var cream := Color(0.93, 0.91, 0.84)
	var left := Rect2(bug.position.x + 6, bug.position.y + 6, 118, 36)
	draw_rect(left, Color(0.12, 0.62, 0.78))
	var title := BroadcastHud.kick_title(run.kick_number, run.run_mode == "endless")
	var title_px := 13
	var title_limit := int(left.size.x) - 12
	while title_px > 9 and BitmapFonts.measure_px("ui", title, title_px) > title_limit:
		title_px -= 1
	_pg(title, left.position + Vector2(6, 4), title_px, Color(0.05, 0.08, 0.1))
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
	var name_x := bug.position.x + 8.0
	if run.is_boss():
		_pg("BOSS", Vector2(bug.position.x + 8, row_y), 12, Color(0.95, 0.55, 0.2))
		name_x = bug.position.x + 52.0
	var name_size := 13
	if BitmapFonts.measure_px("ui", weather, name_size) > 150:
		name_size = 11
	_pg(weather, Vector2(name_x, row_y), name_size, cream)
	var wind := BroadcastHud.wind_band(speed, show_mph)
	var wind_x := maxf(bug.position.x + 168.0, name_x + float(BitmapFonts.measure_px("ui", weather, name_size)) + 18.0)
	_pg(wind, Vector2(wind_x, row_y), 13, cream)
	_wind_pip(Vector2(wind_x - 12.0, row_y + 8), speed, run.wind_direction)
	if run.tad_active(1):
		var tag := "TAD %d" % run.tad_level
		var tag_w := BitmapFonts.measure_px("ui", tag, 13)
		_pg(tag, Vector2(bug.position.x + bug.size.x - float(tag_w) - 8.0, row_y), 13, Color(0.95, 0.78, 0.28))
	row_y += 16
	if show_mph:
		_pg(BroadcastHud.wind_detail(speed, run.wind_direction), Vector2(bug.position.x + 8, row_y), 12, Color(0.55, 0.9, 0.95))
		row_y += 16
	if big_game:
		_pg("METER UPGRADES OFF", Vector2(bug.position.x + 8, row_y), 12, cream)
		row_y += 16
	if run.post_shift_yards() != 0:
		_pg(BroadcastHud.posts_text(run.post_shift_yards()), Vector2(bug.position.x + 8, row_y), 12, Color(0.55, 0.9, 0.95))
		row_y += 16
	if run.on_fire():
		_pg("ON FIRE", Vector2(bug.position.x + 8, row_y), 12, Color(1.0, 0.55, 0.1))
		row_y += 16
	if run.rung_tag() != "":
		_pg(run.rung_tag(), Vector2(bug.position.x + 8, row_y), 12, Color(0.95, 0.78, 0.28))


func _score_bug_rect(run: RunLogic) -> Rect2:
	var show_mph := false
	if game != null and game.logic != null:
		show_mph = game.logic.stats.flag_reader
	var big_game := run.is_boss() and run.weather == RunLogic.BIG_GAME
	var extra := 0
	if show_mph:
		extra += 16
	if big_game:
		extra += 16
	if run.post_shift_yards() != 0:
		extra += 16
	if run.on_fire():
		extra += 16
	if run.rung_tag() != "":
		extra += 16
	return Rect2(868, 18 + 74 + extra, 398, 70)


func _draw_score_bug(run: RunLogic) -> void:
	var bug := _score_bug_rect(run)
	_steel_panel(bug)
	var cells := [
		{"label": "SCORE", "value": str(run.score), "w": 86.0},
		{"label": "STREAK", "value": str(run.streak), "w": 86.0},
		{"label": "MULT", "value": RunLogic._two_decimals(run.kick_mult_preview()), "w": 90.0},
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
			var shown := str(cell["value"])
			var px := 22
			var ring_tag := ""
			if str(cell["label"]) == "MULT" and run.ring_factor > 1.001:
				ring_tag = "RING X%d" % int(round(run.ring_factor))
				px = mini(_mult_px(shown), 16)
			elif str(cell["label"]) == "MULT":
				px = _mult_px(shown)
			var value_y := 16.0 if ring_tag != "" else 22.0
			_pg(shown, rect.position + Vector2(6, value_y), px, cream)
			if ring_tag != "":
				_pg(ring_tag, rect.position + Vector2(6, 40), 11, Color(0.35, 0.90, 1.00))
		x += float(cell["w"]) + 4.0


func _mult_px(text: String) -> int:
	var limit := 90.0 - 12.0
	for size in [22, 18, 16]:
		if float(BitmapFonts.measure_px("ui", text, size)) <= limit:
			return size
	return 16


func _draw_kicker_plate(logic: KickLogic, run: RunLogic) -> void:
	var required := logic.kick_distance
	var max_range := logic.max_range_at_full_power()
	var warn := BroadcastHud.max_warning(required, max_range)
	var kit := BroadcastHud.kit_text(run.kicker_id)
	var ball := BroadcastHud.ball_text(run.kicker_id)
	if run.tad_active(5) and run.kicker_id == Kickers.WALK_ON:
		kit = "OFF AT TAD 5+"
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
	var yards := BroadcastHud.yards_text(max_range)
	_pg(yards, Vector2(text_x + 164, y - 2), 13, yards_color)
	var luck_n := run.luck()
	var luck_text := "LUCK %d" % luck_n
	var luck_size := 12
	var luck_x := text_x + 164.0 + float(BitmapFonts.measure_px("ui", yards, 13)) + 8.0
	var plate_right := plate.position.x + plate.size.x - 8.0
	while luck_size > 8 and luck_x + float(BitmapFonts.measure_px("ui", luck_text, luck_size)) > plate_right:
		luck_size -= 1
	var luck_color := Color(0.95, 0.78, 0.22) if luck_n > 0 else Color(0.55, 0.58, 0.62)
	_pg(luck_text, Vector2(luck_x, y), luck_size, luck_color)
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
			var bottle := Rect2(chip.position + Vector2(22, 3), Vector2(18, 18))
			var locked := not run.belt_usable() or (id == Vitamins.ELECTROLYTE and run.electrolyte_blocked())
			var tint := Color(0.55, 0.56, 0.58, 0.85) if locked else Color.WHITE
			if icon != null:
				draw_texture_rect(icon, bottle, false, tint)
			else:
				var ink := Vitamins.bottle_color(id)
				if locked:
					ink = Color(0.35, 0.36, 0.38)
				draw_rect(bottle, ink)
			if locked:
				draw_rect(chip, Color(0.12, 0.13, 0.14, 0.45))
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
var tad_left := Rect2()
var tad_right := Rect2()
var tad_wheel := Rect2()
var tad_badge := Rect2()
var tad_font := 11


func tad_step_at(point: Vector2) -> int:
	if tad_left.has_point(point):
		return -1
	if tad_right.has_point(point):
		return 1
	return 0


func tad_wheel_at(point: Vector2) -> bool:
	return tad_wheel.size.x > 1.0 and tad_wheel.has_point(point)


func kicker_slot_at(point: Vector2) -> int:
	for i in kicker_rects.size():
		var rect: Rect2 = kicker_rects[i]
		if rect.has_point(point):
			return i
	return -1


var _card_frames := {}
var _card_busts := {}


func layout_select_chrome() -> void:
	kicker_rects = SelectCard.grid_rects()
	clear_tad_picker()
	if game == null or game.front == null or game.front.run_mode != "standard":
		return
	var slot := int(game.tad_picker_slot)
	if slot < 0 or slot != int(game.highlight) or slot >= kicker_rects.size():
		return
	var id := str(Kickers.ALL[slot]["id"])
	if not Kickers.is_unlocked(id) or SaveData.tad_unlocked(id) < 1:
		return
	var layout: Dictionary = SelectCard.picker_layout(kicker_rects[slot])
	tad_left = layout["left"]
	tad_right = layout["right"]
	tad_wheel = layout["union"]
	tad_badge = layout["badge"]
	tad_font = int(layout["font"])


func clear_tad_picker() -> void:
	tad_left = Rect2()
	tad_right = Rect2()
	tad_wheel = Rect2()
	tad_badge = Rect2()
	tad_font = 11


func _draw_kicker_select() -> void:
	# The stadium stays behind a dark gutter. The lock JPEG is not drawn.
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0.02, 0.025, 0.03, 0.78))
	_pg_centered("CHOOSE YOUR KICKER", 16.0, 18, Color(0.95, 0.92, 0.84))
	layout_select_chrome()
	var picked := int(game.highlight)
	for i in kicker_rects.size():
		var info: Dictionary = Kickers.ALL[i]
		_draw_playing_card(kicker_rects[i], str(info["id"]), Kickers.is_unlocked(str(info["id"])), i == picked)
	_draw_tad_picker()
	_draw_kicker_rundown(picked)
	var footer := "1 TO 8 HIGHLIGHT. SPACE OR CLICK AGAIN TO START."
	if game.front != null and game.front.run_mode == "standard":
		if int(game.tad_picker_slot) >= 0:
			footer = "BRACKETS CHANGE TAD. SPACE OR CLICK AGAIN TO START. ESC BACKS OUT."
		else:
			footer = "1 TO 8 HIGHLIGHT. SPACE OR CLICK TO PICK TAD. CLICK AGAIN TO START."
	_pg_centered(footer, 700.0, 13, Color(0.95, 0.92, 0.84))


func _draw_tad_picker() -> void:
	if tad_wheel.size.x < 1.0:
		return
	var cream := Color(0.95, 0.92, 0.84)
	draw_rect(tad_badge, Color(0.05, 0.06, 0.08, 0.94))
	draw_rect(tad_badge, Color(0.95, 0.78, 0.28), false, 1.0)
	_tad_chevron(tad_left, true)
	_tad_chevron(tad_right, false)
	var id := str(Kickers.ALL[int(game.tad_picker_slot)]["id"])
	_pg_centered_in(tad_badge, "TAD %d" % SaveData.tad_selected(id), tad_font, cream, 2.0)


func _tad_chevron(rect: Rect2, point_left: bool) -> void:
	var mid := rect.get_center()
	var reach := minf(rect.size.x, rect.size.y) * 0.32
	var color := Color(0.95, 0.92, 0.84)
	if point_left:
		draw_colored_polygon(PackedVector2Array([mid + Vector2(-reach, 0), mid + Vector2(reach * 0.75, -reach), mid + Vector2(reach * 0.75, reach)]), color)
	else:
		draw_colored_polygon(PackedVector2Array([mid + Vector2(reach, 0), mid + Vector2(-reach * 0.75, -reach), mid + Vector2(-reach * 0.75, reach)]), color)


func _pg_centered_in(rect: Rect2, text: String, size: int, color: Color, y_offset: float) -> void:
	var width := BitmapFonts.measure_px("ui", text, size)
	var at := Vector2(rect.position.x + (rect.size.x - float(width)) * 0.5, rect.position.y + y_offset)
	_pg(text, at, size, color)


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
	var rank_px := SelectCard.corner_px(rect, rank)
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
		var luck := SelectCard.luck_line(id)
		var luck_color := Color(0.95, 0.78, 0.22) if SelectCard.base_luck(id) > 0 else Color(0.55, 0.58, 0.62)
		if kits.size() > 1 and not _well_fits(kits, ball, well, body, true):
			if id == Kickers.VEX:
				body -= 1
			else:
				kits = PackedStringArray([kits[kits.size() - 1]])
		var lines: PackedStringArray = kits.duplicate()
		lines.append(ball)
		lines.append(luck)
		while body > 6 and not _lines_fit(lines, well, body):
			body -= 1
		_pg_stack(lines, well, body, cream, lines.size() - 2, Color(0.42, 0.82, 0.4), luck_color)
	else:
		var unlock := SelectCard.unlock_line(id)
		var fit := body
		var wrapped := _pg_wrap(unlock, int(well.size.x) - 6, fit)
		while fit > 6:
			var too_wide := false
			for line in wrapped:
				if BitmapFonts.measure_px("ui", line, fit) > int(well.size.x) - 4:
					too_wide = true
			if (1 + wrapped.size()) * (fit + 2) <= int(well.size.y) and not too_wide:
				break
			fit -= 1
			wrapped = _pg_wrap(unlock, int(well.size.x) - 6, fit)
		var locked := PackedStringArray(["LOCKED"])
		for line in wrapped:
			locked.append(line)
		_pg_stack(locked, well, fit, orange, -1, orange)
	if picked:
		_stroke_round(rect.grow(3.0), rect.size.y * (10.0 / 134.0), Color(0.96, 0.78, 0.28), 3.0)


func _card_slice(rect: Rect2, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(rect.position + Vector2(rect.size.x * x, rect.size.y * y), Vector2(rect.size.x * w, rect.size.y * h))


func _well_fits(kits: PackedStringArray, ball: String, well: Rect2, size: int, with_luck: bool = false) -> bool:
	var lines := kits.size() + 1
	if ball == "":
		lines = kits.size()
	if with_luck:
		lines += 1
	var height := lines * (size + 2)
	if height > int(well.size.y):
		return false
	var widest := BitmapFonts.measure_px("ui", ball, size)
	for line in kits:
		widest = maxi(widest, BitmapFonts.measure_px("ui", line, size))
	return widest <= int(well.size.x)


func _lines_fit(lines: PackedStringArray, well: Rect2, size: int) -> bool:
	if lines.size() * (size + 2) > int(well.size.y):
		return false
	for line in lines:
		if BitmapFonts.measure_px("ui", line, size) > int(well.size.x):
			return false
	return true


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


func _pg_stack(lines: PackedStringArray, area: Rect2, size: int, color: Color, green_at: int, green: Color, last_color: Color = Color(0, 0, 0, 0)) -> void:
	if lines.is_empty():
		return
	var step := size + 2
	var block_h := lines.size() * step
	var y := area.position.y + maxf(0.0, (area.size.y - float(block_h)) * 0.5)
	for i in lines.size():
		var ink := color
		if last_color.a > 0.0 and i == lines.size() - 1:
			ink = last_color
		elif i == green_at:
			ink = green
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


func _draw_wrapped_at(text: String, x: float, y: float, width: float, size: int, color: Color = KickConstants.COLOR_TEXT) -> float:
	var font := ThemeDB.fallback_font
	if font == null:
		return y
	var line := ""
	for word in text.split(" "):
		var trial := (line + word).strip_edges()
		if line != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			_text(Vector2(x, y), line.strip_edges(), size, color)
			y += float(size) + 4.0
			line = word + " "
		else:
			line = trial + " "
	if line.strip_edges() != "":
		_text(Vector2(x, y), line.strip_edges(), size, color)
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
	_text_centered("M retakes this kick. %s accepts the miss." % Settings.key_sentence("confirm"), box.position.y + 140.0, 22, KickConstants.COLOR_TEXT)


static func pick_row_rects(count: int) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if count < 1:
		return rects
	var card_w := 232.0
	var card_h := 324.0
	var gap := 28.0
	var total := float(count) * card_w + float(count - 1) * gap
	var left := 640.0 - total * 0.5
	for i in count:
		rects.append(Rect2(left + float(i) * (card_w + gap), 214.0, card_w, card_h))
	return rects


static func pick_panel_rect(count: int, score_bottom: float = 0.0) -> Rect2:
	var rects := pick_row_rects(count)
	if rects.is_empty():
		return Rect2()
	var left := rects[0].position.x
	var right := rects[rects.size() - 1].end.x
	var panel := Rect2(left - 24.0, 172.0, right - left + 48.0, 428.0)
	if count >= 4 and panel.position.y <= score_bottom:
		panel.position.y = 186.0
	return panel


static func lifted_rect(rect: Rect2, lift: float) -> Rect2:
	return Rect2(rect.position + Vector2(0.0, lift), rect.size)


const OFFER_GOLD := Color(0.95, 0.78, 0.22)
var _offer_tex: Dictionary = {}
var _offer_panel_box: StyleBoxTexture


func clear_offer_art() -> void:
	_offer_tex.clear()
	_offer_panel_box = null


func offer_texture(file_name: String) -> Texture2D:
	if _offer_tex.has(file_name):
		return _offer_tex[file_name]
	var path := "res://art/ui/offer/%s" % file_name
	var texture: Texture2D = null
	if ResourceLoader.exists(path) and FileAccess.file_exists(path + ".import"):
		texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			texture = ImageTexture.create_from_image(image)
	_offer_tex[file_name] = texture
	return texture


func offer_name_lines(title: String) -> Dictionary:
	var font := ThemeDB.fallback_font
	if font == null:
		return {"size": 12, "lines": PackedStringArray([title])}
	var size := 18
	while size > 12:
		if font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= 200.0:
			return {"size": size, "lines": PackedStringArray([title])}
		size -= 1
	if font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x <= 200.0:
		return {"size": 12, "lines": PackedStringArray([title])}
	return {"size": 12, "lines": _wrap_lines(title, 200.0, 12)}


func offer_effect_lines(text: String) -> Dictionary:
	var size := 15
	var lines := _wrap_lines(text, 200.0, size)
	if lines.size() > 5:
		size = 13
		lines = _wrap_lines(text, 200.0, 13)
	return {"size": size, "lines": lines, "height": float(lines.size()) * (float(size) + 4.0)}


func _offer_panel_style() -> StyleBoxTexture:
	if _offer_panel_box != null:
		return _offer_panel_box
	var texture := offer_texture("offer_panel.png")
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 24
	style.texture_margin_right = 24
	style.texture_margin_top = 24
	style.texture_margin_bottom = 24
	_offer_panel_box = style
	return style


func _draw_pick_panel(run: RunLogic, count: int) -> void:
	if count < 1:
		return
	var score_bottom := 0.0
	if game != null:
		score_bottom = _score_bug_rect(run).end.y
	var panel := pick_panel_rect(count, score_bottom)
	var style := _offer_panel_style()
	if style != null:
		var saved := texture_filter
		texture_filter = TEXTURE_FILTER_NEAREST
		draw_style_box(style, panel)
		texture_filter = saved
	else:
		draw_rect(panel, Color(0.04, 0.05, 0.06, 0.86))
		draw_rect(panel, Color(0.42, 0.40, 0.42), false, 2.0)


func _offer_title(run: RunLogic) -> String:
	if run.forced_offer_live:
		return "FORCED CURSE"
	if run.bomb_offer_live:
		return "BOMB BONUS"
	if run.ring_offer_live:
		return "BONUS RING"
	return "PICK ONE"


func _offer_kind(run: RunLogic, slot: String) -> String:
	if run.ring_offer_live or run.bomb_offer_live or slot == "bonus":
		return "bonus"
	if slot == Loadout.CURSE:
		return "curse"
	if slot == Loadout.PERK:
		return "perk"
	return "equipment"


func _offer_slot_color(slot: String) -> Color:
	if slot == Loadout.PERK:
		return Color(0.55, 0.42, 0.95)
	return _slot_color(slot)


func _offer_border(kind: String, slot: String) -> Color:
	if kind == "bonus":
		return OFFER_GOLD
	return _offer_slot_color(slot)


func _center_default(text: String, baseline: float, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(Vector2(640.0 - width * 0.5, baseline), text, size, color)


func _draw_offer_footer(run: RunLogic) -> void:
	if run.forced_offer_live:
		_center_default("Pick one. This one can't be skipped.", 552.0, 18, KickConstants.COLOR_TEXT)
		return
	if run.free_reroll_ready():
		_center_default("Free rerolls %d. %s rerolls. %s skips." % [run.second_look_bank, Settings.key_sentence("offer_reroll"), Settings.key_sentence("skip")], 552.0, 18, KickConstants.COLOR_TEXT)
	else:
		_center_default("Rerolls left: %d. %s rerolls. %s skips." % [run.rerolls_left, Settings.key_sentence("offer_reroll"), Settings.key_sentence("skip")], 552.0, 18, KickConstants.COLOR_TEXT)
	_center_default("Skip takes nothing.", 576.0, 16, KickConstants.COLOR_TEXT)


func _draw_offer_name(banner: Rect2, title: String, color: Color) -> void:
	var laid: Dictionary = offer_name_lines(title)
	var size := int(laid["size"])
	var lines: PackedStringArray = laid["lines"]
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var step := float(size) + 4.0
	var block := float(lines.size()) * step
	var y := banner.position.y + maxf(0.0, (banner.size.y - block) * 0.5) + float(size)
	for line in lines:
		var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_text(Vector2(banner.position.x + (banner.size.x - width) * 0.5, y), line, size, color)
		y += step


func _draw_rung_yards(window: Rect2, yards: int, fade: float) -> void:
	var text := str(yards)
	var size := 72
	while size > 16 and BitmapFonts.measure_px("callout", text, size) > 88:
		size -= 2
	var num_w := BitmapFonts.measure_px("callout", text, size)
	var yd_w := BitmapFonts.measure_px("ui", "YD", 14)
	var block := float(size) + 18.0
	var top := window.position.y + maxf(0.0, (window.size.y - block) * 0.5)
	var gold := OFFER_GOLD
	gold.a = fade
	BitmapFonts.paint_px(self, "callout", text, Vector2(window.position.x + (window.size.x - float(num_w)) * 0.5, top), size, gold)
	var cream := Color(0.93, 0.91, 0.84, fade)
	_pg("YD", Vector2(window.position.x + (window.size.x - float(yd_w)) * 0.5, top + float(size) + 2.0), 14, cream)


func _draw_pick_shell(rect: Rect2, kind: String, slot: String, fade: float, lifted: bool) -> void:
	var border := _offer_border(kind, slot)
	border.a = fade
	var frame := offer_texture("offer_card_%s.png" % kind)
	var saved := texture_filter
	texture_filter = TEXTURE_FILTER_NEAREST
	if frame != null:
		draw_texture_rect(frame, rect, false, Color(1, 1, 1, fade))
	else:
		draw_rect(rect, Color(0.05, 0.08, 0.1, 0.94 * fade))
		draw_rect(rect, border, false, 4.0)
		draw_rect(Rect2(rect.position + Vector2(12, 10), Vector2(208, 24)), Color(0.10, 0.12, 0.15, fade))
		draw_rect(Rect2(rect.position + Vector2(10, 148), Vector2(212, 36)), Color(0.10, 0.12, 0.15, fade))
		draw_rect(Rect2(rect.position + Vector2(16, 194), Vector2(200, 116)), Color(0.07, 0.08, 0.10, fade))
	if lifted:
		var hover := offer_texture("offer_card_hover.png")
		if hover != null:
			draw_texture_rect(hover, rect, false, Color(1, 1, 1, fade))
		else:
			var bright := border.lerp(Color.WHITE, 0.5)
			bright.a = fade
			draw_rect(rect, bright, false, 2.0)
	texture_filter = saved


func _draw_rung_choice(run: RunLogic) -> void:
	card_rects = []
	var logic: KickLogic = game.logic
	var names: Array = ["safe", "long", "bomb"]
	var lift_index := run.rung_highlight
	if lift_index >= 0 and lift_index < names.size() and run.rung_blocked(str(names[lift_index]), logic):
		lift_index = -1
	if game != null:
		if not game.offer_primed:
			game.set_offer_hover(lift_index, true)
		elif game.offer_hover != lift_index:
			game.set_offer_hover(lift_index)
	_draw_pick_panel(run, names.size())
	_pg_centered("LONG OR SAFE", 182.0, 22, KickConstants.COLOR_ATTEMPT)
	var bases := pick_row_rects(names.size())
	for i in names.size():
		var lift := 0.0
		if game != null and not run.rung_blocked(str(names[i]), logic):
			lift = game.offer_lift(i)
		var rect := lifted_rect(bases[i], lift)
		card_rects.append(rect)
		var name := str(names[i])
		var blocked := run.rung_blocked(name, logic)
		var fade := 0.45 if blocked else 1.0
		_draw_pick_shell(rect, "bonus", "bonus", fade, absf(lift) > 0.5 and not blocked)
		var ribbon := str(i + 1) + " " + name.to_upper()
		var ink := Color(0.45, 0.47, 0.50, fade) if blocked else Color(OFFER_GOLD.r, OFFER_GOLD.g, OFFER_GOLD.b, fade)
		_pg(ribbon, rect.position + Vector2(12, 14), 14, ink)
		_draw_rung_yards(Rect2(rect.position + Vector2(68, 42), Vector2(96, 96)), int(round(run.rung_yards(name))), fade)
		var title_color := Color(0.45, 0.47, 0.50, fade) if blocked else Color(KickConstants.COLOR_ATTEMPT.r, KickConstants.COLOR_ATTEMPT.g, KickConstants.COLOR_ATTEMPT.b, fade)
		_draw_offer_name(Rect2(rect.position + Vector2(10, 148), Vector2(212, 36)), run.rung_card_title(name), title_color)
		var well := Rect2(rect.position + Vector2(16, 194), Vector2(200, 116))
		if blocked:
			var out_w := BitmapFonts.measure_px("ui", "OUT OF RANGE", 14)
			_pg("OUT OF RANGE", Vector2(well.position.x + (well.size.x - float(out_w)) * 0.5, well.position.y + 28.0), 14, Color(0.45, 0.47, 0.50, fade))
		else:
			_draw_wrapped(run.rung_card_line(name), Rect2(well.position + Vector2(0, 16), well.size), 15)
	_draw_offer_footer(run)


func _draw_offer(run: RunLogic) -> void:
	card_rects = []
	var count := run.offer.size()
	if game != null and not game.offer_primed:
		game.set_offer_hover(-1, true)
	if count == 0:
		_text_centered("Nothing left to pick. Press %s to continue." % Settings.key_sentence("skip"), 430.0, 28, KickConstants.COLOR_TEXT)
		_draw_offer_footer(run)
		return
	_draw_pick_panel(run, count)
	_pg_centered(_offer_title(run), 182.0, 22, KickConstants.COLOR_ATTEMPT)
	var bases := pick_row_rects(count)
	for i in count:
		var lift := 0.0
		if game != null:
			lift = game.offer_lift(i)
		var rect := lifted_rect(bases[i], lift)
		card_rects.append(rect)
		var card: Dictionary = run.offer[i]
		var id := str(card.get("id", ""))
		var rank := int(card.get("rank", 1))
		var slot := str(card.get("slot", ""))
		var kind := _offer_kind(run, slot)
		_draw_pick_shell(rect, kind, slot, 1.0, absf(lift) > 0.5)
		var label := Loadout.type_label(slot).to_upper()
		var slot_ink := _offer_slot_color(slot)
		_pg("%d %s" % [i + 1, label], rect.position + Vector2(12, 14), 14, slot_ink)
		if bool(card.get("lucky", false)):
			var lucky_w := BitmapFonts.measure_px("ui", "LUCKY", 14)
			_pg("LUCKY", rect.position + Vector2(220.0 - float(lucky_w), 14), 14, OFFER_GOLD)
		_draw_slot_icon(id, rank, slot, Rect2(rect.position + Vector2(68, 42), Vector2(96, 96)), true)
		_draw_offer_name(Rect2(rect.position + Vector2(10, 148), Vector2(212, 36)), Loadout.card_title(id, rank), KickConstants.COLOR_ATTEMPT)
		var effect: Dictionary = offer_effect_lines(run.lived_effect_line(id, rank))
		_draw_wrapped(run.lived_effect_line(id, rank), Rect2(rect.position + Vector2(16, 194 + 16), Vector2(200, 116)), int(effect["size"]))
	_draw_offer_footer(run)


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
	var middle := logic.inner_ring_hit
	var lines := ResultStamp.words(logic.shanked, logic.result_text, logic.bank_shot, logic.insured, logic.perfect, middle, logic.lucky_save)
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
	if run.end_reason == "too_weak":
		var reason := "TOO WEAK"
		var reason_w := float(BitmapFonts.measure_px("ui", reason, 16))
		var field_width := KickConstants.WINDOW_WIDTH - 500.0
		_pg(reason, Vector2((field_width - reason_w) * 0.5, box.position.y + 78.0), 16, Color(0.95, 0.55, 0.28))
	_text_centered("Score %d" % run.score, box.position.y + 130.0, 32, KickConstants.COLOR_TEXT)
	if run.tad_toast != "":
		_pg_center(run.tad_toast, box.position.y + 188.0, 18, Color(0.95, 0.78, 0.28))
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
	var back_line := "%s: trophy room    %s: main menu    R: choose a kicker" % [Settings.key_sentence("trophy"), Settings.key_sentence("back")]
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
var _meter_frame: Texture2D
var _needle_tex: Texture2D
var meter_frame_draws := 0
var meter_needle_draws := 0


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


func _rail_gap(left: Dictionary, right: Dictionary) -> float:
	if bool(right.get("second", false)):
		return 8.0
	var left_slot := str(left.get("slot", ""))
	var right_slot := str(right.get("slot", ""))
	if left_slot != right_slot and (right_slot == Loadout.PERK or right_slot == Loadout.CURSE or left_slot == Loadout.PERK):
		return 22.0
	return 8.0


func _draw_loadout_rail(run: RunLogic) -> void:
	slot_hits = []
	var entries: Array = []
	var gear: Array = [
		[Loadout.CLEATS, "Cleats", run.cleats_id, run.cleats_rank, run.cleats2_id, run.cleats2_rank],
		[Loadout.HELMET, "Helmet", run.helmet_id, run.helmet_rank, run.helmet2_id, run.helmet2_rank],
		[Loadout.GLOVES, "Gloves", run.gloves_id, run.gloves_rank, run.gloves2_id, run.gloves2_rank],
	]
	for row in gear:
		entries.append({"name": str(row[1]), "id": str(row[2]), "rank": int(row[3]), "slot": str(row[0]), "second": false})
		if str(row[4]) != "":
			entries.append({"name": str(row[1]), "id": str(row[4]), "rank": int(row[5]), "slot": str(row[0]), "second": true})
	for i in 2:
		var perk_id := ""
		var perk_rank := 0
		if i < run.perks.size():
			perk_id = str(run.perks[i].get("id", ""))
			perk_rank = int(run.perks[i].get("rank", 1))
		entries.append({"name": "Perk", "id": perk_id, "rank": perk_rank, "slot": Loadout.PERK, "second": false})
	for i in 2:
		var curse_id := ""
		if i < run.curse_ids.size():
			curse_id = str(run.curse_ids[i])
		entries.append({"name": "Curse", "id": curse_id, "rank": 0, "slot": Loadout.CURSE, "second": false})
	# A second style uses the same 48px frame. Three of them still fit on the 1280-wide bar.
	var slot_w := 48.0
	var width := 0.0
	for i in entries.size():
		width += slot_w
		if i + 1 < entries.size():
			width += _rail_gap(entries[i], entries[i + 1])
	var cursor := (KickConstants.WINDOW_WIDTH - width) * 0.5
	var row_y := 8.0
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var rect := Rect2(cursor, row_y, slot_w, slot_w)
		cursor += slot_w
		if i + 1 < entries.size():
			cursor += _rail_gap(entry, entries[i + 1])
		slot_hits.append({
			"rect": rect,
			"id": str(entry["id"]),
			"rank": int(entry["rank"]),
			"slot": str(entry["slot"]),
			"name": str(entry["name"]),
		})
		var benched := bool(entry.get("second", false)) and not run.gm_live() and run.gm_second_slots.has(str(entry["slot"]))
		var emphasized := slot_is_emphasized(i, hover_slot, pinned_slot) and not benched
		_draw_slot_icon(str(entry["id"]), int(entry["rank"]), str(entry["slot"]), rect, true, emphasized, benched)


func _draw_slot_icon(id: String, rank: int, slot: String, rect: Rect2, show_badge: bool, emphasized: bool = false, dim: bool = false, fade_scale: float = 1.0) -> void:
	var fade := (0.4 if dim else 1.0) * fade_scale
	draw_rect(rect, Color(0.05, 0.08, 0.1, 0.9 * fade))
	var edge := _slot_color(slot)
	edge.a = fade
	draw_rect(rect, edge, false, 2.0)
	var path := Loadout.sprite_path(id) if id != "" else Loadout.empty_slot_path(slot)
	var texture := _icon(path)
	if texture != null:
		_draw_fit(texture, rect.grow(-4), Color(1, 1, 1, fade))
	elif id != "":
		var words := Loadout.piece_name(id).split(" ")
		var ink := KickConstants.COLOR_TEXT
		ink.a = fade
		_text(rect.position + Vector2(4, 22), str(words[0]), 12, ink)
	elif slot == Loadout.PERK:
		draw_rect(rect.grow(-8), Color(0.2, 0.24, 0.3, 0.9 * fade), false, 2.0)
	var badge := Loadout.rank_badge(id, rank) if show_badge else ""
	if badge == "":
		return
	var mode := "standard"
	if game != null and game.run != null:
		mode = game.run.run_mode
	var is_max := rank == Loadout.max_rank(id, mode)
	var size_class := "rail" if rect.size.x <= 56.0 else "card"
	_draw_rank_chip(rect, badge, slot, is_max, emphasized, size_class, fade)


static func slot_is_emphasized(index: int, hover: int, pinned: int) -> bool:
	var active := pinned if pinned >= 0 else hover
	return index == active and active >= 0


static func rank_chip_layout(rect: Rect2, label: String, size_class: String) -> Dictionary:
	var rail := size_class != "card"
	var inset := 2.0 if rail else 3.0
	var pad_x := 2
	var pad_y := 2
	var font := 8 if rail else 10
	var height_cap := 12 if rail else 15
	var width_cap := floorf(rect.size.x * (0.65 if rail else 0.60) - inset)
	while font > 5:
		var text_w := BitmapFonts.measure_px("ui", label, font)
		if float(text_w + pad_x * 2) <= width_cap:
			break
		font -= 1
	var text_w := BitmapFonts.measure_px("ui", label, font)
	var chip_w := float(mini(int(width_cap), text_w + pad_x * 2))
	var chip_h := float(mini(height_cap, font + pad_y * 2))
	var chip_x := floorf(rect.position.x + rect.size.x - inset - chip_w)
	var chip_y := floorf(rect.position.y + rect.size.y - inset - chip_h)
	return {
		"rect": Rect2(chip_x, chip_y, chip_w, chip_h),
		"font": font,
		"text_w": text_w,
	}


static func rank_numeral_color(is_max: bool, emphasized: bool) -> Color:
	var ink := Color(0.95, 0.78, 0.16) if is_max else KickConstants.COLOR_TEXT
	ink.a = 1.0 if emphasized else 0.9
	return ink


func _draw_rank_chip(rect: Rect2, badge: String, slot: String, is_max: bool, emphasized: bool, size_class: String, fade: float = 1.0) -> void:
	var layout: Dictionary = rank_chip_layout(rect, badge, size_class)
	var chip: Rect2 = layout["rect"]
	var font := int(layout["font"])
	var backing := Color(0.03, 0.05, 0.07, (0.92 if emphasized else 0.65) * fade)
	draw_rect(chip, backing)
	var outline := _slot_color(slot)
	outline.a = 0.8 * fade
	draw_rect(chip, outline, false, 1.0)
	var text_w := float(layout["text_w"])
	var at := Vector2(chip.position.x + (chip.size.x - text_w) * 0.5, chip.position.y + (chip.size.y - float(font)) * 0.5)
	var numeral := rank_numeral_color(is_max, emphasized)
	numeral.a *= fade
	BitmapFonts.paint_px(self, "ui", badge, at, font, numeral)


func _draw_fit(texture: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var size := texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var drawn := size * scale
	var at := rect.position + (rect.size - drawn) * 0.5
	draw_texture_rect(texture, Rect2(at, drawn), false, tint)


func _meter_art() -> Texture2D:
	if _meter_frame != null:
		return _meter_frame
	_meter_frame = load(MeterGauge.FRAME_PATH) as Texture2D
	return _meter_frame


func _needle_art() -> Texture2D:
	if _needle_tex != null:
		return _needle_tex
	_needle_tex = load(MeterGauge.NEEDLE_PATH) as Texture2D
	return _needle_tex


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
		lines.append_array(_wrap_lines(game.run.lived_effect_line(id, rank if rank > 0 else 1), 248.0, 14))
	var anchor: Rect2 = hit["rect"]
	var box := Rect2(anchor.position + Vector2(0, anchor.size.y + 8.0), Vector2(264, 16.0 + float(lines.size()) * 18.0))
	if box.position.x + box.size.x > KickConstants.WINDOW_WIDTH - 8.0:
		box.position.x = KickConstants.WINDOW_WIDTH - 8.0 - box.size.x
	if box.position.y + box.size.y > KickConstants.WINDOW_HEIGHT - 8.0:
		box.position.y = maxf(8.0, anchor.position.y - box.size.y - 8.0)
	_paint_tooltip(box, lines)


func _rundown_fit(sentences: PackedStringArray, width: float, panel_h: float) -> Dictionary:
	var chosen := {"size": 11, "step": 12, "rows": [], "height": panel_h}
	for pair in [[14, 18], [12, 15], [11, 12]]:
		var size := int(pair[0])
		var step := int(pair[1])
		var wrapped: Array = []
		for sentence in sentences:
			for row in _wrap_lines(str(sentence), width, size):
				wrapped.append(row)
		var height := 16.0 + float(wrapped.size()) * float(step)
		chosen = {"size": size, "step": step, "rows": wrapped, "height": height}
		if height <= panel_h:
			return chosen
	return chosen


func _paint_tooltip(box: Rect2, lines: Array, size: int = 14, step: int = 18) -> void:
	draw_rect(box, Color(0.05, 0.08, 0.1, 0.94))
	draw_rect(box, KickConstants.COLOR_ATTEMPT, false, 2.0)
	var y := box.position.y + float(step)
	for line in lines:
		_text(Vector2(box.position.x + 8, y), str(line), size, KickConstants.COLOR_TEXT)
		y += float(step)


func _draw_kicker_rundown(slot: int) -> void:
	if slot < 0 or slot >= Kickers.ALL.size() or kicker_rects.is_empty():
		return
	var id := str(Kickers.ALL[slot]["id"])
	var unlocked := Kickers.is_unlocked(id)
	var cap := -1
	var picked := -1
	if unlocked and game.front != null and game.front.run_mode == "standard":
		cap = SaveData.tad_unlocked(id)
		if int(game.tad_picker_slot) == slot:
			picked = SaveData.tad_selected(id)
	var grid_left := float(kicker_rects[0].position.x)
	var width := maxf(120.0, grid_left - 16.0)
	var sentences: PackedStringArray = PackedStringArray()
	for sentence in Kickers.rundown_lines(id, unlocked, cap, picked):
		if str(sentence).strip_edges() != "":
			sentences.append(str(sentence))
	var fit := _rundown_fit(sentences, width - 16.0, 692.0 - 46.0)
	var wrapped: Array = fit["rows"]
	var height := float(fit["height"])
	var top := 46.0
	var limit := 692.0
	if top + height > limit:
		height = limit - top
	# The left gutter stays off the cards, the gold rim, and the footer.
	_paint_tooltip(Rect2(8.0, top, width, height), wrapped, int(fit["size"]), int(fit["step"]))


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
	_text_centered("Trophy: %s" % run.trophy_name, 112.0, 26, Color(1.0, 0.9, 0.45))


func _draw_too_weak() -> void:
	if game == null or game.too_weak_age < RunLogic.TOO_WEAK_BEAT or game.run.phase != RunLogic.Phase.PLAYING:
		return
	var age := float(game.too_weak_age) - RunLogic.TOO_WEAK_BEAT
	var scale := 2
	var lines := PackedStringArray(["TOO", "WEAK"])
	var block := BitmapFonts.line_height("callout", scale) * lines.size()
	block += 16 + BitmapFonts.line_height("ui", 1) * 2
	var top := (KickConstants.WINDOW_HEIGHT - float(block)) * 0.34
	if age < ResultStamp.SLAM_SEC:
		top += 12.0
	draw_rect(Rect2(0, top - 16.0, KickConstants.WINDOW_WIDTH, float(block) + 32.0), Color(0, 0, 0, 0.55))
	var saved_filter := texture_filter
	texture_filter = TEXTURE_FILTER_NEAREST
	var y := top
	for line in lines:
		_paint_centered("callout", line, y, scale, Vector2.ZERO)
		y += float(BitmapFonts.line_height("callout", scale))
	y += 16.0
	_paint_centered("ui", game.too_weak_flavor, y, 1, Vector2.ZERO)
	y += float(BitmapFonts.line_height("ui", 1))
	_paint_centered("ui", game.too_weak_numbers, y, 1, Vector2.ZERO)
	texture_filter = saved_filter


func _draw_too_weak_debug() -> void:
	if game == null or game.too_weak_debug == "":
		return
	var rows: PackedStringArray = str(game.too_weak_debug).split("\n")
	var box := Rect2(180, 86, 920, 18.0 + float(rows.size()) * 22.0)
	draw_rect(box, Color(0.05, 0.08, 0.1, 0.92))
	draw_rect(box, Color(0.95, 0.78, 0.28), false, 2.0)
	var y := box.position.y + 22.0
	for row in rows:
		_text_centered(str(row), y, 16, KickConstants.COLOR_TEXT)
		y += 22.0


func _draw_save_note() -> void:
	if game.save_note == "":
		return
	var box := Rect2(340, 620, 600, 48)
	draw_rect(box, Color(0.05, 0.08, 0.1, 0.92))
	var note := str(game.save_note)
	if note.begins_with("TAD "):
		_pg_center(note, 632.0, 16, Color(0.95, 0.78, 0.28))
	else:
		_text_centered(note, 650.0, 22, KickConstants.COLOR_ATTEMPT)


func _draw_records() -> void:
	draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0.04, 0.07, 0.1, 0.96))
	_text(Vector2(48, 42), "Trophy Room", 32, KickConstants.COLOR_ATTEMPT)
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


static func shop_shelf_frames() -> Array:
	return [Rect2(344, 488, 132, 132), Rect2(572, 488, 128, 132), Rect2(796, 488, 128, 132)]


static func shop_price_plate(frame: Rect2) -> Rect2:
	return Rect2(frame.position.x + frame.size.x * 0.5 - 107.0, 604.0, 214.0, 74.0)


static func shop_info_rect() -> Rect2:
	return Rect2(132, 250, 190, 210)


static func shop_belt_rect(index: int) -> Rect2:
	var info := shop_info_rect()
	return Rect2(info.position + Vector2(12, 74 + float(index) * 58), Vector2(166, 50))


static func shop_b12_rect() -> Rect2:
	return Rect2(980, 250, 250, 150)


func shop_reroll_rect(run: RunLogic) -> Rect2:
	var text := "Reroll (%s): $%d" % [Settings.key_sentence("shop_reroll"), run.shop_reroll_cost()]
	var font := ThemeDB.fallback_font
	var width := 180.0
	var height := 16.0
	if font != null:
		var measured := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		width = measured.x
		height = maxf(measured.y, 16.0)
	return Rect2(36.0, 64.0 - height, width, height)


func shop_hit(point: Vector2) -> String:
	var frames: Array = shop_shelf_frames()
	for i in frames.size():
		var frame: Rect2 = frames[i]
		if frame.has_point(point) or shop_price_plate(frame).has_point(point):
			return "shelf%d" % i
	if shop_b12_rect().has_point(point):
		return "b12"
	for i in 2:
		if shop_belt_rect(i).has_point(point):
			return "belt%d" % i
	if game != null and game.run != null and shop_reroll_rect(game.run).has_point(point):
		return "reroll"
	return ""


func _draw_shop(run: RunLogic) -> void:
	var backdrop := _icon("res://art/shop/vitamin_shop.png")
	if backdrop != null:
		draw_texture_rect(backdrop, Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), false)
	else:
		draw_rect(Rect2(0, 0, KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT), Color(0.12, 0.08, 0.05))
	_text(Vector2(36, 32), "Vitamin Shop", 28, Color(1.0, 0.95, 0.8))
	var info := shop_info_rect()
	draw_rect(info, Color(0.05, 0.04, 0.03, 0.82))
	_text(info.position + Vector2(12, 28), "$%d" % run.cash, 22, KickConstants.COLOR_ATTEMPT)
	if run.cash_popup != "":
		_text(info.position + Vector2(90, 28), run.cash_popup, 18, Color(1.0, 0.92, 0.4))
	_text(info.position + Vector2(12, 58), run.next_boss_line(), 14, KickConstants.COLOR_TEXT)
	for i in 2:
		var id := str(run.belt[i]) if i < run.belt.size() else ""
		var label := "Z" if i == 0 else "X"
		var slot := shop_belt_rect(i)
		_draw_bottle(id, slot, id == "")
		var belt_locked := id == Vitamins.ELECTROLYTE and run.electrolyte_blocked()
		if belt_locked:
			draw_rect(slot, Color(0.08, 0.08, 0.08, 0.55))
		_text(slot.position + Vector2(4, 16), label, 12, KickConstants.COLOR_TEXT)
		if id != "":
			var name_color := Color(0.7, 0.7, 0.7) if belt_locked else KickConstants.COLOR_TEXT
			_text(slot.position + Vector2(42, 16), Vitamins.piece_name(id), 11, name_color)
			_text(slot.position + Vector2(42, 34), run.vitamin_line(id), 10, name_color)
	var frames: Array = shop_shelf_frames()
	for i in 3:
		var id := str(run.shop_stock[i]) if i < run.shop_stock.size() else ""
		var frame: Rect2 = frames[i]
		if id == "":
			_text(frame.position + Vector2(28, 78), "SOLD", 22, Color(0.85, 0.85, 0.88))
		else:
			var shelf_blocked := id == Vitamins.ELECTROLYTE and run.electrolyte_blocked()
			_draw_bottle(id, frame.grow(-18), false)
			if shelf_blocked:
				draw_rect(frame, Color(0.08, 0.08, 0.08, 0.72))
			var plate := shop_price_plate(frame)
			draw_rect(plate, Color(0.08, 0.08, 0.08, 0.9) if shelf_blocked else Color(0.05, 0.04, 0.03, 0.88))
			var price_color := Color(0.7, 0.7, 0.7) if shelf_blocked else (Color(1.0, 0.3, 0.25) if run.shop_flash == str(i) else KickConstants.COLOR_ATTEMPT)
			_text(plate.position + Vector2(8, 16), "%d  $%d  %s" % [i + 1, run.item_price(id), Vitamins.piece_name(id)], 12, price_color)
			_draw_wrapped(run.vitamin_line(id), Rect2(plate.position + Vector2(8, 30), Vector2(plate.size.x - 16, 40)), 10)
			if shelf_blocked:
				_text(Vector2(plate.position.x + 8, plate.position.y + plate.size.y + 4), "Sudden Death", 16, Color(0.8, 0.8, 0.8))
	var b12 := shop_b12_rect()
	var grey := run.b12_grey()
	draw_rect(b12, Color(0.08, 0.08, 0.08, 0.9) if grey else Color(0.16, 0.12, 0.05, 0.92))
	draw_rect(b12, Color(0.45, 0.45, 0.45) if grey else Color(0.95, 0.82, 0.28), false, 3.0)
	var b12_price := Color(1.0, 0.3, 0.25) if run.shop_flash == "b12" else (Color(0.7, 0.7, 0.7) if grey else KickConstants.COLOR_ATTEMPT)
	_text(b12.position + Vector2(16, 32), "%s  B12 Shot" % Settings.key_sentence("buy_b12"), 20, Color(0.75, 0.75, 0.75) if grey else KickConstants.COLOR_TEXT)
	_text(b12.position + Vector2(16, 64), "$%d" % run.item_price(Vitamins.B12), 20, b12_price)
	_text(b12.position + Vector2(16, 96), run.vitamin_line(Vitamins.B12), 16, KickConstants.COLOR_TEXT)
	_draw_bottle(Vitamins.B12, Rect2(b12.position + Vector2(158, 16), Vector2(78, 118)), false)
	var b12_reason := run.b12_reason()
	if b12_reason != "":
		_text(b12.position + Vector2(16, 126), b12_reason, 16, Color(0.8, 0.8, 0.8))
	var reroll_color := Color(1.0, 0.3, 0.25) if run.shop_flash == "reroll" else KickConstants.COLOR_TEXT
	var reroll_at := shop_reroll_rect(run)
	_text(Vector2(reroll_at.position.x, reroll_at.position.y + reroll_at.size.y), "Reroll (%s): $%d" % [Settings.key_sentence("shop_reroll"), run.shop_reroll_cost()], 16, reroll_color)
	if run.shop_note != "":
		_text(Vector2(36, 92), run.shop_note, 18, Color(1.0, 0.45, 0.35))
	_text_centered("%s/%s/%s buy  %s B12  %s/%s sell  %s reroll  %s leave" % [
		Settings.key_sentence("choose_1"), Settings.key_sentence("choose_2"), Settings.key_sentence("choose_3"),
		Settings.key_sentence("buy_b12"), Settings.key_sentence("belt_z"), Settings.key_sentence("belt_x"),
		Settings.key_sentence("shop_reroll"), Settings.key_sentence("confirm"),
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
		names = ["main_menu_endless_unlocked.png", "endless_unlocked.png"]
	var path := MenuLayout.find_texture_path(names)
	if path == "":
		_menu_textures[which] = null
		return null
	var loaded := load(path) as Texture2D
	if which == "endless" and loaded != null and loaded.get_size() != MenuLayout.IMAGE_SIZE:
		if not _menu_textures.has("endless_size_warned"):
			print("E3 unlocked menu painting is %s, expected %s. Keeping the metal cover." % [loaded.get_size(), MenuLayout.IMAGE_SIZE])
			_menu_textures["endless_size_warned"] = true
		_menu_textures[which] = null
		return null
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
	var cam_box := MenuLayout.screen_rect(MenuLayout.BALL_CAM, window, image)
	draw_rect(cam_box, panel)
	var cam_label := "BALL CAM ON" if Settings.ball_cam else "BALL CAM OFF"
	var cam_size := 16
	while cam_size > 10 and BitmapFonts.measure_px("ui", cam_label, cam_size) > int(cam_box.size.x) - 12:
		cam_size -= 1
	var cam_w := BitmapFonts.measure_px("ui", cam_label, cam_size)
	BitmapFonts.paint_px(self, "ui", cam_label, Vector2(cam_box.position.x + (cam_box.size.x - float(cam_w)) * 0.5, cam_box.position.y + (cam_box.size.y - float(cam_size)) * 0.5), cam_size, Color(0.95, 0.92, 0.84))
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


func _draw_cam_dip() -> void:
	if game == null:
		return
	var alpha := float(game.cam_dip_alpha())
	if alpha <= 0.001:
		return
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, alpha))


func _focus_pixel_rect(front: FrontEnd) -> Rect2:
	var index := front.focus
	if index < 3:
		return MenuLayout.SLIDERS[index]
	if index == 3:
		return MenuLayout.BALL_CAM
	if index < 4 + Settings.ACTION_ROWS.size():
		var row: Dictionary = Settings.ACTION_ROWS[index - 4]
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
