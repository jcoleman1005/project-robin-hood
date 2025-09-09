# res://Player/States/SlidingState.gd
extends State

# We no longer need an @onready var here.

func enter() -> void:
	# Start the grace period using the reference from the main player script.
	player.slide_grace_timer.start()
	
	player.slide_timer.start(player.stats.slide_duration)
	player.set_crouching_collision()
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.SLIDING, player.velocity, Vector2.ZERO, input_x)

func exit() -> void:
	player.slide_timer.stop()
	if player.is_head_clear():
		player.set_standing_collision()

func process_physics(_delta: float) -> void:
	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.slide_friction)

	# Use the clean reference here as well.
	if player.slide_grace_timer.is_stopped() and not player.is_on_floor():
		state_machine.change_state("Falling")
		return

	if player.slide_timer.is_stopped():
		if player.is_head_clear():
			state_machine.change_state("Idle")
		else:
			state_machine.change_state("Crouching")
	elif Input.is_action_just_pressed("jump"):
		if player.is_head_clear():
			state_machine.change_state("Jumping")
