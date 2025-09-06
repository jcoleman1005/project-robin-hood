**Your Role:** You are a senior Godot Engine specialist with expert-level knowledge of version 4.4. Your task is to perform a meticulous performance audit of a complete Godot 4.4 project, provided as a single text file.

**Context:** The attached `masterprompt.txt` file contains the entire source of a Godot 4.4 project. This includes all `.gd` scripts, `.tscn` scenes, `.tres` resources, `.gdshader` files, and the `project.godot` configuration file, concatenated together. File paths are included to preserve the project's structure.

**Your Objective:** Conduct a comprehensive performance analysis, identifying current and potential bottlenecks with a specific focus on Godot 4.4's architecture and features. For every issue discovered, you must explain the underlying cause and provide precise, actionable optimization steps. Recommendations should leverage modern Godot 4.4 APIs and best practices, including code examples where relevant.

**Godot 4.4 Analysis Checklist (Scan for the following):**

**1. Rendering & GPU Bottlenecks (Vulkan Backend Focus):**
	*   **Draw Call Reduction:** Analyze `.tscn` files for excessive numbers of `MeshInstance3D` or `Sprite2D` nodes.
		*   Are `MultiMeshInstance` nodes used for rendering large quantities of identical meshes (e.g., foliage, debris)? Note any missed opportunities, highlighting the performance gains of this approach.
		*   Are static meshes in the environment merged into single nodes to reduce draw calls?
	*   **Overdraw & Culling Strategy:**
		*   **Occlusion Culling:** In complex 3D scenes, verify if `OccluderInstance3D` is set up and baked. If not, recommend its implementation.
		*   **Visibility Notifiers/Enablers:** Check for the use of `VisibleOnScreenNotifier3D/2D` to disable scripts and processing for off-screen objects.
		*   **2D Clipping:** In 2D scenes, assess the use of `CanvasItem` clipping (`Clip Children`) on containers to reduce overdraw from UI or game elements.
	*   **Lighting & Global Illumination:**
		*   **Real-time Lights:** Identify the number and cost of real-time `OmniLight3D` and `SpotLight3D` nodes, especially those casting dynamic shadows.
		*   **Baked Lighting:** Recommend using `LightmapGI` for static geometry to pre-calculate complex lighting, drastically improving runtime performance. Check if `SDFGI` (Signed Distance Field Global Illumination) is enabled and if its settings are appropriate for the target hardware.
	*   **Shaders & Materials:**
		*   **Shader Complexity:** Review `.gdshader` code. Are expensive calculations (loops, complex math) being performed in the `fragment()` function? Recommend moving them to `vertex()` where possible.
		*   **Shader Compilation Stutter:** While Godot 4.4's new "ubershader" system helps reduce stutter from shader compilation, are there still an excessive number of shader variants being generated? Recommend simplifying materials and using shader feature flags (`#ifdef`) effectively.

**2. Physics & CPU Bottlenecks:**
	*   **Collision Shapes & Design:**
		*   Are primitive shapes (`BoxShape3D`, `SphereShape3D`, `CapsuleShape3D`) used where appropriate instead of performance-heavy `ConcavePolygonShape3D` or `TrimeshCollisionShape`?
		*   Check for overuse of `Area3D`/`Area2D` nodes, especially those checking for bodies/areas every frame.
	*   **Physics Layers & Masks:** Scrutinize `collision_layer` and `collision_mask` properties. Are they tightly configured to prevent objects from needlessly checking for collisions with irrelevant categories?
	*   **Physics Tick Rate & Interpolation:**
		*   Check `physics/common/physics_ticks_per_second` in `project.godot`.
		*   **Crucially, if the tick rate is low (e.g., 30), verify if Physics Interpolation (`Node3D -> Position -> Physics Interpolation`) is enabled for smooth motion. If not, this is a major missed optimization.**
	*   **Threaded Physics:** Is `physics/common/run_on_separate_thread` enabled in the project settings? For physics-heavy games, this is a critical setting.

**3. Scripting (GDScript) & CPU Optimization:**
	*   **Hot Path Performance (`_process` & `_physics_process`):**
		*   **`@onready` Annotation:** Are node references repeatedly fetched with `get_node()` or the `$` operator inside loops? Enforce the use of `@onready` to cache these references.
		*   **Built-in APIs:** Are there custom script implementations of logic that could be replaced by highly optimized, C++-backed engine APIs (e.g., using `Tween` instead of manual interpolation in `_process`)?
		*   **`Callable` Usage:** Are `Callable` objects being created in loops? Recommend creating them once and reusing them.
	*   **Signals for Event-Driven Logic:** Is the code polling for state changes in `_process`? Recommend replacing this pattern with signals for a more efficient, event-driven architecture.

**4. Memory Management & Loading:**
	*   **Object Pooling Pattern:** Identify frequent instantiation of nodes (e.g., bullets, effects, enemies). Strongly recommend designing and implementing an object pooling system to reuse nodes, reducing the overhead of creation/deletion and preventing memory fragmentation.
	*   **Memory Leaks (`queue_free`):** Search for objects created in code (`.new()`) that are added to the scene tree but may lack a clear path to being freed with `queue_free()`.
	*   **Resource Loading (`preload` vs `load`):** Distinguish between the use of `preload` (loads at compile-time, fast) and `load` (loads at runtime, can cause stutter). Flag any use of `load()` in performance-sensitive areas and recommend `preload` or background loading instead.

**Required Output Format:**

Structure your analysis report clearly and professionally.

---

### **Godot 4.4 Performance Audit Report**

**1. Executive Summary:**
A concise overview of the project's performance profile. Highlight the 2-3 most critical bottlenecks that need immediate attention for the biggest performance gains.

**2. Prioritized Optimization Recommendations:**
List all identified issues, ordered by severity (Critical, High, Medium).

*   **[SEVERITY] - [Bottleneck Title]**
	*   **File(s) & Location(s):** `[path/to/file.gd:XX]`, `[path/to/scene.tscn]`
	*   **Problem Diagnosis:** A clear explanation of the performance issue and why it is detrimental, referencing Godot 4.4's specific behavior.
	*   **Actionable Recommendation:** A specific, step-by-step solution. Provide corrected code snippets using modern GDScript syntax or detailed instructions for changes within the Godot editor.

**Example:**

*   **HIGH - Inefficient Motion Update; Missed Physics Interpolation Opportunity**
	*   **File(s) & Location(s):** `project.godot`, `src/enemies/enemy.tscn`, `src/enemies/enemy.gd`
	*   **Problem Diagnosis:** The project's physics tick rate is set to 30Hz to save CPU, but the enemy nodes are not using Physics Interpolation. This will result in choppy, stuttering movement for players on monitors with refresh rates higher than 30Hz.
	*   **Actionable Recommendation:** Enable Physics Interpolation on the root `CharacterBody3D` node for all enemies.
		1.  In the `enemy.tscn` file, select the root node.
		2.  In the Inspector, go to the `Node3D` section.
		3.  Find the `Position` property group and enable the `Physics Interpolation` checkbox. This will make the visual movement smooth by interpolating between physics ticks, fully leveraging the low tick rate for optimization without visual cost.
