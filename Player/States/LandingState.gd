# res://Player/States/LandingState.gd
extends State

func enter() -> void:
	player.current_jumps = 0
	if player.is_long_fall:
		player.is_long_fall = false
		player.long_fall_ended.emit()

	player.land_timer.start(player.LANDING_DURATION)

	if player.dust_puff_scene:
		var puff = player.dust_puff_scene.instantiate()
		get_tree().root.add_child(puff)
		puff.global_position = player.get_node("FootSpawner").global_position
		puff.emitting = true
	
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.LANDING, player.velocity, Vector2.ZERO, input_x)

func exit() -> void:
	player.land_timer.stop()

func process_physics(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") or player.jump_buffered:
		player.jump_buffered = false
		player.jump_buffer_timer.stop()
		state_machine.change_state("Jumping")
		return

	if Input.is_action_pressed("slide"):
		state_machine.change_state("Sliding")
		return

	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.friction_smoothness)

	if player.land_timer.is_stopped():
		if Input.is_action_pressed("down"):
			state_machine.change_state("Crouching")
		else:
			state_machine.change_state("Idle")
