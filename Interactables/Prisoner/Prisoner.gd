# res://Interactables/Prisoner/Prisoner.gd
extends StaticBody2D

@onready var _interactable: Interactable = $Interactable

func _ready() -> void:
	# This line connects the interaction signal to our logic function below.
	_interactable.interacted.connect(_on_interactable_interacted)


func _on_interactable_interacted() -> void:
	# Announce that a villager was rescued. The GameManager will hear this
	# and update its internal state.
	EventBus.villager_rescued.emit()
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
