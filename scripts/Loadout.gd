class_name Loadout
extends RefCounted

# The pieces a kicker can hold during one run.
# Three equipment slots, two perks, two curses. Nothing here is saved after the run.

const CLEATS := "cleats"
const HELMET := "helmet"
const GLOVES := "gloves"
const PERK := "perk"
const CURSE := "curse"
const EQUIPMENT := "equipment"

const CANNON := "cannon_cleats"
const PINPOINT := "pinpoint_cleats"
const ANCHOR := "anchor_cleats"
const STICKER := "sticker_cleats"
const WIND_VISOR := "wind_visor"
const ICE_CAGE := "ice_cage"
const SCOUT_LID := "scout_lid"
const DOINK_CAP := "doink_cap"
const IRON_GRIP := "iron_grip"
const REPLAY_GLOVES := "replay_gloves"
const HIGH_AIR := "high_air"
const WEATHER_WRAPS := "weather_wraps"
const DEEP_BENCH := "deep_bench"
const HOT_STREAK := "hot_streak"
const STORM_CHASER := "storm_chaser"
const HERO_BALL := "hero_ball"
const GLASS_LEG := "glass_leg"
const TWO_MINUTE := "two_minute_drill"
const ICED := "iced"
const SHANKY := "shanky_cleats"
const HEAVY := "heavy_ball"
const HOWLING := "howling_wind"
const SHAKY := "shaky_arrow"
const NARROW := "narrow_posts"
const STONE := "stone_toe"
const TIGHT := "tight_window"

const CLEAT_IDS: Array = [CANNON, PINPOINT, ANCHOR, STICKER]
const HELMET_IDS: Array = [WIND_VISOR, ICE_CAGE, SCOUT_LID, DOINK_CAP]
const GLOVE_IDS: Array = [IRON_GRIP, REPLAY_GLOVES, HIGH_AIR, WEATHER_WRAPS]
const PERK_IDS: Array = [DEEP_BENCH, HOT_STREAK, STORM_CHASER, HERO_BALL, GLASS_LEG, TWO_MINUTE]
const CURSE_IDS: Array = [ICED, SHANKY, HEAVY, HOWLING, SHAKY, NARROW, STONE, TIGHT]

const _ROMAN: Array = ["", "I", "II", "III", "IV", "V", "VI"]


static func rank_label(rank: int) -> String:
	var index := clampi(rank, 0, 6)
	return str(_ROMAN[index])


static func slot_of(id: String) -> String:
	if CLEAT_IDS.has(id):
		return CLEATS
	if HELMET_IDS.has(id):
		return HELMET
	if GLOVE_IDS.has(id):
		return GLOVES
	if PERK_IDS.has(id):
		return PERK
	if CURSE_IDS.has(id):
		return CURSE
	return ""


static func kind_of(id: String) -> String:
	var slot := slot_of(id)
	if slot == PERK:
		return PERK
	if slot == CURSE:
		return CURSE
	if slot == "":
		return ""
	return EQUIPMENT


static func max_rank(id: String) -> int:
	if PERK_IDS.has(id):
		return 3
	if CURSE_IDS.has(id):
		return 1
	if slot_of(id) == "":
		return 0
	return 6


static func type_label(slot: String) -> String:
	if slot == CLEATS:
		return "CLEATS"
	if slot == HELMET:
		return "HELMET"
	if slot == GLOVES:
		return "GLOVES"
	if slot == PERK:
		return "PERK"
	if slot == CURSE:
		return "CURSE"
	return ""


static func piece_name(id: String) -> String:
	match id:
		CANNON:
			return "Cannon Cleats"
		PINPOINT:
			return "Pinpoint Cleats"
		ANCHOR:
			return "Anchor Cleats"
		STICKER:
			return "Sticker Cleats"
		WIND_VISOR:
			return "Wind Visor"
		ICE_CAGE:
			return "Ice Cage"
		SCOUT_LID:
			return "Scout Lid"
		DOINK_CAP:
			return "Doink Cap"
		IRON_GRIP:
			return "Iron Grip"
		REPLAY_GLOVES:
			return "Replay Gloves"
		HIGH_AIR:
			return "High-Air Gloves"
		WEATHER_WRAPS:
			return "Weather Wraps"
		DEEP_BENCH:
			return "Deep Bench"
		HOT_STREAK:
			return "Hot Streak"
		STORM_CHASER:
			return "Storm Chaser"
		HERO_BALL:
			return "Hero Ball"
		GLASS_LEG:
			return "Glass Leg"
		TWO_MINUTE:
			return "Two-Minute Drill"
		ICED:
			return "Iced"
		SHANKY:
			return "Shanky Cleats"
		HEAVY:
			return "Heavy Ball"
		HOWLING:
			return "Howling Wind"
		SHAKY:
			return "Shaky Arrow"
		NARROW:
			return "Narrow Posts"
		STONE:
			return "Stone Toe"
		TIGHT:
			return "Tight Window"
	return id


static func effect_line(id: String, rank: int) -> String:
	match id:
		CANNON:
			return "+%d yd" % (6 * rank)
		PINPOINT:
			return "PERFECT +%d, good +%d" % [2 * rank, 3 * rank]
		ANCHOR:
			return "Needles ×%s" % KickLogic.format_number(pow(0.85, float(rank)))
		STICKER:
			return "Drift ×%s" % KickLogic.format_number(pow(0.80, float(rank)))
		WIND_VISOR:
			if rank <= 1:
				return "Shows wind mph and an arrow"
			if rank == 2:
				return "Also a dotted path for 40% of the flight"
			if rank == 3:
				return "The path shows the full flight"
			if rank == 4:
				return "Also previews wind for the next 3 kicks"
			if rank == 5:
				return "Also previews wind for the next 5 kicks"
			return "Also previews wind for the next 7 kicks"
		ICE_CAGE:
			if rank <= 1:
				return "No red-tip penalty. Immune to Iced."
			if rank == 2:
				return "Also accuracy needle ×0.90"
			if rank == 3:
				return "Also PERFECT +1"
			if rank == 4:
				return "Also good +2"
			if rank == 5:
				return "PERFECT +2 total"
			return "Good +4 total"
		SCOUT_LID:
			if rank <= 3:
				return "+%d reroll" % rank
			if rank == 4:
				return "+3 rerolls, and one Practice Swing a quarter"
			if rank == 5:
				return "+4 rerolls, and one Practice Swing a quarter"
			return "+5 rerolls, and two Practice Swings a quarter"
		DOINK_CAP:
			if rank >= 6:
				return "5 doink-to-good a quarter, unused carry (max 5)"
			return "%d doink-to-good a quarter" % rank
		IRON_GRIP:
			if rank <= 2:
				return "Red-tip noise −%d" % (2 * rank)
			if rank == 3:
				return "Noise −4 (min ±1), red tip 3 later"
			if rank == 4:
				return "Noise −4 (min ±1), red tip 6 later"
			if rank == 5:
				return "Noise −4 (min ±1), red tip 9 later"
			return "Red tip never triggers"
		REPLAY_GLOVES:
			if rank >= 6:
				return "5 practice swings, unused carry (max 5)"
			return "%d practice swing a quarter" % rank
		HIGH_AIR:
			return "+%d yd, tailwind range ×1.5" % (2 * rank)
		WEATHER_WRAPS:
			if rank <= 1:
				return "Rain, snow, and mud penalties cut in half"
			if rank == 2:
				return "Rain, snow, and mud penalties ignored"
			if rank == 3:
				return "Also ignores Monsoon's rain and mud"
			if rank == 4:
				return "Penalties ignored, +2 yd unless CLEAR"
			if rank == 5:
				return "Penalties ignored, +4 yd unless CLEAR"
			return "Penalties ignored, +6 yd unless CLEAR"
		DEEP_BENCH:
			if rank >= 3:
				return "Cap stays. +1 attempt now and each quarter if below cap"
			return "Attempt cap +%d and attempts +%d" % [rank, rank]
		HOT_STREAK:
			if rank <= 1:
				return "Streak step +0.5"
			if rank == 2:
				return "Streak step +0.75"
			return "Streak step +1.0"
		STORM_CHASER:
			if rank <= 1:
				return "+0.2 Mult per mph of crosswind"
			if rank == 2:
				return "+0.4 Mult per mph of crosswind"
			return "+0.6 Mult per mph of crosswind"
		HERO_BALL:
			if rank <= 1:
				return "+1.0 Mult, both needles ×0.80"
			if rank == 2:
				return "+1.5 Mult, both needles ×0.80"
			return "+2.0 Mult, both needles ×0.80"
		GLASS_LEG:
			if rank <= 1:
				return "+8 yd, attempt cap −1"
			if rank == 2:
				return "+16 yd total, no extra cap loss"
			return "+24 yd total, no extra cap loss"
		TWO_MINUTE:
			if rank <= 1:
				return "Boss kicks +0.5 Mult, on top of ×1.5"
			if rank == 2:
				return "Boss kicks +1.0 Mult, on top of ×1.5"
			return "Boss kicks +1.5 Mult, on top of ×1.5"
		ICED:
			return "Down: meter hides 0.4s after Space. Up: +0.5 Mult"
		SHANKY:
			return "Down: accuracy error ×1.5. Up: +0.5 Mult"
		HEAVY:
			return "Down: −4 yd. Up: accuracy error ×0.85"
		HOWLING:
			return "Down: wind ×1.5. Up: equipment and perks ×1.15"
		SHAKY:
			return "Down: aim sways ±3°. Up: +6 yd"
		NARROW:
			return "Down: posts 5.17 yd. Up: +0.5 Mult"
		STONE:
			return "Down: power needle ×1.20. Up: +6 yd"
		TIGHT:
			return "Down: PERFECT and good −2. Up: +0.5 Mult"
	return ""


static func card_title(id: String, rank: int) -> String:
	var name := piece_name(id)
	if CURSE_IDS.has(id):
		return name
	var roman := rank_label(rank)
	if roman == "":
		return name
	return "%s %s" % [name, roman]


# A factor like 0.85 becomes a little stronger: the gap from 1.0 grows by 15%.
static func boost_factor(factor: float) -> float:
	return 1.0 - (1.0 - factor) * 1.15


static func empty_state() -> Dictionary:
	return {
		"cleats_id": "",
		"cleats_rank": 0,
		"helmet_id": "",
		"helmet_rank": 0,
		"gloves_id": "",
		"gloves_rank": 0,
		"perks": [],
		"curses": [],
	}


static func _perk_rank(state: Dictionary, id: String) -> int:
	for item in state.get("perks", []):
		if str(item.get("id", "")) == id:
			return int(item.get("rank", 0))
	return 0


static func legal_equipment(state: Dictionary) -> Array:
	var cards: Array = []
	var slots := [
		[CLEATS, str(state.get("cleats_id", "")), int(state.get("cleats_rank", 0)), CLEAT_IDS],
		[HELMET, str(state.get("helmet_id", "")), int(state.get("helmet_rank", 0)), HELMET_IDS],
		[GLOVES, str(state.get("gloves_id", "")), int(state.get("gloves_rank", 0)), GLOVE_IDS],
	]
	for slot in slots:
		var slot_name := str(slot[0])
		var owned_id := str(slot[1])
		var rank := int(slot[2])
		var pool: Array = slot[3]
		if owned_id == "":
			for id in pool:
				cards.append(_card(EQUIPMENT, slot_name, str(id), 1))
		elif rank < max_rank(owned_id):
			cards.append(_card(EQUIPMENT, slot_name, owned_id, rank + 1))
	return cards


static func legal_perks(state: Dictionary, attempt_cap: int) -> Array:
	var cards: Array = []
	var owned: Array = state.get("perks", [])
	for id in PERK_IDS:
		if id == GLASS_LEG and attempt_cap <= 2 and _perk_rank(state, str(id)) == 0:
			continue
		var have := _perk_rank(state, str(id))
		if have == 0:
			if owned.size() < 2:
				cards.append(_card(PERK, PERK, str(id), 1))
		elif have < max_rank(str(id)):
			cards.append(_card(PERK, PERK, str(id), have + 1))
	return cards


static func legal_curses(state: Dictionary) -> Array:
	var owned: Array = state.get("curses", [])
	if owned.size() >= 2:
		return []
	var blocked_ice := str(state.get("helmet_id", "")) == ICE_CAGE
	var cards: Array = []
	for id in CURSE_IDS:
		if owned.has(id):
			continue
		if id == ICED and blocked_ice:
			continue
		cards.append(_card(CURSE, CURSE, str(id), 1))
	return cards


static func draw_offer(state: Dictionary, attempt_cap: int, rng: RandomNumberGenerator) -> Array:
	var cards: Array = []
	var equip := legal_equipment(state)
	if equip.size() > 0:
		var index := rng.randi_range(0, equip.size() - 1)
		cards.append(equip[index])
		equip.remove_at(index)
	var pool: Array = []
	pool.append_array(legal_perks(state, attempt_cap))
	pool.append_array(legal_curses(state))
	_fill_offer(cards, pool, rng, true)
	# Perks and curses can run out while equipment ranks are still legal.
	if cards.size() < 3 and equip.size() > 0:
		_fill_offer(cards, equip, rng, false)
	return cards


static func _fill_offer(cards: Array, pool: Array, rng: RandomNumberGenerator, limit_curses: bool) -> void:
	var used_curse := false
	for have in cards:
		if str(have.get("kind", "")) == CURSE:
			used_curse = true
	var guard := 0
	while cards.size() < 3 and pool.size() > 0 and guard < 40:
		guard += 1
		var index := rng.randi_range(0, pool.size() - 1)
		var card: Dictionary = pool[index]
		pool.remove_at(index)
		if limit_curses and str(card.get("kind", "")) == CURSE:
			if used_curse:
				continue
			used_curse = true
		var duplicate := false
		for have in cards:
			if str(have.get("id", "")) == str(card.get("id", "")):
				duplicate = true
		if duplicate:
			continue
		cards.append(card)


static func _card(kind: String, slot: String, id: String, rank: int) -> Dictionary:
	return {"kind": kind, "slot": slot, "id": id, "rank": rank}


# stats already has the kicker's base kit. This adds the owned pieces.
# howling makes equipment and perk numbers 15% stronger. Curse upsides are not included.
static func apply(stats: KickerStats, state: Dictionary, howling: bool) -> void:
	var range_add := 0.0
	var perfect_add := 0.0
	var good_add := 0.0
	var power_mul := 1.0
	var accuracy_mul := 1.0
	var drift_mul := 1.0
	var cleats := str(state.get("cleats_id", ""))
	var cleat_rank := int(state.get("cleats_rank", 0))
	var helmet := str(state.get("helmet_id", ""))
	var helmet_rank := int(state.get("helmet_rank", 0))
	var gloves := str(state.get("gloves_id", ""))
	var glove_rank := int(state.get("gloves_rank", 0))
	if cleats == CANNON:
		range_add += 6.0 * float(cleat_rank)
	elif cleats == PINPOINT:
		perfect_add += 2.0 * float(cleat_rank)
		good_add += 3.0 * float(cleat_rank)
	elif cleats == ANCHOR:
		var factor := pow(0.85, float(cleat_rank))
		if howling:
			factor = boost_factor(factor)
		power_mul *= factor
		accuracy_mul *= factor
	elif cleats == STICKER:
		var factor := pow(0.80, float(cleat_rank))
		if howling:
			factor = boost_factor(factor)
		drift_mul *= factor
	if helmet == WIND_VISOR:
		stats.flag_reader = helmet_rank >= 1
		stats.laser_line = helmet_rank >= 2
		stats.laser_full = helmet_rank >= 3
		stats.wind_preview = helmet_rank >= 4
		if helmet_rank >= 6:
			stats.wind_preview_count = 7
		elif helmet_rank >= 5:
			stats.wind_preview_count = 5
		elif helmet_rank >= 4:
			stats.wind_preview_count = 3
	elif helmet == ICE_CAGE:
		stats.ice_cage = true
		stats.ice_veins = true
		if helmet_rank >= 2:
			var factor := 0.90
			if howling:
				factor = boost_factor(factor)
			accuracy_mul *= factor
		if helmet_rank >= 3:
			perfect_add += 1.0
		if helmet_rank >= 5:
			perfect_add += 1.0
		if helmet_rank >= 4:
			good_add += 2.0
		if helmet_rank >= 6:
			good_add += 2.0
	elif helmet == SCOUT_LID:
		var extra := mini(helmet_rank, 3)
		if helmet_rank == 5:
			extra = 4
		elif helmet_rank >= 6:
			extra = 5
		stats.rerolls_per_run += extra
		if helmet_rank >= 4:
			stats.practice_per_quarter += 1
		if helmet_rank >= 6:
			stats.practice_per_quarter += 1
	elif helmet == DOINK_CAP:
		stats.doink_per_quarter = mini(helmet_rank, 5)
		stats.doink_carry = helmet_rank >= 6
	if gloves == IRON_GRIP:
		var cut := 2.0 * float(mini(glove_rank, 2))
		stats.red_tip_noise = maxf(stats.red_tip_noise - cut, 1.0)
		if glove_rank >= 3:
			stats.red_tip_start += 3.0
		if glove_rank >= 4:
			stats.red_tip_start += 3.0
		if glove_rank >= 5:
			stats.red_tip_start += 3.0
		stats.red_tip_off = glove_rank >= 6
	elif gloves == REPLAY_GLOVES:
		stats.practice_per_quarter += mini(glove_rank, 5)
		stats.practice_carry = glove_rank >= 6
	elif gloves == HIGH_AIR:
		range_add += 2.0 * float(glove_rank)
		stats.thin_air = true
	elif gloves == WEATHER_WRAPS:
		if glove_rank <= 1:
			stats.weather_cut = 1
		elif glove_rank == 2:
			stats.weather_cut = 2
		else:
			stats.weather_cut = 3
		if glove_rank >= 4:
			stats.wraps_yards = 2.0 * float(glove_rank - 3)
	var hero_add := 0.0
	var storm := 0.0
	var drill := 0.0
	for perk_id in PERK_IDS:
		var id := str(perk_id)
		var rank := _perk_rank(state, id)
		if rank <= 0:
			continue
		if id == DEEP_BENCH:
			var cap_ranks := mini(rank, 2)
			stats.attempt_cap = mini(stats.attempt_cap + cap_ranks, KickConstants.ATTEMPT_CAP_MAX)
			stats.bench_spare = rank >= 3
		elif id == HOT_STREAK:
			if rank <= 1:
				stats.streak_step = 0.5
			elif rank == 2:
				stats.streak_step = 0.75
			else:
				stats.streak_step = 1.0
		elif id == STORM_CHASER:
			storm += 0.2 * float(rank)
		elif id == HERO_BALL:
			if rank <= 1:
				hero_add += 1.0
			elif rank == 2:
				hero_add += 1.5
			else:
				hero_add += 2.0
			var factor := 0.80
			if howling:
				factor = boost_factor(factor)
			power_mul *= factor
			accuracy_mul *= factor
		elif id == GLASS_LEG:
			range_add += 8.0 * float(rank)
			stats.attempt_cap = maxi(stats.attempt_cap - 1, 1)
		elif id == TWO_MINUTE:
			drill += 0.5 * float(rank)
	if howling:
		range_add *= 1.15
		perfect_add *= 1.15
		good_add *= 1.15
		hero_add *= 1.15
		storm *= 1.15
		drill *= 1.15
	var curse_range := 0.0
	var curse_mult := 0.0
	var angle := 1.0
	var curses: Array = state.get("curses", [])
	if curses.has(ICED):
		curse_mult += 0.5
		stats.hide_meter = true
	if curses.has(SHANKY):
		angle *= 1.5
		curse_mult += 0.5
	if curses.has(HEAVY):
		angle *= 0.85
		stats.heavy_ball = true
	if curses.has(HOWLING):
		stats.howling = true
	if curses.has(SHAKY):
		curse_range += 6.0
		stats.shaky = true
	if curses.has(NARROW):
		curse_mult += 0.5
		stats.narrow_posts = true
	if curses.has(STONE):
		curse_range += 6.0
		power_mul *= 1.20
	if curses.has(TIGHT):
		curse_mult += 0.5
		stats.tight_window = true
	stats.range_bonus += range_add + curse_range
	stats.perfect_band += perfect_add
	stats.good_band += good_add
	if stats.tight_window:
		stats.perfect_band = maxf(stats.perfect_band - 2.0, 1.0)
		stats.good_band = maxf(stats.good_band - 2.0, 1.0)
	stats.power_speed *= power_mul
	stats.accuracy_speed *= accuracy_mul
	stats.drift_factor = drift_mul
	stats.hero_mult = hero_add
	stats.storm_per_mph = storm
	stats.drill_mult = drill
	stats.curse_mult = curse_mult
	stats.angle_scale = angle
	stats.attempt_cap = clampi(stats.attempt_cap, 1, KickConstants.ATTEMPT_CAP_MAX)


const _SPRITE_DIR := "res://art/loadout/"

# File names for the sprites Jordan provided. Missing items stay "".
static func sprite_path(id: String) -> String:
	var file := ""
	match id:
		SCOUT_LID:
			file = "scout_lid.png"
		DOINK_CAP:
			file = "doink_cap.png"
		DEEP_BENCH:
			file = "deep_bench.png"
		HOT_STREAK:
			file = "hot_streak.png"
		STORM_CHASER:
			file = "storm_chaser.png"
		HERO_BALL:
			file = "hero_ball.png"
		GLASS_LEG:
			file = "glass_leg.png"
		TWO_MINUTE:
			file = "two_minute_drill.png"
		ICED:
			file = "iced.png"
		SHANKY:
			file = "shanky_cleats.png"
		HEAVY:
			file = "heavy_ball.png"
		HOWLING:
			file = "howling_wind.png"
		SHAKY:
			file = "shaky_arrow.png"
		NARROW:
			file = "narrow_posts.png"
		STONE:
			file = "stone_toe.png"
		TIGHT:
			file = "tight_window.png"
	if file == "":
		return ""
	var path := _SPRITE_DIR + file
	if ResourceLoader.exists(path):
		return path
	return ""


static func empty_slot_path(slot: String) -> String:
	var file := ""
	if slot == CLEATS:
		file = "empty_cleats.png"
	elif slot == HELMET:
		file = "empty_helmet.png"
	elif slot == GLOVES:
		file = "empty_gloves.png"
	elif slot == CURSE:
		file = "empty_curse.png"
	if file == "":
		return ""
	var path := _SPRITE_DIR + file
	if ResourceLoader.exists(path):
		return path
	return ""


# Equipment shows I–VI. Perks show I–III. Curses and empty slots show nothing.
static func rank_badge(id: String, rank: int) -> String:
	if id == "" or rank <= 0:
		return ""
	if CURSE_IDS.has(id):
		return ""
	return rank_label(rank)
