class_name Vitamins
extends RefCounted

# One-use shop items. They never take an equipment, perk, or curse slot.
# Missing art stays a colored placeholder. A later file such as protein_shake.png is picked up by name.

const PROTEIN := "protein_shake"
const MAGNESIUM := "magnesium"
const OMEGA := "omega_3"
const ELECTROLYTE := "electrolyte_tabs"
const VITAMIN_D := "vitamin_d"
const PREWORKOUT := "pre_workout"
const ZINC := "zinc"
const LUTEIN := "lutein"
const PICKLE := "pickle_juice"
const TART := "tart_cherry"
const B12 := "b12_shot"

const B12_PRICE := 7
const REROLL_START := 2

const ALL: Array = [
	PROTEIN, MAGNESIUM, OMEGA, ELECTROLYTE, VITAMIN_D,
	PREWORKOUT, ZINC, LUTEIN, PICKLE, TART,
]

const _DIR := "res://art/vitamins/"


static func piece_name(id: String) -> String:
	match id:
		PROTEIN:
			return "Protein Shake"
		MAGNESIUM:
			return "Magnesium"
		OMEGA:
			return "Omega-3"
		ELECTROLYTE:
			return "Electrolyte Tabs"
		VITAMIN_D:
			return "Vitamin D"
		PREWORKOUT:
			return "Pre-Workout"
		ZINC:
			return "Zinc"
		LUTEIN:
			return "Lutein"
		PICKLE:
			return "Pickle Juice"
		TART:
			return "Tart Cherry"
		B12:
			return "B12 Shot"
	return id


static func price(id: String) -> int:
	match id:
		PROTEIN, MAGNESIUM, PREWORKOUT:
			return 4
		OMEGA, VITAMIN_D, ZINC, LUTEIN, PICKLE:
			return 5
		ELECTROLYTE, TART:
			return 6
		B12:
			return B12_PRICE
	return 0


static func sale_price(id: String) -> int:
	return int(floor(float(price(id)) / 2.0))


static func effect_line(id: String) -> String:
	match id:
		PROTEIN:
			return "+6 yd this kick"
		MAGNESIUM:
			return "Needles ×0.70 this kick"
		OMEGA:
			return "GOOD wipes the aim error. No +5 PERFECT bonus. PERFECT cash still pays."
		ELECTROLYTE:
			return "A miss keeps the attempt"
		VITAMIN_D:
			return "Ignore rain, snow, and mud"
		PREWORKOUT:
			return "+0.5 Mult if this kick is made"
		ZINC:
			return "Reroll this kick's wind and weather"
		LUTEIN:
			return "Wind numbers and a full dotted path"
		PICKLE:
			return "Sideways wind drift ×0.5"
		TART:
			return "Remove one curse"
		B12:
			return "+1 attempt"
	return ""


static func bottle_color(id: String) -> Color:
	match id:
		PROTEIN:
			return Color(0.86, 0.45, 0.62)
		MAGNESIUM:
			return Color(0.45, 0.78, 0.46)
		OMEGA:
			return Color(0.92, 0.72, 0.28)
		ELECTROLYTE:
			return Color(0.35, 0.62, 0.95)
		VITAMIN_D:
			return Color(0.98, 0.86, 0.28)
		PREWORKOUT:
			return Color(0.95, 0.48, 0.18)
		ZINC:
			return Color(0.72, 0.74, 0.78)
		LUTEIN:
			return Color(0.92, 0.55, 0.18)
		PICKLE:
			return Color(0.45, 0.62, 0.22)
		TART:
			return Color(0.72, 0.12, 0.28)
		B12:
			return Color(0.95, 0.9, 0.55)
	return Color(0.7, 0.7, 0.7)


static func sprite_path(id: String) -> String:
	if id == "":
		return ""
	var path := _DIR + id + ".png"
	if ResourceLoader.exists(path):
		return path
	return ""


static func draw_three(rng: RandomNumberGenerator, avoid: Array = []) -> Array:
	var blocked := {}
	for id in avoid:
		var name := str(id)
		if name != "":
			blocked[name] = true
	var pool: Array = []
	for id in ALL:
		if not blocked.has(str(id)):
			pool.append(id)
	# Fewer than 3 other vitamins: a previous one may come back in a full redraw.
	if pool.size() < 3:
		pool = ALL.duplicate()
	var picks: Array = []
	while picks.size() < 3 and pool.size() > 0:
		var index := rng.randi_range(0, pool.size() - 1)
		picks.append(pool[index])
		pool.remove_at(index)
	return picks
