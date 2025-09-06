# res://Enemies/Guard/Guard.gd
extends CharacterBody2D

@export_group("Stats")
@export var speed: float = 50.0
@export var hearing_range: float = 300.0

# --- Public State ---
# These variables can be accessed and modified by the state scripts.
var direction: int = 1
var last_known_sound_position: Vector2

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycasts: Node2D = $Raycasts
@onready var ledge_check_ray: RayCast2D = $Raycasts/LedgeCheckRay 
@onready var wall_check_ray: RayCast2D = $Raycasts/WallCheckRay
@onready var turn_cooldown_timer: Timer = $TurnCooldownTimer
@onready var state_machine: GuardStateMachine = $StateMachine
@onready var suspicion_timer: Timer = $SuspicionTimer
# A reference to the custom vision cone component.
@onready var vision_cone_area: Area2D = $VisionConeArea


func _ready() -> void:
	# Connect to the vision cone's signal to know when the player is seen.
	vision_cone_area.body_entered.connect(_on_body_entered)
	# Connect to the global event bus to hear sounds.
	EventBus.sound_created.connect(_on_sound_created)
	
	# Initialize the state machine on the first frame.
	state_machine.initialize.call_deferred()


func _physics_process(delta: float) -> void:
	# Delegate all per-frame logic to the current active state.
	state_machine._physics_process(delta)
	
	# Apply gravity if the guard is in the air.
	if not is_on_floor():
		velocity.y += 980 * delta
	
	move_and_slide()


## Flips the guard's direction and visual components.
func turn_around() -> void:
	direction *= -1
	turn_cooldown_timer.start(0.2)# --- Signal Callbacks ---

## Called when a body enters our custom vision cone's Area2D.
func _on_body_entered(body: Node) -> void:
	# If it's the player, immediately switch to the alert state.
	if body.is_in_group("player"):
		state_machine.change_state("AlertState")


# --- Event Bus Handler ---

## Called when any sound is made in the game.
func _on_sound_created(sound_position: Vector2, sound_range: float) -> void:
	# Ignore sounds if we are already fully alerted.
	if state_machine.current_state.name == "AlertState":
		return

	# Check if the sound is within our hearing range.
	var distance_to_sound = global_position.distance_to(position)
	if distance_to_sound < hearing_range + sound_range:
		last_known_sound_position = position
		# Switch to the suspicious state to investigate the sound.
		state_machine.change_state("SuspiciousState")
