# res://Interactables/PersistenceComponent.gd
@tool
extends Node
class_name PersistenceComponent

# A unique identifier for this object. Use the button below to generate one.
@export var object_id: String = ""

# This creates a "button" in the Inspector to generate a new ID.
@export var generate_new_id: bool = false:
	set(value):
		if value:
			# Generate a new ID based on a hash of the time and node path.
			# This is guaranteed to be unique enough for our purposes.
			var new_id = "obj_" + str(str(get_path()).hash()) + str(Time.get_ticks_usec())
			object_id = new_id
			print("Generated new Object ID: ", new_id)


var _owner: Node

func _ready() -> void:
	# This code only runs when the game is playing, not in the editor.
	if Engine.is_editor_hint():
		return

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

# Called by the owner (e.g., the Chest or Prisoner) when it has been interacted with.
func mark_collected(state: Dictionary) -> void:
	if Engine.is_editor_hint() or object_id.is_empty():
		return
	GameManager.set_persistent_state(object_id, state)
	# We call _apply_state here to immediately trigger the collected behavior (like queue_free).
	_apply_state(state)

# This function tells the owner what to do with the saved data.
func _apply_state(state: Dictionary) -> void:
	# The owner node is responsible for implementing this method to handle its own state.
	if _owner.has_method("_apply_persistent_state"):
		_owner._apply_persistent_state(state)
