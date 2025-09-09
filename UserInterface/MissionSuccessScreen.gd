# res://UserInterface/MissionSuccessScreen.gd
extends CanvasLayer

@onready var _return_button: Button = $MarginContainer/VBoxContainer/ReturnButton

func _ready() -> void:
	_return_button.pressed.connect(_on_return_button_pressed)
	_return_button.grab_focus()


func _on_return_button_pressed() -> void:
	# No longer calls UIManager. It just announces what the user wants
	EventBus.return_to_hideout_requested.emit()
