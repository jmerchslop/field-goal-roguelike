class_name SpecialKicks
extends RefCounted

# Shared special-kick rules. ON FIRE is earned. Rolled specials can plug in later.

const ON_FIRE := "on_fire"

const KINDS := {
	ON_FIRE: "triggered",
}


static func eligible(run) -> bool:
	if run == null:
		return false
	if int(run.kick_number) <= 1:
		return false
	if run.practicing:
		return false
	if run.is_boss():
		return false
	if run.scheduled_ring() or run.ring_showing():
		return false
	return true


static func banner_lines(id: String) -> PackedStringArray:
	if id == ON_FIRE:
		return PackedStringArray(["SPECIAL KICK", "ON FIRE"])
	return PackedStringArray()
