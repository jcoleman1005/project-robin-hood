extends Node2D

@onready var animated_sprite = get_parent().get_node("AnimatedSprite2D")
var player

func _ready():
	player = get_parent()

func update_animation(current_state, current_velocity, wall_normal, input_direction_x):
	var animation_to_play = ""
	
	match current_state:
		player.States.ON_WALL, player.States.WALL_SLIP:
			animation_to_play = "wall slide"
			animated_sprite.flip_h = wall_normal.x < 0
		player.States.WALL_STICKING:
			animation_to_play = "wall hang"
			animated_sprite.flip_h = wall_normal.x > 0
		_:
			match current_state:
				player.States.IDLE:
					animation_to_play = "idle"
				player.States.RUNNING:
					animation_to_play = "run"
				player.States.JUMPING:
					animation_to_play = "jump"
				player.States.FALLING, player.States.WALL_DETACH:
					animation_to_play = "fall"
				player.States.LANDING, player.States.DASH_PREPARE:
					animation_to_play = "crouch"
				player.States.SKIDDING:
					animation_to_play = "turn"
				player.States.SLIDING:
					animation_to_play = "slide"
				player.States.DASHING:
					animation_to_play = "jump"
				player.States.CROUCHING:
					if abs(current_velocity.x) > 10:
						animation_to_play = "crouch walk"
					else:
						animation_to_play = "crouch"

			if input_direction_x > 0:
				animated_sprite.flip_h = false
			elif input_direction_x < 0:
				animated_sprite.flip_h = true
	
	if animation_to_play != "":
		animated_sprite.play(animation_to_play)
		
