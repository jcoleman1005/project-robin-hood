# res://Singletons/DebugManager.gd
extends Node

@export_group("Log Categories")
@export var show_interaction_logs: bool = false
@export var show_player_state_logs: bool = false
@export var show_player_physics_logs: bool = false
@export var show_game_state_logs: bool = false
@export var show_checkpoint_logs: bool = false

@export_group("Camera Logs")
@export var show_camera_logs_horizontal: bool = false
@export var show_camera_logs_vertical: bool = false
@export var show_camera_ledge_peek_logs: bool = false


enum Category {
	INTERACTION,
	PLAYER_STATE,
	PLAYER_PHYSICS,
	GAME_STATE,
	CHECKPOINT
}

# The "static" keyword has been removed. This is now an instance method,
# just like the camera log functions.
func log(category: Category, message: String) -> void:
	# We no longer need to fetch the instance from the Engine. Since this is an
	# instance method, we can directly access our own exported variables.
	var should_log: bool = false
	match category:
		Category.INTERACTION:
			should_log = show_interaction_logs
		Category.PLAYER_STATE:
			should_log = show_player_state_logs
		Category.PLAYER_PHYSICS:
			should_log = show_player_physics_logs
		Category.GAME_STATE:
			should_log = show_game_state_logs
		Category.CHECKPOINT:
			should_log = show_checkpoint_logs

	if should_log:
		print("[QA LOG]: ", message)


func print_camera_log(player_x: float, target_x: float, diff: float, deadzone: float):
	if show_camera_logs_horizontal:
		var log_message = "PlayerX: %.1f | TargetX: %.1f | DiffX: %.1f | DeadzoneX: %.1f" % [player_x, target_x, diff, deadzone]
		print("[QA LOG | CAMERA H]: ", log_message)


func print_camera_log_vertical(player_y: float, target_y: float, diff: float, deadzone: float):
	if show_camera_logs_vertical:
		var log_message = "PlayerY: %.1f | TargetY: %.1f | DiffY: %.1f | DeadzoneY: %.1f" % [player_y, target_y, diff, deadzone]
		print("[QA LOG | CAMERA V]: ", log_message)


func print_ledge_peek_log(is_peeking: bool, reason: String):
	if show_camera_ledge_peek_logs:
		print("[QA LOG | LEDGE PEEK]: Peeking is %s. Reason: %s" % [is_peeking, reason])
