extends CharacterBody2D
class_name Npc


@export var sprite_frames: SpriteFrames
@export var animation: StringName = &"default"
@export var dialogue: DialogueResource
@export var start_node: StringName = &"start"


var player_in_range: bool = false
var dialogue_balloon: Node


@onready var interaction_label: Label = %InteractionLabel
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D"):
	set(value):
		animated_sprite = value
		if animated_sprite:
			animated_sprite.material = load("res://resources/shaders/outline_material.tres").duplicate_deep()
			animated_sprite.material.set("shader_parameter/outline_color",Color.WHITE)
			animated_sprite.material.set("shader_parameter/width",0)
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D"):
	set(value):
		sprite = value
		if sprite:
			sprite.material = load("res://resources/shaders/outline_material.tres").duplicate_deep()
			sprite.material.set("shader_parameter/outline_color",Color.WHITE)
			sprite.material.set("shader_parameter/width",0)


func _ready() -> void:
	$Area2D.player_entered.connect(_on_player_entered)
	$Area2D.player_exited.connect(_on_player_exited)
	animated_sprite = animated_sprite
	sprite = sprite


func _process(_delta: float) -> void:
	if !player_in_range:
		return

	if is_instance_valid(dialogue_balloon):
		return

	if Input.is_action_just_pressed("interact"):
		dialogue_balloon = DialogueManager.show_dialogue_balloon(dialogue, start_node)


func _on_player_entered(_player) -> void:
	if animated_sprite:
		animated_sprite.material.set("shader_parameter/width",1)
	if sprite:
		sprite.material.set("shader_parameter/width",1)
	interaction_label.show()
	player_in_range = true


func _on_player_exited(_player) -> void:
	if animated_sprite:
		animated_sprite.material.set("shader_parameter/width",0)
	if sprite:
		sprite.material.set("shader_parameter/width",0)
	interaction_label.hide()
	player_in_range = false
