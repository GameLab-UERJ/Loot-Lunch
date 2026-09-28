extends Node2D


const CARRYABLE_ITEM_SCENE: PackedScene = preload("res://restaurante/itens/carryable_item.tscn")
const RAW_SKEWER_DATA: ItemData = preload("res://restaurante/itens/dados/espetinho_carne_cru.tres")


@onready var chef: Chef = $Chef


func _ready() -> void:
	call_deferred("_seed_test_item")


func _seed_test_item() -> void:
	var item: CarryableItem = CARRYABLE_ITEM_SCENE.instantiate()
	item.data = RAW_SKEWER_DATA
	chef.hand_component.hold(item)
