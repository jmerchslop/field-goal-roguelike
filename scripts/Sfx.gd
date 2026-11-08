class_name KickSfx
extends Node

# Jordan's sound pack. One file per event, no back-to-back repeat when a pool
# has more than one file. Every player uses the Special Effects bus ("SFX").
# A missing file or a whole missing pool is skipped.

const BUS := "SFX"

const POOL_NAMES := {
	"footsteps": ["approachfootsteps1", "approachfootsteps2"],
	"ballcontact": ["ballcontact1", "ballcontact2"],
	"shank": ["shankedkick", "shankedkick2"],
	"air_bad": ["badaccuracykick", "badaccuracykick2", "badaccuracykick3"],
	"air_good": ["goodaccuracykick", "goodaccuracykick2"],
	"air_perfect": ["perfectaccuracykick", "perfectaccuracykick2"],
	"doink": ["goalpostdoink1"],
	"menu": ["menuclick1", "menuclick2", "menuclick3"],
	"ui": ["menuclick1", "menuclick2", "menuclick3"],
}

const MENU_CONTEXTS: Array[String] = ["title", "menu", "options", "select", "records"]
const UI_CONTEXTS: Array[String] = ["offer", "shop", "belt", "curse", "mulligan"]

var played: Array[Dictionary] = []
var play_calls := 0
var kick_footsteps := false
var kick_contact := false
var kick_airborne := false
var kick_doink := false
var airborne_stops := 0

var _rng := RandomNumberGenerator.new()
var _pools: Dictionary = {}
var _last: Dictionary = {}
var _streams: Dictionary = {}
var _players: Dictionary = {}
var _air: AudioStreamPlayer


func _ready() -> void:
	_rng.randomize()
	_ensure_players()
	scan()


func _ensure_players() -> void:
	if _air != null:
		_assign_bus(_air)
		for pool in _players.keys():
			_assign_bus(_players[pool])
		return
	_air = _make_player("Airborne")
	for pool in ["footsteps", "ballcontact", "shank", "doink", "menu", "ui"]:
		_players[pool] = _make_player(pool)
	_players["air_bad"] = _air
	_players["air_good"] = _air
	_players["air_perfect"] = _air


func _assign_bus(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.bus = BUS
	player.pitch_scale = 1.0


func _make_player(node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = BUS
	player.pitch_scale = 1.0
	player.volume_db = 0.0
	add_child(player)
	return player


# Ignore spaces, underscores, hyphens, and case. The pack spells one file "footseps".
static func normalize_stem(file_name: String) -> String:
	var stem := file_name.get_file().get_basename()
	var flat := stem.to_lower().replace(" ", "").replace("_", "").replace("-", "")
	return flat.replace("footseps", "footsteps")


static func context_pool(context: String) -> String:
	if MENU_CONTEXTS.has(context):
		return "menu"
	if UI_CONTEXTS.has(context):
		return "ui"
	return ""


static func airborne_pool(error: float, perfect_band: float, good_band: float, perfect_lock: bool) -> String:
	if perfect_lock or absf(error) <= perfect_band:
		return "air_perfect"
	if absf(error) <= good_band:
		return "air_good"
	return "air_bad"


func scan(root: String = "res://") -> void:
	var found: Dictionary = {}
	_walk(root, found)
	_pools.clear()
	for pool in POOL_NAMES.keys():
		var files: Array[String] = []
		for alias in POOL_NAMES[pool]:
			if not found.has(alias):
				continue
			var path := str(found[alias])
			if files.has(path):
				continue
			files.append(path)
			if not _streams.has(path):
				var stream: Resource = load(path)
				if stream != null:
					_streams[path] = stream
		_pools[pool] = files


func files_of(pool: String) -> Array:
	return _pools.get(pool, [])


func begin_kick() -> void:
	airborne_stops += 1
	if _air != null:
		_air.stop()
	kick_footsteps = false
	kick_contact = false
	kick_airborne = false
	kick_doink = false


func approach() -> String:
	if kick_footsteps:
		return ""
	kick_footsteps = true
	return play_pool("footsteps")


# Contact plus, on a real lock, one airborne cue. A shank never plays ball contact
# or an airborne file. Calling this again on the same kick does not stack another airborne.
func struck(shanked: bool, error: float, perfect_band: float, good_band: float, perfect_lock: bool) -> String:
	if kick_contact:
		return ""
	kick_contact = true
	if shanked:
		return play_pool("shank")
	var contact := play_pool("ballcontact")
	if not kick_airborne:
		kick_airborne = true
		play_pool(airborne_pool(error, perfect_band, good_band, perfect_lock))
	return contact


func post() -> String:
	if kick_doink:
		return ""
	kick_doink = true
	return play_pool("doink")


func cue(context: String) -> String:
	var pool := context_pool(context)
	if pool == "":
		return ""
	return play_pool(pool)


func play_pool(pool: String) -> String:
	var path := _pick(pool)
	if path == "":
		return ""
	var stream: Resource = _streams.get(path)
	_ensure_players()
	var player: AudioStreamPlayer = _players.get(pool)
	if player != null and stream != null and is_inside_tree():
		player.stream = stream
		player.bus = BUS
		player.pitch_scale = 1.0
		player.play()
		play_calls += 1
	played.append({"pool": pool, "file": path.get_file()})
	return path.get_file()


func player_bus(pool: String) -> String:
	_ensure_players()
	var player: AudioStreamPlayer = _players.get(pool)
	if player == null:
		return ""
	return player.bus


func _pick(pool: String) -> String:
	var files: Array = _pools.get(pool, [])
	if files.is_empty():
		return ""
	if files.size() == 1:
		_last[pool] = files[0]
		return str(files[0])
	var previous := str(_last.get(pool, ""))
	var choice := str(files[_rng.randi() % files.size()])
	var spins := 0
	while choice == previous and spins < 8:
		choice = str(files[_rng.randi() % files.size()])
		spins += 1
	if choice == previous:
		for file in files:
			if str(file) != previous:
				choice = str(file)
				break
	_last[pool] = choice
	return choice


func _walk(path: String, found: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not name.begins_with("."):
			var full := path.path_join(name)
			if dir.current_is_dir():
				_walk(full, found)
			else:
				var ext := name.get_extension().to_lower()
				if ext == "mp3" or ext == "ogg" or ext == "wav":
					var key := normalize_stem(name)
					if not found.has(key):
						found[key] = full
		name = dir.get_next()
	dir.list_dir_end()
