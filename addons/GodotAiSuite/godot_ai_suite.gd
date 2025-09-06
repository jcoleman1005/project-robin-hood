# res://addons/GodotAiSuite/godot_ai_suite.gd

@tool
extends EditorPlugin

# --- UI Elements ---
var suite_container: HBoxContainer = HBoxContainer.new() # The main container for the toolbar UI
var settings_button: Button = Button.new()
var prompts_button: Button = Button.new() # Button for the prompt library
var export_button: Button = Button.new()
var settings_window: AcceptDialog = AcceptDialog.new()
var _prompt_library_instance: Window # The instance of our new scene

# --- Settings Window UI ---
var _tab_container: TabContainer
var include_system_prompt_button: CheckButton = CheckButton.new()
var include_gdd_button: CheckButton = CheckButton.new()
var include_devlog_button: CheckButton = CheckButton.new()
var include_project_settings_button: CheckButton = CheckButton.new()
var include_resources_button: CheckButton = CheckButton.new()
var include_scenes_button: CheckButton = CheckButton.new()
var include_code_button: CheckButton = CheckButton.new()
# New UI elements for exclusion trees
var _scene_exclusion_tree: Tree
var _script_exclusion_tree: Tree
var _total_tokens_label: Label

# --- Internal State for Token Counts ---
var _system_prompt_token_count: int = 0
var _gdd_token_count: int = 0
var _devlog_token_count: int = 0
var _project_settings_token_count: int = 0
var _resources_token_count: int = 0

# --- Constants ---
const PROMPT_LIBRARY_SCENE = preload("res://addons/GodotAiSuite/prompt_library/prompt_library.tscn")
const PROMPT_LIBRARY_ICON: Texture2D = preload("res://addons/GodotAiSuite/assets/prompt_library_icon.png")
const SYSTEM_PROMPT_FILE_PATH: String = "res://addons/GodotAiSuite/system_prompt.txt"
const DEVLOG_FILE_PATH: String = "res://addons/GodotAiSuite/DevLog.txt"
const GDD_FILE_PATH: String =  "res://addons/GodotAiSuite/GDD.txt"
const OUTPUT_FILE_PATH: String = "res://addons/GodotAiSuite/Masterprompt.txt"
const SETTINGS_FILE_PATH: String = "res://addons/GodotAiSuite/settings.cfg"
# Token Ratios
const TOKEN_RATIO_TEXT: float = 0.25   # For prose-like text (GDD, DevLog)
const TOKEN_RATIO_SCRIPT: float = 0.303 # For GDScript, C#, Shaders
const TOKEN_RATIO_SCENE: float = 0.4125 # For TSCN, TRES, and other structured data

# --- Add file paths here to exclude them from the export ---
const IGNORED_FILE_PATHS: Array[String] = [
	"res://addons/GodotAiSuite/godot_ai_suite.gd",
	"res://addons/GodotAiSuite/prompt_library/prompt_library.gd",
	"res://addons/GodotAiSuite/prompt_library/prompt_library.tscn"
	]
# --- Add property names here to exclude them from the scene export ---
const IGNORED_PROPERTIES: Array[String] = [
	"tile_map_data"
]


# --- EditorPlugin Overrides ---
func _enter_tree() -> void:
	# --- Create Toolbar UI ---
	var suite_label: Label = Label.new()
	suite_label.text = "Godot AI Suite:"
	suite_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	settings_button.icon = EditorInterface.get_editor_theme().get_icon("Tools", "EditorIcons")
	settings_button.tooltip_text = "Godot AI Suite Settings"
	settings_button.pressed.connect(_on_settings_button_pressed)

	prompts_button.icon = PROMPT_LIBRARY_ICON
	prompts_button.tooltip_text = "Prompt Library"
	prompts_button.pressed.connect(_on_prompts_button_pressed)
	
	export_button.text = "Generate Masterprompt"
	export_button.pressed.connect(_on_export_button_pressed)

	# Add all controls to the main container
	suite_container.add_child(suite_label)
	suite_container.add_child(VSeparator.new())
	suite_container.add_child(settings_button)
	suite_container.add_child(prompts_button)
	suite_container.add_child(export_button)
	
	add_control_to_container(CONTAINER_TOOLBAR, suite_container)

	_create_settings_window()
	
	# --- Instantiate Windows ---
	_prompt_library_instance = PROMPT_LIBRARY_SCENE.instantiate()
	get_editor_interface().get_base_control().add_child(_prompt_library_instance)
	
	_load_settings()


func _exit_tree() -> void:
	# Clean up the main container (which also frees its children)
	remove_control_from_container(CONTAINER_TOOLBAR, suite_container)
	suite_container.queue_free()
	
	# Clean up the windows
	if settings_window and is_instance_valid(settings_window):
		settings_window.queue_free()
	if _prompt_library_instance and is_instance_valid(_prompt_library_instance):
		_prompt_library_instance.queue_free()


# --- UI Creation ---
func _create_settings_window() -> void:
	settings_window.title = "Godot AI Suite Settings"
	settings_window.ok_button_text = "Close"
	settings_window.size = Vector2i(700, 500)
	
	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_window.add_child(main_vbox)

	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_tab_container)
	
	# --- General Tab ---
	var general_vbox: VBoxContainer = VBoxContainer.new()
	general_vbox.add_theme_constant_override("separation", 10)
	general_vbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	var general_margin: MarginContainer = MarginContainer.new()
	general_margin.name = "General"
	general_margin.add_theme_constant_override("margin_left", 10)
	general_margin.add_theme_constant_override("margin_top", 10)
	general_margin.add_theme_constant_override("margin_right", 10)
	general_margin.add_theme_constant_override("margin_bottom", 10)
	general_margin.add_child(general_vbox)
	_tab_container.add_child(general_margin)
	
	include_system_prompt_button.toggled.connect(_on_setting_changed)
	general_vbox.add_child(include_system_prompt_button)
	general_vbox.add_child(HSeparator.new())
	include_gdd_button.toggled.connect(_on_setting_changed)
	general_vbox.add_child(include_gdd_button)
	include_devlog_button.toggled.connect(_on_setting_changed)
	general_vbox.add_child(include_devlog_button)
	general_vbox.add_child(HSeparator.new())
	include_project_settings_button.toggled.connect(_on_setting_changed)
	general_vbox.add_child(include_project_settings_button)
	include_resources_button.toggled.connect(_on_setting_changed)
	general_vbox.add_child(include_resources_button)
	include_scenes_button.toggled.connect(_on_setting_changed)
	general_vbox.add_child(include_scenes_button)
	include_code_button.toggled.connect(_on_setting_changed)
	general_vbox.add_child(include_code_button)

	# --- Scene Exclusions Tab ---
	var scene_tab_result: Dictionary = _create_file_exclusion_tab("Scene Exclusions", ["tscn"])
	_scene_exclusion_tree = scene_tab_result.tree
	_tab_container.add_child(scene_tab_result.container)
	
	# --- Script Exclusions Tab ---
	var script_tab_result: Dictionary = _create_file_exclusion_tab("Script Exclusions", ["gd", "cs"])
	_script_exclusion_tree = script_tab_result.tree
	_tab_container.add_child(script_tab_result.container)
	
	# --- Total Tokens Label ---
	main_vbox.add_child(HSeparator.new())
	_total_tokens_label = Label.new()
	_total_tokens_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var token_margin := MarginContainer.new()
	token_margin.add_theme_constant_override("margin_right", 10)
	token_margin.add_child(_total_tokens_label)
	main_vbox.add_child(token_margin)
	
	get_editor_interface().get_base_control().add_child(settings_window)
	
	_update_category_token_counts()


func _create_file_exclusion_tab(p_title: String, p_extensions: Array[String]) -> Dictionary:
	var vbox: VBoxContainer = VBoxContainer.new()
	
	var margin: MarginContainer = MarginContainer.new()
	margin.name = p_title
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(vbox)

	var hbox: HBoxContainer = HBoxContainer.new()
	var select_all_button: Button = Button.new()
	select_all_button.text = "Select All"
	var select_none_button: Button = Button.new()
	select_none_button.text = "Deselect All"
	hbox.add_child(select_all_button)
	hbox.add_child(select_none_button)
	vbox.add_child(hbox)
	
	var tree: Tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.hide_root = true
	tree.set_columns(1)
	tree.set_column_title(0, "File")
	tree.set_column_clip_content(0, true)
	vbox.add_child(tree)
	
	select_all_button.pressed.connect(_on_select_all_pressed.bind(tree))
	select_none_button.pressed.connect(_on_select_none_pressed.bind(tree))
	tree.item_edited.connect(_on_file_selection_changed)
	
	# Populate the tree with files matching the extensions
	_populate_file_tree(tree, p_extensions)

	return { "container": margin, "tree": tree }


func _populate_file_tree(p_tree: Tree, p_extensions: Array[String]) -> void:
	var root: TreeItem = p_tree.create_item()
	var files: Array = _find_files_by_extension(p_extensions)
	
	var valid_files: Array = files.filter(func(p): return not p in IGNORED_FILE_PATHS)

	for file_path in valid_files:
		var item: TreeItem = p_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_checked(0, true)
		
		var file_content: String
		var ratio: float
		var extension: String = file_path.get_extension()
		
		if extension == "tscn":
			ratio = TOKEN_RATIO_SCENE
			var scene_res: Resource = load(file_path)
			if scene_res:
				var scene_node: Node = scene_res.instantiate()
				file_content = _get_node_data(scene_node, 0, scene_node)
				scene_node.free()
		else: # Script files
			ratio = TOKEN_RATIO_SCRIPT
			file_content = FileAccess.get_file_as_string(file_path)

		var token_count: int = _calculate_tokens(file_content.length(), ratio)
		
		item.set_text(0, "%s (~%d tokens)" % [file_path, token_count])
		item.set_metadata(0, { "path": file_path, "tokens": token_count })


# --- Signal Handlers ---
func _on_settings_button_pressed() -> void:
	settings_window.popup_centered()

func _on_prompts_button_pressed() -> void:
	if _prompt_library_instance:
		_prompt_library_instance.popup_library()

func _on_setting_changed(_is_toggled: bool) -> void:
	_save_settings()
	_update_ui_and_token_counts()
	
func _on_file_selection_changed() -> void:
	_save_settings()
	_update_ui_and_token_counts()

func _on_select_all_pressed(p_tree: Tree) -> void:
	_set_all_tree_items_checked(p_tree, true)

func _on_select_none_pressed(p_tree: Tree) -> void:
	_set_all_tree_items_checked(p_tree, false)
	
func _set_all_tree_items_checked(p_tree: Tree, p_checked: bool) -> void:
	var root: TreeItem = p_tree.get_root()
	if not root: return
	
	var item: TreeItem = root.get_first_child()
	while item:
		item.set_checked(0, p_checked)
		item = item.get_next()
	
	_save_settings()
	_update_ui_and_token_counts()

# --- Settings Persistence ---
func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("General", "include_system_prompt", include_system_prompt_button.button_pressed)
	config.set_value("General", "include_gdd", include_gdd_button.button_pressed)
	config.set_value("General", "include_devlog", include_devlog_button.button_pressed)
	config.set_value("General", "include_project_settings", include_project_settings_button.button_pressed)
	config.set_value("General", "include_resources", include_resources_button.button_pressed)
	config.set_value("General", "include_scenes", include_scenes_button.button_pressed)
	config.set_value("General", "include_code", include_code_button.button_pressed)
	
	# Save exclusion lists
	config.set_value("Exclusions", "excluded_scenes", _get_excluded_files_from_tree(_scene_exclusion_tree))
	config.set_value("Exclusions", "excluded_scripts", _get_excluded_files_from_tree(_script_exclusion_tree))
	
	config.save(SETTINGS_FILE_PATH)

func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_FILE_PATH) != OK:
		# If no config file, set all to default (true) and save
		include_system_prompt_button.button_pressed = true
		include_gdd_button.button_pressed = true
		include_devlog_button.button_pressed = true
		include_project_settings_button.button_pressed = true
		include_resources_button.button_pressed = true
		include_scenes_button.button_pressed = true
		include_code_button.button_pressed = true
		_save_settings()
	else:
		# Load from config file
		include_system_prompt_button.button_pressed = config.get_value("General", "include_system_prompt", true)
		include_gdd_button.button_pressed = config.get_value("General", "include_gdd", true)
		include_devlog_button.button_pressed = config.get_value("General", "include_devlog", true)
		include_project_settings_button.button_pressed = config.get_value("General", "include_project_settings", true)
		include_resources_button.button_pressed = config.get_value("General", "include_resources", true)
		include_scenes_button.button_pressed = config.get_value("General", "include_scenes", true)
		include_code_button.button_pressed = config.get_value("General", "include_code", true)

		# Load exclusion lists and apply them to the trees
		var excluded_scenes: Array[String] = config.get_value("Exclusions", "excluded_scenes", []) as Array[String]
		var excluded_scripts: Array[String] = config.get_value("Exclusions", "excluded_scripts", []) as Array[String]
		_apply_exclusions_to_tree(_scene_exclusion_tree, excluded_scenes)
		_apply_exclusions_to_tree(_script_exclusion_tree, excluded_scripts)

	_update_ui_and_token_counts()

func _apply_exclusions_to_tree(p_tree: Tree, p_exclusions: Array[String]) -> void:
	if not p_tree or p_exclusions.is_empty(): return
	var root: TreeItem = p_tree.get_root()
	if not root: return
	
	var item: TreeItem = root.get_first_child()
	while item:
		var metadata: Dictionary = item.get_metadata(0)
		if metadata.has("path") and metadata.path in p_exclusions:
			item.set_checked(0, false)
		item = item.get_next()


# --- Core Export Logic ---
func _on_export_button_pressed() -> void:
	# --- PREPARATION ---
	var heading_numbers: Dictionary = {}
	var main_heading_counter: int = 5 if include_system_prompt_button.button_pressed else 1
	var is_any_data_included: bool = (include_gdd_button.button_pressed and FileAccess.file_exists(GDD_FILE_PATH)) or \
								(include_devlog_button.button_pressed and FileAccess.file_exists(DEVLOG_FILE_PATH)) or \
								include_project_settings_button.button_pressed or \
								include_resources_button.button_pressed or \
								include_scenes_button.button_pressed or \
								include_code_button.button_pressed
	
	var excluded_files: Array[String] = _get_excluded_files_from_tree(_scene_exclusion_tree) + \
										_get_excluded_files_from_tree(_script_exclusion_tree)
	var final_ignored_paths: Array[String] = IGNORED_FILE_PATHS + excluded_files
	
	# --- PASS 1: PRE-CALCULATE ALL HEADING NUMBERS ---
	if is_any_data_included:
		heading_numbers["specification"] = str(main_heading_counter); main_heading_counter += 1

	if include_gdd_button.button_pressed and FileAccess.file_exists(GDD_FILE_PATH):
		heading_numbers["gdd"] = str(main_heading_counter); main_heading_counter += 1
	
	if include_devlog_button.button_pressed and FileAccess.file_exists(DEVLOG_FILE_PATH):
		heading_numbers["devlog"] = str(main_heading_counter); main_heading_counter += 1

	var is_project_context_included: bool = include_project_settings_button.button_pressed or \
									  include_resources_button.button_pressed or \
									  include_scenes_button.button_pressed or \
									  include_code_button.button_pressed

	if is_project_context_included:
		var project_context_number: int = main_heading_counter
		heading_numbers["project_context"] = str(project_context_number); main_heading_counter += 1
		var sub_heading_counter: int = 1
		
		if include_project_settings_button.button_pressed:
			heading_numbers["project_settings"] = "%d.%d" % [project_context_number, sub_heading_counter]; sub_heading_counter += 1
		if include_resources_button.button_pressed:
			heading_numbers["resources"] = "%d.%d" % [project_context_number, sub_heading_counter]; sub_heading_counter += 1
		if include_scenes_button.button_pressed:
			heading_numbers["scenes"] = "%d.%d" % [project_context_number, sub_heading_counter]; sub_heading_counter += 1
		if include_code_button.button_pressed:
			heading_numbers["code"] = "%d.%d" % [project_context_number, sub_heading_counter]; sub_heading_counter += 1

	if include_system_prompt_button.button_pressed:
		heading_numbers["initial_task"] = str(main_heading_counter)

	# --- PASS 2: GENERATE OUTPUT ---
	var output: String = ""
	
	if include_system_prompt_button.button_pressed:
		if not FileAccess.file_exists(SYSTEM_PROMPT_FILE_PATH):
			OS.alert("System prompt file not found! Please create a file at:\n%s" % SYSTEM_PROMPT_FILE_PATH, "Export Error"); return
		output += FileAccess.get_file_as_string(SYSTEM_PROMPT_FILE_PATH) + "\n"

	if is_any_data_included:
		var context_spec: String = "### **%s. Project Context Specification**\n\n" % heading_numbers.specification
		context_spec += "You will be provided with a comprehensive dump of the Godot project context, structured as follows. You must parse, understand, and use this context to inform all your responses.\n\n"
		if heading_numbers.has("gdd"): context_spec += "*   **`%s. GDD`**: The Game Design Document.\n" % heading_numbers.gdd
		if heading_numbers.has("devlog"): context_spec += "*   **`%s. DevLog`**: A log of implemented features and changes.\n" % heading_numbers.devlog
		if heading_numbers.has("project_context"):
			context_spec += "*   **`%s. Project Context`**: The technical project dump, including:\n" % heading_numbers.project_context
			if heading_numbers.has("project_settings"): context_spec += "    *   `%s. Project Settings`\n" % heading_numbers.project_settings
			if heading_numbers.has("resources"): context_spec += "    *   `%s. Resource Files`\n" % heading_numbers.resources
			if heading_numbers.has("scenes"): context_spec += "    *   `%s. Scene Structures`\n" % heading_numbers.scenes
			if heading_numbers.has("code"): context_spec += "    *   `%s. Codebase`\n" % heading_numbers.code
		output += context_spec + "\n---\n"

	if include_gdd_button.button_pressed and heading_numbers.has("gdd"):
		output += "### **%s. GDD**\n\n" % heading_numbers.gdd
		output += FileAccess.get_file_as_string(GDD_FILE_PATH) + "\n---\n"

	if include_devlog_button.button_pressed and heading_numbers.has("devlog"):
		output += "### **%s. DevLog**\n\n" % heading_numbers.devlog
		output += FileAccess.get_file_as_string(DEVLOG_FILE_PATH) + "\n---\n"

	if is_project_context_included:
		var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene")
		if main_scene_path.is_empty(): OS.alert("No main scene configured in Project Settings.", "Export Error"); return
		
		output += "### **%s. Project Context**\n\n" % heading_numbers.project_context
		
		if include_project_settings_button.button_pressed and heading_numbers.has("project_settings"):
			output += "#### **%s. Project Settings**\n\n" % heading_numbers.project_settings
			output += "--- START OF PROJECT SETTINGS ---\n" + FileAccess.get_file_as_string("res://project.godot").rstrip(" \n") + "\n--- END OF PROJECT SETTINGS ---\n\n"
		
		if include_resources_button.button_pressed and heading_numbers.has("resources"):
			output += "#### **%s. Resource Files**\n\n" % heading_numbers.resources
			var files: Array = _find_files_by_extension(["tres", "gdshader"])
			var blocks: Array = files.filter(func(p): return not p in final_ignored_paths).map(func(p): return "--- RESOURCE: %s ---\n" % p + FileAccess.get_file_as_string(p).rstrip(" \n"))
			output += "--- START OF RESOURCE FILES ---\n" + "\n\n".join(blocks) + ("\n" if not blocks.is_empty() else "") + "--- END OF RESOURCE FILES ---\n\n"

		if include_scenes_button.button_pressed and heading_numbers.has("scenes"):
			output += "#### **%s. Scene Structures**\n\n" % heading_numbers.scenes
			var files: Array = _find_files_by_extension(["tscn"])
			var blocks: Array = []
			for file_path in files.filter(func(p): return not p in final_ignored_paths):
				var block: String = "--- SCENE: %s ---\n" % file_path
				var scene_res: Resource = load(file_path)
				if scene_res: var scene_node: Node = scene_res.instantiate(); block += _get_node_data(scene_node, 0, scene_node).rstrip(" \n"); scene_node.free()
				blocks.append(block)
			output += "--- START OF SCENE STRUCTURES ---\n" + "\n\n".join(blocks) + ("\n" if not blocks.is_empty() else "") + "--- END OF SCENE STRUCTURES ---\n\n"
			
		if include_code_button.button_pressed and heading_numbers.has("code"):
			output += "#### **%s. Codebase**\n\n" % heading_numbers.code
			var files: Array = _find_files_by_extension(["gd", "cs"])
			var blocks: Array = files.filter(func(p): return not p in final_ignored_paths).map(func(p): return "--- SCRIPT: %s ---\n" % p + FileAccess.get_file_as_string(p).rstrip(" \n"))
			output += "--- START OF CODEBASE ---\n" + "\n\n".join(blocks) + ("\n" if not blocks.is_empty() else "") + "--- END OF CODEBASE ---\n"

		if output.ends_with("\n---\n"): pass
		else: output += "\n---\n"

	if include_system_prompt_button.button_pressed and heading_numbers.has("initial_task"):
		output += "\n### **%s. Initial Task**\n" % heading_numbers.initial_task
		output += "Your first and most important task is to ingest and fully understand all project information contained in this prompt and the subsequent data dump. Once you have processed everything, confirm with a simple message that you understand the project's current state and are ready for development tasks\n"

	var file: FileAccess = FileAccess.open(OUTPUT_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(output.lstrip("\n"))
		file.close()
		var dialog: ConfirmationDialog = ConfirmationDialog.new(); dialog.title = "Export Successful"; dialog.dialog_text = "Project context exported to:\n%s" % OUTPUT_FILE_PATH; dialog.ok_button_text = "Open Folder"; dialog.get_cancel_button().text = "Close"
		dialog.confirmed.connect(_open_output_folder); dialog.confirmed.connect(dialog.queue_free); dialog.canceled.connect(dialog.queue_free)
		get_editor_interface().get_base_control().add_child(dialog)
		dialog.popup_centered()
	else:
		OS.alert("Failed to open file for writing at %s." % OUTPUT_FILE_PATH, "Export Error")

# --- Helper Functions ---
func _open_output_folder() -> void:
	var absolute_file_path: String = ProjectSettings.globalize_path(OUTPUT_FILE_PATH)
	OS.shell_show_in_file_manager(absolute_file_path)

func _calculate_tokens(p_content_length: int, p_ratio: float) -> int:
	return ceili(float(p_content_length) * p_ratio)

func _update_category_token_counts() -> void:
	# System Prompt
	if FileAccess.file_exists(SYSTEM_PROMPT_FILE_PATH):
		_system_prompt_token_count = _calculate_tokens(FileAccess.get_file_as_string(SYSTEM_PROMPT_FILE_PATH).length(), TOKEN_RATIO_TEXT)

	# GDD
	if FileAccess.file_exists(GDD_FILE_PATH):
		_gdd_token_count = _calculate_tokens(FileAccess.get_file_as_string(GDD_FILE_PATH).length(), TOKEN_RATIO_TEXT)
	include_gdd_button.text = "Include GDD.txt (~%d tokens)" % _gdd_token_count

	# DevLog
	if FileAccess.file_exists(DEVLOG_FILE_PATH):
		_devlog_token_count = _calculate_tokens(FileAccess.get_file_as_string(DEVLOG_FILE_PATH).length(), TOKEN_RATIO_TEXT)
	include_devlog_button.text = "Include DevLog.txt (~%d tokens)" % _devlog_token_count

	# Project Settings
	if FileAccess.file_exists("res://project.godot"):
		_project_settings_token_count = _calculate_tokens(FileAccess.get_file_as_string("res://project.godot").length(), TOKEN_RATIO_SCENE)
	include_project_settings_button.text = "Include Project Settings (~%d tokens)" % _project_settings_token_count
	
	# Resources
	_resources_token_count = 0
	var resource_files: Array = _find_files_by_extension(["tres", "gdshader"])
	for file_path in resource_files:
		var ratio: float = TOKEN_RATIO_SCRIPT if file_path.get_extension() == "gdshader" else TOKEN_RATIO_SCENE
		var content_length: int = FileAccess.get_file_as_string(file_path).length()
		_resources_token_count += _calculate_tokens(content_length, ratio)
	include_resources_button.text = "Include Resource Files (.tres, .gdshader) (~%d tokens)" % _resources_token_count
	
func _get_excluded_files_from_tree(p_tree: Tree) -> Array[String]:
	var excluded_files: Array[String] = []
	if not p_tree: return excluded_files
	
	var root: TreeItem = p_tree.get_root()
	if not root: return excluded_files

	var item: TreeItem = root.get_first_child()
	while item:
		if not item.is_checked(0):
			var metadata: Dictionary = item.get_metadata(0)
			if metadata.has("path"):
				excluded_files.append(metadata.path)
		item = item.get_next()
	return excluded_files

func _update_ui_and_token_counts() -> void:
	if not is_instance_valid(_total_tokens_label): return
		
	# Update Scene and Codebase labels on the General tab
	var selected_scene_tokens: int = _get_checked_token_sum_from_tree(_scene_exclusion_tree)
	var excluded_scene_count: int = _get_unchecked_item_count_from_tree(_scene_exclusion_tree)
	var scene_label: String = "Include Scene Structures (.tscn) (~%d tokens selected" % selected_scene_tokens
	if excluded_scene_count > 0:
		scene_label += ", %d files excluded)" % excluded_scene_count
	else:
		scene_label += ")"
	include_scenes_button.text = scene_label
	
	var selected_code_tokens: int = _get_checked_token_sum_from_tree(_script_exclusion_tree)
	var excluded_code_count: int = _get_unchecked_item_count_from_tree(_script_exclusion_tree)
	var code_label: String = "Include Codebase (.gd, .cs) (~%d tokens selected" % selected_code_tokens
	if excluded_code_count > 0:
		code_label += ", %d files excluded)" % excluded_code_count
	else:
		code_label += ")"
	include_code_button.text = code_label
	
	# Update System Prompt label
	include_system_prompt_button.text = "Include System Prompt (~%d tokens)" % _system_prompt_token_count

	# Disable/Enable tabs
	_tab_container.set_tab_disabled(1, not include_scenes_button.button_pressed) # Scene tab is at index 1
	_tab_container.set_tab_disabled(2, not include_code_button.button_pressed)   # Code tab is at index 2
	
	# Calculate grand total
	var total_tokens: int = 0
	if include_system_prompt_button.button_pressed: total_tokens += _system_prompt_token_count
	if include_gdd_button.button_pressed: total_tokens += _gdd_token_count
	if include_devlog_button.button_pressed: total_tokens += _devlog_token_count
	if include_project_settings_button.button_pressed: total_tokens += _project_settings_token_count
	if include_resources_button.button_pressed: total_tokens += _resources_token_count
	if include_scenes_button.button_pressed: total_tokens += selected_scene_tokens
	if include_code_button.button_pressed: total_tokens += selected_code_tokens
	
	_total_tokens_label.text = "Estimated Final Export Tokens: ~%d" % total_tokens

func _get_checked_token_sum_from_tree(p_tree: Tree) -> int:
	var token_sum: int = 0
	if not p_tree: return token_sum
	
	var root: TreeItem = p_tree.get_root()
	if not root: return token_sum

	var item: TreeItem = root.get_first_child()
	while item:
		if item.is_checked(0):
			var metadata: Dictionary = item.get_metadata(0)
			if metadata.has("tokens"):
				token_sum += metadata.tokens
		item = item.get_next()
	return token_sum

func _get_unchecked_item_count_from_tree(p_tree: Tree) -> int:
	var count: int = 0
	if not p_tree: return count
	
	var root: TreeItem = p_tree.get_root()
	if not root: return count

	var item: TreeItem = root.get_first_child()
	while item:
		if not item.is_checked(0):
			count += 1
		item = item.get_next()
	return count

func _find_files_by_extension(extensions: Array) -> Array:
	var files: Array = []
	var dir: DirAccess = DirAccess.open("res://")
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != ".." and file_name != ".godot": _recursive_find(dir.get_current_dir().path_join(file_name), extensions, files)
			elif not dir.current_is_dir():
				for ext in extensions:
					if file_name.ends_with("." + ext): files.append(dir.get_current_dir().path_join(file_name))
			file_name = dir.get_next()
	return files

func _recursive_find(path: String, extensions: Array, files: Array) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..": _recursive_find(path.path_join(file_name), extensions, files)
			elif not dir.current_is_dir():
				for ext in extensions:
					if file_name.ends_with("." + ext): files.append(path.path_join(file_name))
			file_name = dir.get_next()

func _value_to_string(value) -> String:
	if value is String: return '"' + value.c_escape() + '"'
	if value is Resource:
		if value.resource_path.is_empty() and not value.resource_name.is_empty():
			var scene_path: String = "res://<UNKNOWN>"
			if get_tree() and get_tree().edited_scene_root: scene_path = get_tree().edited_scene_root.scene_file_path
			return "%s::%s" % [scene_path, value.resource_name]
		return value.resource_path
	if value is Dictionary or value is Array: return JSON.stringify(value, "", false)
	return str(value)

func _get_node_data(node: Node, indent_level: int, scene_root: Node) -> String:
	var indent_str: String = ""
	if indent_level > 0: indent_str = "> " + "  ".repeat(indent_level - 1)
	var node_info: String = "%s%s (%s)\n" % [indent_str, node.name, node.get_class()]
	var details_indent: String = "> " + "  ".repeat(indent_level)
	if node.get_script() and node.get_script() is Script:
		var script_path: String = node.get_script().get_path()
		if not script_path.is_empty(): node_info += "%sscript: %s\n" % [details_indent, script_path]
	if not node.scene_file_path.is_empty(): node_info += "%sscene: %s\n" % [details_indent, node.scene_file_path]
	var groups: Array = node.get_groups()
	if not groups.is_empty(): node_info += "%sgroups = %s\n" % [details_indent, str(groups)]
	var prop_info: String = ""
	var default_node: Node = ClassDB.instantiate(node.get_class())
	if default_node:
		for prop in node.get_property_list():
			var prop_name: String = prop.name
			if not (prop.usage & PROPERTY_USAGE_STORAGE): continue
			if prop_name.begins_with("script") or prop_name.contains("/") or prop_name.begins_with("editable_children"): continue
			if prop_name in IGNORED_PROPERTIES: continue
			var current_value = node.get(prop_name)
			var default_value = default_node.get(prop_name)
			if not _are_values_equal(current_value, default_value):
				var prop_value_str: String = _value_to_string(current_value)
				prop_info += "%s> %s = %s\n" % [indent_str, prop_name, prop_value_str]
		default_node.free()
	node_info += prop_info
	for child in node.get_children(): node_info += _get_node_data(child, indent_level + 1, scene_root)
	return node_info

func _are_values_equal(a, b) -> bool:
	if typeof(a) != typeof(b):
		if (typeof(a) == TYPE_INT and typeof(b) == TYPE_FLOAT) or (typeof(a) == TYPE_FLOAT and typeof(b) == TYPE_INT):
			return is_equal_approx(float(a), float(b))
		return false
	if a is float: return is_equal_approx(a, b)
	if a is Vector2 or a is Vector3 or a is Color: return a.is_equal_approx(b)
	if a is Resource and b is Resource:
		if a.resource_path.is_empty() or b.resource_path.is_empty(): return a == b
		return a.resource_path == b.resource_path
	return a == b
