# DialogueBox.gd
extends CanvasLayer

@onready var label = $MarginContainer/Panel/Label

func _ready():
	hide()
	# We defer this by one frame to make sure the manager is ready.
	call_deferred("connect_signals")

func connect_signals():
	# Connect to the InteractionManager's signals.
	InteractionManager.message_shown.connect(on_message_shown)
	InteractionManager.message_hidden.connect(on_message_hidden)

# This function is called when the InteractionManager announces a new message.
func on_message_shown(message: String, _speaker_position: Vector2):
	label.text = message
	show()

# This function is called when the InteractionManager announces it's time to hide.
func on_message_hidden():
	hide()

# NO _input function is needed here. The InteractionManager handles everything.
