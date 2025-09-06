# res://Enemies/Guard/States/patrol_state.gd
extends GuardState

func enter() -> void:
	guard.animated_sprite.play("walk")


# In res://Enemies/Guard/States/patrol_state.gd

func process_physics(_delta: float) -> void:
	# PRIORITY 1: Decide if we need to turn around.
	# Do this before checking if we are on the floor.
	if guard.turn_cooldown_timer.is_stopped():
		if not guard.ledge_check_ray.is_colliding() or guard.wall_check_ray.is_colliding():
			guard.turn_around()
			# It's good practice to exit here to let the turn take effect on the next frame.
			return 
			
	# PRIORITY 2: Handle movement and visuals.
	# Only apply horizontal velocity if the guard is on the ground.
	if guard.is_on_floor():
		guard.velocity.x = guard.speed * guard.direction
	
	guard.animated_sprite.flip_h = (guard.direction < 0)
	
	if guard.direction < 0: # Facing Left
		guard.vision_cone_area.rotation_degrees = 180
	else: # Facing Right
		guard.vision_cone_area.rotation_degrees = 0
