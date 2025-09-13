# DashPrepareState.gd
extends State
@onready var vfx = $VFX


func enter():
	player.can_dash = false
	player.velocity = Vector2.ZERO
	player.dash_freeze_timer.start(player.stats.dash_freeze_duration)
	
	# --- NEW ANIMATED EFFECT LOGIC ---
	if player.dust_puff_scene: # This variable now holds AnimatedEffect.tscn
		var effect = player.dust_puff_scene.instantiate()
		get_tree().root.add_child(effect)
		
		# Position the effect at the player's feet.
		effect.global_position = player.get_node("FootSpawner").global_position
		
		# Set direction and flip the sprite accordingly.
		var direction = 1.0 if not player.animated_sprite.flip_h else -1.0
		effect.global_position.x -= direction * 15 # Offset it behind the player.
		effect.flip_h = direction < 0
		

		# Tell the new scene to play the correct animation.
		vfx.play_dash_prepare_effect()
		
	var input_x = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.DASH_PREPARE, player.velocity, Vector2.ZERO, input_x)

func process_physics(_delta):
	# This state is controlled by a timer.
	pass
