# res://Player/States/LandingState.gd
extends State

@export var land_vfx: VFXData

func enter() -> void:
	player.current_jumps = 0
	if player.is_long_fall:
		player.is_long_fall = false
		player.long_fall_ended.emit()

	# Play the squish animation from the AnimationPlayer.
	player.animation_player.play("land_squish")

	# Simultaneously, play the crouch animation on the AnimatedSprite2D.
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.LANDING, player.velocity, Vector2.ZERO, input_x)

	if land_vfx:
		player.vfx.play_effect(land_vfx)

func exit() -> void:
	pass

func process_physics(_delta: float) -> void:
	# The state transition is handled by the "land_squish" animation's Call Method Track.
	if Input.is_action_just_pressed("jump") or player.jump_buffered:
		player.jump_buffered = false
		player.jump_buffer_timer.stop()
		state_machine.change_state("Jumping")
		return

	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.friction_smoothness)
