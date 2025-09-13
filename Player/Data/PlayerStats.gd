class_name PlayerStats
extends Resource

@export_group("Movement & Physics")
@export var speed: float = 350.0
@export var air_control_acceleration: float = 250.0
@export var terminal_velocity: float = 750.0
@export var acceleration_smoothness: float = 0.1
@export var friction_smoothness: float = 0.3

@export_group("Jumping & Gravity")
@export var jump_height: float = 120.0
@export var time_to_apex: float = 0.5
@export var fall_gravity: float = 2400.0
@export var jump_cut_multiplier: float = 0.3

@export_group("Abilities")
@export var glide_velocity: float = 300.0
@export var blink_dash_enabled: bool = false
@export var slide_duration: float = 0.4
@export var standing_slide_speed: float = 375.0
@export var slide_friction: float = 0.01
@export var skid_duration: float = 0.25
@export var skid_friction: float = 0.25
@export var wall_slip_duration: float = 0.08
@export var wall_slide_friction: float = 80.0
@export var crouch_speed_multiplier: float = 0.5
@export var wall_slide_jump_horizontal_velocity: float = 600.0
@export var wall_slide_jump_vertical_velocity: float = -600.0
@export var wall_stick_jump_horizontal_velocity: float = 900.0
@export var wall_stick_jump_vertical_velocity: float = -400.0
@export var dash_end_velocity_multiplier: float = 0.3
@export var invisibility_duration: float = 2.0
@export var invisibility_cooldown: float = 5.0
@export var wall_kick_horizontal_velocity: float = 700.0 ## NEW: Horizontal speed of the kick-off.
@export var wall_kick_vertical_velocity: float = -200.0 ## NEW: Small upward boost during kick-off.
@export var wall_kick_duration: float = 0.25 ## NEW: How long the kick-off state lasts.

@export_group("Game Feel & Timers")
@export var coyote_time_duration: float = 0.2
@export var wall_coyote_time_duration: float = 0.18
@export var jump_buffer_duration: float = 0.1
@export var dash_freeze_duration: float = 0.08
@export var fall_zoom_delay: float = 0.3
@export var wall_detach_hang_time: float = 0.2
@export var wall_detach_gravity_scale: float = 0.5

# --- Calculated Values ---
var jump_velocity: float
var jump_gravity: float
var charged_jump_velocity: float


func _init() -> void:
	if time_to_apex > 0:
		jump_gravity = (2 * jump_height) / (time_to_apex * time_to_apex)
		jump_velocity = -jump_gravity * time_to_apex
		charged_jump_velocity = jump_velocity * 1.5
	else:
		jump_gravity = 1200.0
		jump_velocity = -600.0
		charged_jump_velocity = -900.0
