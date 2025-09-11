# res://Interactables/Prisoner/Prisoner.gd
extends StaticBody2D

@onready var _interactable: Interactable = $Interactable
@onready var _persistence_component: PersistenceComponent = $PersistenceComponent


func _ready() -> void:
	_interactable.interacted.connect(_on_interactable_interacted)

func _on_interactable_interacted() -> void:
	EventBus.villager_rescued.emit()
	# Tell the component this prisoner has been rescued.
	_persistence_component.mark_collected({"is_rescued": true})

# This function is called by the PersistenceComponent if the prisoner has saved data.
func _apply_persistent_state(state: Dictionary) -> void:
	if state.get("is_rescued", false):
		# If this prisoner was already rescued, remove them from the scene.
		queue_free()
