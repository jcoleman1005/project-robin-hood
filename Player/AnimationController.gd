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
func update_animation(current_state, current_velocity, wall_normal):
	# First, handle flipping the sprite based on velocity.
	# We don't do this for wall states, as they have their own flipping logic.
	if current_state != player.States.ON_WALL and current_state != player.States.WALL_STICKING and current_state != player.States.WALL_SLIP:
		if current_velocity.x > 0: 
			animated_sprite.flip_h = false
		elif current_velocity.x < 0: 
			animated_sprite.flip_h = true
	
	# Now, play the correct animation based on the player's current state.
	match current_state:
		player.States.IDLE: 
			animated_sprite.play("idle")
		player.States.RUNNING: 
			animated_sprite.play("run")
		player.States.JUMPING: 
			animated_sprite.play("jump")
		player.States.FALLING: 
			animated_sprite.play("fall")
		player.States.GLIDING: 
			animated_sprite.play("fall") 
		player.States.ON_WALL:
			animated_sprite.play("wall slide")
			animated_sprite.flip_h = wall_normal.x < 0
		player.States.WALL_SLIP:
			animated_sprite.play("wall slide")
			animated_sprite.flip_h = wall_normal.x < 0
		player.States.WALL_STICKING:
			animated_sprite.play("wall hang") 
			animated_sprite.flip_h = wall_normal.x > 0
		player.States.DASH_PREPARE: 
			animated_sprite.play("crouch")
		player.States.DASHING: 
			animated_sprite.play("jump")
		player.States.UNSTICKING: 
			animated_sprite.play("fall")
		player.States.CROUCHING:
			if abs(current_velocity.x) > 10:
				animated_sprite.play("crouch walk")
			else:
				animated_sprite.play("crouch")
		player.States.LANDING: 
			animated_sprite.play("crouch")
		player.States.SKIDDING: 
			animated_sprite.play("turn")
		player.States.SLIDING: 
			animated_sprite.play("slide")
		
