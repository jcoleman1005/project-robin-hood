extends Node2D

# Get a reference to the AnimatedSprite2D node, which is a sibling of this node.
@onready var animated_sprite = get_parent().get_node("AnimatedSprite2D")
# -- A variable to hold a reference to the main player script --
var player

# --- Get the parent reference when the node is ready ---
func _ready():
	# We get the parent node so we can access its "States" enum
	player = get_parent()

# This is the main public function that our player script will call every frame.
# It needs to know the player's current state, velocity, and wall normal to make decisions.
func update_animation(current_state, _current_velocity, wall_normal, input_direction_x):
	# This new structure is much clearer. We handle special cases first.
	match current_state:
		player.States.ON_WALL, player.States.WALL_SLIP:
			animated_sprite.play("wall slide")
			# Flip is based on the wall's direction, not input.
			animated_sprite.flip_h = wall_normal.x < 0

		player.States.WALL_STICKING:
			animated_sprite.play("wall hang")
			# This flip logic makes the player face away from the wall.
			animated_sprite.flip_h = wall_normal.x > 0

		# The default case handles all other "normal" states.
		_:
			# First, determine the animation to play.
			match current_state:
				player.States.IDLE:
					animated_sprite.play("idle")
				player.States.RUNNING:
					animated_sprite.play("run")
				player.States.JUMPING:
					animated_sprite.play("jump")
				player.States.FALLING, player.States.WALL_DETACH:
					animated_sprite.play("fall")
				player.States.LANDING, player.States.DASH_PREPARE:
					animated_sprite.play("crouch")
				player.States.SKIDDING:
					animated_sprite.play("turn")
				player.States.SLIDING:
					animated_sprite.play("slide")
				player.States.DASHING:
					animated_sprite.play("jump") # Or a dedicated dash animation

			# Second, for all these normal states, flip the sprite based on input.
			if input_direction_x > 0:
				animated_sprite.flip_h = false
			elif input_direction_x < 0:
				animated_sprite.flip_h = true
