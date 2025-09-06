GODOT AI SUITE

A powerful plugin to streamline your AI-assisted game development workflow in Godot.

This plugin generates a comprehensive Masterprompt.txt file, providing your chosen AI agent with all the necessary context about your project. This enables you to get tailored, easy-to-follow development instructions for your current project state.
A growing prompt library provides an easy way to access many useful prompts to generate and evaluate ideas, refactor your project and more.

Why use the Godot AI Suite?

- Save Time: Instead of manually explaining your project to an AI, generate a detailed context file in one click.
- Get Better AI Assistance: Provide a rich context, including your Game Design Document (GDD), development logs, project settings, scene structures, and full codebase, to get more accurate and relevant responses from your AI assistant.
- Streamline Your Workflow: The plugin integrates smoothly into your development process, helping you maintain a detailed log of your progress and seamlessly transition between coding and AI-driven guidance.
- Switch Agents at any time: Change Agents or open a new chat anytime, without losing context. Just press a single button.

---

FEATURES

Masterprompt Exporter:
One-Click Export: A simple button to export the entire Godot project as context.
- Comprehensive Context: The Masterprompt.txt includes:
	- Your Game Design Document (GDD.txt).
	- A development log (DevLog.txt) to track implemented features.
	- Your project's settings (project.godot).
	- Detailed scene structures, including nodes, properties, and signals.
	- Your entire GDScript and C# codebase.
- Customizable: You can fine-tune the initial prompt and exclude specific files or properties from the export.
- Export Settings: Choose what parts of the project context should be exportet
- AI-Model Ready: The generated prompt is designed to work well with powerful AI models like Gemini 2.5 Pro.

Prompt library:
A growing library of useful prompts for AI Game Development
- find a prompt by category or name.
- copy to clipboard with one click.

---

HOW TO USE

Initial Setup:

1. Copy the "GodotAiSuite" folder to your Godot project res://addons/GodotAiSuite
2. Click on Project -> Project Settings -> Plugins -> Enable GodotAiSuite
3. Save and Reload your project: Click on Project -> Reload Current Project
4. Add Your GDD: Copy and paste your Game Design Document into the GDD.txt file.
5. (Optional) Customize the Masterprompt: You can edit the masterprompt_template.txt to better suit your needs or target developer profile. The default is set for a solo indie developer with intermediate Godot knowledge.

Workflow:

1. Generate Masterprompt: Click the "Generate Masterprompt" button at the top-right of the Godot editor.
2. Consult Your AI: Drag and Drop your the generated Masterprompt.txt as the context into your AI agent.
3. Implement and Commit: After a feature is implemented, ask the AI to "write a commit." Copy the result into DevLog.txt and use it as your commit message in Git.
4. Iterate: Continue the process in the same AI chat or start a new one with an updated Masterprompt for new features.


GODOT AI SUITE SETTINGS:

1. Click the Godot AI Suite settings button at the top-right of the Godot editor
2. Select wich parts of the project context to include in the output

---

TROUBLESHOOTING AND BEST PRACTICES

- Handling Errors: If you encounter bugs, copy the error message, script name, and line number and feed it back to the AI. It can often provide a fix.
- Guiding the AI: If the AI struggles, provide hints like "this seems like a race condition" or "you need to modify x.gd." Pointing out incorrect syntax (e.g., "that is not Godot 4.4 syntax!") can also help.
- Dealing with Hallucinations: If the AI gives nonsensical or irrelevant answers, it's best to start a fresh chat with the latest Masterprompt.txt.

---

CONFIGURATION

You can customize the plugin's output by editing the godot_ai_suite.gd script:

- Ignoring Files: To exclude certain files from the export, add their paths to the IGNORED_FILE_PATHS array.
- Ignoring Properties: To exclude specific node properties from the scene export, add their names to the IGNORED_PROPERTIES array. This is particularly useful for very large properties like tile_map_data.

---

VERSION HISTORY

1.0 Initial release
1.01 Added .cs export
1.1 Added export settings
1.2 Added prompt library
1.3 Enhanced Export settings
