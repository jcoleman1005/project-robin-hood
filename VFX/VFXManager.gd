# res://VFX/VFXManager.gd
extends Node2D

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D
@onready var camera: Camera2D = player.get_node("PlayerCamera")

# --- Generic, Resource-Based Function for one-shot effects ---
func play_effect(vfx_data: VFXData) -> void:
	if not is_instance_valid(vfx_data) or not is_instance_valid(vfx_data.effect_scene):
		return

	var effect: AnimatedSprite2D = vfx_data.effect_scene.instantiate()
	get_tree().root.add_child(effect)

	# ... (positioning, scaling, flipping logic is the same) ...
	var spawn_marker: Marker2D = player.get_node_or_null(vfx_data.spawn_marker_name)
	var spawn_pos: Vector2
	if is_instance_valid(spawn_marker):
		spawn_pos = spawn_marker.global_position
	else:
		spawn_pos = player.global_position
	effect.scale = vfx_data.scale
	if vfx_data.flip_h_with_player:
		var direction = -1.0 if player.animated_sprite.flip_h else 1.0
		effect.flip_h = player.animated_sprite.flip_h
		spawn_pos.x += vfx_data.position_offset.x * direction
		spawn_pos.y += vfx_data.position_offset.y
	elif vfx_data.flip_h_with_wall:
		var wall_normal = player.get_wall_normal()
		effect.flip_h = wall_normal.x < 0
	else:
		spawn_pos += vfx_data.position_offset
	effect.global_position = spawn_pos
	if vfx_data.rotate_with_wall_normal and player.is_on_wall():
		var wall_normal = player.get_wall_normal()
		effect.rotation_degrees = -90 if wall_normal.x > 0 else 90
	else:
		effect.rotation_degrees = vfx_data.rotation_degrees
		
	# --- NEW: Generic Camera Punch Logic ---
	if vfx_data.camera_punch_intensity > 0.0:
		_trigger_camera_punch(vfx_data.camera_punch_intensity)

	# --- Play ---
	if effect.has_method("play_effect"):
		effect.play_effect(vfx_data.animation_name, vfx_data.playback_speed)


# --- Specific Functions for Sustained Effects (like Dash) ---
func play_dash_effects(particles: GPUParticles2D) -> void:
	if not is_instance_valid(particles): return
	# The camera punch is no longer triggered here.
	var dash_direction = Vector2(1 if not player.animated_sprite.flip_h else -1, 0)
	particles.scale.x = dash_direction.x
	particles.emitting = true

func stop_dash_effects(particles: GPUParticles2D) -> void:
	if not is_instance_valid(particles): return
	particles.emitting = false
	particles.scale.x = 1

func _trigger_camera_punch(intensity: float) -> void:
	if not is_instance_valid(camera):
		return
	var tween = create_tween().set_trans(Tween.TRANS_QUAD)
	# Use the intensity from the VFXData resource.
	var zoomed_in_vec = camera.zoom * (1.0 + intensity)
	tween.tween_property(camera, "zoom", zoomed_in_vec, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "zoom", camera.zoom, 0.1).set_ease(Tween.EASE_IN)
