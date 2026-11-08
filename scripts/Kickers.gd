class_name Kickers
extends RefCounted

# The two kickers. Adding a third one later means adding data here.
# Kick code never names a kicker. It only reads KickerStats and ball_type.
# A barn_burner ball multiplies sideways wind drift by 0.7. The kick reads ball_type.

const BIG_BRUCE := "big_bruce"
const WALK_ON := "walk_on"

const ALL: Array = [
	{
		"id": BIG_BRUCE,
		"name": "Big Bruce",
		"lore": "A farmer who's been booting fence posts loose since he was nine. He can kick it a mile. Where it lands is between him and the Lord.",
		"excels": "Huge leg.",
		"downside": "Shaky accuracy.",
		"ball_name": "Barn Burner",
		"ball_description": "A post hit becomes a make when you still have 10 yards of range left.",
		"ball_type": "barn_burner",
		"color": Color(0.55, 0.09, 0.08),
		"shape": "square",
		"portrait_path": "res://art/kickers/big_bruce.png",
	},
	{
		"id": WALK_ON,
		"name": "The Walk-On",
		"lore": "Nobody recruited him. He showed up to tryouts in borrowed cleats and never left.",
		"excels": "No weaknesses.",
		"downside": "No standout strength.",
		"ball_name": "Team-Issue",
		"ball_description": "A normal ball. No special trick.",
		"ball_type": "standard",
		"color": Color(0.22, 0.38, 0.82),
		"shape": "circle",
		"portrait_path": "res://art/kickers/walk_on.png",
	},
]


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
	if id == BIG_BRUCE:
		stats.range_per_power = 0.49
		stats.red_tip_start = 90.0
		stats.red_tip_noise = 7.0
		stats.accuracy_speed *= 1.1
	elif id == WALK_ON:
		stats.rerolls_per_run = 2
