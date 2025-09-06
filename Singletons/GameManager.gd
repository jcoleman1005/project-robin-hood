extends Node
signal resources_updated
var gold: int = 0
var villagers: int = 0
var archers: int = 0
var is_gameplay_active: bool = true

var mission_objective_complete: bool = false

const SAVE_FILE_PATH = "user://savegame.json"

func _ready() -> void:
	load_game()
	# The GameManager now subscribes to events it cares about.
	EventBus.gold_collected.connect(_on_gold_collected)
	EventBus.villager_rescued.connect(_on_villager_rescued)
	EventBus.train_archer_requested.connect(_on_train_archer_requested)
	EventBus.mission_started.connect(_on_mission_started)
	EventBus.mission_objective_completed.connect(_on_mission_objective_completed)
	EventBus.player_detected.connect(_on_player_detected)
	EventBus.pause_toggled.connect(_on_pause_toggled)
	EventBus.player_died.connect(_on_player_died)
# --- Event Handlers ---

func _on_gold_collected(amount: int) -> void:
	gold += amount
	print("Player received " + str(amount) + " gold. Total gold: " + str(gold))
	save_game()

func _on_villager_rescued() -> void:
	villagers += 1
	mission_objective_complete = true # Set the objective flag
	print("Villager rescued! Total villagers: " + str(villagers))
	save_game()

func _on_train_archer_requested() -> void:
	if gold >= 10 and villagers > 0:
		gold -= 10
		villagers -= 1
		archers += 1
		save_game()
		print("Archer trained!")
	else:
		print("Cannot train archer. Not enough resources.")

func _on_mission_started() -> void:
	mission_objective_complete = false

func _on_mission_objective_completed() -> void:
	# When the player exits a level, we confirm the mission is a success.
	# The UIManager will listen for this to show the success screen.
	EventBus.mission_succeeded.emit()

func _on_player_detected() -> void:
	# When the player is detected, we confirm the mission has failed.
	# The UIManager will listen for this to show the failure screen.
	EventBus.mission_failed.emit()

func _on_pause_toggled(is_paused: bool) -> void:
	get_tree().paused = is_paused
	is_gameplay_active = not is_paused
	print("Game Paused: ", is_paused)

func reset_game_data() -> void:
	gold = 0
	villagers = 0
	archers = 0
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	resources_updated.emit()

# --- Save/Load System ---

func save_game():
	var save_data = {
		"gold": gold,
		"villagers": villagers,
		"archers": archers
	}
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	print("Game saved!")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("DEBUG: GameManager - No save file found.") #<-- ADD THIS
		return
		
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	
	if data:
		gold = data.get("gold", 0)
		villagers = data.get("villagers", 0)
		archers = data.get("archers", 0)
		print("DEBUG: GameManager - load_game() called. Villagers loaded as ", villagers) #<-- ADD THIS
		resources_updated.emit()
	else:
		print("DEBUG: GameManager - Error loading save file.") #<-- ADD THIS
func _on_player_died() -> void:
	# For now, we'll just reload the current scene.
	# This effectively respawns the player at the start of the level.
	get_tree().reload_current_scene()
