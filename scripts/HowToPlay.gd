class_name HowToPlay
extends RefCounted

# Page data for the pause-menu book. Drawing stays in hud.gd.
# UI5B appends pages to PAGE_IDS. Nothing else should hard-code the count.

const PAGE_IDS: Array[String] = ["kick", "wind", "bosses5", "bosses10", "rings", "bonuses"]

const KICK_STEPS: Array[Dictionary] = [
	{"label": "1 AIM", "body": "Hold {aim_left} or {aim_right} to swing the aim arrow. Aim into the wind."},
	{"label": "2 START", "body": "Press {confirm}. The needle starts climbing the left side of the meter."},
	{"label": "3 POWER", "body": "Press {confirm} again to lock power. Higher goes farther. The red tip near MAX goes farthest, but it adds a random hook."},
	{"label": "4 ACCURACY", "body": "The needle drops down the right side. Press {confirm} in the green PERFECT wedge to kick it straight. Gold GOOD is close. Red hooks wide."},
]

const KICK_FOOTER := "Clear the crossbar between the uprights to score. A miss costs an attempt."
const KICK_CAPTION := "Left side: power. Right side: accuracy."

const WIND_MPH: Array[int] = [0, 5, 12, 20]
const WIND_RANGES: Array[String] = ["0 MPH", "1 TO 7 MPH", "8 TO 15 MPH", "16+ MPH"]
const WIND_LINES: Array[String] = [
	"The red ribbons on top of the uprights show the wind. They lean the way it's blowing.",
	"The farther they lean, the harder it blows and the more your kick drifts that way. Aim into it.",
	"Wind at your back adds distance. Wind in your face takes it away. The kick bug's wind word and arrow say the same thing.",
]


static func page_count() -> int:
	return PAGE_IDS.size()


static func page_id(index: int) -> String:
	if index < 0 or index >= PAGE_IDS.size():
		return ""
	return PAGE_IDS[index]


static func title(id: String) -> String:
	if id == "kick":
		return "KICK AND AIM"
	if id == "wind":
		return "WIND CLUES"
	if id == "bosses5":
		return "KICK 5 BOSSES"
	if id == "bosses10":
		return "KICK 10 BOSSES"
	if id == "rings":
		return "RING BONUSES"
	if id == "bonuses":
		return "MORE BONUSES"
	return ""


static func intro(id: String) -> String:
	if id == "bosses5":
		return "Kick 5 is a boss kick. It's one of these. A made boss kick scores x{boss_mult} and pays $2 extra."
	if id == "bosses10":
		return "Kick 10 is Big Game or Moving Posts. In Endless, bosses keep coming and kick 100 is always Big Game."
	if id == "rings":
		return "Rings hang on the posts. Thread one for a bonus."
	if id == "bonuses":
		return "Extra chances to score big."
	return ""


static func footer(id: String) -> String:
	if id == "bosses10":
		return "Beat a boss: x{boss_mult} score and $2 extra on the make."
	return ""


static func entries(id: String) -> Array:
	if id == "bosses5":
		return [
			_entry(RunLogic.ICED, "Snow on the field. The accuracy needle fades out right after it starts down and comes back by halfway. Press by feel.", "iced"),
			_entry(RunLogic.SQUEEZE, "The uprights pull in from {normal_gap} to {squeeze} yards apart. Less room for a hook.", "narrow"),
			_entry(RunLogic.MONSOON, "Rain and mud at once. Rain makes both needles {rain_pct}% faster. Mud makes the power needle shake as it climbs.", "monsoon"),
			_entry(RunLogic.LIGHTS, "A night kick under the floodlights. Both needles run {lights_pct}% faster.", "lights"),
			_entry(RunLogic.CLOCK, "{clock} seconds to start your kick. It counts down {count_list}. At 0 the buzzer sounds and the meter starts without you.", "clock"),
		]
	if id == "bosses10":
		return [
			_entry(RunLogic.BIG_GAME, "Meter upgrades off. Your needles go back to your kicker's normal speed and accuracy. Gear help on the meter doesn't count.", "big_game"),
			_entry(RunLogic.MOVING, "The posts slide {swing} yards side to side every {period} seconds. Time the kick for where they'll be.", "moving"),
		]
	if id == "rings":
		return [
			_entry("BONUS RING", "Kick 7 (Endless 17, 47, 77, 97). A gold ring hangs outside an upright. Go wide through it: it counts as a miss, but you get a bonus gear pick.", "bonus_coin"),
			_entry("INNER RING", "A small cyan ring just inside an upright. Make the kick through it to double your ring Mult, up to x{ring_cap}, and get $2. A miss resets it.", "inner_coin"),
			_entry("ON FIRE", "Make {fire_heat} in a row and a later kick goes ON FIRE. The inner ring grows and pays $2 more.", "on_fire"),
		]
	if id == "bonuses":
		return [
			_entry("LONG OR SAFE", "Some kicks offer a choice. SAFE is normal. LONG is +{long} yards for double Mult. BOMB is +{bomb} yards for a bonus gear pick.", "choice"),
			_entry("PERFECT", "Lock accuracy in the green wedge for PERFECT: +{perfect} points before Mult and $1 extra.", "perfect"),
			_entry("LUCKY", "Luck from gear gives a DOINK off the post a chance to go in anyway. It also brings better gear and more LONG OR SAFE kicks.", "lucky"),
		]
	return []


static func row_counts(id: String) -> Array:
	if id == "bosses5":
		return [3, 2]
	if id == "bosses10":
		return [2]
	if id == "rings" or id == "bonuses":
		return [3]
	return []


static func cells(id: String) -> Array:
	var made: Array = []
	var rows: Array = row_counts(id)
	var tops: Array[float] = [172.0, 368.0]
	for row in rows.size():
		var count := int(rows[row])
		var x := 464.0
		if count >= 3:
			x = 112.0
		elif count == 2:
			x = 288.0
		for i in count:
			made.append(Rect2(x + 352.0 * float(i), tops[row], 352.0, 188.0))
	return made


static func number_values() -> Dictionary:
	var rain := float(RunLogic.weather_kick_flags(RunLogic.MONSOON, 0)["rain_scale"])
	var parts: PackedStringArray = PackedStringArray()
	var second := int(round(RunLogic.CLOCK_SEC))
	while second >= 1:
		parts.append(str(second))
		second -= 1
	return {
		"boss_mult": String.num(KickConstants.BOSS_MULTIPLIER, 1),
		"normal_gap": String.num(2.0 * KickConstants.POST_HALF_GAP_YARDS, 2),
		"squeeze": String.num(RunLogic.SQUEEZE_WIDTH, 2),
		"rain_pct": str(int(round((rain - 1.0) * 100.0))),
		"lights_pct": str(int(round((RunLogic.LIGHTS_NEEDLE - 1.0) * 100.0))),
		"clock": str(int(round(RunLogic.CLOCK_SEC))),
		"count_list": ", ".join(parts),
		"swing": str(int(round(RunLogic.POST_SWING))),
		"period": str(int(round(RunLogic.POST_PERIOD))),
		"ring_cap": str(int(round(KickConstants.RING_FACTOR_CAP))),
		"fire_heat": str(KickConstants.FIRE_HEAT),
		"long": str(int(round(KickConstants.LONG_YARDS))),
		"bomb": str(int(round(KickConstants.BOMB_YARDS))),
		"perfect": str(int(KickConstants.PERFECT_BONUS)),
	}


static func fill_numbers(text: String, overrides: Dictionary = {}) -> String:
	var values := number_values()
	for key in overrides.keys():
		values[str(key)] = str(overrides[key])
	var filled := text
	for key in values.keys():
		filled = filled.replace("{%s}" % str(key), str(values[key]))
	return filled


static func _entry(name: String, body: String, picture: String) -> Dictionary:
	return {"id": name, "name": name, "body": body, "picture": picture}
