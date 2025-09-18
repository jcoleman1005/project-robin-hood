class_name PlayerStats
extends Resource

# ==============================================================================
# CORE MOVEMENT & PHYSICS
# ==============================================================================
@export_group("Core Movement & Physics")
@export var core_speed: float = 350.0 ## The player's maximum horizontal speed on the ground. Higher = faster.
@export var core_acceleration_smoothness: float = 0.1 ## How quickly the player reaches max speed. Lower = snappier, Higher = more 'floaty'.
@export var core_friction_smoothness: float = 0.3 ## How quickly the player stops when there is no input. Lower = stops faster, Higher = more slippery.
@export var core_crouch_speed_multiplier: float = 0.5 ## A multiplier applied to the base speed when crouching. 0.5 = half speed.

# ==============================================================================
# JUMPING & GRAVITY
# ==============================================================================
@export_group("Jumping & Gravity")
@export var jump_height: float = 120.0 ## The maximum height of a standard jump in pixels. Higher = jumps higher.
@export var jump_time_to_apex: float = 0.5 ## Time to reach the peak of the jump. Determines jump gravity. Shorter = faster, snappier jump.
@export var jump_cut_multiplier: float = 0.3 ## The factor by which upward velocity is reduced when jump is released early. 0.5 = cuts half the remaining speed.
@export var jump_fall_gravity: float = 2400.0 ## Gravity applied when falling. Higher = falls faster.
@export var jump_terminal_velocity: float = 750.0 ## Maximum downward speed. Higher = faster max fall speed.
@export var jump_air_control_acceleration: float = 250.0 ## How quickly the player can change direction mid-air. Higher = more responsive.

# ==============================================================================
# DASHING
# ==============================================================================
@export_group("Dashing")
@export var dash_is_blink: bool = false ## If true, dash is an instant teleport. If false, it's a high-speed movement over time.
@export var dash_distance: float = 300.0 ## The distance covered by a dash in pixels. Higher = dashes further.
@export var dash_duration: float = 0.2 ## The time to complete a dash, in seconds. Lower = faster dash.
@export var dash_end_velocity_multiplier: float = 0.3 ## A multiplier for horizontal speed after a dash ends. 0.3 = retains 30% of dash speed.

# ==============================================================================
# GROUND ACTIONS
# ==============================================================================
@export_group("Ground Actions")
@export var ground_crouch_speed_multiplier: float = 0.5 ## A multiplier for speed when crouching. 0.5 = half speed.
@export var ground_slide_duration: float = 0.4 ## The minimum duration of a slide in seconds. Higher = longer mandatory slide.
@export var ground_standing_slide_speed: float = 375.0 ## The initial horizontal speed when sliding from a standstill. Higher = faster start.
@export var ground_slide_friction: float = 0.01 ## How quickly speed is lost during a slide. Lower = slides further.
@export var ground_skid_duration: float = 0.25 ## The duration of the skid animation when changing direction abruptly. Higher = longer skid.
@export var ground_skid_friction: float = 0.25 ## How much the player slows down during a skid. Higher = more speed is lost.

# ==============================================================================
# WALL MOVEMENT
# ==============================================================================
@export_group("Wall Movement")
@export var wall_slide_friction: float = 80.0 ## The downward speed when sliding on a wall. Lower = slides down faster.
@export var wall_slip_duration: float = 0.08 ## Time spent in the 'slip' state before sticking to a wall. Higher = longer before stick.
@export var wall_kick_duration: float = 0.25 ## How long the horizontal push from a wall kick lasts. Higher = longer push.
@export var wall_kick_horizontal_velocity: float = 1200.0 ## The horizontal speed of the wall kick. Higher = kicks off much further.
@export var wall_kick_vertical_velocity: float = -200.0 ## The vertical boost from a wall kick (negative is up). Higher magnitude = more upward boost.
@export var wall_slide_jump_horizontal_velocity: float = 600.0 ## Horizontal speed when jumping off a sliding wall. Higher = jumps further from wall.
@export var wall_slide_jump_vertical_velocity: float = -600.0 ## Vertical speed when jumping off a sliding wall (negative is up). Higher magnitude = jumps higher.
@export var wall_stick_jump_horizontal_velocity: float = 900.0 ## The horizontal speed when jumping from a stuck wall position. Higher = powerful leap from wall.
@export var wall_stick_jump_vertical_velocity: float = -400.0 ## The vertical speed when jumping from a stuck wall position (negative is up).
@export var wall_detach_hang_time: float = 0.2 ## How long the player 'hangs' in the air after detaching from a wall. Higher = more hang time.
@export var wall_detach_gravity_scale: float = 0.5 ## A multiplier for gravity during the wall detach hang time. 0.5 = half gravity.

# ==============================================================================
# SPECIAL ABILITIES
# ==============================================================================
@export_group("Special Abilities")
@export var special_glide_velocity: float = 300.0 ## The constant downward speed while gliding. Lower = slower descent.
@export var special_invisibility_duration: float = 2.0 ## How long the invisibility effect lasts, in seconds. Higher = longer duration.
@export var special_invisibility_cooldown: float = 5.0 ## The time before invisibility can be used again, in seconds. Higher = longer cooldown.

# ==============================================================================
# TUNING & GAME FEEL TIMERS
# ==============================================================================
@export_group("Tuning & Game Feel Timers")
@export var feel_coyote_time_duration: float = 0.2 ## How long the player can still jump after walking off a ledge, in seconds. Higher = more lenient.
@export var feel_wall_coyote_time_duration: float = 0.18 ## How long the player can still wall-jump after leaving a wall, in seconds. Higher = more lenient.
@export var feel_jump_buffer_duration: float = 0.1 ## How early the player can press jump before landing and still have it register, in seconds. Higher = more lenient.
@export var feel_dash_freeze_duration: float = 0.08 ## The brief pause before the dash begins, in seconds. Higher = longer pause.
@export var feel_long_fall_distance: float = 250.0 ## The vertical distance in pixels the player must fall to trigger a hard landing shake. Higher = longer fall needed.


# --- Calculated Values (Not exposed in Inspector) ---
var jump_velocity: float
var jump_gravity: float
var charged_jump_velocity: float


func _init() -> void:
	if jump_time_to_apex > 0:
		jump_gravity = (2 * jump_height) / (jump_time_to_apex * jump_time_to_apex)
		jump_velocity = -jump_gravity * jump_time_to_apex
		charged_jump_velocity = jump_velocity * 1.5
	else:
		# Provide safe fallbacks if time_to_apex is zero to avoid division errors
		jump_gravity = 1200.0
		jump_velocity = -600.0
		charged_jump_velocity = -900.0
