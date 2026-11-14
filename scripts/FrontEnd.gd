class_name FrontEnd
extends RefCounted

# Title, four-tile menu, options focus, and where Trophy Room returns.
# The 20-kick season is unchanged. Endless overtime is not implemented.

enum Screen { TITLE, MAIN, SELECT, OPTIONS, RECORDS, PLAY }

const MENU_IDS: Array[String] = ["standard", "endless", "trophy", "options"]
const LOCK_TEXT := "Beat Standard mode to unlock"
const USED_TEXT := "Already used"

var screen: Screen = Screen.TITLE
var menu_index := 0
var run_mode := "standard"
var records_return: Screen = Screen.MAIN
var lock_message := ""
var lock_left := 0.0
var notice := ""
var notice_left := 0.0
var focus := 0
var rebinding := ""
var dragging := ""
var gate := ""
var gate_index := 0
var came_from_gate := false

const PAUSE_WORD := "PAUSE"
const RESUME_WORD := "RESUME"
const SAVE_QUIT_WORD := "SAVE AND QUIT"
const GATE_CONTINUE := "CONTINUE"
const GATE_NEW := "NEW RUN"
const GATE_REPLACE_STANDARD := "THIS REPLACES THE SAVED STANDARD RUN"
const GATE_REPLACE_ENDLESS := "THIS REPLACES THE SAVED ENDLESS RUN"
const GATE_START := "START NEW RUN"
const GATE_KEEP := "KEEP SAVED RUN"


func tick(delta: float) -> void:
	if lock_left > 0.0:
		lock_left = maxf(lock_left - delta, 0.0)
		if lock_left <= 0.0:
			lock_message = ""
	if notice_left > 0.0:
		notice_left = maxf(notice_left - delta, 0.0)
		if notice_left <= 0.0:
			notice = ""


func endless_unlocked() -> bool:
	var data = _records()
	if data == null:
		return false
	return int(data.wins) >= 1 or bool(data.has_trophy("season_complete"))


func confirm_title() -> void:
	screen = Screen.MAIN
	menu_index = 0
	lock_message = ""
	lock_left = 0.0


func back_title() -> void:
	pass


func move_menu(step: int) -> void:
	if step == 0:
		return
	menu_index = posmod(menu_index + step, MENU_IDS.size())


func hover_menu(index: int) -> void:
	if index >= 0 and index < MENU_IDS.size():
		menu_index = index


func confirm_menu() -> String:
	var id := MENU_IDS[menu_index]
	if id == "standard":
		run_mode = "standard"
		screen = Screen.SELECT
		return "select"
	if id == "endless":
		if not endless_unlocked():
			lock_message = LOCK_TEXT
			lock_left = 2.0
			return "locked"
		run_mode = "endless"
		screen = Screen.SELECT
		return "select"
	if id == "trophy":
		records_return = Screen.MAIN
		screen = Screen.RECORDS
		return "records"
	screen = Screen.OPTIONS
	focus = 0
	rebinding = ""
	dragging = ""
	notice = ""
	return "options"


func back_main() -> void:
	screen = Screen.TITLE
	lock_message = ""


func back_select() -> void:
	screen = Screen.MAIN
	menu_index = 0


func open_records(from_screen: Screen) -> void:
	records_return = from_screen
	screen = Screen.RECORDS


func back_records() -> void:
	screen = records_return


func back_options() -> void:
	rebinding = ""
	dragging = ""
	screen = Screen.MAIN


func focus_count() -> int:
	return 3 + _rows().size() + 2


func focus_kind(index: int) -> String:
	if index < 3:
		return "slider"
	if index < 3 + _rows().size():
		return "bind"
	if index == focus_count() - 2:
		return "reset"
	return "back"


func slider_id(index: int) -> String:
	if index == 0:
		return "music"
	if index == 1:
		return "crowd"
	return "sfx"


func bind_row(index: int) -> Dictionary:
	return _rows()[index - 3]


func move_focus(direction: Vector2) -> void:
	if rebinding != "":
		return
	var here := _focus_point(focus)
	var best := focus
	var best_score := 1000000.0
	for index in focus_count():
		if index == focus:
			continue
		var there := _focus_point(index)
		var delta := there - here
		if direction.x != 0.0:
			if direction.x * delta.x <= 12.0:
				continue
			if absf(delta.y) > absf(delta.x) + 36.0:
				continue
		elif direction.y != 0.0:
			if direction.y * delta.y <= 8.0:
				continue
			if absf(delta.x) > 180.0:
				continue
		else:
			continue
		var score := absf(delta.x) + absf(delta.y) * 1.4
		if score < best_score:
			best_score = score
			best = index
	focus = best


func nudge_slider(step: int) -> bool:
	if focus_kind(focus) != "slider":
		return false
	var which := slider_id(focus)
	var options = _options()
	options.set_volume(which, int(options.volume_of(which)) + step * 5)
	return true


func begin_rebind() -> void:
	if focus_kind(focus) != "bind":
		return
	rebinding = str(bind_row(focus)["id"])
	notice = ""


func cancel_rebind() -> void:
	rebinding = ""


func finish_rebind(code: int) -> String:
	if rebinding == "":
		return ""
	var result := str(_options().try_rebind(rebinding, code))
	rebinding = ""
	if result == "used" or result == "reserved":
		notice = USED_TEXT
		notice_left = 2.0
		return "used"
	notice = ""
	return result


func activate_focus() -> String:
	var kind := focus_kind(focus)
	if kind == "bind":
		begin_rebind()
		return "rebind"
	if kind == "reset":
		_options().reset_controls()
		notice = ""
		return "reset"
	if kind == "back":
		back_options()
		return "back"
	return kind


func _focus_point(index: int) -> Vector2:
	if index < 3:
		return MenuLayout.SLIDERS[index].get_center()
	if index < 3 + _rows().size():
		var row: Dictionary = _rows()[index - 3]
		return MenuLayout.bind_rect(int(row["column"]), int(row["row"])).get_center()
	if index == focus_count() - 2:
		return MenuLayout.RESET_BUTTON.get_center()
	return MenuLayout.BACK_BUTTON.get_center()


func _records():
	var loop := Engine.get_main_loop()
	if loop == null:
		return null
	return loop.root.get_node_or_null("SaveData")


func _options():
	var loop := Engine.get_main_loop()
	if loop == null:
		return null
	return loop.root.get_node_or_null("Settings")


func _rows() -> Array:
	var options = _options()
	if options == null:
		return []
	return options.ACTION_ROWS
