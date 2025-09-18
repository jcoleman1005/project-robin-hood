# res://Player/States/SlidingState.gd
extends State

@export var slide_vfx: VFXData

func enter() -> void:
	player.slide_timer.start(player.stats.ground_slide_duration)
	player.set_crouching_collision()

	if abs(player.velocity.x) < 10.0:
		var direction = 1.0 if not player.animated_sprite.flip_h else -1.0
		player.velocity.x = player.stats.ground_standing_slide_speed * direction
		
		player.can_standing_slide = false
		player.standing_slide_cooldown_timer.start(1.0)

	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.SLIDING, player.velocity, Vector2.ZERO, input_x)

	if is_instance_valid(slide_vfx):
		player.vfx.play_effect(slide_vfx)


func exit() -> void:
	player.slide_timer.stop()
	if player.is_head_clear():
		player.set_standing_collision()


func process_physics(_delta: float) -> void:
	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.ground_slide_friction)
	if not player.ground_ray.is_colliding():
		state_machine.change_state("Falling")
		return

	var wants_to_exit_slide = Input.is_action_just_released("slide")
	var must_exit_slide = player.slide_timer.is_stopped()

	if Input.is_action_just_pressed("jump"):
		if player.is_head_clear():
			state_machine.change_state("Jumping")
		return

	if wants_to_exit_slide or must_exit_slide:
		if player.is_head_clear():
			if Input.is_action_pressed("down"):
				state_machine.change_state("Crouching")
			else:
				state_machine.change_state("Idle")
