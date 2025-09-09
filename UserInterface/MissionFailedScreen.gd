# res://UserInterface/MissionFailedScreen.gd
extends CanvasLayer

@onready var _return_button: Button = $MarginContainer/VBoxContainer/ReturnButton

func _ready() -> void:
	

	_return_button.pressed.connect(_on_return_button_pressed)
	_return_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_return_button_pressed()

func _on_return_button_pressed() -> void:
	_return_button.disabled = true
	EventBus.return_to_hideout_requested.emit()
