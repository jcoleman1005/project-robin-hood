# res://Singletons/InteractionManager.gd
extends Node

signal show_prompt(interactable)
signal hide_prompt

var _current_interactable: Interactable = null
var _is_holding: bool = false
var _hold_progress: float = 0.0

func _ready() -> void:
	EventBus.interaction_started.connect(_on_interaction_started)
	EventBus.interaction_cancelled.connect(_on_interaction_cancelled)
	EventBus.mission_started.connect(clear_interactable)

func _process(delta: float) -> void:
	if _is_holding and is_instance_valid(_current_interactable):
		_hold_progress += delta
		
		var duration = _current_interactable.interaction_duration
		if duration <= 0:
			duration = 0.01

		var progress_percentage = _hold_progress / duration
		EventBus.interaction_progress_updated.emit(progress_percentage)
		
		if _hold_progress >= duration:
			var object_name = _current_interactable.get_parent().name
			Loggie.info("Interaction SUCCEEDED for '%s'." % object_name, "interaction")
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
	Loggie.info("Registered '%s' as current interactable." % interactable.get_parent().name, "interaction")

func unregister_interactable(interactable: Interactable) -> void:
	if _current_interactable == interactable:
		Loggie.info("Unregistered '%s'." % interactable.get_parent().name, "interaction")
		_current_interactable = null
		_reset_hold_state()
		hide_prompt.emit()

func _on_interaction_started() -> void:
	if is_instance_valid(_current_interactable):
		_is_holding = true
		Loggie.info("Interaction hold STARTED.", "interaction")

func _on_interaction_cancelled() -> void:
	if _is_holding:
		Loggie.info("Interaction hold CANCELLED.", "interaction")
	_reset_hold_state()

func _reset_hold_state() -> void:
	if not _is_holding and _hold_progress == 0.0:
		return
	_is_holding = false
	_hold_progress = 0.0
	EventBus.interaction_progress_updated.emit(0.0)
