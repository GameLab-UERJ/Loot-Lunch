extends Node2D


@onready var inventory: Inventory = $CanvasLayer/Inventory
@onready var carne: Item = $Carne
@onready var tomate: Item = $Tomate
@onready var farinha: Item = $Farinha


func _ready() -> void:
	inventory.add_item(carne)
	inventory.add_item(tomate)
	inventory.add_item(farinha)
