class_name HowToPlay
extends RefCounted

# Page data for the pause-menu book. Drawing stays in hud.gd.
# UI5B appends pages to PAGE_IDS. Nothing else should hard-code the count.

const PAGE_IDS: Array[String] = ["kick", "wind"]

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
	return ""
