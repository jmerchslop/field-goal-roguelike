extends Node

# Takes three pictures of this same game: the opening view, the ball in the air,
# and the result. main.gd only adds this node when FG_SHOTS=1.

var board: Node2D
var logic: KickLogic
var shot_dir := "/opt/cursor/artifacts"


func _ready() -> void:
	var made := DirAccess.make_dir_recursive_absolute(shot_dir)
	if made != OK and made != ERR_ALREADY_EXISTS:
		print("Could not create ", shot_dir)
		get_tree().quit(1)
		return
	if not await _capture("kick_start.png"):
		get_tree().quit(1)
		return
	# Power 80 stays out of the red tip. Accuracy 0 is a perfect, straight kick.
	logic.press_space()
	logic.advance(80.0 / KickConstants.POWER_RISE_PER_SEC)
	logic.press_space()
	logic.advance(80.0 / KickConstants.ACCURACY_FALL_PER_SEC)
	logic.press_space()
	logic.advance(logic.flight_duration * 0.5)
	if not await _capture("kick_midflight.png"):
		get_tree().quit(1)
		return
	logic.advance(logic.flight_duration)
	if not await _capture("kick_result.png"):
		get_tree().quit(1)
		return
	get_tree().quit()


func _capture(file_name: String) -> bool:
	board.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := board.get_viewport().get_texture().get_image()
	var path := shot_dir.path_join(file_name)
	var err := image.save_png(path)
	if err != OK:
		print("FAILED to save ", path, " error ", err)
		return false
	print("Saved ", path, " ", image.get_width(), "x", image.get_height())
	return true
