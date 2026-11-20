extends Node

# Crowd bed on the field, menu theme on the menu screens.
# A missing file is silent. It is logged once.

const CROWD_PATH := "res://audio/ambience/crowd_loop.ogg"
const MUSIC_PATH := "res://audio/music/main_menu_theme.ogg"
const FADE_SEC := 1.0

var music_player: AudioStreamPlayer
var crowd_player: AudioStreamPlayer
var music_ready := false
var crowd_ready := false
var _music_gain := 0.0
var _crowd_gain := 0.0
var _music_target := 0.0
var _crowd_target := 0.0
var _duck := 1.0
var _duck_target := 1.0
var _duck_sec := 0.40
var duck_time_scale := 1.0
var _swell_left := -1.0
var _after_swell_sec := 0.20
var _logged := {}


func _ready() -> void:
	boot()


func boot() -> void:
	if music_player != null:
		return
	music_player = _make_player("MusicBed", "Music")
	crowd_player = _make_player("CrowdBed", "Crowd")
	var music := _load_bed(MUSIC_PATH, "menu theme")
	var crowd := _load_bed(CROWD_PATH, "crowd bed")
	if music != null:
		music_player.stream = music
		music_ready = true
	if crowd != null:
		crowd_player.stream = crowd
		crowd_ready = true


func _process(delta: float) -> void:
	_follow_screen()
	_music_gain = move_toward(_music_gain, _music_target, delta / FADE_SEC)
	_crowd_gain = move_toward(_crowd_gain, _crowd_target, delta / FADE_SEC)
	tick_duck(delta)
	_apply(music_player, _music_gain, music_ready)
	_apply(crowd_player, _crowd_gain * _duck, crowd_ready)


func tick_duck(delta: float) -> void:
	var duck_delta := delta * maxf(duck_time_scale, 0.0)
	if _swell_left >= 0.0:
		_swell_left -= duck_delta
		if _swell_left <= 0.0:
			_swell_left = -1.0
			set_duck(1.0, _after_swell_sec)
	_duck = move_toward(_duck, _duck_target, duck_delta / maxf(_duck_sec, 0.001))


func set_duck(target: float, seconds: float) -> void:
	_duck_target = target
	_duck_sec = maxf(seconds, 0.001)


func duck_now() -> float:
	return _duck


func crowd_gain() -> float:
	return _crowd_gain * _duck


func bed_gain() -> float:
	return _crowd_gain


func begin_flight_duck() -> void:
	_swell_left = -1.0
	set_duck(0.25, 0.40)


func begin_result_duck(make: bool, files_ready: bool) -> void:
	_swell_left = -1.0
	if make and not files_ready:
		set_duck(1.35, 0.05)
		_swell_left = 0.6
		_after_swell_sec = 0.2
		return
	if not files_ready:
		set_duck(1.0, 1.4)
		return
	set_duck(1.0, 0.8)


func reset_duck() -> void:
	_swell_left = -1.0
	_duck = 1.0
	_duck_target = 1.0
	_duck_sec = 0.40
	duck_time_scale = 1.0


func note_missing(path: String, label: String) -> void:
	if _logged.has(path):
		return
	_logged[path] = true
	print("AU1 missing %s: %s" % [label, path])


func _follow_screen() -> void:
	if not is_inside_tree():
		return
	var board = get_tree().current_scene
	if board == null:
		return
	var front = board.get("front")
	if front == null:
		return
	var selecting := bool(board.get("selecting"))
	var records := bool(board.get("showing_records"))
	var screen = front.screen
	var on_field: bool = screen == FrontEnd.Screen.PLAY and not selecting and not records
	var on_menu: bool = not on_field
	_music_target = 1.0 if on_menu else 0.0
	_crowd_target = 1.0 if on_field else 0.0
	if on_menu and not music_ready:
		note_missing(MUSIC_PATH, "menu theme")
	if on_field and not crowd_ready:
		note_missing(CROWD_PATH, "crowd bed")


func _load_bed(path: String, label: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		note_missing(path, label)
		return null
	var stream = load(path)
	if stream == null:
		note_missing(path, label)
		return null
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	return stream


func _make_player(node_name: String, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus_name
	player.volume_db = -80.0
	add_child(player)
	return player


func _apply(player: AudioStreamPlayer, gain: float, ready: bool) -> void:
	if player == null or not ready:
		return
	if gain <= 0.001:
		if player.playing:
			player.stop()
		player.volume_db = -80.0
		return
	if not player.playing:
		player.play()
	player.volume_db = linear_to_db(gain)
