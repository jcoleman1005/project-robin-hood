# res://UserInterface/PauseMenu.gd
extends CanvasLayer

@onready var _resume_button: Button = $MarginContainer/VBoxContainer/ResumeButton
@onready var _quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	_resume_button.grab_focus()
	
func _on_resume_button_pressed() -> void:
	# Announce the intent to unpause the game.
	EventBus.pause_toggled.emit(false)

func _on_quit_button_pressed() -> void:
	# This button's only job is to announce the user's intent on the EventBus.
	# The SceneManager will hear this and handle the entire process of
	# closing the UI and changing the scene.
	EventBus.return_to_hideout_requested.emit()
