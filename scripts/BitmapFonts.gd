class_name BitmapFonts
extends RefCounted

# Stadium Block and Pixel Gothic, sliced from the alphabet sheets.
# Nearest-neighbor only. The sheets' painted pixels are the glyphs.

static var _callout: FontFile
static var _ui: FontFile
static var callout_px := 0
static var ui_px := 0
static var _textures := {}
static var _glyphs := {}
static var _space := {}


static func callout_font() -> FontFile:
	if _callout == null:
		_callout = _load_font("res://fonts/stadium_block.png", "callout")
	return _callout


static func ui_font() -> FontFile:
	if _ui == null:
		_ui = _load_font("res://fonts/pixel_gothic.png", "ui")
	return _ui


static func _load_font(png_path: String, key: String) -> FontFile:
	var texture := load(png_path) as Texture2D
	var image := texture.get_image()
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://fonts/glyphs.json"))
	var block: Dictionary = spec[key]
	var height := int(block["height"])
	if key == "callout":
		callout_px = height
	else:
		ui_px = height
	var font := FontFile.new()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.generate_mipmaps = false
	font.oversampling = 1.0
	var px := Vector2i(height, 0)
	font.set_texture_image(0, px, 0, image)
	font.set_cache_ascent(0, height, float(height))
	font.set_cache_descent(0, height, 0.0)
	_textures[key] = texture
	_space[key] = float(block["space"])
	var stored := {}
	var glyphs: Dictionary = block["glyphs"]
	for ch in glyphs.keys():
		var box: Dictionary = glyphs[ch]
		stored[String(ch)] = Rect2(float(box["x"]), float(box["y"]), float(box["w"]), float(box["h"]))
	_glyphs[key] = stored
	for ch in glyphs.keys():
		var g: Dictionary = glyphs[ch]
		var code := String(ch).unicode_at(0)
		var rect := Rect2(float(g["x"]), float(g["y"]), float(g["w"]), float(g["h"]))
		font.set_glyph_texture_idx(0, px, code, 0)
		font.set_glyph_uv_rect(0, px, code, rect)
		font.set_glyph_size(0, px, code, rect.size)
		font.set_glyph_offset(0, px, code, Vector2(0, -rect.size.y))
		font.set_glyph_advance(0, height, code, Vector2(rect.size.x + 2.0, 0))
	var space := float(block["space"])
	font.set_glyph_texture_idx(0, px, 32, 0)
	font.set_glyph_uv_rect(0, px, 32, Rect2(0, 0, 0, 0))
	font.set_glyph_size(0, px, 32, Vector2(space, 1))
	font.set_glyph_offset(0, px, 32, Vector2(0, -1))
	font.set_glyph_advance(0, height, 32, Vector2(space, 0))
	return font


static func line_width(key: String, text: String, scale: int) -> int:
	_ensure(key)
	var width := 0
	var glyphs: Dictionary = _glyphs[key]
	var gap := 0
	for i in text.length():
		var ch := text.substr(i, 1)
		if ch == " ":
			width += int(_space[key]) * scale
		elif glyphs.has(ch):
			var rect: Rect2 = glyphs[ch]
			width += int(rect.size.x) * scale + gap
	if width > 0:
		width -= gap
	return width


static func line_height(key: String, scale: int) -> int:
	_ensure(key)
	return (callout_px if key == "callout" else ui_px) * scale


static func paint(canvas: CanvasItem, key: String, text: String, top_left: Vector2, scale: int, color: Color) -> void:
	_ensure(key)
	var texture: Texture2D = _textures[key]
	var glyphs: Dictionary = _glyphs[key]
	var em := line_height(key, scale)
	var x := int(round(top_left.x))
	var gap := 0
	for i in text.length():
		var ch := text.substr(i, 1)
		if ch == " ":
			x += int(_space[key]) * scale
			continue
		if not glyphs.has(ch):
			continue
		var src: Rect2 = glyphs[ch]
		var dest_h := int(src.size.y) * scale
		var dest_w := int(src.size.x) * scale
		var dest := Rect2(x, int(round(top_left.y)) + (em - dest_h), dest_w, dest_h)
		canvas.draw_texture_rect_region(texture, dest, src, color)
		x += dest_w + gap


static func _ensure(key: String) -> void:
	if key == "callout":
		callout_font()
	else:
		ui_font()
