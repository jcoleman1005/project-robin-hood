# res://Player/States/SkiddingState.gd
extends State

func enter() -> void:
	player.skid_timer.start(player.stats.skid_duration)
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.SKIDDING, player.velocity, Vector2.ZERO, -input_x)

func exit() -> void:
	player.skid_timer.stop()

func process_physics(_delta: float) -> void:
	# Use stats resource for physics values
	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.skid_friction)
	
	if player.skid_timer.is_stopped():
		state_machine.change_state("Running")
	elif Input.is_action_just_pressed("jump"):
		state_machine.change_state("Jumping")
