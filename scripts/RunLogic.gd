class_name RunLogic
extends RefCounted

# The rules of one run: 20 kicks, attempts, and score.
# No drawing. main.gd asks this object what to show.

enum Phase { PLAYING, GAME_OVER, WIN, FAR }

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
const SQUEEZE_WIDTH := 5.17
const SQUEEZE_HALF := 2.585
const DEBUG_SPOTS: Array = [-6.0, -3.0, 0.0, 3.0, 6.0]

var phase: Phase = Phase.PLAYING
# "standard" is the 20-kick season. "endless" is stored for a later prompt.
# This prompt still ends the run after kick 20 either way.
var run_mode := "standard"
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
var offer: Array = []
var cleats_id := ""
var cleats_rank := 0
var helmet_id := ""
var helmet_rank := 0
var gloves_id := ""
var gloves_rank := 0
var perks: Array = []
var curse_ids: Array = []
var balls_kicked := 0
var middles_this_run := 0
var best_streak := 0
var clean_makes := {}
var trophy_name := ""
var new_record_score := false
var new_record_long := false
var _run_saved := false
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
# Endless boss name kept for that kick number, including a shop preview.
var endless_bosses := {}
var _forced_cards: Array = []
var insurance_left := 0
var practice_left := 0
var practicing := false
# Run-only. Never written into SaveData.
var cash := 0
var cash_popup := ""
var unlock_toast := ""
var lucky_stacks := 0
var showtime_mult := 1.0
var shop_guaranteed := false
var belt: Array = ["", ""]
var active_vitamins := {}
var zinc_used := false
var vitamin_note := ""
var awaiting_shop := false
var shop_stock: Array = ["", "", ""]
var shop_b12_bought := false
var shop_reroll_price := 2
var shop_flash := ""
var shop_note := ""
var curse_prompt := false
var curse_prompt_slot := -1
var curses_locked := false
var banned_curses: Array = []

# 0 means "roll the side". -1 or +1 forces the next hash/wide spot.
var _next_side := 0
var _rng := RandomNumberGenerator.new()
var _wind_rng := RandomNumberGenerator.new()
var _weather_rng := RandomNumberGenerator.new()
var _offer_rng := RandomNumberGenerator.new()
var _shop_rng := RandomNumberGenerator.new()
var _previous_weather := ""
var _older_weather := ""
var _insurance_spent := false


func _init() -> void:
	_rng.randomize()
	_wind_rng.randomize()
	_weather_rng.randomize()
	_offer_rng.randomize()
	_shop_rng.randomize()
	new_run()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	# Wind and weather have their own generators so a spot seed still lands on the same hash.
	_wind_rng.seed = seed_value + 7919
	_weather_rng.seed = seed_value + 1543
	_shop_rng.seed = seed_value + 4409


func set_offer_seed(seed_value: int) -> void:
	_offer_rng.seed = seed_value


func force_offer(cards: Array) -> void:
	_forced_cards = cards.duplicate(true)


func set_next_side(side: int) -> void:
	_next_side = side


func new_run() -> void:
	phase = Phase.PLAYING
	run_mode = "standard"
	endless_bosses = {}
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
	offer = []
	cleats_id = ""
	cleats_rank = 0
	helmet_id = ""
	helmet_rank = 0
	gloves_id = ""
	gloves_rank = 0
	perks = []
	curse_ids = []
	balls_kicked = 0
	middles_this_run = 0
	best_streak = 0
	clean_makes = {}
	lucky_stacks = 0
	showtime_mult = 1.0
	shop_guaranteed = false
	unlock_toast = ""
	trophy_name = ""
	new_record_score = false
	new_record_long = false
	_run_saved = false
	_forced_cards = []
	awaiting_offer = false
	awaiting_mulligan = false
	mulligan_used_this_kick = false
	rerolls_left = stats.rerolls_per_run
	pending_result = ""
	wind_speed = 0
	wind_direction = 0.0
	weather = CLEAR
	weather_forced = false
	_previous_weather = ""
	_older_weather = ""
	insurance_left = 0
	practice_left = 0
	practicing = false
	_insurance_spent = false
	attempt_cap = stats.attempt_cap
	_reset_vitamins()
	_refill_quarter()
	_place_spot()
	_roll_wind()
	_roll_weather()


func distance_yards() -> float:
	if run_mode == "endless":
		return RunTable.endless_distance(kick_number)
	return float(RunTable.row(kick_number)["distance"])


func is_boss() -> bool:
	if run_mode == "endless":
		return kick_number >= 10 and kick_number % 10 == 0
	return str(RunTable.row(kick_number)["conditions"]) == RunTable.BOSS


# The multiplier for the kick you are on, from the streak before this kick.
func current_mult() -> float:
	return (1.0 + stats.streak_step * float(streak)) * showtime_mult


func storm_bonus() -> float:
	return stats.storm_per_mph * absf(KickLogic.crosswind_mph(float(wind_speed), wind_direction))


func hero_bonus() -> float:
	return stats.hero_mult


func curse_bonus() -> float:
	return stats.curse_mult


func drill_bonus() -> float:
	if not is_boss():
		return 0.0
	return stats.drill_mult


func wants_upgrade() -> bool:
	# Cards only after a make, and not on the win.
	return phase == Phase.PLAYING and kick_resolved and last_result_made


func can_advance() -> bool:
	# Only a make moves the kick number. A miss retries this same kick.
	if phase != Phase.PLAYING or not kick_resolved or not last_result_made:
		return false
	if run_mode == "endless":
		return distance_yards() < 1000.0
	return kick_number < RunTable.count()


# R is allowed when the run is over. A miss on kick 20 with attempts left is also over:
# there is no kick 21, and it is not a win.
func accepts_restart() -> bool:
	return phase == Phase.GAME_OVER or phase == Phase.WIN or phase == Phase.FAR


func resolve_kick(result_text: String, offset: float, perfect: bool) -> void:
	if kick_resolved or phase != Phase.PLAYING:
		return
	kick_resolved = true
	var attempts_before := attempts
	var made := result_text == "GOOD"
	last_result_made = made
	var distance := distance_yards()
	var boss := is_boss()
	down_the_middle = absf(offset) <= KickConstants.MIDDLE_YARDS
	attempt_note = ""
	score_line = ""
	last_points = 0
	var score_perfect := perfect and _vitamin_count(Vitamins.OMEGA) == 0
	var pre := 0.0
	var gel := 0.0
	if made:
		pre = 0.5 * float(_vitamin_count(Vitamins.PREWORKOUT))
		pre = Loadout.scale_amount(pre, item_effect_scale())
		if stats.gelcap and _belt_vitamin_active():
			gel = 0.5
		var base_mult := current_mult()
		if stats.showtime and down_the_middle:
			base_mult *= 2.0
		var storm := storm_bonus()
		var hero := hero_bonus()
		var curse_add := curse_bonus()
		var drill := drill_bonus()
		var mult := base_mult + storm + hero + curse_add + drill + pre + gel
		last_points = points_for(distance, mult, down_the_middle, boss, score_perfect)
		score += last_points
		score_line = format_score_line(distance, base_mult, down_the_middle, boss, score_perfect, storm, hero, curse_add, drill, pre + gel)
		kicks_made += 1
		if distance > longest_make:
			longest_make = distance
		if is_first_ball:
			clean_makes[kick_number] = true
			if stats.lucky_ball:
				lucky_stacks += 1
		if earns_attempt(kick_number, is_first_ball, perfect, down_the_middle, late_earn_rule):
			if attempts >= attempt_cap:
				attempt_note = NOTE_CAP
			else:
				attempts = mini(attempt_cap, attempts + 1)
				attempt_note = NOTE_EARNED
		streak += 1
		if streak > best_streak:
			best_streak = streak
		if stats.showtime and down_the_middle:
			showtime_mult *= 2.0
		if down_the_middle:
			middles_this_run += 1
		if run_mode == "endless" and distance >= 1000.0:
			phase = Phase.FAR
		elif run_mode != "endless" and kick_number >= RunTable.count():
			phase = Phase.WIN
		_note_trophies(true, distance)
	else:
		streak = 0
		showtime_mult = 1.0
		is_first_ball = false
		if _vitamin_count(Vitamins.ELECTROLYTE) == 0:
			attempts -= 1
			if attempts <= 0:
				attempts = 0
				phase = Phase.GAME_OVER
	var payout := cash_payout(made, perfect, down_the_middle, boss)
	cash += payout
	cash_popup = "+$%d" % payout if payout > 0 else ""
	_clear_ball_vitamins()
	balls_kicked += 1
	if made and attempts_before == 1 and kick_number >= 5:
		_try_unlock(Kickers.WILLOW)
	if made and distance >= 100.0:
		_try_unlock(Kickers.CARLOS)
	if phase == Phase.WIN and run_mode != "endless":
		_try_unlock(Kickers.COLE)
	if phase == Phase.WIN and run_mode != "endless" and _standard_was_clean():
		_try_unlock(Kickers.GARY)
	if phase == Phase.GAME_OVER and run_mode == "endless" and distance > 75.0:
		_try_unlock(Kickers.VEX)
	if phase != Phase.PLAYING:
		_save_finished_run()


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
	awaiting_shop = false
	offer = []
	zinc_used = false
	_clear_ball_vitamins()
	mulligan_used_this_kick = false
	_insurance_spent = false
	_older_weather = _previous_weather
	_previous_weather = weather
	weather_forced = false
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
	if weather == SQUEEZE or has_curse(Loadout.NARROW):
		return SQUEEZE_HALF
	return KickConstants.POST_HALF_GAP_YARDS


func post_width() -> float:
	if weather == SQUEEZE or has_curse(Loadout.NARROW):
		return SQUEEZE_WIDTH
	return KickConstants.POST_SEPARATION_YARDS


func needle_fades() -> bool:
	# Kick 5 fades only the needle. Ice Cage blocks that. The Iced curse hides the bar instead.
	if stats.ice_veins or has_ice_cage():
		return false
	return weather == ICED


func meter_hidden(on_meter: bool, seconds_after_start: float) -> bool:
	if not stats.hide_meter or has_ice_cage():
		return false
	if not on_meter:
		return false
	return seconds_after_start >= 0.4


func has_curse(id: String) -> bool:
	return curse_ids.has(id)


func has_ice_cage() -> bool:
	return helmet_id == Loadout.ICE_CAGE


func shown_wind_speed() -> int:
	var speed := float(wind_speed)
	if has_curse(Loadout.HOWLING):
		speed *= 1.5
	return int(round(speed))


func force_weather(name: String) -> void:
	weather = name
	weather_forced = true


func prepare_kick_stats() -> void:
	rebuild_stats()
	if stats.wraps_yards > 0.0 and weather != CLEAR:
		var bonus := stats.wraps_yards
		if has_curse(Loadout.HOWLING):
			bonus *= 1.15
		stats.range_bonus += bonus
	if weather != BIG_GAME:
		_apply_ball_vitamins()
		return
	var base := KickerStats.new()
	if kicker_id != "":
		Kickers.apply_to(base, kicker_id)
	# Stone Toe still hurries the power needle. That is a curse downside, not meter help.
	stats.power_speed = base.power_speed * (1.2 if has_curse(Loadout.STONE) else 1.0)
	stats.accuracy_speed = base.accuracy_speed
	stats.accuracy = base.accuracy
	stats.perfect_band = base.perfect_band
	stats.good_band = base.good_band
	if has_curse(Loadout.TIGHT):
		stats.perfect_band = maxf(stats.perfect_band - 2.0, 1.0)
		stats.good_band = maxf(stats.good_band - 2.0, 1.0)
	if stats.perfect_band > stats.good_band:
		stats.perfect_band = stats.good_band
	stats.red_tip_start = base.red_tip_start
	stats.red_tip_noise = base.red_tip_noise
	stats.red_tip_off = false
	stats.ice_veins = false
	_apply_ball_vitamins()


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


# Rank I halves rain, snow, and mud. Rank II ignores those three.
# Monsoon's rain and mud extras stay until rank III.
static func weather_kick_flags(weather_name: String, cut: int) -> Dictionary:
	var monsoon := weather_name == MONSOON
	var half := cut == 1
	var ignore_plain := cut >= 2
	var ignore_monsoon := cut >= 3
	var rain := false
	if weather_name == RAIN and not ignore_plain:
		rain = true
	elif monsoon and not ignore_monsoon:
		rain = true
	var mud := false
	if weather_name == MUD and not ignore_plain:
		mud = true
	elif monsoon and not ignore_monsoon:
		mud = true
	return {
		"rain_faster": rain,
		"rain_scale": 1.10 if half else 1.20,
		"snow_range": weather_name == SNOW and not ignore_plain,
		"snow_penalty": 2.0 if half else 4.0,
		"mud_power": mud,
		"mud_span": 1.5 if half else 3.0,
	}


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


static func roll_weather_name(kick: int, previous: String, older: String, rng: RandomNumberGenerator, ignore_fixed_boss: bool = false) -> String:
	if not ignore_fixed_boss:
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


# How far the accuracy needle has traveled down the right arc, 0 to 1.
# 0 is just after MAX (e=+15). 1 is the ACCURACY label (e=-15).
# The iced needle fades out over the first 18% of that trip and is fully back by halfway.
# A needle value above +15 is still the locked power, on the leftover left-side travel.
const ICED_FADE_OUT := 0.18
const ICED_VISIBLE_AT := 0.5


static func iced_needle_alpha(fades: bool, on_accuracy: bool, _power: float, needle: float) -> float:
	if not fades or not on_accuracy:
		return 1.0
	if needle > MeterGauge.ERROR_AT_MAX:
		return 1.0
	var along := clampf((MeterGauge.ERROR_AT_MAX - needle) / (MeterGauge.ERROR_AT_MAX * 2.0), 0.0, 1.0)
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
	return practice_left > 0 and not practicing and stats.practice_per_quarter > 0


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


func roll_offer() -> void:
	if phase != Phase.PLAYING:
		awaiting_offer = false
		offer = []
		return
	if _forced_cards.size() > 0:
		offer = []
		for item in _forced_cards:
			offer.append(_as_loadout_card(item))
		_forced_cards = []
	else:
		offer = Loadout.draw_offer(loadout_state(), attempt_cap, _offer_rng)
	awaiting_offer = true


func pick_card(index: int) -> bool:
	if not awaiting_offer or index < 0 or index >= offer.size():
		return false
	var card := _as_loadout_card(offer[index])
	_close_offer()
	give(str(card.get("id", "")), int(card.get("rank", 1)))
	return true


func skip_offer() -> bool:
	if not awaiting_offer:
		return false
	_close_offer()
	return true


func reroll_offer() -> bool:
	if not awaiting_offer or awaiting_shop or rerolls_left <= 0:
		return false
	rerolls_left -= 1
	var previous: Array = offer.duplicate(true)
	offer = Loadout.draw_offer(loadout_state(), attempt_cap, _offer_rng, previous)
	awaiting_offer = true
	return true


func opens_shop() -> bool:
	if phase != Phase.PLAYING or not last_result_made:
		return false
	return kick_number == 5 or kick_number == 10 or kick_number == 15


func follow_offer() -> String:
	if opens_shop() and not stats.brand_deal:
		open_shop()
		return "shop"
	return "next"


func next_boss_line() -> String:
	if run_mode == "endless":
		var target := 0
		if kick_number == 5:
			target = 10
		elif kick_number == 10 or kick_number == 15:
			target = 20
		if target == 0:
			return ""
		return "Next boss: %s" % _boss_label(_endless_boss(target))
	if kick_number == 5:
		return "Next boss: The Squeeze"
	if kick_number == 10:
		return "Next boss: Monsoon"
	if kick_number == 15:
		return "Next boss: Big Game"
	return ""


func _boss_label(name: String) -> String:
	if name == ICED:
		return "Iced"
	if name == SQUEEZE:
		return "The Squeeze"
	if name == MONSOON:
		return "Monsoon"
	if name == BIG_GAME:
		return "Big Game"
	return name


func _endless_boss(kick: int) -> String:
	if endless_bosses.has(kick):
		return str(endless_bosses[kick])
	var names: Array[String] = [ICED, SQUEEZE, MONSOON, BIG_GAME]
	var pick := names[_weather_rng.randi() % names.size()]
	endless_bosses[kick] = pick
	return pick


func open_shop() -> void:
	awaiting_shop = true
	awaiting_offer = false
	cash_popup = ""
	shop_b12_bought = false
	shop_reroll_price = Vitamins.REROLL_START
	shop_flash = ""
	shop_note = ""
	_fill_shelves(true)


func leave_shop() -> void:
	awaiting_shop = false
	shop_flash = ""
	shop_note = ""


func buy_shelf(index: int) -> bool:
	if not awaiting_shop or index < 0 or index >= shop_stock.size():
		return false
	var id := str(shop_stock[index])
	if id == "":
		return false
	if cash < item_price(id):
		shop_flash = str(index)
		shop_note = ""
		return false
	if _empty_belt() < 0:
		shop_note = "Belt full: sell first"
		shop_flash = ""
		return false
	cash -= item_price(id)
	_try_unlock(Kickers.PHIL)
	shop_stock[index] = ""
	belt[_empty_belt()] = id
	shop_flash = ""
	shop_note = ""
	return true


func buy_b12() -> bool:
	if not awaiting_shop or shop_b12_bought:
		return false
	if attempts >= attempt_cap:
		shop_flash = ""
		return false
	if cash < item_price(Vitamins.B12):
		shop_flash = "b12"
		return false
	cash -= item_price(Vitamins.B12)
	_try_unlock(Kickers.PHIL)
	attempts = mini(attempt_cap, attempts + 1)
	shop_b12_bought = true
	shop_flash = ""
	shop_note = ""
	return true


func b12_grey() -> bool:
	return shop_b12_bought or attempts >= attempt_cap or cash < item_price(Vitamins.B12)


func sell_belt(index: int) -> bool:
	if not awaiting_shop or index < 0 or index >= belt.size():
		return false
	var id := str(belt[index])
	if id == "":
		return false
	cash += item_sale_price(id)
	belt[index] = ""
	shop_note = ""
	shop_flash = ""
	return true


func reroll_shop() -> bool:
	if not awaiting_shop:
		return false
	if cash < shop_reroll_price:
		shop_flash = "reroll"
		return false
	cash -= shop_reroll_price
	shop_reroll_price += 1
	shop_flash = ""
	var previous: Array = shop_stock.duplicate()
	_fill_shelves(false, previous)
	return true


func add_debug_cash() -> void:
	cash += 10
	cash_popup = "+$10"


func use_belt(index: int) -> bool:
	if awaiting_shop or curse_prompt or awaiting_offer or phase != Phase.PLAYING:
		return false
	if index < 0 or index >= belt.size():
		return false
	var id := str(belt[index])
	if id == "":
		return false
	if id == Vitamins.ZINC:
		if zinc_used:
			vitamin_note = "Already rerolled"
			return false
		_reroll_zinc()
		belt[index] = ""
		vitamin_note = Vitamins.piece_name(id)
		return true
	if id == Vitamins.TART:
		return _start_tart(index)
	belt[index] = ""
	active_vitamins[id] = _vitamin_count(id) + 1
	vitamin_note = Vitamins.piece_name(id)
	return true


func pick_curse_removal(index: int) -> bool:
	if not curse_prompt or index < 0 or index >= curse_ids.size():
		return false
	_remove_curse_at(index)
	if curse_prompt_slot >= 0 and curse_prompt_slot < belt.size():
		belt[curse_prompt_slot] = ""
	curse_prompt = false
	curse_prompt_slot = -1
	vitamin_note = "Curse removed"
	return true


func cancel_curse_prompt() -> void:
	curse_prompt = false
	curse_prompt_slot = -1
	vitamin_note = ""


func vitamin_d_active() -> bool:
	return _vitamin_count(Vitamins.VITAMIN_D) > 0


func weather_flags_now() -> Dictionary:
	var flags := weather_kick_flags(weather, stats.weather_cut)
	if vitamin_d_active():
		flags["rain_faster"] = false
		flags["snow_range"] = false
		flags["mud_power"] = false
	return flags


static func cash_payout(made: bool, perfect: bool, middle: bool, boss: bool) -> int:
	if not made:
		return 0
	var gain := 3
	if perfect:
		gain += 1
	if middle:
		gain += 1
	if boss:
		gain += 2
	return gain


func _as_loadout_card(item) -> Dictionary:
	if item is Dictionary and str(item.get("id", "")) != "":
		var card: Dictionary = item.duplicate()
		var id := str(card.get("id", ""))
		if str(card.get("slot", "")) == "":
			card["slot"] = Loadout.slot_of(id)
		if str(card.get("kind", "")) == "":
			card["kind"] = Loadout.kind_of(id)
		if int(card.get("rank", 0)) <= 0:
			card["rank"] = 1
		return card
	var id := str(item)
	return {"kind": Loadout.kind_of(id), "slot": Loadout.slot_of(id), "id": id, "rank": 1}


func give(id: String, rank: int = 1) -> void:
	var slot := Loadout.slot_of(id)
	if slot == "":
		return
	if slot == Loadout.CLEATS:
		if cleats_id != "" and cleats_id != id:
			return
		if rank > Loadout.max_rank(id, run_mode) or rank <= cleats_rank:
			return
	elif slot == Loadout.HELMET:
		if helmet_id != "" and helmet_id != id:
			return
		if rank > Loadout.max_rank(id, run_mode) or rank <= helmet_rank:
			return
	elif slot == Loadout.GLOVES:
		if gloves_id != "" and gloves_id != id:
			return
		if rank > Loadout.max_rank(id, run_mode) or rank <= gloves_rank:
			return
	elif slot == Loadout.PERK:
		var have := _perk_rank(id)
		if have == 0 and perks.size() >= 2:
			return
		if id == Loadout.GLASS_LEG and have == 0 and attempt_cap <= 2:
			return
		if rank > Loadout.max_rank(id, run_mode) or rank <= have:
			return
	elif slot == Loadout.CURSE:
		if curse_ids.has(id) or curse_ids.size() >= 2:
			return
		if id == Loadout.ICED and has_ice_cage():
			return
	var cap_before := attempt_cap
	var reroll_before := stats.rerolls_per_run
	var doink_before := stats.doink_per_quarter
	var practice_before := stats.practice_per_quarter
	if slot == Loadout.CLEATS:
		cleats_id = id
		cleats_rank = rank
	elif slot == Loadout.HELMET:
		helmet_id = id
		helmet_rank = rank
	elif slot == Loadout.GLOVES:
		gloves_id = id
		gloves_rank = rank
	elif slot == Loadout.PERK:
		var found := false
		for item in perks:
			if str(item.get("id", "")) == id:
				item["rank"] = rank
				found = true
		if not found:
			perks.append({"id": id, "rank": rank})
	elif slot == Loadout.CURSE:
		curse_ids.append(id)
		if curse_ids.size() >= 2:
			curses_locked = true
	rebuild_stats()
	var cap_gain := attempt_cap - cap_before
	if cap_gain > 0:
		attempts = mini(attempts + cap_gain, attempt_cap)
	elif attempts > attempt_cap:
		attempts = attempt_cap
	var reroll_gain := stats.rerolls_per_run - reroll_before
	if reroll_gain > 0:
		rerolls_left += reroll_gain
	var doink_gain := stats.doink_per_quarter - doink_before
	if doink_gain > 0:
		insurance_left += doink_gain
	var practice_gain := stats.practice_per_quarter - practice_before
	if practice_gain > 0:
		practice_left += practice_gain
	if id == Loadout.DEEP_BENCH and rank >= 3 and attempts < attempt_cap:
		attempts += 1


func loadout_state() -> Dictionary:
	return {
		"cleats_id": cleats_id,
		"cleats_rank": cleats_rank,
		"helmet_id": helmet_id,
		"helmet_rank": helmet_rank,
		"gloves_id": gloves_id,
		"gloves_rank": gloves_rank,
		"perks": perks.duplicate(true),
		"curses": curse_ids.duplicate(),
		"curses_locked": curses_locked,
		"banned_curses": banned_curses.duplicate(),
		"run_mode": run_mode,
	}


func _perk_rank(id: String) -> int:
	for item in perks:
		if str(item.get("id", "")) == id:
			return int(item.get("rank", 0))
	return 0


func rebuild_stats() -> void:
	stats.reset()
	if kicker_id != "":
		Kickers.apply_to(stats, kicker_id)
	Loadout.apply(stats, loadout_state(), has_curse(Loadout.HOWLING), item_effect_scale())
	attempt_cap = mini(stats.attempt_cap, KickConstants.ATTEMPT_CAP_MAX)


func owned_labels() -> Array:
	var labels: Array = []
	if cleats_id != "":
		labels.append(Loadout.card_title(cleats_id, cleats_rank))
	if helmet_id != "":
		labels.append(Loadout.card_title(helmet_id, helmet_rank))
	if gloves_id != "":
		labels.append(Loadout.card_title(gloves_id, gloves_rank))
	for item in perks:
		labels.append(Loadout.card_title(str(item.get("id", "")), int(item.get("rank", 1))))
	for id in curse_ids:
		labels.append(Loadout.piece_name(str(id)))
	return labels


func upcoming_winds() -> Array:
	if not stats.wind_preview or stats.wind_preview_count <= 0:
		return []
	var saved := _wind_rng.state
	var lines: Array = []
	var kn := kick_number
	for _step in stats.wind_preview_count:
		kn += 1
		if run_mode != "endless" and kn > RunTable.count():
			break
		var info: Dictionary = RunTable.row(RunTable.table_kick(run_mode, kn))
		var lo := int(info["wind_min"])
		var hi := int(info["wind_max"])
		var speed := _wind_rng.randi_range(lo, hi)
		if speed <= 0:
			lines.append("Kick %d: Calm" % kn)
			continue
		var direction := float(_wind_rng.randi_range(0, 359))
		lines.append("Kick %d: %s" % [kn, wind_readout(speed, direction)])
	_wind_rng.state = saved
	return lines


func _close_offer() -> void:
	awaiting_offer = false
	offer = []


func _refill_quarter() -> void:
	if kick_number == 1 or kick_number == 6 or kick_number == 11 or kick_number == 16:
		mulligans_left = 0
		if stats.doink_carry:
			insurance_left = stats.doink_per_quarter + mini(maxi(insurance_left, 0), stats.doink_per_quarter)
		else:
			insurance_left = stats.doink_per_quarter
		if stats.practice_carry:
			practice_left = stats.practice_per_quarter + mini(maxi(practice_left, 0), stats.practice_per_quarter)
		else:
			practice_left = stats.practice_per_quarter
		if stats.bench_spare and attempts < attempt_cap:
			attempts += 1
		_insurance_spent = false


func _records():
	var loop := Engine.get_main_loop()
	if loop == null:
		return null
	return loop.root.get_node_or_null("SaveData")


func _note_trophies(made: bool, distance: float) -> void:
	if not made:
		return
	var data = _records()
	if data == null:
		return
	var earned := ""
	if data.try_trophy("extra_point"):
		earned = "Extra Point"
	if distance >= 50.0 and data.try_trophy("fifty_club"):
		earned = "Fifty Club"
	if distance >= 60.0 and data.try_trophy("sixty_club"):
		earned = "Sixty Club"
	if distance >= 69.0 and data.try_trophy("record_breaker"):
		earned = "Record Breaker"
	if streak >= 10 and data.try_trophy("hot_hand"):
		earned = "Hot Hand"
	if phase == Phase.WIN and run_mode != "endless" and data.try_trophy("season_complete"):
		earned = "Season Complete"
	if int(data.middles) + middles_this_run >= 10 and data.try_trophy("bullseye_collector"):
		earned = "Bullseye Collector"
	if _quarter_was_clean():
		if data.try_trophy("perfect_quarter"):
			earned = "Perfect Quarter"
	if earned != "":
		trophy_name = earned


func _quarter_was_clean() -> bool:
	if kick_number != 5 and kick_number != 10 and kick_number != 15 and kick_number != 20:
		return false
	var start := kick_number - 4
	for n in range(start, kick_number + 1):
		if not bool(clean_makes.get(n, false)):
			return false
	return true


func _save_finished_run() -> void:
	if _run_saved:
		return
	_run_saved = true
	var data = _records()
	if data == null:
		return
	var flags: Dictionary = data.commit_run({
		"score": score,
		"longest": int(round(longest_make)),
		"makes": kicks_made,
		"attempts": balls_kicked,
		"middles": middles_this_run,
		"won": phase == Phase.WIN,
		"kicker_id": kicker_id,
	})
	new_record_score = bool(flags.get("score", false))
	new_record_long = bool(flags.get("longest", false))


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


static func format_score_line(distance: float, mult: float, middle: bool, boss: bool, perfect: bool, storm: float = 0.0, hero: float = 0.0, curse_add: float = 0.0, drill: float = 0.0, pre: float = 0.0) -> String:
	var product := distance * (mult + storm + hero + curse_add + drill + pre)
	var text := "%s yd × %s" % [_whole(distance), _two_decimals(mult)]
	if storm > 0.001 or hero > 0.001 or curse_add > 0.001 or drill > 0.001 or pre > 0.001:
		text = "%s yd × (%s" % [_whole(distance), _two_decimals(mult)]
		if storm > 0.001:
			text += " + %s wind" % _two_decimals(storm)
		if hero > 0.001:
			text += " + %s hero" % _two_decimals(hero)
		if curse_add > 0.001:
			text += " + %s curse" % _two_decimals(curse_add)
		if drill > 0.001:
			text += " + %s drill" % _two_decimals(drill)
		if pre > 0.001:
			text += " + %s pre" % _two_decimals(pre)
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


func _reset_vitamins() -> void:
	cash = 0
	cash_popup = ""
	belt = ["", ""]
	active_vitamins = {}
	zinc_used = false
	vitamin_note = ""
	awaiting_shop = false
	shop_stock = ["", "", ""]
	shop_b12_bought = false
	shop_reroll_price = Vitamins.REROLL_START
	shop_flash = ""
	shop_note = ""
	curse_prompt = false
	curse_prompt_slot = -1
	curses_locked = false
	banned_curses = []


func _clear_ball_vitamins() -> void:
	active_vitamins = {}


func _vitamin_count(id: String) -> int:
	return int(active_vitamins.get(id, 0))


func _empty_belt() -> int:
	if str(belt[0]) == "":
		return 0
	if str(belt[1]) == "":
		return 1
	return -1


func _fill_shelves(opening: bool = false, avoid: Array = []) -> void:
	var picks: Array = Vitamins.draw_three(_shop_rng, [] if opening else avoid)
	if opening and stats.synchronicity and not shop_guaranteed:
		shop_guaranteed = true
		if not picks.has(Vitamins.PROTEIN):
			picks[0] = Vitamins.PROTEIN
	shop_stock = ["", "", ""]
	for i in mini(3, picks.size()):
		shop_stock[i] = str(picks[i])


func item_effect_scale() -> float:
	var scale := 1.0
	if stats.compounding:
		scale *= 1.15
	if stats.lucky_ball:
		scale *= 1.0 + 0.03 * float(lucky_stacks)
	return scale


func item_price(id: String) -> int:
	if stats.house_account:
		return 0
	return Vitamins.price(id)


func item_sale_price(id: String) -> int:
	return int(floor(float(item_price(id)) / 2.0))


func _belt_vitamin_active() -> bool:
	for id in active_vitamins.keys():
		if int(active_vitamins[id]) > 0:
			return true
	return false


func _standard_was_clean() -> bool:
	for n in range(1, RunTable.count() + 1):
		if not bool(clean_makes.get(n, false)):
			return false
	return true


func _try_unlock(id: String) -> void:
	var data = _records()
	if data == null:
		return
	if data.try_unlock(id):
		unlock_toast = "%s unlocked" % str(Kickers.get_def(id).get("name", id))


func _apply_ball_vitamins() -> void:
	var scale := item_effect_scale()
	stats.range_bonus += Loadout.scale_amount(6.0 * float(_vitamin_count(Vitamins.PROTEIN)), scale)
	var mag := _vitamin_count(Vitamins.MAGNESIUM)
	if mag > 0:
		var factor := pow(0.7, float(mag))
		stats.power_speed *= Loadout.scale_gap(factor, scale)
		stats.accuracy_speed *= Loadout.scale_gap(factor, scale)
	stats.omega = _vitamin_count(Vitamins.OMEGA) > 0
	var pickle := _vitamin_count(Vitamins.PICKLE)
	if pickle > 0:
		stats.drift_factor *= Loadout.scale_gap(pow(0.5, float(pickle)), scale)
	if _vitamin_count(Vitamins.LUTEIN) > 0:
		stats.flag_reader = true
		stats.laser_line = true
		stats.laser_full = true


func _reroll_zinc() -> void:
	zinc_used = true
	var info: Dictionary = RunTable.row(kick_number)
	var lo := int(info["wind_min"])
	var hi := int(info["wind_max"])
	wind_speed = _wind_rng.randi_range(lo, hi)
	if wind_speed <= 0:
		wind_speed = 0
		wind_direction = 0.0
	else:
		wind_direction = float(_wind_rng.randi_range(0, 359))
	if boss_weather(kick_number) != "":
		return
	weather_forced = false
	_roll_weather()


func _start_tart(index: int) -> bool:
	if curse_ids.is_empty():
		vitamin_note = "No curse to remove"
		return false
	if curse_ids.size() == 1:
		_remove_curse_at(0)
		belt[index] = ""
		vitamin_note = "Curse removed"
		return true
	curse_prompt = true
	curse_prompt_slot = index
	vitamin_note = "Remove which curse?"
	return true


func _remove_curse_at(index: int) -> void:
	if index < 0 or index >= curse_ids.size():
		return
	var id := str(curse_ids[index])
	if not banned_curses.has(id):
		banned_curses.append(id)
	curse_ids.remove_at(index)
	rebuild_stats()
	_apply_ball_vitamins()


func _place_spot() -> void:
	if run_mode == "endless" and kick_number > 20:
		var side := -1 if kick_number % 2 == 1 else 1
		spot_yards = RunTable.spot_yards(RunTable.SPOT_WIDE, side)
		return
	var spot := str(RunTable.row(RunTable.table_kick(run_mode, kick_number))["spot"])
	if spot == RunTable.SPOT_CENTER:
		spot_yards = 0.0
		return
	# A center kick does not use up a forced side. The next hash or wide kick does.
	var side_pick := _next_side
	_next_side = 0
	if side_pick == 0:
		side_pick = -1 if _rng.randi_range(0, 1) == 0 else 1
	spot_yards = RunTable.spot_yards(spot, side_pick)


func _roll_weather() -> void:
	if weather_forced:
		return
	if run_mode == "endless" and is_boss():
		weather = _endless_boss(kick_number)
		return
	var template := RunTable.table_kick(run_mode, kick_number)
	weather = roll_weather_name(template, _previous_weather, _older_weather, _weather_rng, run_mode == "endless")


func _roll_wind() -> void:
	var info := RunTable.row(RunTable.table_kick(run_mode, kick_number))
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
