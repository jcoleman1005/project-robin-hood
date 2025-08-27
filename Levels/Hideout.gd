extends Control

@onready var gold_label = $GoldLabel
@onready var villager_label = $VillagerLabel
@onready var archer_label = $ArcherLabel
@onready var train_archer_button = $TrainArcherButton
@onready var start_mission_button = $StartMissionButton

func _ready():
	# When the scene starts, update the UI with the latest data from the GameManager.
	update_ui()

func update_ui():
	# Access the global GameManager to get the current resource counts.
	gold_label.text = "Gold: %d" % GameManager.gold
	villager_label.text = "Villagers: %d" % GameManager.villagers
	archer_label.text = "Archers: %d" % GameManager.archers
	
	# Disable the button if the player can't afford the upgrade or has no villagers to train.
	if GameManager.gold >= 10 and GameManager.villagers > 0:
		train_archer_button.disabled = false
	else:
		train_archer_button.disabled = true

func _on_train_archer_button_pressed():
	# Check if the player has enough gold AND a villager to train.
	if GameManager.gold >= 10 and GameManager.villagers > 0:
		# Subtract the cost from the GameManager.
		GameManager.gold -= 10
		GameManager.villagers -= 1
		GameManager.archers += 1
		
		print("Archer trained! Gold: %d, Villagers: %d, Archers: %d" % [GameManager.gold, GameManager.villagers, GameManager.archers])
		
		## This is the fix! Save the game after the purchase is made.
		GameManager.save_game()
		
		# Update the UI to reflect the change.
		update_ui()

func _on_start_mission_button_pressed():
	# Change the scene to your mission level.
	get_tree().change_scene_to_file("res://Scenes/VillageOutskirts.tscn")
