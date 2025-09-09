# res://Interactables/Chest/Chest.gd
extends StaticBody2D

@export var gold_amount: int = 10
@export var floating_text_scene: PackedScene
@export var text_spawn_offset: Vector2 = Vector2(0, -20)

var _is_opened := false
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _interactable: Interactable = $InteractionArea


func _ready() -> void:
	# The parent connects to its child's 'interacted' signal.
	_interactable.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	if _is_opened:
		return
	_is_opened = true
	
	animated_sprite.play("open")
	await animated_sprite.animation_finished
	
	EventBus.gold_collected.emit(gold_amount)
	
	if floating_text_scene:
		var floating_text_instance = floating_text_scene.instantiate()
		get_tree().current_scene.add_child(floating_text_instance)
		floating_text_instance.global_position = self.global_position + text_spawn_offset
		floating_text_instance.show_text("+%d Gold" % gold_amount)
	
	queue_free()
