# res://Enemies/Guard/States/suspicious_state.gd
extends GuardState

func enter() -> void:
	# Stop moving
	guard.velocity = Vector2.ZERO
	guard.animated_sprite.play("idle")
	
	# Turn to face the direction of the sound
	var direction_to_sound = (guard.last_known_sound_position - guard.global_position).normalized()
	var new_direction = 1 if direction_to_sound.x >= 0 else -1
	
	if guard.direction != new_direction:
		guard.turn_around()

	# Start the timer to decide how long to wait
	guard.suspicion_timer.start()
	guard.suspicion_timer.timeout.connect(_on_suspicion_timer_timeout)

func exit() -> void:
	# Disconnect the timer signal to prevent it from being connected multiple times.
	if guard.suspicion_timer.is_connected("timeout", Callable(self, "_on_suspicion_timer_timeout")):
		guard.suspicion_timer.timeout.disconnect(_on_suspicion_timer_timeout)

func process_physics(_delta: float) -> void:
	# While suspicious, the guard is just waiting, so no physics logic is needed here.
	# We could add logic later for the guard to be able to see the player in this state.
	pass

func _on_suspicion_timer_timeout() -> void:
	# Once the timer is done, go back to patrolling.
	state_machine.change_state("PatrolState")
