# res://Interactables/Prisoner/Prisoner.gd
extends StaticBody2D

@onready var _interactable: Interactable = $Interactable
@onready var _persistence_component: PersistenceComponent = $PersistenceComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_interactable.interacted.connect(_on_interactable_interacted)

func _on_interactable_interacted() -> void:
	animation_player.play("rescued")
	await animation_player.animation_finished
	
	animated_sprite.hide()
	_interactable.enabled = false
	
	EventBus.villager_rescued.emit()
	_persistence_component.mark_collected({"is_rescued": true})

# This function is called by the PersistenceComponent if the prisoner has saved data.
func _apply_persistent_state(state: Dictionary) -> void:
	if state.get("is_rescued", false):
		# If this prisoner was already rescued, remove them from the scene.
		queue_free()
