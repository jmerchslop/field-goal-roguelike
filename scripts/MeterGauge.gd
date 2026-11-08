class_name MeterGauge
extends RefCounted

# Screen angles for the semicircle gauge. 0 is to the right, 90 is up, 180 is to the left.
# The live needle rests at MAX (90). Space starts a flick to POWER (180), then a
# constant-angular-speed sweep back to MAX. Accuracy is the right half only:
# just after MAX is e=+15, the center is e=0, and the ACCURACY label is e=-15.

const OMEGA0 := 90.0
const WINDUP_SEC := 0.08
const POWER_ANGLE := 180.0
const MAX_ANGLE := 90.0
const ACCURACY_ANGLE := 0.0
const ERROR_AT_MAX := 15.0
const KEY_LEVEL := 16


static func omega_power(power_speed: float) -> float:
	return OMEGA0 * (power_speed / 100.0)


static func omega_accuracy(accuracy_speed: float) -> float:
	return OMEGA0 * (accuracy_speed / 120.0)


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


# Near-pure black (R, G, and B all <= 16) becomes transparent. The baked silver
# needle is cleared so it cannot sit beside the live needle. Painted orange and
# wedge colors in the band are cleared too; the live fill and wedges replace them.
# White labels and the gray frame stay. The source file is not modified.
static func key_meter_image(source: Image) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var bytes := image.get_data()
	var hub_x := 504.0
	var hub_y := 510.0
	var count := width * height
	for i in count:
		var offset := i * 4
		var red := int(bytes[offset])
		var green := int(bytes[offset + 1])
		var blue := int(bytes[offset + 2])
		var x := float(i % width)
		var y := float(int(i / width))
		var dx := x - hub_x
		var dy := y - hub_y
		var radius := sqrt(dx * dx + dy * dy)
		# The baked needle lies on the 45° ray, where dx + dy is 0.
		var perp := absf(dx + dy) * 0.70710678
		var clear := false
		if red <= KEY_LEVEL and green <= KEY_LEVEL and blue <= KEY_LEVEL:
			clear = true
		elif radius >= 52.0 and radius <= 275.0:
			# The open well. Anything left in here is the baked needle.
			clear = true
		elif radius >= 250.0 and radius <= 455.0:
			var high := maxi(red, maxi(green, blue))
			var low := mini(red, mini(green, blue))
			var near_white := red > 200 and green > 190 and blue > 170
			if high - low > 30 and not near_white and high > 40:
				clear = true
		# The baked needle also crosses the colored band, including its white highlight.
		if not clear and radius > 250.0 and radius < 430.0 and perp <= 11.0:
			clear = true
		if clear:
			bytes[offset + 3] = 0
	image.set_data(width, height, false, Image.FORMAT_RGBA8, bytes)
	return image
