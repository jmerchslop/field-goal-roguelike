class_name Loadout
extends RefCounted

# The pieces a kicker can hold during one run.
# Three equipment slots, two perks, two curses. Nothing here is saved after the run.

const CLEATS := "cleats"
const HELMET := "helmet"
const GLOVES := "gloves"
const PERK := "perk"
const CURSE := "curse"
const EQUIPMENT := "equipment"

const CANNON := "cannon_cleats"
const PINPOINT := "pinpoint_cleats"
const ANCHOR := "anchor_cleats"
const STICKER := "sticker_cleats"
const WIND_VISOR := "wind_visor"
const ICE_CAGE := "ice_cage"
const SCOUT_LID := "scout_lid"
const DOINK_CAP := "doink_cap"
const DRIVE_LID := "drive_lid"
const IRON_GRIP := "iron_grip"
const REPLAY_GLOVES := "replay_gloves"
const HIGH_AIR := "high_air"
const WEATHER_WRAPS := "weather_wraps"
const DEEP_BENCH := "deep_bench"
const HOT_STREAK := "hot_streak"
const STORM_CHASER := "storm_chaser"
const HERO_BALL := "hero_ball"
const GLASS_LEG := "glass_leg"
const TWO_MINUTE := "two_minute_drill"
const ICED := "iced"
const SHANKY := "shanky_cleats"
const HEAVY := "heavy_ball"
const HOWLING := "howling_wind"
const SHAKY := "shaky_arrow"
const NARROW := "narrow_posts"
const STONE := "stone_toe"
const TIGHT := "tight_window"

const CLEAT_IDS: Array = [CANNON, PINPOINT, ANCHOR, STICKER]
const HELMET_IDS: Array = [WIND_VISOR, ICE_CAGE, SCOUT_LID, DOINK_CAP, DRIVE_LID]

const POWER_IDS: Array = [CANNON, DRIVE_LID, HIGH_AIR, GLASS_LEG, STONE, SHAKY]
const GLOVE_IDS: Array = [IRON_GRIP, REPLAY_GLOVES, HIGH_AIR, WEATHER_WRAPS]
const PERK_IDS: Array = [DEEP_BENCH, HOT_STREAK, STORM_CHASER, HERO_BALL, GLASS_LEG, TWO_MINUTE]
const CURSE_IDS: Array = [ICED, SHANKY, HEAVY, HOWLING, SHAKY, NARROW, STONE, TIGHT]

const _ROMAN: Array = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]


static func rank_label(rank: int) -> String:
	var index := clampi(rank, 0, 12)
	return str(_ROMAN[index])


static func slot_of(id: String) -> String:
	if CLEAT_IDS.has(id):
		return CLEATS
	if HELMET_IDS.has(id):
		return HELMET
	if GLOVE_IDS.has(id):
		return GLOVES
	if PERK_IDS.has(id):
		return PERK
	if CURSE_IDS.has(id):
		return CURSE
	return ""


static func kind_of(id: String) -> String:
	var slot := slot_of(id)
	if slot == PERK:
		return PERK
	if slot == CURSE:
		return CURSE
	if slot == "":
		return ""
	return EQUIPMENT


static func _two_decimals(value: float) -> String:
	var hundredths := int(round(absf(value) * 100.0))
	return "%d.%02d" % [int(hundredths / 100), hundredths % 100]


static func _scout_practice(rank: int) -> int:
	if rank < 4:
		return 0
	return 1 + int((rank - 4) / 2.0)


static func _swing_word(count: int) -> String:
	if count == 1:
		return "one"
	if count == 2:
		return "two"
	if count == 3:
		return "three"
	if count == 4:
		return "four"
	if count == 5:
		return "five"
	return str(count)


static func _ice_cage_line(rank: int) -> String:
	var line := "No red-tip penalty. Immune to Iced."
	if rank <= 1:
		return line
	line += " Accuracy needle ×0.90"
	var perfect := 0
	var odd := 3
	while odd <= rank:
		perfect += 1
		odd += 2
	var good := 0
	var even := 4
	while even <= rank:
		good += 2
		even += 2
	if perfect > 0 and good > 0:
		line += ". PERFECT +%d, good +%d" % [perfect, good]
	elif perfect > 0:
		line += ". PERFECT +%d" % perfect
	elif good > 0:
		line += ". good +%d" % good
	return line


static func _scout_rerolls(rank: int) -> int:
	if rank <= 3:
		return rank
	if rank == 4:
		return 3
	if rank == 5:
		return 4
	return rank - 1


static func max_rank(id: String, mode: String = "standard") -> int:
	if PERK_IDS.has(id):
		return 6 if mode == "endless" else 3
	if CURSE_IDS.has(id):
		return 1
	if slot_of(id) == "":
		return 0
	return 12 if mode == "endless" else 6


static func type_label(slot: String) -> String:
	if slot == CLEATS:
		return "CLEATS"
	if slot == HELMET:
		return "HELMET"
	if slot == GLOVES:
		return "GLOVES"
	if slot == PERK:
		return "PERK"
	if slot == CURSE:
		return "CURSE"
	return ""


static func piece_name(id: String) -> String:
	match id:
		CANNON:
			return "Cannon Cleats"
		PINPOINT:
			return "Pinpoint Cleats"
		ANCHOR:
			return "Anchor Cleats"
		STICKER:
			return "Sticker Cleats"
		WIND_VISOR:
			return "Wind Visor"
		DRIVE_LID:
			return "Drive Lid"
		ICE_CAGE:
			return "Ice Cage"
		SCOUT_LID:
			return "Scout Lid"
		DOINK_CAP:
			return "Doink Cap"
		IRON_GRIP:
			return "Iron Grip"
		REPLAY_GLOVES:
			return "Replay Gloves"
		HIGH_AIR:
			return "High-Air Gloves"
		WEATHER_WRAPS:
			return "Weather Wraps"
		DEEP_BENCH:
			return "Deep Bench"
		HOT_STREAK:
			return "Hot Streak"
		STORM_CHASER:
			return "Storm Chaser"
		HERO_BALL:
			return "Hero Ball"
		GLASS_LEG:
			return "Glass Leg"
		TWO_MINUTE:
			return "Two-Minute Drill"
		ICED:
			return "Iced"
		SHANKY:
			return "Shanky Cleats"
		HEAVY:
			return "Heavy Ball"
		HOWLING:
			return "Howling Wind"
		SHAKY:
			return "Shaky Arrow"
		NARROW:
			return "Narrow Posts"
		STONE:
			return "Stone Toe"
		TIGHT:
			return "Tight Window"
	return id


static func effect_line(id: String, rank: int) -> String:
	match id:
		CANNON:
			return "+%d yd" % (6 * rank)
		PINPOINT:
			return "PERFECT +%d, good +%d" % [2 * rank, 3 * rank]
		ANCHOR:
			return "Needles ×%s" % _two_decimals(pow(0.85, float(rank)))
		STICKER:
			return "Drift ×%s" % _two_decimals(pow(0.80, float(rank)))
		DRIVE_LID:
			return "+%d yd" % (4 * rank)
		WIND_VISOR:
			if rank <= 1:
				return "Shows wind mph and an arrow"
			var shown := int(KickLogic.path_percent_for_rank(rank))
			if shown >= 100:
				return "Wind mph and arrow. Dotted path for the full flight"
			return "Wind mph and arrow. Dotted path for %d%% of this kick" % shown
		ICE_CAGE:
			return _ice_cage_line(rank)
		SCOUT_LID:
			if rank <= 3:
				return "+%d reroll" % rank
			if rank == 4:
				return "+3 rerolls, and one Practice Swing a quarter"
			if rank == 5:
				return "+4 rerolls, and one Practice Swing a quarter"
			if rank == 6:
				return "+5 rerolls, and two Practice Swings a quarter"
			return "+%d rerolls, and %s Practice Swings a quarter" % [rank - 1, _swing_word(_scout_practice(rank))]
		DOINK_CAP:
			if rank == 6:
				return "5 doink-to-good a quarter, unused carry (max 5)"
			if rank >= 7:
				return "%d doink-to-good a quarter, unused carry (max %d)" % [rank, rank]
			return "%d doink-to-good a quarter" % rank
		IRON_GRIP:
			if rank <= 2:
				return "Red-tip noise −%d" % (2 * rank)
			if rank == 3:
				return "Noise −4 (min ±1), red tip 3 later"
			if rank == 4:
				return "Noise −4 (min ±1), red tip 6 later"
			if rank == 5:
				return "Noise −4 (min ±1), red tip 9 later"
			return "Red tip never triggers"
		REPLAY_GLOVES:
			if rank == 6:
				return "5 practice swings, unused carry (max 5)"
			if rank >= 7:
				return "%d practice swings, unused carry (max %d)" % [rank, rank]
			return "%d practice swing a quarter" % rank
		HIGH_AIR:
			return "+%d yd, tailwind range ×1.5" % (2 * rank)
		WEATHER_WRAPS:
			if rank <= 1:
				return "Rain, snow, and mud penalties cut in half"
			if rank == 2:
				return "Rain, snow, and mud penalties ignored"
			if rank == 3:
				return "Also ignores Monsoon's rain and mud"
			if rank >= 4:
				return "Penalties ignored, +%d yd unless CLEAR" % (2 * (rank - 3))
			return ""
		DEEP_BENCH:
			if rank <= 2:
				return "Attempt cap +%d and attempts +%d" % [rank, rank]
			if rank == 3:
				return "Cap stays. +1 attempt now and each quarter if below cap"
			if rank == 4:
				return "Cap stays. Halfway to +1 extra attempt. Spare stays."
			if rank == 5:
				return "+1 attempt cap and +1 attempt now. Spare stays."
			return "+1 more attempt cap and +1 attempt now. Spare stays."
		HOT_STREAK:
			if rank <= 1:
				return "Streak step +0.5"
			if rank == 2:
				return "Streak step +0.75"
			if rank == 3:
				return "Streak step +1.0"
			if rank == 4:
				return "Streak step +1.25"
			if rank == 5:
				return "Streak step +1.5"
			return "Streak step +1.75"
		STORM_CHASER:
			if rank <= 1:
				return "+0.2 Mult per mph of crosswind"
			if rank == 2:
				return "+0.4 Mult per mph of crosswind"
			if rank == 3:
				return "+0.6 Mult per mph of crosswind"
			if rank == 4:
				return "+0.8 Mult per mph of crosswind"
			if rank == 5:
				return "+1.0 Mult per mph of crosswind"
			return "+1.2 Mult per mph of crosswind"
		HERO_BALL:
			if rank <= 1:
				return "+1.0 Mult, both needles ×0.80"
			if rank == 2:
				return "+1.5 Mult, both needles ×0.80"
			if rank == 3:
				return "+2.0 Mult, both needles ×0.80"
			if rank == 4:
				return "+2.5 Mult, both needles ×0.80"
			if rank == 5:
				return "+3.0 Mult, both needles ×0.80"
			return "+3.5 Mult, both needles ×0.80"
		GLASS_LEG:
			if rank <= 1:
				return "+8 yd, attempt cap −1"
			if rank == 2:
				return "+16 yd total, no extra cap loss"
			if rank == 3:
				return "+24 yd total, no extra cap loss"
			if rank == 4:
				return "+32 yd total, no extra cap loss"
			if rank == 5:
				return "+40 yd total, no extra cap loss"
			return "+48 yd total, no extra cap loss"
		TWO_MINUTE:
			if rank <= 1:
				return "Boss kicks +0.5 Mult, on top of ×1.5"
			if rank == 2:
				return "Boss kicks +1.0 Mult, on top of ×1.5"
			if rank == 3:
				return "Boss kicks +1.5 Mult, on top of ×1.5"
			if rank == 4:
				return "Boss kicks +2.0 Mult, on top of ×1.5"
			if rank == 5:
				return "Boss kicks +2.5 Mult, on top of ×1.5"
			return "Boss kicks +3.0 Mult, on top of ×1.5"
		ICED:
			return "Down: meter hides 0.4s after Space. Up: +0.5 Mult"
		SHANKY:
			return "Down: accuracy error ×1.5. Up: +0.5 Mult"
		HEAVY:
			return "Down: −4 yd. Up: accuracy error ×0.85"
		HOWLING:
			return "Down: wind ×1.5. Up: equipment and perks ×1.15"
		SHAKY:
			return "Down: aim sways ±3°. Up: +6 yd"
		NARROW:
			return "Down: posts 5.17 yd. Up: +0.5 Mult"
		STONE:
			return "Down: power needle ×1.20. Up: +6 yd"
		TIGHT:
			return "Down: PERFECT and good −2. Up: +0.5 Mult"
	return ""


static func card_title(id: String, rank: int) -> String:
	var name := piece_name(id)
	if CURSE_IDS.has(id):
		return name
	var roman := rank_label(rank)
	if roman == "":
		return name
	return "%s %s" % [name, roman]


# A factor like 0.85 becomes a little stronger: the gap from 1.0 grows by 15%.
static func boost_factor(factor: float) -> float:
	return 1.0 - (1.0 - factor) * 1.15


static func scale_gap(factor: float, item_scale: float) -> float:
	if absf(item_scale - 1.0) < 0.0001:
		return factor
	return 1.0 - (1.0 - factor) * item_scale


static func scale_amount(amount: float, item_scale: float) -> float:
	if absf(item_scale - 1.0) < 0.0001:
		return amount
	return KickLogic.round_tenth(amount * item_scale)


static func empty_state() -> Dictionary:
	return {
		"cleats_id": "",
		"cleats_rank": 0,
		"helmet_id": "",
		"helmet_rank": 0,
		"gloves_id": "",
		"gloves_rank": 0,
		"perks": [],
		"curses": [],
	}


static func _perk_rank(state: Dictionary, id: String) -> int:
	for item in state.get("perks", []):
		if str(item.get("id", "")) == id:
			return int(item.get("rank", 0))
	return 0


static func legal_equipment(state: Dictionary) -> Array:
	var cards: Array = []
	var slots := [
		[CLEATS, str(state.get("cleats_id", "")), int(state.get("cleats_rank", 0)), CLEAT_IDS],
		[HELMET, str(state.get("helmet_id", "")), int(state.get("helmet_rank", 0)), HELMET_IDS],
		[GLOVES, str(state.get("gloves_id", "")), int(state.get("gloves_rank", 0)), GLOVE_IDS],
	]
	for slot in slots:
		var slot_name := str(slot[0])
		var owned_id := str(slot[1])
		var rank := int(slot[2])
		var pool: Array = slot[3]
		if owned_id == "":
			for id in pool:
				cards.append(_card(EQUIPMENT, slot_name, str(id), 1))
		elif rank < max_rank(owned_id, str(state.get("run_mode", "standard"))):
			cards.append(_card(EQUIPMENT, slot_name, owned_id, rank + 1))
	return cards


static func legal_perks(state: Dictionary, attempt_cap: int) -> Array:
	var cards: Array = []
	var owned: Array = state.get("perks", [])
	for id in PERK_IDS:
		if id == GLASS_LEG and attempt_cap <= 2 and _perk_rank(state, str(id)) == 0:
			continue
		var have := _perk_rank(state, str(id))
		if have == 0:
			if owned.size() < 2:
				cards.append(_card(PERK, PERK, str(id), 1))
		elif have < max_rank(str(id), str(state.get("run_mode", "standard"))):
			cards.append(_card(PERK, PERK, str(id), have + 1))
	return cards


static func legal_curses(state: Dictionary) -> Array:
	var owned: Array = state.get("curses", [])
	# Two curses picked this run locks the type even if Tart Cherry removes one.
	if bool(state.get("curses_locked", false)) or owned.size() >= 2:
		return []
	var banned: Array = state.get("banned_curses", [])
	var blocked_ice := str(state.get("helmet_id", "")) == ICE_CAGE
	var cards: Array = []
	for id in CURSE_IDS:
		if owned.has(id) or banned.has(id):
			continue
		if id == ICED and blocked_ice:
			continue
		cards.append(_card(CURSE, CURSE, str(id), 1))
	return cards


static func card_key(card) -> String:
	return "%s|%s" % [str(card.get("id", "")), int(card.get("rank", 0))]


static func draw_offer(state: Dictionary, attempt_cap: int, rng: RandomNumberGenerator, avoid: Array = []) -> Array:
	var equip := legal_equipment(state)
	var perks := legal_perks(state, attempt_cap)
	var curses := legal_curses(state)
	if not avoid.is_empty():
		var keys := {}
		for card in avoid:
			keys[card_key(card)] = true
		var fresh_equip := _without_keys(equip, keys)
		# One equipment card is still required when any equipment is legal.
		# If the previous card was the only one, it may come back.
		if fresh_equip.is_empty() and not equip.is_empty():
			fresh_equip = equip
		var fresh_perks := _without_keys(perks, keys)
		var fresh_curses := _without_keys(curses, keys)
		if _pools_can_fill_offer(fresh_equip, fresh_perks, fresh_curses):
			equip = fresh_equip
			perks = fresh_perks
			curses = fresh_curses
	return _compose_offer(equip, perks, curses, rng)


static func _without_keys(cards: Array, keys: Dictionary) -> Array:
	var kept: Array = []
	for card in cards:
		if keys.has(card_key(card)):
			continue
		kept.append(card)
	return kept


static func _pools_can_fill_offer(equip: Array, perks: Array, curses: Array) -> bool:
	var fillers := perks.size() + mini(curses.size(), 1)
	if equip.size() > 0:
		fillers += equip.size()
	return fillers >= 3


static func _compose_offer(equip: Array, perks: Array, curses: Array, rng: RandomNumberGenerator) -> Array:
	var cards: Array = []
	if equip.size() > 0:
		var index := rng.randi_range(0, equip.size() - 1)
		cards.append(equip[index])
		equip.remove_at(index)
	var pool: Array = []
	pool.append_array(perks)
	pool.append_array(curses)
	_fill_offer(cards, pool, rng, true)
	# Perks and curses can run out while equipment ranks are still legal.
	if cards.size() < 3 and equip.size() > 0:
		_fill_offer(cards, equip, rng, false)
	return cards


static func _fill_offer(cards: Array, pool: Array, rng: RandomNumberGenerator, limit_curses: bool) -> void:
	var used_curse := false
	for have in cards:
		if str(have.get("kind", "")) == CURSE:
			used_curse = true
	var guard := 0
	while cards.size() < 3 and pool.size() > 0 and guard < 40:
		guard += 1
		var index := rng.randi_range(0, pool.size() - 1)
		var card: Dictionary = pool[index]
		pool.remove_at(index)
		if limit_curses and str(card.get("kind", "")) == CURSE:
			if used_curse:
				continue
			used_curse = true
		var duplicate := false
		for have in cards:
			if str(have.get("id", "")) == str(card.get("id", "")):
				duplicate = true
		if duplicate:
			continue
		cards.append(card)


static func _card(kind: String, slot: String, id: String, rank: int) -> Dictionary:
	return {"kind": kind, "slot": slot, "id": id, "rank": rank}


static func is_power_item(id: String) -> bool:
	return POWER_IDS.has(id)


static func offer_has_power(cards: Array) -> bool:
	for card in cards:
		if is_power_item(str(card.get("id", ""))):
			return true
	return false


static func legal_power_items(state: Dictionary, attempt_cap: int) -> Array:
	var found: Array = []
	for card in legal_equipment(state):
		if is_power_item(str(card.get("id", ""))):
			found.append(card)
	for card in legal_perks(state, attempt_cap):
		if is_power_item(str(card.get("id", ""))):
			found.append(card)
	for card in legal_curses(state):
		if is_power_item(str(card.get("id", ""))):
			found.append(card)
	return found


# Endless only calls this. One card is swapped in after the normal draw.
static func with_power_safety(cards: Array, state: Dictionary, attempt_cap: int, rng: RandomNumberGenerator) -> Array:
	if offer_has_power(cards) or cards.is_empty():
		return cards
	var choices := legal_power_items(state, attempt_cap)
	if choices.is_empty():
		return cards
	var offer: Array = []
	for card in cards:
		offer.append((card as Dictionary).duplicate())
	var flexible: Array = []
	var equipment_only: Array = []
	for card in choices:
		if str(card.get("kind", "")) == EQUIPMENT:
			equipment_only.append(card)
		else:
			flexible.append(card)
	if _place_power_pick(offer, flexible, rng):
		return offer
	if _place_equipment_power(offer, equipment_only, rng):
		return offer
	return cards


static func _place_power_pick(offer: Array, picks: Array, rng: RandomNumberGenerator) -> bool:
	var pool: Array = picks.duplicate()
	while not pool.is_empty():
		var index := rng.randi() % pool.size()
		var pick: Dictionary = pool[index]
		pool.remove_at(index)
		var slot := _safety_index(offer, pick)
		if slot < 0:
			continue
		offer[slot] = pick
		return true
	return false


static func _place_equipment_power(offer: Array, picks: Array, rng: RandomNumberGenerator) -> bool:
	if picks.is_empty():
		return false
	var pick: Dictionary = picks[rng.randi() % picks.size()]
	var slot := _index_kind(offer, EQUIPMENT)
	if slot < 0:
		slot = 0
	offer[slot] = pick
	return true


static func _safety_index(offer: Array, pick: Dictionary) -> int:
	var curse_at := _index_kind(offer, CURSE)
	var perk_at := _index_kind(offer, PERK)
	if str(pick.get("kind", "")) == CURSE:
		if curse_at >= 0:
			return curse_at
		if perk_at >= 0:
			return perk_at
		return -1
	if perk_at >= 0:
		return perk_at
	if curse_at >= 0:
		return curse_at
	return -1


static func _index_kind(offer: Array, kind: String) -> int:
	for i in offer.size():
		if str(offer[i].get("kind", "")) == kind:
			return i
	return -1


# stats already has the kicker's base kit. This adds the owned pieces.
# howling makes equipment and perk numbers 15% stronger. Curse upsides are not included.
static func apply(stats: KickerStats, state: Dictionary, howling: bool, item_scale: float = 1.0) -> void:
	var range_add := 0.0
	var perfect_add := 0.0
	var good_add := 0.0
	var power_mul := 1.0
	var accuracy_mul := 1.0
	var drift_mul := 1.0
	var cleats := str(state.get("cleats_id", ""))
	var cleat_rank := int(state.get("cleats_rank", 0))
	var helmet := str(state.get("helmet_id", ""))
	var helmet_rank := int(state.get("helmet_rank", 0))
	var gloves := str(state.get("gloves_id", ""))
	var glove_rank := int(state.get("gloves_rank", 0))
	if cleats == CANNON:
		range_add += 6.0 * float(cleat_rank)
	elif cleats == PINPOINT:
		perfect_add += 2.0 * float(cleat_rank)
		good_add += 3.0 * float(cleat_rank)
	elif cleats == ANCHOR:
		var factor := pow(0.85, float(cleat_rank))
		if howling:
			factor = boost_factor(factor)
		factor = scale_gap(factor, item_scale)
		power_mul *= factor
		accuracy_mul *= factor
	elif cleats == STICKER:
		var factor := pow(0.80, float(cleat_rank))
		if howling:
			factor = boost_factor(factor)
		factor = scale_gap(factor, item_scale)
		drift_mul *= factor
	if helmet == WIND_VISOR:
		stats.flag_reader = helmet_rank >= 1
		stats.path_percent = KickLogic.path_percent_for_rank(helmet_rank)
		stats.laser_line = stats.path_percent > 0.0
	elif helmet == ICE_CAGE:
		stats.ice_cage = true
		stats.ice_veins = true
		if helmet_rank >= 2:
			var factor := 0.90
			if howling:
				factor = boost_factor(factor)
			factor = scale_gap(factor, item_scale)
			accuracy_mul *= factor
		var odd := 3
		while odd <= helmet_rank:
			perfect_add += 1.0
			odd += 2
		var even := 4
		while even <= helmet_rank:
			good_add += 2.0
			even += 2
	elif helmet == SCOUT_LID:
		stats.rerolls_per_run += _scout_rerolls(helmet_rank)
		if helmet_rank >= 4:
			stats.practice_per_quarter += 1 + int((helmet_rank - 4) / 2.0)
	elif helmet == DRIVE_LID:
		range_add += 4.0 * float(helmet_rank)
	elif helmet == DOINK_CAP:
		if helmet_rank <= 5:
			stats.doink_per_quarter = helmet_rank
		elif helmet_rank == 6:
			stats.doink_per_quarter = 5
		else:
			stats.doink_per_quarter = helmet_rank
		stats.doink_carry = helmet_rank >= 6
	if gloves == IRON_GRIP:
		var cut := 2.0 * float(mini(glove_rank, 2))
		stats.red_tip_noise = maxf(stats.red_tip_noise - cut, 1.0)
		if glove_rank >= 3:
			stats.red_tip_start += 3.0
		if glove_rank >= 4:
			stats.red_tip_start += 3.0
		if glove_rank >= 5:
			stats.red_tip_start += 3.0
		stats.red_tip_off = glove_rank >= 6
	elif gloves == REPLAY_GLOVES:
		if glove_rank >= 7:
			stats.practice_per_quarter += glove_rank
		else:
			stats.practice_per_quarter += mini(glove_rank, 5)
		stats.practice_carry = glove_rank >= 6
	elif gloves == HIGH_AIR:
		range_add += 2.0 * float(glove_rank)
		stats.thin_air = true
	elif gloves == WEATHER_WRAPS:
		if glove_rank <= 1:
			stats.weather_cut = 1
		elif glove_rank == 2:
			stats.weather_cut = 2
		else:
			stats.weather_cut = 3
		if glove_rank >= 4:
			stats.wraps_yards = 2.0 * float(glove_rank - 3)
	var hero_add := 0.0
	var storm := 0.0
	var drill := 0.0
	for perk_id in PERK_IDS:
		var id := str(perk_id)
		var rank := _perk_rank(state, id)
		if rank <= 0:
			continue
		if id == DEEP_BENCH:
			var cap_ranks := mini(rank, 2)
			stats.attempt_cap = mini(stats.attempt_cap + cap_ranks, KickConstants.ATTEMPT_CAP_MAX)
			stats.bench_spare = rank >= 3
		elif id == HOT_STREAK:
			if rank <= 1:
				stats.streak_step = 0.5
			elif rank == 2:
				stats.streak_step = 0.75
			else:
				stats.streak_step = 1.0 + 0.25 * float(rank - 3)
		elif id == STORM_CHASER:
			storm += 0.2 * float(rank)
		elif id == HERO_BALL:
			if rank <= 1:
				hero_add += 1.0
			elif rank == 2:
				hero_add += 1.5
			else:
				hero_add += 2.0 + 0.5 * float(rank - 3)
			var factor := 0.80
			if howling:
				factor = boost_factor(factor)
			factor = scale_gap(factor, item_scale)
			power_mul *= factor
			accuracy_mul *= factor
		elif id == GLASS_LEG:
			range_add += 8.0 * float(rank)
			stats.attempt_cap = maxi(stats.attempt_cap - 1, 1)
		elif id == TWO_MINUTE:
			drill += 0.5 * float(rank)
	if howling:
		range_add *= 1.15
		perfect_add *= 1.15
		good_add *= 1.15
		hero_add *= 1.15
		storm *= 1.15
		drill *= 1.15
	range_add = scale_amount(range_add, item_scale)
	perfect_add = scale_amount(perfect_add, item_scale)
	good_add = scale_amount(good_add, item_scale)
	hero_add = scale_amount(hero_add, item_scale)
	storm = scale_amount(storm, item_scale)
	drill = scale_amount(drill, item_scale)
	var curse_range := 0.0
	var curse_mult := 0.0
	var angle := 1.0
	var curses: Array = state.get("curses", [])
	if curses.has(ICED):
		curse_mult += 0.5
		stats.hide_meter = true
	if curses.has(SHANKY):
		angle *= 1.5
		curse_mult += 0.5
	if curses.has(HEAVY):
		angle *= 0.85
		stats.heavy_ball = true
	if curses.has(HOWLING):
		stats.howling = true
	if curses.has(SHAKY):
		curse_range += 6.0
		stats.shaky = true
	if curses.has(NARROW):
		curse_mult += 0.5
		stats.narrow_posts = true
	if curses.has(STONE):
		curse_range += 6.0
		power_mul *= 1.20
	if curses.has(TIGHT):
		curse_mult += 0.5
		stats.tight_window = true
	curse_range = scale_amount(curse_range, item_scale)
	curse_mult = scale_amount(curse_mult, item_scale)
	stats.range_bonus += range_add + curse_range
	stats.perfect_band += perfect_add
	stats.good_band += good_add
	if stats.tight_window:
		stats.perfect_band = maxf(stats.perfect_band - 2.0, 1.0)
		stats.good_band = maxf(stats.good_band - 2.0, 1.0)
	if stats.perfect_band > stats.good_band:
		stats.perfect_band = stats.good_band
	stats.power_speed *= power_mul
	stats.accuracy_speed *= accuracy_mul
	stats.drift_factor = drift_mul
	stats.hero_mult = hero_add
	stats.storm_per_mph = storm
	stats.drill_mult = drill
	stats.curse_mult = curse_mult
	stats.angle_scale = angle
	stats.attempt_cap = clampi(stats.attempt_cap, 1, KickConstants.ATTEMPT_CAP_MAX)


static var _sprite_ready := false
static var _item_paths := {}
static var _empty_paths := {}
static var _unmatched: Array = []

const _SLOT_WORDS: Array = ["cleats", "gloves", "helmet", "curse", "perk"]
const _RANK_TOKENS: Array = ["_viii", "_vii", "_vi", "_iv", "_iii", "_ii", "_ix", "_v", "_i", "_10", "_9", "_8", "_7", "_6", "_5", "_4", "_3", "_2", "_1"]


static func sprite_path(id: String) -> String:
	_ensure_sprites()
	return str(_item_paths.get(id, ""))


static func empty_slot_path(slot: String) -> String:
	_ensure_sprites()
	return str(_empty_paths.get(slot, ""))


static func ensure_sprites() -> void:
	_ensure_sprites()


static func print_sprite_map() -> void:
	_ensure_sprites()
	print("LOADOUT SPRITES")
	for id in _catalog_ids():
		var path := str(_item_paths.get(id, ""))
		if path == "":
			print("  ", piece_name(id), ": MISSING")
		else:
			print("  ", piece_name(id), ": ", path)
	print("EMPTY FRAMES")
	for slot in [CLEATS, HELMET, GLOVES, PERK, CURSE]:
		var path := str(_empty_paths.get(slot, ""))
		if path == "":
			print("  ", slot, ": MISSING")
		else:
			print("  ", slot, ": ", path)
	if _unmatched.is_empty():
		print("UNMATCHED LOADOUT FILES")
		print("  none")
	else:
		print("UNMATCHED LOADOUT FILES")
		for path in _unmatched:
			print("  ", path)


# Test hook. Does not replace the live scan.
static func map_sprite_files(paths: Array) -> Dictionary:
	var items := {}
	var empty := {}
	var unmatched: Array = []
	_fill_sprite_maps(paths, items, empty, unmatched)
	return {"items": items, "empty": empty, "unmatched": unmatched}


static func _ensure_sprites() -> void:
	if _sprite_ready:
		return
	_sprite_ready = true
	_item_paths = {}
	_empty_paths = {}
	_unmatched = []
	_fill_sprite_maps(_collect_images("res://"), _item_paths, _empty_paths, _unmatched)


static func _collect_images(root: String) -> Array:
	var found: Array = []
	_walk_images(root, found)
	return found


static func _walk_images(dir_path: String, found: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not name.begins_with("."):
			var full := dir_path.path_join(name)
			if dir.current_is_dir():
				_walk_images(full, found)
			else:
				var lower := name.to_lower()
				var image := lower.ends_with(".png") or lower.ends_with(".webp") or lower.ends_with(".jpg") or lower.ends_with(".jpeg")
				if image and not lower.ends_with(".import"):
					found.append(full)
		name = dir.get_next()
	dir.list_dir_end()


static func _fill_sprite_maps(paths: Array, items: Dictionary, empty: Dictionary, unmatched: Array) -> void:
	var best := {}
	var empty_best := {}
	for path in paths:
		var file_name := str(path).get_file()
		var stem := _normalize_stem(file_name.get_basename())
		if _skip_untyped(str(path), stem):
			continue
		var empty_slot := _empty_slot_of(stem)
		if empty_slot != "":
			var score := 2 if stem == "empty_" + empty_slot else 1
			if not empty_best.has(empty_slot) or int(empty_best[empty_slot]["score"]) < score:
				empty_best[empty_slot] = {"path": str(path), "score": score}
			continue
		var parsed := _split_slot(stem)
		var suffix := str(parsed["suffix"])
		var name_part := str(parsed["name"])
		var hit := ""
		if suffix != "":
			var slot_ids := _ids_for_word(suffix)
			hit = _match_ids(slot_ids, name_part)
			if hit == "":
				hit = _match_ids(slot_ids, name_part + "_" + suffix)
			if hit == "":
				hit = _match_ids(_catalog_ids(), stem)
			if hit == "":
				hit = _match_ids(_catalog_ids(), name_part)
			if hit == "":
				unmatched.append(str(path))
				continue
		else:
			hit = _match_ids(_catalog_ids(), stem)
			if hit == "":
				continue
		var score := 0
		if suffix != "":
			score = 2 if _word_for_slot(slot_of(hit)) == suffix else 1
		if not best.has(hit) or int(best[hit]["score"]) < score:
			best[hit] = {"path": str(path), "score": score}
	for id in best.keys():
		items[id] = str(best[id]["path"])
	for slot in empty_best.keys():
		empty[slot] = str(empty_best[slot]["path"])


static func _catalog_ids() -> Array:
	var ids: Array = []
	ids.append_array(CLEAT_IDS)
	ids.append_array(HELMET_IDS)
	ids.append_array(GLOVE_IDS)
	ids.append_array(PERK_IDS)
	ids.append_array(CURSE_IDS)
	return ids


static func _ids_for_word(word: String) -> Array:
	if word == "cleats":
		return CLEAT_IDS
	if word == "helmet":
		return HELMET_IDS
	if word == "gloves":
		return GLOVE_IDS
	if word == "perk":
		return PERK_IDS
	if word == "curse":
		return CURSE_IDS
	return []


static func _word_for_slot(slot: String) -> String:
	if slot == CLEATS:
		return "cleats"
	if slot == HELMET:
		return "helmet"
	if slot == GLOVES:
		return "gloves"
	if slot == PERK:
		return "perk"
	if slot == CURSE:
		return "curse"
	return ""


static func _normalize_stem(raw: String) -> String:
	var stem := raw.to_lower().replace("-", "_").replace(" ", "_")
	while stem.find("__") >= 0:
		stem = stem.replace("__", "_")
	return stem


static func _strip_rank(stem: String) -> String:
	for token in _RANK_TOKENS:
		if stem.ends_with(token) and stem.length() > token.length():
			return stem.substr(0, stem.length() - token.length())
	return stem


static func _split_slot(stem: String) -> Dictionary:
	var bare := _strip_rank(stem)
	for word in _SLOT_WORDS:
		var slot_word := str(word)
		var mark := "_" + slot_word
		if bare.ends_with(mark) and bare.length() > mark.length():
			return {"suffix": slot_word, "name": bare.substr(0, bare.length() - mark.length())}
	return {"suffix": "", "name": bare}


static func _empty_slot_of(stem: String) -> String:
	var bare := _strip_rank(stem)
	if not bare.begins_with("empty_"):
		return ""
	var rest := bare.substr(6)
	if _SLOT_WORDS.has(rest):
		return rest
	return ""


static func _skip_untyped(path: String, stem: String) -> bool:
	if _empty_slot_of(stem) != "" or str(_split_slot(stem)["suffix"]) != "":
		return false
	var lower := path.to_lower()
	if lower.find("/kickers/") >= 0 or lower.find("/field/") >= 0 or lower.find("/shop/") >= 0 or lower.find("/ui/") >= 0 or lower.find("/vitamins/") >= 0:
		return true
	if stem.begins_with("big_bruce") or stem.begins_with("walk_on"):
		return true
	if stem == "kick_meter" or stem == "meter" or stem == "power_accuracy_meter" or stem == "vitamin_shop" or stem == "football" or stem == "crowd":
		return true
	return false


static func _match_ids(ids: Array, token: String) -> String:
	var want := _normalize_stem(token)
	if want == "":
		return ""
	for id in ids:
		for alias in _aliases(str(id)):
			if alias == want:
				return str(id)
	return ""


static func _aliases(id: String) -> Array:
	var full := _normalize_stem(piece_name(id))
	var aliases: Array = [full]
	for word in _SLOT_WORDS:
		var slot_word := str(word)
		var mark := "_" + slot_word
		if full.ends_with(mark):
			aliases.append(full.substr(0, full.length() - mark.length()))
	if id == HIGH_AIR:
		aliases.append("highair")
	if id == DRIVE_LID:
		aliases.append("drivelid")
		aliases.append("drive_lid_helmet")
	if id == TWO_MINUTE:
		aliases.append("two_minute")
		aliases.append("twominute")
	if id == SHANKY:
		aliases.append("shanky")
	return aliases


# Equipment shows I–VI. Perks show I–III. Curses and empty slots show nothing.
static func rank_badge(id: String, rank: int) -> String:
	if id == "" or rank <= 0:
		return ""
	if CURSE_IDS.has(id):
		return ""
	return rank_label(rank)
