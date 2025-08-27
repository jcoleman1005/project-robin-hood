extends Control

# --- Node References ---
# We'll connect these in the editor.
@onready var new_game_button = $NewGameButton
@onready var continue_button = $ContinueButton

func _ready():
	# When the title screen loads, check if a save file exists.
	if FileAccess.file_exists(GameManager.SAVE_FILE_PATH):
		# If it exists, enable the "Continue" button.
		continue_button.disabled = false
	else:
		# If it doesn't exist, disable the "Continue" button.
		continue_button.disabled = true

## This function is called when the "New Game" button is pressed.
func _on_new_game_button_pressed():
	# Reset the GameManager to its default state for a new game.
	GameManager.gold = 0
	GameManager.villagers = 0
	GameManager.archers = 0
	
	# Go to the Hideout scene to start the game.
	get_tree().change_scene_to_file("res://Scenes/hideout.tscn")

## This function is called when the "Continue" button is pressed.
func _on_continue_button_pressed():
	# The GameManager automatically loads the save file when the game starts,
	# so we don't need to call load_game() here. We can just go to the Hideout.
	get_tree().change_scene_to_file("res://Scenes/hideout.tscn")
