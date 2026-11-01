extends Node2D

# Draws the field and reads the keyboard.
# The kick rules live in KickLogic.gd. This file only shows them.

const ScreenshotDriverScript := preload("res://scripts/ScreenshotDriver.gd")

var logic := KickLogic.new()
var _taking_pictures := false


func _ready() -> void:
	# How far this kick is. A later version can change this one line.
	logic.kick_distance = KickConstants.KICK_DISTANCE_YARDS
	queue_redraw()
	if OS.get_environment("FG_SHOTS") != "1":
		return
	_taking_pictures = true
	var driver := ScreenshotDriverScript.new()
	driver.board = self
	driver.logic = logic
	var dir := OS.get_environment("FG_SHOT_DIR")
	if dir != "":
		driver.shot_dir = dir
	driver.name = "ScreenshotDriver"
	add_child(driver)


func _process(delta: float) -> void:
	if _taking_pictures:
		return
	var direction := 0.0
	if Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0
	if direction != 0.0:
		logic.aim(direction, delta)
	logic.advance(delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _taking_pictures:
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and key.keycode == KEY_SPACE:
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
	if logic.phase == KickLogic.Phase.RESULT:
		_draw_result()


func _draw_field() -> void:
	var size := Vector2(KickConstants.WINDOW_WIDTH, KickConstants.WINDOW_HEIGHT)
	draw_rect(Rect2(Vector2.ZERO, size), KickConstants.COLOR_FIELD)
	# Darker grass behind the goal line.
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
	var tee := KickConstants.screen_pos(logic.kick_distance, 0.0, 0.0)
	var aim := deg_to_rad(logic.aim_degrees)
	# Negative aim points left. Zero points straight up at the posts.
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
	# The shadow stays on the ground. The ball lifts off it and grows to 2x at mid-flight.
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
	_text(
		Vector2(24.0, 34.0),
		"Aim %s°    negative is left" % KickLogic.format_angle(logic.aim_degrees),
		20,
		KickConstants.COLOR_TEXT
	)
	if logic.ball_forward_yards < 0.05:
		var tee := KickConstants.screen_pos(logic.kick_distance, 0.0, 0.0)
		_text(tee + Vector2(20.0, 40.0), "%s yd" % KickLogic.format_number(logic.kick_distance), 18, KickConstants.COLOR_TEXT)
	var hint := ""
	if logic.phase == KickLogic.Phase.AIMING:
		hint = "Hold Left or Right to aim.   Space starts the meter."
	elif logic.phase == KickLogic.Phase.POWER:
		hint = "Space locks power."
	elif logic.phase == KickLogic.Phase.ACCURACY:
		hint = "Space locks accuracy."
	elif logic.phase == KickLogic.Phase.RESULT:
		hint = "Space kicks again."
	if hint != "":
		_text_centered(hint, 700.0, 20, KickConstants.COLOR_TEXT)


func _draw_result() -> void:
	var box := Rect2(KickConstants.RESULT_LEFT, KickConstants.RESULT_TOP, KickConstants.RESULT_WIDTH, KickConstants.RESULT_HEIGHT)
	draw_rect(box, KickConstants.COLOR_RESULT_SCRIM)
	var word_color := KickConstants.COLOR_MISS
	if logic.result_text == "GOOD":
		word_color = KickConstants.COLOR_GOOD
	if logic.perfect:
		_text_centered("PERFECT!", box.position.y + 58.0, 36, KickConstants.COLOR_PERFECT_TEXT)
		_text_centered(logic.result_text, box.position.y + 128.0, 68, word_color)
	else:
		_text_centered(logic.result_text, box.position.y + 100.0, 68, word_color)
	_text_centered(logic.detail_line(), box.position.y + 176.0, 28, KickConstants.COLOR_TEXT)


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
	# Center in the field, leaving the meter alone on the right.
	var field_width := KickConstants.METER_PANEL_LEFT
	var x := (field_width - width) * 0.5
	_text(Vector2(x, baseline_y), text, size, color)
