# res://Singletons/InteractionManager.gd
extends Node

signal show_prompt(interactable)
signal hide_prompt


# --- Internal State ---
var _current_interactable: Interactable = null # Using the specific class name for type safety
var _is_holding: bool = false
var _hold_progress: float = 0.0

func _ready() -> void:
	EventBus.interaction_started.connect(_on_interaction_started)
	EventBus.interaction_cancelled.connect(_on_interaction_cancelled)
	EventBus.mission_started.connect(clear_interactable)

func _process(delta: float) -> void:
	if _is_holding and is_instance_valid(_current_interactable):
		_hold_progress += delta
		
		# THE KEY CHANGE IS HERE:
		# 1. Get the duration from the specific object we are interacting with.
		var duration = _current_interactable.interaction_duration
		
		# 2. Safety check to prevent division-by-zero errors if the duration is set to 0.
		if duration <= 0:
			duration = 0.01 # Allow for near-instant interaction

		# 3. Calculate progress using the object's specific duration.
		var progress_percentage = _hold_progress / duration
		EventBus.interaction_progress_updated.emit(progress_percentage)
		
		DebugManager.log(DebugManager.Category.INTERACTION, "Hold progress: " + str(snapped(progress_percentage, 0.01)))
		
		# 4. Check for success using that same duration.
		if _hold_progress >= duration:
			var object_name = _current_interactable.get_parent().name
			DebugManager.log(DebugManager.Category.INTERACTION, "Interaction SUCCEEDED for '%s'." % object_name)
			_current_interactable.perform_interaction()
			EventBus.interaction_succeeded.emit()
			_reset_hold_state()

func clear_interactable() -> void:
	_current_interactable = null
	hide_prompt.emit()
	_reset_hold_state()

func register_interactable(interactable: Interactable) -> void:
	_current_interactable = interactable
	show_prompt.emit(_current_interactable)
	DebugManager.log(DebugManager.Category.INTERACTION, "Registered '%s' as current interactable." % interactable.get_parent().name)

func unregister_interactable(interactable: Interactable) -> void:
	if _current_interactable == interactable:
		DebugManager.log(DebugManager.Category.INTERACTION, "Unregistered '%s'." % interactable.get_parent().name)
		_current_interactable = null
		_reset_hold_state()
		hide_prompt.emit()

func _on_interaction_started() -> void:
	if is_instance_valid(_current_interactable):
		_is_holding = true
		DebugManager.log(DebugManager.Category.INTERACTION, "Interaction hold STARTED.")

func _on_interaction_cancelled() -> void:
	if _is_holding:
		DebugManager.log(DebugManager.Category.INTERACTION, "Interaction hold CANCELLED.")
	_reset_hold_state()

func _reset_hold_state() -> void:
	if not _is_holding and _hold_progress == 0.0:
		return
	_is_holding = false
	_hold_progress = 0.0
	EventBus.interaction_progress_updated.emit(0.0)
