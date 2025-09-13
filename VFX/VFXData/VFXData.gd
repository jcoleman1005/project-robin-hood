# res://VFX/VFXData/VFXData.gd
class_name VFXData
extends Resource

@export_group("Core Properties")
@export var effect_scene: PackedScene
@export var animation_name: String = ""
@export var playback_speed: float = 1.0

@export_group("Spawning Behavior")
@export var spawn_marker_name: String = "FootSpawner"
@export var position_offset: Vector2 = Vector2.ZERO
@export var flip_h_with_player: bool = false
@export var flip_h_with_wall: bool = false
@export var rotate_with_wall_normal: bool = false
@export var rotation_degrees: float = 0.0
@export var scale: Vector2 = Vector2.ONE

@export_group("Extra Effects")
## The strength of the camera zoom punch. 0 = no punch, 0.1 = 10% zoom.
@export var camera_punch_intensity: float = 0.0
