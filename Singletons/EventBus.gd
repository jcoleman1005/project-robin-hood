extends Node

# --- Player & Resources ---
signal gold_collected(amount: int)
signal villager_rescued
signal train_archer_requested
signal sound_created(position: Vector2, range: float)

# --- Mission State ---
signal mission_started
signal mission_objective_completed # e.g., Player has reached the exit zone
signal mission_succeeded # Final confirmation after tallying results
signal mission_failed
signal player_detected
signal player_died

# --- UI & Game Flow ---
signal pause_toggled
signal interact_pressed
signal show_dialogue(message: String)
# NEW SIGNALS FOR SCENE TRANSITIONS
signal return_to_hideout_requested
signal start_mission_requested(mission_key: String)
signal new_game_requested
signal continue_game_requested
