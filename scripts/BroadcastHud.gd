class_name BroadcastHud
extends RefCounted

# Glyph-safe copy for the in-kick broadcast bugs. Pixel Gothic has no
# dollar sign, degree mark, hash, hyphen, colon, or times sign.

const FORBIDDEN := "$°#-:&!?×%,"


static func is_safe(text: String) -> bool:
	for i in text.length():
		if FORBIDDEN.contains(text.substr(i, 1)):
			return false
	return true


static func kick_title(number: int, endless: bool) -> String:
	if endless:
		return "KICK %d" % number
	return "KICK %d OF 20" % number


static func yards_text(distance: float) -> String:
	return "%s YD" % KickLogic.format_number(distance)


static func aim_text(degrees: float) -> String:
	var tenths := int(roundf(KickLogic.round_tenth(degrees) * 10.0))
	if tenths == 0:
		return "AIM 0.0"
	var side := "R" if tenths > 0 else "L"
	tenths = absi(tenths)
	return "AIM %s %d.%d" % [side, int(tenths / 10), tenths % 10]


static func wind_band(speed: int, show_mph: bool) -> String:
	if speed <= 0 or not show_mph:
		return "WIND " + RunLogic.wind_name(speed).to_upper()
	return "WIND %d" % speed


static func wind_detail(speed: int, direction: float) -> String:
	var cross := KickLogic.crosswind_mph(float(speed), direction)
	var along := KickLogic.head_tail_mph(float(speed), direction)
	return "%s  %s" % [_cross_text(cross), _along_text(along)]


static func _cross_text(mph: float) -> String:
	var whole := int(roundf(absf(mph)))
	if whole <= 0:
		return "CROSS 0"
	# Positive crosswind adds yards to the right of the posts.
	if mph > 0.0:
		return "CROSS R %d" % whole
	return "CROSS L %d" % whole


static func _along_text(mph: float) -> String:
	var whole := int(roundf(absf(mph)))
	if whole <= 0:
		return "TAIL 0"
	# Positive head/tail is a helping tailwind.
	if mph > 0.0:
		return "TAIL %d" % whole
	return "HEAD %d" % whole


static func plate_name(kicker_id: String) -> String:
	match kicker_id:
		Kickers.BIG_BRUCE:
			return "BIG BRUCE"
		Kickers.WALK_ON:
			return "THE WALK ON"
		Kickers.PHIL:
			return "PHIL THE PHARMACIST"
		Kickers.GARY:
			return "GARY THE GOAT"
		Kickers.VEX:
			return "VEX"
		Kickers.COLE:
			return "COLE LANG"
		Kickers.WILLOW:
			return "WILLOW REED"
		Kickers.CARLOS:
			return "CARLOS HERNANDEZ"
	return ""


static func plate_number(kicker_id: String) -> String:
	if kicker_id == Kickers.BIG_BRUCE:
		return "NO.55"
	if kicker_id == Kickers.WALK_ON:
		return "NO.4"
	return ""


static func kit_text(kicker_id: String) -> String:
	match kicker_id:
		Kickers.BIG_BRUCE:
			return "FARM STRENGTH"
		Kickers.WALK_ON:
			return "EARNS HIS SPOT"
		Kickers.PHIL:
			return "HOUSE ACCOUNT"
		Kickers.GARY:
			return "GOOD AS GOLD"
		Kickers.VEX:
			return "INFINITE RANGE AND BEYOND"
		Kickers.COLE:
			return "BRAND DEAL"
		Kickers.WILLOW:
			return "SYNCHRONICITY"
		Kickers.CARLOS:
			return "NUMERO DOS"
	return ""


static func ball_text(kicker_id: String) -> String:
	match kicker_id:
		Kickers.BIG_BRUCE:
			return "THE FARM BALL"
		Kickers.WALK_ON:
			return "TEAM ISSUE"
		Kickers.PHIL:
			return "THE GELCAP"
		Kickers.GARY:
			return "LUCKY BALL"
		Kickers.VEX:
			return "THE FLYING SAUCER"
		Kickers.COLE:
			return "SHOWTIME"
		Kickers.WILLOW:
			return "THE CHILL BALL"
		Kickers.CARLOS:
			return "THE NOT SO SECRET WEAPON"
	return ""


static func max_warning(required: float, max_range: float) -> bool:
	return max_range + 0.001 < required


static func max_fill(required: float, max_range: float) -> float:
	if max_range <= 0.001:
		return 1.0
	return clampf(required / max_range, 0.0, 1.0)


static func payout_text(popup: String) -> String:
	if popup == "":
		return ""
	var digits := ""
	for i in popup.length():
		var ch := popup.substr(i, 1)
		if ch >= "0" and ch <= "9":
			digits += ch
	if digits == "":
		return ""
	return "+" + digits


static func belt_note(note: String) -> String:
	var text := note.to_upper().replace("-", " ").replace("?", "").replace("!", "")
	return text.strip_edges()


static func hint_text(phase: int, endless_restart: bool, can_practice: bool, practicing: bool, aim_left: String, aim_right: String, confirm: String) -> String:
	if endless_restart:
		return ""
	var line := ""
	if phase == KickLogic.Phase.AIMING:
		line = "HOLD %s OR %s TO AIM. %s STARTS THE METER." % [_key(aim_left), _key(aim_right), _key(confirm)]
		if can_practice:
			line += " P PRACTICE"
		elif practicing:
			line += " PRACTICE SWING"
	elif phase == KickLogic.Phase.POWER:
		line = "%s LOCKS POWER." % _key(confirm)
	elif phase == KickLogic.Phase.ACCURACY:
		line = "%s LOCKS ACCURACY." % _key(confirm)
	elif phase == KickLogic.Phase.RESULT:
		line = "%s CONTINUES." % _key(confirm)
	return line


static func _key(label: String) -> String:
	var text := label.to_upper().replace("-", " ").replace("?", "")
	if text == "":
		return "KEY"
	return text


static func head_path(kicker_id: String) -> String:
	match kicker_id:
		Kickers.BIG_BRUCE:
			return "res://art/hud/heads/big_bruce.png"
		Kickers.WALK_ON:
			return "res://art/hud/heads/walk_on.png"
		Kickers.PHIL:
			return "res://art/hud/heads/pharmacist.png"
		Kickers.GARY:
			return "res://art/hud/heads/gary.png"
		Kickers.VEX:
			return "res://art/hud/heads/vex.png"
		Kickers.COLE:
			return "res://art/hud/heads/cole.png"
		Kickers.WILLOW:
			return "res://art/hud/heads/willow.png"
		Kickers.CARLOS:
			return "res://art/hud/heads/carlos.png"
	return ""
