extends CharacterBody2D

# A signal to announce when the player has been hit.
signal player_hit
signal player_detected

@export_group("Movement")
@export var speed: float = 50.0
@export var direction: int = 1 # 1 for right, -1 for left

@export_group("Detection")
@export var detection_time: float = 1.5
@export var vision_cone_normal_color: Color = Color(1, 1, 0, 0.2)
@export var vision_cone_alert_color: Color = Color(1, 0, 0, 0.3)
@export var detection_meter_scene: PackedScene

# --- Private Variables ---
var player_in_cone = null
var detection_progress: float = 0.0
var detection_meter # A variable to hold our instanced detection meter.

# --- Node References ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox_area = $HitboxArea
@onready var raycasts = $Raycasts
@onready var ledge_check_ray = $Raycasts/LedgeCheckRay
@onready var wall_check_ray = $Raycasts/WallCheckRay
@onready var turn_cooldown_timer = $TurnCooldownTimer
@onready var vision_cone_area = $VisionConeArea
@onready var vision_cone_polygon = $VisionConePolygon
@onready var line_of_sight_ray = $LineOfSightRay

func _ready():
	# Connect the hitbox area's signal to our script.
	hitbox_area.body_entered.connect(_on_hitbox_area_body_entered)
	vision_cone_area.body_entered.connect(_on_vision_cone_area_body_entered)
	vision_cone_area.body_exited.connect(_on_vision_cone_area_body_exited)
	
	# Set the initial color of the vision cone.
	if is_instance_valid(vision_cone_polygon):
		vision_cone_polygon.color = vision_cone_normal_color

	# Create an instance of the detection meter and add it to the scene.
	if detection_meter_scene:
		detection_meter = detection_meter_scene.instantiate()
		add_child(detection_meter)
		# Position it above the guard's head. You may need to adjust this value.
		detection_meter.position = Vector2(0, -40)

func _physics_process(delta):
	# Flip the sprite and the patrol raycasts to match the current direction.
	animated_sprite.flip_h = (direction < 0)
	raycasts.scale.x = direction
	
	# Flip the vision cone as well.
	if is_instance_valid(vision_cone_area):
		vision_cone_area.scale.x = direction
	if is_instance_valid(vision_cone_polygon):
		vision_cone_polygon.scale.x = direction

	animated_sprite.play("walk")
		
	# Check for ledges or walls and turn around if needed.
	if is_on_floor() and turn_cooldown_timer.is_stopped():
		if not ledge_check_ray.is_colliding():
			_turn_around()
		elif wall_check_ray.is_colliding():
			_turn_around()
	
	# Apply gravity so the guard stays grounded.
	if not is_on_floor():
		velocity.y += 980 * delta

	# Calculate horizontal velocity *after* the turn decision has been made.
	velocity.x = speed * direction
	
	move_and_slide()
	
	_handle_detection(delta)

func _turn_around():
	direction *= -1 # Flip the direction
	turn_cooldown_timer.start(0.2) # Start a brief cooldown to prevent glitching

func _handle_detection(delta):
	if not is_instance_valid(vision_cone_polygon): return

	var is_player_visible = false
	if is_instance_valid(player_in_cone) and not player_in_cone.is_invisible:
		var target_position = player_in_cone.global_position
		var target_point_node = player_in_cone.get_node_or_null("TargetPoint")
		if is_instance_valid(target_point_node):
			target_position = target_point_node.global_position

		line_of_sight_ray.target_position = line_of_sight_ray.to_local(target_position)
		line_of_sight_ray.force_raycast_update()
		
		if line_of_sight_ray.get_collider() == player_in_cone:
			is_player_visible = true

	if is_player_visible:
		detection_progress += delta / detection_time
	else:
		detection_progress -= delta / detection_time
	
	detection_progress = clamp(detection_progress, 0, 1)

	vision_cone_polygon.color = vision_cone_normal_color.lerp(vision_cone_alert_color, detection_progress)

	if detection_progress >= 1:
		## This is the change! We now emit a signal instead of calling the player.
		emit_signal("player_detected")
# --- Signal Callbacks ---

func _on_hitbox_area_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("on_player_hit"):
			body.call_deferred("on_player_hit")

func _on_vision_cone_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_cone = body

func _on_vision_cone_area_body_exited(body):
	if body == player_in_cone:
		player_in_cone = null
