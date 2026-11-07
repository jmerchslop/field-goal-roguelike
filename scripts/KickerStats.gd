class_name KickerStats
extends RefCounted

# Numbers an upgrade can change. A new run starts these over.
# The live kick reads these. The constants stay the starting values.

var power_speed := KickConstants.POWER_RISE_PER_SEC
var accuracy_speed := KickConstants.ACCURACY_FALL_PER_SEC
var perfect_band := KickConstants.PERFECT_BAND
var good_band := KickConstants.METER_INNER_BAND
var range_base := KickConstants.RANGE_BASE_YARDS
var range_per_power := KickConstants.RANGE_PER_POWER
var range_bonus := 0.0
var red_tip_start := KickConstants.RED_TIP_START
var red_tip_noise := 5.0
var attempt_cap := KickConstants.ATTEMPT_CAP
var streak_step := KickConstants.STREAK_MULT_STEP
var mulligans_per_quarter := 0
var rerolls_per_run := 1
var ball_type := "standard"


func reset() -> void:
	power_speed = KickConstants.POWER_RISE_PER_SEC
	accuracy_speed = KickConstants.ACCURACY_FALL_PER_SEC
	perfect_band = KickConstants.PERFECT_BAND
	good_band = KickConstants.METER_INNER_BAND
	range_base = KickConstants.RANGE_BASE_YARDS
	range_per_power = KickConstants.RANGE_PER_POWER
	range_bonus = 0.0
	red_tip_start = KickConstants.RED_TIP_START
	red_tip_noise = 5.0
	attempt_cap = KickConstants.ATTEMPT_CAP
	streak_step = KickConstants.STREAK_MULT_STEP
	mulligans_per_quarter = 0
	rerolls_per_run = 1
	ball_type = "standard"
