# res://Levels/Hideout.gd
extends Control

# We need a reference to our new placeholder scene.
@export var archer_placeholder_scene: PackedScene

# --- Node References ---
@onready var gold_label: Label = $ResourceDisplay/PanelContainer/HBoxContainer/GoldLabel
@onready var villager_label: Label = $ResourceDisplay/PanelContainer/HBoxContainer/VillagerLabel
@onready var archer_label: Label =$ResourceDisplay/PanelContainer/HBoxContainer/ArcherLabel
@onready var train_archer_button: Button = $TrainArcherButton

# A reference to the spawn location for our archers.
@onready var archery_range: Node2D = owner.get_node("ArcheryRange")


func _ready() -> void:
	# Connect button signals
	train_archer_button.pressed.connect(_on_train_archer_button_pressed)
	
	
	# Connect to the GameManager's signal to keep visuals and UI in sync.
	GameManager.resources_updated.connect(update_visuals)
	
	# Update everything once at the start to reflect the loaded save data.
	update_visuals()


# This function now handles ALL UI and visual updates for the hideout.
func update_visuals() -> void:
	# --- Update UI Labels ---
	gold_label.text = "Gold: " + str(GameManager.gold)
	villager_label.text = "Villagers: " + str(GameManager.villagers)
	archer_label.text = "Archers: " + str(GameManager.archers)
	
	# --- Update Button State ---
	train_archer_button.disabled = not (GameManager.gold >= 10 and GameManager.villagers > 0)
	
	# --- Update Archer Placeholders ---
	# First, clear any existing archers to prevent duplicates.
	for child in archery_range.get_children():
		child.queue_free()
		
	# Second, spawn one placeholder for each archer we have.
	if archer_placeholder_scene:
		for i in range(GameManager.archers):
			var archer = archer_placeholder_scene.instantiate()
			# Spread them out so they don't spawn on top of each other.
			archer.position.x = i * 50 
			archery_range.add_child(archer)


func _on_train_archer_button_pressed() -> void:
	# This button's only job is to request the upgrade.
	# The GameManager will update the state, which will trigger our 'update_visuals'
	# function via the 'resources_updated' signal.
	EventBus.train_archer_requested.emit()


func _on_start_mission_button_pressed() -> void:
	EventBus.start_mission_requested.emit("village_outskirts")
