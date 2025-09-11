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
signal checkpoint_set(position: Vector2)

# --- UI & Game Flow ---
signal pause_toggled
signal pause_menu_requested
signal interaction_started # Player has pressed the button
signal interaction_cancelled # Player has released the button
signal interaction_succeeded # InteractionManager confirms the hold was completed
signal interaction_progress_updated(progress: float) # InteractionManager broadcasts hold progress
signal show_dialogue(message: String)
signal return_to_hideout_requested
signal start_mission_requested(mission_key: String)
signal new_game_requested
signal continue_game_requested
