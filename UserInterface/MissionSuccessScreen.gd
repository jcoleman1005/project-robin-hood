extends CanvasLayer

# --- Node References ---
@onready var gold_label = $MarginContainer/VBoxContainer/GoldLabel
@onready var villagers_label = $MarginContainer/VBoxContainer/VillagersLabel
@onready var return_button = $MarginContainer/VBoxContainer/ReturnButton

func _ready():
	# The screen should be hidden when the level starts.
	hide()

# This is a public function that the level script will call.
# It takes the rewards as arguments so it can display them.
func show_success_screen(gold_earned: int, villagers_rescued: int):
	# Update the labels with the rewards from the mission.
	gold_label.text = "Gold Earned: %d" % gold_earned
	villagers_label.text = "Villagers Rescued: %d" % villagers_rescued
	
	# Show the UI and pause the game.
	show()
	get_tree().paused = true

# This function is called when the "Return to Hideout" button is pressed.
func _on_return_button_pressed():
	# It's important to unpause the game *before* changing scenes.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/hideout.tscn")
