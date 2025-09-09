# res://Interactables/RescuedVillager/RescuedVillager.gd
extends StaticBody2D

@export_multiline var dialogue_message: String = "Thank you!"

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _interactable: Interactable = $InteractionArea

func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	GameManager.resources_updated.connect(update_visibility)
	update_visibility()


func _on_interacted() -> void:
	EventBus.show_dialogue.emit(dialogue_message)


func update_visibility() -> void:
	
	
	if GameManager.villagers <= 0:
		# Hide and disable everything with the most reliable methods.
		hide()
		_collision_shape.set_deferred("disabled", true)
		_interactable.monitoring = false
		
		# THE DEFINITIVE FIX: Directly disable the interaction area's collision shape.
		# This is a more direct command to the physics server.
		_interactable.get_node("CollisionShape2D").set_deferred("disabled", true)
	else:
		# Show and enable everything.
		show()
		_collision_shape.set_deferred("disabled", false)
		_interactable.monitoring = true
		_interactable.get_node("CollisionShape2D").set_deferred("disabled", false)
