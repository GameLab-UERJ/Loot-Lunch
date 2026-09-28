extends StaticBody2D
class_name TrashBin


signal item_discarded(item: CarryableItem)


@export var accepts_items: bool = true

@onready var interactable: InteractableComponent = $InteractableComponent


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(actor: Node) -> void:
	if not accepts_items:
		return
	var hand: HandComponent = HandComponent.find_in(actor)
	if hand == null or hand.is_empty():
		return
	var item: CarryableItem = hand.held_item
	hand.consume_item()
	item_discarded.emit(item)
