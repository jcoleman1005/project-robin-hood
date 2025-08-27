extends CanvasLayer

# --- Node References ---
@onready var resume_button = $MarginContainer/VBoxContainer/ResumeButton
@onready var quit_button = $MarginContainer/VBoxContainer/QuitButton
@onready var background = $Background

func _ready():
	# The pause menu should be hidden when the game starts.
	hide()
	# Ensure the game is not paused when the level loads.
	get_tree().paused = false

## This is the fix! We now check for input directly in the _process function.
## This is the most reliable way to catch a global input like "pause".
func _process(_delta):
	# Check if the "pause" action was just pressed.
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

# This function handles showing/hiding the menu and pausing/unpausing the game.
func toggle_pause():
	# Flip the paused state of the entire scene tree.
	get_tree().paused = not get_tree().paused
	
	if get_tree().paused:
		# If the game is now paused, show the menu.
		show()
	else:
		# If the game is now unpaused, hide the menu.
		hide()

# This function is called when the "Resume" button is pressed.
func _on_resume_button_pressed():
	# Simply unpause the game, which will also hide the menu.
	toggle_pause()

# This function is called when the "Quit to Hideout" button is pressed.
func _on_quit_button_pressed():
	# It's important to unpause the game *before* changing scenes.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/hideout.tscn")
