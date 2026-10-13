extends StaticBody2D
class_name TrashBin


signal item_discarded(item: CarryableItem)


@export var accepts_items: bool = true

@onready var interactable: InteractableComponent = $InteractableComponent
@onready var vanish_effect: SpriteSheetEffect = $VanishEffect


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	interactable.alt_interacted.connect(_on_interacted)


func can_react_to(actor: Node) -> bool:
	if not accepts_items:
		return false
	var hand: HandComponent = HandComponent.find_in(actor)
	return hand != null and not hand.is_empty()


func _on_interacted(actor: Node) -> void:
	if not accepts_items:
		return
	var hand: HandComponent = HandComponent.find_in(actor)
	if hand == null or hand.is_empty():
		return
	var item: CarryableItem = hand.consume_item_with_effect(vanish_effect)
	if item:
		item_discarded.emit(item)
