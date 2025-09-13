# res://Player/Data/CameraStats.gd
class_name CameraStats
extends Resource

@export_group("Camera Tuning")
@export var horizontal_deadzone: float = 80.0 ## The horizontal space the player can move before the camera follows. Larger is looser, smaller is tighter.
@export var vertical_deadzone: float = 50.0 ## The vertical space the player can move before the camera follows. Good for ignoring small jumps.
@export var smoothing_speed: float = 6.0 ## The main speed at which the camera catches up to the player. Higher is snappier, lower is smoother.
@export var fall_speed_multiplier: float = 2.0 ## Increases camera speed when player is falling to prevent them from going off-screen.
@export var look_offset: float = 100.0 ## How far the camera shifts up/down when holding the look inputs.
@export var look_speed: float = 4.0 ## How quickly the camera moves to the look_offset position.
@export var lookahead_distance: float = 120.0 ## How far the camera shifts in the direction of movement.
@export var facing_offset: float = 50.0 ## The horizontal offset applied when the player is standing still, based on facing direction.
@export var ledge_peek_offset: float = 100.0 ## How far the camera automatically shifts down when the player is near a ledge.
@export var wall_slide_peek_offset: float = 80.0 ## The vertical offset applied when the player is sliding on a wall.
@export var recenter_speed: float = 2.0 ## How quickly the camera returns to center after looking around.

@export_group("Vertical Lookahead")
@export var upward_velocity_threshold: float = 200.0 ## The upward speed the player must exceed to trigger the lookahead.
@export var vertical_lookahead_amount: float = -100.0 ## The vertical offset (negative is up) to apply when lookahead is active.
@export var vertical_lookahead_speed: float = 4.0 ## The speed at which the camera moves to the lookahead position.
