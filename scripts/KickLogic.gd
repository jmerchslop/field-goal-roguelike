class_name KickLogic
extends RefCounted

# The rules of one kick, with no drawing.
# main.gd reads these variables and paints them.

enum Phase { AIMING, POWER, ACCURACY, FLIGHT, RESULT }

# The approach animation reads these. They do not change when the ball leaves.
const APPROACH_AT := 40.0
const PLANT_BEAT := 0.08
const EARLY_RUSH_SEC := 0.25
const RUN_TO_GATHER_SEC := 0.35
# Yards behind the plant spot. A literal 5 puts the kicker under the fixed camera
# (the camera is only 6.4 yards behind the tee) and the sprite falls off the bottom.
# 2.2 is as far back as the standing pose still shows the jersey.
const START_BEHIND := 2.2
const GATHER_SHORT := 1.0
const PLANT_Z := 1.15
# The run portion of a compressed approach. The last 0.08s is the plant sprite.
const EARLY_RUN_SEC := 0.17

# AIMING   - Left / Right swings the arrow. Space starts the meter.
# POWER    - The needle rises. Space locks power. At 100 it locks itself.
# ACCURACY - The needle falls. Space locks accuracy. At -15 it locks itself.
# FLIGHT   - The ball is in the air. Space does nothing.
# RESULT   - The words are on screen. Space on this object sets up the same kick again.
#            The run (main.gd) does not use that. It moves on to the next kick.

var phase: Phase = Phase.AIMING
var aim_degrees := 0.0
var needle := 0.0
var power := 0.0
var accuracy_error := 0.0
var kick_distance := KickConstants.KICK_DISTANCE_YARDS
# Sideways start, in yards. Negative is screen-left. Center spots stay at 0.
# The aim arrow still starts straight up the field, not pointed at the posts.
var start_lateral_yards := 0.0

var final_angle_degrees := 0.0
var max_range := 0.0
var offset_yards := 0.0
var result_text := ""
var perfect := false
var bank_shot := false
var insured := false
var insurance_ready := false
var reached_uprights := false
# Saved wind for this kick. 0° blows toward the uprights. Positive crosswind pushes right.
var wind_speed := 0
var wind_direction := 0.0
var drift_yards := 0.0
# Weather for this kick. The run copies these in. They do not change the scoring rules except where Prompt 5 says so.
var rain_faster := false
var snow_range := false
var mud_power := false
var thin_air_weather := false
var post_half_gap := KickConstants.POST_HALF_GAP_YARDS
# The smooth power needle. Mud draws a jitter on top and does not add it back in.
var power_true := 0.0
var heavy_ball := false
var howling_wind := false
var shaky := false
var angle_scale := 1.0
var rain_scale := 1.2
var snow_penalty := 4.0
var mud_span := 3.0
var aim_base := 0.0
var flight_elapsed := 0.0
var flight_duration := 0.0
var travel_yards := 0.0

# Where the ball is right now. Height is 0 on the ground and 1 at mid-flight.
var ball_forward_yards := 0.0
var ball_lateral_yards := 0.0
var ball_height := 0.0

# Upgrades change these. Defaults match the constants, so an untouched kick plays the same.
var stats := KickerStats.new()

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# Tests pass a seed so the red-tip wobble can be replayed.
func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value


# direction is -1 for left, +1 for right, and 0 to hold still.
func aim(direction: float, delta: float) -> void:
	if phase != Phase.AIMING:
		return
	aim_base += direction * KickConstants.AIM_SPEED_DEG_PER_SEC * delta
	aim_base = clampf(aim_base, KickConstants.AIM_MIN_DEG, KickConstants.AIM_MAX_DEG)
	aim_degrees = aim_base


func press_space() -> void:
	if phase == Phase.AIMING:
		phase = Phase.POWER
		needle = 0.0
		power_true = 0.0
	elif phase == Phase.POWER:
		_lock_power(needle)
	elif phase == Phase.ACCURACY:
		_lock_accuracy(needle)
	elif phase == Phase.RESULT:
		reset_kick()
	# A press during the run-up or the flight does nothing.
	_update_ball()


func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	var left := delta
	var guard := 0
	while left > 0.0000001 and guard < 4:
		guard += 1
		if phase == Phase.POWER:
			_advance_power(left)
			left = 0.0
		elif phase == Phase.ACCURACY:
			_advance_accuracy(left)
			left = 0.0
		elif phase == Phase.FLIGHT:
			var remain := flight_duration - flight_elapsed
			var fly := minf(left, maxf(remain, 0.0))
			flight_elapsed += fly
			if flight_elapsed >= flight_duration - 0.0000001:
				flight_elapsed = flight_duration
				phase = Phase.RESULT
			left = 0.0
		else:
			left = 0.0
	_update_ball()


func reset_kick() -> void:
	var distance := kick_distance
	var lateral := start_lateral_yards
	var saved_speed := wind_speed
	var saved_direction := wind_direction
	var keep_insurance := insurance_ready
	var keep_rain := rain_faster
	var keep_snow := snow_range
	var keep_mud := mud_power
	var keep_thin := thin_air_weather
	var keep_gap := post_half_gap
	var keep_heavy := heavy_ball
	var keep_howl := howling_wind
	var keep_shaky := shaky
	var keep_angle := angle_scale
	var keep_rain_scale := rain_scale
	var keep_snow_pen := snow_penalty
	var keep_mud_span := mud_span
	phase = Phase.AIMING
	aim_degrees = 0.0
	needle = 0.0
	power = 0.0
	accuracy_error = 0.0
	final_angle_degrees = 0.0
	max_range = 0.0
	offset_yards = 0.0
	result_text = ""
	perfect = false
	bank_shot = false
	insured = false
	reached_uprights = false
	drift_yards = 0.0
	flight_elapsed = 0.0
	flight_duration = 0.0
	travel_yards = 0.0
	ball_forward_yards = 0.0
	ball_lateral_yards = lateral
	ball_height = 0.0
	kick_distance = distance
	start_lateral_yards = lateral
	wind_speed = saved_speed
	wind_direction = saved_direction
	insurance_ready = keep_insurance
	rain_faster = keep_rain
	snow_range = keep_snow
	mud_power = keep_mud
	thin_air_weather = keep_thin
	post_half_gap = keep_gap
	heavy_ball = keep_heavy
	howling_wind = keep_howl
	shaky = keep_shaky
	angle_scale = keep_angle
	rain_scale = keep_rain_scale
	snow_penalty = keep_snow_pen
	mud_span = keep_mud_span
	power_true = 0.0
	aim_base = 0.0


func detail_line() -> String:
	# Shown after the kick so the range math can be checked against the flight.
	return "P = %s, max range = %s yd, kick = %s yd, result = %s" % [
		format_number(power),
		format_number(max_range),
		format_number(kick_distance),
		result_text,
	]


# --- Pure math. The meter and the tests both call these. ----------------------

static func accuracy_with_red_tip(power_value: float, needle_value: float, rng: RandomNumberGenerator, tip_start: float = KickConstants.RED_TIP_START, noise: float = 5.0) -> float:
	var error := needle_value
	# The wobble is added before the perfect check, so a press on 0 can miss PERFECT.
	if power_value >= tip_start:
		error += rng.randf_range(-noise, noise)
	return error


static func is_perfect(accuracy_error_value: float) -> bool:
	return absf(accuracy_error_value) <= KickConstants.PERFECT_BAND


static func hook_degrees(accuracy_error_value: float) -> float:
	# Inside the perfect band the hook is wiped out, even though e × 0.35 is not zero.
	if is_perfect(accuracy_error_value):
		return 0.0
	# Positive e hooks left, and left is negative.
	return -accuracy_error_value * KickConstants.ACCURACY_DEG_PER_ERROR


static func final_angle(aim: float, accuracy_error_value: float) -> float:
	return aim + hook_degrees(accuracy_error_value)


static func range_yards(power_value: float) -> float:
	return KickConstants.RANGE_BASE_YARDS + KickConstants.RANGE_PER_POWER * power_value


# Positive crosswind pushes the ball right. Positive head/tail is a tailwind.
static func crosswind_mph(speed: float, direction_degrees: float) -> float:
	return speed * sin(deg_to_rad(direction_degrees))


static func head_tail_mph(speed: float, direction_degrees: float) -> float:
	return speed * cos(deg_to_rad(direction_degrees))


# Yards of sideways drift at the uprights, after resist upgrades and the ball.
static func drift_at_uprights(speed: float, direction_degrees: float, distance_yards: float, low_drive: int, wind_breaker: int, ball_type: String) -> float:
	var resist := pow(0.65, float(low_drive)) * pow(0.8, float(wind_breaker))
	if ball_type == "barn_burner":
		resist *= 0.7
	return crosswind_mph(speed, direction_degrees) * 0.0065 * distance_yards * resist


# Tailwind adds range. Headwind subtracts. Low Drive shrinks it. Thin Air boosts only a tailwind.
static func wind_range_delta(speed: float, direction_degrees: float, low_drive: int, thin_air: bool) -> float:
	var change := head_tail_mph(speed, direction_degrees) * 0.4
	change *= pow(0.65, float(low_drive))
	if thin_air and change > 0.0:
		change *= 1.5
	return change


# The same line the ball is drawn on. At the posts, the wind term is the full drift.
static func path_lateral(start_lateral: float, forward: float, angle_degrees: float, distance_yards: float, drift: float) -> float:
	var along := 0.0
	if distance_yards > 0.0:
		along = forward / distance_yards
	return start_lateral + forward * tan(deg_to_rad(angle_degrees)) + drift * along * along


# End of the aiming preview: the first 40% of the kick, perfect accuracy, with the wind curve.
# Yards behind the tee for the approach puppet.
# idle: standing behind the plant spot, a little left of the tee.
# run: toward a gather point 1 yard short of the plant, then wait.
# plant: the last step into the plant spot.
# early: the whole approach is squeezed into about 0.25 seconds.
static func approach_z(pose: String, run_time: float, swing_time: float, early: bool, from_z: float = -1.0) -> float:
	var plant := PLANT_Z
	var start := plant + START_BEHIND
	var gather := plant + GATHER_SHORT
	var origin := start if from_z < 0.0 else from_z
	if pose == "idle":
		return start
	if pose == "run" and early:
		return lerpf(origin, plant, clampf(swing_time / EARLY_RUN_SEC, 0.0, 1.0))
	if pose == "run":
		return lerpf(start, gather, clampf(run_time / RUN_TO_GATHER_SEC, 0.0, 1.0))
	if pose == "plant" and not early:
		var held := lerpf(start, gather, clampf(run_time / RUN_TO_GATHER_SEC, 0.0, 1.0))
		return lerpf(held, plant, clampf(swing_time / PLANT_BEAT, 0.0, 1.0))
	return plant


# Shanky Cleats and Howling Wind are read by the kick. The run turns them on.
func sway(time: float) -> void:
	if shaky and phase == Phase.AIMING:
		aim_degrees = clampf(aim_base + sin(time * 1.6) * 3.0, KickConstants.AIM_MIN_DEG, KickConstants.AIM_MAX_DEG)
	else:
		aim_degrees = aim_base


static func preview_forward(distance_yards: float) -> float:
	return distance_yards * 0.4


static func offset_yards_at_uprights(distance_yards: float, angle_degrees: float, start_lateral: float = 0.0) -> float:
	# Where the ball crosses the uprights' line. Negative is left of the posts.
	# start_lateral is the spot (hash / wide). Aim is measured from straight upfield.
	return start_lateral + distance_yards * tan(deg_to_rad(angle_degrees))


static func flight_time_seconds(distance_yards: float) -> float:
	return KickConstants.FLIGHT_TIME_BASE_SEC + KickConstants.FLIGHT_TIME_PER_YARD * distance_yards


static func classify(max_range_yards: float, distance_yards: float, offset: float) -> String:
	# The ball has to reach the posts. A perfect aim that falls short is still SHORT.
	return str(judge(max_range_yards, distance_yards, offset, "standard")["text"])


# reached is true only when the ball's path gets to the uprights' plane.
# ball_type "barn_burner" can turn a doink into GOOD when there is range to spare.
static func judge(max_range_yards: float, distance_yards: float, offset: float, ball_type: String, half_gap: float = -1.0) -> Dictionary:
	if max_range_yards < distance_yards:
		return {"text": "SHORT", "bank": false, "reached": false}
	var gap := KickConstants.POST_HALF_GAP_YARDS if half_gap < 0.0 else half_gap
	var text := _result_at_plane(offset, gap)
	var bank := false
	if ball_type == "barn_burner" and text == "DOINK" and max_range_yards >= distance_yards + 10.0:
		text = "GOOD"
		bank = true
	return {"text": text, "bank": bank, "reached": true}


static func _result_at_plane(offset: float, half_gap: float = KickConstants.POST_HALF_GAP_YARDS) -> String:
	var from_the_post := absf(absf(offset) - half_gap)
	if from_the_post <= KickConstants.DOINK_BAND_YARDS:
		return "DOINK"
	if absf(offset) > half_gap:
		if offset < 0.0:
			return "WIDE LEFT"
		return "WIDE RIGHT"
	return "GOOD"


static func format_detail(power_value: float, accuracy_error_value: float, angle: float) -> String:
	return "P = %s, e = %s, angle = %s°" % [
		format_number(power_value),
		format_signed(accuracy_error_value),
		format_angle(angle),
	]


static func format_number(value: float) -> String:
	if absf(value - roundf(value)) < 0.001:
		return str(int(roundf(value)))
	var tenths := int(roundf(absf(round_tenth(value)) * 10.0))
	return "%d.%d" % [int(tenths / 10), tenths % 10]


static func format_signed(value: float) -> String:
	if absf(value) < 0.001:
		return "0"
	var body := format_number(absf(value))
	if value > 0.0:
		return "+" + body
	return "-" + body


static func format_angle(value: float) -> String:
	var tenths := int(roundf(round_tenth(value) * 10.0))
	if tenths == 0:
		return "0.0"
	var sign := "+" if tenths > 0 else "-"
	tenths = absi(tenths)
	return "%s%d.%d" % [sign, int(tenths / 10), tenths % 10]


# Round half away from zero, so 1.05 becomes 1.1 and -5.25 becomes -5.3.
static func round_tenth(value: float) -> float:
	var scaled := value * 10.0
	if scaled >= 0.0:
		return floorf(scaled + 0.5 + 0.0000001) / 10.0
	return ceilf(scaled - 0.5 - 0.0000001) / 10.0


func _advance_power(delta: float) -> void:
	power_true += stats.power_speed * delta
	if power_true < KickConstants.METER_MAX:
		needle = _shown_power(power_true)
		return
	# The fall starts on the next step. One frame at 100 is too small to see.
	power_true = KickConstants.METER_MAX
	needle = _shown_power(power_true)
	_lock_power(needle)


func _shown_power(true_value: float) -> float:
	# Mud jitters the shown needle. The jitter is new every frame and is not kept.
	var shown := true_value
	if mud_power:
		shown += _rng.randf_range(-mud_span, mud_span)
	return clampf(shown, 0.0, KickConstants.METER_MAX)


func _advance_accuracy(delta: float) -> void:
	var fall := stats.accuracy_speed
	if rain_faster:
		fall *= rain_scale
	needle -= fall * delta
	if needle > KickConstants.METER_MIN:
		return
	needle = KickConstants.METER_MIN
	_lock_accuracy(KickConstants.METER_MIN)


func _advance_flight(delta: float) -> void:
	flight_elapsed += delta
	if flight_elapsed >= flight_duration:
		flight_elapsed = flight_duration
		phase = Phase.RESULT


func _lock_power(value: float) -> void:
	power = clampf(value, KickConstants.METER_MIN, KickConstants.METER_MAX)
	needle = power
	power_true = power
	phase = Phase.ACCURACY


func _lock_accuracy(value: float) -> void:
	if stats.ice_veins or stats.red_tip_off:
		accuracy_error = value
	else:
		accuracy_error = accuracy_with_red_tip(power, value, _rng, stats.red_tip_start, stats.red_tip_noise)
	# The perfect window comes from the kicker's stats, so Sweet Spot can widen it.
	perfect = absf(accuracy_error) <= stats.perfect_band
	var per_unit := KickConstants.ACCURACY_DEG_PER_ERROR * angle_scale
	var hook := 0.0 if perfect else -accuracy_error * per_unit
	final_angle_degrees = aim_degrees + hook
	# Howling Wind multiplies this kick's wind speed. The saved wind number stays put.
	var blown := float(wind_speed)
	if howling_wind:
		blown *= 1.5
	drift_yards = drift_at_uprights(blown, wind_direction, kick_distance, 0, 0, stats.ball_type) * stats.drift_factor
	var wind_range := wind_range_delta(blown, wind_direction, 0, stats.thin_air)
	max_range = stats.range_base + stats.range_per_power * power + stats.range_bonus + wind_range
	if snow_range:
		max_range -= snow_penalty
	if thin_air_weather:
		max_range += 4.0
	if heavy_ball:
		max_range -= 4.0
	if max_range < 0.0:
		max_range = 0.0
	travel_yards = max_range
	flight_duration = flight_time_seconds(travel_yards)
	reached_uprights = travel_yards >= kick_distance
	# The drawn path is this same line. A short ball stops at max range.
	# A long ball is scored where that line crosses the uprights, then it keeps going.
	if reached_uprights:
		offset_yards = path_lateral(start_lateral_yards, kick_distance, final_angle_degrees, kick_distance, drift_yards)
	else:
		offset_yards = path_lateral(start_lateral_yards, travel_yards, final_angle_degrees, kick_distance, drift_yards)
	var judged := judge(max_range, kick_distance, offset_yards if reached_uprights else 0.0, stats.ball_type, post_half_gap)
	result_text = str(judged["text"])
	bank_shot = bool(judged["bank"])
	insured = false
	if result_text == "DOINK" and insurance_ready:
		result_text = "GOOD"
		insured = true
		insurance_ready = false
	phase = Phase.FLIGHT
	flight_elapsed = 0.0


func _update_ball() -> void:
	var t := 0.0
	if flight_duration > 0.0 and (phase == Phase.FLIGHT or phase == Phase.RESULT):
		t = clampf(flight_elapsed / flight_duration, 0.0, 1.0)
	ball_forward_yards = t * travel_yards
	ball_lateral_yards = path_lateral(start_lateral_yards, ball_forward_yards, final_angle_degrees, kick_distance, drift_yards)
	# The arc grows the ball on the way up and shrinks it on the way down.
	ball_height = sin(t * PI)


func sync_tee() -> void:
	# Puts the ball on its spot. Call this after changing the distance or the spot.
	_update_ball()
