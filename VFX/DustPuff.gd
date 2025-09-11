# res://VFX/DustPuff.gd
extends GPUParticles2D

# This script makes the particle effect automatically
# remove itself from the scene after it has finished playing.

func _ready() -> void:
	# The 'finished' signal is emitted by GPUParticles2D when all particles
	# have died. This is perfect for a one-shot effect.
	finished.connect(_on_finished)


func _on_finished() -> void:
	# Once the signal is received, we simply queue the node for deletion.
	queue_free()
