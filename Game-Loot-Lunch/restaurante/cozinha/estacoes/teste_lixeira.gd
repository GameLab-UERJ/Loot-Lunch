extends Node2D


const CARRYABLE_ITEM_SCENE: PackedScene = preload("res://restaurante/itens/carryable_item.tscn")
const RAW_SKEWER_DATA: ItemData = preload("res://restaurante/itens/dados/espetinho_carne_cru.tres")
const PERFECT_SKEWER_DATA: ItemData = preload("res://restaurante/itens/dados/espetinho_carne_perfeito.tres")
const BURNT_SKEWER_DATA: ItemData = preload("res://restaurante/itens/dados/espetinho_carne_torrado.tres")


@onready var chef: Chef = $Chef
@onready var items_container: Node2D = $ItensNoChao


func _ready() -> void:
	call_deferred("_seed_test_items")


func _seed_test_items() -> void:
	_spawn_item(RAW_SKEWER_DATA, Vector2(180, 150))
	_spawn_item(PERFECT_SKEWER_DATA, Vector2(280, 150))
	_spawn_item(BURNT_SKEWER_DATA, Vector2(380, 150))


func _spawn_item(data: ItemData, position: Vector2) -> void:
	var item: CarryableItem = CARRYABLE_ITEM_SCENE.instantiate()
	item.data = data
	items_container.add_child(item)
	item.position = position
