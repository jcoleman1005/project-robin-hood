# res://Enemies/Guard/Guard.gd
extends CharacterBody2D

@export var speed: float = 50.0

@export_group("Visuals")
@export var vision_cone_neutral_color: Color = Color(1, 1, 1, 0.2)
@export var vision_cone_suspicious_color: Color = Color(1, 1, 0, 0.25)
@export var vision_cone_alert_color: Color = Color(1, 0, 0, 0.3)

var direction: int = 1
var is_player_in_cone: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ledge_check_ray: RayCast2D = $LedgeCheckRay
@onready var wall_check_ray: RayCast2D = $WallCheckRay
@onready var ground_check_ray: RayCast2D = $GroundCheckRay # ADD THIS LINE
@onready var turn_cooldown_timer: Timer = $TurnCooldownTimer
@onready var state_machine = $StateMachine
@onready var vision_cone_area: Area2D = $VisionCone2D/VisionConeArea
@onready var vision_cone_renderer: Polygon2D = $VisionCone2D/VisionConeRenderer


func _ready() -> void:
	vision_cone_area.body_entered.connect(_on_vision_cone_body_entered)
	vision_cone_area.body_exited.connect(_on_vision_cone_body_exited)
	state_machine.call_deferred("initialize")


func _physics_process(delta: float) -> void:
	if state_machine.current_state:
		state_machine.current_state.process_physics(delta)
	
	move_and_slide()


func turn_around() -> void:
	direction *= -1
	turn_cooldown_timer.start(0.2)


func _on_vision_cone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_cone = true


func _on_vision_cone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_cone = false
