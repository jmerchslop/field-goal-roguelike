class_name RunLogic
extends RefCounted

# The rules of one run: 20 kicks, attempts, and score.
# No drawing. main.gd asks this object what to show.

enum Phase { PLAYING, GAME_OVER, WIN }

const NOTE_EARNED := "+1 ATTEMPT"
const NOTE_CAP := "AT CAP"

var phase: Phase = Phase.PLAYING
var kick_number := 1
var attempts := KickConstants.ATTEMPTS_START
var attempt_cap := KickConstants.ATTEMPT_CAP
var score := 0
var streak := 0
var kicks_made := 0
var longest_make := 0.0
var spot_yards := 0.0
# True on every normal kick. A later retake can set this false, and then a make earns nothing.
var is_first_ball := true
# Copied from KickConstants at the start of a run so a test can flip it.
var late_earn_rule := KickConstants.LATE_EARN_RULE

var kick_resolved := false
var down_the_middle := false
var attempt_note := ""
var score_line := ""
var last_points := 0

# 0 means "roll the side". -1 or +1 forces the next hash/wide spot.
var _next_side := 0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()
	new_run()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func set_next_side(side: int) -> void:
	_next_side = side


func new_run() -> void:
	phase = Phase.PLAYING
	kick_number = 1
	attempts = KickConstants.ATTEMPTS_START
	attempt_cap = mini(KickConstants.ATTEMPT_CAP, KickConstants.ATTEMPT_CAP_MAX)
	score = 0
	streak = 0
	kicks_made = 0
	longest_make = 0.0
	is_first_ball = true
	late_earn_rule = KickConstants.LATE_EARN_RULE
	kick_resolved = false
	down_the_middle = false
	attempt_note = ""
	score_line = ""
	last_points = 0
	_place_spot()


func distance_yards() -> float:
	return float(RunTable.row(kick_number)["distance"])


func is_boss() -> bool:
	return str(RunTable.row(kick_number)["conditions"]) == RunTable.BOSS


# The multiplier for the kick you are on, from the streak before this kick.
func current_mult() -> float:
	return 1.0 + KickConstants.STREAK_MULT_STEP * float(streak)


func can_advance() -> bool:
	return phase == Phase.PLAYING and kick_resolved and kick_number < RunTable.count()


# R is allowed when the run is over. A miss on kick 20 with attempts left is also over:
# there is no kick 21, and it is not a win.
func accepts_restart() -> bool:
	if phase == Phase.GAME_OVER or phase == Phase.WIN:
		return true
	return kick_resolved and kick_number >= RunTable.count() and phase == Phase.PLAYING


func resolve_kick(result_text: String, offset: float, perfect: bool) -> void:
	if kick_resolved or phase != Phase.PLAYING:
		return
	kick_resolved = true
	var distance := distance_yards()
	var boss := is_boss()
	var made := result_text == "GOOD"
	down_the_middle = absf(offset) <= KickConstants.MIDDLE_YARDS
	attempt_note = ""
	score_line = ""
	last_points = 0
	if made:
		var mult := current_mult()
		last_points = points_for(distance, mult, down_the_middle, boss, perfect)
		score += last_points
		score_line = format_score_line(distance, mult, down_the_middle, boss, perfect)
		kicks_made += 1
		if distance > longest_make:
			longest_make = distance
		if earns_attempt(kick_number, is_first_ball, perfect, down_the_middle, late_earn_rule):
			if attempts >= attempt_cap:
				attempt_note = NOTE_CAP
			else:
				attempts = mini(attempt_cap, attempts + 1)
				attempt_note = NOTE_EARNED
		streak += 1
		if kick_number >= RunTable.count():
			phase = Phase.WIN
	else:
		streak = 0
		attempts -= 1
		if attempts <= 0:
			attempts = 0
			phase = Phase.GAME_OVER


func go_to_next_kick() -> bool:
	if not can_advance():
		return false
	kick_number += 1
	is_first_ball = true
	kick_resolved = false
	down_the_middle = false
	attempt_note = ""
	score_line = ""
	last_points = 0
	_place_spot()
	return true


static func earns_attempt(kick_number_value: int, first_ball: bool, perfect: bool, middle: bool, late_rule: bool) -> bool:
	if not first_ball:
		return false
	if late_rule and kick_number_value >= KickConstants.LATE_EARN_FROM_KICK:
		return perfect or middle
	return true


static func points_for(distance: float, mult: float, middle: bool, boss: bool, perfect: bool) -> int:
	return round_whole(raw_points(distance, mult, middle, boss, perfect))


static func raw_points(distance: float, mult: float, middle: bool, boss: bool, perfect: bool) -> float:
	var total := distance * mult
	if middle:
		total *= KickConstants.MIDDLE_MULTIPLIER
	if boss:
		total *= KickConstants.BOSS_MULTIPLIER
	if perfect:
		total += float(KickConstants.PERFECT_BONUS)
	return total


static func format_score_line(distance: float, mult: float, middle: bool, boss: bool, perfect: bool) -> String:
	var product := distance * mult
	var text := "%s yd × %s" % [_whole(distance), _two_decimals(mult)]
	if middle:
		product *= KickConstants.MIDDLE_MULTIPLIER
		text += " × 2"
	if boss:
		product *= KickConstants.BOSS_MULTIPLIER
		text += " × 1.5"
	text += " = %s" % _number(product)
	if perfect:
		text += " (+5 PERFECT)"
	return text


static func round_whole(value: float) -> int:
	# Half rounds away from zero. 47.5 becomes 48.
	if value >= 0.0:
		return int(floorf(value + 0.5))
	return int(ceilf(value - 0.5))


func _place_spot() -> void:
	var spot := str(RunTable.row(kick_number)["spot"])
	if spot == RunTable.SPOT_CENTER:
		spot_yards = 0.0
		return
	# A center kick does not use up a forced side. The next hash or wide kick does.
	var side := _next_side
	_next_side = 0
	if side == 0:
		side = -1 if _rng.randi_range(0, 1) == 0 else 1
	spot_yards = RunTable.spot_yards(spot, side)


static func _two_decimals(value: float) -> String:
	return "%.2f" % value


static func _whole(value: float) -> String:
	return str(int(roundf(value)))


static func _number(value: float) -> String:
	if absf(value - roundf(value)) < 0.001:
		return str(int(roundf(value)))
	var hundredths := int(roundf(absf(value) * 100.0))
	var whole := int(hundredths / 100)
	var frac := hundredths % 100
	if frac % 10 == 0:
		return "%d.%d" % [whole, int(frac / 10)]
	return "%d.%02d" % [whole, frac]
