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
const LIGHTS := "UNDER THE LIGHTS"
const CLOCK := "KICK CLOCK"
const MOVING := "MOVING POSTS"
const CLOCK_SEC := 4.0
const POST_SWING := 3.0
const POST_PERIOD := 4.0
const TAD_MAX := 10
const TOO_WEAK_BEAT := 0.5
const TOO_WEAK_HOLD := 1.8
const TOO_WEAK_CUSHION := 0.05
const TOO_WEAK_LINES: PackedStringArray = [
	"NEED MORE LEG.",
	"OUT OF RANGE.",
	"SEND IN THE PUNTER.",
	"CALL THE PUNT TEAM.",
	"HIT THE WEIGHT ROOM.",
	"NOT ENOUGH BOOT.",
	"THE POSTS ARE TOO FAR.",
	"BACK TO THE PRACTICE FIELD.",
]
const LIGHTS_NEEDLE := 1.35
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
var bench_bank := 0.0
var bench_extra_cap := 0
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
var cleats2_id := ""
var cleats2_rank := 0
var helmet_id := ""
var helmet_rank := 0
var helmet2_id := ""
var helmet2_rank := 0
var gloves_id := ""
var gloves_rank := 0
var gloves2_id := ""
var gloves2_rank := 0
var perks: Array = []
var curse_ids: Array = []
var balls_kicked := 0
var middles_this_run := 0
var best_streak := 0
var clean_makes := {}
# Kick numbers whose Bonus Ring is already collected or made past.
var ring_spent := {}
# -1 left, +1 right. Chosen once per kick and kept for retries.
var ring_sides := {}
var ring_debug := {}
var ring_offer_pending := false
var ring_offer_skipped := false
var trophy_name := ""
var new_record_score := false
var new_record_long := false
var _run_saved := false
var awaiting_offer := false
var awaiting_mulligan := false
var mulligans_left := 0
var mulligan_used_this_kick := false
var rerolls_left := 1
# Second Look. 0 or 1. Set to 1 at the start of each 5-kick block. Does not stack.
var second_look_bank := 0
# Standard difficulty for this run. 0 is today's game. Endless stays 0.
var tad_level := 0
var end_reason := ""
var tad_toast := ""
var power_item_seen := false
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
# Standard kicks 5, 10, 15, and 20. Rolled once at new_run, no repeats.
var standard_bosses := {}
var kick10_boss := ""
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
var synchronicity_offer_done := false
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
var _kick10_rng := RandomNumberGenerator.new()
var _offer_rng := RandomNumberGenerator.new()
var _shop_rng := RandomNumberGenerator.new()
var _previous_weather := ""
var _older_weather := ""
var _insurance_spent := false


func _init() -> void:
	_rng.randomize()
	_wind_rng.randomize()
	_weather_rng.randomize()
	_kick10_rng.randomize()
	_offer_rng.randomize()
	_shop_rng.randomize()
	new_run()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	# Wind and weather have their own generators so a spot seed still lands on the same hash.
	_wind_rng.seed = seed_value + 7919
	_weather_rng.seed = seed_value + 1543
	_kick10_rng.seed = seed_value + 9001
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
	standard_bosses = {}
	kick_number = 1
	attempts = KickConstants.ATTEMPTS_START
	attempt_cap = mini(KickConstants.ATTEMPT_CAP, KickConstants.ATTEMPT_CAP_MAX)
	bench_bank = 0.0
	bench_extra_cap = 0
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
	cleats2_id = ""
	cleats2_rank = 0
	helmet_id = ""
	helmet_rank = 0
	helmet2_id = ""
	helmet2_rank = 0
	gloves_id = ""
	gloves_rank = 0
	gloves2_id = ""
	gloves2_rank = 0
	perks = []
	curse_ids = []
	balls_kicked = 0
	middles_this_run = 0
	best_streak = 0
	clean_makes = {}
	ring_spent = {}
	ring_sides = {}
	ring_debug = {}
	ring_offer_pending = false
	ring_offer_skipped = false
	lucky_stacks = 0
	showtime_mult = 1.0
	synchronicity_offer_done = false
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
	second_look_bank = 0
	tad_level = 0
	end_reason = ""
	tad_toast = ""
	power_item_seen = false
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
	_roll_standard_bosses()
	_roll_weather()


func distance_yards() -> float:
	if run_mode == "endless":
		return RunTable.endless_distance(kick_number)
	var yards := float(RunTable.row(kick_number)["distance"])
	if tad_active(3):
		yards += 4.0
	return yards


func tad_active(level: int) -> bool:
	return run_mode != "endless" and tad_level >= level


func open_tad(level: int) -> void:
	tad_level = 0 if run_mode == "endless" else clampi(level, 0, TAD_MAX)
	if tad_active(5):
		rerolls_left = 0
	_add_tad_wind()
	# Kick 1's weather was rolled before the ladder was applied. Foul weather has to roll again.
	if tad_active(9):
		weather_forced = false
		_roll_weather()


func too_weak_flavor() -> String:
	if TOO_WEAK_LINES.is_empty():
		return ""
	return TOO_WEAK_LINES[_rng.randi() % TOO_WEAK_LINES.size()]


static func too_weak_numbers(best_case: float, required: float) -> String:
	return "MAX %s YD. NEED %s YD." % [KickLogic.format_number(best_case), KickLogic.format_number(required)]


# One report for the tee check, the debug key, and the tests.
# base is the HUD Max. The other parts are yards still available before this ball is kicked.
# blocked is pause, the J preview, or a menu over the tee.
func too_weak_report(kick: KickLogic, blocked: bool = false) -> Dictionary:
	var base := 0.0
	var required := 0.0
	if kick != null:
		base = kick.max_range_at_full_power()
		required = kick.kick_distance
	var practice := practicing or (kick != null and kick.practice_swing)
	var numero := kick != null and kick.stats.numero_dos
	var tip := 0.0
	if kick != null:
		tip = maxf(kick.stats.tip_lock_yards, 0.0)
	var overpower := 0.0
	if not practice and not numero:
		overpower = KickConstants.OVERPOWER_YARDS + tip
	# Gear is whatever is already in stats: filled slots, including a second slot.
	# A benched piece, a banked pass, and a curse that pays only after a make are not added.
	var open_belt := belt_usable()
	var shake_count := _belt_count(Vitamins.PROTEIN) if open_belt else 0
	var shakes := belt_protein_yards()
	var vitamin_d := 0.0
	if open_belt and kick != null and kick.snow_range and _belt_count(Vitamins.VITAMIN_D) > 0 and not vitamin_d_active():
		vitamin_d = kick.snow_penalty
	var belt_electrolyte := open_belt and _belt_count(Vitamins.ELECTROLYTE) > 0
	var retry_possible := attempts >= 2 or _vitamin_count(Vitamins.ELECTROLYTE) > 0 or belt_electrolyte
	var walk_on := 0.0
	if kicker_id == Kickers.WALK_ON and is_first_ball and not practice and retry_possible:
		walk_on = 6.0
	var best := base + overpower + shakes + vitamin_d + walk_on
	var clearance := kick != null and kick.stats.clearance
	var zinc_block := open_belt and _belt_count(Vitamins.ZINC) > 0 and not zinc_used
	var at_tee := (
		phase == Phase.PLAYING
		and kick != null
		and kick.phase == KickLogic.Phase.AIMING
		and not practice
		and not blocked
		and not awaiting_offer
		and not awaiting_shop
		and not awaiting_mulligan
		and not curse_prompt
		and not ring_offer_pending
	)
	var short := best + TOO_WEAK_CUSHION < required
	var weak := short and not clearance and not zinc_block and at_tee
	return {
		"base": base,
		"overpower": overpower,
		"shakes": shakes,
		"shake_count": shake_count,
		"vitamin_d": vitamin_d,
		"walk_on": walk_on,
		"best_case": best,
		"required": required,
		"zinc_block": zinc_block,
		"clearance": clearance,
		"too_weak": weak,
	}


func end_too_weak() -> void:
	if phase != Phase.PLAYING or end_reason == "too_weak":
		return
	end_reason = "too_weak"
	phase = Phase.GAME_OVER
	_save_finished_run()


# ALL NATURAL is not in this build. When that curse is owned, the belt cannot be used.
const BELT_LOCK_CURSE := "all_natural"


func belt_usable() -> bool:
	return not has_curse(BELT_LOCK_CURSE)


func _protein_range_bonus(count: int) -> float:
	if count <= 0:
		return 0.0
	return Loadout.scale_amount(6.0 * float(count), item_effect_scale())


func belt_protein_yards() -> float:
	if not belt_usable():
		return 0.0
	var extra := _belt_count(Vitamins.PROTEIN)
	if extra <= 0:
		return 0.0
	var already := _vitamin_count(Vitamins.PROTEIN)
	return _protein_range_bonus(already + extra) - _protein_range_bonus(already)


func _belt_count(id: String) -> int:
	var count := 0
	for slot in belt:
		if str(slot) == id:
			count += 1
	return count


func posts_move() -> bool:
	# TAD 10 reuses the MOVING POSTS sine. A kick that already rolled that boss uses it once.
	return tad_active(10) or weather == MOVING


func _curse_weight() -> int:
	return 2 if tad_active(6) else 1


func lived_effect_line(id: String, rank: int) -> String:
	var line := Loadout.effect_line(id, rank)
	if tad_active(5) and (id == Loadout.SCOUT_LID or id == Loadout.SECOND_LOOK):
		return line + " Off at TAD 5+."
	return line


static func tad_summary(level: int) -> String:
	match clampi(level, 0, TAD_MAX):
		1:
			return "SHOP PRICES X1.5"
		2:
			return "WIND +3 MPH"
		3:
			return "KICKS +4 YD"
		4:
			return "POSTS 0.25 YD NARROWER"
		5:
			return "NO OFFER REROLLS"
		6:
			return "CURSE OFFERS X2"
		7:
			return "NEEDLES X1.33"
		8:
			return "NO FREE DOWN"
		9:
			return "BAD WEATHER EVERY KICK"
		10:
			return "MOVING CREW"
		_:
			return "STANDARD"


static func tad_name(level: int) -> String:
	match clampi(level, 0, TAD_MAX):
		1:
			return "Short week"
		2:
			return "Swirling winds"
		3:
			return "Long yardage"
		4:
			return "Tight hashes"
		5:
			return "No rerolls"
		6:
			return "Crowded offers"
		7:
			return "Crunch time"
		8:
			return "No free down"
		9:
			return "Foul weather"
		10:
			return "Moving crew"
		_:
			return "Standard"


static func tad_sentence(level: int) -> String:
	match clampi(level, 0, TAD_MAX):
		1:
			return "Shop prices are 1.50 times, rounded up."
		2:
			return "Wind is 3 mph stronger."
		3:
			return "Kicks are 4 yards longer."
		4:
			return "The posts are 0.25 yards narrower."
		5:
			return "Offer rerolls are off. The shop shelf reroll stays."
		6:
			return "Curse offers ×2. Still at most one curse."
		7:
			return "Needles ×1.33 on every kick."
		8:
			return "A first-try make does not grant an attempt."
		9:
			return "Every kick is rain, snow, or mud."
		10:
			return "The posts move on every kick."
		_:
			return "Standard rules."


func _tad_price(amount: int) -> int:
	if not tad_active(1) or amount <= 0:
		return amount
	return int((amount * 3 + 1) / 2)


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
	if practicing or kick_resolved or phase != Phase.PLAYING:
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
		# TAD 8 turns off the first-try attempt. Deep Bench and B12 add attempts on their own.
		if earns_attempt(kick_number, is_first_ball, perfect, down_the_middle, late_earn_rule) and not tad_active(8):
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
		if _ring_armed():
			_spend_ring()
		_note_trophies(true, distance)
	else:
		if result_text == "BONUS RING":
			_spend_ring()
		streak = 0
		showtime_mult = 1.0
		is_first_ball = false
		lucky_stacks = 0
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
	if made and run_mode == "endless" and distance >= 500.0:
		_try_unlock(Kickers.VEX)
	ring_offer_pending = result_text == "BONUS RING" and phase == Phase.PLAYING
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
	ring_offer_pending = false
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
	ring_offer_pending = false
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
	if tad_active(4):
		return post_width() * 0.5
	if weather == SQUEEZE or has_curse(Loadout.NARROW):
		return SQUEEZE_HALF
	return KickConstants.POST_HALF_GAP_YARDS


func post_width() -> float:
	var width := KickConstants.POST_SEPARATION_YARDS
	if weather == SQUEEZE or has_curse(Loadout.NARROW):
		width = SQUEEZE_WIDTH
	if tad_active(4):
		width -= 0.25
	return width


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
	return helmet_id == Loadout.ICE_CAGE or helmet2_id == Loadout.ICE_CAGE


func shown_wind_speed() -> int:
	var speed := float(wind_speed)
	if has_curse(Loadout.HOWLING):
		speed *= 1.5
	return int(round(speed))


func force_weather(name: String) -> void:
	weather = name
	weather_forced = true


func prepare_kick_stats() -> void:
	_rebuild_raw_stats()
	if stats.wraps_yards > 0.0 and weather != CLEAR:
		var bonus := stats.wraps_yards
		if has_curse(Loadout.HOWLING):
			bonus *= Loadout.HOWLING_ITEM
		stats.range_bonus += bonus
	if not practicing and stats.rain_dance:
		var dance := rain_dance_pay(weather, weather == BIG_GAME, vitamin_d_active())
		if bool(dance["yards"]):
			stats.range_bonus += _scaled_perk_yards(4.0)
		# Both needles, before the 0.35 floor. Big Game strips this slow.
		if bool(dance["slow"]):
			stats.power_speed *= 0.90
			stats.accuracy_speed *= 0.90
	if not practicing and stats.chain_gang:
		stats.range_bonus += _scaled_perk_yards(chain_gang_raw())
	if weather == BIG_GAME:
		var base := KickerStats.new()
		if kicker_id != "":
			Kickers.apply_to(base, kicker_id)
		# Meter help is off. Stone Toe is applied after the slow floor, with the vitamins.
		stats.power_speed = base.power_speed
		stats.accuracy_speed = base.power_speed
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
		# Big Game keeps the base band, the +4, and the full 25% band narrowing.
		# Iron Grip's wider band and extra yards, and Ice Cage's halved shrink, are off.
		stats.overpower_width = KickConstants.OVERPOWER_BASE
		stats.tip_lock_yards = 0.0
		stats.overpower_half = false
	_apply_ball_vitamins()
	_finish_needles()


var _fixture_saved := false
var _saved_cleats_id := ""
var _saved_cleats_rank := 0
var _saved_helmet_id := ""
var _saved_helmet_rank := 0
var _saved_gloves_id := ""
var _saved_gloves_rank := 0
var _saved_perks: Array = []
var _saved_curses: Array = []
var _saved_vitamins: Dictionary = {}
var _range_step := 0
var _style_step := 0


func cycle_range_fixture() -> void:
	if run_mode != "endless":
		return
	_capture_fixture()
	_style_step = 0
	_range_step = (_range_step % 3) + 1
	_restore_fixture()
	if _range_step == 1:
		return
	_strip_range_preview()
	cleats_id = Loadout.CANNON
	cleats_rank = 24
	helmet_id = Loadout.DRIVE_LID
	helmet_rank = 24
	if _range_step == 2:
		return
	gloves_id = Loadout.HIGH_AIR
	gloves_rank = 24
	perks = [{"id": Loadout.GLASS_LEG, "rank": 6}]
	curse_ids = [Loadout.SHAKY, Loadout.STONE]
	active_vitamins = {Vitamins.PROTEIN: 1}


func cycle_style_fixture() -> void:
	if run_mode != "endless":
		return
	_capture_fixture()
	_range_step = 0
	_style_step = (_style_step % 6) + 1
	_restore_fixture()
	if _style_step >= 6:
		return
	var id := _style_fixture_id(_style_step)
	_set_slot(id, 1)


func bump_style_fixture() -> void:
	if run_mode != "endless" or _style_step < 1 or _style_step > 5:
		return
	var id := _style_fixture_id(_style_step)
	var rank := _slot_rank(id) + 1
	if rank > 24:
		rank = 1
	_set_slot(id, rank)


func _style_fixture_id(step: int) -> String:
	if step == 1:
		return Loadout.TRUE_LID
	if step == 2:
		return Loadout.SHELTER_LID
	if step == 3:
		return Loadout.GUIDE_GLOVES
	if step == 4:
		return Loadout.PATIENT_GLOVES
	return Loadout.HUSH_GLOVES


func _capture_fixture() -> void:
	if _fixture_saved:
		return
	_fixture_saved = true
	_saved_cleats_id = cleats_id
	_saved_cleats_rank = cleats_rank
	_saved_helmet_id = helmet_id
	_saved_helmet_rank = helmet_rank
	_saved_gloves_id = gloves_id
	_saved_gloves_rank = gloves_rank
	_saved_perks = perks.duplicate(true)
	_saved_curses = curse_ids.duplicate()
	_saved_vitamins = active_vitamins.duplicate()


func _restore_fixture() -> void:
	cleats_id = _saved_cleats_id
	cleats_rank = _saved_cleats_rank
	helmet_id = _saved_helmet_id
	helmet_rank = _saved_helmet_rank
	gloves_id = _saved_gloves_id
	gloves_rank = _saved_gloves_rank
	perks = _saved_perks.duplicate(true)
	curse_ids = _saved_curses.duplicate()
	active_vitamins = _saved_vitamins.duplicate()


func _strip_range_preview() -> void:
	if helmet_id == Loadout.DRIVE_LID:
		helmet_id = ""
		helmet_rank = 0
	if gloves_id == Loadout.HIGH_AIR:
		gloves_id = ""
		gloves_rank = 0
	var kept: Array = []
	for item in perks:
		if str(item.get("id", "")) != Loadout.GLASS_LEG:
			kept.append(item)
	perks = kept
	var curses: Array = []
	for id in curse_ids:
		if str(id) != Loadout.STONE and str(id) != Loadout.SHAKY:
			curses.append(id)
	curse_ids = curses
	active_vitamins.erase(Vitamins.PROTEIN)


func _set_slot(id: String, rank: int) -> void:
	var slot := Loadout.slot_of(id)
	if slot == Loadout.CLEATS:
		cleats_id = id
		cleats_rank = rank
	elif slot == Loadout.HELMET:
		helmet_id = id
		helmet_rank = rank
	elif slot == Loadout.GLOVES:
		gloves_id = id
		gloves_rank = rank


func _slot_rank(id: String) -> int:
	var slot := Loadout.slot_of(id)
	if slot == Loadout.HELMET and helmet_id == id:
		return helmet_rank
	if slot == Loadout.GLOVES and gloves_id == id:
		return gloves_rank
	if slot == Loadout.CLEATS and cleats_id == id:
		return cleats_rank
	return 0


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


static func is_standard_boss_slot(kick: int) -> bool:
	return kick == 5 or kick == 10 or kick == 15 or kick == 20


static func boss_weather(_kick: int) -> String:
	# Standard boss names are rolled into standard_bosses. This no longer names a slot.
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
	var generated := _forced_cards.size() == 0
	if _forced_cards.size() > 0:
		offer = []
		for item in _forced_cards:
			offer.append(_as_loadout_card(item))
		_forced_cards = []
	else:
		offer = Loadout.draw_offer(loadout_state(), attempt_cap, _offer_rng, [], _curse_weight())
	_consider_power_safety()
	if generated:
		_apply_synchronicity_offer()
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


func free_reroll_ready() -> bool:
	if tad_active(5):
		return false
	return awaiting_offer and not awaiting_shop and second_look_bank > 0 and stats.second_look


func reroll_offer() -> bool:
	if tad_active(5) or not awaiting_offer or awaiting_shop:
		return false
	# The banked free reroll is spent before Walk-On or Scout Lid charges.
	if second_look_bank > 0 and stats.second_look:
		second_look_bank -= 1
	elif rerolls_left <= 0:
		return false
	else:
		rerolls_left -= 1
	var previous: Array = offer.duplicate(true)
	offer = Loadout.draw_offer(loadout_state(), attempt_cap, _offer_rng, previous, _curse_weight())
	_consider_power_safety()
	awaiting_offer = true
	return true


func _consider_power_safety() -> void:
	if run_mode == "endless" and not power_item_seen and RunTable.endless_distance(kick_number + 1) >= 50.0:
		offer = Loadout.with_power_safety(offer, loadout_state(), attempt_cap, _offer_rng)
	for card in offer:
		if Loadout.is_power_item(str(card.get("id", ""))):
			power_item_seen = true


func opens_shop() -> bool:
	if phase != Phase.PLAYING or not last_result_made:
		return false
	if run_mode == "endless":
		return kick_number > 0 and kick_number % 5 == 0
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
		return "Next boss: %s" % _boss_label(str(standard_bosses.get(10, "")))
	if kick_number == 10:
		return "Next boss: %s" % _boss_label(str(standard_bosses.get(15, "")))
	if kick_number == 15:
		return "Next boss: %s" % _boss_label(str(standard_bosses.get(20, "")))
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
	if name == LIGHTS:
		return "UNDER THE LIGHTS"
	if name == CLOCK:
		return "Kick Clock"
	if name == MOVING:
		return "Moving Posts"
	return name


func _endless_boss(kick: int) -> String:
	if endless_bosses.has(kick):
		return str(endless_bosses[kick])
	var names := endless_boss_names()
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
	if cash < shop_reroll_cost():
		shop_flash = "reroll"
		return false
	cash -= shop_reroll_cost()
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


# Wet or cold means the condition name is RAIN, SNOW, MUD, or MONSOON.
# Vitamin D clears the first three. It does not clear Monsoon.
# big_game strips the accuracy slow and keeps the yards. A kick stores one condition,
# so BIG GAME by itself is not wet and pays nothing.
static func rain_dance_pay(weather_name: String, big_game: bool, vitamin_d: bool) -> Dictionary:
	var wet := false
	if weather_name == MONSOON:
		wet = true
	elif not vitamin_d and (weather_name == RAIN or weather_name == SNOW or weather_name == MUD):
		wet = true
	return {"yards": wet, "slow": wet and not big_game}


func chain_gang_raw() -> float:
	return float(mini(maxi(streak, 0), 10))


func _scaled_perk_yards(raw: float) -> float:
	if raw <= 0.0:
		return 0.0
	var bonus := raw
	if has_curse(Loadout.HOWLING):
		bonus *= Loadout.HOWLING_ITEM
	return Loadout.scale_amount(bonus, item_effect_scale())


func weather_flags_now() -> Dictionary:
	var flags := weather_kick_flags(weather, stats.weather_cut)
	if vitamin_d_active():
		flags["rain_faster"] = false
		flags["snow_range"] = false
		flags["mud_power"] = false
	return flags


const RING_OPEN_YARDS := 3.0
const RING_COLLECT_YARDS := 1.5
const RING_PAST_UPRIGHT := 3.0
const RING_OUTER_PX := 856.0
const RING_OPEN_PX := 713.0


static func ring_outer_yards() -> float:
	return RING_OPEN_YARDS * (RING_OUTER_PX / RING_OPEN_PX)


static func ring_min_center(half_gap: float) -> float:
	# Inner edge stays clear of the upright's outer face.
	return half_gap + 0.08 + ring_outer_yards() * 0.5


static func ring_ideal_center(half_gap: float) -> float:
	return half_gap + RING_PAST_UPRIGHT


static func ring_window_reaches(center: float, side: float, half_gap: float, distance: float, spot: float, cap_deg: float) -> bool:
	var reach := distance * tan(deg_to_rad(maxf(cap_deg, 0.0)))
	var near := spot - reach
	var far := spot + reach
	var lo := center - RING_COLLECT_YARDS
	var hi := center + RING_COLLECT_YARDS
	var wide := half_gap + KickConstants.DOINK_BAND_YARDS + 0.001
	if side < 0.0:
		hi = minf(hi, -wide)
	else:
		lo = maxf(lo, wide)
	if lo > hi:
		return false
	return hi >= near and lo <= far


# Pulls the center inward only when the ideal spot is outside the aim cap
# and a point still outside the upright is inside that cap.
static func ring_placement(side: int, half_gap: float, distance: float, spot: float, cap_deg: float) -> Dictionary:
	var sign := -1.0 if side < 0 else 1.0
	var ideal := ring_ideal_center(half_gap)
	var minimum := ring_min_center(half_gap)
	if minimum > ideal:
		minimum = ideal
	if ring_window_reaches(sign * ideal, sign, half_gap, distance, spot, cap_deg):
		return {"x": sign * ideal, "pulled": false, "blocked": false}
	if not ring_window_reaches(sign * minimum, sign, half_gap, distance, spot, cap_deg):
		return {"x": sign * ideal, "pulled": false, "blocked": true}
	var low := minimum
	var high := ideal
	for _i in 24:
		var mid := (low + high) * 0.5
		if ring_window_reaches(sign * mid, sign, half_gap, distance, spot, cap_deg):
			low = mid
		else:
			high = mid
	return {"x": sign * low, "pulled": true, "blocked": false}


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


func scheduled_ring() -> bool:
	if run_mode == "endless":
		return kick_number == 17 or kick_number == 47 or kick_number == 97 or kick_number == 147
	return run_mode == "standard" and kick_number == 13


func _ring_armed() -> bool:
	if practicing or phase != Phase.PLAYING or is_boss():
		return false
	if bool(ring_spent.get(kick_number, false)):
		return false
	if bool(ring_debug.get(kick_number, false)):
		return true
	return scheduled_ring()


func ring_showing() -> bool:
	return _ring_armed()


func arm_debug_ring() -> bool:
	# Same gate as the other debug keys: a live kick, not a boss, not practice.
	if practicing or phase != Phase.PLAYING or is_boss():
		return false
	if bool(ring_spent.get(kick_number, false)):
		return false
	ring_debug[kick_number] = true
	_ensure_ring_side()
	return true


func ring_side() -> int:
	_ensure_ring_side()
	return int(ring_sides.get(kick_number, 1))


func _ensure_ring_side() -> void:
	if ring_sides.has(kick_number):
		return
	ring_sides[kick_number] = -1 if _rng.randi_range(0, 1) == 0 else 1


func ring_place(distance: float, spot: float, half_gap: float, cap_deg: float) -> Dictionary:
	if not ring_showing():
		return {"x": 0.0, "pulled": false, "blocked": false, "show": false}
	return ring_placement(ring_side(), half_gap, distance, spot, cap_deg)


func collects_at(offset: float, center: float, result_text: String, reached: bool, shanked: bool) -> bool:
	if shanked or practicing or not reached or not ring_showing():
		return false
	if result_text != "WIDE LEFT" and result_text != "WIDE RIGHT":
		return false
	return absf(offset - center) <= RING_COLLECT_YARDS


func open_ring_offer() -> bool:
	if not ring_offer_pending or phase != Phase.PLAYING:
		return false
	var cards := Loadout.draw_ring_offer(loadout_state(), _offer_rng)
	ring_offer_pending = false
	if cards.is_empty():
		ring_offer_skipped = true
		return false
	offer = cards
	awaiting_offer = true
	return true


func _spend_ring() -> void:
	ring_spent[kick_number] = true


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


func _pair(slot: String) -> Array:
	if slot == Loadout.CLEATS:
		return [cleats_id, cleats_rank, cleats2_id, cleats2_rank]
	if slot == Loadout.HELMET:
		return [helmet_id, helmet_rank, helmet2_id, helmet2_rank]
	return [gloves_id, gloves_rank, gloves2_id, gloves2_rank]


func _accept_equipment(slot: String, id: String, rank: int) -> bool:
	if rank > Loadout.max_rank(id, run_mode) or rank < 1:
		return false
	var pair := _pair(slot)
	var first := str(pair[0])
	var first_rank := int(pair[1])
	var second := str(pair[2])
	var second_rank := int(pair[3])
	if id == first:
		return rank > first_rank
	if id == second:
		return rank > second_rank
	if first == "":
		return true
	if second == "":
		return true
	return false


func _store_equipment(slot: String, id: String, rank: int) -> void:
	var pair := _pair(slot)
	var first := str(pair[0])
	var second := str(pair[2])
	var into_second := first != "" and id != first
	if slot == Loadout.CLEATS:
		if into_second:
			cleats2_id = id
			cleats2_rank = rank
		else:
			cleats_id = id
			cleats_rank = rank
	elif slot == Loadout.HELMET:
		if into_second:
			helmet2_id = id
			helmet2_rank = rank
		else:
			helmet_id = id
			helmet_rank = rank
	elif into_second:
		gloves2_id = id
		gloves2_rank = rank
	else:
		gloves_id = id
		gloves_rank = rank
	if second != "" and id == second:
		pass


func give(id: String, rank: int = 1) -> void:
	_fixture_saved = false
	var slot := Loadout.slot_of(id)
	if slot == "":
		return
	var previous_bench := 0
	if slot == Loadout.CLEATS or slot == Loadout.HELMET or slot == Loadout.GLOVES:
		if not _accept_equipment(slot, id, rank):
			return
	elif slot == Loadout.PERK:
		var have := _perk_rank(id)
		previous_bench = have
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
	if slot == Loadout.CLEATS or slot == Loadout.HELMET or slot == Loadout.GLOVES:
		_store_equipment(slot, id, rank)
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
	if reroll_gain > 0 and not tad_active(5):
		rerolls_left += reroll_gain
	var doink_gain := stats.doink_per_quarter - doink_before
	if doink_gain > 0:
		insurance_left += doink_gain
	var practice_gain := stats.practice_per_quarter - practice_before
	if practice_gain > 0:
		practice_left += practice_gain
	if id == Loadout.SECOND_LOOK and previous_bench == 0 and not tad_active(5):
		second_look_bank += 1
	if id == Loadout.DEEP_BENCH:
		if previous_bench < 3 and rank >= 3 and attempts < attempt_cap:
			attempts += 1
		_bank_deep_bench(previous_bench, rank)


func _grant_bench_attempt() -> void:
	bench_extra_cap += 1
	attempt_cap += 1
	attempts = mini(attempts + 1, attempt_cap)


func _bank_deep_bench(old_rank: int, new_rank: int) -> void:
	var step := maxi(old_rank + 1, 4)
	while step <= new_rank:
		bench_bank += 0.5
		if bench_bank >= 0.999:
			bench_bank -= 1.0
			_grant_bench_attempt()
		if step == 6 and bench_bank >= 0.499:
			bench_bank = 0.0
			_grant_bench_attempt()
		step += 1


func loadout_state() -> Dictionary:
	return {
		"cleats_id": cleats_id,
		"cleats_rank": cleats_rank,
		"cleats2_id": cleats2_id,
		"cleats2_rank": cleats2_rank,
		"helmet_id": helmet_id,
		"helmet_rank": helmet_rank,
		"helmet2_id": helmet2_id,
		"helmet2_rank": helmet2_rank,
		"gloves_id": gloves_id,
		"gloves_rank": gloves_rank,
		"gloves2_id": gloves2_id,
		"gloves2_rank": gloves2_rank,
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
	_rebuild_raw_stats()
	_finish_needles()


func _rebuild_raw_stats() -> void:
	stats.reset()
	if kicker_id != "":
		Kickers.apply_to(stats, kicker_id)
	Loadout.apply(stats, loadout_state(), has_curse(Loadout.HOWLING), item_effect_scale())
	if _walk_on_clutch():
		stats.range_bonus += 6.0
	attempt_cap = mini(stats.attempt_cap, KickConstants.ATTEMPT_CAP_MAX) + bench_extra_cap


func _walk_on_clutch() -> bool:
	# A mulligan sets is_first_ball false, so that retry is clutch too.
	# Practice Swing never is.
	return kicker_id == Kickers.WALK_ON and not is_first_ball and not practicing


func _finish_needles() -> void:
	# One combined speed. Slows are already in power_speed. Walk-On clutch joins them
	# before the 0.35 floor. Stone Toe and UNDER THE LIGHTS come after the floor.
	# Rain and ball speed are applied later, in the shared kick omega, and are not floored.
	var base := KickConstants.POWER_RISE_PER_SEC
	var clutch := 0.90 if _walk_on_clutch() else 1.0
	var stone := 1.20 if has_curse(Loadout.STONE) else 1.0
	var lights := LIGHTS_NEEDLE if lights_active() else 1.0
	# TAD 7 sits after the 0.35 floor, with Stone Toe and UNDER THE LIGHTS.
	# Rain and ball speed still multiply later, in the shared kick omega.
	# Practice Swing uses this same combined speed, so the 1.33 applies there too.
	# Lights stay off during practice because lights_active() is false.
	var crunch := 1.33 if tad_active(7) else 1.0
	var combined := MeterGauge.needle_speed(base, stats.power_speed / base * clutch, stone, lights, 1.0, 1.0) * crunch
	stats.power_speed = combined
	stats.accuracy_speed = combined


func owned_labels() -> Array:
	var labels: Array = []
	if cleats_id != "":
		labels.append(Loadout.card_title(cleats_id, cleats_rank))
	if cleats2_id != "":
		labels.append(Loadout.card_title(cleats2_id, cleats2_rank))
	if helmet_id != "":
		labels.append(Loadout.card_title(helmet_id, helmet_rank))
	if helmet2_id != "":
		labels.append(Loadout.card_title(helmet2_id, helmet2_rank))
	if gloves_id != "":
		labels.append(Loadout.card_title(gloves_id, gloves_rank))
	if gloves2_id != "":
		labels.append(Loadout.card_title(gloves2_id, gloves2_rank))
	for item in perks:
		labels.append(Loadout.card_title(str(item.get("id", "")), int(item.get("rank", 1))))
	for id in curse_ids:
		labels.append(Loadout.piece_name(str(id)))
	return labels


func upcoming_winds() -> Array:
	# Future kicks are not forecast. The visor only describes this kick.
	return []


func _close_offer() -> void:
	awaiting_offer = false
	offer = []


func _refill_quarter() -> void:
	# Kicks 1–5, 6–10, 11–15, and so on. Each block adds one. Unused ones carry.
	if (kick_number - 1) % 5 == 0 and _perk_rank(Loadout.SECOND_LOOK) > 0 and not tad_active(5):
		second_look_bank += 1
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


func export_resume() -> Dictionary:
	var place := "tee"
	if awaiting_shop:
		place = "shop"
	elif awaiting_offer and not last_result_made:
		place = "ring"
	elif awaiting_offer:
		place = "offer"
	var bosses: Array = []
	for kick in endless_bosses.keys():
		bosses.append({"kick": int(kick), "name": str(endless_bosses[kick])})
	var vitamins: Array = []
	for id in active_vitamins.keys():
		vitamins.append({"id": str(id), "count": int(active_vitamins[id])})
	var clean: Array = []
	for kick in clean_makes.keys():
		if bool(clean_makes[kick]):
			clean.append(int(kick))
	return {
		"mode": run_mode,
		"kicker_id": kicker_id,
		"kick_number": kick_number,
		"spot_yards": spot_yards,
		"distance": int(round(distance_yards())),
		"attempts": attempts,
		"bench_extra_cap": bench_extra_cap,
		"bench_bank": bench_bank,
		"score": score,
		"streak": streak,
		"kicks_made": kicks_made,
		"longest_make": longest_make,
		"is_first_ball": is_first_ball,
		"cash": cash,
		"rerolls_left": rerolls_left,
		"second_look_bank": second_look_bank,
		"tad_level": tad_level,
		"mulligans_left": mulligans_left,
		"insurance_left": insurance_left,
		"practice_left": practice_left,
		"wind_speed": wind_speed,
		"wind_direction": wind_direction,
		"weather": weather,
		"weather_forced": weather_forced,
		"previous_weather": _previous_weather,
		"older_weather": _older_weather,
		"power_item_seen": power_item_seen,
		"synchronicity_offer_done": synchronicity_offer_done,
		"zinc_used": zinc_used,
		"lucky_stacks": lucky_stacks,
		"showtime_mult": showtime_mult,
		"balls_kicked": balls_kicked,
		"middles_this_run": middles_this_run,
		"best_streak": best_streak,
		"curses_locked": curses_locked,
		"shop_b12_bought": shop_b12_bought,
		"shop_reroll_price": shop_reroll_price,
		"place": place,
		"cleats_id": cleats_id,
		"cleats_rank": cleats_rank,
		"cleats2_id": cleats2_id,
		"cleats2_rank": cleats2_rank,
		"helmet_id": helmet_id,
		"helmet_rank": helmet_rank,
		"helmet2_id": helmet2_id,
		"helmet2_rank": helmet2_rank,
		"gloves_id": gloves_id,
		"gloves_rank": gloves_rank,
		"gloves2_id": gloves2_id,
		"gloves2_rank": gloves2_rank,
		"perks": perks.duplicate(true),
		"curses": curse_ids.duplicate(),
		"banned_curses": banned_curses.duplicate(),
		"belt": belt.duplicate(),
		"offer": offer.duplicate(true),
		"shop_stock": shop_stock.duplicate(),
		"bosses": bosses,
		"vitamins": vitamins,
		"clean": clean,
		"last_result_made": last_result_made,
		"ring_spent": _kick_keys(ring_spent),
		"ring_sides": _side_rows(),
		"ring_debug": _kick_keys(ring_debug),
		"ring_offer": ring_offer_pending,
		"kick10_boss": kick10_boss,
		"standard_bosses": _boss_rows(standard_bosses),
	}


func import_resume(data: Dictionary) -> void:
	new_run()
	run_mode = str(data.get("mode", "standard"))
	kicker_id = str(data.get("kicker_id", ""))
	cleats_id = str(data.get("cleats_id", ""))
	cleats_rank = int(data.get("cleats_rank", 0))
	cleats2_id = str(data.get("cleats2_id", ""))
	cleats2_rank = int(data.get("cleats2_rank", 0))
	helmet_id = str(data.get("helmet_id", ""))
	helmet_rank = int(data.get("helmet_rank", 0))
	helmet2_id = str(data.get("helmet2_id", ""))
	helmet2_rank = int(data.get("helmet2_rank", 0))
	gloves_id = str(data.get("gloves_id", ""))
	gloves_rank = int(data.get("gloves_rank", 0))
	gloves2_id = str(data.get("gloves2_id", ""))
	gloves2_rank = int(data.get("gloves2_rank", 0))
	perks = _dict_list(data.get("perks", []))
	curse_ids = _string_list(data.get("curses", []))
	banned_curses = _string_list(data.get("banned_curses", []))
	curses_locked = bool(data.get("curses_locked", false))
	bench_extra_cap = int(data.get("bench_extra_cap", 0))
	bench_bank = float(data.get("bench_bank", 0.0))
	rebuild_stats()
	kick_number = int(data.get("kick_number", 1))
	spot_yards = float(data.get("spot_yards", 0.0))
	attempts = int(data.get("attempts", attempts))
	score = int(data.get("score", 0))
	streak = int(data.get("streak", 0))
	kicks_made = int(data.get("kicks_made", 0))
	longest_make = float(data.get("longest_make", 0.0))
	is_first_ball = bool(data.get("is_first_ball", true))
	cash = int(data.get("cash", 0))
	rerolls_left = int(data.get("rerolls_left", rerolls_left))
	second_look_bank = int(data.get("second_look_bank", 0))
	tad_level = clampi(int(data.get("tad_level", 0)), 0, TAD_MAX)
	mulligans_left = int(data.get("mulligans_left", mulligans_left))
	insurance_left = int(data.get("insurance_left", insurance_left))
	practice_left = int(data.get("practice_left", practice_left))
	wind_speed = int(data.get("wind_speed", 0))
	wind_direction = float(data.get("wind_direction", 0.0))
	weather = str(data.get("weather", CLEAR))
	weather_forced = bool(data.get("weather_forced", false))
	_previous_weather = str(data.get("previous_weather", ""))
	_older_weather = str(data.get("older_weather", ""))
	power_item_seen = bool(data.get("power_item_seen", false))
	synchronicity_offer_done = bool(data.get("synchronicity_offer_done", false))
	zinc_used = bool(data.get("zinc_used", false))
	lucky_stacks = int(data.get("lucky_stacks", 0))
	showtime_mult = float(data.get("showtime_mult", 1.0))
	balls_kicked = int(data.get("balls_kicked", 0))
	middles_this_run = int(data.get("middles_this_run", 0))
	best_streak = int(data.get("best_streak", 0))
	shop_b12_bought = bool(data.get("shop_b12_bought", false))
	shop_reroll_price = int(data.get("shop_reroll_price", shop_reroll_price))
	belt = _string_list(data.get("belt", ["", ""]))
	while belt.size() < 2:
		belt.append("")
	endless_bosses = {}
	for pair in _dict_list(data.get("bosses", [])):
		endless_bosses[int(pair.get("kick", 0))] = str(pair.get("name", ""))
	active_vitamins = {}
	for pair in _dict_list(data.get("vitamins", [])):
		active_vitamins[str(pair.get("id", ""))] = int(pair.get("count", 0))
	clean_makes = {}
	for kick in data.get("clean", []):
		clean_makes[int(kick)] = true
	ring_spent = {}
	for kick in data.get("ring_spent", []):
		ring_spent[int(kick)] = true
	ring_debug = {}
	for kick in data.get("ring_debug", []):
		ring_debug[int(kick)] = true
	ring_sides = {}
	for pair in _dict_list(data.get("ring_sides", [])):
		ring_sides[int(pair.get("kick", 0))] = int(pair.get("side", 1))
	ring_offer_pending = bool(data.get("ring_offer", false))
	kick10_boss = str(data.get("kick10_boss", ""))
	var saved_bosses: Array = _dict_list(data.get("standard_bosses", []))
	if saved_bosses.size() >= 4:
		standard_bosses = {}
		for pair in saved_bosses:
			standard_bosses[int(pair.get("kick", 0))] = str(pair.get("name", ""))
		kick10_boss = str(standard_bosses.get(10, kick10_boss))
	var place := str(data.get("place", "tee"))
	if place == "offer":
		awaiting_offer = true
		kick_resolved = true
		last_result_made = true
		offer = _dict_list(data.get("offer", []))
	elif place == "ring":
		awaiting_offer = true
		kick_resolved = true
		last_result_made = false
		ring_offer_pending = false
		offer = _dict_list(data.get("offer", []))
	elif place == "shop":
		awaiting_shop = true
		kick_resolved = true
		last_result_made = true
		shop_stock = _string_list(data.get("shop_stock", ["", "", ""]))
	else:
		awaiting_offer = false
		awaiting_shop = false
		kick_resolved = false
		offer = []


func _dict_list(value) -> Array:
	var rows: Array = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				rows.append((item as Dictionary).duplicate(true))
	return rows


func _kick_keys(flags: Dictionary) -> Array:
	var keys: Array = []
	for kick in flags.keys():
		if bool(flags[kick]):
			keys.append(int(kick))
	return keys


func _side_rows() -> Array:
	var rows: Array = []
	for kick in ring_sides.keys():
		rows.append({"kick": int(kick), "side": int(ring_sides[kick])})
	return rows


func _string_list(value) -> Array:
	var rows: Array = []
	if value is Array:
		for item in value:
			rows.append(str(item))
	return rows


func _save_finished_run() -> void:
	if _run_saved:
		return
	_run_saved = true
	var data = _records()
	if data == null:
		return
	data.clear_run_slot(run_mode)
	if phase == Phase.WIN and run_mode != "endless":
		var unlocked := int(data.grant_tad_win(kicker_id, tad_level))
		if unlocked > tad_level:
			tad_toast = "TAD %d UNLOCKED" % unlocked
	var flags: Dictionary = data.commit_run({
		"score": score,
		"longest": int(round(longest_make)),
		"makes": kicks_made,
		"attempts": balls_kicked,
		"middles": middles_this_run,
		"won": phase == Phase.WIN,
		"kicker_id": kicker_id,
		"end_reason": end_reason,
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
		text += " (+5 Perfect)"
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


func _legal_synchronicity_pool() -> Array:
	var state := loadout_state()
	var legal := {}
	for card in Loadout.legal_equipment(state):
		legal[Loadout.card_key(card)] = card
	for card in Loadout.legal_perks(state, attempt_cap):
		legal[Loadout.card_key(card)] = card
	var pool: Array = []
	for id in [Loadout.CANNON, Loadout.DRIVE_LID, Loadout.HIGH_AIR, Loadout.GLASS_LEG]:
		var key := "%s|1" % id
		if legal.has(key):
			pool.append(legal[key])
	return pool


func _apply_synchronicity_offer() -> void:
	# The first generated offer of a Willow run. A reroll or a later make is a normal draw.
	if not stats.synchronicity or synchronicity_offer_done:
		return
	synchronicity_offer_done = true
	var pool := _legal_synchronicity_pool()
	if pool.is_empty() or offer.is_empty():
		return
	var pick: Dictionary = pool[_offer_rng.randi() % pool.size()]
	var pick_id := str(pick.get("id", ""))
	for card in offer:
		if str(card.get("id", "")) == pick_id and int(card.get("rank", 0)) == 1:
			power_item_seen = true
			return
	var slot := _offer_rng.randi() % offer.size()
	offer[slot] = pick.duplicate()
	power_item_seen = true


func _empty_belt() -> int:
	if str(belt[0]) == "":
		return 0
	if str(belt[1]) == "":
		return 1
	return -1


func _fill_shelves(opening: bool = false, avoid: Array = []) -> void:
	var picks: Array = Vitamins.draw_three(_shop_rng, [] if opening else avoid)
	shop_stock = ["", "", ""]
	for i in mini(3, picks.size()):
		shop_stock[i] = str(picks[i])


func item_effect_scale() -> float:
	var scale := 1.0
	if stats.compounding:
		scale *= 1.15
	if stats.lucky_ball:
		var lucky_bonus := minf(0.03 * float(lucky_stacks), 0.25)
		scale *= 1.0 + lucky_bonus
	return scale


func item_price(id: String) -> int:
	if stats.house_account:
		return 0
	return _tad_price(Vitamins.price(id))


func shop_reroll_cost() -> int:
	return _tad_price(shop_reroll_price)


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
	stats.range_bonus += _protein_range_bonus(_vitamin_count(Vitamins.PROTEIN))
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
		stats.path_percent = maxf(stats.path_percent, 100.0)


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
	_add_tad_wind()
	if is_standard_boss_slot(kick_number):
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


static func endless_boss_names() -> Array[String]:
	return [ICED, SQUEEZE, MONSOON, BIG_GAME, LIGHTS, CLOCK, MOVING]


static func post_slide(seconds: float) -> float:
	# Phase is 0 when the kick becomes ready. One full swing takes 4 seconds.
	return POST_SWING * sin(TAU * seconds / POST_PERIOD)


func lights_active() -> bool:
	return not practicing and weather == LIGHTS


func _roll_standard_bosses() -> void:
	# Kicks 5, 10, and 15 take three of the early five, without replacement.
	# Kick 20 is its own 50/50. _kick10_rng does not move the weather sequence.
	standard_bosses = {}
	var early: Array[String] = [ICED, SQUEEZE, MONSOON, LIGHTS, CLOCK]
	for slot in [5, 10, 15]:
		var index := _kick10_rng.randi_range(0, early.size() - 1)
		standard_bosses[slot] = early[index]
		early.remove_at(index)
	standard_bosses[20] = BIG_GAME if _kick10_rng.randf() < 0.5 else MOVING
	kick10_boss = str(standard_bosses[10])


func _boss_rows(book: Dictionary) -> Array:
	var rows: Array = []
	for kick in book.keys():
		rows.append({"kick": int(kick), "name": str(book[kick])})
	return rows


func _roll_weather() -> void:
	if weather_forced:
		return
	if run_mode == "endless" and is_boss():
		weather = _endless_boss(kick_number)
		return
	if run_mode != "endless" and is_standard_boss_slot(kick_number):
		weather = str(standard_bosses.get(kick_number, ""))
		return
	# One condition string. A boss name already fills it, so foul weather does not stack on top.
	if tad_active(9):
		var foul: Array[String] = [RAIN, SNOW, MUD]
		weather = foul[_weather_rng.randi() % foul.size()]
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
	else:
		wind_direction = float(_wind_rng.randi_range(0, 359))
	_add_tad_wind()


func _add_tad_wind() -> void:
	if tad_active(2):
		wind_speed += 3


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
