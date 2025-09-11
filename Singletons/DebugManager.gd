# res://Singletons/DebugManager.gd
extends Node

@export_group("Log Categories")
@export var show_interaction_logs: bool = false
@export var show_player_state_logs: bool = false
<<<<<<< Updated upstream
@export var show_game_state_logs: bool = false # NEW CATEGORY
=======
@export var show_game_state_logs: bool = false
@export var show_checkpoint_logs: bool = false
@export var show_persistence_logs: bool = false

@export_group("File Logging")
@export var enable_file_logging: bool = true

@export_group("Camera Logs")
@export var show_camera_logs_horizontal: bool = false
@export var show_camera_logs_vertical: bool = false
@export var show_camera_ledge_peek_logs: bool = false
>>>>>>> Stashed changes

enum Category {
	INTERACTION,
	PLAYER_STATE,
<<<<<<< Updated upstream
	GAME_STATE # NEW CATEGORY
=======
	GAME_STATE,
	CHECKPOINT,
	PERSISTENCE
>>>>>>> Stashed changes
}

const LOG_FILE_PATH = "user://game_log.txt"
var _log_file: FileAccess

func _ready() -> void:
	if enable_file_logging:
		_log_file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
		if _log_file:
			var time = Time.get_datetime_string_from_system()
			_log_file.store_line("--- Log Session Started: " + time + " ---")
		else:
			push_error("Failed to open log file at: " + LOG_FILE_PATH)

func _exit_tree() -> void:
	if _log_file:
		_log_file.store_line("--- Log Session Ended ---")
		_log_file.close()

static func log(category: Category, message: String) -> void:
	if not Engine.has_singleton("DebugManager"):
		return

	var instance = Engine.get_singleton("DebugManager")
	if not is_instance_valid(instance): return

	var should_log: bool = false
	var category_name: String = Category.keys()[category]

	match category:
		Category.INTERACTION:
			should_log = instance.show_interaction_logs
		Category.PLAYER_STATE:
			should_log = instance.show_player_state_logs
		Category.GAME_STATE: # NEW CATEGORY
			should_log = instance.show_game_state_logs
<<<<<<< Updated upstream

	if should_log:
		print("[QA LOG]: ", message)
=======
		Category.CHECKPOINT:
			should_log = instance.show_checkpoint_logs
		Category.PERSISTENCE:
			should_log = instance.show_persistence_logs

	if should_log:
		var log_message = "[%s]: %s" % [category_name, message]
		print(log_message)
		
		if instance.enable_file_logging and instance._log_file:
			var time_str = Time.get_time_string_from_system()
			instance._log_file.store_line("[%s] %s" % [time_str, log_message])


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
>>>>>>> Stashed changes
