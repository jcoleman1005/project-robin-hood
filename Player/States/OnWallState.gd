# res://Player/States/OnWallState.gd
extends State
@onready var vfx_timer: Timer = $VFXTimer
@onready var vfx = $"../../VFX"

func _ready() -> void:
	vfx_timer.timeout.connect(_on_particle_timer_timeout)


func enter() -> void:
	var wall_normal = player.get_wall_normal()
	
	if wall_normal.x > 0:
		player.animation_player.play("wall_slide_offset_left")
	else:
		player.animation_player.play("wall_slide_offset_right")
	
	player.set_wall_slide_collision()
	player.current_jumps = 0
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.ON_WALL, player.velocity, wall_normal, input_x)

	# Manually start the timer when entering the state.
	vfx_timer.start()

	
func process_physics(delta: float) -> void:
	var input_x: float = Input.get_axis("left", "right")
	
	if player.jump_buffered:
		player.jump_buffered = false
		player.jump_buffer_timer.stop()
		player.wall_jump()
		state_machine.change_state("Falling")
		return

	player.velocity.y = move_toward(player.velocity.y, player.stats.wall_slide_friction, player.stats.fall_gravity * delta)
	player.velocity.x = -player.get_wall_normal().x * 5.0

	if Input.is_action_just_pressed("jump"):
		player.wall_jump()
		state_machine.change_state("Falling")
	elif Input.is_action_pressed("shift") and player.can_wall_stick:
		state_machine.change_state("WallSlip")
	elif not player.is_on_wall() or (player.get_wall_normal().x * input_x > 0):
		player._start_wall_coyote_time()
		state_machine.change_state("WallDetach")
	elif player.is_on_floor():
		state_machine.change_state("Idle")

func exit() -> void:

	# Stop the timer when leaving the state to prevent further particle spawning.
	vfx_timer.stop()
	# Play the reset animation when we leave this state.

	player.animation_player.play("RESET")
	
	
func _on_particle_timer_timeout() -> void:

	player.vfx.play_wall_slide_effect() 

