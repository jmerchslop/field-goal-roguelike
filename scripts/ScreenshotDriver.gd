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
	if not await _capture("run_kick1.png"):
		get_tree().quit(1)
		return
	_play_straight_make(80.0)
	board.settle_kick()
	if not await _capture("run_make_result.png"):
		get_tree().quit(1)
		return
	# Two more makes, then kick 4, which is a hash spot.
	board.advance_run()
	board.script_good_kick()
	board.advance_run()
	board.script_good_kick()
	board.force_spot_side(1)
	board.advance_run()
	if not await _capture("run_kick4_hash.png"):
		get_tree().quit(1)
		return
	board.script_good_kick()
	board.force_spot_side(-1)
	board.advance_run()
	if not await _capture("run_boss_kick_clear.png"):
		get_tree().quit(1)
		return
	board.restart_run()
	_play_straight_make(20.0)
	board.settle_kick()
	if not await _capture("run_game_over.png"):
		get_tree().quit(1)
		return
	get_tree().quit()


func _play_straight_make(power_value: float) -> void:
	board.play_locked_kick(power_value)


func _capture(file_name: String) -> bool:
	board.queue_redraw()
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
