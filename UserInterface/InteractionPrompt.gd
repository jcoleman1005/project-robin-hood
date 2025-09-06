# InteractionPrompt.gd
extends Node2D

# --- Node References ---
@onready var label: Label = $Label
@onready var prompt_position: Marker2D = $PromptPosition

# --- Private Variables ---
var parent_node: Node2D

func _ready():
	# Hide by default.
	hide()
	# Ensure the label is set to not filter, so it stays crisp.
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Get a reference to the parent (the Chest, Prisoner, etc.).
	parent_node = get_parent()


func _process(_delta):
	# If the parent object is invalid (e.g., has been freed), do nothing.
	if not is_instance_valid(parent_node):
		return

	# Get the main camera to account for its position and zoom.
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	# Calculate the target position in the game world.
	# This is the parent's position plus our offset.
	var world_position = parent_node.global_position + prompt_position.position
	
	# Convert the world position to a screen position.
	# This accounts for camera scrolling.
	var screen_position = camera.get_transform().affine_inverse().translated(world_position)
	
	# Apply the camera's zoom to the position.
	label.global_position = screen_position * camera.get_zoom()


## Public function to show the prompt with a specific message.
func show_prompt(message: String):
	label.text = message
	show()


## Public function to hide the prompt.
func hide_prompt():
	hide()
