class_name MenuLayout
extends RefCounted

# Hitboxes live in the painting's own pixel space (the art is 1280x720).
# Cover-scale maps those pixels onto any window without stretching.

const IMAGE_SIZE := Vector2(1280, 720)

const PRESS_START := Rect2(480, 628, 320, 72)

const TILES: Array[Rect2] = [
	Rect2(54, 491, 277, 188),
	Rect2(354, 491, 272, 188),
	Rect2(651, 491, 275, 188),
	Rect2(949, 491, 274, 188),
]

const SLIDERS: Array[Rect2] = [
	Rect2(78, 252, 354, 28),
	Rect2(78, 364, 354, 28),
	Rect2(78, 476, 354, 28),
]

const SLIDER_NUMBERS: Array[Rect2] = [
	Rect2(368, 208, 62, 32),
	Rect2(368, 320, 62, 32),
	Rect2(368, 432, 62, 32),
]

const RESET_BUTTON := Rect2(330, 590, 300, 56)
const BACK_BUTTON := Rect2(650, 590, 300, 56)

const BIND_LEFT := Rect2(500, 186, 352, 28)
const BIND_RIGHT := Rect2(868, 186, 340, 28)
const BIND_STEP := 40.0
const BIND_LEFT_COUNT := 9
const BIND_RIGHT_COUNT := 8


static func cover_rect(window: Vector2, image: Vector2 = IMAGE_SIZE) -> Rect2:
	if image.x <= 1.0 or image.y <= 1.0 or window.x <= 1.0 or window.y <= 1.0:
		return Rect2(Vector2.ZERO, window)
	var scale := maxf(window.x / image.x, window.y / image.y)
	var drawn := image * scale
	return Rect2((window - drawn) * 0.5, drawn)


static func norm_of(pixel_rect: Rect2, image: Vector2 = IMAGE_SIZE) -> Rect2:
	return Rect2(pixel_rect.position / image, pixel_rect.size / image)


static func screen_rect(pixel_rect: Rect2, window: Vector2, image: Vector2 = IMAGE_SIZE) -> Rect2:
	var norm := norm_of(pixel_rect, image)
	var cover := cover_rect(window, image)
	return Rect2(
		cover.position + Vector2(norm.position.x * cover.size.x, norm.position.y * cover.size.y),
		Vector2(norm.size.x * cover.size.x, norm.size.y * cover.size.y)
	)


static func screen_to_norm(point: Vector2, window: Vector2, image: Vector2 = IMAGE_SIZE) -> Vector2:
	var cover := cover_rect(window, image)
	if cover.size.x <= 1.0 or cover.size.y <= 1.0:
		return Vector2.ZERO
	return (point - cover.position) / cover.size


static func contains_norm(pixel_rect: Rect2, point_norm: Vector2, image: Vector2 = IMAGE_SIZE) -> bool:
	return norm_of(pixel_rect, image).has_point(point_norm)


static func tile_at(point: Vector2, window: Vector2, image: Vector2 = IMAGE_SIZE) -> int:
	var norm := screen_to_norm(point, window, image)
	for index in TILES.size():
		if contains_norm(TILES[index], norm, image):
			return index
	return -1


static func press_start_hit(point: Vector2, window: Vector2, image: Vector2 = IMAGE_SIZE) -> bool:
	return contains_norm(PRESS_START, screen_to_norm(point, window, image), image)


static func bind_rect(column: int, row: int) -> Rect2:
	var base := BIND_LEFT if column == 0 else BIND_RIGHT
	return Rect2(base.position + Vector2(0, BIND_STEP * float(row)), base.size)


static func key_plate(row_rect: Rect2) -> Rect2:
	return Rect2(row_rect.position.x + row_rect.size.x - 86.0, row_rect.position.y + 2.0, 78.0, row_rect.size.y - 4.0)


static func slider_fill(index: int, value: float) -> Rect2:
	var track := SLIDERS[index]
	var handle_w := 26.0
	var travel := maxf(track.size.x - handle_w, 1.0)
	var left := track.position.x
	var width := travel * clampf(value / 100.0, 0.0, 1.0)
	return Rect2(left, track.position.y + 6.0, maxf(width, 0.0), track.size.y - 12.0)


static func slider_handle(index: int, value: float) -> Rect2:
	var track := SLIDERS[index]
	var handle_w := 26.0
	var travel := maxf(track.size.x - handle_w, 1.0)
	var x := track.position.x + travel * clampf(value / 100.0, 0.0, 1.0)
	return Rect2(x, track.position.y + 1.0, handle_w, track.size.y - 2.0)


static func slider_value_at(index: int, point_norm: Vector2, image: Vector2 = IMAGE_SIZE) -> int:
	var track := SLIDERS[index]
	var local := point_norm.x * image.x - track.position.x
	var t := clampf(local / maxf(track.size.x, 1.0), 0.0, 1.0)
	return int(round(t * 100.0))


static func find_texture_path(accepted: Array) -> String:
	var wanted := {}
	for name in accepted:
		wanted[str(name).to_lower()] = true
	return _walk_for(wanted, "res://")


static func _walk_for(wanted: Dictionary, root: String) -> String:
	var dir := DirAccess.open(root)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var path := root.path_join(entry)
		if dir.current_is_dir():
			if entry != "addons":
				var nested := _walk_for(wanted, path)
				if nested != "":
					dir.list_dir_end()
					return nested
		else:
			var base := entry.get_basename().to_lower().replace("-", "_").replace(" ", "_")
			var file_name := entry.to_lower().replace("-", "_").replace(" ", "_")
			if wanted.has(base) or wanted.has(file_name) or wanted.has(base + ".png"):
				if not entry.ends_with(".import"):
					dir.list_dir_end()
					return path
		entry = dir.get_next()
	dir.list_dir_end()
	return ""
