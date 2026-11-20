class_name MeterGauge
extends RefCounted

# Screen angles for the semicircle gauge. 0 is to the right, 90 is up, 180 is to the left.
# The live needle rests at MAX (90). Space starts a flick to POWER (180), then a
# constant-angular-speed sweep back to MAX. Accuracy is the right half only:
# just after MAX is e=+15, the center is e=0, and the ACCURACY label is e=-15.

# ω0 is the old default: POWER → MAX took 1.0s when power_speed was 100.
# Every kicker shares a faster baseline. Accuracy sizes the wedges, not the needle.
const OMEGA0 := 90.0
const SWEEP_SEC := 0.600
# Item, perk, and vitamin slows multiply together, then stop at this floor.
# Stone Toe, UNDER THE LIGHTS, TAD 7, Training Camp, and rain are speed-ups after it.
const NEEDLE_SLOW_FLOOR := 0.40
# Stone × lights × TAD 7 × Training Camp × rain never passes this. Ball speed sits outside it.
const NEEDLE_SPEEDUP_CEILING := 1.60
const WINDUP_SEC := 0.08
const POWER_ANGLE := 180.0
const MAX_ANGLE := 90.0
const ACCURACY_ANGLE := 0.0
const ERROR_AT_MAX := 15.0
# Playing Card frame. The groove is empty, so the live bands fill it edge to edge.
const FRAME_PATH := "res://art/ui/kick_meter_card.png"
const FRAME_W := 1003.0
const FRAME_H := 625.0
const HUB_X := 504.0
const HUB_Y := 510.0
const GROOVE_INNER := 300.0
const GROOVE_OUTER := 395.0
const WELL_RADIUS := 286.0
const NEEDLE_PATH := "res://art/ui/kick_needle.png"
const NEEDLE_PIVOT := Vector2(30, 372)
const NEEDLE_TIP := 366.0


static func omega_base() -> float:
	return OMEGA0 * (1.0 / SWEEP_SEC)


static func floored_slow(product: float) -> float:
	if product < NEEDLE_SLOW_FLOOR:
		return NEEDLE_SLOW_FLOOR
	return product


# slow_product is only multipliers below 1 from items, perks, and vitamins.
# stone, lights, rain, and ball are speed-ups (or a kicker ball rate) and are never floored.
static func needle_speed(base: float, slow_product: float, stone: float, lights: float, rain: float, ball: float) -> float:
	return base * floored_slow(slow_product) * stone * lights * rain * ball


static func omega_power(power_speed: float, ball_speed_mult: float = 1.0) -> float:
	return omega_base() * (power_speed / 100.0) * ball_speed_mult


static func omega_accuracy(accuracy_speed: float, ball_speed_mult: float = 1.0) -> float:
	return omega_base() * (accuracy_speed / 120.0) * ball_speed_mult


static func power_angle(power_value: float) -> float:
	var t := clampf(power_value / KickConstants.METER_MAX, 0.0, 1.0)
	return lerpf(POWER_ANGLE, MAX_ANGLE, t)


# The OVERPOWER band continues past MAX. Power above 100 is a lower angle.
static func power_angle_raw(power_value: float) -> float:
	var t := maxf(power_value, 0.0) / KickConstants.METER_MAX
	return lerpf(POWER_ANGLE, MAX_ANGLE, t)


static func power_from_angle(angle: float) -> float:
	var t := clampf((POWER_ANGLE - angle) / (POWER_ANGLE - MAX_ANGLE), 0.0, 1.0)
	return t * KickConstants.METER_MAX


static func power_from_angle_raw(angle: float) -> float:
	var t := (POWER_ANGLE - angle) / (POWER_ANGLE - MAX_ANGLE)
	return maxf(t, 0.0) * KickConstants.METER_MAX


static func angle_from_error(error_value: float) -> float:
	var e := clampf(error_value, KickConstants.METER_MIN, ERROR_AT_MAX)
	return (e + ERROR_AT_MAX) / (ERROR_AT_MAX * 2.0) * MAX_ANGLE


static func error_from_angle(angle: float) -> float:
	var a := clampf(angle, ACCURACY_ANGLE, MAX_ANGLE)
	return (a / MAX_ANGLE) * (ERROR_AT_MAX * 2.0) - ERROR_AT_MAX


static func accuracy_layout(perfect_band: float, good_band: float) -> Dictionary:
	# Wedge edges sit on the linear error scale, so a wider band is a wider arc
	# and the middle of PERFECT stays at the center of the right half.
	var good := maxf(good_band, 0.5)
	var perfect := clampf(perfect_band, 0.25, good)
	var perfect_top := angle_from_error(perfect)
	var perfect_bottom := angle_from_error(-perfect)
	return {
		"good": good,
		"perfect": perfect,
		"band_top": angle_from_error(good),
		"band_bottom": angle_from_error(-good),
		"perfect_top": perfect_top,
		"perfect_bottom": perfect_bottom,
		"perfect_span": perfect_top - perfect_bottom,
	}


static func accuracy_angle(value: float, _perfect_band: float, _good_band: float) -> float:
	return angle_from_error(value)


static func is_red_tip(power_value: float, tip_start: float) -> bool:
	return power_value >= tip_start


# The sprite points up at rotation 0. Screen rotation 90 − angle keeps 90 up,
# 180 left, and 0 right. The tip sits NEEDLE_TIP pixels above the pivot.
static func needle_tip(hub: Vector2, angle_deg: float, scale: float) -> Vector2:
	var local := Vector2(0.0, -NEEDLE_TIP) * scale
	return hub + local.rotated(deg_to_rad(90.0 - angle_deg))
