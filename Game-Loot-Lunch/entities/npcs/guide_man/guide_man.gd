extends CharacterBody2D


const DIALOGUE_RESOURCE: DialogueResource = preload("res://entities/npcs/dialogos/guide_man_quest.dialogue")


var can_interact: bool = false


@onready var interactable_area: GenericInteractableArea = $InteractableArea
@onready var interaction_label: Label = %InteractionLabel
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D"):
	set(value):
		animated_sprite = value
		if animated_sprite:
			animated_sprite.material = load("res://resources/shaders/outline_material.tres").duplicate_deep()
			animated_sprite.material.set("shader_parameter/outline_color",Color.WHITE)
			animated_sprite.material.set("shader_parameter/width",0)


func _ready() -> void:
	interaction_label.hide()
	interactable_area.player_entered.connect(_on_player_entered)
	interactable_area.player_exited.connect(_on_player_exited)
	animated_sprite = animated_sprite


func _on_player_entered(_player: Player) -> void:
	animated_sprite.material.set("shader_parameter/width",1)
	can_interact = true
	interaction_label.show()
	anim_sprite.play("wave")


func _on_player_exited(_player: Player) -> void:
	animated_sprite.material.set("shader_parameter/width",0)
	can_interact = false
	interaction_label.hide()


func _unhandled_input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		DialogueManager.show_dialogue_balloon(DIALOGUE_RESOURCE, "start")
