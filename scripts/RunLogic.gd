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
var last_result_made := false
var kicker_id := ""
var down_the_middle := false
var attempt_note := ""
var score_line := ""
var last_points := 0

var stats := KickerStats.new()
var stacks := {}
var offer: Array = []
var awaiting_offer := false
var awaiting_mulligan := false
var mulligans_left := 0
var mulligan_used_this_kick := false
var rerolls_left := 1
var pending_result := ""
var pending_offset := 0.0
var pending_perfect := false

# 0 means "roll the side". -1 or +1 forces the next hash/wide spot.
var _next_side := 0
var _rng := RandomNumberGenerator.new()
var _offer_rng := RandomNumberGenerator.new()
var _forced_offer: Array = []


func _init() -> void:
	_rng.randomize()
	_offer_rng.randomize()
	new_run()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func set_offer_seed(seed_value: int) -> void:
	_offer_rng.seed = seed_value


func force_offer(ids: Array) -> void:
	_forced_offer = ids.duplicate()


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
	last_result_made = false
	kicker_id = ""
	down_the_middle = false
	attempt_note = ""
	score_line = ""
	last_points = 0
	stats.reset()
	stacks = {}
	offer = []
	awaiting_offer = false
	awaiting_mulligan = false
	mulligan_used_this_kick = false
	rerolls_left = stats.rerolls_per_run
	pending_result = ""
	attempt_cap = stats.attempt_cap
	_refill_mulligans()
	_place_spot()


func distance_yards() -> float:
	return float(RunTable.row(kick_number)["distance"])


func is_boss() -> bool:
	return str(RunTable.row(kick_number)["conditions"]) == RunTable.BOSS


# The multiplier for the kick you are on, from the streak before this kick.
func current_mult() -> float:
	return 1.0 + stats.streak_step * float(streak)


func can_advance() -> bool:
	# Only a make moves the kick number. A miss retries this same kick.
	return phase == Phase.PLAYING and kick_resolved and last_result_made and kick_number < RunTable.count()


# R is allowed when the run is over. A miss on kick 20 with attempts left is also over:
# there is no kick 21, and it is not a win.
func accepts_restart() -> bool:
	return phase == Phase.GAME_OVER or phase == Phase.WIN


func resolve_kick(result_text: String, offset: float, perfect: bool) -> void:
	if kick_resolved or phase != Phase.PLAYING:
		return
	kick_resolved = true
	var made := result_text == "GOOD"
	last_result_made = made
	var distance := distance_yards()
	var boss := is_boss()
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
		is_first_ball = false
		if attempts <= 0:
			attempts = 0
			phase = Phase.GAME_OVER


func go_to_next_kick() -> bool:
	if not can_advance():
		return false
	kick_number += 1
	is_first_ball = true
	kick_resolved = false
	last_result_made = false
	down_the_middle = false
	attempt_note = ""
	score_line = ""
	last_points = 0
	awaiting_offer = false
	awaiting_mulligan = false
	offer = []
	mulligan_used_this_kick = false
	_place_spot()
	_refill_mulligans()
	return true


func begin_retry() -> bool:
	# After a miss and the upgrade screen, kick the same distance and spot again.
	if phase != Phase.PLAYING or not kick_resolved or last_result_made:
		return false
	kick_resolved = false
	is_first_ball = false
	awaiting_offer = false
	offer = []
	attempt_note = ""
	score_line = ""
	down_the_middle = false
	return true


func start_with_kicker(id: String) -> void:
	new_run()
	kicker_id = id
	Kickers.apply_to(stats, id)
	attempt_cap = mini(stats.attempt_cap, KickConstants.ATTEMPT_CAP_MAX)
	rerolls_left = stats.rerolls_per_run


func can_mulligan(result_text: String) -> bool:
	return result_text != "GOOD" and mulligans_left > 0 and not mulligan_used_this_kick and phase == Phase.PLAYING


func begin_mulligan(result_text: String, offset: float, perfect: bool) -> void:
	awaiting_mulligan = true
	pending_result = result_text
	pending_offset = offset
	pending_perfect = perfect


func use_mulligan() -> bool:
	if not awaiting_mulligan:
		return false
	awaiting_mulligan = false
	mulligans_left -= 1
	mulligan_used_this_kick = true
	is_first_ball = false
	pending_result = ""
	return true


func accept_pending_miss() -> void:
	if not awaiting_mulligan:
		return
	awaiting_mulligan = false
	resolve_kick(pending_result, pending_offset, pending_perfect)


func roll_offer() -> void:
	if phase != Phase.PLAYING:
		awaiting_offer = false
		offer = []
		return
	if _forced_offer.size() > 0:
		offer = _forced_offer.duplicate()
		_forced_offer = []
	else:
		offer = Upgrades.draw_offer(Upgrades.eligible_ids(stacks), _offer_rng)
	awaiting_offer = true


func pick_card(index: int) -> bool:
	if not awaiting_offer or index < 0 or index >= offer.size():
		return false
	grant(str(offer[index]))
	_close_offer()
	return true


func skip_offer() -> bool:
	if not awaiting_offer:
		return false
	score += 10
	_close_offer()
	return true


func reroll_offer() -> bool:
	if not awaiting_offer or rerolls_left <= 0:
		return false
	rerolls_left -= 1
	offer = Upgrades.draw_offer(Upgrades.eligible_ids(stacks), _offer_rng)
	return true


func grant(id: String) -> void:
	var info := Upgrades.get_def(id)
	if info.is_empty():
		return
	if int(stacks.get(id, 0)) >= int(info["max_stacks"]):
		return
	Upgrades.apply(id, stats)
	stacks[id] = int(stacks.get(id, 0)) + 1
	attempt_cap = mini(stats.attempt_cap, KickConstants.ATTEMPT_CAP_MAX)
	if id == Upgrades.DEEP_BENCH:
		attempts = mini(attempts + 1, attempt_cap)
	elif id == Upgrades.MULLIGAN:
		mulligans_left += 1


func owned_ids() -> Array:
	var ids: Array = []
	for item in Upgrades.DEFS:
		var id := str(item["id"])
		if int(stacks.get(id, 0)) > 0:
			ids.append(id)
	return ids


func _close_offer() -> void:
	awaiting_offer = false
	offer = []


func _refill_mulligans() -> void:
	if kick_number == 1 or kick_number == 6 or kick_number == 11 or kick_number == 16:
		mulligans_left = stats.mulligans_per_quarter


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
