# res://Singletons/EventBus.gd
extends Node

# --- Player & Resources ---
signal gold_collected(amount: int)
signal villager_rescued
signal train_archer_requested
signal sound_created(position: Vector2, range: float)
signal flow_combo_success

# --- Mission State ---
signal mission_started
signal mission_objective_completed
signal mission_succeeded
signal mission_failed
signal player_detected
signal player_died

# --- UI & Game Flow ---
signal pause_toggled
signal pause_menu_requested
signal interact_pressed # Restored
signal show_dialogue(message: String)
signal return_to_hideout_requested
signal start_mission_requested(mission_key: String)
signal new_game_requested
signal continue_game_requested
