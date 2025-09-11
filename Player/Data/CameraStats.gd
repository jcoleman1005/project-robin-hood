# res://Player/Data/CameraStats.gd
class_name CameraStats
extends Resource

@export_group("Camera Tuning")
@export var horizontal_deadzone: float = 80.0
@export var vertical_deadzone: float = 50.0
@export var smoothing_speed: float = 6.0
@export var fall_speed_multiplier: float = 2.0
@export var look_offset: float = 100.0
@export var look_speed: float = 4.0
@export var lookahead_distance: float = 120.0
@export var ledge_peek_offset: float = 100.0
@export var wall_slide_peek_offset: float = 80.0
@export var recenter_speed: float = 2.0
