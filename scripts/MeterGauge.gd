class_name MeterGauge
extends RefCounted

# Screen angles for the semicircle gauge. 0 is to the right, 90 is up, 180 is to the left.
# Power fills the left half from 180 (P=0) toward 90 (MAX).
# Accuracy sweeps the right half. Error 0 sits in the middle of that half.
# Band widths come from the live perfect and good bands.


static func power_angle(power_value: float) -> float:
	var t := clampf(power_value / KickConstants.METER_MAX, 0.0, 1.0)
	return lerpf(180.0, 90.0, t)


static func accuracy_layout(perfect_band: float, good_band: float) -> Dictionary:
	var good := maxf(good_band, 0.5)
	var perfect := clampf(perfect_band, 0.25, good)
	var upper_span := maxf(KickConstants.METER_MAX - good, 1.0)
	var lower_span := maxf(good - KickConstants.METER_MIN, 1.0)
	var band_span := good * 2.0
	# Give the colored bands more of the arc than the long red approach, so a wider band looks wider.
	var weight_band := band_span * 4.0
	var total := upper_span + lower_span + weight_band
	var band_deg := clampf(90.0 * weight_band / total, 16.0, 68.0)
	var band_top := 45.0 + band_deg * 0.5
	var band_bottom := 45.0 - band_deg * 0.5
	var perfect_deg := band_deg * (perfect / good)
	return {
		"good": good,
		"perfect": perfect,
		"band_top": band_top,
		"band_bottom": band_bottom,
		"perfect_top": 45.0 + perfect_deg * 0.5,
		"perfect_bottom": 45.0 - perfect_deg * 0.5,
		"perfect_span": perfect_deg,
	}


static func accuracy_angle(value: float, perfect_band: float, good_band: float) -> float:
	var layout := accuracy_layout(perfect_band, good_band)
	var good := float(layout["good"])
	var band_top := float(layout["band_top"])
	var band_bottom := float(layout["band_bottom"])
	if value >= good:
		var t := clampf((KickConstants.METER_MAX - value) / maxf(KickConstants.METER_MAX - good, 0.001), 0.0, 1.0)
		return lerpf(90.0, band_top, t)
	if value <= -good:
		var span := maxf(-good - KickConstants.METER_MIN, 0.001)
		var t := clampf((-good - value) / span, 0.0, 1.0)
		return lerpf(band_bottom, 0.0, t)
	var t_band := clampf((good - value) / (good * 2.0), 0.0, 1.0)
	return lerpf(band_top, band_bottom, t_band)


static func is_red_tip(power_value: float, tip_start: float) -> bool:
	return power_value >= tip_start
