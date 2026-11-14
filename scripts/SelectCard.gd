class_name SelectCard
extends RefCounted

# Playing Card select copy. Pixel Gothic can draw A–Z, 0–9, +, and the period.
# Names, kit lines, and locked corners stay inside that set.

const FRAME_PATH := "res://art/ui/playing-card.png"
const LOCKED_MARK := ".."
const VEX_MARK := "MAX"

# Portrait window and the two type bands, in the 96×134 art grid.
const WIN_X := 12.0 / 96.0
const WIN_Y := 12.0 / 134.0
const WIN_W := 72.0 / 96.0
const WIN_H := 78.0 / 134.0
const BAND_Y := 93.0 / 134.0
const BAND_H := 15.0 / 134.0
const WELL_Y := 109.0 / 134.0
const WELL_H := 15.0 / 134.0


static func order() -> PackedStringArray:
	var ids := PackedStringArray()
	for item in Kickers.ALL:
		ids.append(str(item["id"]))
	return ids


static func card_name(id: String) -> String:
	return BroadcastHud.plate_name(id)


static func kit_lines(id: String) -> PackedStringArray:
	if id == Kickers.PHIL:
		return PackedStringArray(["HOUSE ACCOUNT", "COMPOUNDING"])
	if id == Kickers.VEX:
		return PackedStringArray(["INFINITE RANGE"])
	var line := BroadcastHud.kit_text(id)
	if line == "":
		return PackedStringArray()
	return PackedStringArray([line])


static func ball_line(id: String) -> String:
	return BroadcastHud.ball_text(id)


static func unlock_line(id: String) -> String:
	match id:
		Kickers.PHIL:
			return "BUY SOMETHING FROM THE VITAMIN SHOP"
		Kickers.GARY:
			return "BEAT STANDARD WITHOUT A MISS"
		Kickers.VEX:
			return "FAIL AN ENDLESS RUN PAST 75 YARDS"
		Kickers.COLE:
			return "BEAT STANDARD"
		Kickers.WILLOW:
			return "MAKE A KICK WITH 1 ATTEMPT LEFT ON KICK 5 OR LATER"
		Kickers.CARLOS:
			return "MAKE A 100 YARD FIELD GOAL"
		_:
			return ""


static func yard_cap(id: String) -> int:
	# No-item distance at a 100% lock. Vex has no cap, so this stays negative.
	var stats := KickerStats.new()
	Kickers.apply_to(stats, id)
	if id == Kickers.VEX or stats.clearance:
		return -1
	return int(round(stats.range_base + stats.range_per_power * 100.0))


static func corner_text(id: String, unlocked: bool) -> String:
	if not unlocked:
		return LOCKED_MARK
	var cap := yard_cap(id)
	if cap < 0:
		return VEX_MARK
	return str(cap)


static func glyph_safe(text: String) -> bool:
	return BitmapFonts.ui_allows(text)


static func every_line() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("CHOOSE YOUR KICKER")
	lines.append("1 TO 8 HIGHLIGHT. SPACE OR CLICK AGAIN TO START.")
	for id in order():
		lines.append(card_name(id))
		for kit in kit_lines(id):
			lines.append(kit)
		lines.append(ball_line(id))
		lines.append(unlock_line(id))
		lines.append(corner_text(id, true))
		lines.append(corner_text(id, false))
		lines.append("LOCKED")
	return lines


static func grid_rects() -> Array:
	var gap := 16.0
	var top := 46.0
	var bottom := 686.0
	var avail_h := bottom - top
	var card_h := floorf((avail_h - gap) / 2.0)
	var card_w := floorf(card_h * 5.0 / 7.0)
	var total_w := card_w * 4.0 + gap * 3.0
	var left := floorf((KickConstants.WINDOW_WIDTH - total_w) / 2.0)
	var rects: Array = []
	for i in 8:
		var col := i % 4
		var row := int(i / 4)
		rects.append(Rect2(left + float(col) * (card_w + gap), top + float(row) * (card_h + gap), card_w, card_h))
	return rects


static func step_highlight(index: int, dx: int, dy: int) -> int:
	var slot := index
	if slot < 0 or slot > 7:
		slot = 1
	var col := posmod(slot % 4 + dx, 4)
	var row := posmod(int(slot / 4) + dy, 2)
	return row * 4 + col
