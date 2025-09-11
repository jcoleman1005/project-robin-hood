# res://Persistence/persistence_component.gd
extends Node
class_name PersistenceComponent

# A unique identifier for this object across the entire game.
# Examples: "village_chest_01", "castle_prisoner_main_quest"
@export var object_id: String = ""

var _owner: Node

func _ready() -> void:
	_owner = get_parent()
	
	if object_id.is_empty():
		push_warning("Persistent object has no ID and will not be saved: " + str(_owner.name))
		set_process(false)
		set_physics_process(false)
		return

	# Ask the GameManager if this object has a previously saved state.
	var state = GameManager.get_persistent_state(object_id)
	if state != null:
		# If it does, apply that state.
		_apply_state(state)
	else:
		# Otherwise, it's a new object for this session.
		# No action needed until it's marked as collected.
		pass

# Called by the owner (e.g., the Chest) when it has been interacted with.
func mark_collected(state: Dictionary) -> void:
	if object_id.is_empty():
		return
	GameManager.set_persistent_state(object_id, state)
	# We call _apply_state here to immediately trigger the collected behavior (like queue_free).
	_apply_state(state)

# This function tells the owner what to do with the saved data.
func _apply_state(state: Dictionary) -> void:
	# The owner node is responsible for implementing this method to handle its own state.
	if _owner.has_method("_apply_persistent_state"):
		_owner._apply_persistent_state(state)
