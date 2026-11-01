extends Node

# Saves pictures of this same game. main.gd only adds this node when FG_SHOTS=1.

var board
var shot_dir := "/opt/cursor/artifacts"


func _ready() -> void:
	var made := DirAccess.make_dir_recursive_absolute(shot_dir)
	if made != OK and made != ERR_ALREADY_EXISTS:
		print("Could not create ", shot_dir)
		get_tree().quit(1)
		return
	if not await _capture("view_rest.png"):
		get_tree().quit(1)
		return
	board.logic.press_space()
	board.logic.advance(0.42)
	board._approach_time = 0.42
	if not await _capture("view_runup.png"):
		get_tree().quit(1)
		return
	board.load_current_kick()
	board.logic.press_space()
	board.logic.advance(0.8)
	board.logic.press_space()
	board.logic.advance(0.8 / KickConstants.ACCURACY_FALL_PER_SEC * KickConstants.POWER_RISE_PER_SEC)
	board.logic.press_space()
	board.logic.advance(board.logic.flight_duration * 0.58)
	board._approach_time = 0.8
	if not await _capture("view_flight.png"):
		get_tree().quit(1)
		return
	board.logic.advance(board.logic.flight_duration)
	board.run.resolve_kick(board.logic.result_text, board.logic.offset_yards, board.logic.perfect)
	if not await _capture("view_result.png"):
		get_tree().quit(1)
		return
	while board.run.kick_number < 10:
		board.advance_run()
		board.script_good_kick()
	board.force_spot_side(1)
	board.advance_run()
	if not await _capture("view_wide.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	board.run.resolve_kick("GOOD", 0.0, true)
	board.run.force_offer(["deep_bench", "big_leg", "steady_plant"])
	board.run.roll_offer()
	if not await _capture("offer_cards.png"):
		get_tree().quit(1)
		return
	board.run.pick_card(0)
	board.advance_run()
	if not await _capture("hud_upgrades.png"):
		get_tree().quit(1)
		return
	board.run.grant("sweet_spot")
	if not await _capture("sweet_spot_meter.png"):
		get_tree().quit(1)
		return
	board.run.grant("mulligan")
	board.run.begin_mulligan("WIDE LEFT", -4.0, false)
	if not await _capture("mulligan_prompt.png"):
		get_tree().quit(1)
		return
	get_tree().quit()


func _capture(file_name: String) -> bool:
	board.refresh_view()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = board.get_viewport().get_texture().get_image()
	var path := shot_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		print("FAILED to save ", path, " error ", err)
		return false
	print("Saved ", path, " ", image.get_width(), "x", image.get_height())
	return true
