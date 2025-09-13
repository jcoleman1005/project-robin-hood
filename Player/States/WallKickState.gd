# res://Player/States/WallKickState.gd
extends State

@export var wall_kick_vfx: VFXData

func enter() -> void:
	var wall_normal = player.get_wall_normal()
	var input_x = Input.get_axis("left", "right")
	
	# Apply the horizontal and vertical kick-off velocities from our stats resource
	player.velocity.x = wall_normal.x * player.stats.wall_kick_horizontal_velocity
	player.velocity.y = player.stats.wall_kick_vertical_velocity
	
	# Start the timer that will end this state
	player.wall_kick_timer.start(player.stats.wall_kick_duration)
	
	# --- NEW: Add VFX and Animations ---
	# Set the player's animation pose to the "jump" animation, same as the dash.
	player.animation_controller.update_animation(player.States.DASHING, player.velocity, wall_normal, input_x)
	
	# Play the initial kick-off puff effect using our new resource.
	if is_instance_valid(wall_kick_vfx):
		player.vfx.play_effect(wall_kick_vfx)
	
	# Start the sustained dash particle trail.
	player.vfx.play_dash_effects(player.dash_particles)


func process_physics(delta: float) -> void:
	# Apply gravity while in the kick-off state
	player.velocity.y += player.stats.fall_gravity * delta
	
	# Transition to FallingState if we hit a ceiling
	if player.is_on_ceiling():
		state_machine.change_state("Falling")


func exit() -> void:
	# --- NEW: Stop the particle trail when the state ends. ---
	player.vfx.stop_dash_effects(player.dash_particles)
	player.wall_kick_timer.stop()
