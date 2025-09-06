# res://Enemies/Guard/States/alert_state.gd
extends GuardState

func enter() -> void:
	# Stop all movement.
	guard.velocity = Vector2.ZERO
	
	# You can create a dedicated "alert" animation later. For now, "idle" works.
	guard.animated_sprite.play("idle")
	
	# Announce that the player has been caught.
	EventBus.player_detected.emit()
	
	# Disable the guard's physics process so it does nothing further.
	guard.set_physics_process(false)
