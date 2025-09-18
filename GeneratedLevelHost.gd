# res://Levels/GeneratedLevelHost.gd
extends Node2D

signal level_generated

var spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# _ready() cannot be async, so we call a separate async function to do the work.
	_build_level_and_emit_signal()


func _build_level_and_emit_signal() -> void:
	# First, we must 'await' the generator since it is a coroutine.
	var generated_level: Node2D = await LevelGenerator.generate_level()
	add_child(generated_level)

	# Find the spawn point within the newly created level.
	var spawn_point_node = generated_level.find_child("PlayerSpawnPoint", true, false)
	if is_instance_valid(spawn_point_node):
		spawn_position = spawn_point_node.global_position
	else:
		Loggie.error("Generated level is missing a PlayerSpawnPoint node!", "proc_gen")
		# Failsafe to prevent crash
		spawn_position = generated_level.global_position

	# Wait for one process frame. This is a safety measure to ensure
	# all nodes in the generated level are fully registered in the scene tree.
	await get_tree().process_frame

	# Now it's safe to announce that the level is ready.
	level_generated.emit()
