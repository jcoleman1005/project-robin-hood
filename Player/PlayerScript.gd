# PlayerScript.gd
extends CharacterBody2D

## We replace ALL the old @export variables with this single one.
@export var stats: PlayerStats
@export var dust_puff_scene: PackedScene

# The state enum is logic, so it stays.
enum States {IDLE, RUNNING, JUMPING, FALLING, GLIDING, ON_WALL, WALL_STICKING, DASHING, UNSTICKING, CROUCHING, LANDING, DASH_PREPARE, WALL_SLIP, SKIDDING, SLIDING, WALL_DETACH}

#Signals
signal long_fall_started
signal long_fall_ended
signal gliding_started
signal gliding_ended

# --- Constants ---
# Constants that don't need to be tuned can also stay.
const MAX_JUMPS = 2
const DASH_SPEED = 1500.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.5
const WALL_STICK_DURATION = 2.0
const JUMP_CHARGE_DURATION = 1.0
const LANDING_DURATION = 0.15
const COMBO_STATES: Array[String] = ["Jumping", "OnWall", "Dashing", "Sliding"]

# --- Public State Variables ---
var current_jumps = 0
var can_dash: bool = true
var can_wall_stick: bool = true
var is_jump_charged: bool = false
var jump_buffered: bool = false
var is_long_fall: bool = false # Used by CameraLogic
var is_invisible: bool = false
var can_go_invisible: bool = true
var last_wall_normal: Vector2
var _combo_chain: Array[String] = []
var _interact_held: bool = false

# --- Node References ---
@onready var state_machine = $StateMachine
@onready var dash_timer = $Timers/DashTimer
@onready var dash_cooldown_timer = $Timers/DashCooldownTimer
@onready var wall_stick_timer = $Timers/WallStickTimer
@onready var standing_collision = $StandingCollision
@onready var crouching_collision = $CrouchingCollision
@onready var wall_slide_collision = $WallSlideCollision
@onready var crouch_timer = $Timers/CrouchTimer
@onready var land_timer = $Timers/LandTimer
@onready var coyote_timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer = $Timers/JumpBufferTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_freeze_timer = $Timers/DashFreezeTimer
@onready var fall_zoom_timer = $Timers/FallZoomTimer
@onready var wall_slip_timer = $Timers/WallSlipTimer
@onready var skid_timer = $Timers/SkidTimer
@onready var wall_coyote_timer = $Timers/WallCoyoteTimer
@onready var slide_timer = $Timers/SlideTimer
@onready var head_clearance_ray = $HeadClearanceRaycast
@onready var animation_controller = $AnimationController
@onready var vfx = $VFX
@onready var wall_detach_timer = $Timers/WallDetachTimer
@onready var invisibility_timer = $Timers/InvisibilityTimer
@onready var invisibility_cooldown_timer = $Timers/InvisibilityCooldownTimer
@onready var wall_check_ray_right: RayCast2D = $WallCheckRayRight
@onready var wall_check_ray_left: RayCast2D = $WallCheckRayLeft
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var combo_timer: Timer = $Timers/ComboTimer
@onready var combo_reset_timer: Timer = $Timers/ComboResetTimer
@onready var slide_grace_timer: Timer = $Timers/SlideGraceTimer

func _ready():
	# The jump physics calculations are now handled by the resource itself!
	# All we need to do is connect our timers.
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timer_timeout)
	wall_stick_timer.timeout.connect(_on_wall_stick_timer_timeout)
	crouch_timer.timeout.connect(_on_crouch_timer_timeout)
	land_timer.timeout.connect(_on_land_timer_timeout)
	coyote_timer.timeout.connect(_on_coyote_timer_timeout)
	jump_buffer_timer.timeout.connect(_on_jump_buffer_timer_timeout)
	dash_freeze_timer.timeout.connect(_on_dash_freeze_timer_timeout)
	fall_zoom_timer.timeout.connect(_on_fall_zoom_timer_timeout)
	wall_slip_timer.timeout.connect(_on_wall_slip_timer_timeout)
	skid_timer.timeout.connect(_on_skid_timer_timeout)
	wall_coyote_timer.timeout.connect(_on_wall_coyote_timer_timeout)
	slide_timer.timeout.connect(_on_slide_timer_timeout)
	wall_detach_timer.timeout.connect(_on_wall_detach_timer_timeout)
	invisibility_timer.timeout.connect(_on_invisibility_timer_timeout)
	invisibility_cooldown_timer.timeout.connect(_on_invisibility_cooldown_timer_timeout)
	combo_timer.timeout.connect(_on_combo_timer_timeout)
	combo_reset_timer.timeout.connect(_on_combo_reset_timer_timeout)
	state_machine.state_changed.connect(_on_state_changed)
	state_machine.call_deferred("initialize")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		EventBus.pause_menu_requested.emit()

func _physics_process(_delta: float):
	if not GameManager.is_gameplay_active:
		return

	if not is_instance_valid(stats):
		return
	
	# DELETE THIS BLOCK:
	# if Input.is_action_just_pressed("interact_world"):
	#	 # Emit on the EventBus now
	#	 EventBus.interact_pressed.emit()
	
	velocity.y = min(velocity.y, stats.terminal_velocity)
	_handle_global_inputs()
	move_and_slide()
	

func _handle_global_inputs():
	if Input.is_action_just_pressed("dash") and can_dash:
		state_machine.change_state("DashPrepare")

	if Input.is_action_just_pressed("invisibility") and can_go_invisible:
		_enter_invisibility()

# --- Public Helper Functions (Called by States) ---

func enter_jump_state():
	coyote_timer.stop()
	fall_zoom_timer.stop()
	set_standing_collision()
	velocity.y = stats.jump_velocity
	current_jumps += 1

func wall_jump(wall_normal_override: Vector2 = Vector2.ZERO):
	wall_stick_timer.stop()
	wall_coyote_timer.stop()
	
	var wall_normal = wall_normal_override if wall_normal_override != Vector2.ZERO else get_wall_normal()
	
	if Input.is_action_pressed("shift") and can_wall_stick:
		velocity.y = stats.wall_stick_jump_vertical_velocity
		velocity.x = wall_normal.x * stats.wall_stick_jump_horizontal_velocity
	else:
		velocity.y = stats.wall_slide_jump_vertical_velocity
		velocity.x = wall_normal.x * stats.wall_slide_jump_horizontal_velocity

	can_wall_stick = true
	current_jumps = 1
# Spawn a burst of particles
	if dust_puff_scene:
		var puff = dust_puff_scene.instantiate()
		get_tree().root.add_child(puff)
		var wall_offset = get_wall_normal() * -15
		puff.global_position = get_node("WallSlideSpawner").global_position + wall_offset
		
func _start_wall_coyote_time():
	last_wall_normal = get_wall_normal()
	wall_coyote_timer.start(stats.wall_coyote_time_duration)
	wall_detach_timer.start(stats.wall_detach_hang_time)
	can_wall_stick = true
	fall_zoom_timer.start(stats.fall_zoom_delay)

func is_head_clear() -> bool:
	return not head_clearance_ray.is_colliding()

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

func _enter_invisibility():
	is_invisible = true
	can_go_invisible = false
	invisibility_timer.start(stats.invisibility_duration)
	invisibility_cooldown_timer.start(stats.invisibility_cooldown)
	animated_sprite.modulate.a = 0.5

# --- Timer Callbacks ---

func _on_dash_timer_timeout():
	# If the timer runs out normally, do the cleanup...
	end_dash()
	# ...and then transition to the FallingState.
	state_machine.change_state("Falling")

func _on_dash_cooldown_timer_timeout():
	can_dash = true

func _on_wall_stick_timer_timeout():
	if state_machine.current_state.name == "WallStickingState":
		state_machine.change_state("OnWall")

func _on_crouch_timer_timeout():
	is_jump_charged = true

func _on_coyote_timer_timeout():
	if current_jumps == 0:
		current_jumps = 1

func _on_jump_buffer_timer_timeout():
	jump_buffered = false

func _on_dash_freeze_timer_timeout():
	state_machine.change_state("Dashing")
	var dash_direction = Vector2(1 if not animated_sprite.flip_h else -1, 0)
	vfx.play_dash_effects()
	velocity.x = dash_direction.x * DASH_SPEED
	velocity.y = 0
	dash_timer.start(DASH_DURATION)

func _on_invisibility_timer_timeout():
	is_invisible = false
	animated_sprite.modulate.a = 1.0

func _on_invisibility_cooldown_timer_timeout():
	can_go_invisible = true

func _on_land_timer_timeout():
	if state_machine.current_state.name == "LandingState":
		state_machine.change_state("Idle")

func _on_fall_zoom_timer_timeout():
	if not is_on_floor():
		is_long_fall = true
		# Announce that a long fall has begun.
		long_fall_started.emit()

func _on_wall_slip_timer_timeout():
	if state_machine.current_state.name == "WallSlipState":
		state_machine.change_state("WallSticking")

func _on_skid_timer_timeout():
	if state_machine.current_state.name == "SkiddingState":
		state_machine.change_state("Running")

func _on_wall_coyote_timer_timeout():
	pass

func _on_slide_timer_timeout():
	if state_machine.current_state.name == "SlidingState":
		if is_head_clear():
			if Input.is_action_pressed("down"):
				state_machine.change_state("Crouching")
			else:
				state_machine.change_state("Idle")
		else:
			state_machine.change_state("Crouching")

func _on_wall_detach_timer_timeout():
	if state_machine.current_state.name == "WallDetachState":
		state_machine.change_state("Falling")


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_gameplay_active: return

	if event.is_action_pressed("interact_world"):
		EventBus.interaction_started.emit()
	elif event.is_action_released("interact_world"):
		EventBus.interaction_cancelled.emit()
		
func end_dash() -> void:
	# Don't do anything if we aren't actually in the DashingState.
	if state_machine.current_state.name != "DashingState":
		return

	# Perform all cleanup.
	vfx.stop_dash_effects()
	dash_cooldown_timer.start(DASH_COOLDOWN)
	
	
func _on_state_changed(new_state_name: String) -> void:
	# Check if the new state is a valid move that can extend a combo.
	if new_state_name in COMBO_STATES:
		# Any valid combo move stops the "on ground" reset timer.
		combo_reset_timer.stop()
		
		# To be a valid combo link, the move must be unique.
		if not new_state_name in _combo_chain:
			_add_move_to_combo(new_state_name)
			
	# If the player is idle or running, start the timer to reset the combo.
	elif new_state_name in ["Idle", "Running"]:
		combo_reset_timer.start(1.5)


# This function handles adding a move and checking for success.
func _add_move_to_combo(move_name: String) -> void:
	# Restart the 1-second timer for the next move in the chain.
	combo_timer.start(1.0)
	_combo_chain.append(move_name)
	
	print("Combo Chain: ", _combo_chain) # For debugging

	# Check for a successful 3-move combo.
	if _combo_chain.size() >= 3:
		EventBus.flow_combo_success.emit()
		print("--- FLOW COMBO SUCCESS! ---") # For debugging


# This function resets the combo chain.
func _reset_combo() -> void:
	if not _combo_chain.is_empty():
		_combo_chain.clear()
		print("Combo Reset.") # For debugging


# This timer fires if there's >1 second between combo moves.
func _on_combo_timer_timeout() -> void:
	_reset_combo()


# This timer fires if the player is on the ground for >1.5 seconds.
func _on_combo_reset_timer_timeout() -> void:
	_reset_combo()
# This function allows other nodes, like the camera, to safely
# ask the player what it's currently doing.
func get_current_state_name() -> String:
	if state_machine and is_instance_valid(state_machine.current_state):
		# We return the name of the state's node, e.g., "OnWallState"
		return state_machine.current_state.name
	return ""
