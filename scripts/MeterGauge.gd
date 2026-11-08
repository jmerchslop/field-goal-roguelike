class_name MeterGauge
extends RefCounted

# Screen angles for the semicircle gauge. 0 is to the right, 90 is up, 180 is to the left.
# The live needle rests at MAX (90). Space starts a flick to POWER (180), then a
# constant-angular-speed sweep back to MAX. Accuracy is the right half only:
# just after MAX is e=+15, the center is e=0, and the ACCURACY label is e=-15.

# ω0 is the old default: POWER → MAX took 1.0s when power_speed was 100.
# Every kicker shares a faster baseline. Accuracy sizes the wedges, not the needle.
const OMEGA0 := 90.0
const SWEEP_SEC := 0.700
const WINDUP_SEC := 0.08
const POWER_ANGLE := 180.0
const MAX_ANGLE := 90.0
const ACCURACY_ANGLE := 0.0
const ERROR_AT_MAX := 15.0
# Source-image geometry of res://art/ui/kick_meter.png. The outside backdrop is
# already transparent. The open middle is filled; it is not color-keyed.
const HUB_X := 504.0
const HUB_Y := 510.0
const WELL_INNER := 58.0
const WELL_OUTER := 270.0
const NEEDLE_INNER := 270.0
const NEEDLE_OUTER := 410.0
const NEEDLE_HALF := 9.0


static func omega_base() -> float:
	return OMEGA0 * (1.0 / SWEEP_SEC)


static func omega_power(power_speed: float, ball_speed_mult: float = 1.0) -> float:
	return omega_base() * (power_speed / 100.0) * ball_speed_mult


static func omega_accuracy(accuracy_speed: float, ball_speed_mult: float = 1.0) -> float:
	return omega_base() * (accuracy_speed / 120.0) * ball_speed_mult


static func power_angle(power_value: float) -> float:
	var t := clampf(power_value / KickConstants.METER_MAX, 0.0, 1.0)
	return lerpf(POWER_ANGLE, MAX_ANGLE, t)


static func power_from_angle(angle: float) -> float:
	var t := clampf((POWER_ANGLE - angle) / (POWER_ANGLE - MAX_ANGLE), 0.0, 1.0)
	return t * KickConstants.METER_MAX


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


# The rectangular backdrop stays transparent. Nothing else is color-keyed:
# dark frame pixels, wedge pixels, and labels stay opaque. The open middle
# becomes one flat fill, and the baked needle is painted over so only the
# live needle remains. The source file is not modified.
static func key_meter_image(source: Image) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	if width < 800 or height < 500:
		return image
	var original := image.get_data()
	var bytes := original.duplicate()
	var count := width * height
	var step := 0.70710678
	for i in count:
		var x := i % width
		var y := int(i / width)
		var dx := float(x) - HUB_X
		var dy := float(y) - HUB_Y
		var radius := sqrt(dx * dx + dy * dy)
		var offset := i * 4
		# The painted well is not a perfect circle. Fill the open middle, including
		# the transparent ring that sits against the inner lip, and cover the
		# baked needle there. Opaque lip pixels stay.
		# Soft pixels between the well and the painted arc are the peek-through ring.
		var in_upper := dy <= 4.0 and radius >= WELL_INNER and radius <= 340.0
		var open_pixel := int(original[offset + 3]) < 250
		if in_upper and (radius <= WELL_OUTER or open_pixel):
			bytes[offset] = 18
			bytes[offset + 1] = 20
			bytes[offset + 2] = 24
			bytes[offset + 3] = 255
			continue
		if radius < NEEDLE_INNER or radius > NEEDLE_OUTER:
			continue
		var perp := absf(dx + dy) * step
		if perp > NEEDLE_HALF:
			continue
		var sx := int(round(float(x) + 16.0 * step))
		var sy := int(round(float(y) + 16.0 * step))
		if sx < 0 or sy < 0 or sx >= width or sy >= height:
			continue
		var src := (sy * width + sx) * 4
		if int(original[src + 3]) == 0:
			continue
		bytes[offset] = original[src]
		bytes[offset + 1] = original[src + 1]
		bytes[offset + 2] = original[src + 2]
		bytes[offset + 3] = 255
	image.set_data(width, height, false, Image.FORMAT_RGBA8, bytes)
	return image
