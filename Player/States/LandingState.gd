# res://Player/States/LandingState.gd
extends State

func enter() -> void:
	
	
	# --- Debugging Logic for Particles ---
	print("DEBUG: Trying to spawn dust puff...")
	if player.dust_puff_scene:
		print("DEBUG: dust_puff_scene is valid. Instantiating.")
		var puff = player.dust_puff_scene.instantiate()
		get_tree().root.add_child(puff)
		puff.global_position = player.get_node("FootSpawner").global_position
		
		# THE FIX & DEBUG: We must explicitly tell the particles to emit.
		print("DEBUG: Setting 'emitting = true' on the puff instance.")
		puff.emitting = true 
	else:
		printerr("DEBUG: ERROR - dust_puff_scene is NOT SET on the Player in the Inspector!")


func exit() -> void:
	player.land_timer.stop()

func process_physics(_delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		state_machine.change_state("Jumping")
		return

	# This block now has the necessary return statement.
	if Input.is_action_pressed("slide"):
		state_machine.change_state("Sliding")
		return # <-- THE FIX

	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.friction_smoothness)

	if player.land_timer.is_stopped():
		state_machine.change_state("Idle")
	elif player.jump_buffered:
		player.jump_buffered = false
		player.jump_buffer_timer.stop()
		state_machine.change_state("Jumping")
