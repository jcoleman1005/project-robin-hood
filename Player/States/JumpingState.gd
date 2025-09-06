# res://Player/States/JumpingState.gd
extends State

func enter() -> void:
	# THE FIX: This line was missing. It applies the jump's upward velocity.
	player.enter_jump_state()

	# --- Visuals and Polish ---
	# (The code for animations and particles that we already fixed)
	player.animation_player.play("jump_stretch")

	print("DEBUG: Trying to spawn dust puff...")
	if player.dust_puff_scene:
		print("DEBUG: dust_puff_scene is valid. Instantiating.")
		var puff = player.dust_puff_scene.instantiate()
		get_tree().root.add_child(puff)
		puff.global_position = player.get_node("FootSpawner").global_position
		print("DEBUG: Setting 'emitting = true' on the puff instance.")
		puff.emitting = true 
	else:
		printerr("DEBUG: ERROR - dust_puff_scene is NOT SET on the Player in the Inspector!")

	# --- Final Animation Update ---
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.JUMPING, player.velocity, Vector2.ZERO, input_x)

func exit() -> void:
	# Reset the sprite's scale when we leave the jump state.
	player.animation_player.play("RESET")


func process_physics(delta: float) -> void:
	var input_x: float = Input.get_axis("left", "right")
	var gravity: float = player.stats.jump_gravity if player.velocity.y < 0 else player.stats.fall_gravity
	
	player.velocity.y += gravity * delta
	player.velocity.x = move_toward(player.velocity.x, input_x * player.stats.speed, player.stats.air_control_acceleration)
	
	# --- Check for State Transitions ---
	if player.is_on_wall():
		if not (sign(player.get_wall_normal().x) == sign(input_x)):
			state_machine.change_state("OnWall")
			return

	if player.velocity.y > 0:
		state_machine.change_state("Falling")
		return
	elif Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y *= player.stats.jump_cut_multiplier
		
	player.animation_controller.update_animation(player.States.JUMPING, player.velocity, Vector2.ZERO, input_x)
