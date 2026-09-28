extends Node2D


const CARRYABLE_ITEM_SCENE: PackedScene = preload("res://restaurante/itens/carryable_item.tscn")
const RAW_SKEWER_DATA: ItemData = preload("res://restaurante/itens/dados/espetinho_carne_cru.tres")


@onready var flame_event: FlameRandomEvent = $Churrasqueira/FlameRandomEvent
@onready var grease_event: GreaseRandomEvent = $GreaseRandomEvent
@onready var chef: Chef = $Chef
@onready var churrasqueira: CookingStation = $Churrasqueira


func _ready() -> void:
	queue_redraw()
	call_deferred("_seed_test_skewer")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		flame_event.trigger_random_event()
		grease_event.trigger_random_event(true)


func _seed_test_skewer() -> void:
	var skewer: CarryableItem = CARRYABLE_ITEM_SCENE.instantiate()
	skewer.data = RAW_SKEWER_DATA
	if chef.hand_component.hold(skewer):
		churrasqueira.place_item(chef.hand_component)


func _draw() -> void:
	var spawn_area: Rect2 = Rect2(
		grease_event.position + grease_event.spawn_area.position,
		grease_event.spawn_area.size
	)
	draw_rect(Rect2(32, 40, 576, 280), Color("#302b32"))
	draw_rect(Rect2(32, 40, 576, 280), Color("#17171b"), false, 4.0)
	draw_rect(spawn_area, Color("#d7442e", 0.12))
	draw_rect(spawn_area, Color("#d7442e", 0.8), false, 2.0)
