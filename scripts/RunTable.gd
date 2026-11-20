class_name RunTable
extends RefCounted

# The 10 kicks in a Standard run. Each row's wind min and max already include +3 mph.
# Spot is where the ball starts: center, hash (3 yd off), or wide (6 yd off).

const SPOT_CENTER := "center"
const SPOT_HASH := "hash"
const SPOT_WIDE := "wide"
const CLEAR := "clear"
const BOSS := "boss"

const KICKS: Array = [
	{"kick": 1, "distance": 35.0, "spot": SPOT_CENTER, "wind_min": 3.0, "wind_max": 3.0, "conditions": CLEAR},
	{"kick": 2, "distance": 40.0, "spot": SPOT_CENTER, "wind_min": 3.0, "wind_max": 6.0, "conditions": CLEAR},
	{"kick": 3, "distance": 45.0, "spot": SPOT_CENTER, "wind_min": 3.0, "wind_max": 8.0, "conditions": CLEAR},
	{"kick": 4, "distance": 50.0, "spot": SPOT_HASH, "wind_min": 5.0, "wind_max": 10.0, "conditions": CLEAR},
	{"kick": 5, "distance": 54.0, "spot": SPOT_HASH, "wind_min": 6.0, "wind_max": 11.0, "conditions": BOSS},
	{"kick": 6, "distance": 58.0, "spot": SPOT_HASH, "wind_min": 8.0, "wind_max": 13.0, "conditions": CLEAR},
	{"kick": 7, "distance": 63.0, "spot": SPOT_HASH, "wind_min": 9.0, "wind_max": 15.0, "conditions": CLEAR},
	{"kick": 8, "distance": 68.0, "spot": SPOT_WIDE, "wind_min": 10.0, "wind_max": 16.0, "conditions": CLEAR},
	{"kick": 9, "distance": 74.0, "spot": SPOT_WIDE, "wind_min": 11.0, "wind_max": 17.0, "conditions": CLEAR},
	{"kick": 10, "distance": 80.0, "spot": SPOT_WIDE, "wind_min": 12.0, "wind_max": 18.0, "conditions": BOSS},
]


static func count() -> int:
	return KICKS.size()


static func endless_distance(kick_number: int) -> float:
	return minf(1000.0, 20.0 + float(kick_number - 1) * 5.0)


# Endless kicks 1–10 use that Standard row. Kicks 11+ cycle rows 7–10.
static func table_kick(mode: String, kick_number: int) -> int:
	if mode == "endless" and kick_number > 10:
		return 7 + ((kick_number - 11) % 4)
	return clampi(kick_number, 1, count())


static func row(kick_number: int) -> Dictionary:
	return KICKS[kick_number - 1]


# side is -1 for left and +1 for right. Center ignores it.
static func spot_yards(spot: String, side: int) -> float:
	var sign := -1.0 if side < 0 else 1.0
	if spot == SPOT_HASH:
		return sign * KickConstants.HASH_OFFSET_YARDS
	if spot == SPOT_WIDE:
		return sign * KickConstants.WIDE_OFFSET_YARDS
	return 0.0
