class_name Upgrades
extends RefCounted

# Every upgrade the run can offer. Rarity is stored and not used yet.
# Effects are applied once per stack, from the kicker's base stats.

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
	{"id": HOT_STREAK, "name": "Hot Streak", "description": "Streak step becomes 0.5.", "rarity": "common", "max_stacks": 1},
	{"id": MULLIGAN, "name": "Mulligan", "description": "Each stack: one free retake each quarter.", "rarity": "common", "max_stacks": 2},
	{"id": FLAG_READER, "name": "Flag Reader", "description": "Shows mph, a direction arrow, and the crosswind and head-tail split.", "rarity": "common", "max_stacks": 1},
	{"id": LOW_DRIVE, "name": "Low Drive", "description": "Each stack: wind drift and the wind range effect × 0.65, and range −3 yards.", "rarity": "common", "max_stacks": 2},
	{"id": STORM_CHASER, "name": "Storm Chaser", "description": "Each stack: on a make, Mult +0.1 per mph of crosswind.", "rarity": "common", "max_stacks": 3},
	{"id": LASER_LINE, "name": "Laser Line", "description": "While aiming, a dotted preview of the first 40% of a perfect kick, with the wind curve.", "rarity": "common", "max_stacks": 1},
	{"id": WIND_BREAKER, "name": "Wind Breaker", "description": "Each stack: sideways wind drift × 0.8.", "rarity": "common", "max_stacks": 3},
	{"id": THIN_AIR, "name": "Thin Air", "description": "Each stack: +2 yards of range. Owning it multiplies tailwind range by 1.5.", "rarity": "common", "max_stacks": 3},
	{"id": ICE_VEINS, "name": "Ice Veins", "description": "No random error when power is in the red.", "rarity": "common", "max_stacks": 1},
	{"id": WIDE_RIGHT_INSURANCE, "name": "Wide Right Insurance", "description": "Once each quarter, a doink counts as good.", "rarity": "common", "max_stacks": 1},
	{"id": PRACTICE_SWING, "name": "Practice Swing", "description": "Once each quarter, press P for a free practice kick.", "rarity": "common", "max_stacks": 1},
	{"id": SCOUTING_REPORT, "name": "Scouting Report", "description": "Each stack: +1 reroll per run.", "rarity": "common", "max_stacks": 2},
]


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
	return ""


static func eligible_ids(stacks: Dictionary) -> Array:
	var ids: Array = []
	for item in DEFS:
		var id := str(item["id"])
		if int(stacks.get(id, 0)) < int(item["max_stacks"]):
			ids.append(id)
	return ids


# Up to 3 different upgrades, in random order. Never repeats one in the same offer.
static func draw_offer(eligible: Array, rng: RandomNumberGenerator) -> Array:
	var pool: Array = eligible.duplicate()
	var picked: Array = []
	while pool.size() > 0 and picked.size() < 3:
		var index := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[index])
		pool.remove_at(index)
	return picked


# One stack. The run calls this once per owned stack, starting from the kicker's base.
static func apply(id: String, stats: KickerStats) -> void:
	if id == BIG_LEG:
		stats.range_bonus += 6.0
	elif id == STEADY_PLANT:
		stats.power_speed *= 0.85
		stats.accuracy_speed *= 0.85
	elif id == SWEET_SPOT:
		stats.perfect_band += 2.0
		stats.good_band += 3.0
	elif id == DEEP_BENCH:
		stats.attempt_cap = mini(stats.attempt_cap + 1, KickConstants.ATTEMPT_CAP_MAX)
	elif id == HOT_STREAK:
		stats.streak_step = 0.5
	elif id == MULLIGAN:
		stats.mulligans_per_quarter += 1
	elif id == FLAG_READER:
		stats.flag_reader = true
	elif id == LOW_DRIVE:
		stats.low_drive_stacks += 1
		stats.range_bonus -= 3.0
	elif id == STORM_CHASER:
		stats.storm_chaser_stacks += 1
	elif id == LASER_LINE:
		stats.laser_line = true
	elif id == WIND_BREAKER:
		stats.wind_breaker_stacks += 1
	elif id == THIN_AIR:
		stats.thin_air_stacks += 1
		stats.range_bonus += 2.0
	elif id == ICE_VEINS:
		stats.ice_veins = true
		stats.red_tip_noise = 0.0
	elif id == WIDE_RIGHT_INSURANCE:
		stats.insurance_per_quarter = 1
	elif id == PRACTICE_SWING:
		stats.practice_per_quarter = 1
	elif id == SCOUTING_REPORT:
		stats.rerolls_per_run += 1
