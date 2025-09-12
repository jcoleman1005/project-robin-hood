# DashPrepareState.gd
extends State

func enter():
	player.can_dash = false
	player.velocity = Vector2.ZERO
	player.dash_freeze_timer.start(player.stats.dash_freeze_duration)
	
	# --- NEW PARTICLE LOGIC ---
	if player.dust_puff_scene:
		var puff = player.dust_puff_scene.instantiate()
		get_tree().root.add_child(puff)
		
		# Position the puff at the player's feet
		puff.global_position = player.get_node("FootSpawner").global_position
		
		# Offset it slightly behind the player for a better "kick-off" feel
		var direction = 1.0 if not player.animated_sprite.flip_h else -1.0
		puff.global_position.x -= direction * 15 # Adjust this offset as needed
		
#eee		puff.emitting = true
	# --- END NEW PARTICLE LOGIC ---
	
	var input_x = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.DASH_PREPARE, player.velocity, Vector2.ZERO, input_x)

func process_physics(_delta):
	# This state is controlled by a timer.
	# The logic is in the _on_dash_freeze_timer_timeout() function in PlayerScript.gd.
	# When that timer finishes, it will change the state to Dashing.
	pass
