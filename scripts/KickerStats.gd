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
var storm_per_mph := 0.0
var hero_mult := 0.0
var curse_mult := 0.0
var drift_factor := 1.0
var angle_scale := 1.0
var thin_air := false
var flag_reader := false
var laser_line := false
var laser_full := false
var wind_preview := false
var wind_preview_count := 0
var red_tip_off := false
var ice_cage := false
var ice_veins := false
var hide_meter := false
var heavy_ball := false
var howling := false
var shaky := false
var narrow_posts := false
var tight_window := false
var weather_cut := 0
var wraps_yards := 0.0
var doink_per_quarter := 0
var doink_carry := false
var practice_per_quarter := 0
var practice_carry := false
var bench_spare := false
var drill_mult := 0.0


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
	storm_per_mph = 0.0
	hero_mult = 0.0
	curse_mult = 0.0
	drift_factor = 1.0
	angle_scale = 1.0
	thin_air = false
	flag_reader = false
	laser_line = false
	laser_full = false
	wind_preview = false
	wind_preview_count = 0
	red_tip_off = false
	ice_cage = false
	ice_veins = false
	hide_meter = false
	heavy_ball = false
	howling = false
	shaky = false
	narrow_posts = false
	tight_window = false
	weather_cut = 0
	wraps_yards = 0.0
	doink_per_quarter = 0
	doink_carry = false
	practice_per_quarter = 0
	practice_carry = false
	bench_spare = false
	drill_mult = 0.0
