class_name ResultStamp
extends RefCounted

# Screen-space arcade call for a judged kick. Judging itself stays in KickLogic.

const HOLD_SEC := 0.8
const SLAM_SEC := 0.18


static func hold_ready(age: float) -> bool:
	return age >= HOLD_SEC


static func words(shanked: bool, result: String, bank: bool, insured: bool, perfect: bool, middle: bool) -> PackedStringArray:
	if shanked:
		return PackedStringArray(["SHANK"])
	if result != "GOOD":
		if result == "SHORT" or result == "DOINK" or result == "WIDE LEFT" or result == "WIDE RIGHT":
			return PackedStringArray([result])
		return PackedStringArray([result])
	if bank:
		return PackedStringArray(["BANK SHOT"])
	if insured:
		return PackedStringArray(["INSURED"])
	if middle and perfect:
		return PackedStringArray(["DOWN THE MIDDLE", "PERFECT"])
	if middle:
		return PackedStringArray(["DOWN THE MIDDLE"])
	if perfect:
		return PackedStringArray(["PERFECT"])
	return PackedStringArray(["GOOD"])


static func primary_lines(word: String) -> PackedStringArray:
	if word == "WIDE LEFT" or word == "WIDE RIGHT" or word == "DOWN THE MIDDLE" or word == "BANK SHOT":
		var parts := word.split(" ")
		if word == "DOWN THE MIDDLE":
			return PackedStringArray(["DOWN THE", "MIDDLE"])
		return PackedStringArray(parts)
	return PackedStringArray([word])


static func power_line(shanked: bool, power: float, power_floor: float) -> String:
	if shanked:
		return "POWER 100"
	var used := KickLogic.power_for_range(power, power_floor)
	return "POWER %d" % int(round(clampf(used, 0.0, 100.0)))


static func accuracy_line(shanked: bool, perfect: bool, error: float, perfect_band: float, good_band: float) -> String:
	if shanked:
		return ""
	if perfect or absf(error) <= perfect_band:
		return "ACCURACY PERFECT"
	if absf(error) <= good_band:
		return "ACCURACY GOOD"
	return "ACCURACY BAD"


static func shakes(word: String) -> bool:
	return word == "DOINK" or word == "SHANK"
