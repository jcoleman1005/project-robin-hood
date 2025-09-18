# IdleState.gd
extends State

func enter() -> void:
	
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.IDLE, player.velocity, Vector2.ZERO, input_x)


func process_physics(_delta: float) -> void:
	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.core_friction_smoothness)
	
	var input_x: float = Input.get_axis("left", "right")
	
	if Input.is_action_just_pressed("jump"):
		state_machine.change_state("Jumping")
	elif Input.is_action_just_pressed("slide") and player.can_standing_slide:
		state_machine.change_state("Sliding")
	elif Input.is_action_pressed("down"):
		state_machine.change_state("Crouching")
	elif input_x != 0:
		state_machine.change_state("Running")
	elif not player.is_on_floor():
		player.coyote_timer.start(player.stats.feel_coyote_time_duration)
		state_machine.change_state("Falling")
