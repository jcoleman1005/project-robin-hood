# res://VFX/AnimatedEffect.gd
extends AnimatedSprite2D

# This script plays a specified animation once, then removes itself from the scene.
# It makes our visual effects reusable and self-managing.

func _ready() -> void:
	# Connect the animation_finished signal to our cleanup function.
	# This is the most reliable way to know when the effect is done.
	animation_finished.connect(_on_animation_finished)


# This is the main public function that other scripts will call.
# It tells the effect which animation to play.
func play_effect(animation_name: String) -> void:
	# The 'play()' function is built into AnimatedSprite2D.
	play(animation_name)


func _on_animation_finished() -> void:
	# Once the animation is complete, remove the node from the scene tree.
	queue_free()
