class_name KickConstants
extends RefCounted

# Every number the kick and the drawing use lives here.
# Change a rule by editing this file, not the other scripts.

# --- The screen ----------------------------------------------------------------
# 7 pixels per yard, so a later 75 yard kick still fits in a 720 px tall window.
const PIXELS_PER_YARD := 7.0
const WINDOW_WIDTH := 1280.0
const WINDOW_HEIGHT := 720.0

# The posts sit near the top. The ball starts KICK_DISTANCE_YARDS below them.
const UPRIGHT_Y_PX := 60.0
const KICK_DISTANCE_YARDS := 35.0

# The posts are drawn this far apart. The make/miss test uses 3.08, which is
# the number in the rules (half of 6.16). 6.17 / 2 is 3.085, so the drawn posts
# are a hair wider than the scoring width. Both numbers are kept on purpose.
const POST_SEPARATION_YARDS := 6.17
const POST_HALF_GAP_YARDS := 3.08
const DOINK_BAND_YARDS := 0.15

# --- Aim -----------------------------------------------------------------------
# Negative degrees point to screen-left. Holding Left moves toward -12.
# Holding Right moves toward +12.
const AIM_SPEED_DEG_PER_SEC := 10.0
const AIM_MIN_DEG := -12.0
const AIM_MAX_DEG := 12.0

# --- The meter -----------------------------------------------------------------
const METER_MIN := -15.0
const METER_MAX := 100.0
const POWER_RISE_PER_SEC := 100.0
const ACCURACY_FALL_PER_SEC := 120.0
const PERFECT_BAND := 2.0
const METER_INNER_BAND := 8.0
const RED_TIP_START := 95.0

# If power lands in the red tip, add a random amount in this range to e.
const RED_TIP_ERROR_MIN := -5.0
const RED_TIP_ERROR_MAX := 5.0

# Each point of e is worth this many degrees.
# Positive e hooks left. Left is a negative angle, so the kick uses -(e × this).
const ACCURACY_DEG_PER_ERROR := 0.35

# Max range = 16 + 0.67 × power. Full power is about 83 yards.
const RANGE_BASE_YARDS := 16.0
const RANGE_PER_POWER := 0.67

# Flight time = 1.2 + 0.02 × distance. "Distance" is the kick distance.
const FLIGHT_TIME_BASE_SEC := 1.2
const FLIGHT_TIME_PER_YARD := 0.02

# --- The run --------------------------------------------------------------------
# You start with 1 attempt. The cap starts at 3 and is never allowed past 5.
# Nothing in this build changes the cap. It stays at 3.
const ATTEMPTS_START := 1
const ATTEMPT_CAP := 3
const ATTEMPT_CAP_MAX := 5

# Hash spots are 3 yards off center. Wide spots are 6 yards off center.
const HASH_OFFSET_YARDS := 3.0
const WIDE_OFFSET_YARDS := 6.0

# Score: distance × (1 + 0.25 × streak before this kick).
# Then ×2 inside 1 yard of the middle, ×1.5 on a boss kick, +5 if perfect.
const STREAK_MULT_STEP := 0.25
const MIDDLE_YARDS := 1.0
const MIDDLE_MULTIPLIER := 2.0
const BOSS_MULTIPLIER := 1.5
const PERFECT_BONUS := 5

# From kick 11 on, a first-try make earns an attempt only if this is true
# and the kick was perfect or down the middle. It starts false.
const LATE_EARN_RULE := false
const LATE_EARN_FROM_KICK := 11

# --- Drawing sizes -------------------------------------------------------------
const BALL_RADIUS_PX := 11.0
const SHADOW_RADIUS_PX := 13.0
const BALL_LIFT_PX := 52.0
const AIM_ARROW_YARDS := 14.0
const ARROW_WIDTH_PX := 4.0
const ARROW_HEAD_PX := 16.0
const POST_WIDTH_PX := 8.0
const POST_HEIGHT_PX := 52.0
const CROSSBAR_WIDTH_PX := 3.0

const METER_PANEL_LEFT := 1096.0
const METER_PANEL_TOP := 36.0
const METER_PANEL_RIGHT := 1264.0
const METER_PANEL_BOTTOM := 684.0
const METER_BAR_LEFT := 1172.0
const METER_BAR_RIGHT := 1212.0
const METER_BAR_TOP := 92.0
const METER_BAR_BOTTOM := 640.0

const RESULT_LEFT := 160.0
const RESULT_TOP := 360.0
const RESULT_WIDTH := 800.0
const RESULT_HEIGHT := 300.0
const ATTEMPT_PIP_RADIUS := 7.0
const ATTEMPT_PIP_GAP := 22.0

# --- Colors --------------------------------------------------------------------
const COLOR_FIELD := Color(0.18, 0.55, 0.24)
const COLOR_ENDZONE := Color(0.11, 0.38, 0.16)
const COLOR_GOAL_LINE := Color(0.9, 0.95, 0.9, 0.55)
const COLOR_POST := Color(0.98, 0.86, 0.16)
const COLOR_BALL := Color(0.58, 0.33, 0.14)
const COLOR_BALL_EDGE := Color(0.28, 0.14, 0.05)
const COLOR_SHADOW := Color(0.01, 0.03, 0.01, 0.62)
const COLOR_ARROW := Color(0.98, 0.98, 0.94)
const COLOR_ARROW_EDGE := Color(0.02, 0.02, 0.02, 0.75)
const COLOR_METER_PANEL := Color(0.05, 0.07, 0.06, 0.94)
const COLOR_METER_TRACK := Color(0.14, 0.16, 0.15, 1)
const COLOR_INNER_BAND := Color(0.78, 0.84, 0.92, 0.55)
const COLOR_PERFECT_BAND := Color(0.65, 1.0, 0.72, 0.85)
const COLOR_ZERO := Color(0.2, 0.95, 0.35)
const COLOR_RED_TIP := Color(0.92, 0.16, 0.12, 0.95)
const COLOR_NEEDLE := Color(1, 1, 1)
const COLOR_TEXT := Color(0.97, 0.98, 0.95)
const COLOR_GOOD := Color(0.62, 1.0, 0.55)
const COLOR_MISS := Color(1.0, 0.58, 0.42)
const COLOR_PERFECT_TEXT := Color(1.0, 0.92, 0.38)
const COLOR_RESULT_SCRIM := Color(0, 0, 0, 0.6)
const COLOR_BOSS := Color(0.95, 0.22, 0.16)
const COLOR_ATTEMPT := Color(1.0, 0.86, 0.35)


static func screen_pos(kick_distance: float, forward_yards: float, lateral_yards: float) -> Vector2:
	# Negative lateral yards are screen-left.
	# Forward yards move from the ball up toward the posts.
	var x := WINDOW_WIDTH * 0.5 + lateral_yards * PIXELS_PER_YARD
	var y := UPRIGHT_Y_PX + (kick_distance - forward_yards) * PIXELS_PER_YARD
	return Vector2(x, y)


static func meter_y(value: float) -> float:
	# 100 is the top of the bar. -15 is the bottom. The needle rises upward.
	var height := METER_BAR_BOTTOM - METER_BAR_TOP
	var span := METER_MAX - METER_MIN
	var t := (value - METER_MIN) / span
	return METER_BAR_BOTTOM - t * height
