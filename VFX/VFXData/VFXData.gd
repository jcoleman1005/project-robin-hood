# res://VFX/VFXData.gd
class_name VFXData
extends Resource

@export_group("Core Properties")
## The scene to instance for the effect (e.g., AnimatedEffect.tscn).
@export var effect_scene: PackedScene
## The animation to play from the effect_scene's SpriteFrames.
@export var animation_name: String = ""
## The playback speed. 1.0 is normal, -1.0 is reverse, 0.5 is half-speed.
@export var playback_speed: float = 1.0

@export_group("Spawning Behavior")
## The Marker2D node on the player to spawn at (e.g., FootSpawner, WallSlideSpawner).
@export var spawn_marker_name: String = "FootSpawner"
## An additional position offset applied after spawning.
@export var position_offset: Vector2 = Vector2.ZERO
## Flips the effect horizontally based on the player's facing direction.
@export var flip_h_with_player: bool = false
## Flips the effect horizontally based on the wall normal direction.
@export var flip_h_with_wall: bool = false
## Applies a specific rotation in degrees.
@export var rotation_degrees: float = 0.0
## Sets a specific scale.
@export var scale: Vector2 = Vector2.ONE
