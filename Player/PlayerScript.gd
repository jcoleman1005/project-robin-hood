extends CharacterBody2D

# The enum includes all possible player states.
enum States {IDLE, RUNNING, JUMPING, FALLING, GLIDING, ON_WALL, WALL_STICKING, DASHING, UNSTICKING, CROUCHING, LANDING, DASH_PREPARE, WALL_SLIP, SKIDDING, SLIDING, WALL_DETACH}
var state: States = States.IDLE

@export_group("Movement & Physics")
@export var SPEED = 500.0
@export var air_control_acceleration: float = 100.0
@export var terminal_velocity: float = 750.0
@export var ACCELERATION_SMOOTHNESS = 0.1
@export var FRICTION_SMOOTHNESS = 0.2

@export_group("Jumping & Gravity")
@export var jump_height: float = 120.0 
@export var time_to_apex: float = 0.5
@export var fall_gravity: float = 2400.0
@export var jump_cut_multiplier: float = 0.5

# These are no longer exported, but calculated in _ready()
var JUMP_VELOCITY = -600.0
var jump_gravity: float = 1200.0


@export_group("Abilities")
@export var glide_velocity: float = 300.0
@export var blink_dash_enabled: bool = false
@export var slide_duration: float = 0.5
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
## New: Variables for the invisibility mechanic.
@export var invisibility_duration: float = 2.0
@export var invisibility_cooldown: float = 5.0


@export_group("Camera")
@export var default_camera_zoom: float = 1.75
@export var fall_camera_zoom: float = 1.5
@export var glide_camera_zoom: float = 1.5
@export var fall_zoom_delay: float = 0.3
@export var camera_zoom_reset_delay: float = 0.3
@export var camera_zoom_out_speed: float = 0.05
@export var camera_zoom_in_speed: float = 0.2
@export var look_up_offset: float = -150.0
@export var look_down_offset: float = 150.0
@export var camera_vertical_lerp_speed: float = 0.1
@export var look_down_velocity_threshold: float = 200.0


@export_group("Game Feel & Timers")
@export var coyote_time_duration: float = 0.2
@export var wall_coyote_time_duration: float = 0.18
@export var jump_buffer_duration: float = 0.1
@export var dash_freeze_duration: float = 0.08
@export var wall_detach_hang_time: float = 0.2
@export var wall_detach_gravity_scale: float = 0.5


@export_group("Interaction")
@export var interact_input_action: String = "interact"


@export_group("Debug & Helpers")
@export var show_trajectory_preview: bool = true
@export var debug_wall_jump_timing: bool = false
@export var debug_failed_jumps: bool = false
@export var debug_wall_jump_success_rate: bool = false


# -- Movement smoothness --


const MAX_JUMPS = 2

# -- Dash mechanic values --
const DASH_SPEED = 1500.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.5

# -- Wall stick timer values --
const WALL_STICK_DURATION = 2.0
const JUMP_CHARGE_DURATION = 1.0
const LANDING_DURATION = 0.15

# This is now calculated from jump_height and time_to_apex
var CHARGED_JUMP_VELOCITY = -900.0

var current_jumps = 0
# -- Flags to manage cooldowns and abilities --
var can_dash: bool = true
var can_wall_stick: bool = true
var is_jump_charged: bool = false
var jump_buffered: bool = false
var is_long_fall: bool = false

## New: Public variable for other nodes to check if the player is invisible.
var is_invisible: bool = false
var can_go_invisible: bool = true

var start_position: Vector2
var last_dash_direction: Vector2
var last_wall_normal: Vector2

var wall_detach_time: float = 0.0

var is_in_wall_jump_string: bool = false
var wall_jump_string_count: int = 0

var camera: Camera2D

# -- References to our nodes --
@onready var dash_timer = $Timers/DashTimer
@onready var dash_cooldown_timer = $Timers/DashCooldownTimer
@onready var wall_stick_timer = $Timers/WallStickTimer
@onready var standing_collision = $StandingCollision
@onready var crouching_collision = $CrouchingCollision
@onready var wall_slide_collision = $WallSlideCollision
@onready var trajectory_line = $TrajectoryLine
@onready var crouch_timer = $Timers/CrouchTimer
@onready var land_timer = $Timers/LandTimer
@onready var coyote_timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer = $Timers/JumpBufferTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_freeze_timer = $Timers/DashFreezeTimer
@onready var dash_particles = $DashParticles
@onready var fall_zoom_timer = $Timers/FallZoomTimer
@onready var wall_slip_timer = $Timers/WallSlipTimer
@onready var skid_timer = $Timers/SkidTimer
@onready var wall_coyote_timer = $Timers/WallCoyoteTimer
@onready var slide_timer = $Timers/SlideTimer
@onready var head_clearance_ray = $HeadClearanceRaycast
@onready var animation_controller = $AnimationController
@onready var vfx = $VFX
@onready var camera_zoom_reset_timer = $Timers/CameraZoomResetTimer
@onready var wall_detach_timer = $Timers/WallDetachTimer
@onready var interaction_controller = $InteractionController
## New: References to the new timers.
@onready var invisibility_timer = $Timers/InvisibilityTimer
@onready var invisibility_cooldown_timer = $Timers/InvisibilityCooldownTimer

#signal to trigger mission complete
signal mission_completed(gold_earned, villagers_rescued)

# --- _ready function ---
func _ready():
	start_position = global_position
	
	call_deferred("_find_camera")
	
	## Calculate jump physics based on the exported variables
	if time_to_apex > 0:
		jump_gravity = (2 * jump_height) / (time_to_apex * time_to_apex)
		JUMP_VELOCITY = -jump_gravity * time_to_apex
		# Also calculate the charged jump based on the new gravity
		CHARGED_JUMP_VELOCITY = JUMP_VELOCITY * 1.5 
	
	# Connect all timer signals
	dash_timer.connect("timeout", _on_dash_timer_timeout)
	dash_cooldown_timer.connect("timeout", _on_dash_cooldown_timer_timeout)
	wall_stick_timer.connect("timeout", _on_wall_stick_timer_timeout)
	crouch_timer.connect("timeout", _on_crouch_timer_timeout)
	land_timer.connect("timeout", _on_land_timer_timeout)
	coyote_timer.connect("timeout", _on_coyote_timer_timeout)
	jump_buffer_timer.connect("timeout", _on_jump_buffer_timer_timeout)
	dash_freeze_timer.connect("timeout", _on_dash_freeze_timer_timeout)
	fall_zoom_timer.connect("timeout", _on_fall_zoom_timer_timeout)
	wall_slip_timer.connect("timeout", _on_wall_slip_timer_timeout)
	skid_timer.connect("timeout", _on_skid_timer_timeout)
	wall_coyote_timer.connect("timeout", _on_wall_coyote_timer_timeout)
	slide_timer.connect("timeout", _on_slide_timer_timeout)
	camera_zoom_reset_timer.connect("timeout", _on_camera_zoom_reset_timer_timeout)
	wall_detach_timer.connect("timeout", _on_wall_detach_timer_timeout)
	## New: Connect the new timer signals.
	invisibility_timer.connect("timeout", _on_invisibility_timer_timeout)
	invisibility_cooldown_timer.connect("timeout", _on_invisibility_cooldown_timer_timeout)

# --- Main Game Loop ---
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		reset_player_position()
		return

	velocity.y = min(velocity.y, terminal_velocity)
	var input_direction_x = Input.get_axis("left", "right")
	
	if _handle_global_inputs():
		pass

	match state:
		States.IDLE: idle_state(input_direction_x)
		States.RUNNING: run_state(input_direction_x)
		States.JUMPING: jump_state(input_direction_x, delta)
		States.FALLING: fall_state(input_direction_x, delta)
		States.ON_WALL: on_wall_state(input_direction_x)
		States.GLIDING: glide_state(input_direction_x)
		States.WALL_STICKING: wall_sticking_state(input_direction_x)
		States.DASHING: dash_state(input_direction_x)
		States.CROUCHING: crouching_state(input_direction_x)
		States.LANDING: landing_state(input_direction_x)
		States.DASH_PREPARE: dash_prepare_state(input_direction_x)
		States.WALL_SLIP: wall_slip_state(input_direction_x)
		States.SKIDDING: skidding_state(input_direction_x)
		States.SLIDING: sliding_state(input_direction_x)
		States.WALL_DETACH: wall_detach_state(input_direction_x, delta)
		States.UNSTICKING:
			unsticking_state(input_direction_x)
			return
			
	animation_controller.update_animation(state, velocity, get_wall_normal())
	update_trajectory_preview()
	
	if is_instance_valid(camera):
		update_camera_zoom()
		_update_camera_offset()
	
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("hazards"):
			reset_player_position()
			return

func _handle_global_inputs() -> bool:
	if Input.is_action_just_pressed("dash") and can_dash:
		enter_dash_prepare_state()
		return true
	
	## New: Check for the invisibility input.
	if Input.is_action_just_pressed("invisibility") and can_go_invisible:
		_enter_invisibility()
		return true
	
	return false
	
# --- State Logic Functions ---

func idle_state(input_x: float):
	velocity.x = lerp(velocity.x, 0.0, FRICTION_SMOOTHNESS)
	
	if Input.is_action_pressed("ui_down"):
		enter_crouch_state()
		return

	if input_x != 0: state = States.RUNNING
	elif Input.is_action_just_pressed("jump"): enter_jump_state()
	elif not is_on_floor():
		state = States.FALLING
		coyote_timer.start(coyote_time_duration)
		fall_zoom_timer.start(fall_zoom_delay)

func run_state(input_x: float):
	if input_x != 0 and sign(input_x) != sign(velocity.x) and abs(velocity.x) > 100:
		state = States.SKIDDING
		skid_timer.start(skid_duration)
		return

	velocity.x = lerp(velocity.x, input_x * SPEED, ACCELERATION_SMOOTHNESS)

	if input_x == 0: state = States.IDLE
	elif Input.is_action_just_pressed("jump"): enter_jump_state()
	elif Input.is_action_just_pressed("slide"): enter_slide_state()
	elif not is_on_floor():
		state = States.FALLING
		coyote_timer.start(coyote_time_duration)
		fall_zoom_timer.start(fall_zoom_delay)

func jump_state(input_x: float, delta: float):
	if not is_on_floor():
		var gravity = jump_gravity if velocity.y < 0 else fall_gravity
		velocity.y += gravity * delta
		
	velocity.x = move_toward(velocity.x, input_x * SPEED, air_control_acceleration)
	
	if velocity.y > 0:
		state = States.FALLING
	elif Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

func fall_state(input_x: float, delta: float):
	if not is_on_floor():
		velocity.y += fall_gravity * delta
		
	velocity.x = move_toward(velocity.x, input_x * SPEED, air_control_acceleration)
	
	if Input.is_action_pressed("up"): state = States.GLIDING
	elif is_on_floor():
		state = States.LANDING
		land_timer.start(LANDING_DURATION)
		current_jumps = 0
		
		is_long_fall = false
		camera_zoom_reset_timer.stop()

		if debug_wall_jump_timing:
			wall_detach_time = 0
		if is_in_wall_jump_string:
			if debug_wall_jump_success_rate:
				print("Wall jump string ended at: %d" % wall_jump_string_count)
			is_in_wall_jump_string = false
			wall_jump_string_count = 0
	elif is_on_wall():
		fall_zoom_timer.start(fall_zoom_delay)
		if Input.is_action_pressed("shift") and can_wall_stick:
			state = States.WALL_SLIP
			wall_slip_timer.start(wall_slip_duration)
		elif get_wall_normal().x * input_x < 0:
			state = States.ON_WALL
			set_wall_slide_collision()
		current_jumps = 0
	elif Input.is_action_just_pressed("jump"):
		if not wall_coyote_timer.is_stopped():
			wall_jump(last_wall_normal)
		elif current_jumps < MAX_JUMPS:
			enter_jump_state()
		else:
			jump_buffered = true
			jump_buffer_timer.start(jump_buffer_duration)
			if debug_failed_jumps:
				if wall_coyote_timer.is_stopped():
					print("Failed Jump: No jumps left and wall coyote time expired.")
				else:
					print("Failed Jump: No jumps left.")
			if is_in_wall_jump_string:
				if debug_wall_jump_success_rate:
					print("Wall jump string FAILED at: %d" % wall_jump_string_count)
				is_in_wall_jump_string = false
				wall_jump_string_count = 0
	elif Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

func wall_detach_state(input_x: float, delta: float):
	velocity.y += fall_gravity * wall_detach_gravity_scale * delta
	velocity.x = move_toward(velocity.x, input_x * SPEED, air_control_acceleration)
	
	if Input.is_action_just_pressed("jump"):
		if not wall_coyote_timer.is_stopped():
			wall_jump(last_wall_normal)
			wall_detach_timer.stop()
		else:
			jump_buffered = true
			jump_buffer_timer.start(jump_buffer_duration)

func on_wall_state(input_x: float):
	if jump_buffered:
		jump_buffered = false
		jump_buffer_timer.stop()
		wall_jump()
		return

	velocity.y = move_toward(velocity.y, wall_slide_friction, fall_gravity * get_physics_process_delta_time())
	velocity.x = -get_wall_normal().x * 5.0
	if Input.is_action_just_pressed("jump"): wall_jump()
	elif Input.is_action_pressed("shift") and can_wall_stick:
		state = States.WALL_SLIP
		wall_slip_timer.start(wall_slip_duration)
	elif not is_on_wall():
		_start_wall_coyote_time()
	elif is_on_floor():
		state = States.IDLE
		set_standing_collision()
	elif (get_wall_normal().x > 0 and input_x > 0) or (get_wall_normal().x < 0 and input_x < 0):
		_start_wall_coyote_time()
	
func wall_sticking_state(input_x: float):
	velocity.y = 1.0
	velocity.x = -get_wall_normal().x * 5.0
	if not Input.is_action_pressed("shift"):
		state = States.ON_WALL
		wall_stick_timer.stop()
	elif Input.is_action_just_pressed("jump"): wall_jump()
	elif not is_on_wall():
		_start_wall_coyote_time()
		wall_stick_timer.stop()
	elif is_on_floor():
		state = States.IDLE
		wall_stick_timer.stop()
		set_standing_collision()

func wall_slip_state(input_x: float):
	velocity.y = move_toward(velocity.y, wall_slide_friction, fall_gravity * get_physics_process_delta_time())
	velocity.x = -get_wall_normal().x * 5.0
	
	if not Input.is_action_pressed("shift"):
		state = States.ON_WALL
		wall_slip_timer.stop()
	elif Input.is_action_just_pressed("jump"):
		wall_slip_timer.stop()
		wall_jump()
	elif not is_on_wall():
		_start_wall_coyote_time()
		wall_slip_timer.stop()

func glide_state(input_x: float):
	velocity.y = glide_velocity
	velocity.x = move_toward(velocity.x, input_x * SPEED, 150)
	
	if is_on_floor():
		state = States.LANDING; land_timer.start(LANDING_DURATION)
	elif is_on_wall():
		state = States.ON_WALL
		set_wall_slide_collision()
	elif Input.is_action_just_released("up"):
		state = States.FALLING
	elif Input.is_action_just_pressed("jump"):
		if current_jumps < MAX_JUMPS:
			enter_jump_state()
		else:
			jump_buffered = true
			jump_buffer_timer.start(jump_buffer_duration)

func dash_state(input_x: float):
	if not blink_dash_enabled and is_on_wall():
		dash_timer.stop()
		velocity.x = 0
		end_dash()

func dash_prepare_state(input_x: float):
	velocity = Vector2.ZERO

func crouching_state(input_x: float):
	velocity.x = lerp(velocity.x, input_x * SPEED * crouch_speed_multiplier, ACCELERATION_SMOOTHNESS)
	
	if Input.is_action_just_pressed("jump"):
		crouch_timer.stop()
		if is_head_clear():
			if is_jump_charged:
				velocity.y = CHARGED_JUMP_VELOCITY
			else:
				velocity.y = JUMP_VELOCITY
			current_jumps = 1
			state = States.JUMPING
	elif not Input.is_action_pressed("ui_down"):
		if is_head_clear():
			state = States.IDLE
			crouch_timer.stop()
			is_jump_charged = false

func landing_state(input_x: float):
	if jump_buffered:
		jump_buffered = false
		jump_buffer_timer.stop()
		enter_jump_state()
		return

	if Input.is_action_pressed("slide"):
		land_timer.stop()
		enter_slide_state()
		return

	if Input.is_action_just_pressed("jump"):
		land_timer.stop()
		enter_jump_state()
		return
	velocity.x = lerp(velocity.x, 0.0, FRICTION_SMOOTHNESS)

func skidding_state(input_x: float):
	velocity.x = lerp(velocity.x, 0.0, skid_friction)
	if Input.is_action_just_pressed("jump"):
		skid_timer.stop()
		enter_jump_state()

func sliding_state(input_x: float):
	if not is_on_floor():
		slide_timer.stop()
		set_standing_collision()
		state = States.FALLING
		coyote_timer.start(coyote_time_duration)
		fall_zoom_timer.start(fall_zoom_delay)
		return

	velocity.x = lerp(velocity.x, 0.0, slide_friction)
	
	if Input.is_action_just_pressed("jump"):
		slide_timer.stop()
		enter_jump_state()
	elif not Input.is_action_pressed("slide"):
		slide_timer.stop()
		if is_head_clear():
			state = States.IDLE
		else:
			state = States.CROUCHING

func unsticking_state(input_x: float):
	global_position += last_dash_direction * SPEED * get_physics_process_delta_time()
	if not test_move(transform, Vector2.ZERO):
		state = States.FALLING
		velocity = last_dash_direction * SPEED * 0.3
		dash_cooldown_timer.start(DASH_COOLDOWN)

# --- Helper Functions ---
func reset_player_position():
	global_position = start_position
	velocity = Vector2.ZERO
	state = States.IDLE
	can_dash = true
	can_wall_stick = true
	current_jumps = 0
	wall_detach_time = 0
	is_in_wall_jump_string = false
	wall_jump_string_count = 0
	
	get_tree().call_group("timers", "stop")
	
	vfx.stop_dash_effects()
	set_standing_collision()
	if is_instance_valid(camera):
		camera.zoom = Vector2(default_camera_zoom, default_camera_zoom)
		camera.position_smoothing_enabled = true

func enter_jump_state():
	coyote_timer.stop()
	fall_zoom_timer.stop()
	set_standing_collision()
	velocity.y = JUMP_VELOCITY
	current_jumps += 1
	state = States.JUMPING

func enter_crouch_state():
	state = States.CROUCHING
	is_jump_charged = false
	crouch_timer.start(JUMP_CHARGE_DURATION)
	set_crouching_collision()

func enter_slide_state():
	state = States.SLIDING
	slide_timer.start(slide_duration)
	set_crouching_collision()

func enter_dash_prepare_state():
	can_dash = false
	state = States.DASH_PREPARE
	dash_freeze_timer.start(dash_freeze_duration)

func end_dash():
	if is_instance_valid(camera):
		camera.position_smoothing_enabled = true
	vfx.stop_dash_effects()
	
	if blink_dash_enabled:
		set_standing_collision()
		if test_move(transform, Vector2.ZERO):
			state = States.UNSTICKING
			return
	
	state = States.FALLING
	fall_zoom_timer.start(fall_zoom_delay)
	velocity.x *= dash_end_velocity_multiplier
	dash_cooldown_timer.start(DASH_COOLDOWN)

func wall_jump(wall_normal_override: Vector2 = Vector2.ZERO):
	if debug_wall_jump_timing and wall_detach_time > 0:
		var jump_time = Time.get_ticks_msec() - wall_detach_time
		print("Wall jump time: %d ms" % jump_time)
		wall_detach_time = 0 

	wall_stick_timer.stop()
	wall_coyote_timer.stop()
	
	is_in_wall_jump_string = true
	wall_jump_string_count += 1
	if debug_wall_jump_success_rate:
		print("Wall jump string: %d" % wall_jump_string_count)

	var wall_normal = wall_normal_override if wall_normal_override != Vector2.ZERO else get_wall_normal()
	
	if Input.is_action_pressed("shift") and can_wall_stick:
		velocity.y = wall_stick_jump_vertical_velocity
		velocity.x = wall_normal.x * wall_stick_jump_horizontal_velocity
	else:
		var input_x = Input.get_axis("left", "right")
		if sign(wall_normal.x) == sign(input_x) and wall_jump_string_count >= 3:
			is_long_fall = true
			camera_zoom_reset_timer.stop()
		
		velocity.y = wall_slide_jump_vertical_velocity
		velocity.x = wall_normal.x * wall_slide_jump_horizontal_velocity

	can_wall_stick = true
	current_jumps = 1
	state = States.FALLING

func _start_wall_coyote_time():
	last_wall_normal = get_wall_normal()
	wall_coyote_timer.start(wall_coyote_time_duration)
	if debug_wall_jump_timing:
		wall_detach_time = Time.get_ticks_msec()
	state = States.WALL_DETACH
	wall_detach_timer.start(wall_detach_hang_time)
	can_wall_stick = true
	fall_zoom_timer.start(fall_zoom_delay)
	
func add_gold(amount: int):
	GameManager.gold += amount
	print("Player now has %d gold." % GameManager.gold)

func add_villager():
	GameManager.villagers += 1
	print("You rescued 1 villager!")

func on_player_hit():
	reset_player_position()

func on_player_detected():
	print("Player detected! Mission Failed.")
	reset_player_position()

func complete_mission():
	# Announce that the mission is complete and send the rewards.
	## This is the fix! We now get the values from the GameManager.
	emit_signal("mission_completed", GameManager.gold, GameManager.villagers)
	# Save the game.
	GameManager.save_game()

func is_head_clear() -> bool:
	if head_clearance_ray.is_colliding():
		return false
	
	set_standing_collision()
	return true

func set_standing_collision():
	standing_collision.disabled = false
	crouching_collision.disabled = true
	wall_slide_collision.disabled = true

func set_crouching_collision():
	standing_collision.disabled = true
	crouching_collision.disabled = false
	wall_slide_collision.disabled = true

func set_wall_slide_collision():
	standing_collision.disabled = true
	crouching_collision.disabled = true
	wall_slide_collision.disabled = false

func update_camera_zoom():
	if not is_instance_valid(camera): return

	var airborne_states = [States.JUMPING, States.FALLING, States.GLIDING, States.WALL_DETACH, States.ON_WALL, States.WALL_SLIP, States.WALL_STICKING]
	if not state in airborne_states and is_long_fall:
		if camera_zoom_reset_timer.is_stopped():
			camera_zoom_reset_timer.start(camera_zoom_reset_delay)

	var target_zoom_value = default_camera_zoom
	if is_long_fall:
		target_zoom_value = fall_camera_zoom
	
	if state == States.GLIDING:
		target_zoom_value = glide_camera_zoom
	
	var lerp_speed = camera_zoom_in_speed if target_zoom_value == default_camera_zoom else camera_zoom_out_speed

	var target_zoom = Vector2(target_zoom_value, target_zoom_value)
	camera.zoom = lerp(camera.zoom, target_zoom, lerp_speed)

func _update_camera_offset():
	if not is_instance_valid(camera): return
	
	var target_offset_y = 0.0
	
	# This is the fix! We now only pan down if the player is in a "long fall".
	# This prevents the camera from bouncing on short hops.
	if is_long_fall:
		target_offset_y = look_down_offset
	elif is_on_floor() and Input.is_action_pressed("ui_up"):
		target_offset_y = look_up_offset
	
	camera.offset.y = lerp(camera.offset.y, target_offset_y, camera_vertical_lerp_speed)


# --- Trajectory Prediction Functions ---
func update_trajectory_preview():
	if not show_trajectory_preview:
		trajectory_line.clear_points()
		return

	var initial_velocity = Vector2.ZERO
	var can_predict = false

	match state:
		States.IDLE, States.RUNNING:
			if current_jumps < MAX_JUMPS:
				initial_velocity = velocity
				initial_velocity.y = JUMP_VELOCITY
				can_predict = true
		States.CROUCHING:
			if current_jumps < MAX_JUMPS:
				initial_velocity = velocity
				initial_velocity.y = CHARGED_JUMP_VELOCITY if is_jump_charged else JUMP_VELOCITY
				can_predict = true
		States.FALLING, States.GLIDING, States.WALL_DETACH:
			if not wall_coyote_timer.is_stopped():
				var wall_normal = last_wall_normal
				if Input.is_action_pressed("shift") and can_wall_stick:
					initial_velocity.y = wall_stick_jump_vertical_velocity
					initial_velocity.x = wall_normal.x * wall_stick_jump_horizontal_velocity
				else:
					initial_velocity.y = wall_slide_jump_vertical_velocity
					initial_velocity.x = wall_normal.x * wall_slide_jump_horizontal_velocity
				can_predict = true
			elif current_jumps < MAX_JUMPS:
				initial_velocity = velocity
				initial_velocity.y = JUMP_VELOCITY
				can_predict = true
		States.ON_WALL, States.WALL_STICKING, States.WALL_SLIP:
			var wall_normal = get_wall_normal()
			if Input.is_action_pressed("shift") and can_wall_stick:
				initial_velocity.y = wall_stick_jump_vertical_velocity
				initial_velocity.x = wall_normal.x * wall_stick_jump_horizontal_velocity
			else:
				initial_velocity.y = wall_slide_jump_vertical_velocity
				initial_velocity.x = wall_normal.x * wall_slide_jump_horizontal_velocity
			can_predict = true
	
	if can_predict:
		predict_trajectory(initial_velocity)
	else:
		trajectory_line.clear_points()

func predict_trajectory(start_velocity: Vector2):
	var points = []
	var current_pos = global_position
	var current_vel = start_velocity
	var physics_step = get_physics_process_delta_time()
	
	for i in range(120):
		var time_elapsed = i * physics_step
		var gravity = fall_gravity
		if time_elapsed < wall_coyote_timer.time_left:
			gravity = fall_gravity * wall_detach_gravity_scale
		elif current_vel.y < 0:
			gravity = jump_gravity
		
		current_vel.y += gravity * physics_step
		current_vel.y = min(current_vel.y, terminal_velocity)
		var motion = current_vel * physics_step
		
		var current_transform = transform
		current_transform.origin = current_pos
		
		if test_move(current_transform, motion):
			break
		
		current_pos += motion
		points.append(to_local(current_pos))
		
	trajectory_line.points = points

# --- Timer and Signal Functions ---
func _on_dash_timer_timeout():
	if state == States.DASHING:
		end_dash()

func _on_dash_cooldown_timer_timeout(): can_dash = true

func _on_wall_stick_timer_timeout():
	if state == States.WALL_STICKING:
		state = States.ON_WALL
		set_wall_slide_collision()

func _on_crouch_timer_timeout():
	is_jump_charged = true

func _on_land_timer_timeout():
	if state == States.LANDING:
		state = States.IDLE

func _on_coyote_timer_timeout():
	if current_jumps == 0:
		current_jumps = 1

func _on_jump_buffer_timer_timeout():
	jump_buffered = false

func _on_dash_freeze_timer_timeout():
	state = States.DASHING
	if is_instance_valid(camera):
		camera.position_smoothing_enabled = false
	last_dash_direction = Vector2(1 if not animated_sprite.flip_h else -1, 0)
	
	vfx.play_dash_effects()
	
	velocity.x = last_dash_direction.x * DASH_SPEED
	velocity.y = 0
	if blink_dash_enabled:
		standing_collision.disabled = true
		crouching_collision.disabled = true
		wall_slide_collision.disabled = true
	dash_timer.start(DASH_DURATION)

func _on_fall_zoom_timer_timeout():
	if not is_on_floor():
		is_long_fall = true
		camera_zoom_reset_timer.stop()

func _on_wall_slip_timer_timeout():
	if state == States.WALL_SLIP:
		state = States.WALL_STICKING
		can_wall_stick = false
		wall_stick_timer.start(WALL_STICK_DURATION)

func _on_wall_coyote_timer_timeout():
	if debug_wall_jump_timing:
		wall_detach_time = 0

func _on_skid_timer_timeout():
	if state == States.SKIDDING:
		state = States.RUNNING

func _on_slide_timer_timeout():
	if state == States.SLIDING:
		if is_head_clear():
			if Input.is_action_pressed("ui_down"):
				state = States.CROUCHING
			else:
				state = States.IDLE
		else:
			state = States.CROUCHING

func _on_camera_zoom_reset_timer_timeout():
	is_long_fall = false
	fall_zoom_timer.stop()

func _on_wall_detach_timer_timeout():
	if state == States.WALL_DETACH:
		state = States.FALLING

func _find_camera():
	camera = get_tree().get_first_node_in_group("PlayerCamera")
	if is_instance_valid(camera):
		camera.zoom = Vector2(default_camera_zoom, default_camera_zoom)

func _enter_invisibility():
	is_invisible = true
	can_go_invisible = false
	invisibility_timer.start(invisibility_duration)
	invisibility_cooldown_timer.start(invisibility_cooldown)
	
	# Add a simple visual effect by making the sprite semi-transparent.
	animated_sprite.modulate.a = 0.5

func _on_invisibility_timer_timeout():
	is_invisible = false
	# Restore the sprite's normal appearance.
	animated_sprite.modulate.a = 1.0

func _on_invisibility_cooldown_timer_timeout():
	can_go_invisible = true
