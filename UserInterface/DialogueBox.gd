# res://UserInterface/DialogueBox.gd
extends CanvasLayer

# THE FIX: Add this line to declare the signal.
signal closed

@onready var _label: Label = $MarginContainer/Panel/Label

func _unhandled_input(event: InputEvent) -> void:
	# When the dialogue is visible, wait for an action to close it.
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		# Mark the input as handled so it doesn't trigger anything else.
		get_viewport().set_input_as_handled()
		# Announce that this dialogue is now closed.
		closed.emit()
		# Remove the dialogue box from the scene.
		queue_free()


# This is the public function the UIManager will call to set the text.
func display_message(message: String) -> void:
	_label.text = message
	# We make it visible here, now that it starts hidden by default.
	show()
