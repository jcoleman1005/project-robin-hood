# res://UserInterface/FloatingText.gd
extends Label

@export var float_height: float = 50.0

func show_text(text_to_show: String) -> void:
	text = text_to_show
	# Make the text start slightly transparent
	modulate.a = 0.0

	var tween = create_tween()
	# Chain the animations together
	# 1. Fade in over 0.2 seconds
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	# 2. Move up by 50 pixels over 1 second
	tween.tween_property(self, "position:y", position.y - float_height, 1.0).set_ease(Tween.EASE_OUT)
	# 3. Simultaneously, fade out during the last 0.5 seconds of the move
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.5)

	# When the entire animation sequence is finished, delete the node.
	tween.finished.connect(queue_free)
