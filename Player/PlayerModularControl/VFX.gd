extends Node2D

# We'll export this so we can assign our AnimatedEffect scene in the editor.
@export var animated_effect_scene: PackedScene

# Get references to the nodes this component will control.
var camera: Camera2D
@onready var dash_particles = get_parent().get_node("DashParticles")
@onready var animated_sprite = get_parent().get_node("AnimatedSprite2D")
@onready var player = get_parent()

func _ready():
	camera = get_tree().get_first_node_in_group("PlayerCamera")

# --- Existing Dash Trail Logic ---
func play_dash_effects():
	_trigger_camera_punch()
	var dash_direction = Vector2(1 if not animated_sprite.flip_h else -1, 0)
	dash_particles.scale.x = dash_direction.x
	dash_particles.emitting = true

func stop_dash_effects():
	dash_particles.emitting = false
	dash_particles.scale.x = 1

func _trigger_camera_punch():
	if not is_instance_valid(camera):
		return
	var tween = create_tween()
	var zoomed_in_vec = camera.zoom * 1.1
	var default_zoom_vec = camera.zoom
	tween.tween_property(camera, "zoom", zoomed_in_vec, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "zoom", default_zoom_vec, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


# --- NEW PUBLIC FUNCTIONS FOR ONE-SHOT EFFECTS ---

func play_jump_effect():
	if animated_effect_scene:
		var effect = animated_effect_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = player.get_node("FootSpawner").global_position
		effect.play_effect("jump_puff")

func play_landing_effect():
	if animated_effect_scene:
		var effect = animated_effect_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = player.get_node("FootSpawner").global_position
		effect.play_effect("jump_puff")

func play_dash_prepare_effect():
	if animated_effect_scene:
		var effect = animated_effect_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = player.get_node("FootSpawner").global_position
		var direction = 1.0 if not player.animated_sprite.flip_h else -1.0
		effect.global_position.x -= direction * 15
		effect.flip_h = direction < 0
		effect.play_effect("dash_puff")

func play_wall_slide_effect():
	if animated_effect_scene:
		var effect = animated_effect_scene.instantiate()
		get_tree().root.add_child(effect)
		var wall_offset = player.get_wall_normal() * -10
		effect.global_position = player.get_node("WallSlideSpawner").global_position + wall_offset
		if player.get_wall_normal().x > 0:
			effect.rotation_degrees = 90
		else:
			effect.rotation_degrees = -90
		effect.scale = Vector2(0.5, 0.5)
		effect.play_effect("dash_puff")

func play_wall_jump_effect():
	if animated_effect_scene:
		var effect = animated_effect_scene.instantiate()
		get_tree().root.add_child(effect)
		var wall_offset = player.get_wall_normal() * -15
		effect.global_position = player.get_node("WallSlideSpawner").global_position + wall_offset
		effect.play_effect("jump_puff")
