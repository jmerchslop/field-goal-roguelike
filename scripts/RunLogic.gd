class_name RunLogic
extends RefCounted

# The rules of one run: 20 kicks, attempts, and score.
# No drawing. main.gd asks this object what to show.

enum Phase { PLAYING, GAME_OVER, WIN }

const NOTE_EARNED := "+1 ATTEMPT"
const NOTE_CAP := "AT CAP"

const CLEAR := "CLEAR"
const RAIN := "RAIN"
const SNOW := "SNOW"
const MUD := "MUD"
const THIN_AIR := "THIN AIR"
const ICED := "ICED"
const SQUEEZE := "THE SQUEEZE"
const MONSOON := "MONSOON"
const BIG_GAME := "BIG GAME"
const CURSE_ICED := "iced"
const CURSE_SHANKY := "shanky_cleats"
const CURSE_HEAVY := "heavy_ball"
const CURSE_HOWLING := "howling_wind"
const CURSE_SHAKY := "shaky_arrow"
const CURSE_NARROW := "narrow_posts"
const CURSE_IDS: Array = [CURSE_ICED, CURSE_SHANKY, CURSE_HEAVY, CURSE_HOWLING, CURSE_SHAKY, CURSE_NARROW]
const SQUEEZE_WIDTH := 5.17
const SQUEEZE_HALF := 2.585
const DEBUG_SPOTS: Array = [-6.0, -3.0, 0.0, 3.0, 6.0]

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
# Whole mph, and the direction it blows. Kept for a miss or a mulligan.
var wind_speed := 0
var wind_direction := 0.0
var weather := CLEAR
var weather_forced := false
var curse := ""
var curse_end_kick := 0
var curses_taken: Array = []
var doubled_copies := {}
var cursed_kick := 0
var insurance_left := 0
var practice_left := 0
var practicing := false

# 0 means "roll the side". -1 or +1 forces the next hash/wide spot.
var _next_side := 0
var _rng := RandomNumberGenerator.new()
var _wind_rng := RandomNumberGenerator.new()
var _weather_rng := RandomNumberGenerator.new()
var _offer_rng := RandomNumberGenerator.new()
var _previous_weather := ""
var _older_weather := ""
var _forced_offer: Array = []
var _force_cursed := false
var _cursed_offer_open := false
var _quarter_cursed_used := false
var _insurance_spent := false


func _init() -> void:
	_rng.randomize()
	_wind_rng.randomize()
	_weather_rng.randomize()
	_offer_rng.randomize()
	new_run()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	# Wind and weather have their own generators so a spot seed still lands on the same hash.
	_wind_rng.seed = seed_value + 7919
	_weather_rng.seed = seed_value + 1543


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
	wind_speed = 0
	wind_direction = 0.0
	weather = CLEAR
	weather_forced = false
	curse = ""
	curse_end_kick = 0
	curses_taken = []
	doubled_copies = {}
	_force_cursed = false
	_cursed_offer_open = false
	_quarter_cursed_used = false
	_previous_weather = ""
	_older_weather = ""
	insurance_left = 0
	practice_left = 0
	practicing = false
	_insurance_spent = false
	attempt_cap = stats.attempt_cap
	_refill_quarter()
	_place_spot()
	_roll_wind()
	_roll_weather()
	_pick_cursed_kick()


func distance_yards() -> float:
	return float(RunTable.row(kick_number)["distance"])


func is_boss() -> bool:
	return str(RunTable.row(kick_number)["conditions"]) == RunTable.BOSS


# The multiplier for the kick you are on, from the streak before this kick.
func current_mult() -> float:
	return 1.0 + stats.streak_step * float(streak)


func storm_bonus() -> float:
	return stats.storm_per_mph * absf(KickLogic.crosswind_mph(float(wind_speed), wind_direction))


func hero_bonus() -> float:
	if stats.hero_ball:
		return 1.0
	return 0.0


func wants_upgrade() -> bool:
	# Cards only after a make, and not on the win.
	return phase == Phase.PLAYING and kick_resolved and last_result_made


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
		var base_mult := current_mult()
		var storm := storm_bonus()
		var hero := hero_bonus()
		var mult := base_mult + storm + hero
		last_points = points_for(distance, mult, down_the_middle, boss, perfect)
		score += last_points
		score_line = format_score_line(distance, base_mult, down_the_middle, boss, perfect, storm, hero)
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
	# The quarter is over when its last kick ends the run. A make still clears on the advance.
	if phase != Phase.PLAYING and (kick_number == 5 or kick_number == 10 or kick_number == 15 or kick_number == 20):
		curse = ""
		curse_end_kick = 0


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
	_insurance_spent = false
	var leaving := kick_number - 1
	if leaving == 5 or leaving == 10 or leaving == 15 or leaving == 20:
		curse = ""
		curse_end_kick = 0
	_older_weather = _previous_weather
	_previous_weather = weather
	weather_forced = false
	if kick_number == 6 or kick_number == 11 or kick_number == 16:
		_pick_cursed_kick()
	_place_spot()
	_roll_wind()
	_roll_weather()
	_refill_quarter()
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
	rebuild_stats()
	rerolls_left = stats.rerolls_per_run


func has_rain() -> bool:
	return weather == RAIN or weather == MONSOON


func has_mud() -> bool:
	return weather == MUD or weather == MONSOON


func post_half_gap() -> float:
	if weather == SQUEEZE or curse == CURSE_NARROW:
		return SQUEEZE_HALF
	return KickConstants.POST_HALF_GAP_YARDS


func post_width() -> float:
	if weather == SQUEEZE or curse == CURSE_NARROW:
		return SQUEEZE_WIDTH
	return KickConstants.POST_SEPARATION_YARDS


func needle_fades() -> bool:
	# Kick 5 and the Iced curse share the current needle fade. The bar stays up.
	# Ice Veins is read from the owned card, so a BIG GAME strip cannot pair Iced.
	if int(stacks.get(Upgrades.ICE_VEINS, 0)) > 0 or stats.ice_veins:
		return false
	return weather == ICED or curse == CURSE_ICED


func force_weather(name: String) -> void:
	weather = name
	weather_forced = true


func prepare_kick_stats() -> void:
	rebuild_stats()
	if weather != BIG_GAME:
		return
	var base := KickerStats.new()
	if kicker_id != "":
		Kickers.apply_to(base, kicker_id)
	stats.power_speed = base.power_speed
	stats.accuracy_speed = base.accuracy_speed
	stats.perfect_band = base.perfect_band
	stats.good_band = base.good_band
	stats.red_tip_start = base.red_tip_start
	stats.red_tip_noise = base.red_tip_noise
	stats.ice_veins = false


func cycle_debug_spot() -> void:
	var best := 0
	var best_gap := 1000.0
	for i in DEBUG_SPOTS.size():
		var gap := absf(spot_yards - float(DEBUG_SPOTS[i]))
		if gap < best_gap:
			best_gap = gap
			best = i
	spot_yards = float(DEBUG_SPOTS[(best + 1) % DEBUG_SPOTS.size()])


static func spot_label(yards: float) -> String:
	if yards <= -5.0:
		return "LEFT WIDE"
	if yards < -0.5:
		return "LEFT HASH"
	if yards >= 5.0:
		return "RIGHT WIDE"
	if yards > 0.5:
		return "RIGHT HASH"
	return "CENTER"


static func boss_weather(kick: int) -> String:
	if kick == 5:
		return ICED
	if kick == 10:
		return SQUEEZE
	if kick == 15:
		return MONSOON
	if kick == 20:
		return BIG_GAME
	return ""


static func weather_pool(kick: int) -> Array:
	if kick <= 4:
		return [CLEAR]
	if kick >= 6 and kick <= 8:
		return [CLEAR, RAIN]
	if kick == 9:
		return [CLEAR, RAIN, SNOW]
	if (kick >= 11 and kick <= 14) or (kick >= 16 and kick <= 19):
		return [RAIN, SNOW, MUD, THIN_AIR]
	return [CLEAR]


static func roll_weather_name(kick: int, previous: String, older: String, rng: RandomNumberGenerator) -> String:
	var boss := boss_weather(kick)
	if boss != "":
		return boss
	var blocked := ""
	if previous != "" and previous == older:
		blocked = previous
	var pool: Array = weather_pool(kick)
	var allowed: Array = []
	for name in pool:
		if str(name) != blocked:
			allowed.append(name)
	if allowed.is_empty():
		allowed = pool
	for _try in 24:
		var pick := _weighted_weather(kick, rng)
		if allowed.has(pick):
			return pick
	return str(allowed[rng.randi_range(0, allowed.size() - 1)])


static func _weighted_weather(kick: int, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	if kick >= 6 and kick <= 8:
		return RAIN if roll < 0.30 else CLEAR
	if kick == 9:
		if roll < 0.30:
			return RAIN
		if roll < 0.50:
			return SNOW
		return CLEAR
	if (kick >= 11 and kick <= 14) or (kick >= 16 and kick <= 19):
		var names := [RAIN, SNOW, MUD, THIN_AIR]
		var index := int(roll * 4.0)
		if index > 3:
			index = 3
		return str(names[index])
	return CLEAR


# How far the accuracy needle has fallen from the locked power toward the bottom, 0 to 1.
# The iced needle fades out over the first 18% of that trip and is fully back by halfway.
const ICED_FADE_OUT := 0.18
const ICED_VISIBLE_AT := 0.5


static func iced_needle_alpha(fades: bool, on_accuracy: bool, power: float, needle: float) -> float:
	if not fades or not on_accuracy:
		return 1.0
	var span := power - KickConstants.METER_MIN
	if span <= 0.001:
		return 1.0
	var along := clampf((power - needle) / span, 0.0, 1.0)
	if along <= 0.0:
		return 1.0
	if along < ICED_FADE_OUT:
		return 1.0 - _smoothstep(along / ICED_FADE_OUT)
	if along < ICED_VISIBLE_AT:
		return _smoothstep((along - ICED_FADE_OUT) / (ICED_VISIBLE_AT - ICED_FADE_OUT))
	return 1.0


static func _smoothstep(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func set_wind(speed: float, direction: float) -> void:
	wind_speed = int(round(speed))
	wind_direction = direction


func apply_debug_wind() -> void:
	# W: 10 mph straight to the right. Stays until the next new kick, or another press.
	set_wind(10.0, 90.0)


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


func can_practice() -> bool:
	return practice_left > 0 and not practicing and int(stacks.get(Upgrades.PRACTICE_SWING, 0)) > 0


func start_practice() -> bool:
	if not can_practice():
		return false
	practice_left -= 1
	practicing = true
	return true


func end_practice() -> void:
	practicing = false


func consume_insurance() -> void:
	if _insurance_spent or insurance_left <= 0:
		return
	insurance_left -= 1
	_insurance_spent = true


func force_cursed_offer() -> void:
	_force_cursed = true


func roll_offer() -> void:
	if phase != Phase.PLAYING:
		awaiting_offer = false
		offer = []
		return
	if _forced_offer.size() > 0:
		offer = _wrap_forced(_forced_offer)
		_forced_offer = []
		_cursed_offer_open = false
	else:
		offer = _make_offer()
	awaiting_offer = true


func pick_card(index: int) -> bool:
	if not awaiting_offer or index < 0 or index >= offer.size():
		return false
	var card: Dictionary = _as_card(offer[index])
	var id := str(card["id"])
	var doubled := bool(card.get("doubled", false))
	if doubled:
		_grant_copy(id, true)
		if str(card.get("curse", "")) != "":
			_activate_curse(str(card["curse"]))
	else:
		grant(id)
	_cursed_offer_open = false
	_close_offer()
	return true


func skip_offer() -> bool:
	if not awaiting_offer:
		return false
	score += 10
	_cursed_offer_open = false
	_close_offer()
	return true


func reroll_offer() -> bool:
	if not awaiting_offer or rerolls_left <= 0:
		return false
	rerolls_left -= 1
	if _cursed_offer_open:
		offer = _cursed_trio()
	else:
		offer = _plain_cards(3)
	return true


func grant(id: String) -> void:
	_grant_copy(id, false)


func _grant_copy(id: String, doubled: bool) -> void:
	var info := Upgrades.get_def(id)
	if info.is_empty():
		return
	if int(stacks.get(id, 0)) >= int(info["max_stacks"]):
		return
	var cap_before := attempt_cap
	stacks[id] = int(stacks.get(id, 0)) + 1
	if doubled:
		doubled_copies[id] = int(doubled_copies.get(id, 0)) + 1
	rebuild_stats()
	var cap_gain := attempt_cap - cap_before
	if id == Upgrades.DEEP_BENCH:
		if cap_gain > 0:
			attempts = mini(attempts + cap_gain, attempt_cap)
	elif id == Upgrades.GLASS_LEG:
		if attempts > attempt_cap:
			attempts = attempt_cap
	elif id == Upgrades.MULLIGAN:
		mulligans_left += 1
	elif id == Upgrades.SCOUTING_REPORT:
		rerolls_left += 2 if doubled else 1
	elif id == Upgrades.WIDE_RIGHT_INSURANCE:
		insurance_left += 1
	elif id == Upgrades.PRACTICE_SWING:
		practice_left += 1


func rebuild_stats() -> void:
	stats.reset()
	if kicker_id != "":
		Kickers.apply_to(stats, kicker_id)
	for item in Upgrades.DEFS:
		var id := str(item["id"])
		var copies := int(stacks.get(id, 0))
		var doubles := mini(int(doubled_copies.get(id, 0)), copies)
		var singles := copies - doubles
		for _i in singles:
			Upgrades.apply(id, stats, false)
		for _j in doubles:
			Upgrades.apply(id, stats, true)
	attempt_cap = mini(stats.attempt_cap, KickConstants.ATTEMPT_CAP_MAX)


func curse_label() -> String:
	return curse_name(curse)


static func curse_name(id: String) -> String:
	match id:
		CURSE_ICED:
			return "Iced"
		CURSE_SHANKY:
			return "Shanky Cleats"
		CURSE_HEAVY:
			return "Heavy Ball"
		CURSE_HOWLING:
			return "Howling Wind"
		CURSE_SHAKY:
			return "Shaky Arrow"
		CURSE_NARROW:
			return "Narrow Posts"
	return ""


func _quarter_end(kick: int) -> int:
	if kick <= 5:
		return 5
	if kick <= 10:
		return 10
	if kick <= 15:
		return 15
	return 20


func _pick_cursed_kick() -> void:
	var start := 1
	if kick_number >= 16:
		start = 16
	elif kick_number >= 11:
		start = 11
	elif kick_number >= 6:
		start = 6
	cursed_kick = start + _offer_rng.randi_range(0, 3)
	_quarter_cursed_used = false
	_cursed_offer_open = false


func _activate_curse(id: String) -> void:
	curse = id
	curse_end_kick = _quarter_end(kick_number)
	curses_taken.append(curse_label())


func _make_offer() -> Array:
	var want := _force_cursed or (kick_number == cursed_kick and not _quarter_cursed_used)
	_force_cursed = false
	if not want:
		_cursed_offer_open = false
		return _plain_cards(3)
	var cursed := _cursed_trio()
	if cursed.is_empty():
		_cursed_offer_open = false
		_quarter_cursed_used = true
		return _plain_cards(3)
	_cursed_offer_open = true
	_quarter_cursed_used = true
	return cursed


func _plain_cards(count: int) -> Array:
	var ids: Array = Upgrades.draw_offer(Upgrades.eligible_ids(stacks, attempt_cap), _offer_rng)
	var cards: Array = []
	for id in ids:
		cards.append(_blank_card(str(id)))
	return cards


func _cursed_trio() -> Array:
	var bonus: Array = []
	for id in Upgrades.DOUBLED_IDS:
		if int(stacks.get(id, 0)) < int(Upgrades.get_def(str(id))["max_stacks"]):
			bonus.append(str(id))
	if bonus.is_empty():
		return []
	var bonus_id := str(bonus[_offer_rng.randi_range(0, bonus.size() - 1)])
	var curse_id := _roll_curse()
	var pool: Array = Upgrades.eligible_ids(stacks, attempt_cap)
	pool.erase(bonus_id)
	var others: Array = Upgrades.draw_offer(pool, _offer_rng)
	while others.size() > 2:
		others.pop_back()
	var cards: Array = [_cursed_card(bonus_id, curse_id)]
	for id in others:
		cards.append(_blank_card(str(id)))
	if cards.size() == 3 and not _cards_have_common(cards):
		var taken := {}
		for card in cards:
			taken[str(_as_card(card)["id"])] = true
		var commons: Array = []
		for id in pool:
			if Upgrades.is_common(str(id)) and not taken.has(str(id)):
				commons.append(str(id))
		if commons.size() > 0:
			cards[1 + _offer_rng.randi_range(0, 1)] = _blank_card(str(commons[_offer_rng.randi_range(0, commons.size() - 1)]))
	_shuffle_cards(cards)
	return cards


func _roll_curse() -> String:
	var choices: Array = []
	var owns_ice := int(stacks.get(Upgrades.ICE_VEINS, 0)) > 0
	for id in CURSE_IDS:
		if str(id) == CURSE_ICED and owns_ice:
			continue
		choices.append(str(id))
	return str(choices[_offer_rng.randi_range(0, choices.size() - 1)])


func _cards_have_common(cards: Array) -> bool:
	for card in cards:
		if Upgrades.is_common(str(_as_card(card)["id"])) and not bool(_as_card(card).get("cursed", false)):
			return true
		if Upgrades.is_common(str(_as_card(card)["id"])):
			return true
	return false


func _shuffle_cards(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j := _offer_rng.randi_range(0, i)
		var swap = cards[i]
		cards[i] = cards[j]
		cards[j] = swap


func _blank_card(id: String) -> Dictionary:
	return {"id": id, "cursed": false, "curse": "", "doubled": false}


func _cursed_card(id: String, curse_id: String) -> Dictionary:
	return {"id": id, "cursed": true, "curse": curse_id, "doubled": true}


func _as_card(item) -> Dictionary:
	if item is Dictionary:
		return item
	return _blank_card(str(item))


func _wrap_forced(raw: Array) -> Array:
	var cards: Array = []
	for item in raw:
		cards.append(_as_card(item))
	return cards


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


func _refill_quarter() -> void:
	if kick_number == 1 or kick_number == 6 or kick_number == 11 or kick_number == 16:
		mulligans_left = stats.mulligans_per_quarter
		insurance_left = stats.insurance_per_quarter
		practice_left = stats.practice_per_quarter
		_insurance_spent = false


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


static func format_score_line(distance: float, mult: float, middle: bool, boss: bool, perfect: bool, storm: float = 0.0, hero: float = 0.0) -> String:
	var product := distance * (mult + storm + hero)
	var text := "%s yd × %s" % [_whole(distance), _two_decimals(mult)]
	if storm > 0.001 or hero > 0.001:
		text = "%s yd × (%s" % [_whole(distance), _two_decimals(mult)]
		if storm > 0.001:
			text += " + %s wind" % _two_decimals(storm)
		if hero > 0.001:
			text += " + %s hero" % _two_decimals(hero)
		text += ")"
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


func _roll_weather() -> void:
	if weather_forced:
		return
	weather = roll_weather_name(kick_number, _previous_weather, _older_weather, _weather_rng)


func _roll_wind() -> void:
	var info := RunTable.row(kick_number)
	var lo := int(info["wind_min"])
	var hi := int(info["wind_max"])
	wind_speed = _wind_rng.randi_range(lo, hi)
	if wind_speed <= 0:
		wind_speed = 0
		wind_direction = 0.0
		return
	wind_direction = float(_wind_rng.randi_range(0, 359))


static func wind_name(speed: int) -> String:
	if speed <= 0:
		return "Calm"
	if speed <= 7:
		return "Breezy"
	if speed <= 15:
		return "Windy"
	return "GALE"


static func wind_readout(speed: int, direction: float) -> String:
	var cross := KickLogic.crosswind_mph(float(speed), direction)
	var tail := KickLogic.head_tail_mph(float(speed), direction)
	return "%d mph   cross %s   tail %s" % [speed, KickLogic.format_signed(cross), KickLogic.format_signed(tail)]


static func wind_flag_kind(speed: int) -> String:
	if speed <= 0:
		return "none"
	if speed <= 7:
		return "short"
	if speed <= 15:
		return "medium"
	return "long"


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
