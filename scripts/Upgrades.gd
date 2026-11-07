class_name Upgrades
extends RefCounted

# Every upgrade the run can offer.
# Rarity colors the card border. Effects rebuild from the kicker's base stats.

const BIG_LEG := "big_leg"
const STEADY_PLANT := "steady_plant"
const SWEET_SPOT := "sweet_spot"
const DEEP_BENCH := "deep_bench"
const HOT_STREAK := "hot_streak"
const MULLIGAN := "mulligan"
const FLAG_READER := "flag_reader"
const LOW_DRIVE := "low_drive"
const STORM_CHASER := "storm_chaser"
const LASER_LINE := "laser_line"
const WIND_BREAKER := "wind_breaker"
const THIN_AIR := "thin_air"
const ICE_VEINS := "ice_veins"
const WIDE_RIGHT_INSURANCE := "wide_right_insurance"
const PRACTICE_SWING := "practice_swing"
const SCOUTING_REPORT := "scouting_report"

const DEFS: Array = [
	{"id": BIG_LEG, "name": "Big Leg", "description": "Adds 6 yards of range per stack.", "rarity": "common", "max_stacks": 3},
	{"id": STEADY_PLANT, "name": "Steady Plant", "description": "Each stack multiplies both needle speeds by 0.85.", "rarity": "common", "max_stacks": 3},
	{"id": SWEET_SPOT, "name": "Sweet Spot", "description": "Each stack: perfect band +2 and good band +3.", "rarity": "common", "max_stacks": 3},
	{"id": DEEP_BENCH, "name": "Deep Bench", "description": "Each stack: attempt cap +1 and one more attempt.", "rarity": "common", "max_stacks": 2},
	{"id": HOT_STREAK, "name": "Hot Streak", "description": "Streak step becomes 0.5.", "rarity": "rare", "max_stacks": 1},
	{"id": MULLIGAN, "name": "Mulligan", "description": "Each stack: one free retake each quarter.", "rarity": "rare", "max_stacks": 2},
	{"id": FLAG_READER, "name": "Flag Reader", "description": "Shows mph, a direction arrow, and the crosswind and head-tail split.", "rarity": "rare", "max_stacks": 1},
	{"id": LOW_DRIVE, "name": "Low Drive", "description": "Each stack: wind drift and the wind range effect × 0.65, and range −3 yards.", "rarity": "common", "max_stacks": 2},
	{"id": STORM_CHASER, "name": "Storm Chaser", "description": "Each stack: on a make, Mult +0.1 per mph of crosswind.", "rarity": "rare", "max_stacks": 3},
	{"id": LASER_LINE, "name": "Laser Line", "description": "While aiming, a dotted preview of the first 40% of a perfect kick, with the wind curve.", "rarity": "rare", "max_stacks": 1},
	{"id": WIND_BREAKER, "name": "Wind Breaker", "description": "Each stack: sideways wind drift × 0.8.", "rarity": "rare", "max_stacks": 3},
	{"id": THIN_AIR, "name": "Thin Air", "description": "Each stack: +2 yards of range. Owning it multiplies tailwind range by 1.5.", "rarity": "common", "max_stacks": 3},
	{"id": ICE_VEINS, "name": "Ice Veins", "description": "No random error when power is in the red. Blocks the Iced needle fade.", "rarity": "rare", "max_stacks": 1},
	{"id": WIDE_RIGHT_INSURANCE, "name": "Wide Right Insurance", "description": "Once each quarter, a doink counts as good.", "rarity": "rare", "max_stacks": 1},
	{"id": PRACTICE_SWING, "name": "Practice Swing", "description": "Once each quarter, press P for a free practice kick.", "rarity": "rare", "max_stacks": 1},
	{"id": SCOUTING_REPORT, "name": "Scouting Report", "description": "Each stack: +1 reroll per run.", "rarity": "rare", "max_stacks": 2},
	{"id": GLASS_LEG, "name": "Glass Leg", "description": "Adds 8 yards of range. Attempt cap −1. Never drops the cap to 1.", "rarity": "risky", "max_stacks": 1},
	{"id": HERO_BALL, "name": "Hero Ball", "description": "Made kicks gain +1.0 Mult. The accuracy needle is 25% faster.", "rarity": "risky", "max_stacks": 1},
]

const GLASS_LEG := "glass_leg"
const HERO_BALL := "hero_ball"

# These are the only upgrades a Cursed card can double.
const DOUBLED_IDS: Array = [BIG_LEG, SWEET_SPOT, THIN_AIR, STORM_CHASER, LOW_DRIVE, WIND_BREAKER, SCOUTING_REPORT, DEEP_BENCH]


static func get_def(id: String) -> Dictionary:
	for item in DEFS:
		if str(item["id"]) == id:
			return item
	return {}


static func pickable_copies() -> int:
	var total := 0
	for item in DEFS:
		total += int(item["max_stacks"])
	return total


static func stack_label(id: String, stacks: int) -> String:
	var info := get_def(id)
	var note := effect_note(id, stacks)
	if note == "":
		return "%s %d/%d" % [str(info["name"]), stacks, int(info["max_stacks"])]
	return "%s %d/%d (%s)" % [str(info["name"]), stacks, int(info["max_stacks"]), note]


static func effect_note(id: String, stacks: int) -> String:
	var count := maxi(stacks, 0)
	if id == BIG_LEG:
		return "+%d yd" % (6 * count)
	if id == STEADY_PLANT:
		return "%d%% speed" % int(round(100.0 * pow(0.85, float(count))))
	if id == SWEET_SPOT:
		return "+%d perfect, +%d good" % [2 * count, 3 * count]
	if id == DEEP_BENCH:
		return "+%d cap" % count
	if id == HOT_STREAK:
		return "step 0.5"
	if id == MULLIGAN:
		return "+%d each quarter" % count
	if id == FLAG_READER:
		return "wind numbers"
	if id == LOW_DRIVE:
		return "drift ×%s, −%d yd" % [KickLogic.format_number(pow(0.65, float(count))), 3 * count]
	if id == STORM_CHASER:
		return "+0.1 × %d / mph" % count
	if id == LASER_LINE:
		return "aim line"
	if id == WIND_BREAKER:
		return "drift ×%s" % KickLogic.format_number(pow(0.8, float(count)))
	if id == THIN_AIR:
		return "+%d yd, tail ×1.5" % (2 * count)
	if id == ICE_VEINS:
		return "no red tip"
	if id == WIDE_RIGHT_INSURANCE:
		return "1 doink a quarter"
	if id == PRACTICE_SWING:
		return "1 practice a quarter"
	if id == SCOUTING_REPORT:
		return "+%d reroll" % count
	if id == GLASS_LEG:
		return "+8 yd, cap −1"
	if id == HERO_BALL:
		return "+1 Mult"
	return ""


static func eligible_ids(stacks: Dictionary, attempt_cap: int = 99) -> Array:
	var ids: Array = []
	for item in DEFS:
		var id := str(item["id"])
		if int(stacks.get(id, 0)) >= int(item["max_stacks"]):
			continue
		if id == GLASS_LEG and attempt_cap <= 2:
			continue
		ids.append(id)
	return ids


static func is_common(id: String) -> bool:
	return str(get_def(id).get("rarity", "")) == "common"


# The bigger numbers printed on a Cursed copy of this upgrade.
static func doubled_line(id: String) -> String:
	if id == BIG_LEG:
		return "+12 yd this copy."
	if id == SWEET_SPOT:
		return "Perfect +4, good +6."
	if id == THIN_AIR:
		return "+4 yd this copy."
	if id == STORM_CHASER:
		return "+0.2 Mult per mph of crosswind."
	if id == LOW_DRIVE:
		return "Drift ×0.65 twice, −6 yd."
	if id == WIND_BREAKER:
		return "Drift ×0.8 twice."
	if id == SCOUTING_REPORT:
		return "+2 rerolls."
	if id == DEEP_BENCH:
		return "Cap +2 and attempts +2."
	return "Double copy."


static func border_color(id: String, cursed: bool) -> Color:
	if cursed:
		return Color(0.62, 0.28, 0.9)
	var rarity := str(get_def(id).get("rarity", "common"))
	if rarity == "rare":
		return Color(0.25, 0.48, 0.95)
	if rarity == "risky":
		return Color(0.95, 0.48, 0.12)
	return Color(0.62, 0.62, 0.66)


# Up to 3 different upgrades, in random order. Never repeats one in the same offer.
static func draw_offer(eligible: Array, rng: RandomNumberGenerator) -> Array:
	var pool: Array = eligible.duplicate()
	var picked: Array = []
	while pool.size() > 0 and picked.size() < 3:
		var index := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[index])
		pool.remove_at(index)
	if picked.size() == 3 and not _any_common(picked):
		var commons: Array = []
		for id in eligible:
			if is_common(str(id)) and not picked.has(id):
				commons.append(id)
		if commons.size() > 0:
			picked[rng.randi_range(0, 2)] = commons[rng.randi_range(0, commons.size() - 1)]
	return picked


static func _any_common(ids: Array) -> bool:
	for id in ids:
		if is_common(str(id)):
			return true
	return false


# One stack. doubled is a Cursed copy: bigger numbers, still one stack toward the max.
static func apply(id: String, stats: KickerStats, doubled: bool = false) -> void:
	if id == BIG_LEG:
		stats.range_bonus += 12.0 if doubled else 6.0
	elif id == STEADY_PLANT:
		stats.power_speed *= 0.85
		stats.accuracy_speed *= 0.85
	elif id == SWEET_SPOT:
		stats.perfect_band += 4.0 if doubled else 2.0
		stats.good_band += 6.0 if doubled else 3.0
	elif id == DEEP_BENCH:
		var gain := 2 if doubled else 1
		stats.attempt_cap = mini(stats.attempt_cap + gain, KickConstants.ATTEMPT_CAP_MAX)
	elif id == HOT_STREAK:
		stats.streak_step = 0.5
	elif id == MULLIGAN:
		stats.mulligans_per_quarter += 1
	elif id == FLAG_READER:
		stats.flag_reader = true
	elif id == LOW_DRIVE:
		var times := 2 if doubled else 1
		stats.low_drive_stacks += times
		stats.range_bonus -= 3.0 * float(times)
	elif id == STORM_CHASER:
		stats.storm_chaser_stacks += 1
		stats.storm_per_mph += 0.2 if doubled else 0.1
	elif id == LASER_LINE:
		stats.laser_line = true
	elif id == WIND_BREAKER:
		stats.wind_breaker_stacks += 2 if doubled else 1
	elif id == THIN_AIR:
		stats.thin_air_stacks += 1
		stats.range_bonus += 4.0 if doubled else 2.0
	elif id == ICE_VEINS:
		stats.ice_veins = true
		stats.red_tip_noise = 0.0
	elif id == WIDE_RIGHT_INSURANCE:
		stats.insurance_per_quarter = 1
	elif id == PRACTICE_SWING:
		stats.practice_per_quarter = 1
	elif id == SCOUTING_REPORT:
		stats.rerolls_per_run += 2 if doubled else 1
	elif id == GLASS_LEG:
		stats.range_bonus += 8.0
		stats.attempt_cap = maxi(stats.attempt_cap - 1, 2)
		stats.glass_leg = true
	elif id == HERO_BALL:
		stats.accuracy_speed *= 1.25
		stats.hero_ball = true
