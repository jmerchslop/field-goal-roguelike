class_name KickLogic
extends RefCounted

# The rules of one kick, with no drawing.
# main.gd reads these variables and paints them.

enum Phase { AIMING, POWER, ACCURACY, FLIGHT, RESULT }

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
var reached_uprights := false
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
	aim_degrees += direction * KickConstants.AIM_SPEED_DEG_PER_SEC * delta
	aim_degrees = clampf(aim_degrees, KickConstants.AIM_MIN_DEG, KickConstants.AIM_MAX_DEG)


func press_space() -> void:
	if phase == Phase.AIMING:
		phase = Phase.POWER
		needle = 0.0
	elif phase == Phase.POWER:
		_lock_power(needle)
	elif phase == Phase.ACCURACY:
		_lock_accuracy(needle)
	elif phase == Phase.RESULT:
		reset_kick()
	# A press during FLIGHT is ignored.
	_update_ball()


func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	if phase == Phase.POWER:
		_advance_power(delta)
	elif phase == Phase.ACCURACY:
		_advance_accuracy(delta)
	elif phase == Phase.FLIGHT:
		_advance_flight(delta)
	_update_ball()


func reset_kick() -> void:
	var distance := kick_distance
	var lateral := start_lateral_yards
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
	reached_uprights = false
	flight_elapsed = 0.0
	flight_duration = 0.0
	travel_yards = 0.0
	ball_forward_yards = 0.0
	ball_lateral_yards = lateral
	ball_height = 0.0
	kick_distance = distance
	start_lateral_yards = lateral


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
static func judge(max_range_yards: float, distance_yards: float, offset: float, ball_type: String) -> Dictionary:
	if max_range_yards < distance_yards:
		return {"text": "SHORT", "bank": false, "reached": false}
	var text := _result_at_plane(offset)
	var bank := false
	if ball_type == "barn_burner" and text == "DOINK" and max_range_yards >= distance_yards + 10.0:
		text = "GOOD"
		bank = true
	return {"text": text, "bank": bank, "reached": true}


static func _result_at_plane(offset: float) -> String:
	var from_the_post := absf(absf(offset) - KickConstants.POST_HALF_GAP_YARDS)
	if from_the_post <= KickConstants.DOINK_BAND_YARDS:
		return "DOINK"
	if absf(offset) > KickConstants.POST_HALF_GAP_YARDS:
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
	needle += stats.power_speed * delta
	if needle < KickConstants.METER_MAX:
		return
	# The fall starts on the next step. One frame at 100 is too small to see.
	needle = KickConstants.METER_MAX
	_lock_power(KickConstants.METER_MAX)


func _advance_accuracy(delta: float) -> void:
	needle -= stats.accuracy_speed * delta
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
	phase = Phase.ACCURACY


func _lock_accuracy(value: float) -> void:
	accuracy_error = accuracy_with_red_tip(power, value, _rng, stats.red_tip_start, stats.red_tip_noise)
	# The perfect window comes from the kicker's stats, so Sweet Spot can widen it.
	perfect = absf(accuracy_error) <= stats.perfect_band
	var hook := 0.0 if perfect else -accuracy_error * KickConstants.ACCURACY_DEG_PER_ERROR
	final_angle_degrees = aim_degrees + hook
	# This kick's locked power. Not a leftover, and not the kick distance.
	max_range = stats.range_base + stats.range_per_power * power + stats.range_bonus
	travel_yards = max_range
	flight_duration = flight_time_seconds(travel_yards)
	reached_uprights = travel_yards >= kick_distance
	# The drawn path is this same line. A short ball stops at max range.
	# A long ball is scored where that line crosses the uprights, then it keeps going.
	if reached_uprights:
		offset_yards = offset_yards_at_uprights(kick_distance, final_angle_degrees, start_lateral_yards)
	else:
		offset_yards = offset_yards_at_uprights(travel_yards, final_angle_degrees, start_lateral_yards)
	var judged := judge(max_range, kick_distance, offset_yards if reached_uprights else 0.0, stats.ball_type)
	result_text = str(judged["text"])
	bank_shot = bool(judged["bank"])
	phase = Phase.FLIGHT
	flight_elapsed = 0.0


func _update_ball() -> void:
	var t := 0.0
	if flight_duration > 0.0 and (phase == Phase.FLIGHT or phase == Phase.RESULT):
		t = clampf(flight_elapsed / flight_duration, 0.0, 1.0)
	ball_forward_yards = t * travel_yards
	ball_lateral_yards = start_lateral_yards + ball_forward_yards * tan(deg_to_rad(final_angle_degrees))
	# The arc grows the ball on the way up and shrinks it on the way down.
	ball_height = sin(t * PI)


func sync_tee() -> void:
	# Puts the ball on its spot. Call this after changing the distance or the spot.
	_update_ball()
