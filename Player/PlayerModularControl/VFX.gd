extends Node2D

# Get references to the nodes this component will control.
## We will now find the camera in the _ready() function.
var camera: Camera2D
@onready var dash_particles = get_parent().get_node("DashParticles")
@onready var animated_sprite = get_parent().get_node("AnimatedSprite2D")

func _ready():
	## This is the fix! Search the scene tree for the active camera
	## instead of assuming it's a direct child.
	camera = get_tree().get_first_node_in_group("PlayerCamera")

# This is the "public" function our main player script will call.
func play_dash_effects():
	# Trigger the camera punch effect
	_trigger_camera_punch()
	
	# Start the particle effect
	var dash_direction = Vector2(1 if not animated_sprite.flip_h else -1, 0)
	
	dash_particles.scale.x = dash_direction.x
	dash_particles.emitting = true

func stop_dash_effects():
	dash_particles.emitting = false
	dash_particles.scale.x = 1

# This is the same camera punch function, now living in its own component.
func _trigger_camera_punch():
	## Add a safety check to make sure the camera exists before trying to use it.
	if not is_instance_valid(camera):
		return

	var player = get_parent()
	var tween = create_tween()
	var zoomed_in_vec = Vector2(player.default_camera_zoom, player.default_camera_zoom) * 1.1
	var default_zoom_vec = Vector2(player.default_camera_zoom, player.default_camera_zoom)
	
	tween.tween_property(camera, "zoom", zoomed_in_vec, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "zoom", default_zoom_vec, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
