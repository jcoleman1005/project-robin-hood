# res://Singletons/SceneEntry.gd
# This is a custom Resource script. It simply acts as a data container
# to hold a key-value pair for our scene management system.
# The Godot editor's Inspector understands resources, so it will let us
# edit these properties visually.

class_name SceneEntry
extends Resource

@export var key: String = ""
@export var scene: PackedScene
