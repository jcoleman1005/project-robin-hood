# res://Levels/PCG_Testbed.gd
extends Node2D

@onready var _button: Button = $Button
var _generated_level: Node2D = null

func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if is_instance_valid(_generated_level):
		_generated_level.queue_free()
		
	# FIX: Call the function on the global LevelGenerator instance, not the class.
	_generated_level = await LevelGenerator.generate_level()
	add_child(_generated_level)
