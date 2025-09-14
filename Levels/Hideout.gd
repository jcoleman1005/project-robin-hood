# res://Levels/Hideout/Hideout.gd
extends Node2D

@export var archer_placeholder_scene: PackedScene

# --- Node References (Corrected Paths from Scene Root) ---
@onready var gold_label: Label = $CanvasLayer/GUI/ResourceDisplay/PanelContainer/HBoxContainer/GoldLabel
@onready var villager_label: Label = $CanvasLayer/GUI/ResourceDisplay/PanelContainer/HBoxContainer/VillagerLabel
@onready var archer_label: Label = $CanvasLayer/GUI/ResourceDisplay/PanelContainer/HBoxContainer/ArcherLabel
@onready var train_archer_button: Button = $CanvasLayer/GUI/TrainArcherButton
@onready var archery_range: Node2D = $ArcheryRange


func _ready() -> void:
	train_archer_button.pressed.connect(_on_train_archer_button_pressed)
	GameManager.resources_updated.connect(update_visuals)
	update_visuals()


func update_visuals() -> void:
	# This function can be called by a signal before _ready() completes.
	# We wait for the 'ready' signal to ensure all @onready vars are set.
	if not is_node_ready(): # FIX: Use is_node_ready() for Godot 4.
		await ready

	gold_label.text = "Gold: " + str(GameManager.gold)
	villager_label.text = "Villagers: " + str(GameManager.villagers)
	archer_label.text = "Archers: " + str(GameManager.archers)
	
	train_archer_button.disabled = not (GameManager.gold >= 10 and GameManager.villagers > 0)
	
	for child in archery_range.get_children():
		child.queue_free()
		
	if archer_placeholder_scene:
		for i in range(GameManager.archers):
			var archer = archer_placeholder_scene.instantiate()
			archer.position.x = i * 50 
			archery_range.add_child(archer)


func _on_train_archer_button_pressed() -> void:
	EventBus.train_archer_requested.emit()
