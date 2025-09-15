# res://Singletons/LevelGenerator.gd
extends Node2D

const CHUNK_DATA_PATH = "res://Levels/Chunks/data"

@export_group("Generator Settings")
@export_range(2, 50) var min_length: int = 5
@export_range(2, 50) var max_length: int = 8
@export_range(0.0, 1.0) var stealth_chunk_chance: float = 0.25
@export_range(0.0, 1.0) var verticality_chance: float = 0.3
@export_range(0.0, 1.0) var reverse_direction_chance: float = 0.2
@export var min_chunks_between_dashes: int = 2

@export_group("Scene Dependencies")
@export var camera_boundary_scene: PackedScene ## Assign CameraBoundary.tscn here
@export var kill_zone_scene: PackedScene       ## Assign KillZone.tscn here

var _chunks_by_category: Dictionary = {
	ChunkData.Category.START: [] as Array[ChunkData],
	ChunkData.Category.END: [] as Array[ChunkData],
	ChunkData.Category.TRAVERSAL: [] as Array[ChunkData],
	ChunkData.Category.STEALTH: [] as Array[ChunkData],
	ChunkData.Category.TRANSITION: [] as Array[ChunkData],
	ChunkData.Category.SECRET: [] as Array[ChunkData],
	ChunkData.Category.VERTICAL_TRAVERSAL: [] as Array[ChunkData],
}
var _level_root: Node2D = null
@onready var _debug_font = load("res://UserInterface/8bitlimr.ttf")

func _ready() -> void:
	_load_all_chunk_data()

func _process(_delta: float) -> void:
	if DebugManager.show_chunk_boundaries and is_instance_valid(_level_root):
		queue_redraw()

func _draw() -> void:
	if not DebugManager.show_chunk_boundaries or not is_instance_valid(_level_root):
		return
	for chunk in _level_root.get_children():
		if not chunk is Node2D: continue
		var entry: Marker2D = chunk.get_node_or_null("entry")
		if is_instance_valid(entry):
			draw_circle(entry.global_position, 8, Color.RED)
			draw_string(_debug_font, entry.global_position + Vector2(10, 0), "ENTRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.RED)
		var exit: Marker2D = chunk.get_node_or_null("exit")
		if is_instance_valid(exit):
			draw_circle(exit.global_position, 8, Color.BLUE)
			draw_string(_debug_font, exit.global_position + Vector2(10, 0), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLUE)

func _load_all_chunk_data() -> void:
	var dir = DirAccess.open(CHUNK_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var chunk_data: ChunkData = load(CHUNK_DATA_PATH.path_join(file_name))
				if is_instance_valid(chunk_data):
					_chunks_by_category[chunk_data.category].append(chunk_data)
			file_name = dir.get_next()
	else:
		DebugManager.print_proc_gen_log("ERROR: Could not open chunk data path: " + CHUNK_DATA_PATH)

func generate_level() -> Node2D:
	if is_instance_valid(_level_root):
		_level_root.queue_free()
		
	_level_root = Node2D.new()
	_level_root.name = "GeneratedLevel"
	
	var length = randi_range(min_length, max_length)
	DebugManager.print_proc_gen_log("--- Starting Level Generation (Length: %d) ---" % length)
	
	var last_chunk: Dictionary = {"instance": null, "data": null}
	var chunks_since_last_dash = min_chunks_between_dashes
	
	last_chunk = _add_random_chunk(_level_root, ChunkData.Category.START, last_chunk, chunks_since_last_dash)
	if is_instance_valid(last_chunk.data) and last_chunk.data.requires_dash:
		chunks_since_last_dash = 0
	
	for i in range(length):
		if not is_instance_valid(last_chunk.instance):
			DebugManager.print_proc_gen_log("ERROR: Halting generation...")
			break
		var category_to_spawn: int
		if randf() < verticality_chance:
			category_to_spawn = ChunkData.Category.VERTICAL_TRAVERSAL
		elif randf() < reverse_direction_chance:
			category_to_spawn = ChunkData.Category.TRANSITION
		elif randf() < stealth_chunk_chance:
			category_to_spawn = ChunkData.Category.STEALTH
		else:
			category_to_spawn = ChunkData.Category.TRAVERSAL
		var next_chunk = _add_random_chunk(_level_root, category_to_spawn, last_chunk, chunks_since_last_dash)
		if not is_instance_valid(next_chunk.instance):
			DebugManager.print_proc_gen_log("... Falling back to TRAVERSAL chunk.")
			next_chunk = _add_random_chunk(_level_root, ChunkData.Category.TRAVERSAL, last_chunk, chunks_since_last_dash)
		last_chunk = next_chunk
		if is_instance_valid(last_chunk.data):
			if last_chunk.data.requires_dash:
				chunks_since_last_dash = 0
			else:
				chunks_since_last_dash += 1
	if is_instance_valid(last_chunk.instance):
		_add_random_chunk(_level_root, ChunkData.Category.END, last_chunk, chunks_since_last_dash)
	
	# Add boundaries after all chunks are placed.
	# The await ensures that all chunks have been added and positioned before we calculate bounds.
	await get_tree().process_frame
	var level_bounds = _calculate_level_bounds(_level_root)
	if level_bounds.size != Vector2.ZERO:
		_add_camera_boundary(_level_root, level_bounds)
		_add_killzone(_level_root, level_bounds)
	
	DebugManager.print_proc_gen_log("--- Level Generation Complete ---")
	return _level_root

func _get_compatible_tag(exit_tag: String) -> String:
	if exit_tag.ends_with("_right"): return exit_tag.replace("_right", "_left")
	if exit_tag.ends_with("_left"): return exit_tag.replace("_left", "_right")
	if exit_tag.ends_with("_top"): return exit_tag.replace("_top", "_bottom")
	if exit_tag.ends_with("_bottom"): return exit_tag.replace("_bottom", "_top")
	return "none"

func _add_random_chunk(parent: Node, category: int, previous_chunk: Dictionary, chunks_since_last_dash: int) -> Dictionary:
	var all_chunks_in_category: Array[ChunkData] = _chunks_by_category.get(category, [])
	var compatible_chunks: Array[ChunkData] = []
	if previous_chunk.data == null:
		compatible_chunks = all_chunks_in_category
	else:
		var required_entry_tag = _get_compatible_tag(previous_chunk.data.exit_tag)
		var log_msg = "... Seeking [%s] chunk with entry tag: <%s>" % [ChunkData.Category.keys()[category], required_entry_tag]
		if chunks_since_last_dash < min_chunks_between_dashes:
			log_msg += " (Excluding Dash Chunks)"
		DebugManager.print_proc_gen_log(log_msg)
		for chunk_data in all_chunks_in_category:
			if chunk_data.entry_tag == required_entry_tag:
				if chunk_data.requires_dash and chunks_since_last_dash < min_chunks_between_dashes:
					continue
				compatible_chunks.append(chunk_data)
	if compatible_chunks.is_empty():
		DebugManager.print_proc_gen_log("WARNING: No compatible chunks found for category: " + ChunkData.Category.keys()[category])
		return {"instance": previous_chunk.instance, "data": previous_chunk.data}
	var chosen_chunk_data: ChunkData = compatible_chunks.pick_random()
	var chunk_instance = chosen_chunk_data.chunk_scene.instantiate()
	var category_name_str = ChunkData.Category.keys()[category]
	var scene_path = chosen_chunk_data.chunk_scene.resource_path
	var log_message = "Placing [%s] chunk: %s | Entry: <%s> | Exit: <%s>" % [category_name_str, scene_path.get_file(), chosen_chunk_data.entry_tag, chosen_chunk_data.exit_tag]
	if chosen_chunk_data.requires_dash: log_message += " [REQUIRES DASH]"
	DebugManager.print_proc_gen_log(log_message)
	chunk_instance.name = chosen_chunk_data.chunk_scene.resource_path.get_file().get_basename() + "_" + str(randi())
	parent.add_child(chunk_instance)
	if is_instance_valid(previous_chunk.instance):
		var previous_exit_marker = previous_chunk.instance.get_node_or_null("exit")
		if not is_instance_valid(previous_exit_marker): return {"instance": null, "data": null}
		var entry_marker: Marker2D = chunk_instance.get_node_or_null("entry")
		if not is_instance_valid(entry_marker):
			DebugManager.print_proc_gen_log("ERROR: Chunk " + scene_path + " is missing an 'entry' marker.")
			chunk_instance.queue_free()
			return {"instance": null, "data": null}
		chunk_instance.global_position = previous_exit_marker.global_position - entry_marker.position
		var align_log = "... Alignment: Prev Exit at %s, New Entry at %s" % [previous_exit_marker.global_position.round(), entry_marker.global_position.round()]
		DebugManager.print_proc_gen_log(align_log)
	if chosen_chunk_data.exit_tag == "none":
		return {"instance": chunk_instance, "data": null}
	return {"instance": chunk_instance, "data": chosen_chunk_data}

func _calculate_level_bounds(level_node: Node2D) -> Rect2:
	var combined_rect: Rect2
	var first = true
	for chunk in level_node.get_children():
		# CORRECTED: Use our new helper function to find the TileMap by type.
		var tilemap = _find_child_by_type(chunk, "TileMap") as TileMap
		if is_instance_valid(tilemap):
			var used_rect = tilemap.get_used_rect()
			var global_pos_start = tilemap.to_global(tilemap.map_to_local(used_rect.position))
			var global_pos_end = tilemap.to_global(tilemap.map_to_local(used_rect.end))
			var rect_global = Rect2(global_pos_start, (global_pos_end - global_pos_start))
			if first:
				combined_rect = rect_global
				first = false
			else:
				combined_rect = combined_rect.merge(rect_global)
	return combined_rect

func _add_camera_boundary(level_node: Node2D, bounds: Rect2) -> void:
	if not is_instance_valid(camera_boundary_scene): return
	var boundary = camera_boundary_scene.instantiate()
	level_node.add_child(boundary)
	var shape = RectangleShape2D.new()
	var padded_bounds = bounds.grow(100) # Add padding
	shape.size = padded_bounds.size
	var collision_shape = boundary.get_node("CollisionShape2D")
	collision_shape.shape = shape
	boundary.global_position = padded_bounds.position
	DebugManager.print_proc_gen_log("Added CameraBoundary at %s with size %s" % [padded_bounds.position.round(), padded_bounds.size.round()])

func _add_killzone(level_node: Node2D, bounds: Rect2) -> void:
	if not is_instance_valid(kill_zone_scene): return
	var killzone = kill_zone_scene.instantiate()
	level_node.add_child(killzone)
	var shape = RectangleShape2D.new()
	shape.size = Vector2(bounds.size.x + 2000, 200) 
	var collision_shape = killzone.get_node("CollisionShape2D")
	collision_shape.shape = shape
	killzone.global_position = Vector2(bounds.get_center().x - shape.size.x / 2, bounds.end.y + 200)
	DebugManager.print_proc_gen_log("Added KillZone below level.")

# NEW: A robust helper function to find a child by its class type.
func _find_child_by_type(node: Node, type: String) -> Node:
	for child in node.get_children():
		if child.get_class() == type:
			return child
		# Recurse to check children of children
		var found = _find_child_by_type(child, type)
		if is_instance_valid(found):
			return found
	return null
