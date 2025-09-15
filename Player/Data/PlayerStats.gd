# res://Player/Data/PlayerStats.gd
class_name PlayerStats
extends Resource

@export_group("Movement & Physics")
@export var speed: float = 350.0 ## The player's maximum horizontal running speed.
@export var air_control_acceleration: float = 250.0 ## How quickly the player can change direction mid-air.
@export var terminal_velocity: float = 750.0 ## The maximum downward speed when falling.
@export var acceleration_smoothness: float = 0.1 ## How quickly the player reaches max speed. Lower is faster.
@export var friction_smoothness: float = 0.3 ## How quickly the player stops. Lower is faster.
@export var crouch_speed_multiplier: float = 0.5 ## The speed multiplier when crouching.

@export_group("Jumping & Gravity")
@export var jump_height: float = 120.0 ## The height of a standard jump.
@export var time_to_apex: float = 0.5 ## The time it takes to reach the peak of a jump.
@export var fall_gravity: float = 2400.0 ## The gravity applied when falling.
@export var jump_cut_multiplier: float = 0.3 ## The effect of releasing the jump button early.

@export_group("Dash")
@export var dash_distance: float = 400.0 ## The fixed horizontal distance the dash covers.
@export var dash_duration: float = 0.25 ## The time it takes to complete the dash.
@export var dash_freeze_duration: float = 0.08 ## The short pause before the dash begins.
@export var dash_end_velocity_multiplier: float = 0.3 ## The percentage of dash speed retained after the dash ends.

@export_group("Slide & Skid")
@export var slide_duration: float = 0.4 ## How long the slide lasts.
@export var standing_slide_speed: float = 375.0 ## The initial speed of a slide from a standstill.
@export var slide_friction: float = 0.01 ## How quickly the slide slows down.
@export var skid_duration: float = 0.25 ## The duration of the turn-around skid animation.
@export var skid_friction: float = 0.25 ## How quickly the player stops during a skid.

@export_group("Wall Movement")
@export var wall_slip_duration: float = 0.08 ## The short pause before sticking to a wall.
@export var wall_slide_friction: float = 80.0 ## The downward speed when sliding on a wall.
@export var wall_slide_jump_horizontal_velocity: float = 600.0 ## The horizontal force of a normal wall jump.
@export var wall_slide_jump_vertical_velocity: float = -600.0 ## The vertical force of a normal wall jump.
@export var wall_stick_jump_horizontal_velocity: float = 900.0 ## The horizontal force of a jump from a wall stick.
@export var wall_stick_jump_vertical_velocity: float = -400.0 ## The vertical force of a jump from a wall stick.
@export var wall_kick_horizontal_velocity: float = 700.0 ## Horizontal speed of the wall kick-off ability.
@export var wall_kick_vertical_velocity: float = -200.0 ## Small upward boost during a wall kick-off.
@export var wall_kick_duration: float = 0.25 ## How long the wall kick-off state lasts.
@export var wall_coyote_time_duration: float = 0.18 ## How long the player can still wall jump after leaving a wall.
@export var wall_detach_hang_time: float = 0.2 ## A brief moment of reduced gravity after detaching from a wall.
@export var wall_detach_gravity_scale: float = 0.5 ## The gravity multiplier during a wall detach.

@export_group("Other Abilities")
@export var glide_velocity: float = 300.0 ## The fixed downward speed while gliding.
@export var invisibility_duration: float = 2.0 ## How long the invisibility lasts.
@export var invisibility_cooldown: float = 5.0 ## The cooldown after using invisibility.
@export var blink_dash_enabled: bool = false ## (Future) Flag to enable a different dash type.

@export_group("Game Feel Timers")
@export var coyote_time_duration: float = 0.2 ## How long the player can still jump after running off a ledge.
@export var jump_buffer_duration: float = 0.1 ## How long a jump input is remembered before landing.
@export var fall_zoom_delay: float = 0.3 ## The time before the camera considers a fall a 'long fall'.

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
