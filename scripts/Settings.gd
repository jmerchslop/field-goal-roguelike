class_name GameSettings
extends Node

# Volumes and keybinds. This file is user://settings.cfg, never save.cfg.
# F9 resets records only. It does not call into here.

const FILE_PATH_DEFAULT := "user://settings.cfg"

const RESERVED_KEYS: Array[int] = [KEY_C, KEY_W, KEY_F9]

# id, on-screen name, default key, shown in Options.
const ACTION_ROWS: Array[Dictionary] = [
	{"id": "confirm", "name": "CONFIRM / KICK", "key": KEY_SPACE, "column": 0, "row": 0},
	{"id": "aim_left", "name": "AIM LEFT", "key": KEY_LEFT, "column": 0, "row": 1},
	{"id": "aim_right", "name": "AIM RIGHT", "key": KEY_RIGHT, "column": 0, "row": 2},
	{"id": "menu_up", "name": "MENU UP", "key": KEY_UP, "column": 0, "row": 3},
	{"id": "menu_down", "name": "MENU DOWN", "key": KEY_DOWN, "column": 0, "row": 4},
	{"id": "back", "name": "BACK / CANCEL", "key": KEY_ESCAPE, "column": 0, "row": 5},
	{"id": "choose_1", "name": "CHOOSE 1", "key": KEY_1, "column": 0, "row": 6},
	{"id": "choose_2", "name": "CHOOSE 2", "key": KEY_2, "column": 0, "row": 7},
	{"id": "choose_3", "name": "CHOOSE 3", "key": KEY_3, "column": 0, "row": 8},
	{"id": "buy_b12", "name": "BUY B12", "key": KEY_4, "column": 1, "row": 0},
	{"id": "skip", "name": "SKIP", "key": KEY_S, "column": 1, "row": 1},
	{"id": "belt_z", "name": "BELT Z", "key": KEY_Z, "column": 1, "row": 2},
	{"id": "belt_x", "name": "BELT X", "key": KEY_X, "column": 1, "row": 3},
	{"id": "shop_reroll", "name": "SHOP REROLL", "key": KEY_F, "column": 1, "row": 4},
	{"id": "offer_reroll", "name": "OFFER REROLL", "key": KEY_R, "column": 1, "row": 5},
	{"id": "practice", "name": "PRACTICE SWING", "key": KEY_P, "column": 1, "row": 6},
	{"id": "trophy", "name": "TROPHY ROOM", "key": KEY_T, "column": 1, "row": 7},
]

var file_path := FILE_PATH_DEFAULT
var music := 100
var crowd := 100
var sfx := 100
var binds: Dictionary = {}


func _ready() -> void:
	_ensure_buses()
	_fill_default_binds()
	load_file()
	apply_all()


func _fill_default_binds() -> void:
	binds.clear()
	for row in ACTION_ROWS:
		binds[str(row["id"])] = int(row["key"])
	# Horizontal menu movement shares Left / Right with aim. Not listed in Options.
	binds["menu_left"] = KEY_LEFT
	binds["menu_right"] = KEY_RIGHT


func defaults_match_table() -> bool:
	for row in ACTION_ROWS:
		if int(binds.get(str(row["id"]), -1)) != int(row["key"]):
			return false
	return true


func load_file() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(file_path) != OK:
		save_file()
		return
	music = _clamp_volume(cfg.get_value("audio", "music", 100))
	crowd = _clamp_volume(cfg.get_value("audio", "crowd", 100))
	sfx = _clamp_volume(cfg.get_value("audio", "sfx", 100))
	for row in ACTION_ROWS:
		var id := str(row["id"])
		binds[id] = int(cfg.get_value("input", id, int(row["key"])))
	binds["menu_left"] = int(cfg.get_value("input", "menu_left", KEY_LEFT))
	binds["menu_right"] = int(cfg.get_value("input", "menu_right", KEY_RIGHT))


func save_file() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "crowd", crowd)
	cfg.set_value("audio", "sfx", sfx)
	for id in binds.keys():
		cfg.set_value("input", str(id), int(binds[id]))
	cfg.save(file_path)


func apply_all() -> void:
	_ensure_buses()
	apply_volumes()
	apply_binds()


func set_volume(which: String, value: int, persist: bool = true) -> void:
	var clamped := _clamp_volume(value)
	if which == "music":
		music = clamped
	elif which == "crowd":
		crowd = clamped
	else:
		sfx = clamped
	apply_volumes()
	if persist:
		save_file()


func volume_of(which: String) -> int:
	if which == "music":
		return music
	if which == "crowd":
		return crowd
	return sfx


static func volume_db(value: int) -> float:
	if value <= 0:
		return -80.0
	return linear_to_db(clampf(float(value) / 100.0, 0.001, 1.0))


func apply_volumes() -> void:
	_ensure_buses()
	_set_bus("Music", music)
	_set_bus("Crowd", crowd)
	_set_bus("SFX", sfx)


func _set_bus(bus_name: String, value: int) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	if value <= 0:
		AudioServer.set_bus_mute(index, true)
		AudioServer.set_bus_volume_db(index, -80.0)
		return
	AudioServer.set_bus_mute(index, false)
	AudioServer.set_bus_volume_db(index, volume_db(value))


func bus_is_muted(bus_name: String) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return false
	return AudioServer.is_bus_mute(index)


func bus_volume_db(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return 0.0
	return AudioServer.get_bus_volume_db(index)


func apply_binds() -> void:
	for id in binds.keys():
		var action := str(id)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		else:
			InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.keycode = int(binds[action]) as Key
		InputMap.action_add_event(action, event)


func try_rebind(action_id: String, code: int) -> String:
	if RESERVED_KEYS.has(code):
		return "reserved"
	for id in binds.keys():
		if str(id) == action_id:
			continue
		# Aim and the hidden menu arrows may share Left / Right.
		if _share_ok(action_id, str(id)):
			continue
		if int(binds[id]) == code:
			return "used"
	if not binds.has(action_id):
		return "missing"
	binds[action_id] = code
	apply_binds()
	save_file()
	return "ok"


func _share_ok(left_id: String, right_id: String) -> bool:
	return (left_id == "aim_left" and right_id == "menu_left") or (left_id == "menu_left" and right_id == "aim_left") or (left_id == "aim_right" and right_id == "menu_right") or (left_id == "menu_right" and right_id == "aim_right")


func reset_controls() -> void:
	_fill_default_binds()
	apply_binds()
	save_file()


func key_label(action_id: String) -> String:
	return key_name(int(binds.get(action_id, 0)))


static func key_name(code: int) -> String:
	match code:
		KEY_SPACE:
			return "SPACE"
		KEY_ESCAPE:
			return "ESC"
		KEY_LEFT:
			return "LEFT"
		KEY_RIGHT:
			return "RIGHT"
		KEY_UP:
			return "UP"
		KEY_DOWN:
			return "DOWN"
		KEY_ENTER:
			return "ENTER"
		KEY_TAB:
			return "TAB"
	var text := OS.get_keycode_string(code as Key)
	if text == "":
		return "?"
	return text.to_upper()


func pressed_event(event: InputEvent, action_id: String) -> bool:
	if not event is InputEventKey:
		return false
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return false
	return key.is_action_pressed(action_id)


func held(action_id: String) -> bool:
	return Input.is_action_pressed(action_id)


func play_preview(which: String) -> void:
	var bus := "SFX"
	var freq := 880.0
	var duration := 0.07
	var gain := 0.35
	if which == "music":
		bus = "Music"
		freq = 440.0
		duration = 0.32
		gain = 0.18
	elif which == "crowd":
		bus = "Crowd"
		freq = 330.0
		duration = 0.18
		gain = 0.28
	_play_tone(bus, freq, duration, gain)


func _play_tone(bus_name: String, freq: float, duration: float, gain: float) -> void:
	var rate := 22050
	var count := maxi(int(float(rate) * duration), 1)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / float(rate)
		var env := 1.0 - t / duration
		var sample := sin(TAU * freq * t) * env * gain
		var value := int(clampf(sample * 32767.0, -32767.0, 32767.0))
		data[i * 2] = value & 255
		data[i * 2 + 1] = (value >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _ensure_buses() -> void:
	for bus_name in ["Music", "Crowd", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


func _clamp_volume(value) -> int:
	return clampi(int(value), 0, 100)
