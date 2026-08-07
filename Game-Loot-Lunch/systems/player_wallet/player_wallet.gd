extends Node

# Player Wallet System

## Emitido sempre que a quantidade de gold muda
signal gold_changed(new_amount: int)

var initial_gold: int = 999

var gold: int = 0

func _ready() -> void:
	gold = initial_gold
	gold_changed.emit(gold)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return

	gold += amount
	gold_changed.emit(gold)


func can_remove_gold(amount: int) -> bool:
	if amount <= 0:
		return false
	return gold >= amount

## Tenta remover Gold e retorna se a operação foi concluída.
func remove_gold(amount: int) -> bool:
	if not can_remove_gold(amount):
		return false
		
	gold -= amount
	gold_changed.emit(gold)
	return true

var opened_chests: Array[String] = []

func is_chest_opened(chest_id: String) -> bool:
	return chest_id in opened_chests

func mark_chest_opened(chest_id: String) -> void:
	if not chest_id in opened_chests:
		opened_chests.append(chest_id)
