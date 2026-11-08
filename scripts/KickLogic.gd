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

# AIMING   - Left / Right swings the arrow. The needle rests at MAX. Space starts the meter.
# POWER    - A short flick to the POWER label, then a sweep back toward MAX. Space locks P.
#            Reaching MAX with no Space #2 shanks. Space on that same step locks P=100.
#            Space does nothing during the flick.
# ACCURACY - The needle keeps going to MAX if it is not there, then sweeps the right arc.
#            e is read only on that arc: +15 just after MAX, 0 at the center, -15 at the end.
#            Space locks e once the needle is on the right half. Finishing the arc locks e=-15.
# FLIGHT   - The ball is in the air. Space does nothing.
# RESULT   - The words are on screen. Space on this object sets up the same kick again.
#            The run (main.gd) does not use that. It moves on to the next kick.

var phase: Phase = Phase.AIMING
var aim_degrees := 0.0
var needle := 0.0
# Live needle, in screen degrees. 180 is POWER, 90 is MAX, 0 is the ACCURACY label.
var needle_angle := MeterGauge.MAX_ANGLE
var windup_left := 0.0
# Orange fill. It follows the sweep, then freezes at the locked power.
var fill_power := 0.0
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
# True when the power sweep reached MAX with no Space #2. Not a power lock.
var shanked := false

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
		fill_power = 0.0
		needle_angle = MeterGauge.MAX_ANGLE
		windup_left = MeterGauge.WINDUP_SEC
	elif phase == Phase.POWER:
		# The flick down to POWER is not a lockable power value.
		# A press with the needle already on MAX is P=100, not a shank.
		if windup_left <= 0.0000001:
			if needle_angle <= MeterGauge.MAX_ANGLE + 0.0001:
				power_true = KickConstants.METER_MAX
				needle = _shown_power(power_true)
			_lock_power(needle)
	elif phase == Phase.ACCURACY:
		# Leftover travel on the left arc is not an accuracy reading.
		if needle_angle <= MeterGauge.MAX_ANGLE + 0.0001:
			_lock_accuracy(MeterGauge.error_from_angle(needle_angle))
	elif phase == Phase.RESULT:
		reset_kick()
	# A press during the run-up or the flight does nothing.
	_update_ball()


func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	var left := delta
	var guard := 0
	while left > 0.0000001 and guard < 6:
		guard += 1
		if phase == Phase.POWER:
			left = _advance_power(left)
		elif phase == Phase.ACCURACY:
			left = _advance_accuracy(left)
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


# Seconds from the current needle to an accuracy error on the right arc.
# Leftover left-side travel uses the power-phase angular speed. The right arc uses
# the accuracy-phase speed. Neither side eases.
func seconds_until_error(target_error: float) -> float:
	var target := MeterGauge.angle_from_error(target_error)
	var time := 0.0
	var angle := needle_angle
	if phase == Phase.POWER and windup_left > 0.0:
		time += windup_left
		angle = MeterGauge.POWER_ANGLE
	if angle > MeterGauge.MAX_ANGLE + 0.0001:
		var omega := _power_omega()
		time += (angle - MeterGauge.MAX_ANGLE) / omega
		angle = MeterGauge.MAX_ANGLE
	if angle > target + 0.0001:
		time += (angle - target) / _accuracy_omega()
	return time


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
	needle_angle = MeterGauge.MAX_ANGLE
	windup_left = 0.0
	fill_power = 0.0
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
	shanked = false
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
	# A shank is not a power lock, so the line does not print P = 100.
	if shanked:
		return "SHANK, full power, max range = %s yd, kick = %s yd, result = %s" % [
			format_number(max_range),
			format_number(kick_distance),
			result_text,
		]
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
	if ball_type == "farm_ball":
		resist *= 1.10
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
# A doink stays a doink. Farm Strength does not turn it into a make.
static func judge(max_range_yards: float, distance_yards: float, offset: float, _ball_type: String, half_gap: float = -1.0) -> Dictionary:
	if max_range_yards < distance_yards:
		return {"text": "SHORT", "bank": false, "reached": false}
	var gap := KickConstants.POST_HALF_GAP_YARDS if half_gap < 0.0 else half_gap
	var text := _result_at_plane(offset, gap)
	return {"text": text, "bank": false, "reached": true}


static func power_for_range(locked_power: float, floor_value: float) -> float:
	if floor_value > 0.0 and locked_power < floor_value:
		return floor_value
	return locked_power


# Kicks past 75 yards stay in yard-space for the rules. The view squeezes the extra.
static func visual_span(real_yards: float) -> float:
	if real_yards <= 75.0:
		return real_yards
	return 75.0 + (real_yards - 75.0) * 0.02


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


func _advance_power(delta: float) -> float:
	if windup_left > 0.0:
		var step := minf(delta, windup_left)
		windup_left -= step
		var done := 1.0 - windup_left / MeterGauge.WINDUP_SEC
		needle_angle = lerpf(MeterGauge.MAX_ANGLE, MeterGauge.POWER_ANGLE, clampf(done, 0.0, 1.0))
		needle = 0.0
		power_true = 0.0
		fill_power = 0.0
		if windup_left > 0.0000001:
			return 0.0
		needle_angle = MeterGauge.POWER_ANGLE
		return delta - step
	var omega := _power_omega()
	if omega <= 0.001:
		return 0.0
	var room := needle_angle - MeterGauge.MAX_ANGLE
	var need := room / omega
	if delta < need - 0.0000001:
		needle_angle -= omega * delta
		power_true = MeterGauge.power_from_angle(needle_angle)
		needle = _shown_power(power_true)
		fill_power = power_true
		return 0.0
	# Reaching MAX with no Space #2 shanks. Leftover time does not start accuracy.
	needle_angle = MeterGauge.MAX_ANGLE
	power_true = KickConstants.METER_MAX
	needle = _shown_power(power_true)
	fill_power = power_true
	_shank()
	return 0.0


func _shown_power(true_value: float) -> float:
	# Mud jitters the lockable power. The jitter is new every frame and is not kept.
	# The needle angle itself stays smooth.
	var shown := true_value
	if mud_power:
		shown += _rng.randf_range(-mud_span, mud_span)
	return clampf(shown, 0.0, KickConstants.METER_MAX)


func _advance_accuracy(delta: float) -> float:
	if needle_angle > MeterGauge.MAX_ANGLE + 0.0001:
		var omega := _power_omega()
		var room := needle_angle - MeterGauge.MAX_ANGLE
		var need := room / omega
		if delta < need - 0.0000001:
			needle_angle -= omega * delta
			needle = power
			return 0.0
		needle_angle = MeterGauge.MAX_ANGLE
		needle = MeterGauge.ERROR_AT_MAX
		return delta - need
	var omega_acc := _accuracy_omega()
	if omega_acc <= 0.001:
		return 0.0
	var room_acc := needle_angle - MeterGauge.ACCURACY_ANGLE
	var need_acc := room_acc / omega_acc
	if delta < need_acc - 0.0000001:
		needle_angle -= omega_acc * delta
		needle = MeterGauge.error_from_angle(needle_angle)
		return 0.0
	needle_angle = MeterGauge.ACCURACY_ANGLE
	needle = KickConstants.METER_MIN
	_lock_accuracy(KickConstants.METER_MIN)
	return 0.0


func _power_omega() -> float:
	return MeterGauge.omega_power(stats.power_speed, stats.ball_speed_mult)


func _accuracy_omega() -> float:
	var omega := MeterGauge.omega_accuracy(stats.accuracy_speed, stats.ball_speed_mult)
	if rain_faster:
		omega *= rain_scale
	return omega


# Seconds of power-phase sweep from the current needle to this power.
# Includes a wind-up that has not finished yet. Linear, no easing.
func seconds_to_power(power_value: float) -> float:
	var target := MeterGauge.power_angle(power_value)
	if target < MeterGauge.MAX_ANGLE:
		target = MeterGauge.MAX_ANGLE
	var omega := _power_omega()
	if omega <= 0.001:
		return 0.0
	var angle := needle_angle
	var extra := 0.0
	if phase == Phase.POWER and windup_left > 0.0:
		extra = windup_left
		angle = MeterGauge.POWER_ANGLE
	return extra + maxf(angle - target, 0.0) / omega


# The needle reached MAX with no Space #2. Full-power wild miss, not a lock.
func _shank() -> void:
	shanked = true
	perfect = false
	bank_shot = false
	insured = false
	power = 0.0
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	var full := 100.0
	var cross := crosswind_mph(float(wind_speed), wind_direction) - stats.saucer_mph
	var head := head_tail_mph(float(wind_speed), wind_direction)
	var blown := sqrt(cross * cross + head * head)
	var blown_dir := rad_to_deg(atan2(cross, head))
	if howling_wind:
		blown *= 1.5
	drift_yards = drift_at_uprights(blown, blown_dir, kick_distance, 0, 0, stats.ball_type) * stats.drift_factor
	var wind_range := wind_range_delta(blown, blown_dir, 0, stats.thin_air)
	if stats.clearance:
		max_range = kick_distance + 5.0 + (full - 88.0) * 1.25 + stats.range_bonus + wind_range
	else:
		max_range = stats.range_base + stats.range_per_power * full + stats.range_bonus + wind_range
	if snow_range:
		max_range -= snow_penalty
	if thin_air_weather:
		max_range += 4.0
	if heavy_ball:
		max_range -= 4.0
	if max_range < kick_distance:
		max_range = kick_distance
	travel_yards = max_range
	flight_duration = flight_time_seconds(travel_yards)
	reached_uprights = true
	var gap := post_half_gap
	var target := side * (gap + KickConstants.DOINK_BAND_YARDS + 2.0 + absf(drift_yards))
	var needed := target - start_lateral_yards - drift_yards
	final_angle_degrees = rad_to_deg(atan(needed / maxf(kick_distance, 0.01)))
	offset_yards = path_lateral(start_lateral_yards, kick_distance, final_angle_degrees, kick_distance, drift_yards)
	var judged := judge(max_range, kick_distance, offset_yards, stats.ball_type, gap)
	if str(judged["text"]) == "GOOD" or str(judged["text"]) == "DOINK" or str(judged["text"]) == "SHORT":
		offset_yards = side * (gap + KickConstants.DOINK_BAND_YARDS + 2.0)
		final_angle_degrees = rad_to_deg(atan((offset_yards - start_lateral_yards) / maxf(kick_distance, 0.01)))
		judged = judge(max_range, kick_distance, offset_yards, stats.ball_type, gap)
	result_text = str(judged["text"])
	accuracy_error = side * MeterGauge.ERROR_AT_MAX
	needle_angle = MeterGauge.MAX_ANGLE
	needle = KickConstants.METER_MAX
	fill_power = KickConstants.METER_MAX
	power_true = KickConstants.METER_MAX
	flight_elapsed = 0.0
	phase = Phase.FLIGHT


func _advance_flight(delta: float) -> void:
	flight_elapsed += delta
	if flight_elapsed >= flight_duration:
		flight_elapsed = flight_duration
		phase = Phase.RESULT


# A Space #2 that lands on the step where the needle reaches MAX locks P=100.
# A press earlier on the arc locks the power the needle is on right now.
# The live frame calls this with that frame's delta so the two events agree.
func take_power_press(delta: float) -> void:
	if phase != Phase.POWER or windup_left > 0.0000001:
		return
	var omega := _power_omega()
	if omega <= 0.001:
		_lock_power(needle)
		return
	var need := maxf(needle_angle - MeterGauge.MAX_ANGLE, 0.0) / omega
	if need <= delta + 0.0000001:
		needle_angle = MeterGauge.MAX_ANGLE
		power_true = KickConstants.METER_MAX
		needle = _shown_power(power_true)
		_lock_power(needle)
		var left := delta - need
		if left > 0.0000001:
			advance(left)
		return
	_lock_power(needle)
	if delta > 0.0000001:
		advance(delta)


func _lock_power(value: float) -> void:
	power = clampf(value, 0.0, KickConstants.METER_MAX)
	fill_power = power
	power_true = power
	phase = Phase.ACCURACY
	# The needle stays where it is. Crossing onto the right arc is what starts e.
	if needle_angle <= MeterGauge.MAX_ANGLE + 0.0001:
		needle_angle = MeterGauge.MAX_ANGLE
		needle = MeterGauge.ERROR_AT_MAX
	else:
		needle = power


func _lock_accuracy(value: float) -> void:
	# Numero Dos is a real power lock at 95–100. An auto-shank never reaches here.
	var numero := stats.numero_dos and power >= 95.0 and power <= 100.0
	if numero:
		accuracy_error = 0.0
	elif stats.ice_veins or stats.red_tip_off:
		accuracy_error = value
	else:
		accuracy_error = accuracy_with_red_tip(power, value, _rng, stats.red_tip_start, stats.red_tip_noise)
	# Omega-3 reads the press, including red-tip noise, then can wipe the angle.
	# perfect stays the original press so cash can still pay. The score bonus is suppressed later.
	perfect = absf(accuracy_error) <= stats.perfect_band
	if numero:
		accuracy_error = 0.0
		perfect = true
	if stats.omega and absf(accuracy_error) <= stats.good_band:
		accuracy_error = 0.0
	# Good As Gold: the whole good band is a true perfect, including the cash.
	if stats.good_as_gold and absf(accuracy_error) <= stats.good_band:
		accuracy_error = 0.0
		perfect = true
	var per_unit := KickConstants.ACCURACY_DEG_PER_ERROR * angle_scale
	var hook := 0.0 if perfect else -accuracy_error * per_unit
	final_angle_degrees = aim_degrees + hook
	# The saucer adds 8 mph west, then Howling Wind scales the combined vector.
	var cross := crosswind_mph(float(wind_speed), wind_direction) - stats.saucer_mph
	var head := head_tail_mph(float(wind_speed), wind_direction)
	var blown := sqrt(cross * cross + head * head)
	var blown_dir := rad_to_deg(atan2(cross, head))
	if howling_wind:
		blown *= 1.5
	drift_yards = drift_at_uprights(blown, blown_dir, kick_distance, 0, 0, stats.ball_type) * stats.drift_factor
	var wind_range := wind_range_delta(blown, blown_dir, 0, stats.thin_air)
	var ranged := power_for_range(power, stats.power_floor)
	if stats.clearance:
		var clearance := 5.0 + (ranged - 88.0) * 1.25
		max_range = kick_distance + clearance + stats.range_bonus + wind_range
	else:
		max_range = stats.range_base + stats.range_per_power * ranged + stats.range_bonus + wind_range
	if snow_range:
		max_range -= snow_penalty
	if thin_air_weather:
		max_range += 4.0
	if heavy_ball:
		max_range -= 4.0
	if max_range < 0.0:
		max_range = 0.0
	# 88% and above clears the posts even if a headwind or a penalty would otherwise leave it short.
	if stats.clearance and ranged >= 88.0 and max_range < kick_distance:
		max_range = kick_distance
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
