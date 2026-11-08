extends Node

# Records and trophies. The in-run loadout is not stored here.
# A missing or broken file falls back to zeros and is rewritten.

const DEFAULT_PATH := "user://save.cfg"
const TROPHY_IDS: Array = [
	"extra_point",
	"fifty_club",
	"sixty_club",
	"record_breaker",
	"perfect_quarter",
	"hot_hand",
	"season_complete",
	"bullseye_collector",
]

var file_path := DEFAULT_PATH
var runs := 0
var wins := 0
var longest_make := 0
var best_score := 0
var makes := 0
var attempts := 0
var middles := 0
var kickers := {}
var trophies := {}
var unlocks := {}
var _f9_at := -10.0
var fresh_unlocks: Array[String] = []


func _ready() -> void:
	load_file()


func load_file() -> void:
	_fill_defaults()
	var cfg := ConfigFile.new()
	var err := cfg.load(file_path)
	if err != OK:
		save_file()
		return
	if _as_int(cfg.get_value("meta", "version", 0)) != 1:
		_fill_defaults()
		save_file()
		return
	runs = _as_int(cfg.get_value("lifetime", "runs", 0))
	wins = _as_int(cfg.get_value("lifetime", "wins", 0))
	longest_make = _as_int(cfg.get_value("lifetime", "longest_make", 0))
	best_score = _as_int(cfg.get_value("lifetime", "best_score", 0))
	makes = _as_int(cfg.get_value("lifetime", "makes", 0))
	attempts = _as_int(cfg.get_value("lifetime", "attempts", 0))
	middles = _as_int(cfg.get_value("lifetime", "middles", 0))
	for id in _kicker_ids():
		var section := "kicker_%s" % id
		kickers[id] = {
			"runs": _as_int(cfg.get_value(section, "runs", 0)),
			"wins": _as_int(cfg.get_value(section, "wins", 0)),
			"best_score": _as_int(cfg.get_value(section, "best_score", 0)),
			"longest_make": _as_int(cfg.get_value(section, "longest_make", 0)),
			"makes": _as_int(cfg.get_value(section, "makes", 0)),
			"attempts": _as_int(cfg.get_value(section, "attempts", 0)),
		}
	for id in TROPHY_IDS:
		trophies[id] = bool(cfg.get_value("trophies", id, false))
	for id in _unlock_ids():
		unlocks[id] = bool(cfg.get_value("unlocks", id, false))
	_grant_recorded_unlocks()


func save_file() -> void:
	if not kickers.has(Kickers.BIG_BRUCE) or not kickers.has(Kickers.WALK_ON) or not kickers.has(Kickers.PHIL):
		var kept: Dictionary = kickers.duplicate(true)
		_fill_defaults()
		for id in kept.keys():
			if kickers.has(id):
				kickers[id] = kept[id]
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", 1)
	cfg.set_value("lifetime", "runs", runs)
	cfg.set_value("lifetime", "wins", wins)
	cfg.set_value("lifetime", "longest_make", longest_make)
	cfg.set_value("lifetime", "best_score", best_score)
	cfg.set_value("lifetime", "makes", makes)
	cfg.set_value("lifetime", "attempts", attempts)
	cfg.set_value("lifetime", "middles", middles)
	for id in _kicker_ids():
		var section := "kicker_%s" % id
		var row: Dictionary = kickers[id]
		cfg.set_value(section, "runs", int(row["runs"]))
		cfg.set_value(section, "wins", int(row["wins"]))
		cfg.set_value(section, "best_score", int(row["best_score"]))
		cfg.set_value(section, "longest_make", int(row["longest_make"]))
		cfg.set_value(section, "makes", int(row["makes"]))
		cfg.set_value(section, "attempts", int(row["attempts"]))
	for id in TROPHY_IDS:
		cfg.set_value("trophies", id, bool(trophies[id]))
	for id in _unlock_ids():
		cfg.set_value("unlocks", id, bool(unlocks.get(id, false)))
	cfg.save(file_path)


func reset_save() -> void:
	_fill_defaults()
	save_file()


func press_f9(now: float) -> String:
	if now - _f9_at <= 2.0 and now >= _f9_at:
		_f9_at = -10.0
		reset_save()
		return "Save reset"
	_f9_at = now
	return "Press F9 again to reset save."


func kicker_row(id: String) -> Dictionary:
	if not kickers.has(id):
		return {"runs": 0, "wins": 0, "best_score": 0, "longest_make": 0, "makes": 0, "attempts": 0}
	return kickers[id]


func has_unlock(id: String) -> bool:
	return bool(unlocks.get(id, false))


func try_unlock(id: String) -> bool:
	if not _unlock_ids().has(id):
		return false
	if bool(unlocks.get(id, false)):
		return false
	unlocks[id] = true
	save_file()
	return true


func has_trophy(id: String) -> bool:
	return bool(trophies.get(id, false))


# Returns true only the first time this trophy is earned.
func try_trophy(id: String) -> bool:
	if not TROPHY_IDS.has(id):
		return false
	if bool(trophies.get(id, false)):
		return false
	trophies[id] = true
	save_file()
	return true


# summary: score, longest, makes, attempts, middles, won, kicker_id
func commit_run(summary: Dictionary) -> Dictionary:
	var score := _as_int(summary.get("score", 0))
	var longest := _as_int(summary.get("longest", 0))
	var beat_score := score > best_score
	var beat_long := longest > longest_make
	runs += 1
	makes += _as_int(summary.get("makes", 0))
	attempts += _as_int(summary.get("attempts", 0))
	middles += _as_int(summary.get("middles", 0))
	if bool(summary.get("won", false)):
		wins += 1
	if beat_score:
		best_score = score
	if beat_long:
		longest_make = longest
	var kicker_id := str(summary.get("kicker_id", ""))
	if kickers.has(kicker_id):
		var row: Dictionary = kickers[kicker_id]
		row["runs"] = int(row["runs"]) + 1
		row["makes"] = int(row["makes"]) + _as_int(summary.get("makes", 0))
		row["attempts"] = int(row["attempts"]) + _as_int(summary.get("attempts", 0))
		if bool(summary.get("won", false)):
			row["wins"] = int(row["wins"]) + 1
		if score > int(row["best_score"]):
			row["best_score"] = score
		if longest > int(row["longest_make"]):
			row["longest_make"] = longest
		kickers[kicker_id] = row
	save_file()
	return {"score": beat_score, "longest": beat_long}


static func trophy_name(id: String) -> String:
	match id:
		"extra_point":
			return "Extra Point"
		"fifty_club":
			return "Fifty Club"
		"sixty_club":
			return "Sixty Club"
		"record_breaker":
			return "Record Breaker"
		"perfect_quarter":
			return "Perfect Quarter"
		"hot_hand":
			return "Hot Hand"
		"season_complete":
			return "Season Complete"
		"bullseye_collector":
			return "Bullseye Collector"
	return id


static func trophy_condition(id: String) -> String:
	match id:
		"extra_point":
			return "Make any kick"
		"fifty_club":
			return "Make a 50+ yard kick"
		"sixty_club":
			return "Make a 60+ yard kick"
		"record_breaker":
			return "Make a 69+ yard kick"
		"perfect_quarter":
			return "Make all 5 kicks of a quarter on the first ball"
		"hot_hand":
			return "Reach a streak of 10"
		"season_complete":
			return "Make kick 20"
		"bullseye_collector":
			return "10 lifetime down-the-middle makes"
	return ""


static func fg_text(made: int, tried: int) -> String:
	if tried <= 0:
		return "—"
	return "%.1f%%" % (100.0 * float(made) / float(tried))


func _fill_defaults() -> void:
	runs = 0
	wins = 0
	longest_make = 0
	best_score = 0
	makes = 0
	attempts = 0
	middles = 0
	kickers = {}
	for id in _kicker_ids():
		kickers[id] = {
			"runs": 0,
			"wins": 0,
			"best_score": 0,
			"longest_make": 0,
			"makes": 0,
			"attempts": 0,
		}
	trophies = {}
	for id in TROPHY_IDS:
		trophies[id] = false
	unlocks = {}
	for id in _unlock_ids():
		unlocks[id] = false


func _kicker_ids() -> Array:
	return [Kickers.BIG_BRUCE, Kickers.WALK_ON, Kickers.PHIL, Kickers.GARY, Kickers.VEX, Kickers.COLE, Kickers.WILLOW, Kickers.CARLOS]


func _unlock_ids() -> Array:
	return [Kickers.PHIL, Kickers.GARY, Kickers.VEX, Kickers.COLE, Kickers.WILLOW, Kickers.CARLOS]


# Season Complete and a 100-yard record unlock Cole and Carlos the next time the save loads.
# Willow is not reconstructed from old kicks.
func _grant_recorded_unlocks() -> void:
	fresh_unlocks = []
	var changed := false
	if bool(trophies.get("season_complete", false)) and not bool(unlocks.get(Kickers.COLE, false)):
		unlocks[Kickers.COLE] = true
		fresh_unlocks.append("Cole Lang unlocked")
		changed = true
	if longest_make >= 100 and not bool(unlocks.get(Kickers.CARLOS, false)):
		unlocks[Kickers.CARLOS] = true
		fresh_unlocks.append("Carlos Hernandez unlocked")
		changed = true
	if changed:
		save_file()


func _as_int(value) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String and str(value).is_valid_int():
		return int(str(value))
	return 0
