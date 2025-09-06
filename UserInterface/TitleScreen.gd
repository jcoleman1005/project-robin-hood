# res://UserInterface/TitleScreen.gd
extends Control

@onready var _new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var _continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_button_pressed)
	_continue_button.pressed.connect(_on_continue_button_pressed)
	
	if FileAccess.file_exists(GameManager.SAVE_FILE_PATH):
		_continue_button.disabled = false
		# If the continue button is available, make it the default.
		_continue_button.grab_focus()
	else:
		_continue_button.disabled = true
		# Otherwise, make the New Game button the default.
		_new_game_button.grab_focus()
		
func _on_new_game_button_pressed() -> void:
	GameManager.reset_game_data()
	# CORRECTED: Announce the user's intent on the EventBus.
	EventBus.new_game_requested.emit()

func _on_continue_button_pressed() -> void:
	# CORRECTED: Announce the user's intent on the EventBus.
	EventBus.continue_game_requested.emit()
