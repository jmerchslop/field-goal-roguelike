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
# Stack counts the kick reads. Rebuild sets these from the owned cards.
var low_drive_stacks := 0
var wind_breaker_stacks := 0
var storm_chaser_stacks := 0
var thin_air_stacks := 0
var flag_reader := false
var laser_line := false
var ice_veins := false
var insurance_per_quarter := 0
var practice_per_quarter := 0


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
	low_drive_stacks = 0
	wind_breaker_stacks = 0
	storm_chaser_stacks = 0
	thin_air_stacks = 0
	flag_reader = false
	laser_line = false
	ice_veins = false
	insurance_per_quarter = 0
	practice_per_quarter = 0
