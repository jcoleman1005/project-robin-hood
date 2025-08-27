extends Node

# These variables will be accessible from anywhere in your game.
var gold: int = 0
var villagers: int = 0
var archers: int = 0

# The path to our save file.
const SAVE_FILE_PATH = "user://savegame.json"

func _ready():
	# When the game starts, automatically load any saved progress.
	load_game()

## This function saves the current game state to a file.
func save_game():
	# Create a dictionary to hold all the data we want to save.
	var save_data = {
		"gold": gold,
		"villagers": villagers,
		"archers": archers
	}
	
	# Open the save file in write mode.
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	
	# Convert the dictionary to a JSON string.
	var json_string = JSON.stringify(save_data)
	
	# Write the JSON string to the file.
	file.store_string(json_string)
	
	print("Game saved!")

## This function loads the game state from a file.
func load_game():
	# First, check if the save file actually exists.
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return # Do nothing if there's no save file.
		
	# Open the save file in read mode.
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	
	# Read the entire file as text.
	var content = file.get_as_text()
	
	# Parse the JSON string back into a Godot dictionary.
	var data = JSON.parse_string(content)
	
	# Check if the data is valid.
	if data:
		# Update our variables with the loaded data.
		gold = data.get("gold", 0)
		villagers = data.get("villagers", 0)
		archers = data.get("archers", 0)
		print("Game loaded successfully!")
	else:
		print("Error loading save file. Data might be corrupted.")
