class_name SelectCard
extends RefCounted

# Playing Card select copy. Pixel Gothic can draw A–Z, 0–9, +, and the period.
# Names, kit lines, and locked corners stay inside that set.

const FRAME_PATH := "res://art/ui/playing-card.png"
const LOCKED_MARK := ".."

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
		return PackedStringArray(["OUT OF THIS", "WORLD RANGE"])
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
			return "MAKE A 500 YARD FIELD GOAL IN ENDLESS"
		Kickers.COLE:
			return "BEAT STANDARD"
		Kickers.WILLOW:
			return "MAKE A KICK WITH 1 ATTEMPT LEFT ON KICK 8 OR LATER"
		Kickers.CARLOS:
			return "MAKE A 100 YARD FIELD GOAL"
		_:
			return ""


static func yard_cap(id: String) -> int:
	# No-item distance at a 100% lock.
	var stats := KickerStats.new()
	Kickers.apply_to(stats, id)
	return int(round(stats.range_base + stats.range_per_power * 100.0))


static func corner_text(id: String, unlocked: bool) -> String:
	if not unlocked:
		return LOCKED_MARK
	return str(yard_cap(id))


# One crisp step down when a three-digit corner does not fit the index pocket.
static func corner_px(card: Rect2, text: String) -> int:
	var px := maxi(9, int(card.size.y * 0.048))
	var pocket := int(card.size.x * 0.22)
	if BitmapFonts.measure_px("ui", text, px) > pocket:
		px = maxi(8, px - 1)
	return px


static func glyph_safe(text: String) -> bool:
	return BitmapFonts.ui_allows(text)


static func every_line() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("CHOOSE YOUR KICKER")
	lines.append("1 TO 8 HIGHLIGHT. SPACE OR CLICK AGAIN TO START.")
	lines.append("1 TO 8 HIGHLIGHT. SPACE OR CLICK TO PICK TAD. CLICK AGAIN TO START.")
	lines.append("BRACKETS CHANGE TAD. SPACE OR CLICK AGAIN TO START. ESC BACKS OUT.")
	lines.append("TWO A DAYS")
	lines.append("ALL BELOW ALSO APPLY")
	for level in range(0, RunLogic.TAD_MAX + 1):
		lines.append("TAD %d" % level)
		lines.append(RunLogic.tad_summary(level))
	lines.append("TAD 1 UNLOCKED")
	lines.append("OFF AT TAD 5+")
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


# Compact TAD picker in the top-right steel, above the portrait window.
# The badge is sized for "TAD 10" so the chevrons do not jump while cycling.
static func picker_layout(card: Rect2) -> Dictionary:
	var face_top := card.position.y + card.size.y * WIN_Y
	var top := card.position.y + maxf(2.0, card.size.y * 0.01)
	var height := minf(15.0, face_top - top - 4.0)
	var font := 11
	var sample := "TAD 10"
	var text_w := BitmapFonts.measure_px("ui", sample, font)
	var max_badge := card.size.x * 0.30
	while font > 8 and float(text_w) + 6.0 > max_badge:
		font -= 1
		text_w = BitmapFonts.measure_px("ui", sample, font)
	var badge_w := float(text_w) + 6.0
	var chev := height
	var gap := 2.0
	var right := card.position.x + card.size.x - 5.0
	var total := chev + gap + badge_w + gap + chev
	var left := right - total
	var left_rect := Rect2(left, top, chev, height)
	var badge := Rect2(left + chev + gap, top, badge_w, height)
	var right_rect := Rect2(badge.position.x + badge_w + gap, top, chev, height)
	var union := Rect2(left, top, total, height)
	return {
		"left": left_rect,
		"badge": badge,
		"right": right_rect,
		"union": union,
		"font": font,
	}


static func label_boxes(card: Rect2, id: String) -> Dictionary:
	var name_size := maxi(8, int(card.size.y * 0.04))
	var band := Rect2(card.position + Vector2(card.size.x * 0.1, card.size.y * BAND_Y), Vector2(card.size.x * 0.8, card.size.y * BAND_H))
	var body := maxi(7, int(card.size.y * 0.03))
	var well := Rect2(card.position + Vector2(card.size.x * 0.08, card.size.y * WELL_Y), Vector2(card.size.x * 0.84, card.size.y * WELL_H))
	var kits := kit_lines(id)
	var ball := ball_line(id)
	if kits.size() > 1 and not _well_fits(kits, ball, well, body):
		if id == Kickers.VEX:
			body -= 1
		else:
			kits = PackedStringArray([kits[kits.size() - 1]])
	var lines := kits.duplicate()
	if ball != "":
		lines.append(ball)
	var stacked := _stack_bounds(lines, well, body)
	var kit := Rect2()
	var ball_box := Rect2()
	if stacked.size() > 0 and ball != "":
		ball_box = stacked[stacked.size() - 1]
		if stacked.size() > 1:
			kit = stacked[0]
			for i in range(1, stacked.size() - 1):
				kit = kit.merge(stacked[i])
	elif stacked.size() > 0:
		kit = stacked[0]
	var rank := corner_text(id, true)
	var rank_px := corner_px(card, rank)
	var rank_w := float(BitmapFonts.measure_px("ui", rank, rank_px))
	var rank_tl := Rect2(card.position + Vector2(card.size.x * 0.045, card.size.y * 0.012), Vector2(rank_w, float(rank_px)))
	var rank_br := Rect2(card.position + Vector2(card.size.x * 0.955 - rank_w, card.size.y * 0.905), Vector2(rank_w, float(rank_px)))
	var face := Rect2(card.position + Vector2(card.size.x * WIN_X, card.size.y * WIN_Y), Vector2(card.size.x * WIN_W, card.size.y * WIN_H))
	return {
		"name": _block_bounds(card_name(id), band, name_size),
		"kit": kit,
		"ball": ball_box,
		"rank_tl": rank_tl,
		"rank_br": rank_br,
		"face": face,
	}


static func boxes_clear(card: Rect2, id: String) -> bool:
	var picker: Rect2 = picker_layout(card)["union"]
	var labels := label_boxes(card, id)
	for key in ["name", "kit", "ball", "rank_tl", "rank_br", "face"]:
		var label: Rect2 = labels[key]
		if label.size.x > 0.5 and picker.intersects(label):
			return false
	return picker.position.y + picker.size.y <= card.position.y + card.size.y * WIN_Y - 1.0


static func _well_fits(kits: PackedStringArray, ball: String, well: Rect2, size: int) -> bool:
	var count := kits.size() + (1 if ball != "" else 0)
	if count * (size + 2) > int(well.size.y):
		return false
	var widest := BitmapFonts.measure_px("ui", ball, size)
	for line in kits:
		widest = maxi(widest, BitmapFonts.measure_px("ui", line, size))
	return widest <= int(well.size.x)


static func _wrap(text: String, max_w: int, size: int) -> PackedStringArray:
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


static func _block_bounds(text: String, area: Rect2, size: int) -> Rect2:
	var lines := _wrap(text, int(area.size.x), size)
	if lines.is_empty():
		return Rect2()
	var step := size + 1
	var block_h := lines.size() * step
	var y := area.position.y + maxf(0.0, (area.size.y - float(block_h)) * 0.5)
	var bounds := Rect2()
	for i in lines.size():
		var width := float(BitmapFonts.measure_px("ui", lines[i], size))
		var box := Rect2(area.position.x + (area.size.x - width) * 0.5, y, width, float(size))
		bounds = box if i == 0 else bounds.merge(box)
		y += float(step)
	return bounds


static func _stack_bounds(lines: PackedStringArray, area: Rect2, size: int) -> Array:
	var boxes: Array = []
	if lines.is_empty():
		return boxes
	var step := size + 2
	var block_h := lines.size() * step
	var y := area.position.y + maxf(0.0, (area.size.y - float(block_h)) * 0.5)
	for i in lines.size():
		var width := float(BitmapFonts.measure_px("ui", lines[i], size))
		boxes.append(Rect2(area.position.x + (area.size.x - width) * 0.5, y, width, float(size)))
		y += float(step)
	return boxes
