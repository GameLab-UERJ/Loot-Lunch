extends CharacterBody2D

@onready var interactable_area: GenericInteractableArea = $InteractableArea
@onready var interaction_label: Label = $InteractionLabel
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var can_interact: bool = false
const DIALOGUE_RESOURCE: DialogueResource = preload("res://entities/npcs/guide_man/guide_man_quest.dialogue")

func _ready() -> void:
	interaction_label.hide()
	interactable_area.player_entered.connect(_on_player_entered)
	interactable_area.player_exited.connect(_on_player_exited)

func _on_player_entered(_player: Player) -> void:
	can_interact = true
	interaction_label.show()
	anim_sprite.play("wave")

func _on_player_exited(_player: Player) -> void:
	can_interact = false
	interaction_label.hide()
	#anim_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		DialogueManager.show_dialogue_balloon(DIALOGUE_RESOURCE, "start")
