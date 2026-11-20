class_name Kickers
extends RefCounted

# The two kickers. Adding a third one later means adding data here.
# Kick code never names a kicker. It only reads KickerStats and ball_type.
# farm_ball multiplies sideways wind drift by 1.10. The kick reads ball_type.

const BIG_BRUCE := "big_bruce"
const WALK_ON := "walk_on"
const PHIL := "phil"
const GARY := "gary"
const VEX := "vex"
const COLE := "cole"
const WILLOW := "willow"
const CARLOS := "carlos"

const UNLOCKABLE: Array = [PHIL, GARY, VEX, COLE, WILLOW, CARLOS]

const ALL: Array = [
	{
		"id": BIG_BRUCE,
		"name": "Big Bruce",
		"lore": "A farmer who's been booting fence posts loose since he was nine. He can kick it a mile. The hay ball goes where the wind takes it.",
		"excels": "Farm Strength. A press under 80% still kicks at 80%.",
		"downside": "The Farm Ball. Wind pushes it 10% more.",
		"ball_name": "The Farm Ball",
		"ball_description": "A light hay ball. Wind moves it 10% more than a normal ball. A doink stays a doink.",
		"ball_type": "farm_ball",
		"accuracy": 90,
		"range_line": "70 yd",
		"kit_line": "Farm Strength",
		"unlock": "",
		"color": Color(0.55, 0.09, 0.08),
		"shape": "square",
		"portrait_path": "res://art/kickers/big_bruce.png",
	},
	{
		"id": WALK_ON,
		"name": "The Walk-On",
		"lore": "Nobody recruited him. He showed up to tryouts in borrowed cleats and never left.",
		"excels": "Earns His Spot. 2 rerolls a run. A retry after a miss slows both needles by 10% and adds 6 yards.",
		"downside": "No standout strength.",
		"ball_name": "Team-Issue",
		"ball_description": "A normal ball. No special trick.",
		"ball_type": "standard",
		"accuracy": 100,
		"range_line": "55 yd",
		"kit_line": "Earns His Spot",
		"unlock": "",
		"color": Color(0.22, 0.38, 0.82),
		"shape": "circle",
		"portrait_path": "res://art/kickers/walk_on.png",
	},
	{
		"id": PHIL,
		"name": "Phil the Pharmacist",
		"lore": "He compounds the little things. The shop knows his name, and the gelcap only pays when he actually took it.",
		"excels": "House Account. Shop goods are free, including B12. Shelf rerolls still cost cash. Compounding. Your items are 15% stronger: equipment, perks, curse upsides, and vitamins, not only shop bottles.",
		"downside": "54 yards with nothing on. Rerolls still cost cash.",
		"ball_name": "The Gelcap",
		"ball_description": "A vitamin used on this attempt adds +0.5 Mult on a make.",
		"ball_type": "standard",
		"accuracy": 112,
		"range_line": "54 yd",
		"kit_line": "House Account",
		"unlock": "Buy something from the Vitamin Shop",
		"color": Color(0.85, 0.9, 0.95),
		"shape": "circle",
		"portrait_path": "res://art/kickers/phil_portrait.png",
	},
	{
		"id": GARY,
		"name": "Gary the Goat",
		"lore": "He treats a good kick like gold. First-try makes make his gear a little luckier.",
		"excels": "Good As Gold. The good band counts as PERFECT.",
		"downside": "No Farm Strength. A miss still misses.",
		"ball_name": "Lucky Ball",
		"ball_description": "Each first-try make adds 3%. The bonus caps at +25%. A miss resets it.",
		"ball_type": "standard",
		"accuracy": 98,
		"range_line": "65 yd",
		"kit_line": "Good As Gold",
		"unlock": "Beat Standard without a miss",
		"color": Color(0.55, 0.28, 0.12),
		"shape": "square",
		"portrait_path": "res://art/kickers/gary_portrait.png",
	},
	{
		"id": VEX,
		"name": "Vex",
		"lore": "The saucer carries a long way, then keeps curving left.",
		"excels": "Out of This World Range. A 500 yard base, so full power with nothing on carries 500 yards.",
		"downside": "The Flying Saucer always curves left.",
		"ball_name": "The Flying Saucer",
		"ball_description": "Curves left like 11 mph of west wind, on top of the real wind.",
		"ball_type": "standard",
		"accuracy": 94,
		"range_line": "500 yd",
		"kit_line": "Out of This World Range",
		"unlock": "Make a 500-yard field goal in Endless",
		"color": Color(0.75, 0.8, 0.88),
		"shape": "circle",
		"portrait_path": "res://art/kickers/vex_portrait.png",
	},
	{
		"id": COLE,
		"name": "Cole Lang",
		"lore": "The brand wants the middle of the posts, not a bottle on the belt.",
		"excels": "Brand Deal. Loadout offers stay. The Vitamin Shop does not.",
		"downside": "No vitamins and no B12. The belt stays empty.",
		"ball_name": "Showtime",
		"ball_description": "A down-the-middle make doubles stored Mult, and that kick scores with the doubled Mult.",
		"ball_type": "standard",
		"accuracy": 120,
		"range_line": "75 yd",
		"kit_line": "Brand Deal",
		"unlock": "Beat Standard",
		"color": Color(0.85, 0.45, 0.12),
		"shape": "circle",
		"portrait_path": "res://art/kickers/cole_portrait.png",
	},
	{
		"id": WILLOW,
		"name": "Willow Reed",
		"lore": "She takes her time. The first loadout offer of the run includes a range item.",
		"excels": "Synchronicity. The first loadout offer includes a range item.",
		"downside": "50 yards with nothing on. The Chill Ball is slow.",
		"ball_name": "The Chill Ball",
		"ball_description": "Both needles run at half speed. Items and weather still stack on top.",
		"ball_type": "standard",
		"accuracy": 88,
		"range_line": "50 yd",
		"kit_line": "Synchronicity",
		"unlock": "Make a kick with 1 attempt left (kick 5+)",
		"color": Color(0.2, 0.35, 0.72),
		"shape": "circle",
		"portrait_path": "res://art/kickers/willow_portrait.png",
	},
	{
		"id": CARLOS,
		"name": "Carlos Hernandez",
		"lore": "Smash the power and the accuracy takes care of itself. The ball does not wait around.",
		"excels": "Numero Dos. A lock of 95 or higher, including the OVERPOWER band, is a true PERFECT. OVERPOWER range does not apply.",
		"downside": "94 and below is a normal accuracy swing.",
		"ball_name": "The Not So Secret Weapon",
		"ball_description": "Both needles run 15% faster. Items and weather still stack on top.",
		"ball_type": "standard",
		"accuracy": 96,
		"range_line": "69 yd",
		"kit_line": "Numero Dos",
		"unlock": "Make a 100-yard field goal",
		"color": Color(0.93, 0.9, 0.82),
		"shape": "square",
		"portrait_path": "res://art/kickers/carlos_portrait.png",
	},
]


static func save_tag(id: String) -> String:
	match id:
		BIG_BRUCE:
			return "BRUCE"
		WALK_ON:
			return "WALK ON"
		PHIL:
			return "PHIL"
		GARY:
			return "GARY"
		VEX:
			return "VEX"
		COLE:
			return "COLE"
		WILLOW:
			return "WILLOW"
		CARLOS:
			return "CARLOS"
		_:
			return "KICKER"


static func get_def(id: String) -> Dictionary:
	for item in ALL:
		if str(item["id"]) == id:
			return item
	return {}


static func id_for_slot(slot: int) -> String:
	if slot < 0 or slot >= ALL.size():
		return ""
	return str(ALL[slot]["id"])


static func has_portrait(id: String) -> bool:
	var info := get_def(id)
	if info.is_empty():
		return false
	return ResourceLoader.exists(str(info["portrait_path"]))


# Click once to highlight. Click the highlighted card again to confirm.
static func click_slot(highlighted: int, clicked: int) -> Dictionary:
	if clicked < 0 or clicked >= ALL.size():
		return {"highlight": highlighted, "confirm": false}
	if highlighted == clicked:
		return {"highlight": highlighted, "confirm": true}
	return {"highlight": clicked, "confirm": false}


static func apply_to(stats: KickerStats, id: String) -> void:
	stats.reset()
	var info := get_def(id)
	if info.is_empty():
		return
	stats.ball_type = str(info["ball_type"])
	stats.accuracy = float(info.get("accuracy", 100.0))
	stats.perfect_band = KickConstants.PERFECT_BAND * (stats.accuracy / 100.0)
	stats.good_band = KickConstants.METER_INNER_BAND * (stats.accuracy / 100.0)
	stats.ball_speed_mult = 1.0
	if id == BIG_BRUCE:
		stats.range_per_power = 0.54
		stats.power_floor = 80.0
	elif id == WALK_ON:
		stats.range_per_power = 0.39
		stats.rerolls_per_run = 2
	elif id == PHIL:
		stats.range_per_power = 0.38
		stats.compounding = true
		stats.house_account = true
		stats.gelcap = true
	elif id == GARY:
		stats.range_per_power = 0.49
		stats.good_as_gold = true
		stats.lucky_ball = true
	elif id == VEX:
		stats.clearance = false
		stats.saucer_mph = 11.0
		stats.range_base = 16.0
		stats.range_per_power = 4.84
	elif id == COLE:
		stats.range_per_power = 0.59
		stats.ball_speed_mult = 1.0
		stats.brand_deal = true
		stats.showtime = true
	elif id == WILLOW:
		stats.range_per_power = 0.34
		stats.ball_speed_mult = 0.50
		stats.synchronicity = true
	elif id == CARLOS:
		stats.range_per_power = 0.53
		stats.ball_speed_mult = 1.15
		stats.numero_dos = true


static func unlock_hint(id: String) -> String:
	return str(get_def(id).get("unlock", ""))


# Select-screen kit facts. Numbers come from the same stats the kick uses.
static func rundown_lines(id: String, unlocked: bool, tad_cap: int = -1, tad_picked: int = -1) -> PackedStringArray:
	var info := get_def(id)
	var lines := PackedStringArray()
	if info.is_empty():
		return lines
	lines.append(str(info["name"]))
	if not unlocked:
		lines.append("Locked.")
		var rule := unlock_hint(id)
		if rule != "":
			lines.append(rule + ".")
		return lines
	var stats := KickerStats.new()
	apply_to(stats, id)
	lines.append("%s. %s." % [str(info["kit_line"]), str(info["ball_name"])])
	var yards := stats.range_base + stats.range_per_power * 100.0
	lines.append("Full power with no wind is %s yards." % _plain_number(yards))
	lines.append("Perfect band %s. Good band %s." % [_plain_number(stats.perfect_band), _plain_number(stats.good_band)])
	var sweep := "%.2f" % MeterGauge.SWEEP_SEC
	if is_equal_approx(stats.ball_speed_mult, 1.0):
		lines.append("Both needles share one speed, the %s second sweep." % sweep)
	else:
		lines.append("Both needles share one speed, %s times the %s second sweep." % [_plain_number(stats.ball_speed_mult), sweep])
	if stats.power_floor > 0.0:
		var floor_num := _plain_number(stats.power_floor)
		lines.append("A press under %s%% still kicks at %s%%." % [floor_num, floor_num])
	if stats.ball_type == "farm_ball":
		var pushed := KickLogic.drift_at_uprights(10.0, 90.0, 35.0, 0, 0, "farm_ball")
		var plain := KickLogic.drift_at_uprights(10.0, 90.0, 35.0, 0, 0, "standard")
		var extra := 0
		if absf(plain) > 0.0001:
			extra = int(round((pushed / plain - 1.0) * 100.0))
		lines.append("Wind pushes the ball %d%% more." % extra)
	if stats.rerolls_per_run != 1:
		lines.append("Starts with %d offer rerolls." % stats.rerolls_per_run)
	if id == WALK_ON:
		var retry := RunLogic.new()
		retry.start_with_kicker(WALK_ON)
		retry.is_first_ball = false
		retry.prepare_kick_stats()
		var first := RunLogic.new()
		first.start_with_kicker(WALK_ON)
		first.prepare_kick_stats()
		var slow := 1.0
		if absf(first.stats.power_speed) > 0.001:
			slow = retry.stats.power_speed / first.stats.power_speed
		lines.append("A retry after a miss slows that speed to %s and adds %s yards." % [_plain_number(slow), _plain_number(retry.stats.range_bonus - first.stats.range_bonus)])
	if stats.house_account:
		lines.append("Shop goods are free. Shelf rerolls still cost cash.")
	if stats.compounding:
		lines.append("Compounding makes item effects 15% stronger.")
	if stats.gelcap:
		lines.append("A vitamin used on this kick adds 0.5 Mult on a make.")
	if stats.good_as_gold:
		lines.append("The good band counts as perfect.")
	if stats.lucky_ball:
		lines.append("Each first-try make adds 3% to item scale, up to 25%. A miss resets it.")
	if stats.saucer_mph > 0.0:
		lines.append("The saucer curves left like %s mph of west wind." % _plain_number(stats.saucer_mph))
	if stats.brand_deal:
		lines.append("Loadout offers stay. The Vitamin Shop does not.")
	if stats.showtime:
		lines.append("A down-the-middle make doubles the stored Mult.")
	if stats.synchronicity:
		lines.append("The first loadout offer includes a range item.")
	if stats.numero_dos:
		lines.append("A power lock of %s or higher, including the overpower band, is a true perfect and pays no overpower yards." % _plain_number(KickConstants.RED_TIP_START))
	if tad_cap >= 0:
		lines.append_array(_tad_rundown(tad_cap, tad_picked))
	return lines


static func _tad_rundown(cap: int, picked: int) -> PackedStringArray:
	var lines := PackedStringArray()
	if picked < 0:
		if cap <= 0:
			lines.append("Two-a-days not unlocked.")
		else:
			lines.append("Two-a-days unlocked through %d." % cap)
		return lines
	var level := clampi(picked, 0, cap)
	lines.append("Two-a-days %d: %s." % [level, RunLogic.tad_name(level)])
	lines.append(RunLogic.tad_sentence(level))
	if level >= 2:
		lines.append("All below also apply.")
		for below in range(level - 1, 0, -1):
			lines.append("%s. %s" % [RunLogic.tad_name(below), RunLogic.tad_sentence(below)])
	return lines


static func _plain_number(value: float) -> String:
	var hundredths := snappedf(value, 0.01)
	if is_equal_approx(hundredths, roundf(hundredths)):
		return str(int(roundf(hundredths)))
	return "%.2f" % hundredths


static func is_starter(id: String) -> bool:
	return id == BIG_BRUCE or id == WALK_ON


static func is_unlocked(id: String) -> bool:
	if is_starter(id):
		return true
	if KickConstants.debug_unlock_all_kickers and UNLOCKABLE.has(id):
		return true
	var data = _save()
	if data == null:
		return false
	return bool(data.has_unlock(id))


static func aliases(id: String) -> Array:
	match id:
		BIG_BRUCE:
			return ["big_bruce", "bruce"]
		WALK_ON:
			return ["walk_on", "walkon"]
		PHIL:
			return ["pharmacist", "phil"]
		GARY:
			return ["gary", "goat"]
		VEX:
			return ["vex"]
		COLE:
			return ["cole", "lang", "bigshot", "big_shot"]
		WILLOW:
			return ["willow", "sunshine", "reed"]
		CARLOS:
			return ["carlos", "hernandez"]
	return []


static func is_make_result(shanked: bool, result: String) -> bool:
	# GOOD covers PERFECT, DOWN THE MIDDLE, BANK SHOT, and INSURED.
	# A doink that stays a miss, a shank, and the wide / short calls do not.
	return not shanked and result == "GOOD"


static func reaction_pose(age: float, made: bool) -> String:
	# Measured from the moment the result stamp starts.
	if age < 0.18:
		return "react_front"
	if age < 0.45:
		return "react_up" if made else "react_hands"
	return "react_down" if made else "react_slump"


static func field_frame(id: String, pose: String) -> String:
	_ensure_art()
	var mine: Dictionary = _frames.get(id, {})
	var direct := str(mine.get(pose, ""))
	if direct != "":
		return direct
	# A missing reaction beat uses Walk-On's matching frame, not follow-through.
	if pose.begins_with("react_"):
		if id != WALK_ON:
			return str(_frames.get(WALK_ON, {}).get(pose, ""))
		return ""
	for other in ["idle", "run", "plant", "follow", "portrait"]:
		if other == pose:
			continue
		if str(mine.get(other, "")) != "":
			return str(mine[other])
	if id != WALK_ON:
		var backup: Dictionary = _frames.get(WALK_ON, {})
		var matched := str(backup.get(pose, ""))
		if matched != "":
			return matched
		return str(backup.get("portrait", ""))
	return ""


static func ball_sprite(id: String, place: String = "any") -> String:
	_ensure_balls()
	var row: Dictionary = _ball_rows.get(id, {})
	if row.is_empty():
		return ""
	if place == "tee" and str(row.get("tee", "")) != "":
		return str(row["tee"])
	if place == "air" and str(row.get("air", "")) != "":
		return str(row["air"])
	if str(row.get("any", "")) != "":
		return str(row["any"])
	if str(row.get("tee", "")) != "":
		return str(row["tee"])
	return str(row.get("air", ""))


# Match ball art without touching the disk. A missing kicker returns an empty picture.
static func match_balls(paths: Array) -> Dictionary:
	var named: Dictionary = {}
	var fallback: Dictionary = {}
	for path in paths:
		var text := str(path)
		if _ball_blocked(text):
			continue
		var stem := text.get_file().get_basename()
		var key := _ball_key(stem)
		var slot := _ball_place(key)
		var owner := _ball_owner_by_name(key, text)
		if owner != "":
			_push_ball(named, owner, text, slot, _ball_name_score(text))
			continue
		var backup := _ball_owner_by_kicker(key, text)
		if backup != "":
			_push_ball(fallback, backup, text, slot, 1)
	var rows := {}
	for id in [BIG_BRUCE, WALK_ON, PHIL, GARY, VEX, COLE, WILLOW, CARLOS]:
		var hits: Array = named.get(id, [])
		if hits.is_empty():
			hits = fallback.get(id, [])
		rows[id] = _pick_ball_slots(hits)
	return rows


static func _ball_key(stem: String) -> String:
	var flat := stem.to_lower().replace(" ", "").replace("_", "").replace("-", "")
	if flat.begins_with("the"):
		flat = flat.substr(3)
	return flat


static func _ball_blocked(path: String) -> bool:
	var flat := path.to_lower().replace("-", "_").replace(" ", "_")
	if flat.find("hero_ball") >= 0 or flat.find("heroball") >= 0:
		return true
	if flat.find("/loadout/") >= 0 or flat.find("/vitamins/") >= 0 or flat.find("/shop/") >= 0:
		return true
	return false


static func _ball_aliases(id: String) -> Array:
	match id:
		BIG_BRUCE:
			return ["farmball"]
		WALK_ON:
			return ["teamissue"]
		PHIL:
			return ["gelcap"]
		GARY:
			return ["luckyball"]
		VEX:
			return ["flyingsaucer", "saucer"]
		COLE:
			return ["showtime"]
		WILLOW:
			return ["chillball"]
		CARLOS:
			return ["notsosecretweapon", "secretweapon"]
	return []


static func _ball_owner_by_name(key: String, path: String) -> String:
	var best := ""
	var best_len := 0
	for id in [BIG_BRUCE, WALK_ON, PHIL, GARY, VEX, COLE, WILLOW, CARLOS]:
		for alias in _ball_aliases(id):
			var token := str(alias)
			if token == "" or key.find(token) < 0:
				continue
			if token == "saucer" and not _saucer_is_vex(key, path):
				continue
			if token.length() > best_len:
				best = id
				best_len = token.length()
	return best


static func _saucer_is_vex(key: String, path: String) -> bool:
	if key.find("flying") >= 0 or key.find("vex") >= 0:
		return true
	return path.to_lower().find("vex") >= 0


static func _ball_owner_by_kicker(key: String, path: String) -> String:
	var file_name := path.get_file().get_basename().to_lower()
	var named_ball := key.find("ball") >= 0 or file_name == "ball"
	var folder_ball := path.to_lower().find("/ball/") >= 0
	if not named_ball and not folder_ball:
		return ""
	var hay := "_" + path.to_lower().replace("/", "_").replace("-", "_").replace(" ", "_") + "_"
	var best := ""
	var best_len := 0
	for id in [BIG_BRUCE, WALK_ON, PHIL, GARY, VEX, COLE, WILLOW, CARLOS]:
		for alias in aliases(id):
			var token := str(alias)
			if token == "":
				continue
			var in_key := key.find(_ball_key(token)) >= 0
			var in_path := hay.find("_" + token + "_") >= 0
			if (in_key or in_path) and token.length() > best_len:
				best = id
				best_len = token.length()
	return best


static func _ball_place(key: String) -> String:
	if key.find("tee") >= 0 or key.find("idle") >= 0 or key.find("ground") >= 0:
		return "tee"
	if key.find("flight") >= 0 or key.find("air") >= 0 or key.find("side") >= 0:
		return "air"
	return "any"


static func _ball_name_score(path: String) -> int:
	var flat := path.to_lower()
	var score := 1
	if flat.find("ball") >= 0:
		score += 4
	if flat.find("/balls/") >= 0 or flat.find("/ball/") >= 0:
		score += 2
	return score


static func _push_ball(bucket: Dictionary, id: String, path: String, slot: String, score: int) -> void:
	if not bucket.has(id):
		bucket[id] = []
	var hits: Array = bucket[id]
	hits.append({"path": path, "slot": slot, "score": score})
	bucket[id] = hits


static func _pick_ball_slots(hits: Array) -> Dictionary:
	var best := {"tee": "", "air": "", "any": ""}
	var score := {"tee": -1, "air": -1, "any": -1}
	var top := -1
	var top_path := ""
	for hit in hits:
		var slot := str(hit.get("slot", "any"))
		if not score.has(slot):
			slot = "any"
		var value := int(hit.get("score", 0))
		if value > int(score[slot]):
			score[slot] = value
			best[slot] = str(hit.get("path", ""))
		if value > top:
			top = value
			top_path = str(hit.get("path", ""))
	if str(best["any"]) == "":
		best["any"] = top_path
	return best


static var _balls_ready := false
static var _ball_rows: Dictionary = {}


static func _ensure_balls() -> void:
	if _balls_ready:
		return
	_balls_ready = true
	var paths: Array = []
	_walk_pngs("res://", paths)
	_ball_rows = match_balls(paths)


static var _art_ready := false
static var _frames := {}


static func _save():
	var loop := Engine.get_main_loop()
	if loop == null:
		return null
	return loop.root.get_node_or_null("SaveData")


static func _ensure_art() -> void:
	if _art_ready:
		return
	_art_ready = true
	_frames = {}
	for id in [BIG_BRUCE, WALK_ON, PHIL, GARY, VEX, COLE, WILLOW, CARLOS]:
		_frames[id] = {}
	var paths: Array = []
	_walk_pngs("res://", paths)
	for path in paths:
		var file_name := str(path).get_file().get_basename().to_lower().replace("-", "_").replace(" ", "_")
		var hay := "_" + str(path).to_lower().replace("/", "_").replace("-", "_") + "_"
		var owner := ""
		var owner_len := 0
		for id in [BIG_BRUCE, WALK_ON, PHIL, GARY, VEX, COLE, WILLOW, CARLOS]:
			for alias in aliases(id):
				if hay.find("_" + str(alias) + "_") >= 0 and str(alias).length() > owner_len:
					owner = id
					owner_len = str(alias).length()
		if owner == "":
			continue
		var pose := _pose_of(file_name)
		var row: Dictionary = _frames[owner]
		var previous := str(row.get(pose, ""))
		if previous == "" or _pose_score(file_name, pose) > _pose_score(previous.get_file().get_basename().to_lower(), pose):
			row[pose] = str(path)
		_frames[owner] = row


static func _pose_of(stem: String) -> String:
	if stem.find("miss_02") >= 0 or stem.find("slump") >= 0:
		return "react_slump"
	if stem.find("miss_01") >= 0 or stem.find("hands") >= 0:
		return "react_hands"
	if stem.find("make_02") >= 0:
		return "react_down"
	if stem.find("make_01") >= 0:
		return "react_up"
	if stem.find("00_front") >= 0 or stem.ends_with("_front"):
		return "react_front"
	if stem.find("follow") >= 0:
		return "follow"
	if stem.find("plant") >= 0:
		return "plant"
	if stem.find("run") >= 0:
		return "run"
	if stem.find("idle") >= 0 or stem.ends_with("_back"):
		return "idle"
	if stem.find("portrait") >= 0:
		return "portrait"
	return "portrait"


static func _pose_score(stem: String, pose: String) -> int:
	if pose == "portrait" and stem.find("portrait") >= 0:
		return 3
	if pose == "idle" and stem.find("idle") >= 0:
		return 3
	if pose == "follow" and stem.find("follow_through") >= 0:
		return 3
	return 1


static func _walk_pngs(dir_path: String, found: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not name.begins_with("."):
			var full := dir_path.path_join(name)
			if dir.current_is_dir():
				if name != ".godot":
					_walk_pngs(full, found)
			elif name.to_lower().ends_with(".png") and not name.to_lower().ends_with(".import"):
				found.append(full)
		name = dir.get_next()
	dir.list_dir_end()
