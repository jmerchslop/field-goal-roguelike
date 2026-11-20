extends Node

# Crowd bed on the field, menu theme on the menu screens.
# A missing file is silent. It is logged once.

const CROWD_PATH := "res://audio/ambience/crowd_loop.ogg"
const MUSIC_PATH := "res://audio/music/main_menu_theme.ogg"
const PLAY_PATH := "res://audio/music/gameplay_kick_a.ogg"
const BOSS_PATH := "res://audio/music/boss_a.ogg"
const FADE_SEC := 1.0
const CROSSFADE_SEC := 1.0
const MUSIC_DUCK_DB := 6.0
const CAM_DUCK_SEC := 0.30
const REACTION_UP_SEC := 0.80
const SHOP_LEVEL := 0.50

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
var field_a: AudioStreamPlayer
var field_b: AudioStreamPlayer
var play_ready := false
var boss_ready := false
var _play_stream: AudioStream
var _boss_stream: AudioStream
var _field_gain: Array[float] = [0.0, 0.0]
var _field_target: Array[float] = [0.0, 0.0]
var _field_index := 0
var _field_kind := ""
var _field_armed: Array[bool] = [false, false]
var _field_level := 0.0
var _field_starts := 0
var _music_duck := 1.0
var _music_duck_target := 1.0
var _music_duck_sec := CAM_DUCK_SEC
var _music_hold := -1.0


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
	field_a = _make_player("FieldA", "Music")
	field_b = _make_player("FieldB", "Music")
	_play_stream = _load_bed(PLAY_PATH, "kick loop")
	_boss_stream = _load_bed(BOSS_PATH, "boss loop")
	play_ready = _play_stream != null
	boss_ready = _boss_stream != null


func _process(delta: float) -> void:
	_follow_screen()
	_music_gain = move_toward(_music_gain, _music_target, delta / FADE_SEC)
	_crowd_gain = move_toward(_crowd_gain, _crowd_target, delta / FADE_SEC)
	tick_duck(delta)
	tick_field(delta)
	_apply(music_player, _music_gain, music_ready)
	_apply(crowd_player, _crowd_gain * _duck, crowd_ready)
	_apply(field_a, _field_gain[0] * _music_duck, field_a != null and field_a.stream != null)
	_apply(field_b, _field_gain[1] * _music_duck, field_b != null and field_b.stream != null)


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


func tick_field(delta: float) -> void:
	for index in 2:
		_field_gain[index] = move_toward(_field_gain[index], _field_target[index], delta / CROSSFADE_SEC)
	if _music_hold >= 0.0:
		_music_hold -= delta
		if _music_hold <= 0.0:
			_music_hold = -1.0
			release_music_duck()
	_music_duck = move_toward(_music_duck, _music_duck_target, delta / maxf(_music_duck_sec, 0.001))
	_start_if_ready(field_a, 0)
	_start_if_ready(field_b, 1)


func music_duck_gain() -> float:
	return db_to_linear(-MUSIC_DUCK_DB)


func music_duck_db() -> float:
	return linear_to_db(maxf(_music_duck, 0.0001))


func begin_cam_music_duck() -> void:
	_music_hold = -1.0
	_music_duck_target = music_duck_gain()
	_music_duck_sec = CAM_DUCK_SEC
	print("MUSIC1 duck -%.1f dB over %.2f s" % [MUSIC_DUCK_DB, CAM_DUCK_SEC])


func release_music_duck() -> void:
	_music_hold = -1.0
	_music_duck_target = 1.0
	_music_duck_sec = REACTION_UP_SEC
	print("MUSIC1 recover over %.2f s" % REACTION_UP_SEC)


func note_crowd_reaction(cam_live: bool, seconds: float) -> void:
	if seconds <= 0.05:
		if cam_live:
			release_music_duck()
		return
	if not cam_live:
		begin_cam_music_duck()
	_music_hold = seconds


func field_track() -> String:
	var player := field_a if _field_index == 0 else field_b
	if player == null or not player.has_meta("track"):
		return ""
	return str(player.get_meta("track"))


func field_starts() -> int:
	return _field_starts


func field_gain_at(index: int) -> float:
	return _field_gain[index]


func set_field_level(level: float) -> void:
	_field_level = level
	if _field_kind == "":
		return
	_field_target[_field_index] = level


func select_kick(boss: bool) -> void:
	var kind := "boss" if boss else "play"
	var path := BOSS_PATH if boss else PLAY_PATH
	var ready := boss_ready if boss else play_ready
	if not ready:
		note_missing(path, "boss loop" if boss else "kick loop")
		return
	if kind == _field_kind and _field_armed[_field_index]:
		_field_target[_field_index] = _field_level
		return
	var next := _field_index
	if _field_kind != "" and kind != _field_kind:
		next = 1 - _field_index
		_field_target[_field_index] = 0.0
		print("MUSIC1 crossfade %.2f s" % CROSSFADE_SEC)
	var dest := field_a if next == 0 else field_b
	dest.stream = _boss_stream if boss else _play_stream
	dest.set_meta("track", path)
	_field_armed[next] = true
	_field_starts += 1
	_field_gain[next] = 0.0 if next != _field_index else _field_gain[next]
	_field_target[next] = _field_level
	_field_index = next
	_field_kind = kind
	_start_if_ready(dest, next)
	print("MUSIC1 %s" % path.get_file())


func reset_duck() -> void:
	_swell_left = -1.0
	_duck = 1.0
	_duck_target = 1.0
	_duck_sec = 0.40
	duck_time_scale = 1.0
	_music_duck = 1.0
	_music_duck_target = 1.0
	_music_duck_sec = CAM_DUCK_SEC
	_music_hold = -1.0


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
	var run = board.get("run")
	var ended := false
	var shopping := false
	var boss := false
	if run != null:
		var phase = run.get("phase")
		ended = phase == RunLogic.Phase.WIN or phase == RunLogic.Phase.GAME_OVER or phase == RunLogic.Phase.FAR
		shopping = bool(run.get("awaiting_shop"))
		boss = bool(run.call("is_boss"))
	if not on_field or ended:
		set_field_level(0.0)
	else:
		set_field_level(SHOP_LEVEL if shopping else 1.0)
		select_kick(boss)
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


func _start_if_ready(player: AudioStreamPlayer, index: int) -> void:
	if player == null or not _field_armed[index] or player.stream == null:
		return
	if _field_target[index] <= 0.001 and _field_gain[index] <= 0.001:
		return
	if not player.is_inside_tree() or player.playing:
		return
	player.play()


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
