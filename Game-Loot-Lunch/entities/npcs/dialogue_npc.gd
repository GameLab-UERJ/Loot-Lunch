extends CharacterBody2D
class_name Npc


@export var sprite_frames: SpriteFrames
@export var animation: StringName = &"default"
@export var dialogue: DialogueResource
@export var start_node: StringName = &"start"


var player_in_range: bool = false
var dialogue_balloon: Node


@onready var interaction_label: Label = %InteractionLabel


func _ready() -> void:
	$Area2D.player_entered.connect(_on_player_entered)
	$Area2D.player_exited.connect(_on_player_exited)


func _process(_delta: float) -> void:
	if !player_in_range:
		return

	if is_instance_valid(dialogue_balloon):
		return

	if Input.is_action_just_pressed("interact"):
		dialogue_balloon = DialogueManager.show_dialogue_balloon(dialogue, start_node)


func _on_player_entered(_player) -> void:
	interaction_label.show()
	player_in_range = true


func _on_player_exited(_player) -> void:
	interaction_label.hide()
	player_in_range = false
