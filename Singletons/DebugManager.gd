# res://Singletons/DebugManager.gd
extends Node

@export_group("Log Toggles")
@export var show_interaction_logs: bool = false
@export var show_player_state_logs: bool = false
@export var show_player_physics_logs: bool = false
@export var show_game_state_logs: bool = false
@export var show_checkpoint_logs: bool = false
@export var show_combo_logs: bool = false
@export var show_proc_gen_logs: bool = false
@export var show_chunk_boundaries: bool = false
@export var show_scene_tree_on_load: bool = false ## NEW: Toggle to print a scene's children when it loads.
@export var show_camera_logs_horizontal: bool = false
@export var show_camera_logs_vertical: bool = false
@export var show_camera_ledge_peek_logs: bool = false

# --- Dedicated Debug Print Functions ---

# NEW: A function to print the children of a given scene node.
func print_scene_children(scene: Node) -> void:
	if show_scene_tree_on_load:
		print("--- [QA LOG | SCENE TREE]: Children of '", scene.name, "': ---")
		for child in scene.get_children():
			print(" - Child Node: '", child.name, "' of type: ", child.get_class())
		print("---------------------------------------------------------")

func print_interaction_log(message: String) -> void:
	if show_interaction_logs:
		print("[QA LOG | INTERACTION]: ", message)

func print_player_state_log(message: String) -> void:
	if show_player_state_logs:
		print("[QA LOG | PLAYER STATE]: ", message)

func print_game_state_log(message: String) -> void:
	if show_game_state_logs:
		print("[QA LOG | GAME STATE]: ", message)

func print_checkpoint_log(message: String) -> void:
	if show_checkpoint_logs:
		print("[QA LOG | CHECKPOINT]: ", message)

func print_proc_gen_log(message: String) -> void:
	if show_proc_gen_logs:
		print("[QA LOG | PROC GEN]: ", message)

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
