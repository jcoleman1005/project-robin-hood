# res://Levels/GeneratedLevelHost.gd
extends Node2D

signal level_generated

func _ready() -> void:
	# _ready() cannot be async, so we call a separate async function to do the work.
	_build_level_and_emit_signal()

func _build_level_and_emit_signal() -> void:
	# First, we must 'await' the generator since it is a coroutine.
	var generated_level = await LevelGenerator.generate_level()
	add_child(generated_level)
	
	# NEW: Wait for one process frame. This is a safety measure to ensure
	# all nodes in the generated level are fully registered in the scene tree.
	await get_tree().process_frame
	
	# Now it's safe to announce that the level is ready.
	level_generated.emit()
