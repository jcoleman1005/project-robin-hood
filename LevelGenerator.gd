# res://Singletons/LevelGenerator.gd
extends Node2D

const CHUNK_DATA_PATH = "res://Levels/Chunks/data"

@export_group("Generator Settings")
@export_range(2, 50) var min_length: int = 5
@export_range(2, 50) var max_length: int = 8
@export_range(0.0, 1.0) var stealth_chunk_chance: float = 0.25
@export_range(0.0, 1.0) var verticality_chance: float = 0.3 ## NEW: Chance to build up/down instead of sideways.
@export_range(0.0, 1.0) var reverse_direction_chance: float = 0.2 ## NEW: Chance to place a 'U-turn' transition chunk.

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

# ... (_ready, _process, _draw, _load_all_chunk_data functions are the same) ...
func _ready():
	_load_all_chunk_data()
func _process(_delta: float) -> void:
	if DebugManager.show_chunk_boundaries and is_instance_valid(_level_root):
		queue_redraw()
func _draw() -> void:
	if not DebugManager.show_chunk_boundaries or not is_instance_valid(_level_root):
		return
	for chunk in _level_root.get_children():
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
	last_chunk = _add_random_chunk(_level_root, ChunkData.Category.START, last_chunk)
	
	for i in range(length):
		if not is_instance_valid(last_chunk.instance):
			DebugManager.print_proc_gen_log("ERROR: Halting generation...")
			break

		var category_to_spawn: int
		# NEW: Decide whether to build vertically, horizontally, or reverse direction
		if randf() < verticality_chance:
			category_to_spawn = ChunkData.Category.VERTICAL_TRAVERSAL
		elif randf() < reverse_direction_chance:
			category_to_spawn = ChunkData.Category.TRANSITION
		elif randf() < stealth_chunk_chance:
			category_to_spawn = ChunkData.Category.STEALTH
		else:
			category_to_spawn = ChunkData.Category.TRAVERSAL
		
		var next_chunk = _add_random_chunk(_level_root, category_to_spawn, last_chunk)
		
		# If we failed to find a chunk for our first choice (e.g., no vertical chunks were compatible),
		# fall back to a standard traversal chunk.
		if not is_instance_valid(next_chunk.instance):
			DebugManager.print_proc_gen_log("... Falling back to TRAVERSAL chunk.")
			next_chunk = _add_random_chunk(_level_root, ChunkData.Category.TRAVERSAL, last_chunk)
		
		last_chunk = next_chunk

	if is_instance_valid(last_chunk.instance):
		_add_random_chunk(_level_root, ChunkData.Category.END, last_chunk)
	
	DebugManager.print_proc_gen_log("--- Level Generation Complete ---")
	return _level_root

func _get_compatible_tag(exit_tag: String) -> String:
	# Expanded to handle more tag types
	if exit_tag.ends_with("_right"): return exit_tag.replace("_right", "_left")
	if exit_tag.ends_with("_left"): return exit_tag.replace("_left", "_right")
	if exit_tag.ends_with("_top"): return exit_tag.replace("_top", "_bottom")
	if exit_tag.ends_with("_bottom"): return exit_tag.replace("_bottom", "_top")
	return "none"

func _add_random_chunk(parent: Node, category: int, previous_chunk: Dictionary) -> Dictionary:
	# ... (This function's internal logic remains the same as the last corrected version) ...
	var all_chunks_in_category: Array[ChunkData] = _chunks_by_category.get(category, [])
	var compatible_chunks: Array[ChunkData] = []
	if previous_chunk.data == null:
		compatible_chunks = all_chunks_in_category
	else:
		var required_entry_tag = _get_compatible_tag(previous_chunk.data.exit_tag)
		DebugManager.print_proc_gen_log("... Seeking [%s] chunk with entry tag: <%s>" % [ChunkData.Category.keys()[category], required_entry_tag])
		for chunk_data in all_chunks_in_category:
			if chunk_data.entry_tag == required_entry_tag:
				compatible_chunks.append(chunk_data)
	if compatible_chunks.is_empty():
		DebugManager.print_proc_gen_log("WARNING: No compatible chunks found for category: " + ChunkData.Category.keys()[category])
		return {"instance": previous_chunk.instance, "data": previous_chunk.data} # Return previous chunk to allow fallback
	var chosen_chunk_data: ChunkData = compatible_chunks.pick_random()
	var chunk_instance = chosen_chunk_data.chunk_scene.instantiate()
	var category_name_str = ChunkData.Category.keys()[category]
	var scene_path = chosen_chunk_data.chunk_scene.resource_path
	var log_message = "Placing [%s] chunk: %s | Entry: <%s> | Exit: <%s>" % [category_name_str, scene_path.get_file(), chosen_chunk_data.entry_tag, chosen_chunk_data.exit_tag]
	DebugManager.print_proc_gen_log(log_message)
	chunk_instance.name = chosen_chunk_data.chunk_scene.resource_path.get_file().get_basename() + "_" + str(randi())
	parent.add_child(chunk_instance)
	if is_instance_valid(previous_chunk.instance):
		var previous_exit_marker = previous_chunk.instance.get_node_or_null("exit")
		if not is_instance_valid(previous_exit_marker): return {"instance": null, "data": null} # Previous chunk must have an exit
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
