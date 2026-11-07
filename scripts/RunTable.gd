class_name RunTable
extends RefCounted

# The 20 kicks in a run. Each row's wind min and max are rolled when that kick begins.
# Spot is where the ball starts: center, hash (3 yd off), or wide (6 yd off).

const SPOT_CENTER := "center"
const SPOT_HASH := "hash"
const SPOT_WIDE := "wide"
const CLEAR := "clear"
const BOSS := "boss"

const KICKS: Array = [
	{"kick": 1, "distance": 35.0, "spot": SPOT_CENTER, "wind_min": 0.0, "wind_max": 0.0, "conditions": CLEAR},
	{"kick": 2, "distance": 38.0, "spot": SPOT_CENTER, "wind_min": 0.0, "wind_max": 0.0, "conditions": CLEAR},
	{"kick": 3, "distance": 41.0, "spot": SPOT_CENTER, "wind_min": 0.0, "wind_max": 0.0, "conditions": CLEAR},
	{"kick": 4, "distance": 44.0, "spot": SPOT_HASH, "wind_min": 0.0, "wind_max": 5.0, "conditions": CLEAR},
	{"kick": 5, "distance": 48.0, "spot": SPOT_HASH, "wind_min": 0.0, "wind_max": 5.0, "conditions": BOSS},
	{"kick": 6, "distance": 45.0, "spot": SPOT_HASH, "wind_min": 3.0, "wind_max": 8.0, "conditions": CLEAR},
	{"kick": 7, "distance": 50.0, "spot": SPOT_HASH, "wind_min": 5.0, "wind_max": 10.0, "conditions": CLEAR},
	{"kick": 8, "distance": 53.0, "spot": SPOT_HASH, "wind_min": 5.0, "wind_max": 12.0, "conditions": CLEAR},
	{"kick": 9, "distance": 56.0, "spot": SPOT_HASH, "wind_min": 8.0, "wind_max": 14.0, "conditions": CLEAR},
	{"kick": 10, "distance": 60.0, "spot": SPOT_HASH, "wind_min": 10.0, "wind_max": 15.0, "conditions": BOSS},
	{"kick": 11, "distance": 54.0, "spot": SPOT_WIDE, "wind_min": 10.0, "wind_max": 16.0, "conditions": CLEAR},
	{"kick": 12, "distance": 59.0, "spot": SPOT_WIDE, "wind_min": 10.0, "wind_max": 18.0, "conditions": CLEAR},
	{"kick": 13, "distance": 62.0, "spot": SPOT_WIDE, "wind_min": 12.0, "wind_max": 20.0, "conditions": CLEAR},
	{"kick": 14, "distance": 65.0, "spot": SPOT_WIDE, "wind_min": 12.0, "wind_max": 22.0, "conditions": CLEAR},
	{"kick": 15, "distance": 68.0, "spot": SPOT_WIDE, "wind_min": 15.0, "wind_max": 22.0, "conditions": BOSS},
	{"kick": 16, "distance": 60.0, "spot": SPOT_WIDE, "wind_min": 15.0, "wind_max": 25.0, "conditions": CLEAR},
	{"kick": 17, "distance": 65.0, "spot": SPOT_WIDE, "wind_min": 15.0, "wind_max": 28.0, "conditions": CLEAR},
	{"kick": 18, "distance": 69.0, "spot": SPOT_WIDE, "wind_min": 18.0, "wind_max": 30.0, "conditions": CLEAR},
	{"kick": 19, "distance": 72.0, "spot": SPOT_WIDE, "wind_min": 20.0, "wind_max": 30.0, "conditions": CLEAR},
	{"kick": 20, "distance": 75.0, "spot": SPOT_WIDE, "wind_min": 25.0, "wind_max": 35.0, "conditions": BOSS},
]


static func count() -> int:
	return KICKS.size()


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
