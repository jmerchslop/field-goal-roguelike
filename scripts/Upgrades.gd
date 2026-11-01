class_name Upgrades
extends RefCounted

# The upgrade list. Rarity is stored and not used yet: every eligible card is equally likely.

const BIG_LEG := "big_leg"
const STEADY_PLANT := "steady_plant"
const SWEET_SPOT := "sweet_spot"
const DEEP_BENCH := "deep_bench"
const HOT_STREAK := "hot_streak"
const MULLIGAN := "mulligan"

const DEFS: Array = [
	{"id": BIG_LEG, "name": "Big Leg", "description": "Adds 6 yards of range.", "rarity": "common", "max_stacks": 3},
	{"id": STEADY_PLANT, "name": "Steady Plant", "description": "Power needle rises at 85% speed.", "rarity": "common", "max_stacks": 3},
	{"id": SWEET_SPOT, "name": "Sweet Spot", "description": "Perfect band +2. Good band +3.", "rarity": "common", "max_stacks": 2},
	{"id": DEEP_BENCH, "name": "Deep Bench", "description": "Attempt cap +1 and one more attempt.", "rarity": "common", "max_stacks": 2},
	{"id": HOT_STREAK, "name": "Hot Streak", "description": "Streak step becomes 0.5.", "rarity": "common", "max_stacks": 1},
	{"id": MULLIGAN, "name": "Mulligan", "description": "One free retake each quarter.", "rarity": "common", "max_stacks": 2},
]


static func get_def(id: String) -> Dictionary:
	for item in DEFS:
		if str(item["id"]) == id:
			return item
	return {}


static func stack_label(id: String, stacks: int) -> String:
	var info := get_def(id)
	return "%s %d/%d" % [str(info["name"]), stacks, int(info["max_stacks"])]


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


static func apply(id: String, stats: KickerStats) -> void:
	if id == BIG_LEG:
		stats.range_bonus += 6.0
	elif id == STEADY_PLANT:
		stats.power_speed *= 0.85
	elif id == SWEET_SPOT:
		stats.perfect_band += 2.0
		stats.good_band += 3.0
	elif id == DEEP_BENCH:
		stats.attempt_cap = mini(stats.attempt_cap + 1, KickConstants.ATTEMPT_CAP_MAX)
	elif id == HOT_STREAK:
		stats.streak_step = 0.5
	elif id == MULLIGAN:
		stats.mulligans_per_quarter += 1
