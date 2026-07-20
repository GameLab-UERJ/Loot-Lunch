extends CharacterBody2D

@export var sprite_frames: SpriteFrames
@export var animation := "default"
@export var dialogue: DialogueResource
@export var start_node := "start"

var player_in_range := false
var dialogue_balloon: Node

func _ready():
	$Area2D.player_entered.connect(_on_player_entered)
	$Area2D.player_exited.connect(_on_player_exited)


func _process(_delta):
	if !player_in_range:
		return
	
	if is_instance_valid(dialogue_balloon):
		return
	
	if Input.is_action_just_pressed("interact"):
		dialogue_balloon = DialogueManager.show_dialogue_balloon(dialogue, start_node)


func _on_player_entered(_player):
	player_in_range = true


func _on_player_exited(_player):
	player_in_range = false
